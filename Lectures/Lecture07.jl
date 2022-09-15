### A Pluto.jl notebook ###
# v0.19.11

using Markdown
using InteractiveUtils

# ╔═╡ 1d0b540f-45b0-4c2c-945a-cb098db32b67
# Explicit use of own environment instead of a local one for each notebook
begin
	using Pkg
	cd(joinpath(dirname(@__FILE__),".."))
    Pkg.activate(pwd())
	using JuMP
	using GLPK
end

# ╔═╡ 6f96aa50-fc11-11ea-22c9-01e5e73d8ab0
md"# Applications of Linear Programming"

# ╔═╡ 8c3d90b0-fc11-11ea-2873-934ec496d1ee
md"""## Economy

A manufacturer produces  four different  products  $X_1$, $X_2$, $X_3$ and $X_4$. There are three inputs to this production process:

- labor in man weeks,  
- kilograms of raw material A, and 
- boxes  of raw  material  B.

Each product has different input requirements. In determining each  week's production schedule, the manufacturer cannot use more than the available amounts of  manpower and the two raw  materials:

|Inputs|$X_1$|$X_2$|$X_3$|$X_4$|Availabilities|
|------|-----|-----|-----|-----|--------------|
|Person-weeks|1|2|1|2|20|
|Kilograms of material A|6|5|3|2|100|
|Boxes of material B|3|4|9|12|75|
|Production level|$x_1$|$x_2$|$x_3$|$x_4$| |

These constraints can be written in mathematical form

```math
\begin{aligned}
x_1+2x_2+x_3+2x_4\le&20\\
6x_1+5x_2+3x_3+2x_4\le&100\\
3x_1+4x_2+9x_3+12x_4\le&75
\end{aligned}
```

Because negative production levels are not meaningful, we must impose the following nonnegativity constraints on the production levels:

```math
x_i\ge0,\qquad i=1,2,3,4
```

Now suppose that one unit of product $X_1$ sells for €6 and $X_2$, $X_3$ and $X_4$ sell for €4, €7 and €5, respectively. Then, the total revenue for any production decision $\left(x_1,x_2,x_3,x_4\right)$ is

```math
f\left(x_1,x_2,x_3,x_4\right)=6x_1+4x_2+7x_3+5x_4
```

The problem is then to maximize $f$ subject to the given constraints."""

# ╔═╡ acba3730-fc11-11ea-2d31-27432ab5e777
let
	model = Model(GLPK.Optimizer)
	@variable(model, 0 <= x1)
	@variable(model, 0 <= x2)
	@variable(model, 0 <= x3)
	@variable(model, 0 <= x4)
	@objective(model, Max, 6*x1 + 4*x2 + 7*x3 + 5*x4)
	@constraint(model, con1,   x1 + 2*x2 +   x3 +  2*x4 <= 20)
	@constraint(model, con2, 6*x1 + 5*x2 + 3*x3 +  2*x4 <= 100)
	@constraint(model, con3, 3*x1 + 4*x2 + 9*x3 + 12*x4 <= 75)
	optimize!(model)
	termination_status(model), primal_status(model), value(x1), value(x2), value(x3), value(x4), objective_value(model)
end

# ╔═╡ 06330800-fc12-11ea-011c-e762078d0d88
md"""## Manufacturing

A manufacturer produces two different products $X_1$ and $X_2$ using three machines $M_1$, $M_2$, and $M_3$. Each machine can be used only for a limited amount of time. Production times of each product on each machine are given by 

|Machine|Production time $X_1$|Production time $X_2$|Available time|
|-------|---------------------|---------------------|--------------|
|$M_1$  |1                    |1                    |8             |
|$M_2$  |1                    |3                    |18            |
|$M_3$  |2                    |1                    |14            |
|Total  |4                    |5                    |              |

The objective is to maximize the combined time of utilization of all three machines.

Every production decision must satisfy the constraints on the available time. These restrictions can be written down using data from the table.

```math
\begin{aligned}
x_1+x_2&\le8\,,\\
x_1+3x_2&\le18\,,\\
2x_1+x_2&\le14\,,
\end{aligned}
```

where $x_1$ and $x_2$ denote the production levels. The combined production time of all three machines is

```math
f\left(x_1,x_2\right)=4x_1+5x_2\,.
```"""

