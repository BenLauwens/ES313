### A Pluto.jl notebook ###
# v0.16.1

using Markdown
using InteractiveUtils

# ╔═╡ a62a0de6-04b8-11eb-342f-bfea16900b85
begin
	using Pkg
	cd(joinpath(dirname(@__FILE__),".."))
    Pkg.activate(pwd())
	using PlutoUI
	using JuMP, GLPK, Tulip, Optim
	# Non-linear problem
	using Ipopt, Plots
	#using JuMP, Tulip, GLPK, LinearAlgebra
	#using Distributions, Plots, StatsPlots, LaTeXStrings, Measures
end


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

$(PlutoUI.LocalResource("./Exercises/img/network.png"))

We want to:
1. Determine the maximal flow in the network
2. Be able to get a troughput of 35 from the source node to the sink node, whilst keeping the costs limited. Each link has a possible increase, with an associated cost (cf. table)

$(PlutoUI.LocalResource("./Exercises/img/networkcost.png"))
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

# ╔═╡ 5d0d7415-38fe-4c31-9c3d-59b2cbb54a8e
let
	model = Model(Ipopt.Optimizer)
	@variable(model, F[1:7,1:7])
	@constraint(model, F .<= C) # limite capacité
	for i = 2:6
		@constraint(model, sum(F[i,:]) == sum(F[:,i]))
	end
	@constraint(model, F .>= 0)
	@objective(model, Max, sum(F[1,:]))
	optimize!(model)
	abs.(round.(value.(F),digits=6))
end

# ╔═╡ 0f118a6f-9609-44b3-9e08-2e809f516377
let
	model = Model(Ipopt.Optimizer)
	@variable(model,F[1:size(C,1), 1:size(C,2)])
	# targt
	@objective(model, Max, sum(F[1,:])) #@objective(model, Max, sum(F[:,end]))
	# simplifier un peu
	for ind in findall(iszero,C)
		JuMP.fix(F[ind], 0., force=true)
	end
	# constraints
	for i = 2:6
		@constraint(model, sum(F[i,:]) == sum(F[:,i]))
	end
	@constraint(model, F .<= C)
	@constraint(model, F .>= 0)
	#
	optimize!(model)
	value.(F)
	# actuellement débit = 27
end

# ╔═╡ e6ba22db-4fc3-4a23-bb56-fa500ef616d2
let	
	model = Model(Ipopt.Optimizer)
	@variable(model,F[1:size(C,1), 1:size(C,2)])
	# targt
	@objective(model, Min, sum(F .* xcost)) # faux raisonnement :-(
	# simplifier un peu
	for ind in findall(iszero,C)
		JuMP.fix(F[ind], 0., force=true)
	end
	# constraints
	for i = 2:6
		@constraint(model, sum(F[i,:]) == sum(F[:,i]))
	end
	@constraint(model, F .<= C .+ xcap)
	@constraint(model, F .>= 0)
	@constraint(model, sum(F[1,:]) == 35.)
	#
	optimize!(model)
	value.(F)
	# actuellement débit = 27
	Δ_cap = value.(F) - C
	ind_pos = Δ_cap .> 0
	sum((Δ_cap .* xcost)[ind_pos])
	Δ_cap
end

# ╔═╡ c38feffb-245b-4812-bcec-bdecd43d6c6c
let	
	model = Model(Ipopt.Optimizer)
	@variable(model,F[1:size(C,1), 1:size(C,2)]) # capacité existante
	@variable(model,G[1:size(C,1), 1:size(C,2)]) # capacité supplémentaire
	# target
	@objective(model, Min, sum(G .* xcost)) # bon raisonnement :-)
	# simplifier un peu
	for ind in findall(iszero,C)
		JuMP.fix(F[ind], 0., force=true)
		JuMP.fix(G[ind], 0., force=true)
	end
	# constraints
	for i = 2:6
		@constraint(model, sum(F[i,:] + G[i,:]) == sum(F[:,i] + G[:,i]))
	end
	@constraint(model, F .<= C)
	@constraint(model, F .>= 0)
	@constraint(model, G .<= xcap)
	@constraint(model, G .>= 0)
	@constraint(model, sum(F[1,:]+ G[1,:]) == 35.)
	#
	optimize!(model)
	value.(F)
	# actuellement débit = 27
	sum(value.(G) .* xcost)
	value.(G)
