### A Pluto.jl notebook ###
# v0.11.14

using Markdown
using InteractiveUtils

# ╔═╡ 1c7e914c-03c9-11eb-11cf-0d9346305a53
using NLopt

# ╔═╡ 1866ec44-03c9-11eb-0a21-416587e4e0e0
# Solve the problem with NLopt
let
	
	"""
	Function to be minimized (with its gradient)
	"""
	function myfun(x::Vector, grad::Vector)
		if length(grad) > 0
			grad[1] = -1
			grad[2] = -1
		end
		return -x[1] - x[2]
	end

	"""
	Constraints in form c_i(x)  <= 0 (with gradient)
	"""
	function c1(x::Vector, grad::Vector)
		if length(grad) > 0
			grad[1] = 2*x[1]
			grad[2] = -1
		end
		x[1]^2 - x[2]
	end

	function c2(x::Vector, grad::Vector)
		if length(grad) > 0
			grad[1] = 2*x[1]
			grad[2] = 2*x[2]
		end
		x[1]^2 + x[2]^2 - 1
	end
	
	# optimisation setup
	opt = Opt(:LD_SLSQP, 2)
	opt.lower_bounds = [-Inf, 0.] # only x_2 > 0
	opt.xtol_rel = 1e-4
	opt.min_objective = myfun
	inequality_constraint!(opt, c1, 1e-8)
	inequality_constraint!(opt, c2, 1e-8)

	# solving it.
	(minf,minx,ret) = NLopt.optimize(opt, [0, 0])
	numevals = opt.numevals # the number of function evaluations
	println("got $minf at $minx after $numevals iterations (returned $ret)")
end

# ╔═╡ 2121e5be-03c9-11eb-2b8b-a10cb146216d


# ╔═╡ Cell order:
# ╠═1c7e914c-03c9-11eb-11cf-0d9346305a53
# ╠═1866ec44-03c9-11eb-0a21-416587e4e0e0
# ╠═2121e5be-03c9-11eb-2b8b-a10cb146216d
