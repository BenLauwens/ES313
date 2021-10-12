### A Pluto.jl notebook ###
# v0.16.1

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
end



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
	res_brent = optimize(f, 0, 10, Optim.Brent(), store_trace=true)
	res_golden = optimize(f, 0, 10, Optim.GoldenSection(), store_trace=true)
	res_brent.trace
end

# ╔═╡ f27797e5-b83f-4375-ab17-480c09fd7b7f
let
	# generating the illustration
	p1 = plot([v.iteration for v in res_brent.trace], [v.value for v in res_brent.trace], label="brent method", marker=:circle)
	plot!([v.iteration for v in res_golden.trace], [v.value for v in res_golden.trace], label="golden section method", marker=:circle, markeralpha=0.5)
	title!("function value")
	p2 = plot([v.iteration for v in res_brent.trace], [v.metadata["minimizer"] for v in res_brent.trace], label="brent method", marker=:circle)
	plot!([v.iteration for v in res_golden.trace], [v.metadata["minimizer"] for v in res_golden.trace], label="golden section method", marker=:circle, markeralpha=0.5)
	title!("minimizer")
	
	plot(p1,p2)
	xlabel!("Iterations")
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
	
	où v = [a;b;c ] pour minimiser F(x;a=a,b=b,c=c)
	"""
	function errfun(v, x=x, y=y)
		a,b,c = v
		return sum((F.(x,a=a;b=b,c=c) .- y ) .^2)
	end
	
	res = optimize(errfun, Float64[1;1;1])
	a_opt, b_opt, c_opt = res.minimizer
	plot(X,F.(X), label="ground truth"; settings...)
	plot!(X, F.(X,a=a_opt, b=b_opt, c=c_opt), label="optimised"; settings...)
end

# ╔═╡ 901eed25-2aea-42a4-bd7e-68b919a8766c
res

# ╔═╡ 71d2bf30-0336-11eb-28ed-95518b9204a7


# ╔═╡ d0a304f2-0336-11eb-0d20-6de833d964b3


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
		res = optimize(g, dg!, initial_x,ConjugateGradient(eta=η))
		return res.iterations
	end
	
	optimize(optimme, 0, 20)
end

# ╔═╡ d5feb956-058b-11eb-1a7d-eb56768f00b1


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


1. Solve the problem with [NLopt](https://github.com/JuliaOpt/NLopt.jl) (placed in a seperate notebook)
2. Solve the problem with [JuMP](https://github.com/jump-dev/JuMP.jl) (combined with [Ipopt](https://github.com/jump-dev/Ipopt.jl))
"""

# ╔═╡ 02aedfec-d075-425b-8db6-e60d5d8a79c3
model

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


# ╔═╡ Cell order:
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
# ╟─d0a304f2-0336-11eb-0d20-6de833d964b3
# ╟─add5faba-03b8-11eb-0cc7-15f19eb1e0e2
# ╠═9396ccae-03ba-11eb-27a9-1b88ee4fb45f
# ╠═94abb7a2-03bb-11eb-1ceb-1dff8aa3cce7
# ╠═6f552aa6-07d5-11eb-18a5-b32ed233c403
# ╟─966b88dc-03bc-11eb-15a4-b5492ddf4ede
# ╠═68263aea-07d0-11eb-24f8-6383a3a1e09d
# ╠═d5feb956-058b-11eb-1a7d-eb56768f00b1
# ╟─ec264b44-03c2-11eb-1695-cbf638f8cea9
# ╠═02aedfec-d075-425b-8db6-e60d5d8a79c3
# ╠═053bae8a-087d-11eb-2e8c-73c41fb4e005
# ╠═b5cf333b-5ffa-45d5-b9c0-00abc4b63196
