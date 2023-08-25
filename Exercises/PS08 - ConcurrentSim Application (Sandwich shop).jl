@info "$("-"^70)\nPS08 - ConcurrentSim Applications: Starting sandwich shop demo\n$("-"^70)"

using Dates              # for actual time & date
using Distributions      # for distributions and random behaviour
using HypothesisTests    # for more statistical analysis
using Logging            # for debugging
using Plots              # for figures
using ConcurrentSim      # for DES
using ResumableFunctions # for resumable functions
using StatsPlots         # for nicer histograms
using Statistics         # for statistics

# import Base.show in order to use it for our own types
import Base.show

# logging settings
logger = Logging.ConsoleLogger(stdout,LogLevel(-3000))
Logging.global_logger(logger)
Logging.disable_logging(LogLevel(-1000))
@info "$("-"^70)\nLoaded dependencies\n$("-"^70)"

# ------------------------------------------------ #
#               Simulation core code               # 
# ------------------------------------------------ #

# Available items in the shop
const menulist = ["sandwich, cold","sandwich, hot","pasta","soup"]
# Historical data product demand
const menuprob = Distributions.Categorical([0.6,0.2,0.1,0.1])  
# Preparation times [s]
const preptimes = Dict( menulist[1]=>Distributions.Uniform(60,90),
                        menulist[2]=>Distributions.Uniform(60,120), 
                        menulist[3]=>Distributions.Uniform(60,90),
                        menulist[4]=>Distributions.Uniform(30,45))
# Client arrival rates [s]
const arrivals = Dict("[08-11[" => Distributions.Exponential(25*60),
                        "[11-14[" => Distributions.Exponential(1*60),
                        "[14-17[" => Distributions.Exponential(10*60),
                        "[17-19[" => Distributions.Exponential(2*60),
                        "[19-20[" => Distributions.Exponential(5*60))
# Time required to choose something [s]
const choicetime = Distributions.Uniform(10,30)
# Arrival time function [s]
function nextarrival(t::DateTime; arrivals::Dict=arrivals)
    if (hour(t) >= 8) & (hour(t) < 11)
        return Second(round(rand(arrivals["[08-11["])))
    elseif (hour(t) >= 11) & (hour(t) < 14)
        return Second(round(rand(arrivals["[11-14["])))
    elseif (hour(t) >= 14) & (hour(t) < 17)
        return Second(round(rand(arrivals["[14-17["])))
    elseif (hour(t) >= 17) & (hour(t) < 19)
        return Second(round(rand(arrivals["[17-19["])))
    elseif (hour(t) >= 19) & (hour(t) < 20)
        return Second(round(rand(arrivals["[19-20["])))
    else
        return nothing
    end
end

# define a shop
struct Shop
    staff::Resource
    queuelength::Array{Tuple{DateTime,Int64},1}
    clients::Dict
    waitingtimes::Array{Millisecond, 1}
    renegtimes::Array{DateTime,1}
    function Shop(env::Environment, nstaff::Int=1)
        # add the crew
        staff = Resource(env,nstaff)
        # no queue at the start of the simulation       
        queuelength = [(nowDatetime(env),0)] 
        # keep record of each client, for possible extensions such as:
        #   - a free sandwich after having bought a specific number
        #   - including a feeling of disconent after leaving the queue
        clients = Dict()               
        # client waiting times
        waitingtimes = Array{Millisecond,1}()              
        # moments when a client leaves due to losing his patience     
        renegtimes = Array{DateTime,1}()     
        return new(staff,queuelength,clients,waitingtimes,renegtimes)
    end
end

function show(io::IO,s::Shop)
    print(io,"Shop with $(s.staff.capacity) employees, currently $(length(s.staff.put_queue)) people waiting")
end

# define a client
mutable struct Client
    id::Int
    patience::Second
    orderhist::Dict
    proc::Process
    function Client(env::Environment,shop::Shop)
        client = new()
        client.id = length(shop.clients) + 1
        client.patience = Second(round(rand(Distributions.Uniform(5*60,10*60))) )
        client.orderhist = Dict()
        # add client to shop registry
        shop.clients[client.id]= client
        # start the client process
        client.proc = @process clientbehavior(env, shop, client)
        return client
    end
end
    
function show(io::IO,c::Client)
    print(io,"Client N° $(c.id) with $(round(c.patience.value / 60,digits=2)) minutes of patience")
end

# Generating function for clients.
@resumable function clientgenerator(env::Environment, shop::Shop, topen::Int=8, tclose::Int=20)
    while true
        # before opening hours => wait
        if hour(nowDatetime(env)) < topen
            delta = floor(nowDatetime(env), Day) + Hour(topen) - nowDatetime(env)
            @logmsg LogLevel(-3000) "$(nowDatetime(env)) - Not open yet, waiting for $(delta)"
            @yield timeout(env, delta)
        end
        
        # after opening hours => wait
        if hour(nowDatetime(env)) >= tclose
            delta = floor(nowDatetime(env), Day) + Day(1) + Hour(topen) - nowDatetime(env)
            @logmsg LogLevel(-3000) "$(nowDatetime(env)) - Closing shop, waiting for $(delta)"
            @yield timeout(env, delta)
        end
        
        # during opening hours => generate clients
        tnext = nextarrival(nowDatetime(env))
        @yield timeout(env, tnext)
        c = Client(env,shop)
    end
