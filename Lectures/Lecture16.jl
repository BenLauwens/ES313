### A Pluto.jl notebook ###
# v0.19.27

using Markdown
using InteractiveUtils

# ╔═╡ bd423f92-1529-11eb-11e7-359bce6c0764
begin
	using Pkg
	cd(joinpath(dirname(@__FILE__),".."))
	Pkg.activate(pwd())
    using ResumableFunctions
	using ConcurrentSim
	using Distributions
	using Plots
	using StatsPlots
	using Logging
	using HypothesisTests
end

# ╔═╡ 2e2366b3-182f-4519-b126-ff41072def48
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

# ╔═╡ 726eab70-1529-11eb-2909-17dad0c9fcfb
md"""# MM1 Queuing System

A MM1 queuing system will be used to illustrate the three main simulation methodologies:
- time-stepping
- discrete-events processing
- process-driven simulation"""

# ╔═╡ ae038200-1529-11eb-0887-a9c9d9e0daeb
md"## Using packages"

# ╔═╡ cd0ce970-1529-11eb-059f-b5e15a579b69
md"""## MM1 Queuing System

- The queuing system has 1 server.
- The interarrival times between clients (packets, ...) are exponential distributed with rate $\lambda$.
- The service times are also exponential distributed with rate $\mu$."""

# ╔═╡ d7a417f0-1529-11eb-2acc-b94a8317292b
begin
	const λ = 1.0
	const μ = 2.0
end;

# ╔═╡ 2a3f8df0-152a-11eb-14a1-b5bdcc40fe83
md"""### Time-stepping

- A small value for the time increment ``\Delta t`` is chosen and every tick of the clock a function that mimics our queuing system is run.
- Exponential distributions can be easily simulated; ``P(\text{"arrival"})=\lambda\Delta t`` and ``P(\text{"departure"})=\mu\Delta t``."""

# ╔═╡ 2e944210-152a-11eb-00cb-c57b7ae74863
Δt = 0.1

# ╔═╡ 3bf7fe10-152a-11eb-0294-37536f017897
function time_step(nr_in_system::Int)
    if nr_in_system > 0
        if rand() < μ*Δt
            nr_in_system -= 1
        end
    end
    if rand() < λ*Δt
        nr_in_system += 1
    end
    nr_in_system
end

# ╔═╡ 41da08f2-152a-11eb-0e49-439859838d80
let output = Int[], t = 0.0
	push!(output, 0)
	while t < 10
		t += Δt
		result = time_step(output[end])
		push!(output, result)
	end
	output
end

# ╔═╡ 982a97b0-152a-11eb-0013-49c24821b14e
md"* Very easy to implement for simple queuing systems but this become cumbersome if the system gets more complex (number of queues, interactions, other distributions, ...).
* A simulation is always something dynamic, i.e. time is an important feature:
 
  - When are we in steady-state?
  - How many samples of the system in steady-state are needed, to produce a useful average?
  - How many runs do a need to have some statistics about the variation around the average?
  - These questions are trivial for our example but in real-world applications they are though to answer.
  - A stable single server queue is reset every time the queue becomes idle, so we don't have to worry about steady-state and we can use eg. 1000 time-steps and 100 runs.

"

# ╔═╡ 50b321b2-153c-11eb-282c-55c7ed62a880
md"""### Discrete-event processing

- Looking at the output of the time-stepping procedure, we can observe that a lot of the time-steps the state of our system, i.e. the number of clients in the system does not change. So the procedure does a lot of processing for nothing.
- We can predict the next arrival of a client by sampling an exponential distribution with parameter ``\frac{1}{\lambda}``, so can we predict the service time of a client by sampling an exponential distribution with parameter ``\frac{1}{\mu}``.
- Only during an arrival of a client or an end of service of a client, the state changes."""

# ╔═╡ 45c57e80-152b-11eb-05fa-558d4a0b696e
begin
	const interarrival_distribution = Exponential(1/λ)
	const service_distribution = Exponential(1/μ)
end;

# ╔═╡ 3aae2380-152b-11eb-2e3f-23cd2172a8ba
function service(ev::AbstractEvent, times::Vector{Float64}, output::Vector{Int})
    sim = environment(ev)
    time = now(sim)
    push!(times, time)
    push!(output, output[end]-1)
    if output[end] > 0
        service_delay = rand(service_distribution)
        @callback service(timeout(sim, service_delay), times, output)
    end
