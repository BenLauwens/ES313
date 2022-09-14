### A Pluto.jl notebook ###
# v0.19.11

using Markdown
using InteractiveUtils

# ╔═╡ 7e441457-f128-4b48-9197-268ad85f8070
# Explicit use of own environment instead of a local one for each notebook
begin
	using Pkg
	cd(joinpath(dirname(@__FILE__),".."))
    Pkg.activate(pwd())
    using NativeSVG
	using Plots
	using JuMP
	using GLPK
	using LaTeXStrings
	using Tulip
end

# ╔═╡ 5fd1dfc0-fc04-11ea-1747-69f05b302ab0
md"# Linear Programming: Simplex Method"

# ╔═╡ dec71840-fc04-11ea-33f5-c353bc11b181
md"""## Karush-Kuhn-Tucker Conditions

We consider the linear program

```math
\begin{aligned}
\min &\vec{c}^\mathsf{T}\vec x\\
\textrm{ subject to } &\begin{cases}
\mathbf{A}\vec x=\vec b\\
\vec x\ge\vec 0
\end{cases}
\end{aligned}
```

and define the Lagrangian function

```math
\mathcal L\left(\vec x,\vec \lambda,\vec s\right) = \vec{c}^\mathsf{T}\vec x - \vec \lambda^\mathsf{T}\left(\mathbf A\vec x-\vec b\right) - \vec s^\mathsf{T}\vec x
```

where $\vec \lambda$ are the multipliers for the equality constraints and $\vec s$ are the multipliers for the bound constraints.

The Karush-Kuhn-Tucker condition states that to find the first-order necessary conditions for $\vec x^\star$ to be a solution of the problem, their exist $\vec \lambda^\star$ and $\vec s^\star$ such that

```math
\begin{aligned}
\mathbf A^\mathsf{T}\vec \lambda^\star+\vec s^\star&=\vec c\\
\mathbf A\vec x^\star&=\vec b\\
\vec x^\star&\ge\vec 0\\
\vec s^\star&\ge \vec 0\\
\left(\vec x^\star\right)^\mathsf{T}\vec s^\star&=0
\end{aligned}
```

The first eqation states that the gradient of the Lagrangian with respect to $\vec x$ must be zero and the last equation that at least $x_i$ or $s_i$ must be zero for each $i=1,2,\dots,n$.

It can be shown that these conditions are also sufficient."""

