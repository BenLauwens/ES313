### A Pluto.jl notebook ###
# v0.12.4

using Markdown
using InteractiveUtils

# ╔═╡ 92928394-1462-11eb-04fd-557587660fc2
using Logging

# ╔═╡ 3cc48592-146d-11eb-1546-cd39a0f8e407
using SimJulia, ResumableFunctions

# ╔═╡ 73f24a8e-146f-11eb-2978-cfef033adae1
let
	@resumable function fill(sim::Simulation, c::Container)
		while true 
			@yield timeout(sim,rand(1:10))
			@yield put(c,1)
			@info "item added to the container on time $(now(sim))"
		end
	end

	@resumable function empty(sim::Simulation, c::Container)
		while true
			@yield timeout(sim,rand(1:10))
			n = rand(1:3)
			@info "Filed my request for $(n) items on time $(now(sim))"
			@yield get(c,n)
			@info "Got my $(n) items on time $(now(sim))"
		end
	end

	@resumable function monitor(sim::Simulation, c::Container)
		while true
			@info "$(now(sim)) - current container level: $(c.level)/$(c.capacity)"
			@yield timeout(sim,1)
		end
	end
	
	# setup the simulation
	# fix random seed for reproduction
	using Random
	Random.seed!(173)
	
	@info "\n$("-"^70)\nWorking with containers\n$("-"^70)\n"
	sim = Simulation()
	c = Container(sim,10)
	@process fill(sim,c)
	@process monitor(sim,c)
	@process empty(sim,c)
	run(sim,30)
end

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
			@yield timeout(sim,rand(1:10))
			@yield put(s,item)
			@info "item $(item) added to the store on time $(now(sim))"
		end
	end
	
	@resumable function empty(sim::Simulation, s::Store)
		while true
			@yield timeout(sim,rand(1:10))
			n = rand(1:3)
			@info "Filed my request for $(n) items on time $(now(sim))"
			for _ in 1:n
				@yield get(s)
			end
			@info "Got my $(n) items on time $(now(sim))"
		end
	end
	
	@resumable function monitor(sim::Simulation, s::Store)
		while true
			@info "$(now(sim)) - current store level: $(length(s.items))/$(s.capacity)"
			@yield timeout(sim,1)
		end
	end
	
	# fix random seed for reproduction
	using Random
	Random.seed!(173)
	
	# setup the simulation
	@info "\n$("-"^70)\nWorking with stores\n$("-"^70)\n"
	sim = Simulation()
	s = Store{Object}(sim, capacity=UInt(10))
	
	@process fill(sim, s)
	@process empty(sim, s)
	@process monitor(sim, s)
	run(sim,30)
	
end

# ╔═╡ 951f3fc2-1538-11eb-3430-656e7a5c950a
using Distributions

# ╔═╡ c395df98-145a-11eb-1716-2de187df1a1a
md"""
# Logging
The [Logging](https://docs.julialang.org/en/v1/stdlib/Logging/index.html) module will be used for efficient debugging and testing during development. 

A logger has its own lower bound on the `LogLevel` that it can show. In addition to this, there is a global setting that determines the lowest level that will be registered.

Below you find some practical examples of using this module.
"""

# ╔═╡ dafa45ae-1462-11eb-3338-037167917f4d
disable_logging(LogLevel(-5001))

# ╔═╡ 0560f32a-1462-11eb-0685-09e4f341ddf5
"""
	logdemo1()

A small demo where everything is run on a single logger. Keep in mind when using the global logger, that its lowest level is `Info` (`LogLevel(0)`), so you won't see anything below. 

Also keep in mind that you need to modify the global settings before you can see anything below `Debug`. You can do this with `disable_logging(LogLevel(N))`. 

### keywords
* logger: the logger you want to use. Defaults to the global logger.
"""
function logdemo1(args...; kwargs...)
	# direct all the following messages to my logger
	logger = get(kwargs, :logger, Logging.global_logger())
	with_logger(logger) do
		# print some information about the function
		@info "logdemo1 was invoked with:\n\t- args: $(args)\n\t- kwargs: $(kwargs)\n\t- using logger <$(logger)> (current logger's lowest level: $(Logging.min_enabled_level(logger)))"
		@debug "logdemo1 lowest level message that allows the debug level"
		@logmsg LogLevel(-2000) "not visible by default"
	end
end

