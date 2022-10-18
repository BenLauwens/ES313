### A Pluto.jl notebook ###
# v0.19.12

using Markdown
using InteractiveUtils

# ╔═╡ 5ce221c0-0fab-11eb-106a-6bf5967d6cc2
begin
	using Pkg
	cd(joinpath(dirname(@__FILE__),".."))
	Pkg.activate(pwd())
	using SimJulia
	using Distributions
	using Plots
	using StatsPlots
	using CSV
	using Logging
	using DataFrames
end

# ╔═╡ da36e622-0faa-11eb-11cd-45664830e371
md"""# Simulating the Atomic Bomb"""

# ╔═╡ 7d836740-0fab-11eb-3dc2-49f84d2ab795
md"""## Packages"""

# ╔═╡ 62c05c10-0fab-11eb-34b0-a1f4cc2a8250
md"""## Constants"""

# ╔═╡ 93553030-0fab-11eb-37fe-af046009261a
begin
	const Nₐ = 6.02214086e23  # atoms / mole
	const ρᵤ = 19.1           # g / cm3
	const mᵤ = 235.0439299    # g / mole
	const nᵤ = ρᵤ * Nₐ / mᵤ   # atoms / cm3
	const mₙ = 1.008664916    # g / mole
	const Mₙ = mₙ / Nₐ * 1e-3 # kg
	const k = 1.38064852e-23  # J / K
	const q = 1.60217662e-19  # C
	const A = mᵤ / mₙ
	const α = (A - 1)^2 / (A + 1) ^2
	const numberofspontaneousfis = 0.0003 # / g / s
	ρᵤ * 4/3 * π * 9^3 * numberofspontaneousfis
end;

# ╔═╡ b9bb0d80-0fab-11eb-05a4-7f41fc472d40
md"""## Distributions"""

# ╔═╡ b3f42bc2-0fab-11eb-05be-77abdb15db5f
begin
	const cosΘdistr = Uniform(-1, 1)
	const cosϕdistr = Uniform(-1, 1)

	const energy = 1e-3:1e-3:15
	function wattspectrum(energy) # MeV
		0.453 * sinh(sqrt(2.29*energy))*exp(-1.036*energy)
	end
	const spectrum = wattspectrum.(energy)
	const wattdistr = Categorical(spectrum ./ sum(spectrum))

	const numberofneutronsdistr = Categorical([0,0.6,0.36,0.04])
	const numberofneutronsspontaneousdistr = Categorical([0.2,0.74,0.06])
end;

# ╔═╡ e9f2cd80-0fab-11eb-2596-cdcf2e69d0ba
md"""## Data"""

# ╔═╡ d7cfdbc0-0fab-11eb-1c3f-4722cf426fa8
begin
	σt = CSV.read("Lectures/sigma_total.txt", DataFrame)
	σf = CSV.read("Lectures/sigma_fission.txt", DataFrame)
	σa = CSV.read("Lectures/sigma_absorption.txt", DataFrame)
	σi = CSV.read("Lectures/sigma_inelastic.txt", DataFrame)
end;

# ╔═╡ 0e6abd80-0fac-11eb-0e14-530966220de9
function Σ(energy::Float64) # 1 / cm
    i = findfirst(e -> e > energy, σt[:, 1])
    σ = σt[i, 2] + (energy - σt[i, 1]) / (σt[i-1, 1] - σt[i, 1]) * (σt[i-1, 2] - σt[i, 2])
    nᵤ * σ * 1e-24
end;

# ╔═╡ 109f50c0-0fac-11eb-26f5-f7f079d29999
function ΔtΔl(energy::Float64)
    Δl = -log(rand()) / Σ(energy)
    v = sqrt(2 * energy * q / Mₙ) * 100
    Δl / v, Δl
end;

# ╔═╡ 1887da02-0fac-11eb-1a10-c35a3cb3e379
md"""## Types and Callbacks"""

# ╔═╡ 23073ac2-0fac-11eb-3145-3f6809370a2b
struct Bomb
    radius :: Float64             # cm
    generated :: Vector{Int64}
    neutrons :: Vector{Int64}
    times :: Vector{Float64}      # s
    function Bomb(radius::Real)
        new(radius, Float64[], Int64[], Float64[])
    end
end;

