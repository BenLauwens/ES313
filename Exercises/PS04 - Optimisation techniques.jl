### A Pluto.jl notebook ###
# v0.19.12

using Markdown
using InteractiveUtils

# ╔═╡ f1068fca-0331-11eb-20de-a98c65d5c2dc
begin
	using Pkg
	cd(joinpath(dirname(@__FILE__),".."))
    Pkg.activate(pwd())
	using Optim, Plots
    using Distributions
	using GeneralQP
	using JuMP, Ipopt
	using LaTeXStrings
	using LinearAlgebra
end



# ╔═╡ 543d9901-6bdc-4ca5-bfac-800f543c3490
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

# ╔═╡ b4764948-0330-11eb-3669-974d75ab1134
md"""
# Optimisation techniques
"""

# ╔═╡ 1b769f0c-0332-11eb-1efb-178c1985f3df
md"""
We will be using [`Optim`](https://julianlsolvers.github.io/Optim.jl/stable/) for several applications, both uni- and multivariate optimization.
"""

# ╔═╡ 165f35b0-0332-11eb-12e7-f7939d389e58
md"""
## Optimizing a function without gradient information
### Straightforward example
For a univariation function, you need to provide an upper and lower bound
```Julia
optimize(f, lower, upper)
```
Try to optimize $x^3 - 6x + x^2 +2$
* Compare the result between both methods (`Brent()` vs `GoldenSection()`).
* Intermediate results can be store by using the `store_trace=true` keyword argument. The type of the returned object is `Optim.UnivariateOptimizationResults`. The numerical value of each entry can be read by using `.value`.
* Illustrate the evolution of the estimated optimum.
"""

# ╔═╡ 77d89aa8-07d2-11eb-1bbd-a5c896e3ecfe
begin
	f(x) =  x .^3 - 6 * x + x.^2 + 2
	df(x) = 3 .* x .^2 .- 6 + 2 .* x
	res_brent = optimize(f, 0, 10, Optim.Brent(), store_trace=true)
	res_golden = optimize(f, 0, 10, Optim.GoldenSection(), store_trace=true)
	res_brent.trace
end

# ╔═╡ f27797e5-b83f-4375-ab17-480c09fd7b7f
let
	# generating the illustration
	x = range(0,5, length=100)
	p0 = plot(x, f.(x), label=L"f(x)", legendposition=:topleft, title="function evolution")
	p1 = plot([v.iteration for v in res_brent.trace], [v.value for v in res_brent.trace], label="brent method", marker=:circle)
	plot!([v.iteration for v in res_golden.trace], [v.value for v in res_golden.trace], label="golden section method", marker=:circle, markeralpha=0.5)
	title!("function value")
	p2 = plot([v.iteration for v in res_brent.trace], [v.metadata["minimizer"] for v in res_brent.trace], label="brent method", marker=:circle)
	plot!([v.iteration for v in res_golden.trace], [v.metadata["minimizer"] for v in res_golden.trace], label="golden section method", marker=:circle, markeralpha=0.5)
	title!("minimizer")
	xlabel!(p1,"Iteration")
	plot(p0, p1,p2, layout=(1,3), size=(900, 300))
	
end

# ╔═╡ 7bce2500-0332-11eb-2b63-87dc0d713825


# ╔═╡ e6294d6a-0334-11eb-3829-51ee2b8cadaf
md"""
### Data fitting
Suppose we have a random periodic signal with noise, i.e. $y_i = a \sin(x_i-b) + c + \epsilon_i$ and we wish to determine the values of $a,b$ and $c$ that minimize the difference between the “model” and the measured points.

* Define an error function
* Determine possible values for $a,b$ and $c$
* What is the effect of the initial values? Make an illustration of the error for different starting values.
"""

# ╔═╡ 66be5114-0335-11eb-01a9-c594b92937bf
# data generation (simulated sample)
begin
	# actual values
	a = 3; b = pi/3; c=10; 
	# noise distribution
	e=Normal(0,0.1)
	# function
	F(x;a=a,b=b,c=c) = a*sin.(x .- b) .+ c
	# sample length
	n = 10;
	# domain
	xmin = 0; xmax = 20
	d=Uniform(xmin, xmax)
	# random data points (independent variable)
	x = sort(rand(d, n))
	# dependent variable with noise
	y = F.(x) .+ rand(e,n);
end

