### A Pluto.jl notebook ###
# v0.19.27

using Markdown
using InteractiveUtils

# ╔═╡ 4de0ee11-f8af-4865-8737-ba0dc5c3404e
begin
	using Pkg
	cd(joinpath(dirname(@__FILE__),".."))
    Pkg.activate(pwd())
	using Logging
	# for simulation
	using Random
	using ConcurrentSim, ResumableFunctions
	using PlutoUI
	PlutoUI.TableOfContents()
end

# ╔═╡ 9cda8f1c-2394-42bf-883c-4dbe5df8ae56
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

# ╔═╡ c395df98-145a-11eb-1716-2de187df1a1a
md"""
# Logging
The [Logging](https://docs.julialang.org/en/v1/stdlib/Logging/index.html) module will be used for efficient debugging and testing during development. 

A logger has its own lower bound on the `LogLevel` that it can show. In addition to this, there is a global setting that determines the lowest level that will be registered. When you are running a Julia script in the REPL, the default logger's minimal level is `Info`, so you won't see any messages below this level. When working with a Pluto notebook, as is the case here, a specific logger has ben built with the default level set to `Debug`.

Below you find some practical examples of using this module.
"""

# ╔═╡ dafa45ae-1462-11eb-3338-037167917f4d
# Current logger's minimal level
Logging.min_enabled_level(current_logger())

# ╔═╡ f23a3616-6b07-4853-8a77-564cce1bacc7
begin 
	# Setting global settings
	disable_logging(LogLevel(-1001))
	@debug "globally visible"
	disable_logging(Info)
	@debug "no longer visible"

	# enable more for later use
	disable_logging(LogLevel(-5001))
	nothing
end

# ╔═╡ 0560f32a-1462-11eb-0685-09e4f341ddf5
begin		
	"""
		logging_demo_1()
	
	A small demo where everything is run on a single logger. Keep in mind when using the global logger, that its lowest level is `Info` (`LogLevel(0)`), so you won't see anything below. 
	
	Also keep in mind that you need to modify the global settings before you can see anything below `Debug`. You can do this with `disable_logging(LogLevel(N))`. 
	
	### keywords
	* logger: the logger you want to use. Defaults to the global logger.
	"""
	function logging_demo_1(args...; logger=Logging.global_logger(), kwargs...)
		with_logger(logger) do
			# a message at the info level
			@info "logging_demo_1 was invoked with:\n\t- args: $(args)\n\t- kwargs: $(kwargs)\n\t- using logger <$(logger)> (current logger's lowest level: $(Logging.min_enabled_level(logger)))"
			# a message at the debug level (-1000; visible)
			@debug "logging_demo_1 lowest level message that allows the debug level"
			# a message at an even lower level
			@logmsg LogLevel(-2000) "not visible by default"
		end
	end

	nothing;
end

# ╔═╡ 8ddac37c-1465-11eb-17d4-fdce80dc78fe
# DEMO 1a - USING LOGGING DEFAULT SETTINGS
logging_demo_1(1,2, goedemorgen="bonjour")

# ╔═╡ b05f57c2-1466-11eb-272f-5fc93c04c744
begin 
	# DEMO 1b - USING A SPECIFIC LOGGER THAT WILL SHOW THE LOWER LEVEL MESSAGE
	customlogger = Logging.SimpleLogger(stdout, LogLevel(-3000))
	logging_demo_1(3,4,logger=customlogger, goedenavond="bonsoir")
end

