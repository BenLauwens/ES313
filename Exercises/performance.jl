using BenchmarkTools

# generic tools for evaluation
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

# avoid globals (general rule unless constants, in that case define them as such)


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



function main(N::Int=8)
    for i in 1:N
        eval(Symbol("demo$(i)"))()
    end
end

#main(8)
#res = demo7()

main()
