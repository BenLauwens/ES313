### A Pluto.jl notebook ###
# v0.19.14

using Markdown
using InteractiveUtils

# ╔═╡ dc3c2030-144f-11eb-08ab-0b68dc2698ac
begin
	using Pkg
	cd(joinpath(dirname(@__FILE__),".."))
    Pkg.activate(pwd())
	using BenchmarkTools
end

# ╔═╡ 615d2b78-9a47-41bf-bae4-f0f7fb875956
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

# ╔═╡ 1c49d8ae-144e-11eb-024a-137460f78b15
md"""
# Performance
When building more complex programs, performance can be an issue. The [performance tips](https://docs.julialang.org/en/v1/manual/performance-tips/) website already contains a lot tips. We will illustrate potential performance gains for a function by providing one or more alternatives. In order to make sure the the functions produce the same result, the results are verified to be identical before starting the benchmarks.

The actual performance is measured using [BenchmarkTools](https://github.com/JuliaCI/BenchmarkTools.jl). More advanced methods (that we cannot cover due to time constraints) included profiling your code. In Visual Studio Code you can get a detailed overview with the [`@profview`](https://discourse.julialang.org/t/julia-vs-code-extension-version-v0-17-released/42865) macro. For a REPL based method you could use [Traceur](https://github.com/JunoLab/Traceur.jl).

## Tools
Below you can find a set of very generic functions that we will be using to evaluate the functions that we will be benchmarking.

### Notes
At some point we try to make use of multithreading. You can see the number of threads that are currently being used with
```julia
Threads.nthreads()
```

Should this be only 1, you can set the number of threads to use by setting the environment variable `JULIA_NUM_THREADS` to the required before starting julia.

In a windows terminal:
```
$env:JULIA_NUM_THREADS = 4
julia
```
In a Linux/Mac OS terminal:
```
export JULIA_NUM_THREADS=4
julia
```

both examples above suppose "julia" is known in your terminal. If this is not the case, simply replace it by the path to the julia executable.

*Remark*: starting from julia 1.5 you can use command line arguments to specify the number of threads e.g. `julia --threads 4`
"""

# ╔═╡ a4ed00b8-144f-11eb-0c66-932242a1767c
begin
	"""
    testfuns(F, args...; kwargs...)

Benchmark the functions in F using `args` and `kwargs`.
"""
function testfuns(F::Union{Array{Function,1}, Array{Type,1}}, args...; kwargs...)
    # set up benchmark suite
    suite = BenchmarkGroup()
    for f in F
        suite[string(f)] = @benchmarkable $(f)($(args)...; $(kwargs)...)
    end
    # tune and run suite
    tune!(suite)
    results = run(suite, verbose=get(kwargs, :verbose, false))
    # show results
    for f in F
        println("\nResult for $(f):\n$("-"^length("Result for $(f):"))")
        display(results[string(f)])
    end
    medians = sort!([(fun, median(trial.times)) for (fun, trial) in results], by=x->x[2])
    speedup = round(Int,medians[end][2] / medians[1][2])
    println("\n$(speedup)x speedup (fastest: $(medians[1][1]), slowest: $(medians[end][1]))\n")
    return 

end
	nothing
end

# ╔═╡ e32569b0-144f-11eb-33e9-8fd8755c208f
begin
	"""
		equality(F::Array{Function,1}, args...; kwargs...)

	Verify the result of an array of functions F is the same using `args` and `kwargs`.

	### Notes
	The first function in the array is used as the reference
	"""
	function equality(F::Array{Function,1}, args...; kwargs...)
		return all([equality(F[1], F[i], args...; kwargs...) for i in 2:length(F)])
	end

	"""
		equality(f::Function, g::Function, args...; kwargs...)

	Verify the result of function f and g is the same (element-wise) using `args` and `kwargs`.
	"""
	function equality(f::Function, g::Function, args...; kwargs...)
		return all(isequal.(map(f->f(args...; kwargs...), [f, g])...))
	end

	nothing
end

# ╔═╡ ff480c88-144f-11eb-2839-598b8452a945
md"""
## Hands-on
"""