# ╔═╡ 29ce0050-0fac-11eb-3367-33e9802eebb4
begin
	mutable struct Neutron
		r :: Float64                  # cm
		cosθ :: Float64
		energy :: Float64             # eV
		function Neutron(r::Float64, energy::Float64, cosθ::Float64 = rand(cosΘdistr))
			new(r, cosθ, energy)
		end
	end
	
	function Neutron(sim::Simulation, bomb::Bomb, r::Float64, energy::Float64=energy[rand(wattdistr)] * 1e6)
		neutron = Neutron(r, energy)
		time = now(sim)
		@info("$time: create neutron at position $r with cosθ = $(neutron.cosθ) and energy = $(neutron.energy) eV")
		push!(bomb.times, time)
		push!(bomb.neutrons, 1)
		Δt, Δl = ΔtΔl(neutron.energy)
		@callback collision(timeout(sim, Δt), bomb, neutron, Δl)
	end
	
	function collision(ev::AbstractEvent, bomb::Bomb, neutron::Neutron, Δl::Float64)
		sim = environment(ev)
		time = now(ev)
		r′ = sqrt(neutron.r^2 + Δl^2 + 2*neutron.r*Δl*neutron.cosθ)
		if r′ > bomb.radius
			@info("$(now(sim)): neutron has left the bomb")
			push!(bomb.times, time)
			push!(bomb.neutrons, -1)
			push!(bomb.generated, 0)
		else
			i = findfirst(e -> e > neutron.energy, σt[:, 1])
			σtot = σt[i, 2] + (neutron.energy - σt[i, 1]) / (σt[i-1, 1] - σt[i, 1]) * (σt[i-1, 2] - σt[i, 2])
			i = findfirst(e -> e > neutron.energy, σf[:, 1])
			σfis = σf[i, 2] + (neutron.energy - σf[i, 1]) / (σf[i-1, 1] - σf[i, 1]) * (σf[i-1, 2] - σf[i, 2])
			i = findfirst(e -> e > neutron.energy, σa[:, 1])
			σabs = σa[i, 2] + (neutron.energy - σa[i, 1]) / (σa[i-1, 1] - σa[i, 1]) * (σa[i-1, 2] - σa[i, 2])
			i = findfirst(e -> e > neutron.energy, σi[:, 1])
			i = i == 1 ? 2 : i
			σin = σi[i, 2] + (neutron.energy - σi[i, 1]) / (σi[i-1, 1] - σi[i, 1]) * (σi[i-1, 2] - σi[i, 2])
			rnd = rand()
			if rnd < σfis / σtot
				n = rand(numberofneutronsdistr)
				@info("$(now(sim)): fission with creation of $n neutrons")
				for _ in 1:n
					Neutron(sim, bomb, r′)
				end
				push!(bomb.times, time)
				push!(bomb.neutrons, -1)
				push!(bomb.generated, n)
			elseif rnd < (σabs + σfis) / σtot
				@info("$(now(sim)): neutron absorbed")
				push!(bomb.times, time)
				push!(bomb.neutrons, -1)
				push!(bomb.generated, 0)
			elseif rnd < (σin + σabs + σfis) / σtot
				@info("$(now(sim)): inelastic scattering")
				n = 1
				Neutron(sim, bomb, r′)
				push!(bomb.times, time)
				push!(bomb.neutrons, -1)
			else
				cosϕ = rand(cosϕdistr)
				cosψ = (A * cosϕ + 1) / sqrt(A^2 + 2 * A * cosϕ +1)
				neutron.r = r′
				neutron.energy *= 0.5 * (1 + α + (1 - α) * cosϕ)
				θ = acos(neutron.cosθ)
				ψ = acos(cosψ)
				θplusψ = θ + ψ
				θminψ = ψ < π / 2 ? θ - ψ : θ - ψ + 2π
				neutron.cosθ = cos(θplusψ + rand() * (θminψ - θplusψ))
				@info("$(now(sim)): elastic scattering at position $r′ with cosθ = $(neutron.cosθ) and energy = $(neutron.energy) eV")
				Δt, Δl = ΔtΔl(neutron.energy)
				@callback collision(timeout(sim, Δt), bomb, neutron, Δl)
			end
		end
		((sum(bomb.generated) > 500 && sum(bomb.neutrons) == 0) || (time > 1 && sum(bomb.neutrons) == 0) || sum(bomb.generated) > 1000) && throw(StopSimulation())
	end
end;

# ╔═╡ 761f5ad0-0fac-11eb-1ffb-2ff423ad2e32
function spontaneousfission(ev::AbstractEvent, bomb::Bomb)
    sim = environment(ev)
    for _ in rand(numberofneutronsspontaneousdistr)
        Neutron(sim, bomb, rand() * bomb.radius)
    end
    rate = ρᵤ * 4/3 * π * bomb.radius^3 * numberofspontaneousfis
    @callback spontaneousfission(timeout(sim, -log(rand()) / rate), bomb)
end;