end

# ╔═╡ 3e7368e0-152b-11eb-14a7-2b9ab301221e
function arrival(ev::AbstractEvent, times::Vector{Float64}, output::Vector{Int})
    sim = environment(ev)
    time = now(sim)
    push!(times, time)
    push!(output, output[end]+1)
    if output[end] == 1
        service_delay = rand(service_distribution)
        @callback service(timeout(sim, service_delay), times, output)
    end
    next_arrival_delay = rand(interarrival_distribution)
    @callback arrival(timeout(sim, next_arrival_delay), times, output)
end

# ╔═╡ 00dccee0-152b-11eb-0e13-637d49cb7f8e
let times = Float64[0.0], output = Int[0], sim = Simulation(), next_arrival_delay = rand(interarrival_distribution)
	@callback arrival(timeout(sim, next_arrival_delay), times, output)
	run(sim, 10.0)
    times, output
end

# ╔═╡ 60d767d0-153d-11eb-1a44-258093009804
md"""- Two callback functions describe completely what happens during the execution of an event.
- For complicated systems (network of queues, clients with priorities, other scheduling methods) working with discrete events in this ways results in spaghetti code.
- Code reuse is very limited. A lot of very different application domains can be modeled in a similar way."""

# ╔═╡ 6c269bb0-153d-11eb-3fb8-4b50a8b27910
md"""### Process-driven Discrete-event Simulation

- Events and their callbacks are abstracted and the simulation creator has only to program the logic of the system.
- A process function describes what a specific entity (also called agent) is doing."""

# ╔═╡ a10bde32-153d-11eb-3f8b-1701ada37610
begin
	@resumable function packet(sim::Simulation, line::Resource, times::Vector{Float64}, output::Vector{Int})
		time = now(sim)
		push!(times, time)
		push!(output, output[end]+1)
		@yield request(line)
		service_delay = rand(service_distribution)
		@yield timeout(sim, service_delay)
		time = now(sim)
		push!(times, time)
		push!(output, output[end]-1)
		@yield release(line)
	end
	
	@resumable function packet(sim::Simulation, line::Resource, times::Vector{Float64})
		@yield request(line)
		service_delay = rand(service_distribution)
		@yield timeout(sim, service_delay)
		time = now(sim)
		push!(times, time)
		@yield release(line)
	end
end

# ╔═╡ 78357610-153d-11eb-0633-2b960c4f9798
begin
	@resumable function packet_generator(sim::Simulation, times::Vector{Float64}, output::Vector{Int})
		line = Resource(sim, 1)
		while true
			next_arrival_delay = rand(interarrival_distribution)
			@yield timeout(sim, next_arrival_delay)
			@process packet(sim, line, times, output)
		end
end
	
	@resumable function packet_generator(sim::Simulation, times::Vector{Float64})
		line = Resource(sim, 1)
		while true
			next_arrival_delay = rand(interarrival_distribution)
			@yield timeout(sim, next_arrival_delay)
			@process packet(sim, line, times)
		end
	end
end

# ╔═╡ bc08be10-153d-11eb-1fd3-5f69bc2a2651
times, output = let times = Float64[0.0], output = Int[0], sim = Simulation()
	@process packet_generator(sim, times, output)
	run(sim, 10.0)
	times, output
end

# ╔═╡ d57030e0-153d-11eb-3b9f-45e0d418608e
md"## Plotting"

# ╔═╡ f0a92f60-153d-11eb-0b7d-6923c24e4c60
begin
	plot(times, output, line=:steppost, leg=false)
	plot!(title = "MM1", xlabel = "Time", ylabel = "Number of clients in system")
end

# ╔═╡ 023eae30-153e-11eb-1185-c7647f393ba6
md"""## Monte Carlo Simulation and Statistical Processing

- Often we like to gather information about probabilites.
- We also want to know the variation of these probabilities between simulation runs."""

# ╔═╡ 0b53f7a0-153e-11eb-0dbf-e541f7cc0eb0
begin
	const RUNS = 30
	const DURATION = 1000.0
