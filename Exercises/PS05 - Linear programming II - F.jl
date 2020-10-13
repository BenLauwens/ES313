### A Pluto.jl notebook ###
# v0.12.3

using Markdown
using InteractiveUtils

# ╔═╡ a62a0de6-04b8-11eb-342f-bfea16900b85
using PlutoUI

# ╔═╡ eb1b597a-04b8-11eb-08ea-7bb72fd33686
using JuMP, GLPK, Tulip, Optim

# ╔═╡ 56a7c778-04c1-11eb-03c0-fd5d27d989b1
# Non-linear problem
using Ipopt, Plots

# ╔═╡ 86702ce8-04b7-11eb-22d1-b7f1437cf740
md"""
# Linear programming II
## Maximize flow in a network

We try to maximize the flow in a network using Linear Programming.



Let $N = (V, E)$ be a directed graph, where $V$ denotes the set of vertices and $E$ is the set of edges. Let $s ∈ V$ and $t ∈ V$ be the source and the sink of $N$, respectively. The capacity of an edge is a mapping $c : E \mapsto \mathbb{R}^+$, denoted by $c_{u,v}$ or $c(u, v)$. It represents the maximum amount of flow that can pass through an edge.

A flow is a mapping $f : E \mapsto \mathbb{R}^+$ , denoted by $f_{uv}$ or  $f(u, v)$, subject to the following two constraints:

* Capacity Constraint: 

```math
\forall e \in E: f_{uv} \le c_{uv}
```

* Conservation of Flows: 

```math
\forall v \in V\setminus\{s,t\} : \sum_{u:(u,v)\in E}f_{uv} = \sum_{w:(v,w)\in E} f_{vw}
```

We want to maximize the flow in the network, i.e. 
```math
\max |f| = \max \sum_{v:(s,v)\in E}f_{sv} = \max \sum_{v:(v,t)\in E}f_{vt}
```


#### Setting:
Consider the following network:

$(PlutoUI.LocalResource("./img/network.png"))

We want to:
1. Determine the maximal flow in the network
2. Be able to get a troughput of 35 from the source node to the sink node, whilst keeping the costs limited. Each link has a possible increase, with an associated cost (cf. table)

$(PlutoUI.LocalResource("./img/networkcost.png"))
"""

# ╔═╡ caf5c6d8-04b8-11eb-1c04-0966207fbf28
# given set-up
begin
	# Topology and maximum flow matrix
	C = [0 13 6 10 0 0 0;
		 0 0  0  9 5 7 0;
		 0 0  0  8 0 0 0;
		 0 0  0  0 3 0 12;
		 0 0  0  0 0 4 6;
		 0 0  0  0 0 0 9;
		 0 0  0  0 0 0 0;
	];
	# extra capacity
	xcap = [ 0 6  4  3 0 0 0;
			 0 0  0  4 5 3 0;
			 0 0  0  5 0 0 0;
			 0 0  0  0 2 0 5;
			 0 0  0  0 0 2 4;
			 0 0  0  0 0 0 5;
			 0 0  0  0 0 0 0;
	];
	# cost per increased capacity
	xcost= [ 0 2.8  2.5  2.8 0   0   0;
			 0 0    0    2.5 3.1 1.6 0;
			 0 0    0    3.9 0   0   0;
			 0 0    0    0   2.8 0   1.6;
			 0 0    0    0   0   4.6 2.9;
			 0 0    0    0   0   0   1.8;
			 0 0    0    0   0   0   0;
	];
end

# ╔═╡ b87810d0-0d49-11eb-0179-8df04359fbf0
let
	model = Model(Tulip.Optimizer)
	@variable(model, f[1:7,1:7] >= 0)
	# contrainte
	@constraint(model, capacity, f .<= C)
	for i in 2:6
		@constraint(model, sum(f[i,:]) == sum(f[:,i])) # équilibre par noeud
	end
	@objective(model, Max, sum(f[1,:]))
	optimize!(model)
	termination_status(model)
	# débit réalisé
	objective_value(model)
	# répartition
	round.(value.(f), digits=2)
end

