### A Pluto.jl notebook ###
# v0.17.1

using Markdown
using InteractiveUtils

# ╔═╡ a1373212-153d-11eb-0716-d98194a1fbe4
using PlutoUI

# ╔═╡ 647a69ae-5af7-4ab1-92f3-e0132f79fa1b
# Make cells wider
html"""<style>
/*              screen size more than:                     and  less than:                     */
@media screen and (max-width: 699px) { /* Tablet */ 
  /* Nest everything into here */
    main { /* Same as before */
        max-width: 1200px !important; /* Same as before */
        margin-right: 100px !important; /* Same as before */
    } /* Same as before*/

}

@media screen and (min-width: 700px) and (max-width: 1199px) { /* Laptop*/ 
  /* Nest everything into here */
    main { /* Same as before */
        max-width: 1200px !important; /* Same as before */
        margin-right: 100px !important; /* Same as before */
    } /* Same as before*/
}

@media screen and (min-width:1000px) and (max-width: 1920px) { /* Desktop */ 
  /* Nest everything into here */
    main { /* Same as before */
        max-width: 1000px !important; /* Same as before */
        margin-right: 100px !important; /* Same as before */
    } /* Same as before*/
}

@media screen and (min-width:1921px) { /* Stadium */ 
  /* Nest everything into here */
    main { /* Same as before */
        max-width: 1200px !important; /* Same as before */
        margin-right: 100px !important; /* Same as before */
    } /* Same as before*/
}
</style>
"""

# ╔═╡ ac736b76-153d-11eb-2dd8-f79d303626fa
md"""
# Sandwich shop
## Setting
You manage a sandwich shop. You want to investigate if adding an extra crew member during rush hour is worth our trouble.

## Some background information
* The arrival time between clients $\left(T\right)$ is a stochastic variable following an exponential distribution with parameter $\lambda(t)$, where $\lambda$ depends on the time of day $t$. From historical data we know the following about the mean time between client arrivals:
    * 00:00-08:00: shop is closed
    * 08:00-11:00: 25 minutes
    * 11:00-14:00: 1 minutes
    * 14:00-17:00: 10 minutes
    * 17:00-19:00: 2 minutes
    * 19:00-20:00: 5 minutes
    * 20:00-24:00: shop is closed
    

    **Remark**: in reality you would execute a measurements campaign and verify if the experimental distribution actually follows an exponential distribution (by means of a Kolmogorov–Smirnov test).
        
* If an employee is available, the client places an order (we could also incorporate a decision time). This implies that we need the shop to have a limited `::Resource` i.e. the employees. 
* If no one is available, the client waits for his turn, but has a limited amount of patience. When this runs out, the client leaves the shop (and should thus cancel his request for the employee `::Resource`). Patience for the different clients is defined as a random variable $\sim\mathcal{U}(5,10)$. 
* Once the order is placed, the preparation time is also a random variable.

## Methodology
Remember the different steps in the simulation process:
###### Formulate the problem and plan the study
The problem is known from the setting. Based on historical data, we will simulate our shop and analyse the impact of increasing the staff size on the client satisfaction (reduced waiting times) and the increased costs.

###### Collect the data and formulate the simulation model
* For this application this historical data is provided (cf. below)
* Make a schematical representation of what is going on and who needs to "communicate" with whom.
* Think about how you will implement all of this (types, field, storage of useful information, opening times etc.)

###### Check the accuracy of the simulation model (assumptions, limitations etc.)
* We assume that the selected distributions match with the reality (exponential for arrival rates, uniform for preparation times, categorical for the menu).

###### Construct a computer program
Cf. below.

###### Test the validity of the simulation model
We will run some simple tests to ensure the simulation works as intended.

###### Plan the simulations to be performed
We will need to keep track of the following information:
* Queue build-up $\rightarrow$ logging of queue required
* Client waiting times $\rightarrow$ logging of waiting times required

Once we have this information we can determine the amount of simulations required for each configuration and start experimenting with different configurations.

###### Conduct the simulation runs and analyze the results
cf. below.

###### Present the conclusions
We need to some data from the activities in our shop:
1. Queue build-up
2. Client waiting times 

## Some tips
* You can round a `::DateTime` e.g.
```Julia
    round(Dates.now(),Minute)
```
* You can use a `::DateTime` within a simulation e.g.
```Julia
	# start on current day, rounded downwards (Q: why?)
    tstart = floor(now(),Day) 
	# setup simulation starting on tstart
    sim = Simulation(tstart)  
	# run the simulation for three days
    run(sim, tstart + Day(3)) 
```
* The current time of the simulation (as a DateTime) can be obtained with `nowDatetime(sim)`.
* You could use a specific logger for a particular function in order to facilitate debugging.

## Possible extensions
* Consider clients with a memory i.e. if they do not get served within their patience range, they go away and spread they word (which in its turn influences future arrival rates).
* Include orders that are place by phone before a specific time. How do you include this in the process of the staff?
* Consider the reverse problem: how many clients do you need for it to be worth it to add an extra person? You could one of the optimisation methods we saw in earlier sessions for this.


"""

