__precompile__(true)

module GeneralQP

using LinearAlgebra
using Polynomials

include("linear_algebra.jl")
include("change_constraints.jl")
include("qp.jl")
include("printing.jl")

export solve
export UpdatableQR, NullspaceHessianLDL, NullspaceHessian
export add_column!, remove_column!
export add_constraint!, remove_constraint!

end