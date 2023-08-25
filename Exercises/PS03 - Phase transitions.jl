### A Pluto.jl notebook ###
# v0.19.27

using Markdown
using InteractiveUtils

# ╔═╡ cc106912-0b14-4981-a67b-580dda8a56ed
begin
	# Pkg needs to be used to force Pluto to use the current project instead of making an environment for each notebook
	using Pkg
	cd(joinpath(dirname(@__FILE__),".."))
    Pkg.activate(pwd())
    using Distributions, LinearAlgebra, Plots, InteractiveUtils, Graphs
end

# ╔═╡ f6ac02a6-6fd5-4527-bd45-d77c96526517
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

# ╔═╡ 235e2200-fce9-11ea-0696-d36cddaa843e
md"""
# Phase transition in networks
## Generalities - Networks

A network is a set of objects (called nodes or vertices) that are connected together. The connections between the nodes are called edges or links. In mathematics, networks are often referred to as [graphs](https://en.wikipedia.org/wiki/Graph_(discrete_mathematics)). 

In the following, we will only consider undirected networks i.e. if node $i$ is connected to node $j$, then node $j$ is automatically connected to node $i$ (as is the case with Facebook friendships). For unweighted networks of $N$ nodes, the network structure can be represented by an $N \times N$ adjacency matrix $A$:

```math
a_{i,j} = \left\{
                \begin{array}{ll}
                  1 & \text{if there is an edge from node $i$ to node $j$}\\
                  0 & \text{otherwise}\\
                \end{array}
                \right.
```
The degree of a node $i$ is the number of connections it has. In terms of the adjacency matrix
$A$, the degree of node $i$ is the sum of the i$^{\text{th}}$ row of $A$:
$$k_i = \sum_{j=1}^{N}a_{i,j}$$

The average node degree $\langle k \rangle$ is then given by: $$\langle k \rangle = \sum_{i=1}^{N}k_{i}$$


## Erdös-Rényi random graph model
One of the simplest graph models is the Erdös-Rényi random graph model, denoted by $\mathcal{G}(N,p)$ with $N$ being the amount of nodes and $p$ being the probability that a link exists between two nodes. Self-loops are excluded. The value of $p$ is typically small (this is to avoid that the average degree $\langle k \rangle$ depends on $N$, cf. specialised literature for more details). When studying random graph model models, a major aim is to predict the average behaviour of certain network metrics and, if possible, their variance.



The Erdös-Rényi random graph  exhibits a phase transition. Let us consider the size (i.e., number of nodes) of the largest connected component in the network as a function of the mean degree ⟨k⟩. When ⟨k⟩ = 0, the network is trivially composed of N disconnected nodes. In the other extreme of ⟨k⟩ = N − 1, each node pair is adjacent such that the network is trivially connected. Between the two extremes, the network does not change smoothly in terms of the largest component size. Instead, a giant component, i.e., a component whose size is the largest and proportional to N, suddenly appears as ⟨k⟩ increases, marking a phase transition. The goal of this application is to determine this value by simulation.

## Problem solution
We split the problem in a series of subproblems:
* generating a random graph
* determine the average degree
* identifying the size of the largest connected component
* visualising the result
* determine the critical value

"""

# ╔═╡ 6383ad7c-9f23-40a0-a505-d9f36d4b26eb


# ╔═╡ 88477467-5ff0-40ff-bdfe-950838bc65ec
md"""
# From theory to simulation
Read through the paper "[Phase transition for the SIR model with random transition rates on complete graphs](https://arxiv.org/pdf/1609.05974.pdf)".

Do you understand this model? Can you:
1. implement the SIR model on graphs? (hint: use Graphs.jl and or SimpleWeightedGraphs.jl)
2. show how the S-I-R evolve over time?
3. observe the theoretical results in your simulation?
"""

# ╔═╡ Cell order:
# ╟─f6ac02a6-6fd5-4527-bd45-d77c96526517
# ╠═cc106912-0b14-4981-a67b-580dda8a56ed
# ╟─235e2200-fce9-11ea-0696-d36cddaa843e
# ╠═6383ad7c-9f23-40a0-a505-d9f36d4b26eb
# ╟─88477467-5ff0-40ff-bdfe-950838bc65ec