# ╔═╡ 35e94ee0-fc05-11ea-3183-d153786970b0
md"""## The Simplex Method Explained

As mentioned in the previous lecture, all iterates of the simplex method are basic feasible points and therefore vertices of the feasible polytope. Most steps consists of a move from one vertex to an adjacent one. On most steps (but not all), the value of the objective function $\vec{c}^\mathsf{T}\vec x$ is decreased. Another type of step occurs when the problem is unbounded: the step is an edge along which the objective funtion is reduced, and along which we can move infinitely far without reaching a vertex.

The major issue at each simplex iteration is to decide which index to remove from the basic index set $\mathcal B$. Unless the step is a direction of unboundness, a single index must be removed from $\mathcal B$ and replaced by another from outside $\mathcal B$. We can gain some insight into how this decision is made by looking again at the KKT conditions.

First, define the nonbasic index set $\mathcal N = \left\{1,2,\dots,n\right\} \setminus \mathcal B$. Just as $\mathbf B$ is the basic matrix, whose columns are $\mathbf A_i$ for $i\in\mathcal B$, we use $\mathbf N$ to denote the nonbasic matrix $\mathbf N=\left[\mathbf A_i\right]_{i\in\mathcal N}$. We also partition the vectors $\vec x$, $\vec s$ and $\vec c$ according to the index sets $\mathcal B$  and $\mathcal N$, using the notation

```math
\begin{aligned}
\vec x_\mathbf B=\left[\vec x_i \right]_{i\in\mathcal B},&\qquad\vec x_\mathbf N=\left[\vec x_i \right]_{i\in\mathcal N}\\
\vec s_\mathbf B=\left[\vec s_i \right]_{i\in\mathcal B},&\qquad\vec s_\mathbf N=\left[\vec s_i \right]_{i\in\mathcal N}\\
\vec c_\mathbf B=\left[\vec c_i \right]_{i\in\mathcal B},&\qquad\vec c_\mathbf N=\left[\vec c_i \right]_{i\in\mathcal N}
\end{aligned}
```

From the second KKT conditions, we have that

```math
\mathbf A \vec x= \mathbf B \vec x_\mathbf B + \mathbf N \vec x_\mathbf N=\vec b\,.
```

The _primal_ variable $\vec x$ for this simplex iterate is defined as

```math
\vec x_\mathbf B = \mathbf B^{-1}\vec b,\qquad \vec x_\mathbf N=\vec 0\,.
```

Since we are dealing only with basic feasible points, we know that $\mathbf B$ is nonsingular and that $\vec x_\mathbf B\ge\vec0$, so this choice of $\vec x$ satisfies two of the KKT conditions.

We choose $\vec s$ to satisfy the complimentary condition (the last one) by setting $\vec s_\mathbf B=\vec 0$. The remaining components $\vec \lambda$ and $\vec s_\mathbf N$ can be found by partitioning this condition into $\vec c_\mathbf B$ and $\vec c_\mathbf N$ components and using $\vec s_\mathbf B=\vec 0$ to obtain

```math
\mathbf B^\mathsf{T}\vec \lambda=\vec c_\mathbf B,\qquad \vec N^\mathsf{T}\vec\lambda+\vec s_\mathbf N = \vec c_\mathbf N\,.
```

Since $\mathbf B$ is square and nonsingular, the first equation uniquely defines $\vec \lambda$ as

```math
\vec \lambda = \left(\mathbf B^\mathsf{T}\right)^{-1}\vec c_\mathbf B\,.
```

The second equation implies a value for $\vec s_\mathbf N$:

```math
\vec s_\mathbf N = \vec c_\mathbf N - \mathbf N^\mathsf{T}\vec \lambda=\vec c_\mathbf N -\left(\mathbf B ^{-1}\mathbf N\right)^\mathsf{T}\vec c_\mathbf B\,.
```

Computation of the vector $\vec s_\mathbf N$ is often referred to as _pricing_. The components of $\vec s_\mathbf N$ are often called the _reduced costs_ of the nonbasic variables $\vec x_\mathbf N$.

The only KKT condition that we have not enforced explicitly is the nonnegativity condition $\vec s \ge \vec 0$. The basic components $\vec s_\mathbf B$ certainly satisfy this condition, by our choice $\vec s_\mathbf B = 0$. If the vector $\vec s_\mathbf N$ also satisfies $\vec s_\mathbf N \ge \vec 0$, we have found an optimal
vector triple $\left(\vec x^\star, \vec \lambda^\star, \vec s^\star\right)$, so the algorithm can terminate and declare success. Usually, however, one or more of the components of $\vec s_\mathbf N$ are negative. The new index to enter the basis index set $\mathcal B$ is chosen to be one of the indices $q \in \mathcal N$ for which $s_q < 0$. As we show below, the objective $\vec{c}^\mathsf{T}\vec x$ will decrease when we allow $x_q$ to become positive if and only if 

1. ``s_q < 0`` and
2. it is possible to increase $x_q$ away from zero while maintaining feasibility of $\vec x$.

Our procedure for altering $\mathcal B$ and changing $\vec x$ and $\vec s$ can be described accordingly as follows:

- allow $x_q$ to increase from zero during the next step;
- fix all other components of $\vec x_\mathbf N$ at zero, and figure out the effect of increasing $x_q$ on the current basic vector $\vec x_\mathbf B$, given that we want to stay feasible with respect to the equality constraints $\mathbf{A}\vec x=\vec b$;
- keep increasing $x_q$ until one of the components of $\vec x_\mathbf B$ ($x_p$, say) is driven to zero, or determining that no such component exists (the unbounded case);
- remove index $p$ (known as the leaving index) from $\mathcal B$ and replace it with the entering index $q$.

This process of selecting entering and leaving indices, and performing the algebraic operations necessary to keep track of the values of the variables $\vec x$, $\vec \lambda$, and $\vec s$, is sometimes known as _pivoting_.

We now formalize the pivoting procedure in algebraic terms. Since both the new iterate $\vec x^+$ and the current iterate $\vec x$ should satisfy $\mathbf A\vec x=\vec b$, and since $\vec x_\mathbf N=\vec 0$ and $\vec x_i^{+}=0$ for $i\in\mathcal N\setminus\left\{q\right\}$ we have

```math
\mathbf A\vec x^+=\mathbf B\vec x_\mathbf B^+ +\vec A_q x_q^+=\vec b=\mathbf B\vec x_\mathbf B=\mathbf A\vec x\,.
```

By multiplying this expression by $\mathbf B^{-1}$ and rearranging, we obtain

```math
\vec x_\mathbf B^+=\vec x_\mathbf B-\mathbf B^{-1}\vec A_q x_q^+
```

Geometrically speaking, we move along an edge of the feasible polytope that decreases $\vec{c}^\mathsf{T}\vec x$. We continue to move along this edge until a new vertex is encountered. At this vertex, a new constraint $x_p \ge 0$ must have become active, that is, one of the components $x_p$, $p \in \mathbf B$, has decreased to zero. We then remove this index $p$ from the basis index set $\mathcal B$ and replace it by $q$.

It is possible that we can increase $x_q^+$ to $\infty$ without ever encountering a new vertex. In other words, the constraint $x_\mathbf B^+=x_\mathbf B-\mathbf B^{-1}\vec A_q\vec x_q^+\ge 0$ holds for all positive values of $x_q+$. When this happens, the linear program is unbounded; the simplex method has identified a
ray that lies entirely within the feasible polytope along which the objective $\vec{c}^\mathsf{T}\vec x$ decreases to $−\infty$.
"""

