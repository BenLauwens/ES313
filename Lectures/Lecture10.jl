### A Pluto.jl notebook ###
# v0.11.14

using Markdown
using InteractiveUtils

# ╔═╡ 71de0200-0192-11eb-2262-4f4777e8f058
using Ipopt

# ╔═╡ 759abbe0-0192-11eb-1102-15733a22fcff
using JuMP

# ╔═╡ 444a0740-0191-11eb-382f-dd522542f7c4
md"# Interior Point Methods"

# ╔═╡ db7adcc0-0191-11eb-07b4-5b3fbfc45f72
md"""## Introduction

In the 1980s it was discovered that many large linear programs could
be solved efficiently by using formulations and algorithms from nonlinear
programming. One characteristic of these methods was that they required
all iterates to satisfy the inequality constraints in the problem
strictly, so they became known as _interior-point methods_. In
the 1990s, a subclass of interior-point methods known as _primal-dual
methods_ had distinguished themselves as the most efficient practical
approaches, and proved to be strong competitors to the _simplex
method_ on large problems. Recently, it has been shown that
interior-point methods are as successful for nonlinear optimization
as for linear programming. General primal-dual interior point methods
are the focus of this chapter"""

# ╔═╡ e2fe62a0-0191-11eb-0a1d-51d009d5ab5c
md"""## Interior-point Quadratic Programming

For simplicity, we restrict our attention to convex quadratic programs,
which we write as follows:
```math
\begin{aligned}
\min_{\vec{x}}\, & f\left(\vec{x}\right)\overset{\vartriangle}{=}\frac{1}{2} \vec{x}^\mathsf{T}Q\vec{x}- \vec{c}^\mathsf{T}\vec{x}\\
\textrm{subject to}\, & \begin{cases}
A_{\textrm{eq}}\vec{x}=\vec{b}_{\textrm{eq}}\,,\\
A_{\textrm{in}}\vec{x}\leq\vec{b}_{\textrm{in}}\,,
\end{cases}
\end{aligned}
```
where $Q$ is a symmetric and positive semidefinite $n\times n$ matrix,
$\vec{c}\in\mathbb{R}^{n}$, $A_{\textrm{eq}}$ is a $m\times n$ matrix,
$\vec{b}_{\textrm{eq}}\in\mathbb{R}^{m}$, $A_{\textrm{in}}$ is a $p\times n$
matrix and $\vec{b}_{\textrm{in}}\in\mathbb{R}^{p}$. Rewriting the KKT
conditions in this notation, we obtain
```math
\begin{aligned}
\vec{\mu} & \geq\vec{0}\,,\\
Q\vec{x}+ A_{\textrm{eq}}^\mathsf{T}\vec{\lambda}+ A_{\textrm{in}}^\mathsf{T}\vec{\mu}-\vec{c} & =\vec{0}\,,\\
\left(A_{\textrm{in}}\vec{x}-\vec{b}_{\textrm{in}}\right)_{j}\mu_{j} & =0\,,\quad j=1,\dots,p\,,\\
A_{\textrm{eq}}\vec{x} & =\vec{b}_{\textrm{eq}}\,,\\
A_{\textrm{in}}\vec{x} & \leq\vec{b}_{\textrm{in}}\,.
\end{aligned}
```
By introducing the slack vector $\vec{y}\geq\vec{0}$, we can rewrite
these conditions as
```math
\begin{aligned}
\left(\vec{\mu},\vec{y}\right) & \geq\vec{0}\,,\\
Q\vec{x}+ A_{\textrm{eq}}^\mathsf{T}\vec{\lambda}+ A_{\textrm{in}}^\mathsf{T}\vec{\mu}-\vec{c} & =\vec{0}\,,\\
y_{j}\mu_{j} & =0\,,\quad j=1,\dots,p\,,\\
A_{\textrm{eq}}\vec{x}-\vec{b}_{\textrm{eq}} & =\vec{0}\,,\\
A_{\textrm{in}}\vec{x}-\vec{b}_{\textrm{in}}+\vec{y} & =\vec{0}\,.
\end{aligned}
```
Since we assume that $Q$ is positive semidefinite, these KKT conditions
are not only necessary but also sufficient, so we can solve the convex
quadratic program by finding solutions of this system.

Primal-dual methods generate iterates that satisfy the bounds strictly; that is, $\vec{y}>0$
and $\vec{\mu}>0$. This property is the origin of the term interior-point.
By respecting these bounds, the methods avoid spurious solutions,
points that satisfy the system but not the bounds. Spurious solutions
abound, and do not provide useful information about real solutions,
so it makes sense to exclude them altogether. Given a current iterate
$\left(\vec{x}^{\left(k\right)},\vec{y}^{\left(k\right)},\vec{\lambda}^{\left(k\right)},\vec{\mu}^{\left(k\right)}\right)$
that satisfies $\left(\vec{\mu}^{\left(k\right)},\vec{y}^{\left(k\right)}\right)>0$,
we can define a _complementary measure_
```math
\nu_{k}=\frac{ \left(\vec{y}^{\left(k\right)}\right)^\mathsf{T}\vec{\mu}^{\left(k\right)}}{p}\,.
```
This measure gives an indication of the desirability of the couple
$\left(\vec{\mu}^{\left(k\right)},\vec{y}^{\left(k\right)}\right)$.

We derive a path-following, primal-dual method by considering the
perturbed KKT conditions by
```math
\vec{F}\left(\vec{x}^{\left(k+1\right)},\vec{y}^{\left(k+1\right)},\vec{\lambda}^{\left(k+1\right)},\vec{\mu}^{\left(k+1\right)},\sigma_{k}\nu_{k}\right)=\begin{pmatrix}Q\vec{x}^{\left(k+1\right)}+ A_{\textrm{eq}}^\mathsf{T}\vec{\lambda}^{\left(k+1\right)}+ A_{\textrm{in}}^\mathsf{T}\vec{\mu}^{\left(k+1\right)}-\vec{c}\\
Y_{k+1}M_{k+1}\vec{1}-\sigma_{k}\nu_{k}\vec{1}\\
A_{\textrm{eq}}\vec{x}^{\left(k+1\right)}-\vec{b}_{\textrm{eq}}\\
A_{\textrm{in}}\vec{x}^{\left(k+1\right)}-\vec{b}_{\textrm{in}}+\vec{y}^{\left(k+1\right)}
\end{pmatrix}=\vec{0}\,,
```
where
```math
Y_{k+1}=\begin{pmatrix}y_{1}^{\left(k+1\right)} & 0 & \cdots & 0\\
0 & y_{2}^{\left(k+1\right)} & \ddots & 0\\
\vdots & \ddots & \ddots & 0\\
0 & 0 & 0 & y_{p}^{\left(k+1\right)}
\end{pmatrix}\,,\quad M_{k+1}=\begin{pmatrix}\mu_{1}^{\left(k+1\right)} & 0 & \cdots & 0\\
0 & \mu_{2}^{\left(k+1\right)} & \ddots & 0\\
\vdots & \ddots & \ddots & 0\\
0 & 0 & 0 & \mu_{p}^{\left(k+1\right)}
\end{pmatrix}\,,
```
and $\sigma\in\left[0,1\right]$ is the reduction factor that we wish
to achieve in the complementary measure on one step. We call $\sigma$
the \emph{centering parameter}. The solution of this system for all
positive values of $\sigma$ and $\nu$ define the \emph{central path},
which is a trajectory that leads to the solution of the quadratic
program as $\sigma\nu$ tends to zero.

By fixing $\sigma_{k}$ and applying Newton's method to the system,
we obtain the linear system
```math
\begin{pmatrix}Q & 0 &  A_{\textrm{eq}}^\mathsf{T} &  A_{\textrm{in}}^\mathsf{T}\\
0 & M_{k} & 0 & Y_{k}\\
A_{\textrm{eq}} & 0 & 0 & 0\\
A_{\textrm{in}} & I & 0 & 0
\end{pmatrix}\begin{pmatrix}\vec{d}_{\vec{x}}^{\left(k\right)}\\
\vec{d}_{\vec{y}}^{\left(k\right)}\\
\vec{d}_{\vec{\lambda}}^{\left(k\right)}\\
\vec{d}_{\vec{\mu}}^{\left(k\right)}
\end{pmatrix}=-\begin{pmatrix}Q\vec{x}^{\left(k\right)}+ A_{\textrm{eq}}^\mathsf{T}\vec{\lambda}^{\left(k\right)}+ A_{\textrm{in}}^\mathsf{T}\vec{\mu}^{\left(k\right)}-\vec{c}\\
Y_{k}M_{k}\vec{1}-\sigma_{k}\nu_{k}\vec{1}\\
A_{\textrm{eq}}\vec{x}^{\left(k\right)}-\vec{b}_{\textrm{eq}}\\
A_{\textrm{in}}\vec{x}^{\left(k\right)}-\vec{b}_{\textrm{in}}+\vec{y}^{\left(k\right)}
\end{pmatrix}\,.
```
We obtain the next iterate by setting
```math
\begin{pmatrix}\vec{x}^{\left(k+1\right)}\\
\vec{y}^{\left(k+1\right)}\\
\vec{\lambda}^{\left(k+1\right)}\\
\vec{\mu}^{\left(k+1\right)}
\end{pmatrix}=\begin{pmatrix}\vec{x}^{\left(k\right)}\\
\vec{y}^{\left(k\right)}\\
\vec{\lambda}^{\left(k\right)}\\
\vec{\mu}^{\left(k\right)}
\end{pmatrix}+\alpha_{k}\begin{pmatrix}\vec{d}_{\vec{x}}^{\left(k\right)}\\
\vec{d}_{\vec{y}}^{\left(k\right)}\\
\vec{d}_{\vec{\lambda}}^{\left(k\right)}\\
\vec{d}_{\vec{\mu}}^{\left(k\right)}
\end{pmatrix}\,,
```
where $\alpha_{k}$ is chosen to retain the bounds $\left(\vec{\mu}^{\left(k+1\right)},\vec{y}^{\left(k+1\right)}\right)>0$
and possibly to satisfy various other conditions.

The choices of centering parameter $\sigma_{k}$ and step-length $\alpha_{k}$
are crucial for the performance of the method. Techniques for controlling
these parameters, directly and indirectly, give rise to a wide variety
of methods with diverse properties. One option is to use equal step
length for the primal and dual updates, and to set $\alpha_{k}=\min\left\{ \alpha_{k}^{\textrm{pri}},\alpha_{k}^{\textrm{dual}}\right\} $,
where
```math
\begin{aligned}
\alpha_{k}^{\textrm{pri}} & =\max\left\{ \alpha\in\left\{ 0,1\right\} :\vec{y}^{\left(k\right)}+\alpha\vec{d}_{\vec{y}}^{\left(k\right)}\geq\left(1-\tau\right)\vec{y}^{\left(k\right)}\right\} \,,\label{eq:alpha_pri_max}\\
\alpha_{k}^{\textrm{dual}} & =\max\left\{ \alpha\in\left\{ 0,1\right\} :\vec{\mu}^{\left(k\right)}+\alpha\vec{d}_{\vec{\mu}}^{\left(k\right)}\geq\left(1-\tau\right)\vec{\mu}^{\left(k\right)}\right\} \,,\label{eq:alpha_dual_max}
\end{aligned}
```
the parameter $\tau\in\left]0,1\right[$ controls how far we back
off from the maximum step for which the conditions $\vec{y}^{\left(k\right)}+\alpha\vec{d}_{\vec{y}}^{\left(k\right)}\geq\vec{0}$
and $\vec{\mu}^{\left(k\right)}+\alpha\vec{d}_{\vec{\mu}}^{\left(k\right)}\geq\vec{0}$
are satisfied. A typical value of $\tau=0.995$ and we can choose
$\tau_{k}$ to approach $1$ as the iterates approach the solution,
to accelerate the convergence.

The most popular interior-point method for convex QP is based on Mehrotra's
predictor-corrector. First we compute an affine scaling step $\left(\vec{d}_{\vec{x},\textrm{aff}},\vec{d}_{\vec{y},\textrm{aff}},\vec{d}_{\vec{\lambda},\textrm{aff}},\vec{d}_{\vec{\mu},\textrm{aff}}\right)$
by setting $\sigma_{k}=0$. We improve upon this step by computing
a corrector step. Next, we compute the centering parameter $\sigma_{k}$
using following heuristic
```math
\sigma_{k}=\left(\frac{\nu_{\textrm{aff}}}{\nu_{k}}\right)^{3}\,,
```
where $\nu_{\textrm{aff}}=\frac{ \left(\vec{y}_{\textrm{aff}}\right)^\mathsf{T}\left(\vec{\mu}_{\textrm{aff}}\right)}{p}$.
The total step is obtained by solving the following system
```math
\begin{pmatrix}Q & 0 &  A_{\textrm{eq}}^\mathsf{T} &  A_{\textrm{in}}^\mathsf{T}\\
0 & M_{k} & 0 & Y_{k}\\
A_{\textrm{eq}} & 0 & 0 & 0\\
A_{\textrm{in}} & I & 0 & 0
\end{pmatrix}\begin{pmatrix}\vec{d}_{\vec{x}}^{\left(k\right)}\\
\vec{d}_{\vec{y}}^{\left(k\right)}\\
\vec{d}_{\vec{\lambda}}^{\left(k\right)}\\
\vec{d}_{\vec{\mu}}^{\left(k\right)}
\end{pmatrix}=-\begin{pmatrix}Q\vec{x}^{\left(k\right)}+ A_{\textrm{eq}}^\mathsf{T}\vec{\lambda}^{\left(k\right)}+ A_{\textrm{in}}^\mathsf{T}\vec{\mu}^{\left(k\right)}-\vec{c}\\
Y_{k}M_{k}\vec{1}+\Delta Y_{\textrm{aff}}\Delta M_{\textrm{aff}}\vec{1}-\sigma_{k}\nu_{k}\vec{1}\\
A_{\textrm{eq}}\vec{x}^{\left(k\right)}-\vec{b}_{\textrm{eq}}\\
A_{\textrm{in}}\vec{x}^{\left(k\right)}-\vec{b}_{\textrm{in}}+\vec{y}^{\left(k\right)}
\end{pmatrix}\,,
```
where
```math
\Delta Y_{\textrm{aff}}=Y_{\textrm{aff}}-Y_{k}\,,\quad\Delta M_{\textrm{aff}}=M_{\textrm{aff}}-M_{k}\,.
```"""

