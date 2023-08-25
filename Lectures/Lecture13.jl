### A Pluto.jl notebook ###
# v0.19.27

using Markdown
using InteractiveUtils

# ╔═╡ 82b07d30-0faf-11eb-3b48-2dccf08d0545
begin
	using Pkg
	cd(joinpath(dirname(@__FILE__),".."))
  Pkg.activate(pwd())
  using ResumableFunctions
  using ConcurrentSim
	using Logging
end

# ╔═╡ ef11256b-c5ee-43d4-8757-918a05ad3d1d
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

# ╔═╡ 1546ff80-0faf-11eb-2e03-a3ed4337a0df
md"""# ConcurrentSim
## Basic Concepts

ConcurrentSim is a discrete-event simulation library. The behavior of active components (like vehicles, customers or messages) is modeled with processes. All processes live in an environment. They interact with the environment and with each other via events.

Processes are described by `@resumable` functions. You can call them process function. During their lifetime, they create events and `@yield` them in order to wait for them to be triggered."""

# ╔═╡ 57765b80-0faf-11eb-2e25-f9d8a95128be
@resumable function fibonacci(n::Int) :: Int
    a = 0
    b = 1
    for i in 1:n
        @yield a
        a, b = b, a+b
    end
end

# ╔═╡ 996923b0-0faf-11eb-0b98-b9c64f28e5c0
fib = fibonacci(5);

# ╔═╡ a83919e2-0faf-11eb-17ef-a3eac492c533
fib()

# ╔═╡ a3a70ea2-0faf-11eb-33c8-dd40db996416
fib()

# ╔═╡ abd7c470-0faf-11eb-071e-4535258ede59
fib()

# ╔═╡ ad4f4940-0faf-11eb-22b9-0b324557463d
fib()

# ╔═╡ aebda650-0faf-11eb-0ee5-074a408638d7
let
	io = IOBuffer()
	for fib in fibonacci(10)
		print(io, fib, " ")
	end
	String(take!(io))
end

# ╔═╡ e85462f0-0faf-11eb-0d54-e52e8c1e9b26
md"""When a process yields an event, the process gets suspended. ConcurrentSim resumes the process, when the event occurs (we say that the event is triggered). Multiple processes can wait for the same event. ConcurrentSim resumes them in the same order in which they yielded that event.

An important event type is the `timeout`. Events of this type are scheduled after a certain amount of (simulated) time has passed. They allow a process to sleep (or hold its state) for the given time. A `timeout` and all other events can be created by calling a constructor having the environment as first argument."""

# ╔═╡ 0153c520-0fb0-11eb-1253-0bd7e9dd04ee
md"""## Our First Process

Our first example will be a car process. The car will alternately drive and park for a while. When it starts driving (or parking), it will print the current simulation time.

So let’s start:"""

# ╔═╡ 105133ee-0fb0-11eb-1eba-238a216c5182
@resumable function car(env::Environment)
    while true
        @info("Start parking at $(now(env))")
        parking_duration = 5
        @yield timeout(env, parking_duration)
        @info("Start driving at $(now(env))")
        trip_duration = 2
        @yield timeout(env, trip_duration)
    end
end

# ╔═╡ 18ba5ee0-0fb0-11eb-1c6d-e1ced026d640
md"""Our car process requires a reference to an `Environment` in order to create new events. The car‘s behavior is described in an infinite loop. Remember, the car function is a `@resumable function`. Though it will never terminate, it will pass the control flow back to the simulation once a `@yield` statement is reached. Once the yielded event is triggered (“it occurs”), the simulation will resume the function at this statement.

As said before, our car switches between the states parking and driving. It announces its new state by printing a message and the current simulation time (as returned by the function call `now`). It then calls the constructor `timeout` to create a timeout event. This event describes the point in time the car is done parking (or driving, respectively). By yielding the event, it signals the simulation that it wants to wait for the event to occur.

Now that the behavior of our car has been modeled, lets create an instance of it and see how it behaves:"""

# ╔═╡ 2326d3e2-0fb0-11eb-1827-6d08b4032c34
let sim = Simulation()
	@process car(sim)
	run(sim, 15)
end

# ╔═╡ 31d8458e-0fb0-11eb-0fe5-0b2a1a5d56c3
md"""The first thing we need to do is to create an environment, e.g. an instance of `Simulation`. The macro `@process` having as argument a car process function call creates a process that is initialised and added to the environment automatically.

Note, that at this time, none of the code of our process function is being executed. Its execution is merely scheduled at the current simulation time.

The `Process` returned by the `@process` macro can be used for process interactions.

Finally, we start the simulation by calling run and passing an end time to it."""