# ╔═╡ 15ef34dc-0336-11eb-0de5-b942e8871db8
# illustration
begin
	settings = Dict(:xlabel=>"x",:ylabel=>"y",:title=>"a sin(x - b) + c")
	X = range(xmin, xmax, length=50)
	scatter(x,y, label="sample")
	plot!(X,F.(X), label="ground truth"; settings...)
end

# ╔═╡ e949078a-07d3-11eb-0146-8115e335b2e9
begin
	"""
		errfun(v, x=x, y=y)
	
	where v = [a;b;c ] holds the arguments to minimise F(x;a=a,b=b,c=c). Returns the RMSE for the parameter values
	"""
	function errfun(v, x=x, y=y)
		a,b,c = v
		ŷ = F.(x,a=a;b=b,c=c)
		return sqrt(sum((ŷ .- y ) .^2) / length(y))
	end
	
	res = optimize(errfun, Float64[1;1;1])
	a_opt, b_opt, c_opt = res.minimizer
	plot(X,F.(X), label="ground truth"; settings...)
	plot!(X, F.(X,a=a_opt, b=b_opt, c=c_opt), label="optimised"; settings...)
end

# ╔═╡ 901eed25-2aea-42a4-bd7e-68b919a8766c
res

# ╔═╡ 71d2bf30-0336-11eb-28ed-95518b9204a7
md"""
Compare the estimates:
* â: $(res.minimizer[1]) $$\leftrightarrow$$ a: $(a)
* b̂: $(res.minimizer[2]) $$\leftrightarrow$$ b: $(b)
* ĉ: $(res.minimizer[3]) $$\leftrightarrow$$ c: $(c)

with the original data. What do you observe? can you explain this?
"""

# ╔═╡ add5faba-03b8-11eb-0cc7-15f19eb1e0e2
md"""
## Optimisation with gradient information
Suppose we want to minimize a function ``\mathbb{R}^3 \mapsto \mathbb{R}``:

``\min g(\bar{x}) = x_1 ^2 + 2.5\sin(x_2) - x_1^2x_2^2x_3^2 ``

Compare the results (computation time) using
1. a zero order method (i.e. no gradients used)
2. the function and its gradient (both newton and bfgs method)
3. the function, its gradient and the hessian

You can evaluate the performance using the `@time` macro. For a more detailed and representative analysis, you can use the package [`BenchmarkTools`](https://github.com/JuliaCI/BenchmarkTools.jl) (we will go into detail in the session about performance)
"""

# ╔═╡ 9396ccae-03ba-11eb-27a9-1b88ee4fb45f
begin 
	g(x) = x[1]^2 + 2.5*sin(x[2]) - x[1]^2*x[2]^2*x[3]^2
	initial_x = [-0.6;-1.2; 0.135];
end

# ╔═╡ 94abb7a2-03bb-11eb-1ceb-1dff8aa3cce7
begin
	# gradients
	function dg!(G, x)
		G[1] = 2*x[1] - 2*x[1]*x[2]^2*x[3]^2
		G[2] = 2.5*cos(x[2]) - 2*x[1]^2*x[2]*x[3]^2
		G[3] = -2*x[1]^2*x[2]^2*x[3]
	end

	function h!(H,x)
		H[1,1] = 2 - 2*x[2]^2*x[3]^2 
		H[1,2] = -4*x[1]*x[2]*x[3]^2 
		H[1,3] = -4*x[1]*x[2]^2*x[3]
		H[2,1] = -4*x[1]*x[2]*x[3]^2 
		H[2,2] = -2.5*sin(x[2]) - 2*x[1]^2*x[3]^2
		H[2,3] = -4*x[1]^2*x[2]*x[3]
		H[3,1] = -4*x[1]*x[2]^2*x[3]
		H[3,2] = -4*x[1]^2*x[2]*x[3]
		H[3,3] = -2*x[1]^2*x[2]^2
	end
end

# ╔═╡ 6f552aa6-07d5-11eb-18a5-b32ed233c403
begin
	println("start method comparison")
	for _ in 1:2
		@time optimize(g, initial_x)
		@time optimize(g, dg!, initial_x, Newton())
		@time optimize(g, dg!, initial_x, BFGS())
		@time optimize(g, dg!, h!, initial_x)
	end
	println("finished method comparison")
end