# ╔═╡ b0e1d068-160e-11eb-1362-01c43074510b
md"""
## Implementation
We start with by loading up the dependencies and by defining some shared constants and useful functions.
```julia
using Dates              # for actual time & date
using Distributions      # for distributions and random behaviour
using HypothesisTests    # for more statistical analysis
using Logging            # for debugging
using Plots              # for figures
using SimJulia           # for DES
using StatsPlots         # for nicer histograms
using Statistics         # for statistics

# import Base.show in order to use it for our own types
import Base.show

# logging settings
logger = Logging.ConsoleLogger(stdout,LogLevel(-3000))
Logging.global_logger(logger)
Logging.disable_logging(LogLevel(-1000))
@info "$("-"^70)\nLoaded dependencies\n$("-"^70)"

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
```
Once this is know, we can proceed to the definition of the processes that will be used in the simulation.

```julia
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
    
    if res[req].state == SimJulia.processed
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
```

### Test simulation
We can verify the proper functioning of the simulation by running a simulation where there is no personnel available. 
```julia
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
```
From the above demo we can see that the simulation works as intended, however there are some problems we can see as well:
* a client can arrive after closing time due to the way the generator works
* when a client arrives after closing time, he still waits until he runs out of patience.

We will accept these small limitations and continue. We can generate an illustration that shows the queue length and the amount of clients leaving the queue.

```julia

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
    savefig(p, "queuelength.png")
end
```


"""

# ╔═╡ 8d8a51fc-1777-11eb-0690-8575e369cdc9
LocalResource("queuelength.png")

# ╔═╡ 86eab698-1777-11eb-209f-cb2b5eb01c3b
md"""
### Multiple simulations
We are now capable of running multiple simulations and look at the distribution of several metrics such as the mean queue length, the mean waiting time and the amount of clients that run out of patience.

```julia
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
        fname = "multisim - $(n) iterations - $(staff) staff.pdf"
        overviewplot(Nreneg, MWT, MQL, fname)
    end

    return Nreneg, MWT, MQL
end

# run a single multisim in different configurations
multisim(plt=true)
multisim(staff=2,plt=true)
```

*Using 1 staff member:*
"""

# ╔═╡ 1bbd3af4-1776-11eb-0226-91212c01c89b
LocalResource("multisim - 100 iterations - 1 staff.png")

# ╔═╡ 9833c350-1776-11eb-108f-e197d9e465df
md"""
*Using 2 staff members:*

"""

# ╔═╡ 77b5ac42-1776-11eb-23b0-936d3918e053
LocalResource("multisim - 100 iterations - 2 staff.png")