# ╔═╡ b106b67e-0fb0-11eb-04f2-a734c4fa2e3b
md"""## Process Interaction

The `Process` instance that is returned by `@process` macro can be utilized for process interactions. The two most common examples for this are to wait for another process to finish and to interrupt another process while it is waiting for an event.

### Waiting for a Process

As it happens, a ConcurrentSim `Process` can be used like an event. If you yield it, you are resumed once the process has finished. Imagine a car-wash simulation where cars enter the car-wash and wait for the washing process to finish, or an airport simulation where passengers have to wait until a security check finishes.

Lets assume that the car from our last example is an electric vehicle. Electric vehicles usually take a lot of time charging their batteries after a trip. They have to wait until their battery is charged before they can start driving again.

We can model this with an additional charge process for our car. Therefore, we redefine our car process function and add a charge process function.

A new charge process is started every time the vehicle starts parking. By yielding the `Process` instance that the `@process` macro returns, the run process starts waiting for it to finish:"""

# ╔═╡ c5df5262-0fb0-11eb-2125-755ecf44ff81
@resumable function charge(env::Environment, duration::Number)
    @yield timeout(env, duration)
end

# ╔═╡ d80b92f0-0fb0-11eb-04f5-1d40f00d07b8
@resumable function car2(env::Environment)
    while true
        @info("Start parking and charging at $(now(env))")
        charge_duration = 5
        charge_process = @process charge(env, charge_duration)
        @yield charge_process
        println("Start driving at $(now(env))")
        trip_duration = 2
        @yield timeout(env, trip_duration)
    end
end

# ╔═╡ bc5dbd20-0fb1-11eb-0bda-c3e4c7877daa


# ╔═╡ eda6bb80-0fb0-11eb-2f87-d586f0b69f26
md"""Starting the simulation is straightforward again: We create a `Simulation`, one (or more) cars and finally call `run`."""

# ╔═╡ f67c3cce-0fb0-11eb-3349-4181800dde90
let sim = Simulation()
	@process car2(sim)
	run(sim, 15)
end;

# ╔═╡ 061cc970-0fb1-11eb-0210-d7d0f215be77
md"""### Interrupting Another Process

Imagine, you don’t want to wait until your electric vehicle is fully charged but want to interrupt the charging process and just start driving instead.

ConcurrentSim allows you to interrupt a running process by calling the `interrupt` function:"""

# ╔═╡ 16770920-0fb1-11eb-1551-67668809b19a
@resumable function driver(env::Environment, car_process::Process)
    @yield timeout(env, 3)
    @yield interrupt(car_process)
end

# ╔═╡ 32c0db60-0fb1-11eb-3d75-f1a189baf482
md"""The driver process has a reference to the car process. After waiting for 3 time steps, it interrupts that process.

Interrupts are thrown into process functions as `Interrupt` exceptions that can (should) be handled by the interrupted process. The process can then decide what to do next (e.g., continuing to wait for the original event or yielding a new event):"""

# ╔═╡ ce847f70-0fb1-11eb-144b-6b9542b72e9b
@resumable function car3(env::Environment)
    while true
        @info("Start parking and charging at $(now(env))")
        charge_duration = 5
        charge_process = @process charge(env, charge_duration)
        try
            @yield charge_process
        catch
            @info("Was interrupted. Hopefully, the battery is full enough ...")
        end
        @info("Start driving at $(now(env))")
        trip_duration = 2
        @yield timeout(env, trip_duration)
    end
end

# ╔═╡ f8b8f0ee-0fb1-11eb-13d6-571cad22a19a
md"""When you compare the output of this simulation with the previous example, you’ll notice that the car now starts driving at time 3 instead of 5:"""

# ╔═╡ 05760cb2-0fb2-11eb-2bc4-dd2a2bfde126
let sim = Simulation(), car_process = @process car3(sim)
	@process driver(sim, car_process)
	run(sim, 15)
end;