# ╔═╡ 19b12fc6-1464-11eb-2fc1-cbb3f82479c5
begin
	"""
		logging_demo_2()

	A small demo where it is possible to direct the logs generated by a specific function to a file. The can be very handy for debugging purposes or analysis after a simulation. By default everything is run on a single logger. 

	### keywords
	* logger: the logger you want to use. Defaults to the global logger.
	* myspecialfunlogfilename: if you want to log `myspecialfun` to a file specify its name. When not specified the global logger is used 
	* myspecialfunlogfilemode: the mode you want to use to write to a file. Defaults to "w" (cf. [write modes](https://docs.julialang.org/en/v1/base/io-network/#Base.open))
	"""
	function logging_demo_2(args...; globallogger=Logging.global_logger(), 
									 extraloggerfilename::Union{Nothing, String}=nothing,
									 extraloggerwritemode::Union{Nothing, String}=nothing,
									 outstream::Union{Nothing, IO} = !isnothing(extraloggerfilename) && !isnothing(extraloggerwritemode) ? open(extraloggerfilename, extraloggerwritemode) : nothing,
									 maxrep=3,
									 kwargs...)
		# direct all the following messages to the selected logger
		with_logger(globallogger) do
			# log message for the global logger
			@info "logging_demo_2 was invoked with:\n\t- args: $(args)\n\t- kwargs: $(kwargs)\n\t- using logger <$(globallogger)> (current logger's lowest level: $(Logging.min_enabled_level(globallogger)))"
			
			# verify if a special logger should be used
			speciallogger = isnothing(outstream) ? globallogger : SimpleLogger(outstream)
			
			# run the function with the appropriate logger
			with_logger(speciallogger) do
				for i in 1:maxrep
					myspecialfun(i; speciallogger=speciallogger)
				end
			end
			
			# close outstream if required
			isnothing(outstream) ? nothing : close(outstream)
		end
	end

	"""
		myspecialfun(args...; kwargs...)
	
	a function that generates log messages
	"""
	function myspecialfun(args...; kwargs...)
		@info "myspecialfun was invoked with:\n\t- args: $(args)\n\t- kwargs: $(kwargs)\n\t- using logger <$(kwargs[:speciallogger])> "
	end

	nothing
end

# ╔═╡ fec37932-89b5-4cd2-a472-aea8c07856a4
# DEMO 2a - USING LOGGING DEFAULT SETTINGS
logging_demo_2(1,2, goedemorgen="bonjour", maxrep=2)

# ╔═╡ e3eae0ce-1462-11eb-2e02-fd2f746569d1
# DEMO 2a - USING LOGGING TO FILE SETTINGS
logging_demo_2(1,2, goedemorgen="bonjour", 
				extraloggerfilename="./Exercises/logging_demo_2.log",
				extraloggerwritemode="a+",
				maxrep=2)

# ╔═╡ dd63ff16-146d-11eb-059c-0586e1f972a5
md"""
## Working with resumable functions
Using a resumable function, try to implement:
1. the pascal triangle: each iteration should return a line of the Pascal triangle.
2. a root finding method (e.g. square root of a number)

*Note*: a resumable function returns an iterator you need to call.
"""

# ╔═╡ 010af16a-1474-11eb-10dc-292a149988f1
begin
	@resumable function pascal()
		# two initial values
		a = [1]
		@yield a
		a = [1,1]
		@yield a
		# all the following values
		while true
			a = vcat([1],a[1:end-1] .+ a[2:end],[1])
			@yield a
		end
	end
	
	p = pascal()
	println("Pascal's triangle:")
	for i in 1:10
		println(p())
	end
end

# ╔═╡ 363eba24-1474-11eb-26b8-718eed4e5f21
begin
	@resumable function findroot(x0::Number)
		# note: based on Newton's method
		res = x0
		@yield res
		while true
			res = res - (res^2 - x0) / (2*res)
			@yield res
		end  
	end

	r = findroot(5)
	println("evolution of absolute error")
	for i in 0:10
		println("Iteration $(i): $(abs(sqrt(5) - r()) )")
	end
end

# ╔═╡ 0368ea70-145b-11eb-0b5c-fb3a33bf2027
md"""
# ConcurrentSim
Before starting a larger project, we will look into some ConcurrentSim tricks.

There are some compatibility issues between Pluto and more complex ConcurrentSim constructions, which is why you will find specific examples in a seperate file.

You can execute these file by running them from the REPL by using 
```julia
include("path/to/file.jl")
```

"""

# ╔═╡ 9da38750-146d-11eb-0757-2318eb6520ca
md"""
## Working with `containers`

Containers represent a level of something (e.g. liquid level, energy ...). If you want to store a specific type of object, you will be better of using a `store`.

Experiment a bit with containers (::Container). Discover their attributes (environment, capacity, level, get\_queue, put\_queue, seid) and find out how to use them. Generate a simple setting with:
1. a fill process that waits for a random time $t < 10 \in \mathbb{N}$ and then adds 1 unit to a container. This process repeats forever.
2. an empty process that waits for a random time $t < 10 \in \mathbb{N}$ and then requires a random amount from the container. This process repeats forever.
3. a monitor proces that periodically prints an info message detailing the current level of the container. This process repeats forever.
"""

