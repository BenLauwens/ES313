### A Pluto.jl notebook ###
# v0.19.12

using Markdown
using InteractiveUtils

# ╔═╡ 10349518-03ca-11eb-09b2-69c80c4662ac
begin
	using Pkg
	cd(joinpath(dirname(@__FILE__),".."))
    Pkg.activate(pwd())
	using JuMP, Tulip, GLPK, LinearAlgebra, Ipopt
	using Distributions, Plots, StatsPlots, LaTeXStrings, Measures
	using PlutoUI
	using Optim
end

# ╔═╡ 10850c10-3b60-406a-8741-5ed5618af8e9
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

# ╔═╡ f7f3a256-03c6-11eb-2c1e-83cc62bf55e6
md"""
# Linear programming
We will be using [JuMP](https://jump.dev/JuMP.jl/stable/) as a general framework, combined with [Tulip](https://github.com/ds4dm/Tulip.jl) or [GLPK](https://github.com/jump-dev/GLPK.jl) as a solver.
"""

# ╔═╡ 7910d53e-03ca-11eb-1536-7fc4c236e10a
md"""
## Application - Employee planning
We manage a crew of call center employees and want to optimise our shifts in order to reduce the total payroll cost. Employees have to work for five consecutive days and are then given two days off. The current policy is simple: each day gets the same amount of employees (currently we have 5 persons per shift, which leads to 25 persons on any given day).

We have some historical data that gives us the minimum amount of calls we can expect: Mon: 22, Tue: 17, Wed:13, Thu:14, Fri: 15, Sat: 18, Sun: 24

Employees are payed € 96 per day of work. This lead to the current payroll cost of 25x7x96 = € 16.800. You need to optimize employee planning to reduce the payroll cost.


| Schedule | Days worked | Attibuted Pers | Mon | Tue | Wed | Thu | Fri | Sat | Sun |
|----------|-------------|----------------|-----|-----|-----|-----|-----|-----|-----|
| A | Mon-Fri | 5 | W | W | W | W | W | O | O |
| B | Tue-Sat | 5 | O | W | W | W | W | W | O |
| C | Wed-Sun | 5 | O | O | W | W | W | W | W |
| D | Thu-Mon | 5 | W | O | O | W | W | W | W |
| E | Fri-Tue | 5 | W | W | O | O | W | W | W |
| F | Sat-Wed | 5 | W | W | W | O | O | W | W |
| G | Sun-Thu | 5 | W | W | W | W | O | O | W |
| Totals: | - | 35 | 5 | 5 | 5 | 5 | 5 | 5 | 5 |
| Required: | - | - | 22 | 17 | 13 | 14 | 15 | 18 | 24 |

### Mathematical formulation
We need do formaly define our decision variables, constraints and objective function.
* decision variables: the amount of persons attributed to each schedule ( ``Y = [y_1,y_2,\dots,y_7]^{\intercal} ``)
* objective function: the payroll cost
  
  Suppose the matrix ``A`` is the matrix indicating the workload for each schedule (in practice ``W=1`` and ``O=0``):
```math
A = \begin{bmatrix}  
W & W & W & W & W & O & O \\
O & W & W & W & W & W & O \\
O & O & W & W & W & W & W \\
W & O & O & W & W & W & W \\
W & W & O & O & W & W & W \\
W & W & W & O & O & W & W \\
W & W & W & W & O & O & W 	\\
\end{bmatrix}
```

  Now $$Y*A'$$ gives us a vector indicating the amount of employees working on a given day. Suppose we also use the vector $$c$$ to indicate the salary for a given day (in this case $$c = [96,96,96,\dots,96]$$). 

We are now able to write our objective function:
```math
\min Z = c^\intercal A^\intercal Y
```

* constraints (1): each day we need at least enough employees to cover all incoming calls. Suppose we use the vector $$b$$ to indicate the amount of incoming calls for a given day. We are able to write the constraints in a compact way:

```math
\text{subject to } A^\intercal Y  \ge b 
```

* constraints (2): we also want to avoid a negative amount of attributed employees on any given day, since this would lead to a negative payroll cost:
```math
\text{and }Y \ge 0
```

* $\forall Y : Y \in \mathbb{N}$
### Implementation
"""