# ╔═╡ 1d92d712-0fb2-11eb-23fd-4554371e8a3b
md"""## Shared Resources

ConcurrentSim offers three types of resources that help you modeling problems, where multiple processes want to use a resource of limited capacity (e.g., cars at a fuel station with a limited number of fuel pumps) or classical producer-consumer problems.

In this section, we’ll briefly introduce ConcurrentSim’s Resource class.

### Basic Resource Usage

We’ll slightly modify our electric vehicle process car that we introduced in the last sections.

The car will now drive to a battery charging station (BCS) and request one of its two charging spots. If both of these spots are currently in use, it waits until one of them becomes available again. It then starts charging its battery and leaves the station afterwards:"""

# ╔═╡ 3778c8b0-0fb2-11eb-2c8f-379bf1d61719
@resumable function car4(env::Environment, name::Int, bcs::Resource, driving_time::Number, charge_duration::Number)
    @yield timeout(env, driving_time)
    @info("$name arriving at $(now(env))")
    @yield request(bcs)
    @info("$name starting to charge at $(now(env))")
    @yield timeout(env, charge_duration)
    @info("$name leaving the bcs at $(now(env))")
    @yield release(bcs)
end

# ╔═╡ 6e3a9360-0fb2-11eb-11dc-af7b71bd4184
md"""The resource’s `request` function generates an event that lets you wait until the resource becomes available again. If you are resumed, you “own” the resource until you release it.

You are responsible to call release once you are done using the resource. When you `release` a resource, the next waiting process is resumed and now “owns” one of the resource’s slots. The basic Resource sorts waiting processes in a FIFO (first in—first out) way.

A resource needs a reference to an `Environment` and a capacity when it is created.

We can now create the car processes and pass a reference to our resource as well as some additional parameters to them. 

Finally, we can start the simulation. Since the car processes all terminate on their own in this simulation, we don’t need to specify an until time — the simulation will automatically stop when there are no more events left:"""

# ╔═╡ 7845ae80-0fb2-11eb-195b-4d0d4ffca60b
let sim = Simulation(), bcs = Resource(sim, 2)
	for i in 1:4
		@process car4(sim, i, bcs, 2i, 5)
	end
	run(sim)
end

# ╔═╡ 9a77cd30-0fb2-11eb-1196-df634baf199d
md"""### Priority resource

As you may know from the real world, not every one is equally important. To map that to ConcurrentSim, the methods `request(res, priority=priority)` and `release(res, priority=priority)` lets requesting and releasing processes provide a priority for each request/release. More important requests/releases will gain access to the resource earlier than less important ones. Priority is expressed by integer numbers; smaller numbers mean a higher priority:"""

# ╔═╡ c8dbb78e-0fb2-11eb-1ed5-554d10df71a8
@resumable function resource_user(sim::Simulation, name::Int, res::Resource, wait::Float64, prio::Int)
  @yield timeout(sim, wait)
  @info("$name Requesting at $(now(sim)) with priority=$prio")
  @yield request(res, priority=prio)
  @info("$name got resource at $(now(sim))")
  @yield timeout(sim, 3.0)
  @yield release(res)
end

# ╔═╡ d683334e-0fb2-11eb-3dc4-4be3043674a7
let sim = Simulation(), res = Resource(sim, 1)
	@process resource_user(sim, 1, res, 0.0, 0)
	@process resource_user(sim, 2, res, 1.0, 0)
	@process resource_user(sim, 3, res, 2.0, -1)
	run(sim)
end

# ╔═╡ eff30a90-0fb2-11eb-01c6-c3a35033923d
md"""Although the third process requested the resource later than the second, it could use it earlier because its priority was higher."""

# ╔═╡ 066d6f8e-0fb3-11eb-0979-ab193faf5653
md"""### Containers

Containers help you modelling the production and consumption of a homogeneous, undifferentiated bulk. It may either be continuous (like water) or discrete (like apples).

You can use this, for example, to model the gas / petrol tank of a gas station. Tankers increase the amount of gasoline in the tank while cars decrease it.

The following example is a very simple model of a gas station with a limited number of fuel dispensers (modeled as `Resource`) and a tank modeled as `Container`:"""

# ╔═╡ 0a431330-0fb4-11eb-2795-2194b90087ee
struct GasStation
  fuel_dispensers :: Resource
  gas_tank :: Container{Float64}
  function GasStation(env::Environment)
    gs = new(Resource(env, 2), Container(env, 1000.0, level=100.0))
    return gs
  end
end

# ╔═╡ fa9830e0-0fb4-11eb-0098-5d09cf3ae3e2
@resumable function tanker(env::Environment, gs::GasStation)
  @yield timeout(env, 10.0)
  @info("Tanker arriving at $(now(env))")
  amount = gs.gas_tank.capacity - gs.gas_tank.level
  @yield put(gs.gas_tank, amount)