# ╔═╡ 71ce4140-fc05-11ea-3e86-913a7fbbdbc4
md"""## One Step of Simplex Algorithm

Given $\mathcal B$, $\mathcal N$, $x_\mathbf B=\mathbf B^{-1}\vec b\ge 0$,$\vec x_\mathbf N=\vec 0$;

1. Solve $\vec \lambda = \left(\mathbf B^\mathsf{T}\right)^{-1}\vec c_\mathbf B$, and  compute $\vec s_\mathbf N =\vec c_\mathbf N - \mathbf N^\mathsf{T} \vec \lambda$ (pricing);
2. If $\vec s_\mathbf N \ge \vec 0$ stop (optimal point found);
3. Select $q\in\mathcal N$ with $s_q<0$ and solve $\vec d=\mathbf B^{-1}\vec A_q$;
4. If $\vec d\le\vec 0$ stop (problem is unbounded);
5. Calculate $x_q^+=\min_{i|d_i>0}\frac{\left(x_\mathbf B\right)_i}{d_i}$, and use $p$ to denote the minimizing $i$;
6. Update $\vec x_\mathbf B^+=\vec x_\mathbf B-x_q^+\vec d$;
7. Change $\mathcal B$ by adding $q$ and removing the basic variable corresponding to column $p$ of $\mathbf B$.

We illustrate this procedure with a simple example.

Consider the problem

```math
\begin{aligned}
\min &-4x_1-2x_2\\
\textrm{ subject to }&
\begin{cases}
x_1+x_2+x_3&=5\\
2x_1+\frac{1}{2}x_2+x_4&=8\\
\vec x&\ge \vec 0
\end{cases}
\end{aligned}
```

Suppose we start with the basis index set $\mathcal B=\left\{3,4\right\}$, for which we have"""

# ╔═╡ 3178001e-fc07-11ea-382e-ad3800a90164
let B = [1 0;0 1], N = [1 1;2 0.5], b = [5;8], cB = [0;0], cN = [-4;-2]
	xB = inv(B)*b
	λ = inv(transpose(B))*cB
	sN = cN - transpose(N)*λ
	xB, λ, sN
end

# ╔═╡ b28dceae-fc07-11ea-1170-6dc3520cfafb
md"""```math
\vec x_\mathbf B =
\begin{pmatrix}
x_3\\
x_4
\end{pmatrix}
= 
\begin{pmatrix}
5\\
8
\end{pmatrix}
\,\qquad\vec\lambda = 
\begin{pmatrix}
0\\
0
\end{pmatrix}
\,\qquad\vec s_\mathbf N =
\begin{pmatrix}
s_1\\
s_2
\end{pmatrix}
=
\begin{pmatrix}
-4\\
-2
\end{pmatrix}
```

and an objective value of $\vec{c}^\mathsf{T}\vec x=0$. Since both elements of $\vec s_\mathbf N$ are negative, we could choose either 1 or 2 to be the entering variable. Suppose we choose $q=1$. We obtain

```math
\vec d = \begin{pmatrix}
1\\
2
\end{pmatrix}\,,
```

so we cannot (yet) conclude that the problem is unbounded. By performing the ratio calculation, we find that $p=2$ (corresponding to index 4) and $x_1^+=4$."""

