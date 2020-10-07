### A Pluto.jl notebook ###
# v0.11.14

using Markdown
using InteractiveUtils

# ╔═╡ 10349518-03ca-11eb-09b2-69c80c4662ac
using JuMP, Tulip, GLPK, LinearAlgebra

# ╔═╡ 6e48e306-04b4-11eb-2561-0151a5e0a908
using Distributions, Plots, StatsPlots, LaTeXStrings, Measures

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
	termination_status(model)
	objective_value(model)
	A' * value.(Y) .> B
end

# ╔═╡ 4bc4c2aa-04b4-11eb-2b6e-452d4ecc258a
md"""
### Adding uncertainty
Up to now, we have had constant numbers the minimum number of employees needed per day. In reality these quantities are uncertain. The actual number of calls will fluctuate each day. For simplicity's sake will we use a [lognormal distribution](https://en.wikipedia.org/wiki/Log-normal_distribution#Occurrence_and_applications) for the amount of calls (using their initial value as mean and a standard deviation of two). Working this way, we avoid having negative calls.
"""

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
StatsPlots.histogram(cost, yscale=:log10)

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
	StatsPlots.histogram(cost_c)
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

# ╔═╡ Cell order:
# ╟─f7f3a256-03c6-11eb-2c1e-83cc62bf55e6
# ╠═10349518-03ca-11eb-09b2-69c80c4662ac
# ╟─7910d53e-03ca-11eb-1536-7fc4c236e10a
# ╠═572d14c4-03cb-11eb-2b68-234b3d7e9e8e
# ╠═4ba4687e-087f-11eb-1cb0-2581818cbd93
# ╠═79351ee4-087f-11eb-147d-d389de200857
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
