mutable struct UpdatableQR{T} <: Factorization{T}
    """
    Gives the qr factorization an (n, m) matrix as Q1*R1
    Q2 is such that Q := [Q1 Q2] is orthogonal and R is an (n, n) matrix where R1 "views into".
    """
    Q::Matrix{T}
    R::Matrix{T}
    n::Int
    m::Int

    Q1::SubArray{T, 2, Matrix{T}, Tuple{Base.Slice{Base.OneTo{Int}}, UnitRange{Int}}, true}
    Q2::SubArray{T, 2, Matrix{T}, Tuple{Base.Slice{Base.OneTo{Int}}, UnitRange{Int}}, true}
    R1::UpperTriangular{T, SubArray{T, 2, Matrix{T}, Tuple{UnitRange{Int},UnitRange{Int}}, false}}

    function UpdatableQR(A::AbstractMatrix{T}) where {T}
        n, m = size(A)
        @assert(m <= n, "Too many columns in the matrix.")

        F = qr(A)
        Q = F.Q*Matrix(I, n, n)
        R = zeros(T, n, n)
        R[1:m, 1:m] .= F.R

        new{T}(Q, R, n, m,
            view(Q, :, 1:m), view(Q, :, m+1:n),
            UpperTriangular(view(R, 1:m, 1:m)))
    end
end

