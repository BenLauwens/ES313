### A Pluto.jl notebook ###
# v0.11.14

using Markdown
using InteractiveUtils

# ╔═╡ 7ad2ee88-07c9-11eb-3b6b-65a34e4980ef
using Distributions, LinearAlgebra

# ╔═╡ e0e6af0a-07ce-11eb-3da3-e93277620d89
using Plots

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

# ╔═╡ 976bb1e0-07c9-11eb-2a4f-fb7aac69f8ec
begin
	function gengraph(N::Int, p::Float64)
		d = Bernoulli(p) # definir la distribution
		A = rand(d, N, N)
		# annuler la diagonale
		A[diagind(A)] = zeros(Int,N)
		return LinearAlgebra.Symmetric(A)
	end
	
	function avgdegree(A)
		return mean(sum(A, dims=1))
	end
	
	"""
		voisins(A, i)
	
	Détermine les voisins du noeud i dans le graph représenté par A
	"""
	function voisins(A, i)
		findall(x -> isequal(x, 1), A[i,:])
	end
	
	function composantes(A)
		N = size(A,1) # taille du graph
		visited = Dict(i => false for i in 1:N)
		comps = []
		for n in 1:N
			if !visited[n]
				# faire qqch (i.e. déterminier la composante)
				push!(comps,creuser(A, n, visited))
				end
		end
		#return comps
		return maximum(length,comps) / N
	end
	
	function creuser(A, n, visited, comp=[])
		visited[n] = true
		push!(comp, n)
		for voisin in voisins(A, n)
			if !visited[voisin]
				creuser(A, voisin, visited, comp)
			end
		end
		return comp
	end
	
	function sim(N::Int, p::Float64)
		A = gengraph(N,p)
		return composantes(A), avgdegree(A)
	end
end

# ╔═╡ 42f5cca6-07d1-11eb-3169-cd3650c42081
N = 1000

# ╔═╡ a060dc62-07cb-11eb-2aaa-7190bde5dc36
let N = N
	P = range(5e-5, 3e-3, length=10)
	rat_comp = Array{Float64, 1}()
	k_moy = Array{Float64, 1}()
	for p in P
		for _ in 1:10
			res = sim(N,p)
			push!(rat_comp, res[1])
			push!(k_moy, res[2])
		end
	end
	scatter(k_moy, rat_comp, ylims=(0,1), label="", xlabel="<k>", ylabel="N_largest_comp / N")
end

# ╔═╡ Cell order:
# ╟─235e2200-fce9-11ea-0696-d36cddaa843e
# ╠═7ad2ee88-07c9-11eb-3b6b-65a34e4980ef
# ╠═976bb1e0-07c9-11eb-2a4f-fb7aac69f8ec
# ╠═e0e6af0a-07ce-11eb-3da3-e93277620d89
# ╠═42f5cca6-07d1-11eb-3169-cd3650c42081
# ╠═a060dc62-07cb-11eb-2aaa-7190bde5dc36