# ╔═╡ abb70132-1776-11eb-298c-bf23946166b2
md"""
### Required sample size
We still need to find out the minimal required sample size that can be considered as representative (i.e. "stable"). In order to have an idea, we generate a boxplot of the three metrics of interest for different sample lengths. For this application a sample size of 1000 should be sufficient.

```julia

function determinesamplesize(;maxpow::Int=3, fname::String="determinesamplesize.pdf")
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
        boxplot(r_MWT, label=["$(n)" for n in labels], title="MWT"),
        boxplot(r_MQL, label=["$(n)" for n in labels], title="MQL"),
        layout=(1,3), size=(1200, 500)
    )
    xticks!(collect(1:maxpow), ["$(n)" for n in labels])
    xlabel!("Sample length")
    savefig(p, fname)
    
end
```
"""

# ╔═╡ 4ef4c1c0-1777-11eb-2cc8-f1c40fa6154e
LocalResource("determinesamplesize.png")

# ╔═╡ 1a2ac91e-1778-11eb-0d8d-653f6a55f915
md"""
If we can show that one of the metrics follows a normal distribution, we can use the desired confidence interval width to determine the required sample length. You can use  the Kolmogorov-Smirnof test for this.

```julia
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
```

"""

# ╔═╡ 0323d94a-177a-11eb-2efe-7fe0cb9c922a
LocalResource("samplesize.png")

# ╔═╡ 1b2e8bb0-177b-11eb-119b-4f1bef23fed2
md"""
We have shown that adding a single person to the staff can drastically reduce the waiting times. You can and should also show this by using statistics. For comparing two cases, we can use a two sample t-test. When comparing multiple populations you can use ANOVA.

```julia
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
    @info \"\"\"  Conclusion: $(ifelse(pvalue(r) > α, "Equal population mean",
                            "Unequal population mean"))\"\"\" 
end

```
"""

# ╔═╡ 00000000-0000-0000-0000-000000000001
PLUTO_PROJECT_TOML_CONTENTS = """
[deps]
PlutoUI = "7f904dfe-b85e-4ff6-b463-dae2292396a8"

[compat]
PlutoUI = "~0.7.18"
"""

