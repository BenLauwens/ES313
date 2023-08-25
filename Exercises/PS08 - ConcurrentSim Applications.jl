### A Pluto.jl notebook ###
# v0.19.27

using Markdown
using InteractiveUtils

# ╔═╡ 50cf3ffd-614a-4f6f-a064-bc26767d7a59
begin
	using Pkg
	cd(joinpath(dirname(@__FILE__),".."))
    Pkg.activate(pwd())
	using PlutoUI
	PlutoUI.TableOfContents()
end

# ╔═╡ 647a69ae-5af7-4ab1-92f3-e0132f79fa1b
html"""
 <! -- this adapts the width of the cells to display its being used on -->
<style>
	main {
		margin: 0 auto;
		max-width: 2000px;
    	padding-left: max(160px, 10%);
    	padding-right: max(160px, 10%);
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
Below you can find some excerpts from the code you can run yourself
```Julia
include("/path/to/PS08 - ConcurrentSim Application (Sandwich shop).jl")
```


We start with by loading up the dependencies and by defining some shared constants and useful functions.
```julia
using Dates              # for actual time & date
using Distributions      # for distributions and random behaviour
using HypothesisTests    # for more statistical analysis
using Logging            # for debugging
using Plots              # for figures
using ConcurrentSim           # for DES
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
LocalResource("./Exercises/img/multisim - 100 iterations - 1 staff.png")

# ╔═╡ 9833c350-1776-11eb-108f-e197d9e465df
md"""
*Using 2 staff members:*

"""

# ╔═╡ 77b5ac42-1776-11eb-23b0-936d3918e053
LocalResource("./Exercises/img/multisim - 100 iterations - 2 staff.png")

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
LocalResource("./Exercises/img/determinesamplesize.png")

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
LocalResource("./Exercises/img/samplesize.png")

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

# ╔═╡ c33d60cd-0fff-4a2a-b995-88842a17c96b
md"""
# Counter-Battery fire
There are numerous use cases for simulation in a military context:
- long history, starting with the atomic bomb
- large scale conflicts with combination of all components (e.g. air defense operations)
- mass casualty events
- planning phase of operations
- operationality of fleet 
- agent based modeling for optimal assault scenario

## Counterbattery principle
NATO definition:
```
Fire delivered for the purpose of destroying or neutralizing the enemy's fire support system**
```

$(PlutoUI.LocalResource("./Exercises/img/CBoverview.png",:width => 2000))

## Motivation:

➡ Statistical exploitation ↔ single trial (real world)

➡ Flexibility
* Evaluate different tactics
* Compare different weapon systems
* Parametric study sensors

➡ Use cases:
* Compare contestants in the procurement phase
* Fine-tuning the tactics in a pre-deployment phase (using latest battlefield info)