end

# ╔═╡ d82dbb55-1d31-445a-b5e4-ec11ec4fcf65


# ╔═╡ 84804f16-8dfb-4bad-afe7-fe8ccd854e39


# ╔═╡ d4f240a2-73c5-4828-b728-d922db6148b8


# ╔═╡ 27080e2e-a7df-4acb-93a9-98f2352fd8b5


# ╔═╡ 508ae591-46f9-4dd9-97b8-08a5fd90e6e1


# ╔═╡ d3dcd770-058d-11eb-2829-fbb18e85f401
begin
	model = Model(Ipopt.Optimizer)
	@variable(model, F[1:size(C,1),1:size(C,2)])
	# gekende waarde op nul zetten
	for ind in findall(iszero, C)
		JuMP.fix(F[ind],0.)
	end
	@objective(model, Max, sum(F[1,:])) # of ook @objective(model, Max, sum(F[:,end]))
	# capacity constraint
	@constraint(model, F .<= C)
	# maintain flow
	for i = 2:6
		@constraint(model, sum(F[:,i]) == sum(F[i,:]))
	end
	
	optimize!(model)
end

# ╔═╡ c78e64e1-df73-4c6d-b705-2e1766d8ef3a
let
	# capaciteitsverhoging
	model = Model(Ipopt.Optimizer)
	@variable(model, F[1:size(C,1),1:size(C,2)])
	# gekende waarde op nul zetten
	for ind in findall(iszero, C)
		JuMP.fix(F[ind],0.)
	end
	# minimise total cost 
	@objective(model, Min, sum(F .* xcost) ) # hier zit een redeneringsprobleem (!)
	# better?
	#helpfun(F) = F .- C .> 0
	#@objective(model, Min, filter(x-> x>0, (F .- C) .* xcost))
	
	# capacity constraint
	@constraint(model, F .<= C .+ xcap)
	@constraint(model, F .>= 0)
	# maintain flow
	for i = 2:6
		@constraint(model, sum(F[:,i]) == sum(F[i,:]))
	end
	# demand specifc throughput
	@constraint(model, sum(F[1,:]) == 35)
	
	optimize!(model)
	value.(F)
	# value of extra cost?
	Δ_cap = value.(F) .- C
	indpos = Δ_cap .> 0.
	sum(Δ_cap[indpos] .* xcost[indpos])
	#helpfun(F)
end

# ╔═╡ 74a20456-a91a-44de-9e4b-3e6d86440392
let
	# capaciteitsverhoging
	model = Model(Ipopt.Optimizer)
	@variable(model, F[1:size(C,1),1:size(C,2)]) # oorspronkelijk
	@variable(model, G[1:size(C,1),1:size(C,2)]) # extra
	# gekende waarde op nul zetten
	for ind in findall(iszero, C)
		JuMP.fix(F[ind],0.)
		JuMP.fix(G[ind],0.)
	end
	# minimise total cost of additional capacity
	@objective(model, Min, sum(G .* xcost) )
	
	# capacity constraint
	@constraint(model, F .<= C)
	@constraint(model, G .<= xcap)
	@constraint(model, F .>= 0)
	@constraint(model, G .>= 0)
	# maintain flow
	for i = 2:6
		@constraint(model, sum(F[:,i] .+ G[:,i]) == sum(F[i,:] .+ G[i,:]))
	end
	# demand specifc throughput
	@constraint(model, sum(F[1,:] .+ G[1,:]) == 35)
	
	optimize!(model)
	value.(F) .+ value.(G)
	# total cost:
	sum(value.(G) .* xcost)
end

# ╔═╡ 6ea03142-b487-4459-8391-cd50dae56340


# ╔═╡ 42371ec0-55fa-459b-bcb2-a6ea4363d876
value.(F)

