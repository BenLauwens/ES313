#=
We want to simulate a number of machines that each produce a specific product and 
put it in a warehouse (a `Store`). There is a combination process that needs one
of each generated products and combines it into another. The simulation ends when
the fictive container of combined goods is full.

We create our own type `Product` with two fields that allow to identify the kind of
product and to identify its "creator" by means of a serial number.
We also create a type `Machine` that has an associated process. This machine has
an ID an make one type of products. All generated product are put into the same 
store. 

The combiner process works as follows:
* generate the events matching the availability of one of each product
* wait until all of these events are realised. *Note*: if you only have two events, 
you can simply use `ev1` & `ev2`.
* generate the event of putting a fictive combined product in a container
* @yield the event (i.e. time-out until done)
* verify if the container is full and if so stop the simulation on this event.

This application illustrates how you can wait on multiple other events before 
continuing the simulation. Keep in mind that this requires ALL events to be 
processed.
=#

using Logging
using ConcurrentSim
using ResumableFunctions
import Base.show

struct Product
    kind::Symbol
    serial_number::String
end

show(io::Core.IO, p::Product) =  print(io, "$(p.kind) with serial N° $(p.serial_number)")

mutable struct Machine
    id::String
    prod_kind::Symbol
    prod_time::Int
    n_prod::Int
    prod_store::Store{Product}
    proc::Process
    function Machine(id::String, 
                     prod_kind::Symbol, prod_time::Int, 
                     prod_store::Store{Product}, n_prod::Int=0)
        m = new()
        m.id = id
        m.prod_kind = prod_kind
        m.prod_time = prod_time
        m.n_prod = n_prod
        m.prod_store = prod_store
        m.proc = @process produce(m.prod_store.env, m)
        return m
    end
end

@resumable function produce(env::Environment, m::Machine)
    while true
        @yield timeout(env, m.prod_time)
        m.n_prod += 1
        newprod = Product(m.prod_kind, "$(m.id)-"*lpad("$(m.n_prod)", 4, "0"))
        @debug "$(env.time) - Machine $(m.id) produced a $(newprod)"
        @yield put(m.prod_store, newprod)
    end
end

@resumable function combiner(env::Environment, prod_store::Store{Product}, 
                             products::Array{Symbol, 1}, result_container::Container)
    while true
        # obtain a request for each product kind
        requests = map(x::Symbol -> get(prod_store, p::Product -> p.kind == x), products)
        @debug "$(env.time) - Combiner requests: $(requests)"
        # all requests must be matched
        @yield Operator(ConcurrentSim.eval_and, requests...)
        @debug "$(env.time) - Combiner got all required products!"
        newcomb = put(result_container, 1)
        @yield newcomb
        # stop the simulation after the final combination was made
        if result_container.level == result_container.capacity
            @info "Combiner made all products in $(env.time) time units"
            ConcurrentSim.stop_simulation(newcomb)
        end
        @debug "$(env.time) - Current container level $(result_container.level)"
    end
    
    
end

"""
    mysim()

This is the main simulation function in which we first create the store, followed by the products, the result
container and the machines. Finally, we start the simulation and wait for it to finish.
"""
function mysim()
    # setup simulation
    @info "\n$("-"^70)\nPS07 - ConcurrentSim: Machine application\n$("-"^70)\n"
    sim = Simulation()
    # products
    prod_store = Store{Product}(sim)
    products = [:nut, :bolt, :rivet, :beam]
    prod_times = [1;2;4;6]
    # combined results
    result_container = Container(sim, 10)
    # machines
    machines = [Machine("Machine $(i)", products[i], prod_times[i], prod_store) for i in 1:length(products)]
    @process combiner(sim, prod_store, products, result_container)
    run(sim)
end

# logging settings
Logging.disable_logging(LogLevel(-1001)) # (de-)activate debug messages
logger = Logging.ConsoleLogger(stdout, Logging.Debug)

# run simulation
with_logger(logger) do
    mysim()
end