# ╔═╡ 73f24a8e-146f-11eb-2978-cfef033adae1
let
	@resumable function fill(sim::Simulation, c::Container)
		while true 
			@yield timeout(sim, rand(1:10))
			@yield put(c,1)
			@info "$(now(sim)) - item added to the container"
		end
	end

	@resumable function empty(sim::Simulation, c::Container)
		while true
			@yield timeout(sim, rand(1:10))
			n = rand(1:3)
			@info "$(now(sim)) - Filed a request for $(n) items"
			@yield get(c,n)
			@info "$(now(sim)) - Got my $(n) items"
		end
	end

	@resumable function monitor(sim::Simulation, c::Container)
		while true
			@info "$(now(sim)) - current container level: $(c.level)/$(c.capacity)"
			@yield timeout(sim, 1)
		end
	end
	
	
	# fix random seed for reproducibility
	Random.seed!(175)

	# setup the simulation
	@info "\n$("-"^70)\nWorking with containers\n$("-"^70)\n"
	sim = Simulation()
	c = Container(sim,10)
	@process fill(sim,c)
	@process monitor(sim,c)
	@process empty(sim,c)
	run(sim,30)
end

# ╔═╡ 71911828-1470-11eb-3519-bb52522ed2c9
md"""
## Working with `Stores`
A store can hold objects (struct) that can be used by other processes. Let's reconsider the same small scale application we did with the containers, i.e. generate a simple setting and verify everything works as intended (e.g. a fill, empty and monitor process). 
"""

# ╔═╡ fbfed3c4-1470-11eb-0f28-231b891d0d9b
let
	# our own type of object
	struct Object
		id::Int
	end

	@resumable function fill(sim::Simulation, s::Store)
		i = 0
		while true 
			i += 1
			item = Object(i)
			@yield timeout(sim, rand(1:10))
			@yield put(s,item)
			@info "$(now(sim)) - item $(item) added to the store"
		end
	end
	
	@resumable function empty(sim::Simulation, s::Store)
		while true
			@yield timeout(sim, rand(1:10))
			n = rand(1:3)
			@info "$(now(sim)) - filed my request for $(n) items"
			for _ in 1:n
				@yield get(s)
			end
			@info "$(now(sim)) - Got my $(n) items"
		end
	end
	
	@resumable function monitor(sim::Simulation, s::Store)
		while true
			@info "$(now(sim)) - current store level: $(length(s.items))/$(s.capacity)"
			@yield timeout(sim, 1)
		end
	end
	
	# fix random seed for reproduction
	Random.seed!(175)
	
	# setup the simulation
	@info "\n$("-"^70)\nWorking with stores\n$("-"^70)\n"
	sim = Simulation()
	s = Store{Object}(sim, capacity=UInt(10))
	
	@process fill(sim, s)
	@process empty(sim, s)
	@process monitor(sim, s)
	run(sim,30)
	
end

# ╔═╡ 118eecdc-146d-11eb-1d4b-71b301d4d5e6
md"""
## Process dependencies
Below you have an illustration of a process waiting for another one to terminate before continuing.
"""

# ╔═╡ 363592fc-146d-11eb-2dde-d56c18095702
let
	@resumable function basic(sim::Simulation)
    	@info "$(now(sim)) - Basic goes to work"
    	p = @process bottleneck(sim)
    	@yield p
    	@info "$(now(sim)) - Basic continues after bottleneck completion"
	end

	@resumable function bottleneck(sim::Simulation)
   		@yield timeout(sim, 10)
	end
	
	@info "\n$("-"^70)\nProcess dependencies\n$("-"^70)\n"
	sim = Simulation()
	@process basic(sim)
	run(sim)
end

# ╔═╡ ddd43e36-1473-11eb-2544-8f9e1ac0f59c
md"""
## Linking a process to a type
We want to simulate the life of a puppy. It's life consists of three activities:
eating, sleeping and playing. This simple life can be disturbed (i.e. interrupted) 
when it gets picked up by a human. If a puppy likes you, it might lick your face. 
After being picked up, a puppy continues its life as before.

We create our own type `Puppy` that has an associated process that models its life. 
We also create a type `Human` that has an associated process to pick up a random 
puppy from time to time.

This application illustrates how you can interrupt an ongoing process and even do 
something with the cause of the interruption (in this case keeping track of who 
got liked by a puppy).

```julia
include("path/to/PS07 - ConcurrentSim - Puppies.jl")
```


"""

