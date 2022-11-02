#=
Small illustation on the capacitated vehicle routing problem (CVRP)
Just run the script for an illustration

Mathematical model based on: https://www.researchgate.net/publication/323173028_Two_models_of_the_capacitated_vehicle_routing_problem
using modified indices to match Julia's 1-based indexing

In this model we eliminate all subtour explicitely, keep in mind that this is very expensive  
as the number of subtours grows exponentially with the number of cities! A modified approach is to solve the
relaxed problem (i.e. without subtour constraints) and only add them when they occur (thus solving the model again),
adding the constraint that prohibits the subtour that was found during the previous iteration cf.
https://how-to.aimms.com/Articles/332/332-Implicit-Dantzig-Fulkerson-Johnson.html
for a clear explanation.

=#
using JuMP
using GLPK
using Plots
using Combinatorics:powerset # may require additional install

"""
Multiple Vehicle Routing problem (using the entire set of possible subtours for subtour elimination)
"""
function MVRP()
    # general problem setup #
    # --------------------- #
    # number of cities
    n = 6
    # pick random locations
    coord_x = rand(n+1)
    coord_y = rand(n+1)
    dist(x_1, x_2, y_1, y_2) = sqrt((x_1 - x_2)^2 + (y_1 - y_2)^2)
    # cost matrix (symmetrical, distances, depot is city 1) 
    c = zeros(n+1, n+1)
    for i in 1:n+1
        for j in i+1:n+1
            c[i,j] = dist(coord_x[i], coord_x[j], coord_y[i], coord_y[j])
        end
    end
    c .+= c'
    # demand for each city (number of e.g. number of pallets)
    d = rand(1:10, n+1)
    d[1] = 0 # no demand @ depot
    # truck capacity (equal for all trucks, can easily be extended to different size trucks)
    Q = 20
    # minimum number of trucks for order to be feasible:
    p = ceil(Int,sum(d) / Q)
    @info "$(p) trucks required"


    # Linear programming setup #
    # ------------------------ #
    model = Model(with_optimizer(GLPK.Optimizer))
    # Add variables (x_{i,j,p}: edge from i > j by truck p, Boolean valued)
    @variable(model, x[1:n+1,1:n+1,1:p], Bin)
    # Add objective
    @objective(model, Min, sum(sum(x[:,:,i] .* c) for i in 1:p))
    # Add constraints
    for r in 1:p
        # each vehicle can leave the depot only once
        @constraint(model, sum(x[1, j, p] for j in 2:n+1) == 1)
        # sum of the demands of the customers visited in a route is less than or equal to the capacity of the vehicle
        @constraint(model, sum(d[j]*x[i,j,r] for i in 1:n+1 for j in 2:n+1 if i≠j) <= Q)
        # the number of the vehicles arriving at every customer and entering the depot is equal to the number of the vehicles leaving
        for j in 1:n+1
            @constraint(model, sum(x[i,j,r] for i in 1:n+1 if i≠j) == sum(x[j,i,r] for i in 1:n+1))
        end
    end
    # ensure that each customer is visited by exactly one vehicle
    for j in 2:n+1
        @constraint(model, sum(x[i,j,r] for r in 1:p for i in 1:n+1 if i≠j) == 1)
    end
    
    #=
    # eliminate sub-tours (essential but costly)
    for subset in powerset(2:n+1, 2, n)
        @constraint(model, sum(x[i,j,r] for r in 1:p for i in subset for j in subset if i≠j) <= length(subset) - 1 )
    end
    =#
    # Solve problem
    optimize!(model)
    @info "termination status: $(termination_status(model))"
    @info "objective_value $(objective_value(model))"



    #     Nice illustration    #
    # ------------------------ #
    marks = [:circle for _ in 1:n+1]
    marks[1] = :cross
    fig = plot()
    scatter!(fig, coord_x[1:1], coord_y[1:1], marker=:cross, label="Depot", color=:black,markersize=12)
    scatter!(fig, coord_x[2:end], coord_y[2:end], marker=:circle, label="Stores", color=:gray )
    for r in 1:p
        inds = findall(x-> !iszero(x), value.(x[:,:,r]))
        for ind in inds
            xx = [coord_x[ind[1]]; coord_x[ind[2]]]
            yy = [coord_y[ind[1]]; coord_y[ind[2]]]
            plot!(fig, xx, yy, color=r, label="")
        end
    end
    title!(fig, "lay-out for $(p) trucks with $(n) cities")
    display(fig)
end

