### A Pluto.jl notebook ###
# v0.19.11

using Markdown
using InteractiveUtils

# ╔═╡ bf54eece-fc02-11ea-3dbc-b37a5644eab1
using Plots

# ╔═╡ cd9cc940-fc02-11ea-2a40-19bc6f79a6d3
using LaTeXStrings

# ╔═╡ dad114fe-fbfb-11ea-32dd-a302838af30f
md"# Linear Programming: Introduction"

# ╔═╡ fdab0c70-fbfb-11ea-116d-9f1b613f9d0d
md"""## Definition

Formally, a linear program is an optimization problem of the form:

```math
\begin{aligned}
\min \vec{c}^\mathsf{T}\vec x&\\
\textrm{ subject to }&\begin{cases}
\mathbf{A}\vec x=\vec b\\
\vec x\ge\vec 0
\end{cases}
\end{aligned}
```

where $\vec c\in\mathbb R^n$, $\vec b\in\mathbb R^m$ and $\mathbf A \in \mathbb R^{m\times n}$. The vector inequality $\vec x\ge\vec 0$ means that each component of $\vec x$ is nonnegative. Several variations of this problem are possible; eg. instead of minimizing, we can maximize, or the constraints may be in the form of inequalities, such as $\mathbf A\vec x\ge \vec b$ or $\mathbf A\vec x\le\vec b$. We shall see later, these variations can all be rewritten into the standard form."""

# ╔═╡ 0d88a212-fbfc-11ea-37ae-c5e0c6a894e8
md"""## Example

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

# ╔═╡ 67071830-fbfc-11ea-3925-798d3d288500
md"""## Vector Notation

Using vector notation with

```math
\vec x = \begin{pmatrix}
x_1\\x_2\\x_3\\x_4
\end{pmatrix}
```

the problem can be written in the compact form

```math
\max 
\begin{pmatrix}6&4&7&5\end{pmatrix}
\begin{pmatrix}
x_1\\x_2\\x_3\\x_4
\end{pmatrix}\\
\textrm{ subject to }
\begin{cases}
\begin{pmatrix}
1&2&1&2\\
6&5&3&2\\
3&4&9&12
\end{pmatrix}
\begin{pmatrix}
x_1\\x_2\\x_3\\x_4
\end{pmatrix}\le
\begin{pmatrix}
20\\100\\75
\end{pmatrix}\\
\begin{pmatrix}
x_1\\x_2\\x_3\\x_4
\end{pmatrix}\ge
\begin{pmatrix}
0\\0\\0\\0
\end{pmatrix}
\end{cases}
```
 """

# ╔═╡ 3bb281f0-fc02-11ea-34f0-fd00648c27bb
md"""## Two-dimensional Linear Program

Many fundamental concepts of linear programming are easily illustrated in two-dimensional space.

Consider the following linear program:

```math
\begin{aligned}
\max&
\begin{pmatrix}
1&5
\end{pmatrix}
\begin{pmatrix}
x_1\\
x_2
\end{pmatrix}&\\
\textrm{ subject to }
&\begin{cases}
\begin{pmatrix}
5&6\\
3&2
\end{pmatrix}
\begin{pmatrix}
x_1\\
x_2
\end{pmatrix}\le
\begin{pmatrix}
30\\
12
\end{pmatrix}\\
\begin{pmatrix}
x_1\\
x_2
\end{pmatrix}\ge
\begin{pmatrix}
0\\
0
\end{pmatrix}
\end{cases}
\end{aligned}
```
"""

# ╔═╡ e5488250-fc02-11ea-0bc1-4365461fb202
let
	x = -2:6
	plot(x, (30 .- 5 .* x) ./ 6, linestyle=:dash, label=L"5x_1+6x_2=30")
	plot!(x, (12 .- 3 .* x) ./ 2, linestyle=:dash, label=L"3x_1+2x_2=12")
	plot!([0,4,1.5,0,0],[0,0,3.75,5,0], linewidth=2, label="constraints")
	plot!(x, -x ./ 5, label=L"f\left(x_1,x_2\right)=x_1+5x_2=0")
	plot!(x, (25 .- x) ./ 5, label=L"f\left(x_1,x_2\right)=x_1+5x_2=25")
end

# ╔═╡ 08de4fb0-fc03-11ea-08fb-616f792f7c7f
md"""## Slack Variables

Theorems and solution techniques are usually stated for problems in standard form. other forms of linear programs can be converted as the standard form. If a linear program is in the form

```math
\begin{aligned}
\min &\vec{c}^\mathsf{T}\vec x\\
\textrm{ subject to }& \begin{cases}
\mathbf{A}\vec x\ge \vec b\\
\vec x\ge\vec 0
\end{cases}
\end{aligned}
```

