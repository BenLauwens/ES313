### A Pluto.jl notebook ###
# v0.11.14

using Markdown
using InteractiveUtils

# ╔═╡ 1c83c71e-0fa9-11eb-28d3-49496955dc7f
using CSV

# ╔═╡ 39ea5400-0fa9-11eb-185b-096971c52c61
using Plots

# ╔═╡ bd6092b0-0fa7-11eb-0ec2-cdc01bf1360b
md"""# Atomic Bomb and the Monte Carlo Method
## Monte Carlo Origins

There is no single Monte Carlo method. Rather, the term describes a broad approach encompassing many specific techniques. As its name lightheartedly suggests, the defining element is the application of the laws of chance. Physicists had traditionally sought to create elegant equations to describe the outcome of processes involving the interactions of huge numbers of particles. For example, Einstein’s equations for Brownian motion could be used to describe the expected diffusion of a gas cloud over time, without needing to simulate the random progression of its individual molecules. There remained many situations in which tractable equations predicting the behavior of the overall system were elusive even though the factors influencing the progress of an individual particle over time could be described with tolerable accuracy.

One of these situations, of great interest to Los Alamos, was the progress of free neutrons hurtling through a nuclear weapon as it began to explode. As Stanislaw Ulam, a mathematician who joined Los Alamos during the war and later helped to invent the hydrogenbomb, would subsequently note, “Most of the physics at Los Alamos could be reduced to the study of assemblies of particles interacting with each other, hitting each other, scattering, sometimes giving rise to new particles.”

Given the speed, direction, and position of a neutron and some physical constants, physicists could fairly easily compute the probability that it would, during the next tiny fraction of a second, crash into the nucleus of an unstable atom with sufficient force to break it up and release more neutrons in a process known as fission. One could also estimate the likelihood that neutron would fly out of the weapon entirely, change direction after a collision, or get stuck. But even in the very short time span of a nuclear explosion, these simple actions could be combined in an almost infinite number of sequences, defying even the brilliant physicists and mathematicians gathered at Los Alamos to simplify the proliferating chains of probabilities sufficiently to reach a traditional analytical solution.

The arrival of electronic computers offered an alternative: simulate the progress overtime of a series of virtual neutrons representing members of the population released by the bomb’s neutron initiator when a conventional explosive compressed its core to form a critical mass and trigger its detonation. Following these neutrons through thousands of random events would settle the question statistically, yielding a set of neutron histories that closely approximated the actual distribution implied by the parameters chosen. If the number of fissions increased over time, then a self-sustaining chain reaction was underway. The chain reaction would end after an instant as the core blew itself to pieces, so the rapid proliferation of free neutrons, measured by a parameter the weapon designers called “alpha,” was crucial to the bomb’s effectiveness in converting enriched uranium into destructive power."""

# ╔═╡ 0911b590-0fa8-11eb-0b36-315109cc9657
md"""## Physics of the Atomic Bomb

### Neutron Reaction Rate Proportional to Neutron Flux and Target Area

Assume foil density $n$ (atoms/cm3), width $\Delta x$, bombarded with beam (area $A$) of neutrons $I$ (neutrons/s) with velocity $v_n$.

Each nucleus in foil represents possible target area: $\sigma = \pi R_0^2$ where $R_0$ is nuclear radius. Total target area ~ $A \Delta x n \sigma$

Rate of removing neutrons from $I$ is proportional to: #neutrons crossing through $A$ and total area presented by all targets:
\begin{equation}
\frac{\mathrm d N}{\mathrm d t} = \frac{I}{A}\left(A \Delta x n \sigma\right)
\end{equation}

### Neutron reaction cross sections

Total microscopic neutron cross section is expressed as:
\begin{equation}
\sigma = \frac{\mathrm d N}{\mathrm d t} \frac{1}{\frac{I}{A}\left(A \Delta x n \right)}
\end{equation}

Defining neutron flux as: 
\begin{equation}
\phi= \frac{I}{A} \textrm{(neutrons/s cm2)}
\end{equation}

Then
```math
\frac{\mathrm d N}{\mathrm d t} = \phi A \Delta x n \sigma
```

Neutron flux can also be defined as $\phi= n_nv_n$ where $n_n$ is neutron density per cm3 in beam, $v_n$ relative velocity (cm/s) of neutrons in beam.

Cross section $\sigma$ can be experimentally measured as function of energy: $\sigma\left(E\right)$, expressed in “barns” (b) with 1b = 10-24cm2.

### Neutron reaction cross sections

Cross sections $\sigma\left(E\right)$ can be separated into different types of reactions – scattering, absorption, fission:
```math
\sigma\left(E\right) =\sigma_s\left(E\right)+ \sigma_a\left(E\right)+ \sigma_f\left(E\right)
```

Neutron cross section data is available from [NNDC](http://www.nndc.bnl.gov/sigma/index.jsp).
"""

# ╔═╡ 7676ed80-0fa8-11eb-2998-d398e4701fde
#using Pkg