# ╔═╡ 966b88dc-03bc-11eb-15a4-b5492ddf4ede
md"""
## Optimize the optimizer
You could study the influence of the optimization methods and try to optimize them as well (this is sometimes refered to as hyperparameter tuning). 

Try to create a method that minimizes the amount of iterations by modifying the parameter $\eta$ from the `BFGS` method.

**Note:** 
* Look at the documentation for possible values of $\eta$.
* This is merely as a proof of concept and will not come up with a significant improvement for this case.

"""

# ╔═╡ 68263aea-07d0-11eb-24f8-6383a3a1e09d
begin
	function optimme(η)
		res = optimize(g, dg!, initial_x, ConjugateGradient(eta=η))
		return res.iterations
	end
	
	optimize(optimme, 0, 20)
end

# ╔═╡ ec264b44-03c2-11eb-1695-cbf638f8cea9
md"""
## Sequential Quadratic Programming
**Reminder**:  typical problem layout:



```math
\begin{align}
\min_{\vec{x}}\, & f\left(\vec{x}\right)\, \textrm{subject to}\, \begin{cases}
\vec{h}\left(\vec{x}\right)=\vec{0}\, \\
\vec{g}\left(\vec{x}\right)\leq\vec{0}
\end{cases}
\end{align}
```

where  ``f:\mathbb{R}^{n}\rightarrow\mathbb{R}``, ``\vec{h}:\mathbb{R}^{n}\rightarrow\mathbb{R}^{m}``,
``m\leq n, \text{and } \vec{g}:\mathbb{R}^{n}\rightarrow\mathbb{R}^{p}``.


This allows you to deal with non-linear constraints. 

Try to solve the following problem:
```math
\begin{align}
\min_{\bar{x}} f(\bar{x}) = -x_1 - x_2 \\
\text{ST:} \begin{cases}-x_1^2 + x_2 \ge 0\\1- x_1^2 - x_2^2 \ge 0\end{cases}
\end{align}
```

Solve the problem with [JuMP](https://github.com/jump-dev/JuMP.jl) (combined with [Ipopt](https://github.com/jump-dev/Ipopt.jl)).
"""

# ╔═╡ 053bae8a-087d-11eb-2e8c-73c41fb4e005
let 
	model = Model(Ipopt.Optimizer)
	@variable(model, x[1:2])
	@objective(model, Min, -x[1] - x[2])
	@constraint(model, - x[1] ^2 + x[2] >= 0)
	@constraint(model, 1 - x[1] ^2 - x[2] ^2 >= 0)
	optimize!(model)
	println(termination_status(model))
	println("minimum: $(objective_value(model))")
	value.(x)
end

# ╔═╡ b5cf333b-5ffa-45d5-b9c0-00abc4b63196
md"""
## Some applications
### More curve fitting
Consider the following setting:
we want to recover an unknown function ``u(t)`` from noisy datapoints ``b_i``. As we do not know the actual underlying signal, we want to make sure that the resulting function is piecewise smooth.

**Note**
```
A piecewise smooth function is can be broken into distinct pieces and on each piece both the functions and their derivatives, are continuous. A piecewise smooth function may not be continuous everywhere, however only a finite number of discontinuities are allowed.
```
For the underlying signal, we use the following function:
```math
b_p(t) = \begin{cases}1 & 0 \le t < 0.25 \\
				      2 & 0.25 \le t < 0.5\\
					  2 - 100(t-0.5)(0.7-t) & 0.5 \le t < 0.7 \\
					  4 & 0.7 \le t \le 1
\end{cases}
```

Given our unknown vector ``u``, which should be an approximation for ``b_i``, we consider the following loss function which needs to be minimized:
```math
\phi_1 = \frac{h}{2}\sum_{i=1}^{N}\frac{1}{2}\left[ (u_i - b_i)^2 + (u_{i-1} - b_{i-1})^2 \right]+ \frac{\beta h}{2}\sum_{i=1}^{N}\left( \frac{u_i - u_{i-1}}{h}\right) ^2
```

Find the optimal fit using `Optim.jl`. Use ``h=\{0.0125; 0.008\}``. Given the following pairs of values for ``(β, noise) = \{(1\text{e-3}; 0.01); (1\text{e-3}; 0.1); (1\text{e-4}; 0.01); (1\text{e-3}; 0.1) \}``. What do you observe and what is the best approximation?

"""

