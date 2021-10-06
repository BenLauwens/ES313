### A Pluto.jl notebook ###
# v0.16.0

using Markdown
using InteractiveUtils

# ╔═╡ 863debb0-fc11-11ea-09e6-dfb25ad73b07
using JuMP

# ╔═╡ 894add90-fc11-11ea-16ed-0120c97d8aec
using GLPK

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

# ╔═╡ 00000000-0000-0000-0000-000000000001
PLUTO_PROJECT_TOML_CONTENTS = """
[deps]
GLPK = "60bf3e95-4087-53dc-ae20-288a0d20c6a6"
JuMP = "4076af6c-e467-56ae-b986-b466b2749572"

[compat]
GLPK = "~0.14.14"
JuMP = "~0.21.10"
"""

# ╔═╡ 00000000-0000-0000-0000-000000000002
PLUTO_MANIFEST_TOML_CONTENTS = """
# This file is machine-generated - editing it directly is not advised

[[ArgTools]]
uuid = "0dad84c5-d112-42e6-8d28-ef12dabb789f"

[[Artifacts]]
uuid = "56f22d72-fd6d-98f1-02f0-08ddc0907c33"

[[Base64]]
uuid = "2a0f44e3-6c83-55bd-87e4-b1978d98bd5f"

[[BenchmarkTools]]
deps = ["JSON", "Logging", "Printf", "Profile", "Statistics", "UUIDs"]
git-tree-sha1 = "61adeb0823084487000600ef8b1c00cc2474cd47"
uuid = "6e4b80f9-dd63-53aa-95a3-0cdb28fa8baf"
version = "1.2.0"

[[BinaryProvider]]
deps = ["Libdl", "Logging", "SHA"]
git-tree-sha1 = "ecdec412a9abc8db54c0efc5548c64dfce072058"
uuid = "b99e7846-7c00-51b0-8f62-c81ae34c0232"
version = "0.5.10"

[[Bzip2_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "19a35467a82e236ff51bc17a3a44b69ef35185a2"
uuid = "6e34b625-4abd-537c-b88f-471c36dfa7a0"
version = "1.0.8+0"

[[CEnum]]
git-tree-sha1 = "215a9aa4a1f23fbd05b92769fdd62559488d70e9"
uuid = "fa961155-64e5-5f13-b03f-caf6b980ea82"
version = "0.4.1"

[[Calculus]]
deps = ["LinearAlgebra"]
git-tree-sha1 = "f641eb0a4f00c343bbc32346e1217b86f3ce9dad"
uuid = "49dc2e85-a5d0-5ad3-a950-438e2897f1b9"
version = "0.5.1"

[[ChainRulesCore]]
deps = ["Compat", "LinearAlgebra", "SparseArrays"]
git-tree-sha1 = "4ce9393e871aca86cc457d9f66976c3da6902ea7"
uuid = "d360d2e6-b24c-11e9-a2a3-2a2ae2dbcce4"
version = "1.4.0"

[[CodecBzip2]]
deps = ["Bzip2_jll", "Libdl", "TranscodingStreams"]
git-tree-sha1 = "2e62a725210ce3c3c2e1a3080190e7ca491f18d7"
uuid = "523fee87-0ab8-5b00-afb7-3ecf72e48cfd"
version = "0.7.2"

[[CodecZlib]]
deps = ["TranscodingStreams", "Zlib_jll"]
git-tree-sha1 = "ded953804d019afa9a3f98981d99b33e3db7b6da"
uuid = "944b1d66-785c-5afd-91f1-9de20f533193"
version = "0.7.0"

[[CommonSubexpressions]]
deps = ["MacroTools", "Test"]
git-tree-sha1 = "7b8a93dba8af7e3b42fecabf646260105ac373f7"
uuid = "bbf7d656-a473-5ed7-a52c-81e309532950"
version = "0.3.0"

[[Compat]]
deps = ["Base64", "Dates", "DelimitedFiles", "Distributed", "InteractiveUtils", "LibGit2", "Libdl", "LinearAlgebra", "Markdown", "Mmap", "Pkg", "Printf", "REPL", "Random", "SHA", "Serialization", "SharedArrays", "Sockets", "SparseArrays", "Statistics", "Test", "UUIDs", "Unicode"]
git-tree-sha1 = "4866e381721b30fac8dda4c8cb1d9db45c8d2994"
uuid = "34da2185-b29b-5c13-b0c7-acf172513d20"
version = "3.37.0"

[[CompilerSupportLibraries_jll]]
deps = ["Artifacts", "Libdl"]
uuid = "e66e0078-7015-5450-92f7-15fbd957f2ae"

[[DataStructures]]
deps = ["Compat", "InteractiveUtils", "OrderedCollections"]
git-tree-sha1 = "7d9d316f04214f7efdbb6398d545446e246eff02"
uuid = "864edb3b-99cc-5e75-8d2d-829cb0a9cfe8"
version = "0.18.10"

[[Dates]]
deps = ["Printf"]
uuid = "ade2ca70-3891-5945-98fb-dc099432e06a"

[[DelimitedFiles]]
deps = ["Mmap"]
uuid = "8bb1440f-4735-579b-a4ab-409b98df4dab"

[[DiffResults]]
deps = ["StaticArrays"]
git-tree-sha1 = "c18e98cba888c6c25d1c3b048e4b3380ca956805"
uuid = "163ba53b-c6d8-5494-b064-1a9d43ac40c5"
version = "1.0.3"

[[DiffRules]]
deps = ["NaNMath", "Random", "SpecialFunctions"]
git-tree-sha1 = "7220bc21c33e990c14f4a9a319b1d242ebc5b269"
uuid = "b552c78f-8df3-52c6-915a-8e097449b14b"
version = "1.3.1"

[[Distributed]]
deps = ["Random", "Serialization", "Sockets"]
uuid = "8ba89e20-285c-5b6f-9357-94700520ee1b"

[[DocStringExtensions]]
deps = ["LibGit2"]
git-tree-sha1 = "a32185f5428d3986f47c2ab78b1f216d5e6cc96f"
uuid = "ffbed154-4ef7-542d-bbb7-c09d3a79fcae"
version = "0.8.5"

[[Downloads]]
deps = ["ArgTools", "LibCURL", "NetworkOptions"]
uuid = "f43a241f-c20a-4ad4-852c-f6b1247861c6"

[[ForwardDiff]]
deps = ["CommonSubexpressions", "DiffResults", "DiffRules", "LinearAlgebra", "NaNMath", "Printf", "Random", "SpecialFunctions", "StaticArrays"]
git-tree-sha1 = "b5e930ac60b613ef3406da6d4f42c35d8dc51419"
uuid = "f6369f11-7733-5829-9624-2563aa707210"
version = "0.10.19"

[[GLPK]]
deps = ["BinaryProvider", "CEnum", "GLPK_jll", "Libdl", "MathOptInterface"]
git-tree-sha1 = "833dbc8fbb0554e31186df509d67fc2f78f1bb09"
uuid = "60bf3e95-4087-53dc-ae20-288a0d20c6a6"
version = "0.14.14"

[[GLPK_jll]]
deps = ["Artifacts", "GMP_jll", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "01de09b070d4b8e3e1250c6542e16ed5cad45321"
uuid = "e8aa6df9-e6ca-548a-97ff-1f85fc5b8b98"
version = "5.0.0+0"

[[GMP_jll]]
deps = ["Artifacts", "Libdl"]
uuid = "781609d7-10c4-51f6-84f2-b8444358ff6d"

[[HTTP]]
deps = ["Base64", "Dates", "IniFile", "MbedTLS", "Sockets"]
git-tree-sha1 = "c7ec02c4c6a039a98a15f955462cd7aea5df4508"
uuid = "cd3eb016-35fb-5094-929b-558a96fad6f3"
version = "0.8.19"

[[IniFile]]
deps = ["Test"]
git-tree-sha1 = "098e4d2c533924c921f9f9847274f2ad89e018b8"
uuid = "83e8ac13-25f8-5344-8a64-a9f2b223428f"
version = "0.5.0"

[[InteractiveUtils]]
deps = ["Markdown"]
uuid = "b77e0a4c-d291-57a0-90e8-8db25a27a240"

[[IrrationalConstants]]
git-tree-sha1 = "f76424439413893a832026ca355fe273e93bce94"
uuid = "92d709cd-6900-40b7-9082-c6be49f344b6"
version = "0.1.0"

[[JLLWrappers]]
deps = ["Preferences"]
git-tree-sha1 = "642a199af8b68253517b80bd3bfd17eb4e84df6e"
uuid = "692b3bcd-3c85-4b1f-b108-f13ce0eb3210"
version = "1.3.0"

[[JSON]]
deps = ["Dates", "Mmap", "Parsers", "Unicode"]
git-tree-sha1 = "8076680b162ada2a031f707ac7b4953e30667a37"
uuid = "682c06a0-de6a-54ab-a142-c8b1cf79cde6"
version = "0.21.2"

[[JSONSchema]]
deps = ["HTTP", "JSON", "ZipFile"]
git-tree-sha1 = "b84ab8139afde82c7c65ba2b792fe12e01dd7307"
uuid = "7d188eb4-7ad8-530c-ae41-71a32a6d4692"
version = "0.3.3"

[[JuMP]]
deps = ["Calculus", "DataStructures", "ForwardDiff", "JSON", "LinearAlgebra", "MathOptInterface", "MutableArithmetics", "NaNMath", "Printf", "Random", "SparseArrays", "SpecialFunctions", "Statistics"]
git-tree-sha1 = "4358b7cbf2db36596bdbbe3becc6b9d87e4eb8f5"
uuid = "4076af6c-e467-56ae-b986-b466b2749572"
version = "0.21.10"

[[LibCURL]]
deps = ["LibCURL_jll", "MozillaCACerts_jll"]
uuid = "b27032c2-a3e7-50c8-80cd-2d36dbcbfd21"

[[LibCURL_jll]]
deps = ["Artifacts", "LibSSH2_jll", "Libdl", "MbedTLS_jll", "Zlib_jll", "nghttp2_jll"]
uuid = "deac9b47-8bc7-5906-a0fe-35ac56dc84c0"

[[LibGit2]]
deps = ["Base64", "NetworkOptions", "Printf", "SHA"]
uuid = "76f85450-5226-5b5a-8eaa-529ad045b433"

[[LibSSH2_jll]]
deps = ["Artifacts", "Libdl", "MbedTLS_jll"]
uuid = "29816b5a-b9ab-546f-933c-edad1886dfa8"

[[Libdl]]
uuid = "8f399da3-3557-5675-b5ff-fb832c97cbdb"

[[LinearAlgebra]]
deps = ["Libdl"]
uuid = "37e2e46d-f89d-539d-b4ee-838fcccc9c8e"

[[LogExpFunctions]]
deps = ["ChainRulesCore", "DocStringExtensions", "IrrationalConstants", "LinearAlgebra"]
git-tree-sha1 = "34dc30f868e368f8a17b728a1238f3fcda43931a"
uuid = "2ab3a3ac-af41-5b50-aa03-7779005ae688"
version = "0.3.3"

[[Logging]]
uuid = "56ddb016-857b-54e1-b83d-db4d58db5568"

[[MacroTools]]
deps = ["Markdown", "Random"]
git-tree-sha1 = "5a5bc6bf062f0f95e62d0fe0a2d99699fed82dd9"
uuid = "1914dd2f-81c6-5fcd-8719-6d5c9610ff09"
version = "0.5.8"

[[Markdown]]
deps = ["Base64"]
uuid = "d6f4376e-aef5-505a-96c1-9c027394607a"

[[MathOptInterface]]
deps = ["BenchmarkTools", "CodecBzip2", "CodecZlib", "JSON", "JSONSchema", "LinearAlgebra", "MutableArithmetics", "OrderedCollections", "SparseArrays", "Test", "Unicode"]
git-tree-sha1 = "575644e3c05b258250bb599e57cf73bbf1062901"
uuid = "b8f27783-ece8-5eb3-8dc8-9495eed66fee"
version = "0.9.22"

[[MbedTLS]]
deps = ["Dates", "MbedTLS_jll", "Random", "Sockets"]
git-tree-sha1 = "1c38e51c3d08ef2278062ebceade0e46cefc96fe"
uuid = "739be429-bea8-5141-9913-cc70e7f3736d"
version = "1.0.3"

[[MbedTLS_jll]]
deps = ["Artifacts", "Libdl"]
uuid = "c8ffd9c3-330d-5841-b78e-0817d7145fa1"

[[Mmap]]
uuid = "a63ad114-7e13-5084-954f-fe012c677804"

[[MozillaCACerts_jll]]
uuid = "14a3606d-f60d-562e-9121-12d972cd8159"

[[MutableArithmetics]]
deps = ["LinearAlgebra", "SparseArrays", "Test"]
git-tree-sha1 = "3927848ccebcc165952dc0d9ac9aa274a87bfe01"
uuid = "d8a4904e-b15c-11e9-3269-09a3773c0cb0"
version = "0.2.20"

[[NaNMath]]
git-tree-sha1 = "bfe47e760d60b82b66b61d2d44128b62e3a369fb"
uuid = "77ba4419-2d1f-58cd-9bb1-8ffee604a2e3"
version = "0.3.5"

[[NetworkOptions]]
uuid = "ca575930-c2e3-43a9-ace4-1e988b2c1908"

[[OpenSpecFun_jll]]
deps = ["Artifacts", "CompilerSupportLibraries_jll", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "13652491f6856acfd2db29360e1bbcd4565d04f1"
uuid = "efe28fd5-8261-553b-a9e1-b2916fc3738e"
version = "0.5.5+0"

[[OrderedCollections]]
git-tree-sha1 = "85f8e6578bf1f9ee0d11e7bb1b1456435479d47c"
uuid = "bac558e1-5e72-5ebc-8fee-abe8a469f55d"
version = "1.4.1"

[[Parsers]]
deps = ["Dates"]
git-tree-sha1 = "438d35d2d95ae2c5e8780b330592b6de8494e779"
uuid = "69de0a69-1ddd-5017-9359-2bf0b02dc9f0"
version = "2.0.3"

[[Pkg]]
deps = ["Artifacts", "Dates", "Downloads", "LibGit2", "Libdl", "Logging", "Markdown", "Printf", "REPL", "Random", "SHA", "Serialization", "TOML", "Tar", "UUIDs", "p7zip_jll"]
uuid = "44cfe95a-1eb2-52ea-b672-e2afdf69b78f"

[[Preferences]]
deps = ["TOML"]
git-tree-sha1 = "00cfd92944ca9c760982747e9a1d0d5d86ab1e5a"
uuid = "21216c6a-2e73-6563-6e65-726566657250"
version = "1.2.2"

[[Printf]]
deps = ["Unicode"]
uuid = "de0858da-6303-5e67-8744-51eddeeeb8d7"

[[Profile]]
deps = ["Printf"]
uuid = "9abbd945-dff8-562f-b5e8-e1ebf5ef1b79"

[[REPL]]
deps = ["InteractiveUtils", "Markdown", "Sockets", "Unicode"]
uuid = "3fa0cd96-eef1-5676-8a61-b3b8758bbffb"

[[Random]]
deps = ["Serialization"]
uuid = "9a3f8284-a2c9-5f02-9a11-845980a1fd5c"

[[SHA]]
uuid = "ea8e919c-243c-51af-8825-aaa63cd721ce"

[[Serialization]]
uuid = "9e88b42a-f829-5b0c-bbe9-9e923198166b"

[[SharedArrays]]
deps = ["Distributed", "Mmap", "Random", "Serialization"]
uuid = "1a1011a3-84de-559e-8e89-a11a2f7dc383"

[[Sockets]]
uuid = "6462fe0b-24de-5631-8697-dd941f90decc"

[[SparseArrays]]
deps = ["LinearAlgebra", "Random"]
uuid = "2f01184e-e22b-5df5-ae63-d93ebab69eaf"

[[SpecialFunctions]]
deps = ["ChainRulesCore", "LogExpFunctions", "OpenSpecFun_jll"]
git-tree-sha1 = "a322a9493e49c5f3a10b50df3aedaf1cdb3244b7"
uuid = "276daf66-3868-5448-9aa4-cd146d93841b"
version = "1.6.1"

[[StaticArrays]]
deps = ["LinearAlgebra", "Random", "Statistics"]
git-tree-sha1 = "3240808c6d463ac46f1c1cd7638375cd22abbccb"
uuid = "90137ffa-7385-5640-81b9-e52037218182"
version = "1.2.12"

[[Statistics]]
deps = ["LinearAlgebra", "SparseArrays"]
uuid = "10745b16-79ce-11e8-11f9-7d13ad32a3b2"

[[TOML]]
deps = ["Dates"]
uuid = "fa267f1f-6049-4f14-aa54-33bafae1ed76"

[[Tar]]
deps = ["ArgTools", "SHA"]
uuid = "a4e569a6-e804-4fa4-b0f3-eef7a1d5b13e"

[[Test]]
deps = ["InteractiveUtils", "Logging", "Random", "Serialization"]
uuid = "8dfed614-e22c-5e08-85e1-65c5234f0b40"

[[TranscodingStreams]]
deps = ["Random", "Test"]
git-tree-sha1 = "216b95ea110b5972db65aa90f88d8d89dcb8851c"
uuid = "3bb67fe8-82b1-5028-8e26-92a6c54297fa"
version = "0.9.6"

[[UUIDs]]
deps = ["Random", "SHA"]
uuid = "cf7118a7-6976-5b1a-9a39-7adc72f591a4"

[[Unicode]]
uuid = "4ec0a83e-493e-50e2-b9ac-8f72acf5a8f5"

[[ZipFile]]
deps = ["Libdl", "Printf", "Zlib_jll"]
git-tree-sha1 = "3593e69e469d2111389a9bd06bac1f3d730ac6de"
uuid = "a5390f91-8eb1-5f08-bee0-b1d1ffed6cea"
version = "0.9.4"

[[Zlib_jll]]
deps = ["Libdl"]
uuid = "83775a58-1f1d-513f-b197-d71354ab007a"

[[nghttp2_jll]]
deps = ["Artifacts", "Libdl"]
uuid = "8e850ede-7688-5339-a07c-302acd2aaf8d"

[[p7zip_jll]]
deps = ["Artifacts", "Libdl"]
uuid = "3f19e933-33d8-53b3-aaab-bd5110c3b7a0"
"""

# ╔═╡ Cell order:
# ╟─6f96aa50-fc11-11ea-22c9-01e5e73d8ab0
# ╠═863debb0-fc11-11ea-09e6-dfb25ad73b07
# ╠═894add90-fc11-11ea-16ed-0120c97d8aec
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
# ╟─00000000-0000-0000-0000-000000000001
# ╟─00000000-0000-0000-0000-000000000002
