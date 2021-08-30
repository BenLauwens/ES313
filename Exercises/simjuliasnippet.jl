using SimJulia

# minimalistic simjulia evactuation example 
# - random ambulances are generated, they only do one trip
# - random patients generated
# - simulation stops when all processes are terminated
const hospitals = ["St. Luc", "Erasme", "UZ Jette"]

struct Victim
    name::String
    state::Int
end
Base.show(io::IO, v::Victim) = print(io, "victim $(v.name) in state $(v.state)")

mutable struct Ambulance
    number::Int
    hospital::String
    traveltime::Int
    p::Process
    function Ambulance(sim::Environment, number::Int, hospital::String, traveltime::Int, victims::Array{Victim, 1})
        a = new()
        a.number = number
        a.hospital = hospital
        a.traveltime = traveltime
        a.p = @process ambulance(sim, a, victims)
    end
end

Base.show(io::IO, a::Ambulance) = print(io, "ambulance $(a.number) from $(a.hospital)")

@resumable function ambulance(sim::Environment, a::Ambulance, victims::Array{Victim, 1})
    @info "$(now(sim)) - $(a) moving"
    @yield timeout(sim, a.traveltime)
    @info "$(now(sim)) - $(a) on site"
    @yield timeout(sim, rand(5:10))
    # pick random victim
    v = popat!(victims, rand(1:length(victims)))
    @info "$(now(sim)) - $(a) leaving site with $(v)"
    @yield timeout(sim, a.traveltime)
    @info "$(now(sim)) - $(a) at hospital with $(v)"
end

function disaster(n_v=10, n_a=5)
    @info "\n\t\tEvaction demo\n\n"
    sim = Simulation()
    victims = [Victim("person $(i)", rand(1:4)) for i in 1:n_v]
    ambs = [Ambulance(sim, i, rand(hospitals), 10 + rand(1:10), victims) for i in 1:n_a]
    run(sim)
    @info "$(length(victims))/$(n_v) victims remaining on site"
    println()
end

disaster()


# minimalistic object transfering
# - only a single jump is done
# - not all steps are present
# - chutes are transferred from one store to another
# - chutes is warehouse "age" in their ready state

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
        @info "got $(chute)"
        @process chutecycle(sim, chute, folders)
    end
end

# aging process
@resumable function aging(sim::Environment, mag::Store)
    while true
        @yield timeout(sim, 1)
        age!.(mag.items)
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
    @info "\n\t\tParatrooper demo\n\n"
    sim = Simulation()
    mag = Store{Chute}(sim)
    folders = Store{Chute}(sim)
    # fill storage with chutes
    @process fillmag(sim, mag, nchutes)
    # add single jump to simulation
    @process jump(sim, 2, mag, folders)
    # add folding process
    @process fold(sim, mag, folders)
    # add aging process
    @process aging(sim, mag)
    run(sim, 20)
    @info "$(length(mag.items)) chutes in warehouse, $(length(folders.items)) waiting to be folded"
    @info mag.items

    println()
end

airborne()

########################################################
# Simple and empty process

@resumable function filler(sim::Environment, s::Store)
    i = 0
    while true
        @yield put(s, i)
        @info "$(now(sim)) - current store: $(s.items)"
        i += 1
        @yield timeout(sim, 1)
    end
end

@resumable function taker(sim::Environment, s::Store)
    while true
        res = @yield get(s)
        @info "$(now(sim)) - got $(res)"
        @yield timeout(sim, rand(1:4))
    end
end

function testfun()
    @info "\n\t\tStore usage demo\n\n"
    sim = Simulation()
    s = Store{Int}(sim)
    @process filler(sim, s)
    @process taker(sim, s)
    run(sim, 10)
end

testfun()


# worker process with prioties
# - each job has an ID and a priority
# - items are removed from store according to their priority
# - task can be split over multiple days

mutable struct job
    number::Int           # job identification
    prio::Int             # priority (0: normal, 1: high, 2: super high (i.e. unfinished))
    duration # standard time delta when working with datetime
    start       # moment task started
    stop        # moment when finished
    finished::Bool        # task terminated
    # only intialise required fields
    function job(number; prio::Int=0, duration)
        j = new()
        j.number = number
        j.prio = prio
        j.duration = duration
        return j
    end
end

Base.show(io::IO, j::job) = print(io, "job $(j.number) (prio: $(j.prio), duration: $(j.duration))")

@resumable function work(sim::Environment, tasks::Store{job}, completed::Store{job})
    while true
        # check if (super) high prio jobs exist and get one
        if length([t for t in tasks.items if t.prio == 2]) > 0 
            @info "$(now(sim)) - VERY HIGH prio task(s) found"
            current = @yield get(tasks, x-> x.prio == 2)
        elseif length([t for t in tasks.items if t.prio == 1]) > 0
            @info "$(now(sim)) - HIGH prio task(s) found"
            current = @yield get(tasks, x-> x.prio == 1)
        elseif length([t for t in tasks.items if t.prio == 0]) > 0
            @info "$(now(sim)) - default prio task(s) found"
            current = @yield get(tasks, x-> x.prio == 0)
        else
            @info "$(now(sim)) - Nothing to do!"
            current = nothing
        end

        # next day if no work
        if isnothing(current)
            @yield timeout(sim, 24)
        # proces the task 
        else
            @info "$(now(sim)) - working on task $(current)"
            current.start = now(sim)
            if (current.start + current.duration) % 24 > 16
                @info "$(now(sim)) - not enough time for task $(current)"
                # calculate remaining time
                dt =  current.duration - ((current.start + current.duration) % 24 - 16)
                # add remaing part of task on next day with super high prio
                current.duration -= dt
                current.prio = 2
                @yield put(tasks, current)
                # move on to end of day
                @yield timeout(sim, 16 - now(sim))
                @info "$(now(sim)) - end of day!"
                @yield timeout(sim, 16)
            else
                @yield timeout(sim, current.duration)
                current.stop = now(sim)
                current.finished = true
                @info "$(now(sim)) - task $(current) is done!"
                @yield put(completed, current)
            end
        end
    end
end

function jobman()
    @info "\n\t\tJobman demo\n\n"
    sim = Simulation(8)
    jobs = Store{job}(sim)
    completedjobs = Store{job}(sim)
    # add some jobs
    for i in 1:10
        push!(jobs.items, job(i, prio=rand([0,1]), duration = 10))
    end
    @process work(sim, jobs, completedjobs)
    run(sim, 50)
    @info "$(length(completedjobs.items)) completed tasks: \n\n$(completedjobs.items)\n\n"
    @info "$(length(jobs.items)) planned tasks: \n\n$(jobs.items)\n"
end

jobman()