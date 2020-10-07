using GeneralQP
using JuMP, Gurobi
using Random

rng = MersenneTwister(123)
n = 300
m = 500
P = randn(rng, n, n); P = (P + P')/2
q = randn(rng, n)
A = randn(rng, m, n); b = randn(rng, m)


# Choose Gurobi's primal simplex method
model = Model(solver=GurobiSolver(Presolve=0, Method=0))
@variable(model, x[1:size(A, 2)])
@constraint(model, A*x - b .<=0)
status = JuMP.solve(model)

x_init = getvalue(x)  # Initial point to be passed to our solver

using Main.GeneralQP

Main.GeneralQP.solve(P, q, A, b, x_init; verbosity=1)