# ╔═╡ 1e0ef46a-1450-11eb-2676-d94d5cc1f073
begin

	"""
		renew(char="", n::Int=0)

	Slow implementation of string joining
	"""
	function renew(char="", n::Int=0; kwargs...)
		res = ""
		for i in 1:n
			res *= char
		end

		return res
	end

	"""
		buffer(char="", n::Int=0)

	Fast implementation of string joining
	"""
	function buffer(char="", n::Int=0; kwargs...)
		res = IOBuffer()
		for i in 1:n
			print(res, char)
		end

		return String(take!(res))
	end

	"""
		demo1

	- Illustration of implementation issues

	speedup ∝ length
	"""
	function demo1()
		F = [renew, buffer]; 
		args=("a", 10000)
		# test validity
		@info "Testing demo 1"
		@assert equality(F, args...)
		# Run benchmark
		@info "Benching demo 1"
		testfuns(F, args...)
	end
	
	demo1()
	
end

# ╔═╡ 41ef249a-1450-11eb-2c52-0930531fa46e
begin
	function f_alloc(x::Vector{T}, y::Array{T,2}; props::Vector{T}, kwargs...) where T
		# read properties
		prop_A = props[1]
		prop_B = props[2] 
		prop_C = props[3]
		prop_D = props[4]
		# initialise
		result = zeros(T, size(x))
		result .+= x
		# update result
		result = result .+ prop_A .* y[:,1]
		result = result .+ prop_B .* y[:,2]
		result = result .+ prop_C .* y[:,3]
		result = result .+ prop_D .* y[:,4]
		return result
	end

	struct Props{T<:AbstractFloat}
		prop_A::T
		prop_B::T
		prop_C::T
		prop_D::T
	end

	@views function f_noalloc(x::Vector{T}, y::Array{T,2}; p::Props, kwargs...) where T
		return x .+ p.prop_A .* y[:,1] .+ p.prop_B .* y[:,2] + p.prop_C .* y[:,3] + p.prop_D .* y[:,4]
	end


	"""
		demo2()

	- Avoiding unnecessary allocations
	- Using views 
	- Avoiding fields with abstract types
	"""
	function demo2()
		F = [f_alloc, f_noalloc]
		N = 10000
		x = rand(N)
		y = rand(N,4)
		args = [x, y]
		props = Float64[1,2,3,4]
		p = Props(props...)
		kwargs = Dict(:props => props, :p => p)
		# test validity
		@info "Testing demo 2"
		@assert equality(F, args...; kwargs...)
		# run benchmark
		@info "Benching demo 2"
		testfuns(F, args...; kwargs...)
	end
	
	demo2()
	
end

# ╔═╡ 6332ef7e-1450-11eb-0a36-41818207b78f
begin
	# avoid changing type of a variable
	function f_typechange(x)
		res = 0
		for val in x
			res += val
		end
		return res
	end

	function f_notypechange(x::Array{T,1}) where T <: Number
		res = zero(T)
		for val in x
			res += val
		end
		return res
	end

	"""
		demo3()

	- avoid changing type of a variable
	"""
	function demo3()
		F = [f_typechange, f_notypechange]
		N = 2
		args = [rand(N)]
		# test validity
		@info "Testing demo 3"
		@assert equality(F, args...)
		# run benchmark
		@info "Benching demo 3"
		testfuns(F, args...)
	end
	
	demo3()
end

# ╔═╡ 75948388-1450-11eb-0a0e-431ad5929504
begin
	f_norm(x) = 3x.^2 + 4x + 7x.^3;
	f_vec(x) = @. 3x.^2 + 4x + 7x.^3;

	"""
		demo 4

	- use vectorisation where possible
	"""
	function demo4()
		F = [f_norm, f_vec]
		N::Int = 1e6
		args = [rand(N)]
		# test validity
		@info "Testing demo 4"
		@assert equality(F, args...)
		# run benchmark
		@info "Benching demo 4"
		testfuns(F, args...)
	end
	
	demo4()
	
end