# ╔═╡ 572d14c4-03cb-11eb-2b68-234b3d7e9e8e
begin
	# basic data
	A = ones(Bool,7,7) - diagm(-1=>ones(Bool,6), -2=> ones(Bool,5), 5=>ones(Bool,2), 6=>ones(Bool,1))
	Y = [5,5,5,5,5,5,5]
	B = [22,17,13,14,15,18,24]
	C = [96,96,96,96,96,96,96];
	A
end

# ╔═╡ 4ba4687e-087f-11eb-1cb0-2581818cbd93
# A' * Y .> B
C' * A' * Y

# ╔═╡ 79351ee4-087f-11eb-147d-d389de200857
let
	model = Model(GLPK.Optimizer)
	@variable(model, Y[1:7] >= 0, Int)
	@constraint(model, A' * Y .>= B)
	@objective(model, Min, C' * A' * Y)
	optimize!(model)
	println("termination status: $(termination_status(model))")
	println("objective value:    $(objective_value(model))")
	#A' * value.(Y) .> B
	println("personnel assignment per schedule: $(value.(Y))")
end

# ╔═╡ 3bafd152-6724-4847-a79d-f2340e2ab5e4


# ╔═╡ 4bc4c2aa-04b4-11eb-2b6e-452d4ecc258a
md"""
### Adding uncertainty
Up to now, we have had constant numbers the minimum number of employees needed per day. In reality these quantities are uncertain. The actual number of calls will fluctuate each day. For simplicity's sake will we use a [lognormal distribution](https://en.wikipedia.org/wiki/Log-normal_distribution#Occurrence_and_applications) for the amount of calls (using their initial value as mean and a standard deviation of two). Working this way, we avoid having negative calls.
"""

# ╔═╡ 6e48e306-04b4-11eb-2561-0151a5e0a908
B

# ╔═╡ 7a54f9b4-04b4-11eb-3a7c-8d90eb026392
begin
	# generating the distributions
	B_u = Distributions.LogNormal.(B,2) # array with distributions

	# quick sample to illustrate amount of calls being randomized
	log.(rand.(B_u))
end

# ╔═╡ 9d3ceafe-0880-11eb-36f0-0f8530d6b285
begin
	cost = Float64[]
	for _ in 1:10000
		let cout=cost
			model = Model(GLPK.Optimizer)
			@variable(model, Y[1:7] >= 0, Int)
			@constraint(model, A' * Y .>= log.(rand.(B_u)))
			@objective(model, Min, C' * A' * Y)
			optimize!(model)
			push!(cout, objective_value(model))
		end
	end
	cost
end

# ╔═╡ 14a32a20-0881-11eb-1a20-715b99417266
StatsPlots.histogram(cost, normalize=:pdf,xlabel="objective value", ylabel="PDF", label="")

# ╔═╡ 259bbbc6-04b5-11eb-1ad4-c567e45ba4b6
md"""
### Small variant: adding a commission
Suppose each worker receives extra pay for the amount of calls that have been treated. We can easily include this in our model
"""

# ╔═╡ 83130656-0881-11eb-2c87-a3ae5f81f04b
begin
	cost_c = Float64[]
	commission = 20
	for _ in 1:1000
		let cout=cost_c
			model = Model(GLPK.Optimizer)
			appels = log.(rand.(B_u))
			@variable(model, Y[1:7] >= 0, Int)
			@constraint(model, A' * Y .>= appels)
			@objective(model, Min, C' * A' * Y + sum(appels) * commission)
			optimize!(model)
			push!(cout, objective_value(model))
		end
	end

	StatsPlots.histogram(cost_c, normalize=:pdf,xlabel="objective value", ylabel="PDF", label="")
end

# ╔═╡ e1e41ea6-04b5-11eb-174e-1d43f601a07c
md"""
#### Playing it safe
The above has given us some information on what the distributions of the payroll cost may be, however in reality, you would want to make sure that the clients calling to center are taken care off. To realise this, one might say that for any given day, you want to make sure that 90% of all calls can be treated by the specific capacity.
"""

# ╔═╡ 62b516be-0882-11eb-094b-d183f8d00ab8
log.(quantile.(B_u, 0.90))

# ╔═╡ 6274be66-0882-11eb-11be-05163cda6633
 let
	model = Model(GLPK.Optimizer)
	@variable(model, Y[1:7] >= 0, Int)
	@constraint(model, A' * Y .>= log.(quantile.(B_u, 0.99)))
	@objective(model, Min, C' * A' * Y)
	optimize!(model)
	termination_status(model)
	objective_value(model)
end

# ╔═╡ 1f177098-04b6-11eb-2508-6bd8d7e1e996
md"""
### Additional questions
* The example we have treated so far has very traditional working patterns for the employees. How woud you deal with modern working patterns (e.g. 4/5 or parttime working)?
* We took a look at the stochastic nature of the amount of calls, however, the personnel might not show up for various reasons. How would you describe the possible influence? Hint: make a discrete event model of this setting, using the optimal design and controlling for employees showing up or not.
"""

# ╔═╡ ab9a13a8-7cc2-4057-8b16-f6a378fca668


# ╔═╡ b849b11a-05e8-4b3b-b1ca-a766df13f0e0
md"""
## Application - Maximize flow in a network

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

# ╔═╡ 672dcd20-e610-4723-97ec-11a16f69742b
# given set-up
begin
	# Topology and maximum flow matrix
	W = [0 13 6 10 0 0 0;
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

# ╔═╡ 2974d8f5-1355-4ba6-b942-292680311f77
let
	model = Model(Ipopt.Optimizer)
	@variable(model, F[1:7,1:7])
	@constraint(model, F .<= W) # limite capacité
	for i = 2:6
		@constraint(model, sum(F[i,:]) == sum(F[:,i]))
	end
	@constraint(model, F .>= 0)
	@objective(model, Max, sum(F[1,:]))
	# to limit the number of messages printed
	set_optimizer_attribute(model, "print_level", 0)
	optimize!(model)
	abs.(round.(value.(F),digits=6))
end

# ╔═╡ 8023562d-9863-414d-961e-a6d2174d84fa
let
	model = Model(GLPK.Optimizer)
	@variable(model, F[1:7,1:7])
	@constraint(model, F .<= W) # limite capacité
	for i = 2:6
		@constraint(model, sum(F[i,:]) == sum(F[:,i]))
	end
	@constraint(model, F .>= 0)
	@objective(model, Max, sum(F[1,:]))
	# to limit the number of messages printed
	#set_optimizer_attribute(model, "print_level", 0)
	optimize!(model)
	abs.(round.(value.(F),digits=6))
end

# ╔═╡ d0dd636e-4a14-4501-aef6-c6cd909c8cfb
let
	# same results, using extra problem info 
	model = Model(Ipopt.Optimizer)
	@variable(model,F[1:size(W,1), 1:size(W,2)])
	@objective(model, Max, sum(F[1,:])) 
	# simplify by fixing variable that cannot be different from zero
	for ind in findall(iszero, W)
		JuMP.fix(F[ind], 0., force=true)
	end
	# impose constraints
	for i = 2:6
		@constraint(model, sum(F[i,:]) == sum(F[:,i]))
	end
	@constraint(model, F .<= W)
	@constraint(model, F .>= 0)
	# to limit the number of messages printed
	set_optimizer_attribute(model, "print_level", 0)
	optimize!(model)

	# show result (if found)
	if has_values(model)
		println("Current network flow: $(sum(value.(F)[1,:]))")
	else
		println("No solution found ($(termination_status(model))")
	end
end

# ╔═╡ 4b56a433-1742-46a5-a2c7-db76d07c8062
let	
	model = Model(Ipopt.Optimizer)
	@variable(model,F[1:size(W,1), 1:size(W,2)]) # existing capacity
	@variable(model,G[1:size(W,1), 1:size(W,2)]) # additional capacity
	@objective(model, Min, sum(G .* xcost)) 	 # minimise the cost of extra Cap
	# simplify by fixing variable that cannot be different from zero
	for ind in findall(iszero,W)
		JuMP.fix(F[ind], 0., force=true)
		JuMP.fix(G[ind], 0., force=true)
	end
	# constraints
	for i = 2:6
		@constraint(model, sum(F[i,:] + G[i,:]) == sum(F[:,i] + G[:,i]))
	end
	@constraint(model, F .<= W)
	@constraint(model, F .>= 0)
	@constraint(model, G .<= xcap)
	@constraint(model, G .>= 0)
	@constraint(model, sum(F[1,:] + G[1,:]) == 35.)

	# to limit the number of messages printed
	set_optimizer_attribute(model, "print_level", 0)
	optimize!(model)

	# show result (if found)
	if has_values(model)
		println("Expanded network flow:  $(sum(value.(F)[1,:] + value.(G)[1,:]))")
		println("Network expansion cost: $(sum(value.(G) .* xcost))")
	else
		println("No solution found ($(termination_status(model))")
	end
end

# ╔═╡ 242139f3-4213-45d4-805e-89caff6493d7
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

# ╔═╡ ff4eed1a-2711-4ef2-8624-72f7a8643f81
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

# ╔═╡ df68b242-cf29-4412-8b55-80db38e6b566
# solution part 1
let
	# generate model
	model = Model(Ipopt.Optimizer)
	set_optimizer_attribute(model, "print_level", 0)
	# add variables
	@variable(model, S[1:6] >= 0)
	# add constraint
	@constraint(model, lowerbounds, S .>= 0)
	@constraint(model, upperbounds, S .<= 1)
	@constraint(model, portfolio, sum(S) == 1)
	# add objective
	@objective(model, Max, sum(μ .* S))
	# solve model
	optimize!(model)
	# show result
	println("Portfolio management - part 1")
	println(" optimal portfolio composition without risk:")
	for i in 1:6
		println("  S$(i) : $(value(S[i]))")
	end
	println(" portfolio gains: $(sum(value.(S) .* μ))")
end

# ╔═╡ 1a0115fb-1871-4072-a7a7-ae86a9eb00c1
# solution part 2
let
	# generate model
	model = Model(Ipopt.Optimizer)
	set_optimizer_attribute(model, "print_level", 0)
	# add variables
	@variable(model, S[1:6] >= 0)
	# add constraint
	@constraint(model, lowerbounds, S .>= 0)
	@constraint(model, upperbounds, S .<= 0.4)
	@constraint(model, portfolio, sum(S) == 1)
	# add objective
	@objective(model, Max, sum(μ .* S))
	# solve model
	optimize!(model)
	# show result
	println("Portfolio management - part 2")
	println(" optimal portfolio composition without risk:")
	for i in 1:6
		println("  S$(i) : $(value(S[i]))")
	end
	println(" portfolio gains: $(sum(value.(S) .* μ))")
end

# ╔═╡ 21fad125-0c82-4f5e-a259-617c46b612cd
let minreturn = 0.35
	# generate model
	model = Model(Ipopt.Optimizer)
	set_optimizer_attribute(model, "print_level", 0)
	# add variables
	@variable(model, S[1:6] >= 0)
	# add constraints
	@constraint(model, lowerbounds, S .>= 0)
	@constraint(model, upperbounds, S .<= 1)
	@constraint(model, portfolio, sum(S) == 1)
	@constraint(model, minimalreturn, sum(S .* μ) >= minreturn)
	# add objective
	@objective(model, Min, S'*Σ*S)
	# solve model
	optimize!(model)
	# show result
	println("Portfolio management - part 3")
	println(" optimal portfolio composition with minimal risk:")
	for i in 1:6
		println("  S$(i) : $(value(S[i]))")
	end
	println(" portfolio gains: $(sum(value.(S) .* μ))")
end

# ╔═╡ d5259cf5-d07a-4463-978a-a87ccc26ff9f
# Solution part 4
begin
	"""
		portfolio(minreturn, Σ=Σ, μ=μ)
	
	Given an expected return, determine the minimal risk for a given covariance 
	matrix and expected returns.
	"""
	function portfolio(minreturn, Σ=Σ, μ=μ)
		# dims check
		@assert isequal(size(Σ)...)
		@assert isequal(size(Σ, 1), length(μ))
		# generate model
		model = Model(Ipopt.Optimizer)
		set_optimizer_attribute(model, "print_level", 0)
		# add variables
		@variable(model, S[1:6] >= 0)
		# add constraints
		@constraint(model, lowerbounds, S .>= 0)
		@constraint(model, upperbounds, S .<= 1)
		@constraint(model, portfolio, sum(S) == 1)
		@constraint(model, minimalreturn, sum(S .* μ) >= minreturn)
		# add objective
		@objective(model, Min, S'*Σ*S)
		# solve model
		optimize!(model)
		return objective_value(model), value.(S)
	end
	
	# return range
	x = range(minimum(μ), maximum(μ), length=20)
	r = map(v -> portfolio(v,Σ, μ), x)
	
	# minimal risk
	risk = map(v -> v[1], r)
	# portfolio composition (cumulative for graphics)
	comp = map(v -> cumsum(v[2]), r)
	# final portfolio value
	port_val = map(v -> sum(v[2] .* μ), r)

end

# ╔═╡ f51a17d0-baae-462f-aa95-bd754d4aa133
begin
	plot(x,risk, marker=:circle, xlabel="minimal required return", ylabel="minimum risk",label="", yscale=:log10)
end

# ╔═╡ 729985d6-7df5-46fc-b609-c6302a9d3078
plot(x, permutedims(hcat(comp...)), 
	 label = permutedims(["S_$(i)" for i in 1:6]),
	 xlabel="minimal required return",
	 ylabel="portfolio composition (cumulative)",
	 legend=:bottomright)

# ╔═╡ 696f869a-5cf6-4430-b1d0-66ffca89e0e9
plot(x, port_val, 
	 label = "",
	 xlabel="minimal required return",
	 ylabel="portfolio value",
	 xlims=(0,1),ylims=(0,1))

# ╔═╡ 5364cd1d-599b-40da-b296-823a89d33fca
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

# ╔═╡ dd4844b6-64fe-41da-a510-9fbacd76828a
begin
	# Part 1 & 2 - optimal split + illustration
	
	# constants
	a = 2; b = 3; N = 20
	θ = 0.05; α = -0.1; β = 1.4;
	
	let
		# Setup the model
		model = Model(Tulip.Optimizer)

		# Add variables #
		# ------------- #
		# basics
		@variable(model,T[1:N] >= 0)
		@variable(model,A[1:N] >= 0)

		# Add constraints #
		# --------------- #
		# physical constraints
		@constraint(model, T .<= 1)
		@constraint(model, A .<= 1)
		@constraint(model,sum(A[b+1:N]) <= a*sum(T[b+1:N]) )
		for i in 1:N
			if i <= b
				JuMP.fix(T[i], 1.,force=true)
				JuMP.fix(A[i], 0.,force=true)
			else
				@constraint(model, T[i] + A[i] == 1) 
			end
		end

		# Find emotional states:
		s₀ = 0
		S = Any[(1-θ)*s₀ + θ*(α*T[1] + β*A[1] )]
		for i in 2:N
			push!(S,(1-θ)*S[i-1] + θ*(α*T[i] + β*A[i] ))
		end

		# Set objective
		@objective(model,Max,S[end])

		# solve the model
		optimize!(model)
		termination_status(model)
		
		# illustrate the optimal repartition
		settings = Dict(:marker=>:circle)# :xlabel="Lecture", :ylabel="Time usage")
		plot(value.(T), label="theory"; settings...)
		plot!(value.(A), label="applications"; settings...)
		xlabel!("lecture")
		ylabel!("Time allocation")
		title!("teaching strategy")

		#S[end]
	end
end

# ╔═╡ 714b2ac5-b01b-4873-9488-abcd01584515
begin
	# Part 3 - optimal values α & β for a neutral outcome
	#  principle: maximize the outcome and minimize the associated result
	
	"""
		myplanner(x)
	
	Solve the planning problem and return the emotional state in the end.
	
	x should be a vector of length two.
	
	"""
	function myplanner(x)
		# Load constants
		α, β = x
		θ = 0.05
		# Setup the model
		model = Model(Tulip.Optimizer)

		# Add variables #
		# ------------- #
		# basics
		@variable(model,T[1:N] >= 0)
		@variable(model,A[1:N] >= 0)

		# Add constraints #
		# --------------- #
		# physical constraints
		@constraint(model, T .<= 1)
		@constraint(model, A .<= 1)
		@constraint(model,sum(A[b+1:N]) <= a*sum(T[b+1:N]) )
		for i in 1:N
			if i <= b
				JuMP.fix(T[i], 1.,force=true)
				JuMP.fix(A[i], 0.,force=true)
			else
				@constraint(model, T[i] + A[i] == 1) 
			end
		end

		# Find emotional states:
		s₀ = 0
		S = Any[(1-θ)*s₀ + θ*(α*T[1] + β*A[1] )]
		for i in 2:N
			push!(S,(1-θ)*S[i-1] + θ*(α*T[i] + β*A[i] ))
		end

		# Set objective
		@objective(model,Max,S[end])

		# solve the model
		optimize!(model)
		
		# get return value (use absolute value to be able to minimize afterwards)
		return abs(value(S[end]))
	end
	
	# optimize the parameter to obtain a neutral outcome
	optcfg = optimize(myplanner, [α; β])
	println("Optimal values [α, β]: $(optcfg.minimizer) with satisfaction S_final of $(myplanner(optcfg.minimizer))")
	
end

# ╔═╡ Cell order:
# ╟─10850c10-3b60-406a-8741-5ed5618af8e9
# ╟─f7f3a256-03c6-11eb-2c1e-83cc62bf55e6
# ╠═10349518-03ca-11eb-09b2-69c80c4662ac
# ╟─7910d53e-03ca-11eb-1536-7fc4c236e10a
# ╠═572d14c4-03cb-11eb-2b68-234b3d7e9e8e
# ╠═4ba4687e-087f-11eb-1cb0-2581818cbd93
# ╠═79351ee4-087f-11eb-147d-d389de200857
# ╠═3bafd152-6724-4847-a79d-f2340e2ab5e4
# ╟─4bc4c2aa-04b4-11eb-2b6e-452d4ecc258a
# ╠═6e48e306-04b4-11eb-2561-0151a5e0a908
# ╠═7a54f9b4-04b4-11eb-3a7c-8d90eb026392
# ╠═9d3ceafe-0880-11eb-36f0-0f8530d6b285
# ╠═14a32a20-0881-11eb-1a20-715b99417266
# ╟─259bbbc6-04b5-11eb-1ad4-c567e45ba4b6
# ╠═83130656-0881-11eb-2c87-a3ae5f81f04b
# ╟─e1e41ea6-04b5-11eb-174e-1d43f601a07c
# ╠═62b516be-0882-11eb-094b-d183f8d00ab8
# ╠═6274be66-0882-11eb-11be-05163cda6633
# ╟─1f177098-04b6-11eb-2508-6bd8d7e1e996
# ╠═ab9a13a8-7cc2-4057-8b16-f6a378fca668
# ╟─b849b11a-05e8-4b3b-b1ca-a766df13f0e0
# ╠═672dcd20-e610-4723-97ec-11a16f69742b
# ╠═2974d8f5-1355-4ba6-b942-292680311f77
# ╠═8023562d-9863-414d-961e-a6d2174d84fa
# ╠═d0dd636e-4a14-4501-aef6-c6cd909c8cfb
# ╠═4b56a433-1742-46a5-a2c7-db76d07c8062
# ╟─242139f3-4213-45d4-805e-89caff6493d7
# ╠═ff4eed1a-2711-4ef2-8624-72f7a8643f81
# ╠═df68b242-cf29-4412-8b55-80db38e6b566
# ╠═1a0115fb-1871-4072-a7a7-ae86a9eb00c1
# ╠═21fad125-0c82-4f5e-a259-617c46b612cd
# ╠═d5259cf5-d07a-4463-978a-a87ccc26ff9f
# ╟─f51a17d0-baae-462f-aa95-bd754d4aa133
# ╟─729985d6-7df5-46fc-b609-c6302a9d3078
# ╟─696f869a-5cf6-4430-b1d0-66ffca89e0e9
# ╟─5364cd1d-599b-40da-b296-823a89d33fca
# ╠═dd4844b6-64fe-41da-a510-9fbacd76828a
# ╠═714b2ac5-b01b-4873-9488-abcd01584515
