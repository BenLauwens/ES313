mutable struct Data{T}
    """
    Data structure for the solution of
        min         ½x'Px + q'x
        subject to  Ax ≤ b
    with an active set algorithm.

    The most important element is F, which holds
    - F.QR:      an updatable QR factorization of the working constraints
    - F.Z:       a view on an orthonormal matrix spanning the nullspace of the working constraints
    - F.P:       the hessian of the problem
    - F.U & F.D: the ldl factorization of the projected hessian, i.e. F.U'*F.D*F.D = F.Z'*F.P*F.Z

    The Data structure also keeps matrices of the constraints not in the working set (A_ignored and b_ignored)
    stored in a continuous manner. This is done to increase use of BLAS.
    """
    x::Vector{T}

    n::Int
    m::Int

    F::NullspaceHessianLDL{T}
    q::Vector{T}
    A::Matrix{T}
    b::Vector{T}
    working_set::Vector{Int}
    ignored_set::Vector{Int}
    λ::Vector{T}
    residual::T

    iteration::Int
    done::Bool

    e::Vector{T} # Just an auxiliary vector used in computing step directions

    A_ignored::SubArray{T, 2, Matrix{T}, Tuple{UnitRange{Int}, Base.Slice{Base.OneTo{Int}}}, false}
    b_ignored::SubArray{T, 1, Vector{T}, Tuple{UnitRange{Int}}, true}
    A_shuffled::Matrix{T}
    b_shuffled::Vector{T}

    verbosity::Int
    printing_interval::Int
    r_min::T
    r_max::T

    function Data(P::Matrix{T}, q::Vector{T}, A::Matrix{T}, b::Vector{T},
        x::Vector{T}; r_min::T=zero(T), r_max::T=Inf, verbosity=1, printing_interval=50) where T
        if r_min < 1e-9; r_min = -one(T); end

        m, n = size(A)
        working_set = zeros(Int, 0)
        @assert(maximum(A*x - b) < 1e-9, "The initial point is infeasible!")
        @assert(norm(x) - r_min > -1e-9, "The initial point is infeasible!")
        @assert(norm(x) - r_max < 1e-9, "The initial point is infeasible!")

        ignored_set = setdiff(1:m, working_set)

        F = NullspaceHessianLDL(P, Matrix(view(A, working_set, :)'))
        if F.m == 0 # To many artificial constraints...
            remove_constraint!(F, 0)
        end
        A_shuffled = zeros(T, m, n)
        l = length(ignored_set)
        A_shuffled[end-l+1:end, :] .= view(A, ignored_set, :)
        b_shuffled = zeros(T, m)
        b_shuffled[end-l+1:end] .= view(b, ignored_set)

        e = zeros(T, n);
        λ = zeros(T, m);

        new{T}(x, n, m, F, q, A, b, working_set, ignored_set, λ,
            NaN, 0, false, e,
            view(A_shuffled, m-l+1:m, :),
            view(b_shuffled, m-l+1:m),
            A_shuffled, b_shuffled,
            verbosity, printing_interval,
            r_min, r_max)
    end
end

function solve(P::Matrix{T}, q::Vector{T}, A::Matrix{T}, b::Vector{T},
    x::Vector{T}; max_iter::Int=5000, kwargs...) where T

    data = Data(P, q, A, b, x; kwargs...)

    if data.verbosity > 0
        print_header(data)
        print_info(data)
    end

    while !data.done && data.iteration <= max_iter && norm(data.x) <= data.r_max - 1e-10 && norm(data.x) >= data.r_min + 1e-10
        iterate!(data)

        if data.verbosity > 0
            mod(data.iteration, 10*data.printing_interval) == 0 && print_header(data)
            mod(data.iteration, data.printing_interval) == 0 && print_info(data)
        end
    end
    data.verbosity > 0 && print_info(data)

    return x
end

function iterate!(data::Data{T}) where{T}
    direction, stepsize, new_constraints = calculate_step(data)
    data.x .+= stepsize*direction

    if !isempty(new_constraints)
        add_constraint!(data, new_constraints[1])
    end
    #ToDo: break next condition into simpler ones or a more representative flag
    if (isempty(new_constraints) || data.F.m == 0) && norm(data.x) <= data.r_max - 1e-10
        if data.F.artificial_constraints > 0
            remove_constraint!(data.F, 0)
        else
            idx = check_kkt!(data)
            !data.done && remove_constraint!(data, idx)
        end
    end
    data.iteration += 1
end

function calculate_step(data)
    gradient = data.F.P*data.x + data.q
    if data.F.D[end] >= data.F.indefinite_tolerance
        qw = data.F.Z'*(gradient)
        if norm(qw) <= 1e-10 # We are alread on the optimizer of the current subproblem
            return zeros(data.n), 0, []
        end
        # Gill & Murray (1978) calculate the direction/stepsize as:
        # direction = data.F.Z*reverse(data.F.U\e)
        # direction .*= -sign(dot(direction, gradient))
        # α_min = -dot(gradient, direction)/data.F.D[end]
        # This assumes that we start from a feasible vertex or a feasible stationary point.
        # This assumption is suitable e.g. when we use a Phase I algorithm to find a feasible point
        # and it allows for a faster/simpler calculation of the direction.
        # Nevertheless, for purposes of generality, we calculate the direction in a more general way.
        direction = -data.F.Z*reverse(data.F.U\(data.F.D\(data.F.U'\reverse(qw))))
        α_min = 1
    else
        e = view(data.e, 1:data.F.m); e[end] = 1
        #=
        if norm(data.F.U[:, end]) <= 1e-11
            data.F.U[end] = 1e-11
        end
        =#
        direction = data.F.Z*reverse(data.F.U\e)
        if dot(direction, gradient) >= 0
            direction .= -direction
        end
        e .= 0
        α_min = Inf
    end

    Α_times_direction = data.A_ignored*direction
    ratios = abs.(data.b_ignored - data.A_ignored*data.x)./(Α_times_direction)
    ratios[Α_times_direction .<= 1e-11] .= Inf

    α_constraint = minimum(ratios)
    idx = findlast(ratios .== α_constraint)
    # @show α_constraint, data.ignored_set[idx]

    α = min(α_min, α_constraint) 
    if α == Inf 
        # variable "direction" holds the unbounded ray
        @info "GeneralQP.jl has detected the problem to be unbounded (unbounded ray found)."
    end

    α_max = Inf
    if isfinite(data.r_max)
        # Calculate the maximum allowable step α_max so that r_min ≤ norm(x) ≤ r_max
        roots_rmax = roots(Poly([norm(data.x)^2 - data.r_max^2, 2*dot(direction, data.x), norm(direction)^2]))
        if data.r_min > 0
            roots_rmin = roots(Poly([norm(data.x)^2 - data.r_min^2, 2*dot(direction, data.x), norm(direction)^2]))
            roots_all = [roots_rmin; roots_rmax]
        else
            roots_all = roots_rmax
        end
        # Discard complex and negative steps
        roots_all = real.(roots_all[isreal.(roots_all)])
        roots_all = roots_all[roots_all .>= 0]
        if length(roots_all) > 0
            α_max = minimum(roots_all)
        end
    end
    stepsize = min(α, α_max)
    @assert(isfinite(stepsize), "Set the keyword argument r_max to a finite value if you want to get bounded solutions.")
    if α_constraint == stepsize
        new_constraints = [idx]
    else
        new_constraints = []
    end

    return direction, stepsize, new_constraints
end

function check_kkt!(data)
    grad = data.F.P*data.x + data.q
    λ = -data.F.QR.R1\data.F.QR.Q1'*grad
    data.λ .= 0.0
    data.λ[data.working_set] .= λ
    data.residual = norm(data.F.Z'*grad)
    # data.residual = norm(grad + data.A[data.working_set, :]'*λ)

    idx = NaN
    if all(λ .>= -1e-8)
        data.done = true
    else
        data.done = false
        idx = argmin(λ)
    end

    return idx
end