# ╔═╡ 578662d0-0192-11eb-027a-7d04d8c5524d
md"""## Julia

The package `Ipopt` integrated in `JuMP` solves a quadratic problem with an interior point method. 
"""

# ╔═╡ 705fed7e-0192-11eb-3f1f-9d13ebbb4fb9
let
	model = Model(with_optimizer(Ipopt.Optimizer))
	@variable(model, 0 <= x, start=2)
	@variable(model, 0 <= y, start=0)
	@NLobjective(model, Min, (x-1)^2+(y-2.5)^2)
	@constraint(model, con1, -x+2y <= 2)
	@constraint(model, con2,  x+2y <= 6)
	@constraint(model, con3,  x-2y <= 2)
	optimize!(model)
    value(x), value(y)
end

# ╔═╡ 947daf90-0192-11eb-38f5-d921e71228e3
md"""## General interior-point method

We consider the general constrained problem
```math
\begin{aligned}
\min\, & f\left(\vec{x}\right)\\
\textrm{subject to} & \begin{cases}
\vec{h}\left(\vec{x}\right)=\vec{0}\\
\vec{g}\left(\vec{x}\right)\leq\vec{0}
\end{cases}
\end{aligned}
```
where $f: \mathbb{R}^{n}\rightarrow \mathbb{R}$, $\vec{h}: \mathbb{R}^{n}\rightarrow \mathbb{R}^{m}$,
$m\leq n$, and $\vec{g}: \mathbb{R}^{n}\rightarrow \mathbb{R}^{p}$. The general
interior-point method can be viewed as a direct extension of interior-point
methods for quadratic programming.

The KKT conditions for the nonlinear optimization problem can be written
as
```math
\begin{aligned}
\left(\vec{\mu},\vec{y}\right) & \geq\vec{0}\,,\\
\nabla f\left(\vec{x}\right)+ \mathsf{J}^\mathsf{T}\vec{h}\left(\vec{x}\right)\vec{\lambda}+ \mathsf{J}^\mathsf{T}\vec{g}\left(\vec{x}\right)\vec{\mu} & =\vec{0}\,,\\
YM\vec{1} -\sigma\nu\vec{1}&=0\,,\\
\vec{h}\left(\vec{x}\right) & =\vec{0}\,,\\
\vec{g}\left(\vec{x}\right)+\vec{y} & =\vec{0}\,,
\end{aligned}
```
with $\nu=0$. This first and third equation from the system introduce
into the problem the combinatorial aspects of determining the optimal
active set. We circumvent this difficulty be letting $\nu$ be strict
positive, thus forcing the variables $\vec{\mu}$ and $\vec{y}$ to
take positive values. We solve approximately the perturbed KKT conditions
for a sequence of positive parameters $\left\{ \sigma_{k}\nu_{k}\right\} $
that converges to zero, while maintaining $\left(\vec{\mu}^{\left(k\right)},\vec{y}^{\left(k\right)}\right)\geq\vec{0}$.

Applying Newton's method to the nonlinear system, we obtain
```math
\begin{gathered}
\begin{bmatrix}\mathsf{H} \mathcal{L}\left(\vec{x}^{\left(k\right)},\vec{y}^{\left(k\right)},\vec{\lambda}^{\left(k\right)},\vec{\mu}^{\left(k\right)}\right) & 0 &  \mathsf{J}^\mathsf{T}\vec{h}\left(\vec{x}^{\left(k\right)}\right) &  \mathsf{J}^\mathsf{T}\vec{g}\left(\vec{x}^{\left(k\right)}\right)\\
0 & M_{k} & 0 & Y_{k}\\
\mathsf{J}\vec{h}\left(\vec{x}^{\left(k\right)}\right) & 0 & 0 & 0\\
\mathsf{J}\vec{g}\left(\vec{x}^{\left(k\right)}\right) & I & 0 & 0
\end{bmatrix}\begin{bmatrix}\vec{d}_{\vec{x}}^{\left(k\right)}\\
\vec{d}_{\vec{y}}^{\left(k\right)}\\
\vec{d}_{\vec{\lambda}}^{\left(k\right)}\\
\vec{d}_{\vec{\mu}}^{\left(k\right)}
\end{bmatrix}=\\\qquad\qquad\qquad\qquad-\begin{bmatrix}\nabla f\left(\vec{x}^{\left(k\right)}\right)+ \mathsf{J}^\mathsf{T}\vec{h}\left(\vec{x}^{\left(k\right)}\right)\vec{\lambda}^{\left(k\right)}+ \mathsf{J}^\mathsf{T}\vec{g}\left(\vec{x}^{\left(k\right)}\right)\vec{\mu}^{\left(k\right)}\\
Y_{k}M_{k}-\sigma_{k}\nu_{k}\vec{1}\\
\vec{h}\left(\vec{x}^{\left(k\right)}\right)\\
\vec{g}\left(\vec{x}^{\left(k\right)}\right)+\vec{y}^{\left(k\right)}
\end{bmatrix}\,.
\end{gathered}
```
Numerical experience has shown, however, that using different step-lengths
in the primal and dual variables often leads to better convergence.
After the step $k$ has been computed and the maximum step lengths have been
determined, we perform a backtracking line search that computes the
step-lengths.
```math
\alpha_{k,\textrm{back}}^{\textrm{pri}}\in\left]0,\alpha_{k}^{\textrm{pri}}\right]\,,\quad\alpha_{k,\textrm{back}}^{\textrm{dual}}\in\left]0,\alpha_{k}^{\textrm{dual}}\right]\,,
```
providing sufficient decrease.

The centering parameter $\sigma_{k}$ can be calculated by a predictor-corrector
strategy as in the quadratic programming case. """

