### A Pluto.jl notebook ###
# v0.16.0

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

# ╔═╡ d3dcd770-058d-11eb-2829-fbb18e85f401


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

# ╔═╡ 56a7c778-04c1-11eb-03c0-fd5d27d989b1


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

# ╔═╡ c6cb56d8-058d-11eb-2f71-73a5e5ca3dd0


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
# ╟─86702ce8-04b7-11eb-22d1-b7f1437cf740
# ╠═caf5c6d8-04b8-11eb-1c04-0966207fbf28
# ╠═d3dcd770-058d-11eb-2829-fbb18e85f401
# ╟─a510792e-04c0-11eb-0f6e-a7e40dfe602c
# ╠═56a7c778-04c1-11eb-03c0-fd5d27d989b1
# ╠═c4eca510-04c0-11eb-0e29-a5dcc1386bd5
# ╠═c6cb56d8-058d-11eb-2f71-73a5e5ca3dd0
# ╟─cb6898d6-0565-11eb-2a3c-1514a0fa4f50
# ╠═b76bae36-058d-11eb-216c-dfb8abd85772