# ╔═╡ 0a95f12e-c5eb-490a-bc7c-0cd7a70edddb
sum(value.(F)[1,:])

# ╔═╡ ef581235-7b51-4d2d-8097-7f6637c40b24
let
	model = Model(Ipopt.Optimizer)
	@variable(model, F[1:size(C,1),1:size(C,2)] >=0)
	# gekende waarde op nul zetten
	for ind in findall(iszero, C)
		JuMP.fix(F[ind],0, force=true)
	end
	@objective(model, Max, sum(F[1,:]))
	# capacity constraint
	@constraint(model, F .<= C .+ xcap)
	# maintain flow
	for i = 2:6
		@constraint(model, sum(F[:,i]) == sum(F[i,:]))
	end
	
	optimize!(model)
	value.(F)
end

# ╔═╡ 1283cdae-1a6b-4a4e-be2b-a9072bfc3972


# ╔═╡ 55ac8bb2-eb86-4536-9a89-245cf3883763


# ╔═╡ 7e852fdd-4363-4e15-ab24-e76448fbe1cf


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

# ╔═╡ 0589b400-06a9-4f91-99aa-97e52f191dd0
let
	# Q1
	model = Model(Ipopt.Optimizer)
	# variables 
	@variable(model,S[1:length(μ)]) # % van ieder aandeel in mijn portefeuille
	# objective
	@objective(model, Max, μ'*S) # max profit, risico bestaat niet
	# constraints
	@constraint(model, sum(S) == 1.) # total 100 %
	@constraint(model, S .>= 0.) # geen negatieve bijdrages
	# los het op
	optimize!(model)
	value.(S)
	
	# Q2
	model = Model(Ipopt.Optimizer)
	# variables 
	@variable(model,S[1:length(μ)]) # % van ieder aandeel in mijn portefeuille
	# objective
	@objective(model, Max, μ'*S) # max profit, risico bestaat niet
	# constraints
	@constraint(model, sum(S) == 1.) # total 100 %
	@constraint(model, S .>= 0.) # geen negatieve bijdrages
	@constraint(model, S .<= 0.4) # diversificatie!
	# los het op
	optimize!(model)
	value.(S)
	
	# Q3 
	model = Model(Ipopt.Optimizer)
	# variables 
	@variable(model,S[1:length(μ)]) # % van ieder aandeel in mijn portefeuille
	# objective
	@objective(model, Min, S'*Σ*S) # min risk
	# constraints
	@constraint(model, μ'*S >= 0.35) # min return van 0.35
	@constraint(model, sum(S) == 1.) # total 100 %
	@constraint(model, S .>= 0.) # geen negatieve bijdrages
	@constraint(model, S .<= 0.4) # diversificatie!
	# los het op
	optimize!(model)
	value.(S), μ'*value.(S)
	termination_status(model)
end

# ╔═╡ e15f2647-04e0-4882-a193-5a63813852d4
let
	# ignorer le risque & maximiser le gain
	model = Model(Ipopt.Optimizer)
	@variable(model, S[1:length(P)])
	@constraint(model, S .<= 1.) # pas plus de 100% par action
	@constraint(model, S .>= 0.) # pas de proportion négative
	@constraint(model, sum(S) == 1.) # Σproportion = 1
	@objective(model, Max, μ' * S)
	optimize!(model)
	value.(S)
	# ignorer le risque & maximiser le gain & <=40% par action
	model = Model(Ipopt.Optimizer)
	@variable(model, S[1:length(P)])
	@constraint(model, S .<= 0.4) # pas plus de 100% par action
	@constraint(model, S .>= 0.) # pas de proportion négative
	@constraint(model, sum(S) == 1.) # Σproportion = 1
	@objective(model, Max, μ' * S)
	optimize!(model)
	value.(S)
	# minimiser le risque & gain minimal de 0.35
	model = Model(Ipopt.Optimizer)
	@variable(model, S[1:length(P)])
	@constraint(model, S .<= 0.4) # pas plus de 100% par action
	@constraint(model, S .>= 0.) # pas de proportion négative
	@constraint(model, sum(S) == 1.) # Σproportion = 1
	@constraint(model, μ' * S >= 0.35) # gain minimal à assurer
	@objective(model, Min, S' * Σ * S)
	
	optimize!(model)
	value.(S)
	
end

# ╔═╡ c6cb56d8-058d-11eb-2f71-73a5e5ca3dd0


# ╔═╡ ac5e426e-55f6-4ed0-98e4-19fb00ff1aec
let
	model = Model(Tulip.Optimizer)
	N = 20
	@variable(model, T[1:N] >= 0) # theorie part
	@variable(model, A[1:N] >= 0) # application part
	@constraint(model, T .<= 1) # logic
	@constraint(model, A .<= 1) # logic
	# teaching model
	a = 2; b = 3;
	@constraint(model, sum(A[1:N]) <= sum( T[b+1:N]))
	for i = 1:N
		if i <= b
			JuMP.fix(T[i], 1., force=true)
			JuMP.fix(A[i], 0., force=true)
		else
			@constraint(model, T[i] + A[i] == 1.)
		end
	end
	# emotional states
	s₀ = 0.
	α = -0.1; θ = 0.05; β = 1.4;
	S = [(1-θ)*s₀ + θ*(α*T[1] + β*A[1])]
	for i = 2:N
		push!(S, (1-θ)*S[i-1] + θ*(α*T[i-1] + β*A[i-1]))
	end
	@objective(model, Max, S[end])
	optimize!(model)
	termination_status(model)
	plot(value.(T))
	plot!(value.(A))
end

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

# ╔═╡ b76bae36-058d-11eb-216c-dfb8abd85772


# ╔═╡ Cell order:
# ╠═a62a0de6-04b8-11eb-342f-bfea16900b85
# ╠═5d0d7415-38fe-4c31-9c3d-59b2cbb54a8e
# ╟─86702ce8-04b7-11eb-22d1-b7f1437cf740
# ╠═0f118a6f-9609-44b3-9e08-2e809f516377
# ╠═e6ba22db-4fc3-4a23-bb56-fa500ef616d2
# ╠═c38feffb-245b-4812-bcec-bdecd43d6c6c
# ╠═caf5c6d8-04b8-11eb-1c04-0966207fbf28
# ╠═d82dbb55-1d31-445a-b5e4-ec11ec4fcf65
# ╠═84804f16-8dfb-4bad-afe7-fe8ccd854e39
# ╠═d4f240a2-73c5-4828-b728-d922db6148b8
# ╠═27080e2e-a7df-4acb-93a9-98f2352fd8b5
# ╠═508ae591-46f9-4dd9-97b8-08a5fd90e6e1
# ╠═d3dcd770-058d-11eb-2829-fbb18e85f401
# ╠═c78e64e1-df73-4c6d-b705-2e1766d8ef3a
# ╠═74a20456-a91a-44de-9e4b-3e6d86440392
# ╠═6ea03142-b487-4459-8391-cd50dae56340
# ╠═42371ec0-55fa-459b-bcb2-a6ea4363d876
# ╠═0a95f12e-c5eb-490a-bc7c-0cd7a70edddb
# ╠═ef581235-7b51-4d2d-8097-7f6637c40b24
# ╠═1283cdae-1a6b-4a4e-be2b-a9072bfc3972
# ╠═55ac8bb2-eb86-4536-9a89-245cf3883763
# ╠═7e852fdd-4363-4e15-ab24-e76448fbe1cf
# ╟─a510792e-04c0-11eb-0f6e-a7e40dfe602c
# ╠═0589b400-06a9-4f91-99aa-97e52f191dd0
# ╠═c4eca510-04c0-11eb-0e29-a5dcc1386bd5
# ╠═e15f2647-04e0-4882-a193-5a63813852d4
# ╠═c6cb56d8-058d-11eb-2f71-73a5e5ca3dd0
# ╠═ac5e426e-55f6-4ed0-98e4-19fb00ff1aec
# ╟─cb6898d6-0565-11eb-2a3c-1514a0fa4f50
# ╠═b76bae36-058d-11eb-216c-dfb8abd85772
