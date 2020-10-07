# Disclaimer
This is a fork of the original package that can be found [here](https://github.com/oxfordcontrol/GeneralQP.jl). The inner workings are unchanged. This only serves to make the package compatible with Julia 1.5. Only this readme has changed with respect to the original package.


# GeneralQP.jl
This package is a Julia implementation of [the following paper](https://link.springer.com/article/10.1007/BF01588976)
```
Gill, Philip E., and Walter Murray.
Numerically stable methods for quadratic programming.
Mathematical programming 14.1 (1978): 349-372.
```
i.e. an inertia-controlling active-set solver for general (definite/indefinite) *dense* quadratic programs
```
minimize    ½x'Px + q'x
subject to  Ax ≤ b
```
given an [initial feasible point](#obtaining-an-initial-feasible-point) `x_init`. 

To avoid further restrictions on the initial point, an artificial constraints approach is taken as described in [QPOPT's 1.0 User manual, Section 3.2](https://web.stanford.edu/group/SOL/guides/qpopt.pdf).

## Installation
The solver can be installed by running
```
add https://github.com/oxfordcontrol/GeneralQP.jl
```
in [Julia's Pkg REPL mode](https://docs.julialang.org/en/v1/stdlib/Pkg/index.html#Getting-Started-1).
## Usage
The solver can be used by calling the function
```
solve(P, q, A, b, x_init; kwargs) -> x
```
with **inputs** (`T` is any real numerical type):

* `P::Matrix{T}`: the quadratic cost;
* `q::Vector{T}`: the linear cost;
* `A::Matrix{T}` and `b::AbstractVector{T}`: the constraints; and
* `x_init::Vector{T}`: the initial, [feasible](#obtaining-an-initial-feasible-point) point

**keywords** (optional):
* `max_iter::Int=5000` Maximum number of iterations.
* `verbosity::Int=1` the verbosity of the solver ranging from `0` (no output)
to `2` (most verbose). Note that setting `verbosity=2` affects the algorithm's performance.
* `printing_interval::Int=50`.
* `r_max::T=Inf` Maximum radius. The algorithm terminates if ‖x‖ ≥ r with a return solution of ‖x‖ = r. This is particularly useful for unbounded problems.

and **output** `x::Vector{T}`, the calculated optimizer.

## Updatable factorizations
This package includes [`UpdatableQR`](https://github.com/oxfordcontrol/GeneralQP.jl/blob/master/src/linear_algebra.jl), an updatable `QR` factorization `F` of a "thin" `n x m` matrix
```
X = F.Q*F.R
```
that allows efficient `O(n^2)` update of the factors when adding/removing rows in the matrix `X`. This is critical for efficient execution of (dense) active-set algorithms.

These updates can be simply performed using
```
add_column!(F::UpdatableQR{T}, a::AbstractVector{T})
remove_column!(F::UpdatableQR{T}, idx::Int).
```

Similarly, [`UpdatableHessianLDL`](https://github.com/oxfordcontrol/GeneralQP.jl/blob/master/src/linear_algebra.jl) provides an updatable `LDLt` factorization for the projection of the hessian `P` on the nullspace of the working constraints.

`UpdatableHessianLDL` is based on `UpdatableQR` and implements functionality for artificial constraints ([QPOPT 1.0 Manual, Section 3.2](https://web.stanford.edu/group/SOL/guides/qpopt.pdf)).

## Obtaining an initial feasible point

An initial feasible point can be obtained e.g. by performing `Phase-I` `Simplex` on the polyhedron `Ax ≤ b`:
```
using JuMP, Gurobi
# Choose Gurobi's primal simplex method
model = Model(solver=GurobiSolver(Presolve=0, Method=0))
@variable(model, x[1:size(A, 2)])
@constraint(model, A*x - b .<=0)
status = JuMP.solve(model)

x_init = getvalue(x)  # Initial point to be passed to our solver
```