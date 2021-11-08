#=
We want to simulate the life of a puppy. It's life consists of three activities:
eating, sleeping and playing. This simple life can be disturbed (i.e. interrupted) 
when it gets picked up by a human. If a puppy likes you, it might lick your face. 
After being picked up, a puppy continues its life as before.

We create our own type `Puppy` that has an associated process that models its life. 
We also create a type `Human` that has an associated process to pick up a random 
puppy from time to time.

This application illustrates how you can interrupt an ongoing process and even do 
something with the cause of the interruption (in this case keeping track of who 
got liked by a puppy).
=#
using SimJulia
using ResumableFunctions
using Logging

# known puppy properties
const puppyparams = Dict(:eat => 1:5, :sleep => 5:30, :play => 5:10)

mutable struct Puppy
    name::String
    state::Symbol
    proc::Process
    pickedup::Int
    licked::Int
    function Puppy(env::Environment, n::String)
        p = new()
        p.name = n 
        p.pickedup=0
        p.licked=0
        p.state = rand(keys(puppyparams)) # start in random state
        p.proc = @process puppylife(env,p)
        return p
    end
end

mutable struct Human
    name::String
    picked::Int
    licked::Int
    proc::Process
    function Human(env::Environment, litter::Array{Puppy,1}, name::String)
        h = new()
        h.name = name
        h.picked = 0
        h.licked = 0
        h.proc = @process humanlife(env, litter, h)
        return h
    end
end

@resumable function puppylife(env::Environment, p::Puppy)
    while true
        try
            # do current activity for an amount of time
            duration = rand(puppyparams[p.state])
            @debug """$(now(env)) - Puppy '$(p.name)' current state: $(p.state) for $(duration)"""
            @yield timeout(env, duration)
            # change state (avoiding the current one)
            newstate = rand(filter(x -> x ≠ p.state, keys(puppyparams)))
            @debug """$(now(env)) - Puppy '$(p.name)' will go from $(p.state) to $(newstate)"""
            p.state = newstate
        catch err
            # if interuppted this will happen
            @debug "$(now(env)) - '$(p.name)' is picked up by $(err.cause.name)"
            p.pickedup += 1
            if rand() < 0.5
                @debug "$(now(env)) - '$(p.name)' likes $(err.cause.name)"
                # track how many humans a puppy has liked
                p.licked += 1
                # track how many this specific human was liked by a puppy
                err.cause.licked += 1
            end
        end
    end
end

@resumable function humanlife(env::Environment, litter::Array{Puppy,1}, human::Human)
    while true
        @yield timeout(env, rand(5:20))
        choice = rand(litter)
        @debug "$(now(env)) - $(human.name) chooses to pick up $(choice.name)"
        human.picked += 1
        @yield interrupt(choice.proc, human)
    end
end

function mysim(humannames=["Anaïs", "Pieter", "Bart"],
               dognames=["Django", "Zappa", "Squeez", "Fluffy"])
    @info "\n$("-"^70)\nPuppy life\n$("-"^70)\n"
    sim = Simulation()
    # add puppies
    litter = [Puppy(sim, name) for name in dognames]
    # add humans
    humans = [Human(sim, litter, name) for name in humannames]
    # run simulation
    run(sim,100)
    # show results
    overview_h = ["\t$(human.name) was liked $(human.licked)/$(human.picked) times\n" for human in humans]
    overview_p = ["\t$(p.name) liked getting picked up $(p.licked)/$(p.pickedup) times\n" for p in litter]
    msg = "Results\n$("-"^15)\n$(string("\tHumans:\n",overview_h...))\n$(string("\tPuppies:\n",overview_p...))" 
    @info msg
end

# logging settings
Logging.disable_logging(LogLevel(-1000)) # (de-)activate debug messages
logger = Logging.ConsoleLogger(stdout, Logging.Debug)

# run simulation
with_logger(logger) do
    mysim()
end