Active research domain:
* Networks of radar stations ([2021](https://papers.ssrn.com/sol3/papers.cfm?abstract_id=3855034),  [2022](https://papers.ssrn.com/sol3/papers.cfm?abstract_id=4139697))
* Networks of acoustic sensors ([2019](https://asa.scitation.org/doi/10.1121/1.5138927))
* Military research budgets (DARPA/EDA) (e.g. [covert sensing](https://ec.europa.eu/info/funding-tenders/opportunities/portal/screen/opportunities/topic-details/edf-2022-ra-sens-csens;callCode=null;freeTextSearchKeyword=;matchWholeText=false;typeCodes=1,2,8;statusCodes=31094501;programmePeriod=null;programCcm2Id=null;programDivisionCode=null;focusAreaCode=null;destination=null;mission=null;geographicalZonesCode=null;programmeDivisionProspect=null;startDateLte=null;startDateGte=null;crossCuttingPriorityCode=null;cpvCode=null;performanceOfDelivery=null;sortQuery=startDate;orderBy=asc;onlyTenders=false;topicListKey=callTopicSearchTableState))
* all the classified research in collaboration with industry (or not)

"""

# ╔═╡ 7fdf6c82-449b-490b-b7c6-f7d2bb253f2b
md"""
## Methodology
Remember the different steps in the simulation process:
###### Formulate the problem and plan the study
The counter-battery fire problem is complicated. We will focus on a specific problem within this context. E.g. An enemy artillery unit is firing on targets using a shoot and scoot strategy. We try to determine their location and fire upon them in order to disable the unit. We use passive sensing (acoustic detection) to trigger our active sensing (radar). Limiting active sensing makes sense from a tactical point of view (limit exposure). We also follow a shoot and scoot strategy to avoid becoming victim of counter-battery fire ourselves.

We want to:
1. compare different weapon systems in terms of efficiency.
2. evaluate the impact of proximity of passive sensors on counter battery effectiveness. This can be used in a mission planning phase to find a trade-off between putting troops at risk and eliminating enemy capacity.



###### Collect the data and formulate the simulation model
* For this application some data is provided for different weapon systems
* Make a schematical representation of what is going on and who needs to "communicate" with whom.
* Tackling this problem requires you to look at it from a different angle. Some examples:
  - sound wave of a shot (receive ↔ actively trigger)
  - radar for point of origin (emit radar waves ↔ signal visibility)
  - damage assessment (tangible ↔ proximity scan & damage model(s))
  - standard operating procedures of units (small ➡ large, coherence)


###### Check the accuracy of the simulation model (assumptions, limitations etc.)
* 2D world without obstacles
* constant speed of sound, no attenuation of the sound wave (signal-to-noise always high)
* rectilinear movement for projectiles (vs PMM, MPMM, 6DOF)
* a fired shot is visible to the radar in a specific window (central part of its trajectory).
* shoot and scoot strategy for artillery units
* a canon can no longer move if its health is below 1/2 and no longer able to fire if its health is below 1/3
* we ignore the military decision making process wich normally determines if and when to return fire, i.e. we suppose we always have the go to return fire.
* a firing mission has a shelf life

###### Construct a computer program
We will build a modular and layered composition of the program. The details can be found in
```Julia
include("/path/to/PS08 - ConcurrentSim Application (Counter-battery).jl")
```


Technical types:
- ammunition type (velocity, lethal radius)
- canon type (precision, type of ammunition, timings, movement)

Tactical types:
- Equipment
  - Canon (position, health, positions)
  - Acoustic (ownership = other party!)
  - Radar (ownership = other party!)
- Shot (source canon, target, time of flight, ammunition type...)
- FiringMission
- Unit
  - Platoon
  - Battery
- Battlefield

Processes
* enemy mission generator: generate firing mission for the adversary
* battery cycle: complete process for this tactical level (dispatching fires, movement, waiting for subunits)
* platooncycle: complete process for this tactical level (dispatching fires, movement, waiting for subunits)
* canoncycle: for this tactical level (fires, movement)
* mission scheduler: dispatch the firing according to a specific strategy at a certain level (e.g. max simultaneous firings)
* move: make a specific tactical level move to a new position
* acousticdetection: simulation of the soundwave
* getmissions: get a mission from the unit's queue, check validity, combine or split and return the actual mission that will be executed
* fire: determine order of actions and schedule them accordingly for each shot fired
* impactassessment: evaluate damage of a shot on impact location to nearby units according to a damage model
* radarvisible: increase number of shots from a specific canon that can be seen by the radar
* radarnonvisible: decrease number of shots from a specific canon that can be seen by the radar
* radarscan: simulation of the radar actually scanning the sky. This results in a firing mission based on the location the shot was fired from
* missionscheduler: used to dispatches firing mission to a lower lever tactical unit

"""

# ╔═╡ 91cb22d0-3b01-4378-9f89-f9fdf9e14341
md"""
$(PlutoUI.LocalResource("./Exercises/img/principle.png",:width => 2000))
"""

# ╔═╡ fd246bac-2929-41fc-ac82-7fd404bc3333
md"""
###### Test the validity of the simulation model
We will run some simple tests to ensure the simulation works as intended.

###### Plan the simulations to be performed
Let's compare the current Belgian artillery systems with a future artillery system in a counter battery setting where the adversary is using a shoot and scoot strategy.
* scenario_1: classic FA vs classic FA
* scenario_2: classic FA vs more mobile FA
* scenario_3: classic FA vs extremely mobile FA

###### Conduct the simulation runs and analyze the results
The comparison of the different scenarios can be run by
```Julia
p_mobkil, p_inops = compare_scenarios(scenario_1, scenario_2, n=100)
```

The impact of the sensor location can be run by
```Julia
p_sensor = distance_study(0.:2000.:10000.,100)
```


###### Present the conclusions
We were able to show that current Belgian artillery system is unable to provide addequate counter-battery fire against and adversary using a shoot and scoot strategy. The newer systems are able to provide adequate counter-battery fire. It was found that mobility and the in- and out-of-action timings are crucial for success.

$(PlutoUI.LocalResource("./Exercises/img/inoperational.png",:width => 500))

$(PlutoUI.LocalResource("./Exercises/img/sensorlocation.png",:width => 500))

"""

# ╔═╡ a92d9284-a02f-4e49-a683-9d14c69467e8
md"""
## Possible extensions of our simulation:
* Combine differential equations in the ConcurrentSim framework (6DOF)
* Additional damage models (feasible, thanks to modular composition)
* more "players" (feasible: array of sensors instead of single sensor)
* real world topography, line-of-sight limitations, signal dampening (both radar and sound)
* ``\dots``
"""

# ╔═╡ Cell order:
# ╟─50cf3ffd-614a-4f6f-a064-bc26767d7a59
# ╟─647a69ae-5af7-4ab1-92f3-e0132f79fa1b
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
# ╟─c33d60cd-0fff-4a2a-b995-88842a17c96b
# ╟─7fdf6c82-449b-490b-b7c6-f7d2bb253f2b
# ╟─91cb22d0-3b01-4378-9f89-f9fdf9e14341
# ╟─fd246bac-2929-41fc-ac82-7fd404bc3333
# ╟─a92d9284-a02f-4e49-a683-9d14c69467e8