end;

# ╔═╡ 177e7050-153e-11eb-34f2-a7342ec00e38
Pₙ = let Pₙ = Vector{Dict{Int, Float64}}()
	for r in 1:RUNS
		push!(Pₙ, Dict{Int, Float64}())
		times = Float64[0.0]
		output = Int[0]
		sim = Simulation()
		@process packet_generator(sim, times, output)
		run(sim, DURATION)
		for (i,t) in enumerate(times[1:length(times)-1])
			duration = times[i+1] - t
			if output[i] ∈ keys(Pₙ[r])
				Pₙ[r][output[i]] = Pₙ[r][output[i]] + duration
			else
				Pₙ[r][output[i]] = duration
			end
		end
		tₑ = times[end]
		for nr_in_system in keys(Pₙ[r])
			Pₙ[r][nr_in_system] = Pₙ[r][nr_in_system] / tₑ
		end
	end
	Pₙ
end;

# ╔═╡ 469e57b0-153e-11eb-2c80-e1e47bc2ab05
let n = 8, arr = zeros(Float64, RUNS, n+1)
	for v in 0:n
		for r in 1:RUNS
			if v ∈ keys(Pₙ[r])
				arr[r, v+1] = Pₙ[r][v]
			else
				arr[r, v+1] = 0
			end
		end
	end
	boxplot(reshape(collect(0:n), 1, n+1), arr, label=reshape(collect(0:n), 1, n+1))
end

# ╔═╡ 42efcea0-153e-11eb-1a88-e3401ac10a22
md"""## Hypothesistests

We can test easily whether that the data in a vector comes from a given distribution"""

# ╔═╡ 02dd42b0-153f-11eb-2b6c-43650d8f4b38
let times = Float64[], sim = Simulation()
	@process packet_generator(sim, times)
	run(sim, 100.0)
	vec = diff(times)
	ExactOneSampleKSTest(vec, interarrival_distribution)
end

# ╔═╡ Cell order:
# ╟─2e2366b3-182f-4519-b126-ff41072def48
# ╟─726eab70-1529-11eb-2909-17dad0c9fcfb
# ╟─ae038200-1529-11eb-0887-a9c9d9e0daeb
# ╠═bd423f92-1529-11eb-11e7-359bce6c0764
# ╟─cd0ce970-1529-11eb-059f-b5e15a579b69
# ╠═d7a417f0-1529-11eb-2acc-b94a8317292b
# ╟─2a3f8df0-152a-11eb-14a1-b5bdcc40fe83
# ╠═2e944210-152a-11eb-00cb-c57b7ae74863
# ╠═3bf7fe10-152a-11eb-0294-37536f017897
# ╠═41da08f2-152a-11eb-0e49-439859838d80
# ╟─982a97b0-152a-11eb-0013-49c24821b14e
# ╟─50b321b2-153c-11eb-282c-55c7ed62a880
# ╠═45c57e80-152b-11eb-05fa-558d4a0b696e
# ╠═3e7368e0-152b-11eb-14a7-2b9ab301221e
# ╠═3aae2380-152b-11eb-2e3f-23cd2172a8ba
# ╠═00dccee0-152b-11eb-0e13-637d49cb7f8e
# ╟─60d767d0-153d-11eb-1a44-258093009804
# ╟─6c269bb0-153d-11eb-3fb8-4b50a8b27910
# ╠═78357610-153d-11eb-0633-2b960c4f9798
# ╠═a10bde32-153d-11eb-3f8b-1701ada37610
# ╠═bc08be10-153d-11eb-1fd3-5f69bc2a2651
# ╟─d57030e0-153d-11eb-3b9f-45e0d418608e
# ╠═f0a92f60-153d-11eb-0b7d-6923c24e4c60
# ╟─023eae30-153e-11eb-1185-c7647f393ba6
# ╠═0b53f7a0-153e-11eb-0dbf-e541f7cc0eb0
# ╠═177e7050-153e-11eb-34f2-a7342ec00e38
# ╠═469e57b0-153e-11eb-2c80-e1e47bc2ab05
# ╟─42efcea0-153e-11eb-1a88-e3401ac10a22
# ╠═02dd42b0-153f-11eb-2b6c-43650d8f4b38