# ╔═╡ c53141dc-37ef-4295-a94d-7eee43177e5b
begin
	"""
		bₚ(t::K)	

	piecewise continuous function that is used a a reference
	"""
	function bₚ(t::K) where K <: Real
		if 0 ≤ t < 0.25
			return 1.
		elseif 0.25 ≤ t < 0.5
			return 2.
		elseif 0.5 ≤ t < 0.7
			return 2 - 100*(t-0.5)*(0.7-t)
		elseif 0.7 ≤ t ≤ 1
			return 4.
		else
			return 0.
		end
	end

	"""
		gensample(t, noise)

	add noise to the value of bₚ
	"""
	gensample(t, noise) = bₚ(t) + rand(Normal()) * noise

	"""
		ϕ₁(u, b, h, β)

	Loss function used to quantify the quality of the proposed fit `u` given the observed value `b` sampled at a step size `h`. The parameter β is used for tuning the regularization term which penalizes excessive roughness in `u`
	"""
	function ϕ₁(u, b, h, β)
		return h/2 * sum(0.5 .* ((u[2:end] - b[2:end]).^2 + (u[1:end-1] - b[1:end-1]).^2)) + β*h/2 * sum( ((u[2:end] - u[1:end-1]) ./ h).^2 )
	end

end

# ╔═╡ 841fcd56-1fee-495c-ae4e-47a3ad36b953
let
	# prentje
	h= 0.0125
	β = 1e-3
	t = range(0, 1, step=h)
	s = gensample.(t, 0.01)
	plot(t, bₚ.(t), label="ground thruth")
	scatter!(t, s, label="sample", legendposition=:topleft)

	# poging tot optimalisatie
	res = optimize(u -> ϕ₁(u, s, h, β), s)
	res.minimizer
	plot!(t, res.minimizer, marker=:circle, label="fit")
end

# ╔═╡ 2a1e165c-b26a-4962-b243-184d83fa00da
let
	p = plot(range(0, 1, step=0.01), bₚ.(range(0, 1, step=0.01)), "real")
	# conept solution
	for h in [0.0125; 0.008]
		for (β, noise) in [(1e-3, 0.01); (1e-3, 0.1); (1e-4, 0.01); (1e-4, 0.1)]
			t = range(0, 1, step=h)
			s = gensample.(t, noise)
			fit = optimize(u -> ϕ₁(u, s, h, β), s).minimizer
			plot!(t, fit, label="fit (β = $(β), noise = $(noise))")

		end
	end
	p
end

# ╔═╡ eac72e64-8584-4588-8b0e-03ddb04956f8
md"""
From the previous results, you might not be satisfied, so we propose an additional loss function ϕ₂, this time using anouter regularization term. Repeat the exercise, but using ϵ=1e-6, 
``(γ, noise) = \{(1\text{e-2}; 0.01); (1\text{e-2}; 0.1); (1\text{e-3}; 0.01); (1\text{e-3}; 0.1) \}``. What do you observe and what is the best approximation?
"""

# ╔═╡ 128d37f1-f4b0-44f8-8a47-5c75e0c44875
	"""
		ϕ₂(u, b, h, γ, ϵ)

	Loss function used to quantify the quality of the proposed fit `u` given the observed value `b` sampled at a step size `h`. The parameters γ and ϵ are used for tuning the regularization term which penalizes excessive roughness in `u`
	"""
	function ϕ₂(u, b, h, γ, ϵ)
		return h/2 * sum(0.5 .* ((u[2:end] - b[2:end]).^2 + (u[1:end-1] - b[1:end-1]).^2)) + γ*h * sum( sqrt.(((u[2:end] - u[1:end-1]) ./ h).^2 .+ ϵ))
	end

# ╔═╡ 8da27e06-3798-423d-b882-b8c98eb36f6a
begin
	# signal generation
	h = 0.0125
	β = 1e-3
	noise = 0.1
	T = range(0,1, step=h)
	B = bₚ.(T) + rand(Normal(),length(T)) * mean(bₚ.(T)) * noise
end

# ╔═╡ 6ea718f8-7e52-4402-b5eb-7fca1310d796


# ╔═╡ 8e3a7568-ae6c-459d-9d95-4f80ca79accf
md"""
Can you optimize the loss function, i.e. determine those values of β or (γ, ϵ) that generate the best result? Note: you might want to think on how to deal with the stochastic aspect of the problem.
"""