then by introducing _surplus variables_, we can convert the orginal problem into the standard form

```math
\begin{aligned}
\min& \vec{c}^\mathsf{T}\vec x\\
\textrm{ subject to }& \begin{cases}
\mathbf{A}\vec x-\mathbf I\vec y = \vec b\\
\vec x\ge\vec 0\\
\vec y\ge\vec 0
\end{cases}
\end{aligned}
```

where $\mathbf I$ is the $m\times m$ identity matrix.

If, on the other hand, the constraints have the form

```math
\begin{cases}
\mathbf{A}\vec x\le b\\
\vec x\ge\vec 0
\end{cases}
```

then we introduce the _slack variables_ to convert the constraints into the form

```math
\begin{cases}
\mathbf{A}\vec x+\mathbf I\vec y = \vec b\\
\vec x\ge\vec 0\\
\vec y\ge\vec 0
\end{cases}
```

Consider the following optimization problem

```math
\begin{aligned}
\max& x_2-x_1\\
\textrm{ subject to }&
\begin{cases}
3x_1=x_2-5\\
\left|x_2\right|\le2\\
x_1\le0
\end{cases}
\end{aligned}
```

To convert the problem into a standard form, we perform the following steps:

1. Change the objective function to:

```math
\min x_1 - x_2
```

2. Substitute $x_1=-x_1^\prime$.

3. Write $\left|x_2\right|\le2$ as $x_2\le 2$ and $-x_2\le 2$.

4. Introduce slack variables $y_1$ and $y_2$, and convert the inequalities above to

```math
\begin{cases}
\hphantom{-}x_2 + y_1 =2\\
-x_2+y_2 =2
\end{cases}
```

5. Write $x_2=u-v$ with $u,v\ge0$.

Hence, we obtain

```math
\begin{aligned}
\min& -x_1^\prime-u+v\\
\textrm{ subject to }&
\begin{cases}
3x_1^\prime+u-v=5\\
u-v+y_1=2\\
v-u+y_2=2\\
x_1^\prime,u,v,y_1,y_2\ge0
\end{cases}
\end{aligned}
```
"""

# ╔═╡ cfd86bf0-fc03-11ea-22ef-b99d3e3fbfce
md"""## Fundamental Theorem of Linear Programming

We consider the system of equalities

```math
\mathbf{A}\vec x=\vec b
```

where $\mathrm{rank}\,\mathbf A=m$.

Let $\mathbf B$ a square matrix whose columns are $m$ linearly independent columns of $\mathbf A$. If necessary, we reorder the columns of $\mathbf A$ so that the columns in $\mathbf B$ appear first: $\mathbf A$ has the form $\left(\mathbf B |\mathbf N\right)$.

The matrix is nonsingular, and thus we can solve the equation

```math
\mathbf B\vec x_\mathbf B = \vec b
```

The solution is $\vec x_\mathbf B = \mathbf B^{-1}\vec b$.

Let $\vec x$ be the vector whose first $m$ components are equal to $\vec x_\mathbf B$ and the remaining components are equal to zero. Then $\vec x$ is a solution to $\mathbf A\vec x=\vec b$. We call $\vec x$  a _basic solution_. Its components refering to the the components of $\vec x_\mathbf B$ are called _basic variables_.

- If some of the basic variables are zero, then the basic solution is _degenerate_.
- A vector $\vec x$ satisfying $\mathbf A\vec x=\vec b$, $\vec x \ge \vec 0$, is said to be a _feasible solution_.
- A feasible solution that is also basic is called a _basic feasible solution_.

The fundamental theorem of linear programming states that when solving a linear programming problem, we need only consider basic feasible solutions. This is because the optimal value (if it exists) is always achieved at a basic solution."""

# ╔═╡ Cell order:
# ╟─dad114fe-fbfb-11ea-32dd-a302838af30f
# ╟─fdab0c70-fbfb-11ea-116d-9f1b613f9d0d
# ╟─0d88a212-fbfc-11ea-37ae-c5e0c6a894e8
# ╟─67071830-fbfc-11ea-3925-798d3d288500
# ╟─3bb281f0-fc02-11ea-34f0-fd00648c27bb
# ╠═bf54eece-fc02-11ea-3dbc-b37a5644eab1
# ╠═cd9cc940-fc02-11ea-2a40-19bc6f79a6d3
# ╠═e5488250-fc02-11ea-0bc1-4365461fb202
# ╟─08de4fb0-fc03-11ea-08fb-616f792f7c7f
# ╟─cfd86bf0-fc03-11ea-22ef-b99d3e3fbfce