# ╔═╡ 4f9fee58-1536-11eb-1a4d-bd94541cb767
md"""
### Waiting on more than one event

We want to simulate a number of machines that each produce a specific product and 
put it in a warehouse (a `Store`). There is a combination process that needs one
of each generated products and combines it into another. The simulation ends when
the fictive container of combined goods is full.

We create our own type `Product` with two fields that allow to identify the kind of
product and to identify its "creator" by means of a serial number.
We also create a type `Machine` that has an associated process. This machine has
an ID an make one type of products. All generated product are put into the same 
store. 

The combiner process works as follows:
* generate the events matching the availability of one of each product
* wait until all of these events are realised. *Note*: if you only have two events, you can simply use `ev1` & `ev2`.
* generate the event of putting a fictive combined product in a container
* @yield the event (i.e. time-out until done)
* verify if the container is full and if so stop the simulation on this event.

This application illustrates how you can wait on multiple other events before 
continuing the simulation. Keep in mind that this requires ALL events to be 
processed.

```julia
include("path/to/PS07 - ConcurrentSim - Machines.jl")
```
"""

# ╔═╡ 63db05d2-1546-11eb-169c-7b23fe0009c4
md"""
### What if only one event needs to be realised?
Suppose an agent requests a resource but only has a limited amount of patience before no longer wanting/needing the resource.

For the example, a simulation is made with a `::Resource` with a capacity of $0$. So the agent can never obtain the requested resource. In the `agent` function the following happens:
1. A request for `r::Resource` is made. The type of `req` is `ConcurrentSim.Put`. This event will be triggered by an `@yield`
2. the variable `res` is a dictionary with the events as key and the `::StateValue` as value. The first event to have been processed will have its `::StateValue` equal to `ConcurrentSim.processed`
3. the `if` conditions test whether the `::StateValue` of our request is equal to `ConcurrentSim.processed`. 
  1. If this is the case, the agent obtains the `::Resource`, uses it for 1 time unit and releases it back for further use.
  2. If this is NOT the case, the other event will have taken place (in this case the timeout) and we remove the request from the `::Resource` queue with `cancel`.
4. the simulation terminates since no more processes are active on time 4.0.

"""

# ╔═╡ 9abf31ea-1546-11eb-3ff2-41ad2484a04b
let
	@resumable function agent(env::Environment,r::Resource)
		req = request(r)
		res = @yield req | timeout(env, 4)
		if res[req].state == ConcurrentSim.processed
			@info "$(env.time) - Agent is using the resource..."
			@yield timeout(env,1)
			release(r)
			@info "$(env.time) - Agent released the resource."
		else
			@info "$(env.time) - Patience ran out..."
			cancel(r, req)
		end
	end
	
	function runsim()
		@info "\n$("-"^70)\nOne of both events\n$("-"^70)\n"
		sim = Simulation()
		r = Resource(sim,0)
		@process agent(sim, r)
		run(sim,10)
	end
	
	runsim()
end

# ╔═╡ a955fd5c-1536-11eb-0405-9bc433188115
md"""
### Using the first available resource

We want to simulate a number of warehouses that store the same product. At a regular
interval, a product is required. But the origin of the product does not matter.

We create our own type `Warehouse` with two field that allow to identify the 
warehouse and that allow to track its stock by by means of a `Store`.

The production process works adds a random quantity to a random warehouse 
(the first available) and works as follows:
* generate a product
* generate the requests for all resources
* yield the requests the will occur first. *note*: if two events occur at the same time, they will both happen. We deal with this later.
* cancel all the other requests that have not occured yet. For those that have occured,
we decrement the store with the value it was increased by.

The simulation stops when either all warehouses are full (or cannot handle the 
produced quantity).

A similar approach can be followed when dealing with `get` requests instead of
`put` requests.

This application illustrates how you can deal with resource concurrency,
i.e. taking whatever resource(s) come(s) available first without blocking the
other ones or introducing unwanted artifacts.

```julia
include("path/to/PS07 - ConcurrentSim - Warehouse.jl")
```

"""

# ╔═╡ 418601ce-8469-4cad-967b-73cba91d566e
md"""
### Minimalistic evacuation simulation
We build a small simulation in which victims are generated and evacuated to a nearby hospital.

```Julia
include("path/to/PS07 - ConcurrentSim - Ambulances.jl")
```

"""

# ╔═╡ 2bc8a711-3c47-4969-8755-80364148387b
md"""
### Minimalistic parachute life cycle simulation
We build a small simulation to model the life cycle of a parachute. his application illustrates how you can transfer objects between stores and act on them.

```Julia
include("path/to/PS07 - ConcurrentSim - Parachutes.jl")
```

"""