# ╔═╡ 88ddf050-0fac-11eb-2513-e7adbb01af6f
md"""## Simulation"""

# ╔═╡ f0fb88a0-0fac-11eb-21d7-294b7f646c3c
bomb = let
	sim = Simulation()
	bomb = Bomb(5)
	@callback spontaneousfission(timeout(sim, 0.0), bomb)
	run(sim)
	bomb
end;

# ╔═╡ 08c2b8f0-0fad-11eb-31bc-b1f5d13ee7a1
mean(bomb.generated)

# ╔═╡ 12fe59ee-0fad-11eb-1b11-639b1af9acd4
md"""## Plot"""

# ╔═╡ 26b3d292-0fad-11eb-03ce-bf599698ad10
let
	i = findlast(x->x==0, cumsum(bomb.neutrons))
	i = i === nothing ? 1 : i
	plot(bomb.times[i+1:end], cumsum(bomb.neutrons)[i+1:end], seriestype=:scatter, ylabel="N", xlabel="time [s]")
end

# ╔═╡ 310da9f0-0fad-11eb-0418-4519c618e55d
md"""## Monte Carlo"""

# ╔═╡ 4154d6d0-0fad-11eb-0ec4-6354a4a55477
begin
	const RUNS = 100
	const RADII = 5:12;
	Logging.disable_logging(LogLevel(1000));
end;

# ╔═╡ 54ba339e-0fad-11eb-1e1f-ef2a9bedc565
ks = let
	ks = zeros(Float64, RUNS, length(RADII))
	for (i, r) in enumerate(RADII)
		for j in 1:RUNS
			sim = Simulation()
			bomb = Bomb(r)
			@callback spontaneousfission(timeout(sim, 0.0), bomb)
			run(sim)
			ks[j, i] = mean(bomb.generated)
		end
	end
	ks
end;

# ╔═╡ 78bf8bb0-0fad-11eb-2e74-355f4a8d2268
boxplot(reshape(collect(RADII), 1, length(RADII)), ks, label=reshape(collect(RADII), 1, length(RADII)), legend=:bottomright, xlabel="R [cm]", ylabel="k")

# ╔═╡ 8096afd0-0fad-11eb-3474-7d081e1c48d4
mean(ks, dims=1)

# ╔═╡ 85e81370-0fad-11eb-17f7-63bbbe7e0705
plot(RADII, [mean(ks, dims=1) ...], seriestype=:scatter, xlabel="R [cm]", ylabel="k")

# ╔═╡ Cell order:
# ╟─da36e622-0faa-11eb-11cd-45664830e371
# ╟─7d836740-0fab-11eb-3dc2-49f84d2ab795
# ╠═5ce221c0-0fab-11eb-106a-6bf5967d6cc2
# ╟─62c05c10-0fab-11eb-34b0-a1f4cc2a8250
# ╠═93553030-0fab-11eb-37fe-af046009261a
# ╟─b9bb0d80-0fab-11eb-05a4-7f41fc472d40
# ╠═b3f42bc2-0fab-11eb-05be-77abdb15db5f
# ╟─e9f2cd80-0fab-11eb-2596-cdcf2e69d0ba
# ╠═d7cfdbc0-0fab-11eb-1c3f-4722cf426fa8
# ╠═0e6abd80-0fac-11eb-0e14-530966220de9
# ╠═109f50c0-0fac-11eb-26f5-f7f079d29999
# ╟─1887da02-0fac-11eb-1a10-c35a3cb3e379
# ╠═23073ac2-0fac-11eb-3145-3f6809370a2b
# ╠═29ce0050-0fac-11eb-3367-33e9802eebb4
# ╠═761f5ad0-0fac-11eb-1ffb-2ff423ad2e32
# ╟─88ddf050-0fac-11eb-2513-e7adbb01af6f
# ╠═f0fb88a0-0fac-11eb-21d7-294b7f646c3c
# ╠═08c2b8f0-0fad-11eb-31bc-b1f5d13ee7a1
# ╟─12fe59ee-0fad-11eb-1b11-639b1af9acd4
# ╠═26b3d292-0fad-11eb-03ce-bf599698ad10
# ╟─310da9f0-0fad-11eb-0418-4519c618e55d
# ╠═4154d6d0-0fad-11eb-0ec4-6354a4a55477
# ╠═54ba339e-0fad-11eb-1e1f-ef2a9bedc565
# ╠═78bf8bb0-0fad-11eb-2e74-355f4a8d2268
# ╠═8096afd0-0fad-11eb-3474-7d081e1c48d4
# ╠═85e81370-0fad-11eb-17f7-63bbbe7e0705