# ╔═╡ d9164f2e-fc07-11ea-144c-f1056f14c202
let B = [1 0;0 1], N = [1 1;2 0.5], b = [5;8], cB = [0;0], cN = [-4;-2], xB = [5;8]
	q = 1
	Aq = [1;2]
	d = inv(B)*Aq
	ratio = xB./d
	xq = minimum(ratio)
	xB -= d * xq
	d, ratio, xq, xB
end

# ╔═╡ 2194cfbe-fc08-11ea-1b60-7992c45b8657
md"""We update the basic and nonbasic index sets to $\mathcal B=\left\{3,1\right\}$ and  $\mathcal N=\left\{4,2\right\}$, and move to the next iteration.

At the second iteration, we have"""

# ╔═╡ 3c9691a0-fc08-11ea-22d5-0f2f300742dd
let B = [1 1;0 2], N = [0 1;1 0.5], b = [5;8], cB = [0;-4], cN = [0;-2]
	xB = inv(B)*b
	λ = inv(transpose(B))*cB
	sN = cN - transpose(N)*λ
	xB, λ, sN
end

# ╔═╡ 5f50cc10-fc08-11ea-1685-7971cb0db6dc
md"""
```math
\vec x_\mathbf B =
\begin{pmatrix}
x_3\\
x_1
\end{pmatrix}
= 
\begin{pmatrix}
1\\
4
\end{pmatrix}
\,\qquad\vec\lambda = 
\begin{pmatrix}
0\\
-2
\end{pmatrix}
\,\qquad\vec s_\mathbf N =
\begin{pmatrix}
s_4\\
s_2
\end{pmatrix}
=
\begin{pmatrix}
2\\
-1
\end{pmatrix}
```

with an objective value of -16. We see that $\vec s_\mathbf N$ has one negative component, corresponding to the index $q=2$, se we select this index to enter the basis. We obtain
"""

# ╔═╡ 75854e70-fc08-11ea-1b6a-85041a569331
let B = [1 1;0 2], N = [0 1;1 0.5], b = [5;8], cB = [0;-4], cN = [0;-2], xB=[1;4]
	q = 2
	Aq = [1;0.5]
	d = inv(B)*Aq
	ratio = xB./d
	xq = minimum(ratio)
	xB -= d * xq
	d, ratio, xq, xB
end

# ╔═╡ f8c0e330-fc08-11ea-167e-5387081f0284
md"""```math
\vec d = \begin{pmatrix}
\frac{3}{4}\\
\frac{1}{4}
\end{pmatrix}\,,
```

so again we do not detect unboundedness. Continuing, we find that the minimum value of $x_2^+$ is $\frac{4}{3}$, and that $p=1$, which indicates that index 3 will leave the basic index set $\mathcal B$. We update the index sets to $\mathcal B=\left\{2,1\right\}$ and  $\mathcal N=\left\{4,3\right\}$ and continue.

At the start of the third iteration, we have
"""

# ╔═╡ 1d47ee60-fc09-11ea-3bf3-35d97f379156
let B = [1 1;0.5 2], N = [0 1;1 0], b = [5;8], cB = [-2;-4], cN = [0;0]
	xB = inv(B)*b
	λ = inv(transpose(B))*cB
	sN = cN - transpose(N)*λ
	xB, λ, sN
end