function add_column!(F::UpdatableQR{T}, a::AbstractVector{T}) where {T}
    a1 = F.Q1'*a;
    a2 = F.Q2'*a;

    x = copy(a2)
    for i = length(x):-1:2
        G, r = givens(x[i-1], x[i], i-1, i)
        lmul!(G, x)
        lmul!(G, F.Q2')
    end

    F.R[1:F.m, F.m+1] .= a1
    F.R[F.m+1, F.m+1] = x[1]

    F.m += 1; update_views!(F)

    return a2
end

function add_column_householder!(F::UpdatableQR{T}, a::AbstractVector{T}) where {T}
    a1 = F.Q1'*a;
    a2 = F.Q2'*a;

    Z = qr(a2)
    LAPACK.gemqrt!('R','N', Z.factors, Z.T, F.Q2) # Q2 .= Q2*F.Q
    F.R[1:F.m, F.m+1] .= a1
    F.R[F.m+1, F.m+1] = Z.factors[1, 1]
    F.m += 1; update_views!(F)

    return Z
end

function remove_column!(F::UpdatableQR{T}, idx::Int) where {T}
    Q12 = view(F.Q, :, idx:F.m)
    R12 = view(F.R, idx:F.m, idx+1:F.m)

    for i in 1:size(R12, 1)-1
        G, r = givens(R12[i, i], R12[i + 1, i], i, i+1)
        lmul!(G, R12)
        rmul!(Q12, G')
    end

    for i in 1:F.m, j in idx:F.m-1
        F.R[i, j] = F.R[i, j+1]
    end
    F.R[:, F.m] .= zero(T)

    F.m -= 1; update_views!(F)

    return nothing 
end

function update_views!(F::UpdatableQR{T}) where {T}
    F.R1 = UpperTriangular(view(F.R, 1:F.m, 1:F.m))
    F.Q1 = view(F.Q, :, 1:F.m)
    F.Q2 = view(F.Q, :, F.m+1:F.n)
end

mutable struct NullspaceHessianLDL{T}
    # Struct for the LDL factorization of the reduced Hessian
    # on the nullspace Z of the working constraints
    # U'*D*U = Z[:, end:-1:1]'*P*Z[:, end:-1:1]
    # The projected hessian can include at most one negative eigenvector

    n::Int # Dimension of the original space
    m::Int # Dimension of the nullspace
    artificial_constraints::Int

    P::Matrix{T}     # The full hessian
    # Z is the nullspace, i.e. QR.Q2 where QR is defined below
    Z::SubArray{T, 2, Matrix{T}, Tuple{Base.Slice{Base.OneTo{Int}}, UnitRange{Int}}, true}
    U::UpperTriangular{T, SubArray{T, 2, Matrix{T}, Tuple{UnitRange{Int},UnitRange{Int}}, false}}
    D::Diagonal{T, SubArray{T, 1, Vector{T}, Tuple{UnitRange{Int}}, true}}
    QR::UpdatableQR{T}
    data::Matrix{T}  # That's where U is viewing into
    d::Vector{T}     # That's where D.diag views into
    indefinite_tolerance::T

    function NullspaceHessianLDL(P::Matrix{T}, A::AbstractMatrix{T}) where {T}
        @assert(size(A, 1) == size(P, 1) == size(P, 2), "Matrix dimensions do not match.")

        F = UpdatableQR(A)
        n = F.n
        m = F.n - F.m

        data = zeros(T, n, n)
        F.Q2 .= F.Q2[:, m:-1:1]
        WPW = F.Q2'*P*F.Q2; WPW .= (WPW .+ WPW')./2
        indefinite_tolerance = 1e-12

        C = cholesky(WPW, Val(true); check=false)
        if all(diag(C.U) .> indefinite_tolerance)
            F.Q2 .= F.Q2[:, C.p]
            artificial_constraints = 0
        else
            idx = findfirst(diag(C.U) .<= indefinite_tolerance)
            F.Q2 .= [F.Q2[:, C.p[idx:end]] F.Q2[:, C.p[1:idx-1]]]
            artificial_constraints = m + 1 - idx 
        end
        m -= artificial_constraints
        U = view(data, 1:m, 1:m) 
        
        F.Q2[:, artificial_constraints+1:end].= F.Q2[:, end:-1:artificial_constraints+1]
        Z = view(F.Q2, :, artificial_constraints+1:size(F.Q2, 2))
        U .= view(C.U, 1:m, 1:m)
        d = ones(T, n)
        D = Diagonal(view(d, 1:m))

        new{T}(n, m, artificial_constraints, P, Z, UpperTriangular(U), D, F, data, d, indefinite_tolerance)
    end

end

function add_constraint!(F::NullspaceHessianLDL{T}, a::AbstractVector{T}) where {T}
    a2 = add_column!(F.QR, a)
    if F.m == 1 # Nothing to write
        F.m -= 1; update_views!(F)
        return nothing
    end
    
    l = length(a2)
    for i = l:-1:2
        if l-i+2 <= F.m
            G, _ = givens(a2[i-1], a2[i], l-i+1, l-i+2)
            rmul!(F.U.data, G)
        end
        G, _ = givens(a2[i-1], a2[i], i-1, i)
        lmul!(G, a2)
    end
    F.m -= 1; update_views!(F)
    lmul!(sqrt.(F.D), F.U.data)
    hessenberg_to_triangular!(F.U.data)

    z = view(F.Z, :, 1)
    Pz = F.P*z
    if F.d[F.m + 1] <= -10
        # Recompute the last column of U
        l = reverse!(F.Z'*Pz)
        F.U[:, end] = F.U'\l
    end
    # Correct last element of U
    u1 = view(F.U, 1:F.m-1, F.m)
    d_new = dot(z, F.P*z) - dot(u1, u1)
    # Prevent F.U having zero columns
    F.U[end] = max(sqrt(abs(d_new)), F.indefinite_tolerance)

    # Scale matrices so that diag(F.U) = ones(..) 
    F.D.diag .= one(T) 
    F.D.diag[end] *= sign(d_new)

    return nothing
end

function remove_constraint!(F::NullspaceHessianLDL{T}, idx::Int) where{T}
    @assert(F.m == 0 || F.D[end] > F.indefinite_tolerance,
        "Constraints can be removed only when the reduced Hessian was already Positive Semidefinite.")

    if F.artificial_constraints == 0
        remove_column!(F.QR, idx)
    else
        idx != 0 && @warn("Ignoring non-zero index: Removing an artificial constraint.")
        F.artificial_constraints -= 1
    end

    z = view(F.QR.Q2, :, F.artificial_constraints + 1)
    Pz = F.P*z
    u = F.D\(F.U'\reverse!(F.Z'*Pz))
    d_new = dot(z, Pz) - dot(u, F.D*u)

    F.m += 1; update_views!(F)

    F.U[1:end-1, end] .= u
    F.U[end, end] = one(T)
    F.D[end] = d_new

    return nothing
end

function update_views!(F::NullspaceHessianLDL{T}) where {T}
    if size(F.U, 1) > F.m
        F.U.data[F.m+1, :] .= zero(T)
        F.U.data[:, F.m+1] .= zero(T)
    end
    F.U = UpperTriangular(view(F.data, 1:F.m, 1:F.m))
    F.D = Diagonal(view(F.d, 1:F.m))
    F.Z = view(F.QR.Q2, :, F.artificial_constraints+1:size(F.QR.Q2, 2))
end

function hessenberg_to_triangular!(A::AbstractMatrix{T}) where {T}
    n = size(A, 1)
    for i in 1:n-1
        G, _ = givens(A[i, i], A[i + 1, i], i, i+1)
        lmul!(G, A)
    end
    return A
end

mutable struct NullspaceHessian{T}
    n::Int # Dimension of the original space
    m::Int # Dimension of the nullspace

    P::Matrix{T}     # The full hessian
    # Z is the nullspace, i.e. QR.Q2 where QR is defined below
    Z::SubArray{T, 2, Matrix{T}, Tuple{Base.Slice{Base.OneTo{Int}}, UnitRange{Int}}, true}
    ZPZ::SubArray{T, 2, Matrix{T}, Tuple{UnitRange{Int},UnitRange{Int}}, false}  # equal to Z'*P*Z
    QR::UpdatableQR{T}
    data::Matrix{T}  # That's where ZPZ is viewing into

    function NullspaceHessian{T}(P::Matrix{T}, A::Matrix{T}) where {T}
        @assert(size(A, 1) == size(P, 1) == size(P, 2), "Matrix dimensions do not match.")

        F = UpdatableQR(A)
        n = F.n
        m = F.n - F.m

        data = zeros(T, n, n)
        ZPZ = view(data, n-m+1:n, n-m+1:n) 
        ZPZ .= F.Q2'*P*F.Q2; ZPZ .= (ZPZ .+ ZPZ')./2

        new{T}(n, m, P, F.Q2, ZPZ, F, data)
    end

    function NullspaceHessian{T}(P::Matrix{T}, F::UpdatableQR{T}) where {T}
        n = F.n
        m = F.n - F.m
        @assert(n == size(P, 1) == size(P,2), "Dimensions do not match.")

        data = zeros(T, n, n)
        ZPZ = view(data, n-m+1:n, n-m+1:n) 
        ZPZ .= F.Q2'*P*F.Q2; ZPZ .= (ZPZ .+ ZPZ')./2

        new{T}(n, m, P, F.Q2, ZPZ, F, data)
    end
end

function add_constraint!(H::NullspaceHessian{T}, a::Vector{T}) where {T}
    Z = add_column_householder!(H.QR, a)

    LAPACK.gemqrt!('L','T',Z.factors,Z.T,H.ZPZ)
    LAPACK.gemqrt!('R','N',Z.factors,Z.T,H.ZPZ)
    # ToDo: Force symmetry? (i.e. H.ZPZ .= (H.ZPZ .+ H.ZPZ')./2)
    H.m -= 1; update_views!(H)
    # H.ZPZ .= (H.ZPZ .+ H.ZPZ')./2

    return nothing
end

function remove_constraint!(H::NullspaceHessian{T}, idx::Int) where{T}
    remove_column!(H.QR, idx)
    H.m += 1; update_views!(H)

    Pz = H.P*view(H.Z, :, 1)  # ToDo: avoid memory allocation
    mul!(view(H.ZPZ, 1, :), H.Z', Pz)
    for i = 2:H.m
        H.ZPZ[i, 1] = H.ZPZ[1, i]
    end
    
    return nothing
end

function update_views!(H::NullspaceHessian{T}) where {T}
    range = H.n-H.m+1:H.n
    H.ZPZ = view(H.data, range, range)
    H.Z = H.QR.Q2
end