# ╔═╡ 51553150-fc12-11ea-2020-7b418f5eb559
let
	model = Model(GLPK.Optimizer)
	@variable(model, 0 <= x1)
	@variable(model, 0 <= x2)
	@objective(model, Max, 4*x1 + 5*x2)
	@constraint(model, con1,   x1 +   x2 <= 8)
	@constraint(model, con2,   x1 + 3*x2 <= 18)
	@constraint(model, con3, 2*x1 +   x2 <= 14)
	optimize!(model)
	termination_status(model), primal_status(model), value(x1), value(x2), objective_value(model)
end

# ╔═╡ 7616fb90-fc12-11ea-1b4b-f7ad83c91fe9
md"""## Transportation

A manufacturing company has plants in cities A, B, and C. The company produces and distributes its product to dealers in various cities. On a particular day, the company has 30 units of its product in A, 40 in B, and 30 in C. The company plans to ship 20 units to D, 20 to E, 25 to F, and 35 to G, following orders received from dealers. The transportation costs per unit of each product between the cities are given by

|From|To D|To E|To F|To G|Supply|
|----|----|----|----|----|------|
|A   |7   |10  |14  |8   |30    |
|B   |7   |11  |12  |6   |40    |
|C   |5   |8   |15  |9   |30    |
|Demand|20|20  |25  |35  |100   |

In the table, the quantities supplied and demanded appear at the right and along the bottom of the table. The quantities to be transported from the plants to different destinations are represented by the decision variables.

This problem can be stated in the form:

```math
\min 7x_{AD}+10x_{AE}+14x_{AF}+8x_{AG}+7x_{BD}+11x_{BE}+12x_{BF}+6x_{BG}+5x_{CD}+8x_{CE}+15x_{CF}+9x_{CG}
```

subject to

```math
\begin{aligned}
x_{AD}+x_{AE}+x_{AF}+x_{AG}&=30\\
x_{BD}+x_{BE}+x_{BF}+x_{BG}&=40\\
x_{CD}+x_{CE}+x_{CF}+x_{CG}&=30\\
x_{AD}+x_{BD}+x_{CD}&=20\\
x_{AE}+x_{BE}+x_{CE}&=20\\
x_{AF}+x_{BF}+x_{CF}&=25\\
x_{AG}+x_{BG}+x_{CG}&=35
\end{aligned}
```

In this problem, one of the constraint equations is redundant because it can be derived from the rest of the constraint equations. The mathematical formulation of the transportation problem is then in a linear programming form with twelve (3x4) decision variables and six (3 + 4 - 1) linearly independent constraint equations. Obviously, we also require nonnegativity of the decision variables, since a negative shipment is impossible and does not have any valid interpretation."""

# ╔═╡ d6798340-fc12-11ea-0b8d-71931d797511
let
	model = Model(GLPK.Optimizer)
	@variable(model, 0 <= x[1:3,1:4])
	@objective(model, Min, 7x[1,1]+10x[1,2]+14x[1,3]+8x[1,4]+7x[2,1]+11x[2,2]+12x[2,3]+6x[2,4]+5x[3,1]+8x[3,2]+15x[3,3]+9x[3,4])
	@constraint(model, con1, sum(x[1,j] for j in 1:4) == 30)
	@constraint(model, con2, sum(x[2,j] for j in 1:4) == 40)
	@constraint(model, con3, sum(x[3,j] for j in 1:4) == 30)
	@constraint(model, con4, sum(x[i,1] for i in 1:3) == 20)
	@constraint(model, con5, sum(x[i,2] for i in 1:3) == 20)
	@constraint(model, con6, sum(x[i,3] for i in 1:3) == 25)
	@constraint(model, con7, sum(x[i,4] for i in 1:3) == 35)
	optimize!(model)
	termination_status(model), primal_status(model), value.(x), objective_value(model)
end

# ╔═╡ 6d012070-fc13-11ea-1f08-b3754cf9c6bd
md"""This problem is an _integer linear programming_ problem, i.e. the solution components must be integers.

We can use the simplex method to find a solution to an ILP problem if the $m\times n$ matrix $A$ is unimodular, i.e. if all its nonzero $m$th order minors are $\pm 1$."""