# ╔═╡ 98e356f4-1450-11eb-0229-eb57f262ea4d
begin
	function f_nopre(x::Vector; kwargs...)
		y = similar(x)
		for i in eachindex(x)
			y[i] = sum(x[1:i])
		end
		return y
	end

	function f_pre!(x::Vector{T}; y::Vector{T}, kwargs...) where {T}
		for i in eachindex(x)
			y[i] = sum(x[1:i])
		end
		return y
	end

	function f_preboost!(x::Vector{T}; y::Vector{T}, kwargs...) where {T}
		Threads.@threads for i in eachindex(x)
			@inbounds y[i] = sum(x[1:i])
		end
		return y
	end

	@views function f_preturboboost!(x::Vector{T}; y::Vector{T}, kwargs...) where {T}
		Threads.@threads for i in eachindex(x)
			@inbounds y[i] = sum(x[1:i])
		end
		return y
	end

	"""
		demo5()

	- preallocate outputs if possible
	- make use of threads if possible
	- make use of views if possible
	- skip index check when sure of dimensions
	"""
	function demo5()
		F = [f_nopre, f_pre!, f_preboost!, f_preturboboost!]
		@info "Currently running on $(Threads.nthreads()) threads"
		N::Int = 1e4
		x::Vector = rand(N)
		y_pre = similar(x)
		args = [x]
		kwargs = Dict( :y => y_pre)
		# test validity
		@info "Testing demo 5"
		@assert equality(F, args...; kwargs...)
		# run benchmark
		@info "Benching demo 5"
		testfuns(F, args...; kwargs...)
	end
	
	demo5()
end

# ╔═╡ b341b4d2-1450-11eb-0549-7db5bd6756ba
begin
	function grow(N::Int; kwargs...)
		res = []
		for _ in 1:N
			push!(res, 1)
		end
		return res
	end

	function nogrow(N::Int; x::Array{T,1}) where{T}
		res = similar(x)
		for i in 1:N
			res[i] = 1
		end
		return res
	end

	"""
		demo6()

	- growing vs. allocating for known dimensions
	"""
	function demo6()
		N = 10000
		x = rand(N)
		F = [grow, nogrow]
		args = [N]
		kwargs = Dict(:x => x)
		# test validity
		@info "Testing demo 6"
		@assert equality(F, args...; kwargs...)
		# run benchmark
		@info "Benching demo 6"
		testfuns(F, args...; kwargs...)
	end
	
	demo6()
end

# ╔═╡ c6702048-1450-11eb-1f1d-a54089545949
begin
	struct mystruct
		a
		b
		c
	end

	struct mytypedstruct{T}
		a::T
		b::T
		c::T
	end

	mutable struct mymutablestruct
		a
		b
		c
	end

	"""
		demo7

	- creation time of mutable vs unmutable structs and the parameter version
	"""
	function demo7()
		structs = [mystruct, mytypedstruct, mymutablestruct]
		@info "Benching demo 7"
		testfuns(structs, [1;2;3]...)
	end
	
	demo7()
	
end

# ╔═╡ df4563da-1450-11eb-08a7-25ed365f578c
begin
	function reader(s::mystruct)
		return (s.a, s.b, s.c)
	end

	function reader(s::mytypedstruct)
		return (s.a, s.b, s.c)
	end

	function reader(sm::mymutablestruct)
		return (sm.a, sm.b, sm.c)
	end

	"""
		demo8

	- read times of fields of mutable vs unmutable structs and the parameter version
	"""
	function demo8()
		vals = [1;2;3]
		@info "Benching demo8"
		for arg in [mystruct, mytypedstruct, mymutablestruct]
			println("\nResult for $(arg):\n$("-"^length("Result for $(arg):"))")
			x = arg(vals...)
			display(@benchmark reader($(x)))
		end
	end
	
	demo8()
end

# ╔═╡ Cell order:
# ╟─615d2b78-9a47-41bf-bae4-f0f7fb875956
# ╟─dc3c2030-144f-11eb-08ab-0b68dc2698ac
# ╟─1c49d8ae-144e-11eb-024a-137460f78b15
# ╠═a4ed00b8-144f-11eb-0c66-932242a1767c
# ╠═e32569b0-144f-11eb-33e9-8fd8755c208f
# ╟─ff480c88-144f-11eb-2839-598b8452a945
# ╠═1e0ef46a-1450-11eb-2676-d94d5cc1f073
# ╠═41ef249a-1450-11eb-2c52-0930531fa46e
# ╠═6332ef7e-1450-11eb-0a36-41818207b78f
# ╠═75948388-1450-11eb-0a0e-431ad5929504
# ╠═98e356f4-1450-11eb-0229-eb57f262ea4d
# ╠═b341b4d2-1450-11eb-0549-7db5bd6756ba
# ╠═c6702048-1450-11eb-1f1d-a54089545949
# ╠═df4563da-1450-11eb-08a7-25ed365f578c