end

@resumable function clientbehavior(env::Environment, s::Shop, c::Client)
    @debug "$(nowDatetime(env)) - Client (N° $(c.id) arrives (Client patience: $(c.patience))"
    # choose what to get
    @yield timeout(env, Second(round(rand(choicetime))))
    choice = menulist[rand(menuprob)]
    # ready to order
    tin = nowDatetime(env)                               
    # try to obtain a staff member 
    req = request(s.staff)                            
    res  = @yield req | timeout(env, c.patience)
    # log of current queuelength
    push!(s.queuelength, (nowDatetime(env), length(s.staff.put_queue) ) )
    
    if res[req].state == ConcurrentSim.processed
        @debug "$(nowDatetime(env)) - Client N° $(c.id) is being served and orders a $(choice)"
        tserved = nowDatetime(env)
        twait = tserved - tin # in milliseconds
        push!(s.waitingtimes, twait)
        @yield timeout(env, Second(round(rand(preptimes[choice])))) # preparing order
        @debug "$(nowDatetime(env)) - Client N° $(c.id) receives order"
        @yield release(s.staff) # release staff
    else
        @debug "$(nowDatetime(env)) - Client N° $(c.id) ran out of patience"
        if haskey(s.staff.put_queue, req)
            cancel(s.staff, req)                   # cancel staff request
        end
        push!(s.renegtimes, nowDatetime(env))  # store renegtimes
    end 
end


@info "$("-"^70)\nLoaded functions\n$("-"^70)"


# ------------------------------------------------ #
#               helper functions                   # 
# ------------------------------------------------ #

"""
    plotqueue(s::Shop)

Store an illustration of the queuelength over time from a `::Store`
"""
function plotqueue(s::Shop)
    # some makeup
    tstart = floor(s.queuelength[1][1], Day) + Hour(8)
    tstop  = floor(s.queuelength[1][1], Day) + Hour(23)
    daterange =  tstart : Minute(60) : tstop
    datexticks = [Dates.value(mom) for mom in daterange]
    datexticklabels = Dates.format.(daterange,"HH:MM")
    # queue length
    x::Array{DateTime,1} = map(v -> v[1], s.queuelength)
    y::Array{Int,1} = map(v -> v[2], s.queuelength)
    p1 = plot(x, y, linetype=:steppost, label="Queue length")
    xticks!(datexticks, datexticklabels,rotation=0)
    xlims!(Dates.value(tstart),Dates.value(tstop))
    yticks!(0:1:maximum(y)+1)
    # reneg moments
    nreneg = 1:length(s.renegtimes)
    p2 = plot(s.renegtimes, collect(nreneg), linetype=:steppost, label="Number of renegs")
    xticks!(datexticks, datexticklabels,rotation=0)
    xlims!(Dates.value(tstart),Dates.value(tstop))
    yticks!(0:5:length(s.renegtimes)+1)
    # global figure
    p = plot(p1,p2, layout=(2,1), size=(1000,800))
    savefig(p, "./Exercises/img/queuelength.png")
end



"""
    overviewplot(Nreneg::Array{Int64,1}, MWT::Array{Float64,1}, 
MQL::Array{Float64,1}, fname::String)

function to make an overview plot that includes a histogram of
the amount of renegs, the mean waiting time and the mean queue
length.

"""
function overviewplot(Nreneg::Array{Int64,1}, MWT::Array{Float64,1}, 
                      MQL::Array{Float64,1}, fname::String)
    @info "making overviewplot $(fname)"
    p1 = StatsPlots.histogram(Nreneg,bins=0:2:80,normalize=:probability, 
                              title="Reneg distribution", label="",
                              xlabel="Amount of renegs",
                              ylabel="Experimental probability")
    p2 = StatsPlots.histogram(MWT,bins=20,normalize=:probability, 
                              title="MWT distribution", label="",
                              xlabel="MWT [s]",
                              ylabel="Experimental probability")
    p3 = StatsPlots.histogram(MQL,bins=20,normalize=:probability, 
                              title="MWT distribution", label="",
                              xlabel="MQL",
                              ylabel="Experimental probability")
    p = plot(p1, p2, p3, layout=(1,3), size=(1200, 500))
    savefig(p, fname)
    return
end

# ------------------------------------------------ #
#            Simulation configuration              # 
# ------------------------------------------------ #

"""
    test()

Run a simple simulation for one day without staff. Conclusions:
    - a client can arrive after closing time
    - when a client arrives after closing time, he still waits until he runs out of patience
"""
function test()
    @info "$("-"^70)\nStarting a store without staff\n$("-"^70)"
    # Start a simulation on today 00Hr00
    sim = Simulation(floor(Dates.now(),Day))
    s = Shop(sim, 0)
    @process clientgenerator(sim, s)
    # Run the sim for one day
    run(sim, floor(Dates.now(),Day) + Day(1))
end

test()