# ╔═╡ 38877c92-fc09-11ea-0968-a1ca7452e641
md"""```math
\vec x_\mathbf B =
\begin{pmatrix}
x_2\\
x_1
\end{pmatrix}
= 
\begin{pmatrix}
\frac{4}{3}\\
\frac{11}{3}
\end{pmatrix}
\,\qquad\vec\lambda = 
\begin{pmatrix}
-\frac{4}{3}\\
-\frac{4}{3}
\end{pmatrix}
\,\qquad\vec s_\mathbf N =
\begin{pmatrix}
s_4\\
s_3
\end{pmatrix}
=
\begin{pmatrix}
\frac{4}{3}\\
\frac{4}{3}
\end{pmatrix}
```

with an objective value of $-\frac{52}{3}$. We see that $\vec s_\mathbf N\ge\vec 0$, so the optimality test is satisfied, and we terminate.

We need to flesh out this procedure with specifics of three important aspects of the implementation:

- Linear algebra issues—maintaining an LU factorization of $\mathbf B$ that can be used to solve for $\vec \lambda$ and $\vec d$.
- Selection of the entering index $q$ from among the negative components of $\vec s_\mathbf N$. (In general, there are many such components.)
- Handling of degenerate bases and degenerate steps, in which it is not possible to choose a positive value of $x_q$ without violating feasibility.

Proper handling of these issues is crucial to the efficiency of a simplex implementation. We will use a software package handling these details."""

# ╔═╡ 875ac700-fc09-11ea-217b-0b38e80b750f
begin
	model = Model(GLPK.Optimizer)
	@variable(model, 0 <= x1)
	@variable(model, 0 <= x2)
	@objective(model, Min, -4*x1 -2*x2)
	@constraint(model, con1, x1 + x2 <= 5)
	@constraint(model, con2, 2*x1 + 0.5*x2 <= 8)
	model
end

# ╔═╡ d173e4c0-fc09-11ea-1fbe-d1194a0d0705
optimize!(model)

# ╔═╡ e1efb630-fc09-11ea-300d-916f043ea3a6
termination_status(model)

# ╔═╡ e6daddf0-fc09-11ea-21f5-d3f750fe3091
primal_status(model)

# ╔═╡ ec419e50-fc09-11ea-2878-292809bd19a9
objective_value(model)

# ╔═╡ f1f82c60-fc09-11ea-0422-0572134255d0
value(x1)

# ╔═╡ f7f8e2d0-fc09-11ea-0fe5-f3fe06bee660
value(x2)

# ╔═╡ 0a0dcad0-fc0a-11ea-152a-c97a915d6598
let
	x = -1:5
	plot(x, 5 .- x, linestyle=:dash, label=L"x_1+x_2=5")
	plot!(x, (8 .- 2 .* x) ./ 0.5, linestyle=:dash, label=L"2x_1+0.5x_2=8")
	plot!([0,4,11/3,0,0],[0,0,4/3,5,0], linewidth=2, label="constraints")
	plot!(x, -4 .* x ./ 2, label=L"f\left(x_1,x_2\right)=-4x_1-2x_2=0")
	plot!(x, (-16 .+ 4 .* x) ./ -2, label=L"f\left(x_1,x_2\right)=-4x_1-2x_2=-16")
	plot!(x, (-52/3 .+ 4 .* x) ./ -2, label=L"f\left(x_1,x_2\right)=-4x_1-2x_2=-52/3")
end

# ╔═╡ 209a3130-fc0a-11ea-3e4d-831b98ac933f
md"""## Where does the Simplex Method fit?

In linear programming, as in all optimization problems in which inequality constraints are present, the fundamental task of the algorithm is to determine which of these constraints are active at the solution and which are inactive. The simplex method belongs to a general class of algorithms for constrained optimization known as _active set methods_, which explicitly maintain estimates of the active and inactive index sets that are updated at each step of the algorithm. (At each iteration, the basis $\mathcal B$ is our current estimate of the inactive set, that is, the set of indices $i$ for which we suspect that $x_i > 0$ at the solution of the linear program.) Like most active set methods, the simplex method makes only modest changes to these index sets at each step; a single index is exchanged between $\mathcal B$ into $\mathcal N$.

One undesirable feature of the simplex method attracted attention from its earliest days. Though highly efficient on almost all practical problems (the method generally requires at most $2m$ to $3m$ iterations, where $m$ is the row dimension of the constraint matrix, there are pathological problems on which the algorithm performs very poorly. The complexity of the simplex method is _exponential_, roughly speaking, its running time may be an exponential function of the dimension of
the problem. For many years, theoreticians searched for a linear programming algorithm that has polynomial complexity, that is, an algorithm in which the running time is bounded by a polynomial function of the amount of storage required to define the problem.

In the mid-1980s, Karmarkar described a polynomial algorithm that approaches the solution through the interior of the feasible polytope rather than working its way around the boundary as the simplex method does."""

