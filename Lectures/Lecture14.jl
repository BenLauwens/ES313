### A Pluto.jl notebook ###
# v0.11.14

using Markdown
using InteractiveUtils

# ╔═╡ 829bef12-1526-11eb-1130-2fa0030083df
begin
	using Distributions
	using SimJulia
	using Plots
	using StatsPlots
	using Logging
end

# ╔═╡ 04730740-1526-11eb-1cf9-2d8c5426d8cf
md"""# A Repair Problem
Ross, Simulation 5th edition, Section 7.7, p. 124-126"""

# ╔═╡ 4031d400-1526-11eb-2591-d1bd720229a7
md"""## Description

A system needs $n$ working machines to be operational. To guard against machine breakdown, additional machines are kept available as spares. Whenever a machine breaks down it is immediately replaced by a spare and is itself sent to the repair facility, which consists of a single repairperson who repairs failed machines one at a time. Once a failed machine has been repaired it becomes available as a spare to be used when the need arises. All repair times are independent random variables having the common distribution function $G$. Each time a machine is put into use the amount of time it functions before breaking down is a random variable, independent of the past, having distribution function $F$.

The system is said to “crash” when a machine fails and no spares are available. Assuming that there are initially $n + s$ functional machines of which $n$ are put in use and $s$ are kept as spares, we are interested in simulating this system so as to approximate $E[T]$, where $T$ is the time at which the system crashes."""

# ╔═╡ 724f9210-1526-11eb-25e6-45c4bcfadce9
md"## Needed Packages"

# ╔═╡ 8f14fcf0-1526-11eb-3867-af9f05caeec1
md"""## Define constants"""

# ╔═╡ a164f220-1526-11eb-10b9-253cad9c3ef4
begin
	const RUNS = 30
	const N = 10
	const S = 3
	const LAMBDA = 100
	const MU = 1

	const F = Exponential(LAMBDA)
	const G = Exponential(MU)
end;

# ╔═╡ b9758782-1526-11eb-1f28-f91ea66a8507
md"## Define the behaviour of a machine"

# ╔═╡ c5f4d6f2-1526-11eb-3ea2-3f8a4be50550
@resumable function machine(sim::Simulation, repair_facility::Resource, spares::Store{Process})
    while true
        try
            @yield timeout(sim, Inf)
        catch
        end
        @info "At time $(now(sim)): $(active_process(sim)) starts working."
        @yield timeout(sim, rand(F))
        @info "At time $(now(sim)): $(active_process(sim)) stops working."
        get_spare = get(spares)
        @yield get_spare | timeout(sim, 0.0)
        if state(get_spare) != SimJulia.idle
            interrupt(value(get_spare))
        else
            throw(SimJulia.StopSimulation("No more spares!"))
        end
        @yield request(repair_facility)
        @info "At time $(now(sim)): $(active_process(sim)) repair starts."
        @yield timeout(sim, rand(G))
        @yield release(repair_facility)
        @info "At time $(now(sim)): $(active_process(sim)) is repaired."
        @yield put(spares, active_process(sim))
    end
end

# ╔═╡ b3fcc5c0-1526-11eb-1660-83009fe4380c
md"## Startup procedure"

# ╔═╡ d842f760-1526-11eb-1216-5f4867b6bde4
@resumable function start_sim(sim::Simulation, repair_facility::Resource, spares::Store{Process})
    procs = Process[]
    for i=1:N
        push!(procs, @process machine(sim, repair_facility, spares))
    end
    @yield timeout(sim, 0.0)
    for proc in procs
        interrupt(proc)
    end
    for i=1:S
        @yield put(spares, @process machine(sim, repair_facility, spares))
    end
end

# ╔═╡ e044fc10-1526-11eb-228a-0bf8feb7984a
md"## One simulation run"

# ╔═╡ 0d13a070-1527-11eb-231d-adaa63a43f26
function sim_repair()
    sim = Simulation()
    repair_facility = Resource(sim)
    spares = Store{Process}(sim)
    @process start_sim(sim, repair_facility, spares)
    msg = run(sim)
    stop_time = now(sim)
    @info "At time $stop_time: $msg"
    stop_time
end

# ╔═╡ 09346a70-1527-11eb-1255-53b9af4f25d8
sim_repair()

# ╔═╡ 2995e7d0-1527-11eb-1029-a9bb9fa1f39b
md"## Multiple simulations"

# ╔═╡ 3ea1efc0-1527-11eb-3a20-71bc13f41d92
Logging.disable_logging(LogLevel(1000));

# ╔═╡ 68be4560-1527-11eb-1dd5-056ea4589f75
begin
	results = Float64[]
	for i=1:RUNS
		push!(results, sim_repair())
	end
	"Average crash time: $(sum(results)/RUNS)"
end

# ╔═╡ a7a10e70-1527-11eb-3c45-65d6564d5b45
md"## Plots"

# ╔═╡ e9a69b50-1527-11eb-3bac-01cb8cae7524
boxplot(results)

# ╔═╡ Cell order:
# ╟─04730740-1526-11eb-1cf9-2d8c5426d8cf
# ╟─4031d400-1526-11eb-2591-d1bd720229a7
# ╟─724f9210-1526-11eb-25e6-45c4bcfadce9
# ╠═829bef12-1526-11eb-1130-2fa0030083df
# ╟─8f14fcf0-1526-11eb-3867-af9f05caeec1
# ╠═a164f220-1526-11eb-10b9-253cad9c3ef4
# ╟─b9758782-1526-11eb-1f28-f91ea66a8507
# ╠═c5f4d6f2-1526-11eb-3ea2-3f8a4be50550
# ╟─b3fcc5c0-1526-11eb-1660-83009fe4380c
# ╠═d842f760-1526-11eb-1216-5f4867b6bde4
# ╟─e044fc10-1526-11eb-228a-0bf8feb7984a
# ╠═0d13a070-1527-11eb-231d-adaa63a43f26
# ╠═09346a70-1527-11eb-1255-53b9af4f25d8
# ╟─2995e7d0-1527-11eb-1029-a9bb9fa1f39b
# ╠═3ea1efc0-1527-11eb-3a20-71bc13f41d92
# ╠═68be4560-1527-11eb-1dd5-056ea4589f75
# ╟─a7a10e70-1527-11eb-3c45-65d6564d5b45
# ╠═e9a69b50-1527-11eb-3bac-01cb8cae7524