# ╔═╡ 580b7d3b-78c3-4eee-889a-884fc732515a
md"""
### Constrained flower function optimisation
Consider the two-dimensional flower function
```math
f(x) = a ||x|| + b \sin \left(c \tan ^{-1}\left( x_2, x_1  \right) \right)
```
where ``a=1,b=1,c=4``.
"""

# ╔═╡ 117d36ab-a6ba-40e0-b5fc-c0209acbfbfd
"""
	flower(x; a=1, b=1, c=4)

flower function
"""
function flower(x::Vector{T}; a=1, b=1, c=4) where T<:Real
	return a*norm(x) + b*sin(c*atan(x[2], x[1]))
end

# ╔═╡ ffa3233d-a17c-4600-8fa1-8001e07fe600
md"""
1. minimise the flower function.
2. minimise the flower function with the additional constraint ``x_1^2 + x_2^2 \ge 2``

Make an illustration for different starting values.

How could you allow (limited) disrespect of the constraints?
"""

# ╔═╡ f7478cd0-7558-4c71-8933-2003863eb1bd
let
	# some illustrations
	x = range(-3, 3, length=100)
	y = range(-3, 3, length=100)
	contour(x,y, (x,y) -> flower([x;y]), label="flower")
	title!("Flower function contour plot")
	xlabel!("x")
	ylabel!("y")
end

# ╔═╡ d39b62d0-3f89-45d7-9ddc-4f9a106611d6


# ╔═╡ Cell order:
# ╟─543d9901-6bdc-4ca5-bfac-800f543c3490
# ╟─b4764948-0330-11eb-3669-974d75ab1134
# ╟─1b769f0c-0332-11eb-1efb-178c1985f3df
# ╠═f1068fca-0331-11eb-20de-a98c65d5c2dc
# ╟─165f35b0-0332-11eb-12e7-f7939d389e58
# ╠═77d89aa8-07d2-11eb-1bbd-a5c896e3ecfe
# ╠═f27797e5-b83f-4375-ab17-480c09fd7b7f
# ╟─7bce2500-0332-11eb-2b63-87dc0d713825
# ╟─e6294d6a-0334-11eb-3829-51ee2b8cadaf
# ╠═66be5114-0335-11eb-01a9-c594b92937bf
# ╠═15ef34dc-0336-11eb-0de5-b942e8871db8
# ╠═e949078a-07d3-11eb-0146-8115e335b2e9
# ╠═901eed25-2aea-42a4-bd7e-68b919a8766c
# ╟─71d2bf30-0336-11eb-28ed-95518b9204a7
# ╟─add5faba-03b8-11eb-0cc7-15f19eb1e0e2
# ╠═9396ccae-03ba-11eb-27a9-1b88ee4fb45f
# ╠═94abb7a2-03bb-11eb-1ceb-1dff8aa3cce7
# ╠═6f552aa6-07d5-11eb-18a5-b32ed233c403
# ╟─966b88dc-03bc-11eb-15a4-b5492ddf4ede
# ╠═68263aea-07d0-11eb-24f8-6383a3a1e09d
# ╟─ec264b44-03c2-11eb-1695-cbf638f8cea9
# ╠═053bae8a-087d-11eb-2e8c-73c41fb4e005
# ╟─b5cf333b-5ffa-45d5-b9c0-00abc4b63196
# ╠═c53141dc-37ef-4295-a94d-7eee43177e5b
# ╠═841fcd56-1fee-495c-ae4e-47a3ad36b953
# ╠═2a1e165c-b26a-4962-b243-184d83fa00da
# ╟─eac72e64-8584-4588-8b0e-03ddb04956f8
# ╠═128d37f1-f4b0-44f8-8a47-5c75e0c44875
# ╠═8da27e06-3798-423d-b882-b8c98eb36f6a
# ╠═6ea718f8-7e52-4402-b5eb-7fca1310d796
# ╟─8e3a7568-ae6c-459d-9d95-4f80ca79accf
# ╟─580b7d3b-78c3-4eee-889a-884fc732515a
# ╠═117d36ab-a6ba-40e0-b5fc-c0209acbfbfd
# ╟─ffa3233d-a17c-4600-8fa1-8001e07fe600
# ╠═f7478cd0-7558-4c71-8933-2003863eb1bd
# ╠═d39b62d0-3f89-45d7-9ddc-4f9a106611d6