# ╔═╡ 18261250-0fa9-11eb-2fda-8b8683d5a90c
#pkg"add CSV"

# ╔═╡ 40c34200-0fa9-11eb-12b5-6196f71e1a7c
let
	data = CSV.read("sigma_total.txt")
	plot(data[:,1], data[:,2], xaxis=:log, yaxis=:log, xlabel="E (eV)", ylabel="sigma (b)", label="sigma_total")
	data = CSV.read("sigma_fission.txt")
	plot!(data[:,1], data[:,2], xaxis=:log, yaxis=:log, label="sigma_fission")
	data = CSV.read("sigma_elastic.txt")
	plot!(data[:,1], data[:,2], xaxis=:log, yaxis=:log, label="sigma_elastic")
	data = CSV.read("sigma_inelastic.txt")
	plot!(data[:,1], data[:,2], xaxis=:log, yaxis=:log, label="sigma_inelastic")
	data = CSV.read("sigma_absorption.txt")
	plot!(data[:,1], data[:,2], xaxis=:log, yaxis=:log, label="sigma_absorption")
end

# ╔═╡ 8553233e-0fa9-11eb-119d-01b79be544b7
md"""### Attenuation of Neutron Beam
From conservation of neutrons in beam: number scattered, absorbed, reacted removed from beam: $\mathrm d N = - \mathrm d I$

Since
\begin{equation}
\frac{N}{I} = n\Delta x\sigma \leftarrow \begin{cases}
N= In\sigma \Delta x \\
- \mathrm d I = In\sigma \mathrm d x
\end{cases}
\end{equation}

Integrated, this yields attenuation formula in terms of total reaction cross section and foil density:
\begin{equation}
I\left(x\right) = I_0\mathrm e^{-n\sigma x}
\end{equation}

$\frac{I\left(x\right)}{I_0} = \mathrm e^{-n\sigma x}$ is probability of non-interaction

###  Macroscopic Cross Section

For nuclear engineering calculations macroscopic neutron cross section $\Sigma\left(E\right)= n\sigma\left(E\right)$ becomes more useful

$\Sigma\left(E\right)$ effectively has units of: #/cm3 x cm2 = #/cm

###  Probability of Interaction

Probability of neutron interaction event in $\mathrm d x$ is expressed as
\begin{equation}
p\left(x\right) \mathrm d x = \Sigma \mathrm e^{- \Sigma x} \mathrm d x
\end{equation}

Average distance traveled without interaction, or mean free path:
\begin{equation}
\lambda = \int_0^{+\infty}xp\left(x\right) \mathrm d x = \frac{1}{\Sigma}
\end{equation}

Distance traveled without interaction follows an exponential law with parameter $\Sigma$

### Fission
"""

# ╔═╡ 95544670-0fa9-11eb-36a5-6987b08129a0
begin
	data = CSV.read("sigma_fission.txt")
	const Nₐ = 6.02214086e23 # atoms / mole
	const ρᵤ = 19.1          # g / cm3
	const mᵤ = 235.0439299   # g / mole
	const nᵤ = ρᵤ * Nₐ / mᵤ
	const k = 1.38064852e-23
	const q = 1.60217662e-19
	E = 300 * k / q # eV
	@show E
	i = findfirst(x -> x > E, data[:, 1])
	σ300K = data[i, 2] + (E - data[i, 1]) / (data[i-1, 1] - data[i, 1]) * (data[i-1, 2] - data[i, 2])
	E = 2e6 # eV
	i = findfirst(x -> x > E, data[:, 1])
	σ2e6eV = data[i, 2] + (E - data[i, 1]) / (data[i-1, 1] - data[i, 1]) * (data[i-1, 2] - data[i, 2])
	@show σ300K σ2e6eV # barn
	Σ300K = nᵤ * σ300K * 1e-24
	Σ2e6eV = nᵤ * σ2e6eV * 1e-24
	@show Σ300K Σ2e6eV # cm-1
	λ300K = 1 / Σ300K
	λ2e6eV = 1 / Σ2e6eV
	@show λ300K λ2e6eV; # cm
	E, σ300K, σ2e6eV, Σ300K, Σ2e6eV, λ300K, λ2e6eV
end

# ╔═╡ 0a643b50-0faa-11eb-2a07-93790802d704
md"""Fission of U235 yields on average: 2.44 total neutrons (1, 2, 3 or 4 depending on reaction)

Neutrons are ejected isotropically.

So due to the spherical symmetry, the angle $\theta$ with the radius is determined by

\begin{equation}
\cos\theta \approx \mathcal U\left(\left[-1,1\right]\right)
\end{equation}

The distance from the center of a neutron created at radius $r$, flying in the direction $\theta$ for a distance $d$ (exponentially distributed) is given by

\begin{equation}
r^\prime = \sqrt{r^2 + d^2 + 2rd\cos\theta}
\end{equation}

and the time of flight

\begin{equation}
\Delta t = \frac{d}{v} = \displaystyle\frac{d}{\sqrt\frac{2E}{m}}
\end{equation}"""

