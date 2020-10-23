#=
We want to simulate a number of warehouses that store the same product. At a regular
interval, a product is required. But the origin of the product does not matter.

We create our own type `Warehouse` with two field that allow to identify the 
warehouse and that allow to track its stock by by means of a `Store`.

The production process works adds a random quantity to a random warehouse 
(the first available) and works as follows:
* generate a product
* generate the requests for all resources
* yield the requests the will occur first. *note*: if two events occur at the same time,
they will both happen. We deal with this later.
* cancel all the other requests that have not occured yet. For those that have occured,
we decrement the store with the value it was increased by.

The simulation stops when either all warehouses are full (or cannot handle the 
produced quantity).

A similar approach can be followed when dealing with `get` requests instead of
`put` requests.

This application illustrates how you can deal with resource concurrency,
i.e. taking whatever resource(s) come(s) available first without blocking the
other ones or introducing unwanted artifacts.
=#

using Logging
using SimJulia
import Base.show

struct Warehouse
    name::String
    stock::Container
    function Warehouse(env::Environment, name::String; capacity::Int=10)
        return new(name, Container(env,capacity))
    end
end

show(io::Core.IO, w::Warehouse) = print(io::Core.IO, "$(w.name) - capacity $(w.stock.level)/$(w.stock.capacity)")

@resumable function production(env::Environment, warehouses::Array{Warehouse,1})
    while true
        @info "$(env.time) - warehouse status: $(status(warehouses))"
        # Start making the product (variable production time)
        @debug "$(env.time) - Production starts"
        @yield timeout(env, rand(6:10))
        quant = rand(1:5)
        @info "$(env.time) - Production finished ($(quant) units produced)"
        # get an overview of available resources -> Array{Store, 1}
        resources = map(w::Warehouse -> w.stock, warehouses) 
        @debug "$(env.time) - resources: $(resources)"
        # Signal a product needs storage -> Array{SimJulia.Put,1}
        signal = map(r -> put(r, quant), resources) 
        @debug "$(env.time) - signal: $(signal)"
        # Yield the different events -> Dict{AbstractEvent,SimJulia.StateValue}
        delivery_requests = @yield Operator(SimJulia.eval_or, signal...) # only one required
        @debug "$(env.time) - delivery requests: $(delivery_requests)"
        # Get the delivery status
        delivery_status = [delivery_requests[s].state for s in signal]
        @debug "$(env.time) - delivery status: $(delivery_status)"
        # Select "winning" warehouse from the status
        wh = findfirst(x -> x == SimJulia.processed, delivery_status)
        @debug "$(env.time) - winning warehouse : $(warehouses[wh])"
        @debug "$(env.time) - BAD warehouse status: $(status(warehouses))"
        # Cancel other requests or reduce value if they happened at the same time
        for i in 1:length(warehouses)
            if i ≠ wh
                @debug "$(env.time) - cancelling warehouse request for $(warehouses[i])"
                if haskey(resources[i].put_queue, signal[i])
                    cancel(resources[i], signal[i])
                else
                    warehouses[i].stock.level -= quant
                end
            end
        end
    end
end

function mysim()
    # setup simulation
    @info "\n$("-"^70)\nwarehouse application\n$("-"^70)\n"
    sim = Simulation()
    # warehouses
    names = ["Brussels", "Amsterdam", "Paris"]
    warehouses = [Warehouse(sim, name, capacity=10) for name in names]
    # start production
    @process production(sim, warehouses)
    # start client
    run(sim)
    @info "$(sim.time) - FINAL warehouse status: $(status(warehouses))"
end

# helper function for printing
function status(v::Array{Warehouse,1})
    string("\n",["\t- $(w)\n" for w in v]..., "\n")
end

# logging settings
Logging.disable_logging(LogLevel(-1001)) # (de-)activate debug messages
logger = Logging.ConsoleLogger(stdout, Logging.Debug)

# run simulation
with_logger(logger) do
    mysim()
end