# ╔═╡ 9a17bf80-0193-11eb-1a85-d79e20b63a4a


# ╔═╡ 96b90420-0193-11eb-3f8f-b1fdc9e66341
let
	m = Model(with_optimizer(Ipopt.Optimizer))

	a1 = 2
	b1 = 0
	a2 = -1
	b2 = 1

	@variable(m, x1, start=1.234)
	@variable(m, x2 >= 0, start=5.678)

	@NLobjective(m, Min, sqrt(x2))
	@NLconstraint(m, x2 >= (a1*x1+b1)^3)
	@NLconstraint(m, x2 >= (a2*x1+b2)^3)

	optimize!(m)
	value(x1), value(x2)
end

# ╔═╡ Cell order:
# ╟─444a0740-0191-11eb-382f-dd522542f7c4
# ╟─db7adcc0-0191-11eb-07b4-5b3fbfc45f72
# ╟─e2fe62a0-0191-11eb-0a1d-51d009d5ab5c
# ╟─578662d0-0192-11eb-027a-7d04d8c5524d
# ╠═71de0200-0192-11eb-2262-4f4777e8f058
# ╠═759abbe0-0192-11eb-1102-15733a22fcff
# ╠═705fed7e-0192-11eb-3f1f-9d13ebbb4fb9
# ╟─947daf90-0192-11eb-38f5-d921e71228e3
# ╠═9a17bf80-0193-11eb-1a85-d79e20b63a4a
# ╠═96b90420-0193-11eb-3f8f-b1fdc9e66341