# ╔═╡ 7a077a30-fc13-11ea-193e-6b30f852c9e7
md"""## Electricity

An electric circuit is designed to use a 30 V source to charge 10 V, 6 V, and 20 V batteries connected in parallel. Physical constraints limit the currents $I_1$, $I_2$, $I_3$, $I_4$, and $I_5$ to a maximum of 4 A, 3 A, 3 A, 2 A, and 2 A, respectively. In addition, the batteries must not be discharged, that is, the currents $I_1$, $I_2$, $I_3$, $I_4$, and $I_5$ must not be negative. We wish to find the values of the currents $I_1$, $I_2$, $I_3$, $I_4$, and $I_5$ such that the total power transferred to the batteries is maximized.

The total power transferred to the batteries is the sum of the powers transferred to each battery, and is given by $10I_2 + 6I_4 + 20I_5$ W. From the circuit, we observe that the currents satisfy the constraints $I_1 = I_2 + I_3$, and $I_3 = I_4 + I_5$. Therefore, the problem can be posed as the following linear program:

```math
\max 10I_2+6I_4+20I_5
```

subject to

```math
\begin{aligned}
I_1 &= I_2 + I_3\\
I_3 &= I_4 + I_5\\
I_1 &\le 4\\
I_2 &\le 3\\
I_3 &\le 3\\
I_4 &\le 2\\
I_5 &\le 2
\end{aligned}
```

"""

# ╔═╡ 98561d20-fc13-11ea-0278-cf26118a2c51
let
	model = Model(GLPK.Optimizer)
	@variable(model, 0 <= I[1:5])
	@objective(model, Max, 10*I[2]+6*I[4]+20I[5])
	@constraint(model, con1, I[1] == I[2] + I[3])
	@constraint(model, con2, I[3] == I[4] + I[5])
	@constraint(model, con3, I[1] <= 4)
	@constraint(model, con4, I[2] <= 3)
	@constraint(model, con5, I[3] <= 3)
	@constraint(model, con6, I[4] <= 2)
	@constraint(model, con7, I[5] <= 2)
	optimize!(model)
	termination_status(model), primal_status(model), value.(I), objective_value(model)
end

# ╔═╡ 478fe6e0-fc14-11ea-10d4-4d9e0de6ea00
md"""## Telecom

Consider a wireless communication system. There are $n$ "mobile" users. For each $i$ in $1,\dots, n$; user $i$ transmits a signal to the base station with power $P_i$ and an attenuation factor of $h_i$ (i.e., the actual received signal power at the basestation from user $i$ is $h_iP_i$). When the basestation is receiving from user $i$, the total received power from all other users is considered "interference" (i.e., the interference for user $i$ is $\sum_{i\ne j}h_jP_j$). For the communication with user $i$ to be reliable, the signal-to-interference ratio must exceed a threshold $\gamma_i$, where the "signal" is the received power for user $i$.

We are interested in minimizing the total power transmitted by all the users subject to having reliable communications for all users. We can formulate the problem as a linear programming problem of the form

```math
\min \sum_iP_i
```

subject to

```math
\forall i \in 1,\dots,n\,:\,\begin{cases}
\frac{h_iP_i}{\sum_{i\ne j}h_jP_j}\ge\gamma_i\\
P_i\ge0
\end{cases}
```"""

# ╔═╡ Cell order:
# ╠═1d0b540f-45b0-4c2c-945a-cb098db32b67
# ╟─6f96aa50-fc11-11ea-22c9-01e5e73d8ab0
# ╟─8c3d90b0-fc11-11ea-2873-934ec496d1ee
# ╠═acba3730-fc11-11ea-2d31-27432ab5e777
# ╟─06330800-fc12-11ea-011c-e762078d0d88
# ╠═51553150-fc12-11ea-2020-7b418f5eb559
# ╟─7616fb90-fc12-11ea-1b4b-f7ad83c91fe9
# ╠═d6798340-fc12-11ea-0b8d-71931d797511
# ╟─6d012070-fc13-11ea-1f08-b3754cf9c6bd
# ╟─7a077a30-fc13-11ea-193e-6b30f852c9e7
# ╠═98561d20-fc13-11ea-0278-cf26118a2c51
# ╟─478fe6e0-fc14-11ea-10d4-4d9e0de6ea00