# ╔═╡ fd4e40ba-0d4b-11eb-3fcf-73167f945637
let
	model = Model(Tulip.Optimizer)
	@variable(model, f[1:7,1:7] >= 0)
	# contrainte
	@constraint(model, capacity, f .<= C + xcap)
	for i in 2:6
		@constraint(model, sum(f[i,:]) == sum(f[:,i])) # équilibre par noeud
	end
	@constraint(model, sum(f[1,:]) == 35)
	
	@objective(model, Min, sum((f - C) .* xcost))
	optimize!(model)
	termination_status(model)
	# débit réalisé
	objective_value(model)
	# répartition
	res = round.(value.(f), digits=2) - C
	# coût de l'augmentation des capacités
	sum((res .> 0) .* res .* xcost)
#	ind = findall(x-> x>0, res)
end

# ╔═╡ 734bc850-0d4c-11eb-04da-275cb189c9ea
xcost

# ╔═╡ d3dcd770-058d-11eb-2829-fbb18e85f401


# ╔═╡ dd30bfc4-0d2d-11eb-0709-e93b631c4997


# ╔═╡ 66f75a6e-0d2f-11eb-17f3-355321d4e630


# ╔═╡ a510792e-04c0-11eb-0f6e-a7e40dfe602c
md"""
## Optimizing an investment portfolio

In 1952 [Harry Max Markowitz](https://en.wikipedia.org/wiki/Harry_Markowitz) proposed a new approach for the optimization of an investment portfolio. This ultimately led to him winning the Nobel Prize in Economic Sciences in 1990. The idea is relatively simple:

Given a portfolio with $n$ stock proportions $S_1,S_2,\dots, S_n$, we want to maximize the return (=profit) and minimize the risk. The goal is to find the values $S_i$ that lead to either a minimum risk attribution with a minimal return or that lead to a maximum return attribution with a maximal risk.

Remembering that $\sigma^{2}_{\sum_{i=1}^{n}X_i}= \sum_{i=1}^{n}\sigma^2_{X_i} + \sum_{i \ne j}\text{Cov}(X_i,X_j) $, the risk can be expressed in terms of the covariance matrix $\Sigma$:

$$S^\mathsf{T} \Sigma S $$ 

The return can be expressed as:
$$\mu^\mathsf{T}S$$

Consider the following portfolio problem:
You are given the covariance matrix and expected returns and you want study several approaches. For each case you should formulate a proper Linear/Quadratic Programming form.
1. Ignore the risk and go for optimal investment (i.e. maximal return)
2. Same as (1), but a single stock can be at most 40% of the portfolio
3. Minimize the risk, with a lower bound on the return e.g. with at least 35% expected return
4. Make a graph for:
    * the minimal risk in fuction of the expected return. 
    * the distribution of the portfolio with the minimal risk in function of the expected return
    * the final portfolio value in function of the expected return
"""

# ╔═╡ c4eca510-04c0-11eb-0e29-a5dcc1386bd5
# data for problem
begin
	P = [60; 127; 4; 50; 150; 20] # stock prices
	μ = [0.2; 0.42; 1.; 0.5; 0.46; 0.3] # expected returns
	Σ = [0.032 0.005 0.03 -0.031 -0.027 0.01;
		 0.005 0.1 0.085 -0.07 -0.05 0.02;
		 0.03 0.085 1/3 -0.11 -0.02 0.042;
		 -0.031 -0.07 -0.11 0.125 0.05 -0.06;
		 -0.027 -0.05 -0.02 0.05 0.065 -0.02;
		 0.01 0.02 0.042 -0.06 -0.02 0.08]; # covariance matrix
end