# ╔═╡ 276abac0-fc0a-11ea-3f72-97fec80d2b88
md"""# Linear Programming: Interiod Point Method

In the 1980s it was discovered that many large linear programs could be solved efficiently by using formulations and algorithms from nonlinear programming and nonlinear equations. One characteristic of these methods was that they required all iterates to satisfy the inequality constraints in the problem _strictly_, so they became known as interior-point methods. By the early 1990s, a subclass of interior-point methods known as primal-dual methods had distinguished themselves as the most efficient practical approaches, and proved to be strong competitors to the simplex method on large problems.

Interior-point methods arose from the search for algorithms with better theoretical properties than the simplex method. The simplex method can be inefficient on certain pathological problems. Roughly speaking, the time required to solve a linear program may be exponential in the size of the problem, as measured by the number
of unknowns and the amount of storage needed for the problem data. For almost all practical problems, the simplex method is much more efficient than this bound would suggest, but its poor worst-case complexity motivated the development of new algorithms with better guaranteed performance.

Interior-point methods share common features that distinguish them from the simplex method. Each interior-point iteration is expensive to compute and can make significant progress towards the solution, while the simplex method usually requires a larger number of inexpensive iterations. Geometrically speaking, the simplex method works its way around the boundary of the feasible polytope, testing a sequence of vertices in turn until it finds the optimal one. Interior-point methods approach the boundary of the feasible set only in the limit. They may approach the solution either from the interior or the exterior of the feasible region, but they never actually lie on the boundary of this region."""

# ╔═╡ c4b3f7f0-fc0b-11ea-2d9b-e9af94723e70
let
	model = Model(Tulip.Optimizer)
	@variable(model, 0 <= x1)
	@variable(model, 0 <= x2)
	@objective(model, Min, -4*x1 -2*x2)
	@constraint(model, con1, x1 + x2 <= 5)
	@constraint(model, con2, 2*x1 + 0.5*x2 <= 8)
	optimize!(model)
	value(x1), value(x2)
end

# ╔═╡ Cell order:
# ╠═7e441457-f128-4b48-9197-268ad85f8070
# ╟─5fd1dfc0-fc04-11ea-1747-69f05b302ab0
# ╟─dec71840-fc04-11ea-33f5-c353bc11b181
# ╟─35e94ee0-fc05-11ea-3183-d153786970b0
# ╟─71ce4140-fc05-11ea-3e86-913a7fbbdbc4
# ╠═3178001e-fc07-11ea-382e-ad3800a90164
# ╟─b28dceae-fc07-11ea-1170-6dc3520cfafb
# ╠═d9164f2e-fc07-11ea-144c-f1056f14c202
# ╟─2194cfbe-fc08-11ea-1b60-7992c45b8657
# ╠═3c9691a0-fc08-11ea-22d5-0f2f300742dd
# ╟─5f50cc10-fc08-11ea-1685-7971cb0db6dc
# ╠═75854e70-fc08-11ea-1b6a-85041a569331
# ╟─f8c0e330-fc08-11ea-167e-5387081f0284
# ╠═1d47ee60-fc09-11ea-3bf3-35d97f379156
# ╟─38877c92-fc09-11ea-0968-a1ca7452e641
# ╠═875ac700-fc09-11ea-217b-0b38e80b750f
# ╠═d173e4c0-fc09-11ea-1fbe-d1194a0d0705
# ╠═e1efb630-fc09-11ea-300d-916f043ea3a6
# ╠═e6daddf0-fc09-11ea-21f5-d3f750fe3091
# ╠═ec419e50-fc09-11ea-2878-292809bd19a9
# ╠═f1f82c60-fc09-11ea-0422-0572134255d0
# ╠═f7f8e2d0-fc09-11ea-0fe5-f3fe06bee660
# ╠═0a0dcad0-fc0a-11ea-152a-c97a915d6598
# ╟─209a3130-fc0a-11ea-3e4d-831b98ac933f
# ╟─276abac0-fc0a-11ea-3f72-97fec80d2b88
# ╠═c4b3f7f0-fc0b-11ea-2d9b-e9af94723e70