"""
Multiple Trip Vehicle Routing problem

Implementation according to the 4-index formulation, also uses the entire set of subtours (similar to the other example)

Remark: since we are mimimising the total time of all trips, it can happen that a single truck gets two trips, while the 
other one gets nothing at all. In a simulation context, you should take this into account.
"""
function MTVRP()
    # general problem setup #
    # --------------------- #
    # number of cities
    n = 7
    # pick random locations
    coord_x = rand(n+1)
    coord_y = rand(n+1)
    dist(x_1, x_2, y_1, y_2) = sqrt((x_1 - x_2)^2 + (y_1 - y_2)^2)
    # cost matrix (symmetrical, distances, depot is city 1) 
    c = zeros(n+1, n+1)
    for i in 1:n+1
        for j in i+1:n+1
            c[i,j] = dist(coord_x[i], coord_x[j], coord_y[i], coord_y[j])
        end
    end
    c .+= c'
    # demand for each city (number of e.g. number of pallets)
    d = rand(1:10, n+1)
    d[1] = 0 # no demand @ depot
    # truck capacity (equal for all trucks, can easily be extended to different size trucks)
    Q = 20
    V = 2 # number of vehicles
    R = 3 # number of trips/vehicle
    TH = 5 # max trip length => results in "infeasible" 
    # minimum number of trucks for order to be feasible:
    @info "$(ceil(Int,sum(d) / Q)) trips required for a solution"
    @info "$(V) trucks used, max $(R) trips per truck, total work time $(TH)"
    # Linear programming setup #
    # ------------------------ #
    model = Model(with_optimizer(GLPK.Optimizer))
    # Add variables 
    # x_{i,j,v, r}: edge from i > j by truck v on trip r, Boolean valued
    @variable(model, x[1:n+1, 1:n+1, 1:V, 1:R], Bin)
    # y_{i, v, r}: 1 if trip r of vehicle v visits vertex i, Boolean valued
    @variable(model, y[1:n+1, 1:V, 1:R], Bin)
    
    # Add objective (slices)
    @objective(model, Min, sum(sum(x[:,:,v,r] .* c) for v in 1:V for r in 1:R)) # (1)
    
    # Add constraints
    for i in 2:n+1
        @constraint(model, sum(y[i,v,r] for v in 1:V for r in 1:R) == 1) # (2)
    end

    for v in 1:V
        for r in 1:R
            for i in 1:n+1
                @constraint(model, sum(x[i,j,v,r] for j in 1:n+1 if j≠i) == y[i,v,r]) # (3)
                @constraint(model, sum(x[j,i,v,r] for j in 1:n+1 if j≠i) == y[i,v,r]) # (3)
                @constraint(model, sum(x[j,i,v,r] for j in 1:n+1 if j≠i) == sum(x[i,j,v,r] for j in 1:n+1 if j≠i)) # (3)
            end

            @constraint(model, sum(d[i] * y[i,v,r] for i in 2:n+1) <= Q) # (4)
            for subset in powerset(2:n+1, 2, n)
                @constraint(model, sum(x[i,j,v,r] for i in subset for j in subset if i≠j) <= length(subset) - 1 ) # (5)
            end
        
        end
    end

    for v in 1:V
        @constraint(model, sum(sum(x[:,:,v,r] .* c) for r in 1:R) <= TH) # (6)
    end

    optimize!(model)
    @info "termination status: $(termination_status(model))"
    @info "objective_value $(objective_value(model))"
    
    #     Nice illustration    #
    # ------------------------ #
    marks = [:circle for _ in 1:n+1]
    marks[1] = :cross
    fig = plot()
    scatter!(fig, coord_x[1:1], coord_y[1:1], marker=:cross, label="Depot", color=:black,markersize=12)
    scatter!(fig, coord_x[2:end], coord_y[2:end], marker=:circle, label="Stores", color=:gray )
    for v in 1:V
        for r in 1:R
            inds = findall(x-> !iszero(x), value.(x[:,:,v,r]))
            for ind in inds
                xx = [coord_x[ind[1]]; coord_x[ind[2]]]
                yy = [coord_y[ind[1]]; coord_y[ind[2]]]
                plot!(fig, xx, yy, color=v, label="", line=r)
            end
            @info "truck $(v), route $(r): $(round(sum(c[inds]), digits=2)) kms"
        end
    end
    title!(fig, "lay-out for $(V) trucks with $(n) cities, max $(R) routes per truck\ncolor= truck, line thickness=route")
    display(fig)
end


MVRP()
#MTVRP()