# ╔═╡ 8f58e940-0d4e-11eb-10ab-6f666a513b44
let 
	# ignorance v1.0
	model = Model(Ipopt.Optimizer)
	@variable(model, S[1:length(μ)] >= 0)
	@constraint(model, sum(S) == 1)
	@objective(model, Max, μ' * S)
	optimize!(model)
	termination_status(model)
	value.(S)
end

# ╔═╡ 114ca444-0d4f-11eb-0ea5-254084e20f7c
let 
	# ignorance v1.0
	model = Model(Ipopt.Optimizer)
	@variable(model, S[1:length(μ)] >= 0)
	@constraint(model, sum(S) == 1)
	@constraint(model, S .<= 0.4)
	@objective(model, Max, μ' * S)
	optimize!(model)
	termination_status(model)
	value.(S)
end

# ╔═╡ 0ff4b924-0d51-11eb-393b-f7d0b49bdd90
let
	"""
	Minimize the risk, with a lower bound on the return e.g. with at least 35% expected return


	"""
	model = Model(Ipopt.Optimizer)
	@variable(model, S[1:length(μ)] >= 0)
	
	@constraint(model, sum(S) == 1)
	@constraint(model, μ' * S >= 0.35)
	
	@objective(model, Min, S' * Σ * S)
	
	optimize!(model)
	termination_status(model)
	value.(S)
end

# ╔═╡ 4431e5f8-0d4f-11eb-17b0-ef8a02a6134b
begin
	"""
	Minimize the risk, with a lower bound on the return e.g. with at least 35% expected return


	"""
	
	"""
		optimme(ret_min::Float64)
	
	pour un rapport minimal demandé, rend le risque, la composition et le rapport
	"""
	function optimme(ret_min::Float64)
		model = Model(Ipopt.Optimizer)
		@variable(model, S[1:length(μ)] >= 0)
		@constraint(model, sum(S) == 1)
		@constraint(model, μ' * S >= ret_min)
		@objective(model, Min, S' * Σ * S)
		optimize!(model)
		return objective_value(model), value.(S), μ' * value.(S)
	end
	
	x = range(minimum(μ), maximum(μ), length=21)
	minrisk = Float64[]
	composition = []
	retour = Float64[]
	for val in x
		res = optimme(val)
		push!(minrisk, res[1])
		push!(composition, res[2])
		push!(retour, res[3])
	end
end

# ╔═╡ a37f36e8-0d52-11eb-128e-9339b3a87082
plot(x, minrisk, marker=:circle, xlabel="expected minimal return", ylabel="minimal risk", label="", yscale=:log10)

# ╔═╡ 1d5b05b2-0d53-11eb-196f-db366bc7ce2e
begin
	vals = permutedims(hcat(composition...))
plot(x, vals, marker=:circle, xlabel="expected minimal return", ylabel="pourcentage", label=["S1" "S2" "S3" "S4" "S5" "S6"])
end

# ╔═╡ ce229bda-0d53-11eb-1361-9ffe474d289d
plot(x,cumsum(vals; dims=2), marker=:circle, xlabel="expected minimal return", ylabel="cumulative pourcentage", label=["S1" "S2" "S3" "S4" "S5" "S6"])

# ╔═╡ 52c8019a-0d54-11eb-2509-f13b9746ce04
plot(x,retour)

# ╔═╡ c6cb56d8-058d-11eb-2f71-73a5e5ca3dd0


# ╔═╡ d9e81b48-0d32-11eb-33fe-a99c034737d1


# ╔═╡ 12598884-0d33-11eb-01ef-1535f185732c


# ╔═╡ 06080804-0d34-11eb-2712-39413847a60d


# ╔═╡ bf633da2-0d35-11eb-215c-c76227572e1b


# ╔═╡ 01bc23b2-0d36-11eb-16a1-c7cbe39cbe95


# ╔═╡ 99cd073c-0d36-11eb-3fc3-7ff361ed70fe


# ╔═╡ fdc3f8e2-0d36-11eb-3de7-5de4d183abb7


# ╔═╡ cb6898d6-0565-11eb-2a3c-1514a0fa4f50
md"""
## Optimal course planning
Suppose a professor teaches a course with $N=20$ lectures. We must decide how to split each lecture between theory and applications. Let $T_i$ and $A_i$ denote the fraction of the i$^{\text{th}}$ lecture devoted to theory and applications, for $i=1,\dots,N$. We can already determine the following: 

```math
\forall i: T_i \ge 0, A_i \ge 0, T_i+A_i =1.
```

As you may know from experience, you need to cover a certain amount of theory before you can start doing applications. For this application consider the following model:

$$\sum_{i=1}^{N} A_i \le \phi \left( \sum_{i=1}^{N} T_i \right)$$

We interpret $\phi(u)$ as the cumulative amount of applications that can be covered, when the cumulative amount of theory covered is $u$. We will use the simple form $\phi(u) = a(u − b)$, with $a=2, b=3$, which means that no applications can be covered until $b$ lectures of the theory are covered; after that, each lecture of theory covered opens the possibility of covering a lecture on applications.

Psychological studies have shown that the theory-applications split affects the emotional state of students differently. Let $s_i$ denote the emotional state of a student after lecture $i$, with $s_i = 0$ meaning neutral, $s_i > 0$ meaning happy, and $s_i < 0$ meaning unhappy. Careful studies have shown that $s_i$ evolves via a linear recursion dynamic:

$$s_i =(1−\theta)s_{i−1} +\theta(\alpha T_i +\beta A_i)\text{ with }\theta \in[0,1]$$ 

with $s_0=0$. In order to make sure that the student leave with a good feeling at the end of the course, we try to maximize $s_N$, i.e. the emotional state after the last lecture.

Questions:
1. Determine the optimal split that leads to the most positive emotional state (for $\theta = 0.05, \alpha = -0.1, \beta = 1.4$);
2. Show the course repartition graphically
3. Determine values for $\alpha$ and $\beta$ that lead to a neutral result at the end of the course. Can you give an interpretation to these values?
"""

# ╔═╡ 85edae78-0d55-11eb-3475-f3e435626206
begin
	Θ = 0.05
	α = -0.1
	β = 1.4
	a = 2
	b = 3
	s₀ = 0
	N = 20
	let
		model = Model(Ipopt.Optimizer)
		# variables
		@variable(model, T[1:N] >= 0)
		@variable(model, A[1:N] >= 0)
		
		@constraint(model, T + A .== 1)
		for i = 1:N
			if i <= 3
				@constraint(model, T[i] == 1)
				@constraint(model, A[i] == 0)
			else
				@constraint(model, sum(A[1:i]) <= a*(sum(T[1:i]) - b))
			end
		end
		
		S = Any[s₀]
		for i = 2:N
			push!(S, (1-Θ) * S[i-1] + Θ * ( α * T[i] + β * A[i]))
		end
		
		@objective(model, Max, S[end])
		optimize!(model)
		plot(collect(1:N),  value.(T), marker=:circle)
		plot!(collect(1:N), value.(A), marker=:circle)
	end
end

# ╔═╡ b76bae36-058d-11eb-216c-dfb8abd85772


# ╔═╡ Cell order:
# ╠═a62a0de6-04b8-11eb-342f-bfea16900b85
# ╠═eb1b597a-04b8-11eb-08ea-7bb72fd33686
# ╟─86702ce8-04b7-11eb-22d1-b7f1437cf740
# ╠═caf5c6d8-04b8-11eb-1c04-0966207fbf28
# ╠═b87810d0-0d49-11eb-0179-8df04359fbf0
# ╠═fd4e40ba-0d4b-11eb-3fcf-73167f945637
# ╠═734bc850-0d4c-11eb-04da-275cb189c9ea
# ╟─d3dcd770-058d-11eb-2829-fbb18e85f401
# ╟─dd30bfc4-0d2d-11eb-0709-e93b631c4997
# ╟─66f75a6e-0d2f-11eb-17f3-355321d4e630
# ╟─a510792e-04c0-11eb-0f6e-a7e40dfe602c
# ╠═56a7c778-04c1-11eb-03c0-fd5d27d989b1
# ╠═c4eca510-04c0-11eb-0e29-a5dcc1386bd5
# ╠═8f58e940-0d4e-11eb-10ab-6f666a513b44
# ╠═114ca444-0d4f-11eb-0ea5-254084e20f7c
# ╠═0ff4b924-0d51-11eb-393b-f7d0b49bdd90
# ╠═4431e5f8-0d4f-11eb-17b0-ef8a02a6134b
# ╠═a37f36e8-0d52-11eb-128e-9339b3a87082
# ╠═1d5b05b2-0d53-11eb-196f-db366bc7ce2e
# ╠═ce229bda-0d53-11eb-1361-9ffe474d289d
# ╠═52c8019a-0d54-11eb-2509-f13b9746ce04
# ╟─c6cb56d8-058d-11eb-2f71-73a5e5ca3dd0
# ╟─d9e81b48-0d32-11eb-33fe-a99c034737d1
# ╟─12598884-0d33-11eb-01ef-1535f185732c
# ╟─06080804-0d34-11eb-2712-39413847a60d
# ╟─bf633da2-0d35-11eb-215c-c76227572e1b
# ╟─01bc23b2-0d36-11eb-16a1-c7cbe39cbe95
# ╟─99cd073c-0d36-11eb-3fc3-7ff361ed70fe
# ╟─fdc3f8e2-0d36-11eb-3de7-5de4d183abb7
# ╟─cb6898d6-0565-11eb-2a3c-1514a0fa4f50
# ╠═85edae78-0d55-11eb-3475-f3e435626206
# ╟─b76bae36-058d-11eb-216c-dfb8abd85772