# ╔═╡ 282bd3f0-0faa-11eb-2357-278dee39e9a0
begin
	v300K = sqrt(2 * 300 * k / 1.674929e-27) # m/s
	Δt300K = λ300K / v300K / 100
	v2e6eV = sqrt(2 * 2e6 * q / 1.674929e-27) # m/s
	Δt2e6eV = λ2e6eV / v2e6eV / 100
	@show v300K v2e6eV Δt300K Δt2e6eV;
	v300K, v2e6eV, Δt300K, Δt2e6eV
end

# ╔═╡ 408cfa50-0faa-11eb-005a-21e46e3bdec4
md"""Energy spectrum of released neutrons is also available from [NNDC](http://www.nndc.bnl.gov/sigma/index.jsp) but we will use the empirical Watt distribution:

\begin{equation}
P\left(E\right)=0.4865\sinh\left(\sqrt{2E}\right)\mathrm e^{-E}
\end{equation}"""

# ╔═╡ 649b7a20-0faa-11eb-0ede-a7a1e709af7a
let 
	logE = -8:0.1:1.5
	E = 10 .^(logE)
	plot(E, 0.4865 .* sinh.(sqrt.(2 .* E)) .* exp.(-E), label="Watt", xlabel="E (MeV)", ylabel="Prob")
end

# ╔═╡ 8031178e-0faa-11eb-3ef7-c94a993bc778
md"""1 eV = 1.60217662 10-19 J

Neutrons created by fission are fast neutrons. Scattering is important to increase reaction rate!

### Scattering

Scattering in the center of mass frame:
```math
E_\textrm{out} = E_\textrm{in} \frac{1}{2}\left((1+\alpha) + (1-\alpha)\cos\phi \right)
```

where $\displaystyle\alpha = \left(\frac{A-1}{A+1}\right)^2$ and A=235 for U235.

The scattering angle in the laboratory frame yields:
\begin{equation}
\cos\psi = \frac{A\cos\phi + 1}{\sqrt{A^2+2A\cos\phi+1}}
\end{equation}

The probability of a neutron (initial kinetic energy $E_\textrm{in}$) colliding and resulting in final neutron kinetic energy $E_\textrm{out}$ is
```math
P\left\{E_\textrm{in}\rightarrow E_\textrm{out}\right\}=\frac{4\pi\displaystyle\frac{\mathrm d \sigma_s\left(\phi\right)}{\mathrm d \phi}}{\sigma_s E_\textrm{in}\left(1-\alpha\right)}
```

The differential cross section can also is also available from [NNDC](http://www.nndc.bnl.gov/sigma/index.jsp), but we will suppose the scattering happens isotropically in a solid angle so $\cos\phi$ is distributed uniformally in the interval $\left[-1,1\right]$ and we use the previous formulas to calculate $\psi$ and $E_\textrm{out}$.

The new $\theta^\prime$ is uniformally distributed in the interval $\left[\theta-\psi, \theta+\psi\right]$.

### Neutron Multiplication Factor

A numerical measure of a critical mass is dependent on the effective neutron multiplication factor $k$, the average number of neutrons released per fission event that go on to cause another fission event rather than being absorbed or leaving the material. When $k=1$, the mass is critical, and the chain reaction is self-sustaining. So for each neutron we should log the amount of neutrons it generates before it dies. Afterwards we can take the average value of all of these and get an idea of the multiplication factor $k$.

### Spontaneous Fission

U235 has a halflife of 7.037 10^8 years and generates 1.86 neutrons. Spontaneous fission occurs 0.0003 times per g per s."""

# ╔═╡ b2955482-0faa-11eb-2a3f-d71bf8a4bc7d
ρᵤ * 4/3 * π * 9^3 * 0.0003

# ╔═╡ Cell order:
# ╟─bd6092b0-0fa7-11eb-0ec2-cdc01bf1360b
# ╟─0911b590-0fa8-11eb-0b36-315109cc9657
# ╠═7676ed80-0fa8-11eb-2998-d398e4701fde
# ╠═18261250-0fa9-11eb-2fda-8b8683d5a90c
# ╠═1c83c71e-0fa9-11eb-28d3-49496955dc7f
# ╠═39ea5400-0fa9-11eb-185b-096971c52c61
# ╠═40c34200-0fa9-11eb-12b5-6196f71e1a7c
# ╟─8553233e-0fa9-11eb-119d-01b79be544b7
# ╠═95544670-0fa9-11eb-36a5-6987b08129a0
# ╟─0a643b50-0faa-11eb-2a07-93790802d704
# ╠═282bd3f0-0faa-11eb-2357-278dee39e9a0
# ╟─408cfa50-0faa-11eb-005a-21e46e3bdec4
# ╠═649b7a20-0faa-11eb-0ede-a7a1e709af7a
# ╟─8031178e-0faa-11eb-3ef7-c94a993bc778
# ╠═b2955482-0faa-11eb-2a3f-d71bf8a4bc7d