end

# ╔═╡ c3526920-0fb4-11eb-09cb-c320ebe70780
@resumable function monitor_tank(env::Environment, gs::GasStation)
  while true
    if gs.gas_tank.level < 100.0
      @info("Calling tanker at $(now(env))")
      @process tanker(env, gs)
    end
    @yield timeout(env, 15.0)
  end
end

# ╔═╡ 8c905050-0fb4-11eb-3218-ad71581a62e9
@resumable function car5(env::Environment, name::Int, gs::GasStation)
  @info("Car $name arriving at $(now(env))")
  @yield request(gs.fuel_dispensers)
  @info("Car $name starts refueling at $(now(env))")
  @yield get(gs.gas_tank, 40.0)
  @yield timeout(env, 15.0)
  @yield release(gs.fuel_dispensers)
  @info("Car $name done refueling at $(now(env))")
end

# ╔═╡ 214e781e-0fb5-11eb-10fe-2d8c3f9ce347
@resumable function car_generator(env::Environment, gs::GasStation)
  for i = 0:3
    @process car5(env, i, gs)
    @yield timeout(env, 5.0)
  end
end

# ╔═╡ 13ba2120-0fb3-11eb-0599-831b085542c8
let sim = Simulation()
	gs = GasStation(sim)
	@process car_generator(sim, gs)
	@process monitor_tank(sim, gs)
	run(sim, 55.0)
end

# ╔═╡ 461ec14e-0fb5-11eb-38f0-61ad30ab4e1e
md"""Priorities can be given to a `put` or a `get` event by setting the named argument priority."""

# ╔═╡ 5d04b960-0fb5-11eb-01fe-fd0ff58627f6
md"""### Stores

Using a `Store` you can model the production and consumption of concrete objects (in contrast to the rather abstract “amount” stored in a Container). A single `Store` can even contain multiple types of objects.

A custom function can also be used to filter the objects you get out of the `store`.

Here is a simple example modelling a generic producer/consumer scenario:"""

# ╔═╡ 4047da00-0fb5-11eb-23a2-19f13af4fac6
@resumable function producer(env::Environment, sto::Store)
  for i = 1:100
    @yield timeout(env, 2.0)
    @yield put(sto, "spam $i")
    @info("Produced spam at $(now(env))")
  end
end

# ╔═╡ 5824f8c0-0fb4-11eb-0073-15bcb8f48aec
@resumable function consumer(env::Environment, name::Int, sto::Store)
  while true
    @yield timeout(env, 1.0)
    @info("$name requesting spam at $(now(env))")
    item = @yield get(sto)
    @info("$name got $item at $(now(env))")
  end
end

# ╔═╡ 23885800-0fb4-11eb-0378-1191e7ec5ca8
let sim = Simulation()
	sto = Store{String}(sim, capacity=UInt(2))
	@process producer(sim, sto)
	consumers = [@process consumer(sim, i, sto) for i=1:2]
	run(sim, 5.0)
end

# ╔═╡ 835bf0b0-0fb5-11eb-2a68-275326c4e73c
md"""A `Store` with a filter on the `get` event can, for example, be used to model machine shops where machines have varying attributes. This can be useful if the homogeneous slots of a` Resource` are not what you need:"""

# ╔═╡ a2c77550-0fb5-11eb-10b3-151670af6203
struct Machine
  size :: Int
  duration :: Float64
end

# ╔═╡ ab861340-0fb5-11eb-29ff-45bc893e6e6f
@resumable function user(env::Environment, name::Int, sto::Store, size::Int)
  machine = @yield get(sto, (mach::Machine)->mach.size == size)
  @info("$name got $machine at $(now(env))")
  @yield timeout(env, machine.duration)
  @yield put(sto, machine)
  @info("$name released $machine at $(now(env))")
end

# ╔═╡ aff2bc30-0fb5-11eb-365f-7b96cdbce30e
@resumable function machineshop(env::Environment, sto::Store)
  m1 = Machine(1, 2.0)
  m2 = Machine(2, 1.0)
  @yield put(sto, m1)
  @yield put(sto, m2)
end

# ╔═╡ b54c3620-0fb5-11eb-2348-b9f57946f679
let sim = Simulation()
	sto = Store{Machine}(sim, capacity=UInt(2))
	ms = @process machineshop(sim, sto)
	users = [@process user(sim, i, sto, (i % 2) + 1) for i=0:2]
	run(sim)
