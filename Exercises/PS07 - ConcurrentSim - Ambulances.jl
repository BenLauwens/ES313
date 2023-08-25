#=
We want to simulate a the evactuation of people who got hurt in a disaster. The 
different victims can be in a specific state (maybe useful for triage once they
arrive in the hospital). The ambulance can only carry one person at a time. 

In this simulation we will use the following settings:
- random ambulances are generated, they only do one trip
- random patients generated
- the simulation stops when all processes are terminated

We create our own type `Victim` with two field that allow to identify the 
victim and see its status. We also create a type `Ambulance` that has a number,
is linked to a hospital, a traveltime and an associated Process.

=#
using ResumableFunctions
using ConcurrentSim

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
end

disaster()