# ╔═╡ 8ddac37c-1465-11eb-17d4-fdce80dc78fe
begin
	println("DEMO 1a - USING LOGGING DEFAULT SETTINGS\n$("-"^70)\n\n")
	logdemo1(1,2, goedemorgen="bonjour")
	println("-"^70)
end

# ╔═╡ b05f57c2-1466-11eb-272f-5fc93c04c744
begin 
	println("DEMO 1b - USING A SPECIFIC LOGGER THAT WILL SHOW THE LAST MESSAGE\n$("-"^70)\n\n")
	customlogger = Logging.SimpleLogger(stdout, LogLevel(-2000))
	logdemo1(3,4,logger=customlogger, goedenavond="bonsoir")
	println("-"^70)
end

# ╔═╡ 19b12fc6-1464-11eb-2fc1-cbb3f82479c5
begin
	"""
		logdemo2()

	A small demo where it is possible to direct the logs generated by a specific function to a file. The can be very handy for debugging purposes or analysis after a simulation. By default everything is run on a single logger. 

	### keywords
	* logger: the logger you want to use. Defaults to the global logger.
	* myspecialfunlogfilename: if you want to log `myspecialfun` to a file specify its name. When not specified the global logger is used 
	* myspecialfunlogfilemode: the mode you want to use to write to a file. Defaults to "w" (cf. [write modes](https://docs.julialang.org/en/v1/base/io-network/#Base.open))
	"""
	function logdemo2(args...; kwargs...)
		# direct all the following messages to my logger
		logger = get(kwargs, :logger, Logging.global_logger())
		with_logger(logger) do
			# log message from the 
			@info "logdemo2 was invoked with:\n\t- args: $(args)\n\t- kwargs: $(kwargs)\n\t- using logger <$(logger)> (current logger's lowest level: $(Logging.min_enabled_level(logger)))"
			# verify if a special logger should be used
			if haskey(kwargs, :myspecialfunlogfilename)
				logname = kwargs[:myspecialfunlogfilename]
				logmode = get(kwargs, :myspecialfunlogfilemode, "w")
				io = open(logname, logmode)
				speciallogger = SimpleLogger(io)
			else
				speciallogger = logger
			end
			
			# run the function with the appropriate logger
			with_logger(speciallogger) do
				for i in 1:get(kwargs,:maxrep, 20)
					myspecialfun(i; speciallogger=speciallogger)
				end
			end
			
			# close io if required
			if haskey(kwargs, :myspecialfunlogfilename)
				close(io)
			end
		end
	end

	"""
		myspecialfun(args...; kwargs...)
	
	a function that generates log messages
	
	### keywords
	"""
	function myspecialfun(args...; kwargs...)
		@info "myspecialfun was invoked with:\n\t- args: $(args)\n\t- kwargs: $(kwargs)\n\t- using logger <$(kwargs[:speciallogger])> "
	end
end

# ╔═╡ e3eae0ce-1462-11eb-2e02-fd2f746569d1
begin
	println("DEMO 2a - USING LOGGING DEFAULT SETTINGS\n$("-"^70)\n\n")
	logdemo2(1,2, goedemorgen="bonjour")
	println("-"^70)
end

# ╔═╡ 12710aa4-146b-11eb-034a-97b515563abc
begin
	println("DEMO 2b - USING LOGGING TO FILE SETTINGS\n$("-"^70)\n\n")
	logdemo2(1,2, myspecialfunlogfilename="demo2.log", maxrep=10)
	println("-"^70)
end

# ╔═╡ 0368ea70-145b-11eb-0b5c-fb3a33bf2027
md"""
# SimJulia
Before starting a larger project, we will look into some SimJulia tricks.

There are some compatibility issues between Pluto and more complex SimJulia constructions, which is why you will find specific examples in a seperate file.

You can execute these file by running them from the REPL by using 
```julia
include("path/to/file.jl")
```

"""

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

# ╔═╡ 9da38750-146d-11eb-0757-2318eb6520ca
md"""
## Working with `containers`

Containers represent a level of something (e.g. liquid level, energy ...). If you want to store a specific type of object, you will be better of using a `store`.

Experiment a bit with containers (::Container). Discover their attributes (environment, capacity, level, get\_queue, put\_queue, seid) and find out how to use them. Generate a simple setting with:
1. a fill process that waits for a random time $t < 10 \in \mathbb{N}$ and then adds 1 unit to a container. This process repeats forever.
2. an empty process that waits for a random time $t < 10 \in \mathbb{N}$ and then requires a random amount from the container. This process repeats forever.
3. a monitor proces that periodically prints an info message detailing the current level of the container. This process repeats forever.
"""

