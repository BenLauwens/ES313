#=
We want to simulate the life cycle of a parachute. This is a limited example, as not all the 
steps of the real process are present. In the simulation, only a single jump is done.

A parachute is characterized by its id, its age and its status. A parachute typically hase the following life cycle:
- it is taken out of the warehouse for a jump or to be folded again
- a jump takes place
- the parachute is dried after the jump
- the parachute is inspected for damage and repaired or discarded if necessary
- the parachute folded
- the parachute is put back in the warehouse for future use

While the parachute is in the warehouse, it ages. This is done by the `aging` process. This
is required because a parachute can only be stored for a limited time. After that, it is
required to be folded again and put back in the warehouse.

This application illustrates how you can transfer objects between stores and act on them.
=#

using SimJulia

mutable struct Chute
    id::Int
    age::Int
    ready::Bool
end

Base.show(io::IO, c::Chute) = print(io, """chute $(c.id) (age $(c.age), $(c.ready ? "" : "not") ready)""")
age!(c::Chute) = c.age += 1

@resumable function fillmag(sim::Environment, mag::Store, n::Int=5)
    chutes = [Chute(i, 0, true) for i in 1:n]
    for chute in chutes
        @yield put(mag, chute)
    end
    @info "$(now(sim)) - current warehouse: $(mag.items)"
end

# cycle for single jump
@resumable function jump(sim::Environment, n::Int,  mag::Store, folders::Store)
    @info "$(now(sim)) - dropping $(n) paratroopers"
    for _ in 1:n
        chute = @yield get(mag)
        chute.ready = false
        @info "$(now(sim)) - got $(chute)"
        # run the actual process of the chute
        @process chutecycle(sim, chute, folders)
    end
end

# aging process
@resumable function aging(sim::Environment, mag::Store)
    while true
        @yield timeout(sim, 1)
        # age each chute in the warehouse
        # note that internally, the store is a Dict{Chute, UInt}, so we can iterate over it
        # cf. https://github.com/BenLauwens/SimJulia.jl/blob/master/src/resources/stores.jl
        for chute in keys(mag.items)
            age!(chute)
        end
    end
end

@resumable function chutecycle(sim::Environment, c::Chute, folders::Store) 
    @info "$(now(sim)) - $(c) is drying"
    @yield timeout(sim, rand(1:3))
    @info "$(now(sim)) - $(c) is dry, going to fold"
    # store chute with the folders
    @yield put(folders, c)
    @info "$(now(sim)) - waiting list folding: $(folders.items)"
end

@resumable function fold(sim::Environment, mag::Store, folders::Store)
    while true
        @yield timeout(sim, 10)
        for _ in 1:37 # daily folds per person
            if length(folders.items) > 0
                chute = @yield get(folders)
                chute.ready = true
                @info "$(now(sim)) - folded $(chute)"
                @yield put(mag, chute)
            end
        end  
    end
end

function airborne(nchutes=3)
    @info "\nPS07 - SimJulia - Paratrooper demo\n\n"
    sim = Simulation()
    mag = Store{Chute}(sim)
    folders = Store{Chute}(sim)
    # fill storage with chutes
    @process fillmag(sim, mag, nchutes)
    # add single jump with two paratroopers to the simulation
    @process jump(sim, 2, mag, folders)
    # add folding process
    @process fold(sim, mag, folders)
    # add aging process
    @process aging(sim, mag)
    
    # run simulation
    run(sim, 20)
    @info "$(length(mag.items)) chutes in warehouse, $(length(folders.items)) waiting to be folded"
end

airborne()