# ╔═╡ 00000000-0000-0000-0000-000000000002
PLUTO_MANIFEST_TOML_CONTENTS = """
# This file is machine-generated - editing it directly is not advised

[[AbstractPlutoDingetjes]]
deps = ["Pkg"]
git-tree-sha1 = "0ec322186e078db08ea3e7da5b8b2885c099b393"
uuid = "6e696c72-6542-2067-7265-42206c756150"
version = "1.1.0"

[[Base64]]
uuid = "2a0f44e3-6c83-55bd-87e4-b1978d98bd5f"

[[Dates]]
deps = ["Printf"]
uuid = "ade2ca70-3891-5945-98fb-dc099432e06a"

[[Distributed]]
deps = ["Random", "Serialization", "Sockets"]
uuid = "8ba89e20-285c-5b6f-9357-94700520ee1b"

[[Hyperscript]]
deps = ["Test"]
git-tree-sha1 = "8d511d5b81240fc8e6802386302675bdf47737b9"
uuid = "47d2ed2b-36de-50cf-bf87-49c2cf4b8b91"
version = "0.0.4"

[[HypertextLiteral]]
git-tree-sha1 = "2b078b5a615c6c0396c77810d92ee8c6f470d238"
uuid = "ac1192a8-f4b3-4bfe-ba22-af5b92cd3ab2"
version = "0.9.3"

[[IOCapture]]
deps = ["Logging", "Random"]
git-tree-sha1 = "f7be53659ab06ddc986428d3a9dcc95f6fa6705a"
uuid = "b5f81e59-6552-4d32-b1f0-c071b021bf89"
version = "0.2.2"

[[InteractiveUtils]]
deps = ["Markdown"]
uuid = "b77e0a4c-d291-57a0-90e8-8db25a27a240"

[[JSON]]
deps = ["Dates", "Mmap", "Parsers", "Unicode"]
git-tree-sha1 = "8076680b162ada2a031f707ac7b4953e30667a37"
uuid = "682c06a0-de6a-54ab-a142-c8b1cf79cde6"
version = "0.21.2"

[[LibGit2]]
deps = ["Printf"]
uuid = "76f85450-5226-5b5a-8eaa-529ad045b433"

[[Libdl]]
uuid = "8f399da3-3557-5675-b5ff-fb832c97cbdb"

[[Logging]]
uuid = "56ddb016-857b-54e1-b83d-db4d58db5568"

[[Markdown]]
deps = ["Base64"]
uuid = "d6f4376e-aef5-505a-96c1-9c027394607a"

[[Mmap]]
uuid = "a63ad114-7e13-5084-954f-fe012c677804"

[[Parsers]]
deps = ["Dates"]
git-tree-sha1 = "ae4bbcadb2906ccc085cf52ac286dc1377dceccc"
uuid = "69de0a69-1ddd-5017-9359-2bf0b02dc9f0"
version = "2.1.2"

[[Pkg]]
deps = ["Dates", "LibGit2", "Libdl", "Logging", "Markdown", "Printf", "REPL", "Random", "SHA", "UUIDs"]
uuid = "44cfe95a-1eb2-52ea-b672-e2afdf69b78f"

[[PlutoUI]]
deps = ["AbstractPlutoDingetjes", "Base64", "Dates", "Hyperscript", "HypertextLiteral", "IOCapture", "InteractiveUtils", "JSON", "Logging", "Markdown", "Random", "Reexport", "UUIDs"]
git-tree-sha1 = "57312c7ecad39566319ccf5aa717a20788eb8c1f"
uuid = "7f904dfe-b85e-4ff6-b463-dae2292396a8"
version = "0.7.18"

[[Printf]]
deps = ["Unicode"]
uuid = "de0858da-6303-5e67-8744-51eddeeeb8d7"

[[REPL]]
deps = ["InteractiveUtils", "Markdown", "Sockets"]
uuid = "3fa0cd96-eef1-5676-8a61-b3b8758bbffb"

[[Random]]
deps = ["Serialization"]
uuid = "9a3f8284-a2c9-5f02-9a11-845980a1fd5c"

[[Reexport]]
git-tree-sha1 = "45e428421666073eab6f2da5c9d310d99bb12f9b"
uuid = "189a3867-3050-52da-a836-e630ba90ab69"
version = "1.2.2"

[[SHA]]
uuid = "ea8e919c-243c-51af-8825-aaa63cd721ce"

[[Serialization]]
uuid = "9e88b42a-f829-5b0c-bbe9-9e923198166b"

[[Sockets]]
uuid = "6462fe0b-24de-5631-8697-dd941f90decc"

[[Test]]
deps = ["Distributed", "InteractiveUtils", "Logging", "Random"]
uuid = "8dfed614-e22c-5e08-85e1-65c5234f0b40"

[[UUIDs]]
deps = ["Random", "SHA"]
uuid = "cf7118a7-6976-5b1a-9a39-7adc72f591a4"

[[Unicode]]
uuid = "4ec0a83e-493e-50e2-b9ac-8f72acf5a8f5"
"""

# ╔═╡ Cell order:
# ╟─647a69ae-5af7-4ab1-92f3-e0132f79fa1b
# ╠═a1373212-153d-11eb-0716-d98194a1fbe4
# ╟─ac736b76-153d-11eb-2dd8-f79d303626fa
# ╟─b0e1d068-160e-11eb-1362-01c43074510b
# ╟─8d8a51fc-1777-11eb-0690-8575e369cdc9
# ╟─86eab698-1777-11eb-209f-cb2b5eb01c3b
# ╟─1bbd3af4-1776-11eb-0226-91212c01c89b
# ╟─9833c350-1776-11eb-108f-e197d9e465df
# ╟─77b5ac42-1776-11eb-23b0-936d3918e053
# ╟─abb70132-1776-11eb-298c-bf23946166b2
# ╟─4ef4c1c0-1777-11eb-2cc8-f1c40fa6154e
# ╟─1a2ac91e-1778-11eb-0d8d-653f6a55f915
# ╟─0323d94a-177a-11eb-2efe-7fe0cb9c922a
# ╟─1b2e8bb0-177b-11eb-119b-4f1bef23fed2
# ╟─00000000-0000-0000-0000-000000000001
# ╟─00000000-0000-0000-0000-000000000002