end

# ╔═╡ Cell order:
# ╟─ef11256b-c5ee-43d4-8757-918a05ad3d1d
# ╟─1546ff80-0faf-11eb-2e03-a3ed4337a0df
# ╠═82b07d30-0faf-11eb-3b48-2dccf08d0545
# ╠═57765b80-0faf-11eb-2e25-f9d8a95128be
# ╠═996923b0-0faf-11eb-0b98-b9c64f28e5c0
# ╠═a83919e2-0faf-11eb-17ef-a3eac492c533
# ╠═a3a70ea2-0faf-11eb-33c8-dd40db996416
# ╠═abd7c470-0faf-11eb-071e-4535258ede59
# ╠═ad4f4940-0faf-11eb-22b9-0b324557463d
# ╠═aebda650-0faf-11eb-0ee5-074a408638d7
# ╟─e85462f0-0faf-11eb-0d54-e52e8c1e9b26
# ╟─0153c520-0fb0-11eb-1253-0bd7e9dd04ee
# ╠═105133ee-0fb0-11eb-1eba-238a216c5182
# ╟─18ba5ee0-0fb0-11eb-1c6d-e1ced026d640
# ╠═2326d3e2-0fb0-11eb-1827-6d08b4032c34
# ╟─31d8458e-0fb0-11eb-0fe5-0b2a1a5d56c3
# ╟─b106b67e-0fb0-11eb-04f2-a734c4fa2e3b
# ╠═c5df5262-0fb0-11eb-2125-755ecf44ff81
# ╠═d80b92f0-0fb0-11eb-04f5-1d40f00d07b8
# ╠═bc5dbd20-0fb1-11eb-0bda-c3e4c7877daa
# ╟─eda6bb80-0fb0-11eb-2f87-d586f0b69f26
# ╠═f67c3cce-0fb0-11eb-3349-4181800dde90
# ╟─061cc970-0fb1-11eb-0210-d7d0f215be77
# ╠═16770920-0fb1-11eb-1551-67668809b19a
# ╟─32c0db60-0fb1-11eb-3d75-f1a189baf482
# ╠═ce847f70-0fb1-11eb-144b-6b9542b72e9b
# ╟─f8b8f0ee-0fb1-11eb-13d6-571cad22a19a
# ╠═05760cb2-0fb2-11eb-2bc4-dd2a2bfde126
# ╟─1d92d712-0fb2-11eb-23fd-4554371e8a3b
# ╠═3778c8b0-0fb2-11eb-2c8f-379bf1d61719
# ╟─6e3a9360-0fb2-11eb-11dc-af7b71bd4184
# ╠═7845ae80-0fb2-11eb-195b-4d0d4ffca60b
# ╟─9a77cd30-0fb2-11eb-1196-df634baf199d
# ╠═c8dbb78e-0fb2-11eb-1ed5-554d10df71a8
# ╠═d683334e-0fb2-11eb-3dc4-4be3043674a7
# ╟─eff30a90-0fb2-11eb-01c6-c3a35033923d
# ╟─066d6f8e-0fb3-11eb-0979-ab193faf5653
# ╠═0a431330-0fb4-11eb-2795-2194b90087ee
# ╠═c3526920-0fb4-11eb-09cb-c320ebe70780
# ╠═fa9830e0-0fb4-11eb-0098-5d09cf3ae3e2
# ╠═8c905050-0fb4-11eb-3218-ad71581a62e9
# ╠═214e781e-0fb5-11eb-10fe-2d8c3f9ce347
# ╠═13ba2120-0fb3-11eb-0599-831b085542c8
# ╟─461ec14e-0fb5-11eb-38f0-61ad30ab4e1e
# ╟─5d04b960-0fb5-11eb-01fe-fd0ff58627f6
# ╠═4047da00-0fb5-11eb-23a2-19f13af4fac6
# ╠═5824f8c0-0fb4-11eb-0073-15bcb8f48aec
# ╠═23885800-0fb4-11eb-0378-1191e7ec5ca8
# ╟─835bf0b0-0fb5-11eb-2a68-275326c4e73c
# ╠═a2c77550-0fb5-11eb-10b3-151670af6203
# ╠═ab861340-0fb5-11eb-29ff-45bc893e6e6f
# ╠═aff2bc30-0fb5-11eb-365f-7b96cdbce30e
# ╠═b54c3620-0fb5-11eb-2348-b9f57946f679