# ╔═╡ 71911828-1470-11eb-3519-bb52522ed2c9
md"""
## Working with `Stores`
A store can hold objects (struct) that can be used by other processes. Let's reconsider the same small scale application we did with the containers, i.e. generate a simple setting and verify everything works as intended (e.g. a fill, empty and monitor process). 
"""

# ╔═╡ 118eecdc-146d-11eb-1d4b-71b301d4d5e6
md"""
## Process dependencies
Below you have an illustration of a process waiting for another one to terminate before continuing.
"""

# ╔═╡ 363592fc-146d-11eb-2dde-d56c18095702
let
	@resumable function basic(sim::Simulation)
    	@info "Basic goes to work on time $(now(sim))"
    	p = @process bottleneck(sim)
    	@yield p
    	@info "Basic continues after bottleneck completion on time $(now(sim))"
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
include("path/to/puppies.jl")
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
include("path/to/machines.jl")
```
"""

# ╔═╡ 63db05d2-1546-11eb-169c-7b23fe0009c4
md"""
### What if only one event needs to be realised?
Suppose an agent requests a resource but only has a limited amount of patience before no longer wanting/needing the resource.

For the example, a simulation is made with a `::Resource` with a capacity of $0$. So the agent can never obtain the requested resource. In the `agent` function the following happens:
1. A request for `r::Resource` is made. The type of `req` is `SimJulia.Put`. This event will be triggered by an `@yield`
2. the variable `res` is a dictionary with the events as key and the `::StateValue` as value. The first event to have been processed will have its `::StateValue` equal to `SimJulia.processed`
3. the `if` conditions test whether the `::StateValue` of our request is equal to `SimJulia.processed`. 
  1. If this is the case, the agent obtains the `::Resource`, uses it for 1 time unit and releases it back for further use.
  2. If this is NOT the case, the other event will have taken place (in this case the timeout) and we remove the request from the `::Resource` queue with `cancel`.
4. the simulation terminates since no more processes are active on time 4.0.

"""

# ╔═╡ 9abf31ea-1546-11eb-3ff2-41ad2484a04b
let
	@resumable function agent(env::Environment,r::Resource)
		req = request(r)
		res = @yield req | timeout(env, 4)
		if res[req].state == SimJulia.processed
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
include("path/to/warehouse.jl")
```

"""

# ╔═╡ 414b4ee2-1473-11eb-3d7b-ef4f49e7efa0
md"""
## Exercises

"""

# ╔═╡ 4bf1fce0-1470-11eb-1290-63d06c8246a2
md"""
#### Application 1
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


# ╔═╡ de71f9fa-150e-11eb-01a5-ab89ea762405


# ╔═╡ Cell order:
# ╟─c395df98-145a-11eb-1716-2de187df1a1a
# ╠═92928394-1462-11eb-04fd-557587660fc2
# ╠═dafa45ae-1462-11eb-3338-037167917f4d
# ╠═0560f32a-1462-11eb-0685-09e4f341ddf5
# ╠═8ddac37c-1465-11eb-17d4-fdce80dc78fe
# ╠═b05f57c2-1466-11eb-272f-5fc93c04c744
# ╠═19b12fc6-1464-11eb-2fc1-cbb3f82479c5
# ╠═e3eae0ce-1462-11eb-2e02-fd2f746569d1
# ╠═12710aa4-146b-11eb-034a-97b515563abc
# ╟─0368ea70-145b-11eb-0b5c-fb3a33bf2027
# ╠═3cc48592-146d-11eb-1546-cd39a0f8e407
# ╟─dd63ff16-146d-11eb-059c-0586e1f972a5
# ╠═010af16a-1474-11eb-10dc-292a149988f1
# ╠═363eba24-1474-11eb-26b8-718eed4e5f21
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
# ╟─414b4ee2-1473-11eb-3d7b-ef4f49e7efa0
# ╟─4bf1fce0-1470-11eb-1290-63d06c8246a2
# ╠═951f3fc2-1538-11eb-3430-656e7a5c950a
# ╠═f3c8a4ba-1474-11eb-06b0-7f0e5ba47670
# ╟─c7b95ece-150e-11eb-0058-c15fde632ea0
# ╠═25a78e3a-1511-11eb-2239-1b938a2129fa
# ╠═de71f9fa-150e-11eb-01a5-ab89ea762405