# ╔═╡ 3a41b319-0d19-4ddd-b6da-c6c53212fe54
md"""
### Minimalistic simulation with priorities
We build a small simulation in which different jobs are generated. These jobs can have different priorities. Each day we will look for tasks that are scheduled. The ones with the highest priority are done first.

This application illustrates how you can work with stores and priorities.


```Julia
include("path/to/PS07 - ConcurrentSim - Jobman.jl")
```
"""

# ╔═╡ 414b4ee2-1473-11eb-3d7b-ef4f49e7efa0
md"""
## Exercises

"""

# ╔═╡ 4bf1fce0-1470-11eb-1290-63d06c8246a2
md"""
### Application 1
Consider a candy machines that is continuously being monitored by a supervisor.  If the level is below a given treshold, the supervisor fills the machine up. 
* Client arrival follows an exponential distribution with parameter $\theta = 1$ and each client takes two candies at a time.
* Look at the mean time between refills. Is this what you would expect?
* What happens when the amount of candy varies?  Is this still what you would expect? E.g. a clients takes one, two or three candies.
"""

# ╔═╡ f3c8a4ba-1474-11eb-06b0-7f0e5ba47670


# ╔═╡ c7b95ece-150e-11eb-0058-c15fde632ea0
md"""
### Application 2
When modeling physical things such as cables, RF propagation, etc. encapsulation of this process is better in order to keep the propagation mechanism outside of the sending and receiving processes.

Consider the following:
* a sender sends messages on a regular interval (e.g. every 5 minutes)
* a receiver is listening on a permanent basis for new messages
* the transfer between both of them is not instantaneous, but takes some time. To model this, you can store (hint: use a `::Store`) the messages on the cable for later reception.

"""

# ╔═╡ 25a78e3a-1511-11eb-2239-1b938a2129fa


# ╔═╡ Cell order:
# ╟─9cda8f1c-2394-42bf-883c-4dbe5df8ae56
# ╠═4de0ee11-f8af-4865-8737-ba0dc5c3404e
# ╟─c395df98-145a-11eb-1716-2de187df1a1a
# ╠═dafa45ae-1462-11eb-3338-037167917f4d
# ╠═f23a3616-6b07-4853-8a77-564cce1bacc7
# ╠═0560f32a-1462-11eb-0685-09e4f341ddf5
# ╠═8ddac37c-1465-11eb-17d4-fdce80dc78fe
# ╠═b05f57c2-1466-11eb-272f-5fc93c04c744
# ╠═19b12fc6-1464-11eb-2fc1-cbb3f82479c5
# ╠═fec37932-89b5-4cd2-a472-aea8c07856a4
# ╠═e3eae0ce-1462-11eb-2e02-fd2f746569d1
# ╟─dd63ff16-146d-11eb-059c-0586e1f972a5
# ╠═010af16a-1474-11eb-10dc-292a149988f1
# ╠═363eba24-1474-11eb-26b8-718eed4e5f21
# ╟─0368ea70-145b-11eb-0b5c-fb3a33bf2027
# ╟─9da38750-146d-11eb-0757-2318eb6520ca
# ╠═73f24a8e-146f-11eb-2978-cfef033adae1
# ╟─71911828-1470-11eb-3519-bb52522ed2c9
# ╠═fbfed3c4-1470-11eb-0f28-231b891d0d9b
# ╟─118eecdc-146d-11eb-1d4b-71b301d4d5e6
# ╠═363592fc-146d-11eb-2dde-d56c18095702
# ╟─ddd43e36-1473-11eb-2544-8f9e1ac0f59c
# ╟─4f9fee58-1536-11eb-1a4d-bd94541cb767
# ╟─63db05d2-1546-11eb-169c-7b23fe0009c4
# ╠═9abf31ea-1546-11eb-3ff2-41ad2484a04b
# ╟─a955fd5c-1536-11eb-0405-9bc433188115
# ╟─418601ce-8469-4cad-967b-73cba91d566e
# ╟─2bc8a711-3c47-4969-8755-80364148387b
# ╟─3a41b319-0d19-4ddd-b6da-c6c53212fe54
# ╟─414b4ee2-1473-11eb-3d7b-ef4f49e7efa0
# ╟─4bf1fce0-1470-11eb-1290-63d06c8246a2
# ╠═f3c8a4ba-1474-11eb-06b0-7f0e5ba47670
# ╟─c7b95ece-150e-11eb-0058-c15fde632ea0
# ╠═25a78e3a-1511-11eb-2239-1b938a2129fa