"""
    runsim()

From our first simulation and the generated figure we can clearly see that there is a problem
serving the clients fast enough during the midday peak hours.

"""
function runsim()
    @info "$("-"^70)\nStarting a complete simulation\n$("-"^70)"
    # Start a simulation on today 00Hr00
    sim = Simulation(floor(Dates.now(),Day))
    s = Shop(sim, 1)
    @process clientgenerator(sim, s)
    # Run the sim for one day
    run(sim, floor(Dates.now(),Day) + Day(1))
    # Make an illustration of the queue length
    @info "Making queue length figure"
    plotqueue(s)
end

runsim()

"""
    multisim(;n::Int=100, staff::Int=1,tstart=floor(now(),Day), duration::Period=Day(1))

Run `n` simulations with shop staffed with `staff` persons. By default start on current day and
runs for one day.

Returns a vector of the number of renegs, the Mean Waiting Times (MWT) and Mean Queue Length (MQL)
"""
function multisim(;n::Int=100, staff::Int=1,
                  tstart::DateTime=floor(now(),Day), 
                  duration::Period=Day(1), plt::Bool=false)
    @info "<multisim>: Running a multisim simulation on $(Threads.nthreads()) threads"
    # pre-allocate results
    Nreneg = Array{Int64,1}(undef, n)
    MWT = Array{Float64,1}(undef, n)
    MQL = Array{Float64,1}(undef, n)
    # run all simulations (in parallel where available)
    Threads.@threads for i in 1:n
        sim = Simulation(tstart)
        shop = Shop(sim, staff)
        @process clientgenerator(sim,shop)
        run(sim, tstart + duration)
        Nreneg[i] = length(shop.renegtimes)
        MWT[i] = mean(Dates.value.(shop.waitingtimes)/1e3) # in seconds
        MQL[i] = mean([x[2] for x in shop.queuelength])
    end
    # generate a nice illustration
    if plt
        #@info Nreneg, MWT, MQL
        fname = "multisim - $(n) iterations - $(staff) staff.png"
        overviewplot(Nreneg, MWT, MQL, fname)
    end

    return Nreneg, MWT, MQL
end

# run a single multisim in different configurations
multisim(plt=true)
multisim(staff=2,plt=true)

# Determine when you have enough sample data
"""
    determinesamplesize()

Make a boxplot of Nreneg, MWT, MQL for different sample sizes.

When looking at the boxplot, you see the boxes stay fixed starting from
a sample length of around 1000. Of course the amount of outlier will increase
for an increasing sample length.
"""
function determinesamplesize(;maxpow::Int=3, fname::String="determinesamplesize.png")
    @info "<determinesamplesize>: Running determinesamplesize $(fname)"
    r_reneg = []
    r_MWT = []
    r_MQL = []
    labels = collect(10 .^ (1:maxpow))
    
    for n in labels
        @info "\t<determinesamplesize>: working on sample length $(n)"
        (Nreneg, MWT, MQL) = multisim(n, 1);
        push!(r_reneg, Nreneg)
        push!(r_MWT, MWT)
        push!(r_MQL, MQL)
    end

    @info "\t<determinesamplesize>: rendering plot"
    p = plot(
        boxplot(r_reneg, label="", title="Renegs"),
        boxplot(r_MWT, label="", title="MWT"),
        boxplot(r_MQL, label="", title="MQL"),
        layout=(1,3), size=(1200, 500)
    )
    xticks!(collect(1:maxpow), ["$(n)" for n in labels])
    xlabel!("Sample length")
    savefig(p, fname)
    
end

#determinesamplesize(maxpow=4)

# Evaluate normality and required sample lengths
function evalnorm(;α::Float64=0.05)
    @info "running normality test"
    # use MWT for this example
    _, MWT, _ = multisim()
    # run K-S test
    res = ExactOneSampleKSTest(MWT, Normal(mean(MWT), std(MWT)))
    if pvalue(res) > α
        # make plot for CI
        @info "normality respected, making sample size plot"
        # basis stat formulas
        E = range(0.25, stop=20, length=50)
        n = (std(MWT)*quantile(Normal(),1 - 0.05/2) ./ E ) .^2
        p = plot(E,n,marker=:circle,label="", yscale=:log10)
        xlabel!("precision on MWT [s]")
        ylabel!("Required sample size")
        savefig(p,"samplesize.png")
    else
        @info "data not normal"
    end
    return res
end

evalnorm()

# verify statistical difference between two staffings
function comparestaffing(;α::Float64=0.05)
    @info "comparing two populations"
    _, MWT_1, _ = multisim()
    _, MWT_2, _ = multisim(staff=2)
    @info "  checking equality of variances"
    eqvar = VarianceFTest(MWT_1, MWT_2)
    if pvalue(eqvar) > α
        @info "  assuming equal variance"
        r = EqualVarianceTTest(MWT_1, MWT_2)
    else
        @info "  assuming unequal variance"
        r = UnequalVarianceTTest(MWT_1, MWT_2)
    end
    @info """  Conclusion: $(ifelse(pvalue(r) > α, "Equal population mean",
                            "Unequal population mean"))""" 
end

comparestaffing()