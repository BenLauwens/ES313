using Plots
using Dates
using Logging
using ResumableFunctions
using ConcurrentSim
using Distributions, StatsBase
using StatsPlots



### constants 
# for logging
const namewidth = 20
const timewidth= 20
# physical constants
const v_sound = 343 # m/s
const timeres = Millisecond(1000) # time resolution for moving the canons
# systems operationality treshold (below this, a system can no long fire)
const h_ops = 1/3
## tactical constants
# validity of a firing mission - mission that are older will be discarded
const t_valid = Minute(5) # + split between CBy & TacAie
# multimission window - after being triggered for a first mission, the timeframe during which additional missions
#                       can be included for multiple simultaneous firings
const t_window = Minute(2)
# number of shots used for a counter battery firing mission
const cb_shots = 12

# stopping health
const h_stop = 0.5


d(x,y) = sqrt((x[1] - y[1])^2 + (x[2] - y[2])^2) # helper function distance

"""
    angle(a::NTuple{2,Float64}, b::NTuple{2,Float64})

return angle between two points in a 2D reference frame.
"""
function angle(a::NTuple{2,Float64}, b::NTuple{2,Float64})
    return b[1]-a[1] < 0 ? atan((b[2]-a[2])/(b[1]-a[1])) + π : atan((b[2]-a[2])/(b[1]-a[1]))
end

"""
    positionangles(p::Vector{NTuple{2, Float64}})

determine the angle between a list of vectors
"""
function positionangles(p::Vector{NTuple{2, Float64}})
    θ = Vector{Float64}(undef, length(p))
    for i = 1:length(p)-1
        θ[i] = angle(p[i], p[i+1])
    end
    θ[end] = angle(p[end], p[1])

    return θ
end

"""
		positiongenerator(x,y; rmin=500, rmax=1000) where T
	
	Generate a random triangle with (x,y) as one of the corner points. All points are located at a distance between rmin and rmax from one another.

	Returns a vector of X and Y coördinates.
	"""
	function positiongenerator(x::T,y::T; rmin=500, rmax=1000) where T
		X = Vector{T}(undef,3); X[1] = x
		Y = Vector{T}(undef,3); Y[1] = y
		# pick random angle and distance for second point and first leg (within limits)
		θa = rand()*2pi
		a = rmin + rand()*(rmax-rmin)
		X[2] = x + a*cos(θa)
		Y[2] = y + a*sin(θa)
		# pick random length for second and third leg
		b = rmin + rand()*(rmax-rmin)
		c = rmin + rand()*(rmax-rmin)
		# this defines the other angle
		γ = acos((c^2 - a^2 - b^2) / (-2*a*b))
		θb = θa - γ
		# which in turn defines the other point
		X[3] = x + b*cos(θb)
		Y[3] = y + b*sin(θb)
		return X, Y
	end

"""
    linecoordinates(x, y, dist, n::Int; angle=0)

Position `n` pieces in line centered around (x,y) with an interdistance `dist` between them. The optional keyword argument angle (in radians) rotates them.

Returns a vector of coordinate tuples.
"""
function linecoordinates(x, y, dist, n::Int; angle=0)
    map(p->(x+p[1]*cos(angle), y+p[2]*sin(angle)) , zip(rangemaker(dist,n), rangemaker(dist,n)))
end

"""
    rangemaker(dist,n)

helper function for linecoordinates
"""
rangemaker(dist,n) = range(-(n-1)/2*dist, step=dist,length=n)

"""
    show_me_positions(;n_friends::Int=12;n_foe::Int=6)

Make friendly and enemy positions and put the pieces in line. We use the average 
enemy location as a reference for aiming, so some friendly position aren't necessarily
all parallel
"""
function show_me_positions(;n_friends::Int=12,n_foe::Int=6)
    # main locations
    Xf, Yf = positiongenerator(0., 0.)
    Xe, Ye = positiongenerator(2000., 8000.)
    # determine angles (average location)
    θ_f = angle((mean(Xf),mean(Yf)), (mean(Xe), mean(Ye)))
    θ_e = angle((mean(Xe),mean(Ye)), (mean(Xf), mean(Yf)))
    # compute the actual locations
    F = [linecoordinates(x, y, 100, n_friends; angle=θ_f - π/2) for (x,y) in zip(Xf,Yf)]
    E = [linecoordinates(x, y, 50, n_foe; angle=θ_e - π/2) for (x,y) in zip(Xe,Ye)]
           
    fig = plot(title="overview of locations",
                aspect_ratio=:equal, 
                xlims=(-1500, 6000),
                legend=:outertopright)
    scatter!(vcat(F...), label="friends")
    scatter!(vcat(E...), label="foes")
    Plots.savefig(fig, "./Exercises/img/canonplacement.png")
    return fig
end  

## Datatypes
abstract type Equipment end

"""
    MunType(;   name::Symbol=:default,
            maxlethalrange::Float64=20., 
            v_muzzle::Float64=400.)

minimalistic representation of an ammunition
"""
struct MunType
    "Ammunition name"
    name::Symbol
    "Maximum letal range [m]"
    maxlethalrange::Float64
    "Muzzle velocity [m/s]"
    v_muzzle::Float64
end

Base.show(io::IO, m::MunType) = print(io, "$(m.name) ammunition (d_kill: $(m.maxlethalrange) [m], v_m: $(m.v_muzzle) [m/s])")

MunType(;   name::Symbol=:default,
            maxlethalrange::Float64=20., 
            v_muzzle::Float64=400.) = MunType(name, maxlethalrange, v_muzzle)


"""
    CanonType(;  name::Symbol=:default,
            PED::Float64=20.,
            PER::Float64=100.,
            BL::Int=12,
            mun::MunType=MunType(),
            v_mov::Float64=10.,
            reloadtime::TimePeriod=Second(10),
            outactiontime::TimePeriod=Second(60),
            inactiontime::TimePeriod=Second(60))

minimalistic representation of a canontype
"""
struct CanonType
    "Canon name"
    name::Symbol
    "Probable Error Deflection. Can be a value or a function that returns the PED depending on the range/wind/..."
    PED::Union{Float64, Function}
    "Probable Error Range. Can be a value or a function that returns the PER depending on the range/wind/..."
    PER::Union{Float64, Function}
    "Basic Load"
    BL::Int
    "Ammunition type"
    mun::MunType
    "Movement speed [m/s]"
    v_mov::Float64 #in m/s
    "Time needed for reloading [ms]"
    reloadtime::TimePeriod
    "Total time to break up and leave position [ms]"
    outactiontime::TimePeriod
    "Total time to build up position before firing [ms]" 
    inactiontime::TimePeriod
    "Impact point distribution used for sampling (PER, PED)"
    impactdist::ContinuousMultivariateDistribution
end

Base.show(io::IO, ct::CanonType) = print(io, "$(ct.name) canon type using $(ct.mun.name) (BL: $(ct.BL) shots)")

CanonType(;  name::Symbol=:default,
            PED::Float64=20.,
            PER::Float64=100.,
            BL::Int=12,
            mun::MunType=MunType(),
            v_mov::Float64=10.,
            reloadtime::TimePeriod=Second(10),
            outactiontime::TimePeriod=Second(60),
            inactiontime::TimePeriod=Second(60)) = CanonType(name, PED, PER, BL, mun, v_mov, reloadtime, outactiontime, inactiontime, 
                                                             MvNormal([0;0],[PER/quantile(Normal(), 0.75) 0;0 PED/quantile(Normal(), 0.75)])) 

"""
    Canon(; ctype::CanonType=CanonType(), 
        location::NTuple{2, Float64}=(0.,0.), 
        health::Float64=1., 
        id::Int=1,
        Pl::Char='A', 
        By::Int=100)

minimalistic representation of a Canon
"""
mutable struct Canon <: Equipment
    "number of the canon"
    ID::Int64
    "platoon of the canon"
    Pl::Char
    "battery of the canon"
    By::Int64
    "number of shots fired"
    nshots::Int64
    "type of canon"
    canontype::CanonType
    "location of canon in (x,y) [m]"
    location::NTuple{2, Float64}
    "different positions of the canons (x,y) [m]"
    posn::Vector{NTuple{2, Float64}}
    "angles between main positions [radians]"
    θ::Vector{Float64}
    "current main position"
    current_pos::Int
    "Operational status ∈ [0,1] where 0 corresponds with destroyed and 1 with fully operational"
    health::Float64 #1= fully operational, 0= destroyed	
end

Base.show(io::IO, c::Canon) = print(io, "canon $(c.ID) $(c.Pl) Pl, $(c.By) By ($(c.canontype.name) type) @($(c.location[1]),$(c.location[2]))")

Canon(; ctype::CanonType=CanonType(), 
        posn::Vector{NTuple{2, Float64}}=[(0.,0.)], 
        health::Float64=1., 
        id::Int=1,
        Pl::Char='A', 
        current_pos::Int=1,
        By::Int=100) = Canon(id, Pl, By, 0, ctype, posn[1], posn, positionangles(posn), current_pos, health)

"""
    Shot(; id::Int, c::Canon, target::NTuple{2,Float64}, timestamp::DateTime=now())

actual shot (that will \"fly\")
"""
struct Shot
    "shot identifier"
    id::Int
    "time of fire"
    timestamp::DateTime
    "canon that fires the shot"
    canon::Canon
    "aimpoint"
    target::NTuple{2,Float64}
    "actual impact location"
    impact::NTuple{2,Float64}
    "time of flight"
    tof::TimePeriod
    "ammunition type - used for damage assessment"
    mun::MunType
end

Base.show(io::IO, s::Shot) = print(io, "Shot $(s.id) fired from $(s.canon) towards $(s.target) on time $(Dates.format(s.timestamp,"YYYY-mm-dd HH:MM:SS")), impact @$(s.impact) after $(s.tof)")

"""

"""
function Shot(; id::Int, c::Canon, target::NTuple{2,Float64}, timestamp::DateTime=now())
    # determine actual impact point
    impact = impactpoint(c.location, target, c.canontype)
    # determine time of flight
    tof = Millisecond(round(Int,1000*d(c.location, target) / c.canontype.mun.v_muzzle))

    return Shot(id, timestamp, c, target, impact, tof, c.canontype.mun)
end

"""
    FiringMission(id, timestamp, targer, nshots)

minimalistic firing mission
"""
struct FiringMission
    "identifier (should be unique)"
    id::String
    "moment of creation, can be used to discard missions that are too old"
    timestamp::DateTime
    "target"
    target::NTuple{2,Float64} #target => location
    "number of shots to fire on target"
    nshots::Int64
end

"""
    Top level for military unit
"""
abstract type Unit end


"""
    Acoustic(;name::Symbol=:accoustic_1, location::NTuple{2,Float64}=(0.,0.))

minimal acoustic sensor implementation
"""
mutable struct Acoustic <: Equipment
    name::Symbol
    location::NTuple{2,Float64}
    "owner of the sensor (who gets the information)"
    owner::Union{Nothing, Unit}
end

Base.show(io::IO, a::Acoustic) = print(io, """accoustic sensor $(a.name) @$(a.location) owned by $(a.owner)""")
Acoustic(;name::Symbol=:accoustic_1, location::NTuple{2,Float64}=(0.,0.)) = Acoustic(name, location, nothing)

"""
    Radar(; name::Symbol=:radarpost_1, location::NTuple{2,Float64}=(0., 0.),
        available::Union{Nothing,Store{Shot}}=nothing, 
        av=Dict(), 
        scantime::TimePeriod=Second(60),
        trackers::Union{Nothing,ConcurrentSim.Resource}=nothing,
        missions::Union{Nothing,Store{FiringMission}}=nothing)

Point of origin detection radar. Used to generate firing missions

*Note:*
- can track a set amount of targets in parallel (using the `trackers resource`)
- will generate firing missing for a battery
- scans for a set amount of time before going offline again

"""
mutable struct Radar <: Equipment
    name::Symbol
    location::NTuple{2,Float64}
    "all shots that can currently be seen by the radar (independent of tracking)"
    available::Union{Nothing,Store{Shot}}
    "TBD"
    av::Dict # maybe better for counting
    "duration of the scan (limited emission time for tactical purposes: ≤ 30 secondes) "
    scantime::TimePeriod
    "resource used for the number of simultaneous targets we can track"
    trackers::Union{Nothing,ConcurrentSim.Resource}
    "missions that can be generated go here"
    missions::Union{Nothing,Store{FiringMission}}
    "owner of the sensor (who gets the information)"
    owner::Union{Nothing, Unit}
    "frequency between evaluations of the current sky"
    freq::TimePeriod
end

Base.show(io::IO, r::Radar) = print(io, "radar sensor $(r.name) @$(r.location) owned by $(r.owner)")

Radar(; name::Symbol=:radarpost_1, location::NTuple{2,Float64}=(0., 0.),
        available::Union{Nothing,Store{Shot}}=nothing, 
        av=Dict(), 
        scantime::TimePeriod=Second(60),
        trackers::Union{Nothing,ConcurrentSim.Resource}=nothing,
        missions::Union{Nothing,Store{FiringMission}}=nothing,
        freq::TimePeriod=Second(1)) = Radar(name, location,available, av, scantime, trackers, missions, nothing, freq)



Base.show(io::IO, m::FiringMission) = print(io, "FM-$(m.id) ($(m.nshots) shots on $(m.target), generated at $(Dates.format(m.timestamp,"YYYY-mm-dd HH:MM:SS"))")

FiringMission(; id::String="1", 
                timestamp::DateTime=now(), 
                target::NTuple{2,Float64}=(1000.,1000.),
                nshots::Int=10) = FiringMission(id, timestamp, target, nshots)

"""
    Platoon(canons::Vector{Canon};Pl::Char='A', By::Int=100)

contains a number of canons and has an identifier
"""
mutable struct Platoon <: Unit
    "platoon identifier"
    Pl::Char
    "battery identifier"
    By::Int
    "all the canons in the platoon (used for synchronous movement and firing)"
    canons::Vector{Canon}
    "firing mission to be executed by the platoon"
    missions::Union{Nothing,Store{FiringMission}}
    #"regrouping zone"
   # regroup
end

Base.show(io::IO, p::Platoon) = print(io, """$(p.Pl) Pl ($(p.By) By, $(length(p.canons)) canons) """)
Platoon(canons::Vector{Canon};Pl::Char='A', By::Int=100) = Platoon(Pl, By, canons, nothing)
Platoon(sim::Environment, canons::Vector{Canon};Pl::Char='A', By::Int=100) = Platoon(Pl, By, canons, Store{FiringMission}(sim))

"""
    Battery(platoons::Vector{Platoon}; By::Int=100,
        missions::Union{Nothing,Store{FiringMission}}=nothing,
        accousticobserver::Union{Nothing, Acoustic}=nothing,
        radarobserver::Union{Nothing, Acoustic}=nothing)

contains a number of platoons and has an identifier. Also contains the sensor(s) who are one the lookout for shots from this battery (this is the inverse problem)
"""
mutable struct Battery <: Unit
    "battery identifier"
    By::Int
    "all the platoons in the battery (used for synchronous movement and firing)"
    Pls::Vector{Platoon}
    "firing mission to be executed by the battery (can be devided and tasked to separate platoons)"
    missions::Union{Nothing,Store{FiringMission}}
    "acoustic sensor that is listening to this battery"
    accousticobserver::Union{Nothing, Acoustic}
    "radar sensor that is listening to this battery"
    radarobserver::Union{Nothing, Radar}
end

Base.show(io::IO, b::Battery) = print(io, """$(b.By) By ($(length(b.Pls)) platoons)""")
Battery(platoons::Vector{Platoon}; By::Int=100,
        missions::Union{Nothing,Store{FiringMission}}=nothing,
        accousticobserver::Union{Nothing, Acoustic}=nothing,
        radarobserver::Union{Nothing, Radar}=nothing) = Battery(By, platoons, missions, accousticobserver, radarobserver)


"""
    Battlefield

keeps track of all elements in the battlefield and also used for logging effects.
"""
struct Battlefield
    elements::Vector{Equipment}
    status::Dict
    damage::Dict
    shotsfired::Dict
    missions::Vector{Tuple{DateTime, Battery, Int}}
end

"""
    Battlefield(sim::Environment, x::Battery...; kwargs...)

Generate a new battlefield for a simulation with multiple batteries.
"""
function Battlefield(sim::Environment, x::Battery...; kwargs...)
    elements = Vector{Equipment}()
    status = Dict()
    damage = Dict()
    shotsfired = Dict()
    missions = Vector{Tuple{DateTime, Battery, Int}}()
    #totalhealth = Tuple{Vector{TimePeriod}, Vector{Float64}}
    for By in x
        for Pl in By.Pls
            for canon in Pl.canons
                push!(elements, canon)
                status[canon] = [(nowDatetime(sim), canon.health)]
                damage[canon] = [(nowDatetime(sim), 0.)]
            end
        end
        shotsfired[By.By] = typeof(nowDatetime(sim))[]
    end

    return Battlefield(elements, status, damage, shotsfired, missions)#, Tuple{Vector{TimePeriod}, Vector{Float64}}())
end

"""
    Battlefield_evolution()

plot the evolution of a `Battlefield` over time, containing multiple Batteries
"""
function Battlefield_evolution(bf::Battlefield)
    pal = palette(:default)
    # process data - health status
    Hplot = Plots.plot(title="Health status", ylims=[0;1], yticks=(collect(0:0.125:1)))
    Bycolor = Dict()
    tmin = nothing
    tmax = nothing
    for canon in bf.elements
        col = get!(Bycolor, canon.By,length(Bycolor)+1) # nice color
        ts = [x[1] for x in bf.status[canon]]
        if isnothing(tmin)
            tmin = floor(minimum(ts),Hour)
        else
            tmin =  floor(minimum(ts),Hour) < tmin ? floor(minimum(ts),Hour) : tmin
        end
        if isnothing(tmax)
            tmax = ceil(maximum(ts),Hour)
        else
            tmax =  ceil(maximum(ts),Hour) > tmax ? ceil(maximum(ts),Hour) : tmax
        end
        hs = [x[2] for x in bf.status[canon]]
        plot!(Hplot, ts, hs, 
                linetype=:steppost, linecolor=pal[col], 
                marker=:circle, markerfill=pal[col],
                label="Canon $(canon.ID) ($(canon.Pl) Pl, $(canon.By) By)")
    end
    tticks = collect(tmin : Hour(1) : tmax)
    @warn tticks
    plot!(xticks=(tticks, Dates.format.(tticks, "HH:MM:SS")), xrot=60,
            xlims=(tmin, tmax))
    
    

    # process data - shots fired
    Splot = Plots.plot(title="shots fired")
    tmin = nothing
    tmax = nothing
    for by in keys(bf.shotsfired)
        if isnothing(tmin)
            tmin = floor(minimum(bf.shotsfired[by]),Hour)
        else
            tmin =  floor(minimum(bf.shotsfired[by]),Hour) < tmin ? floor(minimum(bf.shotsfired[by]),Hour) : tmin
        end
        if isnothing(tmax)
            tmax = ceil(maximum(bf.shotsfired[by]),Hour)
        else
            tmax =  ceil(maximum(bf.shotsfired[by]),Hour) > tmax ? ceil(maximum(bf.shotsfired[by]),Hour) : tmax
        end
        plot!(bf.shotsfired[by], collect(1:length(bf.shotsfired[by])),
              linetype=:steppost, linecolor=pal[Bycolor[by]],
              label="$(by) By)")
              
        tticks = collect(tmin : Hour(1) : tmax)
        @warn tticks
        plot!(xticks=(tticks, Dates.format.(tticks, "HH:MM:SS")), xrot=60,
                      xlims=(tmin, tmax))
    end
    Plots.plot(Hplot, Splot)
    

    # Proces data - Radar missions
    #plot(Rplot) = plot(title="N° missions in radar")
end

## General functions
"""
    Emissiongenerator(sim::Environment, b::Battery)

Function that generates random missions for the enemy (not aimed at us specifically).

Runs a firing missions every one or two hours

TO DO: make it more random
"""

@resumable function Emissiongenerator(sim::Environment, b::Battery; nshots::Union{Int, UnitRange{Int64}}=50:100)
    mid = 0
    while true
        @debug """$(Dates.format(nowDatetime(sim),"YYYY-mm-dd HH:MM:SS")) current EBy capacity: $(capacity(b))
        Firing capacity: $([capacity(c) for pl in b.Pls for c in pl.canons ])
        Mobility status: $([ismobile(c) for pl in b.Pls for c in pl.canons ])
        """
        @yield timeout(sim, Hour(2))
        if capacity(b) <= h_stop
            @error "$(Dates.format(nowDatetime(sim),"YYYY-mm-dd HH:MM:SS")) [$(rpad("Emission",namewidth))] - STOPPING (NO MORE FIRING CAPACITY FOR EBy)"
            throw(ConcurrentSim.StopSimulation("$(b) has no remaining firing capacity"))
            #return
        end
        mid += 1
        mission = FiringMission("$(mid)", nowDatetime(sim), (rand(-2000.:-1000.), rand(-3000.:-2000.)), isa(nshots, Int) ? nshots : rand(nshots))
        @info "$(Dates.format(nowDatetime(sim),"YYYY-mm-dd HH:MM:SS")) [$(rpad("Emission",namewidth))] - new enemy mission generated: $(mission)"
        @yield put(b.missions, mission)
    end
end

"""
    isvalid(sim::Environment, m::FiringMission)

Analyse if a firing mission is still valid ("shelf life") not expired
"""
isvalid(sim::Environment, m::FiringMission) = nowDatetime(sim) < m.timestamp + t_valid

"""
    batterycycle(sim::Environment, b::Battery)

simulates the cycle of a battery: 
1. acquiring mission
2. tasking platoons
3. platoons FFE:
    - go to ready Posn from waiting zone
    - from ready Posn: FFE
    - regroup to Zone Pl
    - Mov in By to new locations, prepare next mission
4. regroup @new location and continue mission/wait for new mission

If a mission is seen a lot later than its creation date, we discard it
"""

@resumable function batterycycle(sim::Environment, BF::Battlefield, b::Battery; Δtmax::TimePeriod=Minute(5))
    while true
        @info "$(Dates.format(nowDatetime(sim),"YYYY-mm-dd HH:MM:SS")) [$(rpad("By $(b.By)",namewidth))] - started new cycle"
        # get the mission(s)
        mission = @yield @process getmissions(sim, b)
        @info "$(Dates.format(nowDatetime(sim),"YYYY-mm-dd HH:MM:SS")) [$(rpad("By $(b.By)",namewidth))] - new mission: $(mission)"
        ## task mission(s) to platoons
        @yield @process missionscheduler(sim, b, mission)
        ## fire for effect
        FFE = [@process platooncycle(sim, BF, b, pl) for pl in b.Pls]
        @info """$(Dates.format(nowDatetime(sim),"YYYY-mm-dd HH:MM:SS")) [$(rpad("By $(b.By)",namewidth))] - FFE call given
        Firing capacity: $([capacity(c) for pl in b.Pls for c in pl.canons ])
        health statys:   $([c.health for pl in b.Pls for c in pl.canons ])
        Mobility status: $([ismobile(c) for pl in b.Pls for c in pl.canons ])
        """
        @yield Operator(ConcurrentSim.eval_and, FFE...)
        @info "$(Dates.format(nowDatetime(sim),"YYYY-mm-dd HH:MM:SS")) [$(rpad("By $(b.By)",namewidth))] - FFE call finished"
        ## Mov new location
        movers = [@process move(sim, pl) for pl in b.Pls]
        @yield Operator(ConcurrentSim.eval_and, movers...)
    end
end

@resumable function platooncycle(sim::Environment, BF::Battlefield, b::Battery, p::Platoon)
    @info """$(Dates.format(nowDatetime(sim),"YYYY-mm-dd HH:MM:SS")) [$(rpad("Pl $(p.Pl)",namewidth))] - Platoon received mission
    current taskings: $(p.missions.items)
    """
    # get mission if available
    if length(p.missions.items) > 0
        mission = @yield get(p.missions)
        # schedule mission over canons
        to_fire = missionscheduler(sim, p, mission)
        # POSSIBLE EXTENSION: spread out the fires of the canons instead of focussing on one location 
        FFEpl = [@process canoncycle(sim, BF, b, p.canons[i], to_fire[i], mission) for i in eachindex(to_fire) if !iszero(to_fire[i])]
        @yield Operator(ConcurrentSim.eval_and, FFEpl...)
    end
    
    @info "$(Dates.format(nowDatetime(sim),"YYYY-mm-dd HH:MM:SS")) [$(rpad("Pl $(p.Pl) ($(p.By) By)",namewidth))] - Platoon completed mission"
end

"""
    getmissions(sim::Environment, b::Battery)

Helper function used for selecting the missions and sending them to the battery, takes into consideration
    the capacity of the battery, the validity of the firing mission(s) and the time window during which we observe
    before calling the FFE.

    This generates a problem locking the simulation
"""

@resumable function getmissions(sim::Environment, b::Battery)
    missions = FiringMission[]
    to_restore = FiringMission[]
    # wait for new mission
    mission = @yield get(b.missions)
    
    while true
        if isvalid(sim, mission)
            @debug "current mission is valid! $(nowDatetime(sim)), $(mission.timestamp)"
            break
        else
            @debug "$(Dates.format(nowDatetime(sim),"YYYY-mm-dd HH:MM:SS")) [$(rpad("By $(b.By)",namewidth))] - previous mission $(mission) was not valid, waiting for a more recent one..."
            mission = @yield get(b.missions)
        end
    end
    
    # if current mission requirements surpass battery capacity => stop 
    if mission.nshots > capacity(b)
        #retval = @yield mission
        return mission
    end

    return mission
end

prepare(c::Canon) = gettime(c.canontype.inactiontime)
reload(c::Canon)  = gettime(c.canontype.reloadtime)
breakup(c::Canon) = gettime(c.canontype.outactiontime)

gettime(x::TimePeriod) = x
gettime(f::Function) = throw(MethodError("`gettime` not implemented for functions",f))
gettime(d::T) where T<:Distribution{Univariate, Continuous} = rand(d)



"""
    impactpoint(pos, target, ct)

Given my current position, a target and a canontype, determine the coordinates of a random impact point.

NOTE: currently this is not random, all impactpoints have a fixed value depending on the type of canon.
"""
function impactpoint(pos::NTuple{2,Float64}, target::NTuple{2,Float64}, ct::CanonType)
    # determine angle θ
    θ = atan((target[2]-pos[2])/(target[1]-pos[1]))
    if target[1]-pos[1] < 0
        θ = pi + θ
    end
    if target[2]-pos[2] < 0
        θ = 2*pi + θ
    end
    # determine impact point in local reference frame (x',y') % TO MODIFY
    #xᵢ, yᵢ = ct.PED, ct.PER
    yᵢ, xᵢ = rand(ct.impactdist)
    ϕ = θ - pi/2
    # determine impact point in orthogonal global frame
    xᵢ, yᵢ = xᵢ*cos(ϕ) - yᵢ*sin(ϕ) + target[1], xᵢ*sin(ϕ) + yᵢ*cos(ϕ) + target[2]
        
    return xᵢ, yᵢ
end

canfire(c::Canon) = c.health > h_ops
ismobile(c::Canon) = c.health > 0.


@resumable function canoncycle(sim::Environment, BF::Battlefield, b::Battery, c::Canon, nshots::Int, m::FiringMission)
    @debug "$(Dates.format(nowDatetime(sim),"YYYY-mm-dd HH:MM:SS")) [$(rpad("Pl $(c.Pl), Canon $(c.ID)",namewidth))] - Firing! ($(nshots) shots)"
    # process order - prepare firing
    @yield timeout(sim, prepare(c))
    # starting firing
    for i = 1:nshots
        if canfire(c) # check the canon has not been killed in the meantime
            c.nshots += 1
            # MAKE ACTUAL SHOT & launch it's process
            @process fire(sim, BF, b, Shot( id=c.nshots, 
                                        c=c, 
                                        target=m.target, 
                                        timestamp=nowDatetime(sim)))
            # reload
            @yield timeout(sim, reload(c))
        else
            @warn "$(Dates.format(nowDatetime(sim),"YYYY-mm-dd HH:MM:SS")) [$(rpad("Pl $(c.Pl), Canon $(c.ID)",namewidth))] - can no longer fire)"
            break
        end
    end
    if ismobile(c)
        # break up
        @yield timeout(sim, breakup(c))
        # join regrouping zone (move function)
    end
    @debug "$(Dates.format(nowDatetime(sim),"YYYY-mm-dd HH:MM:SS")) [$(rpad("Pl $(c.Pl), Canon $(c.ID)",namewidth))] - canon cycle complete"
end

"""
    actionfinder(b::Battery, s::Shot; detection_ratio=0.15)

For a `Shot` fired from a `Battery`, determine the timings of the different possible actions. If
no sensor are observing the `Battery`, only the impact will be evaluated.

The returned actions are symbols and the retured timings are time intervals between the actions.

The `detection_ratio` determines when a `Shot` can be seen by the radar (hypotheses: due to terrain
and trajectory, this is limited to 70% of the flight time by default)
"""
function actionfinder(b::Battery, s::Shot; detection_ratio=0.15)
    # get absolute timings
    actions = [:impact]
    timings = [s.tof]
    if !isnothing(b.accousticobserver)
        push!(actions, :acoustic)
        push!(timings, Millisecond(round(Int,d(b.accousticobserver.location, s.canon.location) / v_sound * 1000)))
    end
    if !isnothing(b.radarobserver)
        push!(actions, :radarvis)
        push!(timings, Millisecond(round(Int,detection_ratio * s.tof.value)))
        push!(actions, :radarnonvis)
        push!(timings, Millisecond(round(Int,(1-detection_ratio) * s.tof.value)))
    end
    
    if length(actions) > 1
        # sort timings
        tind = sortperm(timings)
        actions = actions[tind]
        timings = timings[tind]
        # staggered timings
        timings = vcat(timings[1], diff(timings))
    end

    return (actions, timings)
end

"""
    fire(sim::Environment, b::Battery, s::Shot)

Fire a shot. If there is a sensor listening to the Battery, send a signal to the sensor
"""

@resumable function fire(sim::Environment, BF::Battlefield, b::Battery, s::Shot)
    @debug "$(Dates.format(nowDatetime(sim),"YYYY-mm-dd HH:MM:SS")) [$(rpad("$(s.canon)", namewidth))] - shot $(s.id) fired"
    push!(BF.shotsfired[s.canon.By], nowDatetime(sim))

    # observe what event happens when
    (actions, timings) = actionfinder(b, s)

    for i in eachindex(actions)
        @yield timeout(sim, timings[i])
        if isequal(actions[i], :acoustic)	
            @process acousticdetection(sim, BF, b, s)
        elseif isequal(actions[i], :impact)
            @process impactassessment(sim, BF, s)
        elseif isequal(actions[i], :radarvis)
            @process radarvisible(sim, b, s)
        elseif isequal(actions[i], :radarnonvis)
            @process radarnonvisible(sim, b, s)
        end
    end
end

"""
    lineardamage(pos::NTuple{2, Float64}, s::Shot)

damage function for effect of a `Shot`. Effect of the damage decreases linearly with distance 
from the impactpoint (d=0 => damage = 1, d = s.mun.maxlethalrange => damage = 0)
"""
function lineardamage(pos::NTuple{2, Float64}, s::Shot)
    return d(pos, s.impact) <= s.mun.maxlethalrange ? 1. - d(pos, s.impact)/s.mun.maxlethalrange : 0.
end

"""
    impactassessment(sim::Environment, bf::Battlefield, s::Shot)

Evaluate if a shot has hit a target and modify the health of the target accordingly.
"""

@resumable function impactassessment(sim::Environment, bf::Battlefield, s::Shot, damagemodel::Function=lineardamage)
    for victim in bf.elements
        if victim.health >= 0
            dam = damagemodel(victim.location, s)
            if iszero(dam)
                continue
            else
                # limit damage so health does not become negative
                dam = victim.health - dam > 0 ? dam : victim.health
                # update status
                victim.health -= dam
                @info "$(Dates.format(nowDatetime(sim),"YYYY-mm-dd HH:MM:SS")) [$(rpad("DAMAGE ASSESMENT", namewidth))] - impact of -$(dam) on $(victim) "
                push!(bf.status[victim], (nowDatetime(sim),victim.health))
                push!(bf.damage[victim], (nowDatetime(sim), dam))
            end
        end
    end
end

"""
    acousticdetection(sim::Environment, s::Shot)

Triggers the accoustic detection process for a shot fired from a battery.
"""

@resumable function acousticdetection(sim::Environment, BF::Battlefield, b::Battery, s::Shot)
    @info "$(Dates.format(nowDatetime(sim),"YYYY-mm-dd HH:MM:SS")) [$(rpad("$(b.accousticobserver)", namewidth))] - trigger by sound from $(s)"
    #@warn "acoustic detection of shot << $(s) >> by $(b.accousticobserver.owner)"
    if !isnothing(b.radarobserver)
        if b.radarobserver.trackers.level < b.radarobserver.trackers.capacity
            @info "$(Dates.format(nowDatetime(sim),"YYYY-mm-dd HH:MM:SS")) [$(rpad("$(b.accousticobserver)", namewidth))] - tasking radar"
            @yield request(b.radarobserver.trackers)
            @yield @process radarscan(sim, BF, b.radarobserver, s, b.accousticobserver.owner)
            @yield release(b.radarobserver.trackers)
        else
            @info "$(Dates.format(nowDatetime(sim),"YYYY-mm-dd HH:MM:SS")) [$(rpad("$(b.accousticobserver)", namewidth))] - no radar capacity available"
        end
    else
        @info "$(Dates.format(nowDatetime(sim),"YYYY-mm-dd HH:MM:SS")) [$(rpad("$(b.accousticobserver)", namewidth))] - no radar available"
    end
end


"""
    radarvisible(sim::Environment, b::Battery, s::Shot)

makes a shot visible for tracking radar
"""

@resumable function radarvisible(sim::Environment, b::Battery, s::Shot)
    @debug """$(Dates.format(nowDatetime(sim),"YYYY-mm-dd HH:MM:SS")) [$(rpad("RADARVISIBLE",namewidth))] - shot $(s.id) visible for radar"""
    b.radarobserver.av[s.canon] = get!(b.radarobserver.av, s.canon, 0) + 1
end

"""
    radarnonvisible(sim::Environment, b::Battery, s::Shot)

makes a shot visible for tracking radar
"""

@resumable function radarnonvisible(sim::Environment, b::Battery, s::Shot)
    @debug """$(Dates.format(nowDatetime(sim),"YYYY-mm-dd HH:MM:SS")) [$(rpad("RADARNONVISIBLE",namewidth))] - shot $(s.id) no longer visible for radar"""
    b.radarobserver.av[s.canon] = get!(b.radarobserver.av, s.canon, 0) - 1
end

"""
    radarscan(sim::Environment, s::Shot, b::Battery)

Simulation of the radar actually scanning the sky. This results in a firing mission for the `Battery` based on 
the `Shot` that was fired.

In the current implementation, the radar gives the exact point of origin of the shot,
and does not take into considaration higher precision of the estimate if more shots are seen
during the observation period.
"""

@resumable function radarscan(sim::Environment, BF::Battlefield,  r::Radar, s::Shot, b::Battery; 
                                locationfinder::Function=perfectlocationfinder)
    @info """$(Dates.format(nowDatetime(sim),"YYYY-mm-dd HH:MM:SS")) [$(rpad("RADARSCAN",namewidth))] - radar was triggered by shot $(s.id) from canon $(s.canon)..."""
    # max number of times shot from specific canon has been seen
    n_max_from_piece = 0
    tstart = nowDatetime(sim)
    while nowDatetime(sim) <= tstart + r.scantime
        @yield timeout(sim, r.freq)
        n_max_from_piece = get!(r.av, s.canon,0) > n_max_from_piece ? r.av[s.canon] : n_max_from_piece
    end
    # generate FiringMission for origin of the Shot
    @yield put(b.missions, FiringMission(id="CBy mission",
                                    timestamp=nowDatetime(sim),
                                    target=locationfinder(r, s, n_max_from_piece), 
                                    nshots=cb_shots))
    # store timing of mission generation
    push!(BF.missions,(nowDatetime(sim), b ,length(b.missions.items)))
end

"""
    perfectlocationfinder(r::Radar, s::Shot, Nobs::Int) = (s.canon.location[1], s.canon.location[2]) # new Tuple to avoid always knowing the location of the target

function to determine the point of origin of a `Shot` by a `Radar` given a number of observed shots.
"""
perfectlocationfinder(r::Radar, s::Shot, Nobs::Int) = (s.canon.location[1], s.canon.location[2]) # new Tuple to avoid always knowing the location of the target

"""
    missionscheduler(sim::Environment, b::Battery, mission::FiringMission)

function that dispatches a battery-level firing mission to the platoons composing the battery. 
Pieces who are no longer operational are unable to fire. The firing mission will be distributed in such a way 
that firing duration for each platoon should be similar. If the battery mission cannot be executed in 
a single pass, it will be split into multiple parts to fire from multiple locations.
"""

@resumable function missionscheduler(sim::Environment, b::Battery, mission::FiringMission)
    @info "$(Dates.format(nowDatetime(sim),"YYYY-mm-dd HH:MM:SS")) [$(rpad("By $(b.By) SCHEDULER", namewidth))] - dispatching mission to platoons"
    #@info "$(Dates.format(nowDatetime(sim),"YYYY-mm-dd HH:MM:SS")) [$(rpad("By $(b.By)",namewidth))] - new mission: $(mission)"
    # get current platoons capacity
    pl_caps = map(pl -> capacity(pl), b.Pls)
    by_cap = capacity(b)
    # evaluate still able to fire
    if by_cap <= h_stop
        @warn "$(Dates.format(nowDatetime(sim),"YYYY-mm-dd HH:MM:SS")) [$(rpad("By $(b.By) SCHEDULER", namewidth))] - NO MORE FIRING CAPACITY!"
        #@yield ConcurrentSim.stop_simulation(sim)
        throw(ConcurrentSim.StopSimulation("$(b) has no remaining firing capacity"))
        return
    end
    # evaluate if split required
    if mission.nshots > by_cap
        @warn "$(Dates.format(nowDatetime(sim),"YYYY-mm-dd HH:MM:SS")) [$(rpad("By $(b.By) SCHEDULER", namewidth))] - mission requires multiple missions"
        @yield put(b.missions, FiringMission(   id="$(mission.id)bis",
                                                target=mission.target, 
                                                timestamp=nowDatetime(sim),
                                                nshots=mission.nshots - by_cap))
    end
    # split mission over platoons (propertional to capacity)
    to_fire = ceil.(Int, min(mission.nshots, by_cap) * pl_caps / by_cap)
    #@error min(mission.nshots, by_cap) * pl_caps / by_cap
    @debug "$(Dates.format(nowDatetime(sim),"YYYY-mm-dd HH:MM:SS")) [$(rpad("By $(b.By) SCHEDULER", namewidth))] - TO FIRE: $(to_fire)"
    # index largest amount to fire
    fix_ind = argmax(to_fire) 
    #@error fix_ind
    # Avoid firing more or less shots than required due to rounding errors
    to_fire[fix_ind] = min(mission.nshots, by_cap) - sum(to_fire) + to_fire[fix_ind] 
    #@error to_fire
    #@warn "TO FIRE: $(to_fire)"
    # dispatch mission to platoons
    for i in eachindex(to_fire)
        if !iszero(to_fire[i])
            @yield put(b.Pls[i].missions, FiringMission(id="$(mission.id)-Pl$(i)",
                                                        target=mission.target,
                                                        timestamp=nowDatetime(sim),
                                                        nshots=to_fire[i]))
        end
    end
end

function missionscheduler(sim::Environment, p::Platoon, m::FiringMission)
    @info "$(Dates.format(nowDatetime(sim),"YYYY-mm-dd HH:MM:SS")) [$(rpad("Pl $(p.Pl) SCHEDULER", namewidth))] - dispatching missions to canons"
    # capacity per canon
    c_caps = [capacity(c) for c in p.canons]
    # split mission over canons
    to_fire = round.(Int, m.nshots * c_caps / sum(c_caps))
   # @warn
    
    # index largest amount to fire
    fix_ind = argmax(to_fire) 
    # Avoid firing more or less shots than required due to rounding errors
    to_fire[fix_ind] = m.nshots - sum(to_fire) + to_fire[fix_ind] 
    #@error "TO FIRE for $(p) = $(to_fire)"
    return to_fire
end

"""
    capacity(u<:Unit)

Evaluate the current firing capacity (based on basic load) of a unit. Only includes
canons that are still mission capable, i.e. their health status is superior to 
the predefined constant `h_ops`.
"""
capacity(b::Battery) = mapreduce(p -> capacity(p), +, b.Pls)
capacity(p::Platoon) = mapreduce(c -> capacity(c), +, p.canons)
capacity(c::Canon) = c.health > h_ops ? c.canontype.BL : 0


nextpos(c::Canon) = c.current_pos + 1 <= length(c.posn) ? (c.current_pos + 1) : 1

"""
    move(sim::Environment, c::Canon, newpos::NTuple{2, Float64})

moves a canon to a new position, accounts for possible mobility kills
"""

@resumable function move(sim::Environment, c::Canon, newpos::Union{Nothing,NTuple{2, Float64}}=nothing)
    if !ismobile(c)
        return
    end
    # determine next point if none provided
    if isnothing(newpos)
        futurepos = nextpos(c)
        newpos = c.posn[futurepos]
    end
    # determine angle to location
    θ = angle(c.location, newpos)
    # project velocity vector, scaled to Millisecond resolution
    v_proj = (c.canontype.v_mov/1000*cos(θ), c.canontype.v_mov/1000*sin(θ))
    # total duration of moving [in ms]
    Δt = d(c.location, newpos) / c.canontype.v_mov * 1000
    # number of timesteps and final timestep
    Nsteps, δt_final = Δt ÷ timeres.value, Millisecond(round(Int,Δt % timeres.value))
    # actual moving (fixed steps and remainder in time)
    for i = 1:Nsteps
        if ismobile(c) # check for mobility kill
            @yield timeout(sim, timeres)
            c.location = (c.location[1] + v_proj[1]*1000, c.location[2] + v_proj[2]*1000)
        else
            return
        end
    end

    if ismobile(c)
        @yield timeout(sim, δt_final)
        c.location = newpos
        c.current_pos = futurepos
    end
end

"""
    move(sim::Environment, p::Platoon)

move an entire platoon to their new locations. Uses the predefined locations within the canons
"""

@resumable function move(sim::Environment, p::Platoon)
    movers = [@process move(sim,c) for c in filter(ismobile,p.canons)]# if ismobile(c)]
    if length(movers) > 0
        @yield Operator(ConcurrentSim.eval_and, movers...)
    end
end


########################################################
########################################################
#                       demo functions                 #
########################################################
########################################################

"""
    oneVSone()

CBy demo with one friendly and one adversary canons, no movement
"""
function oneVSone()
    
    ### Define simulation
    sim = Simulation(now())
    
    ### Battle order
    ## Friends
    # Equipment used
    FMunType = MunType(name=:USM1HE, maxlethalrange=50.0, v_muzzle=485.)
    FCanType = CanonType(name=:GIAT, PED=12., PER=15., BL=20, mun=FMunType, 
                            reloadtime=Second(5), 
                            outactiontime=Second(60), 
                            inactiontime=Second(60))
    # Tactical elements
    FCanon = Canon(id=1, Pl='A', By=158, ctype=FCanType,posn=[(0.,0.)]) # a single canon
    FPlatoons = [Platoon(sim, [FCanon], Pl='A',By=158)] 						  # in a single platoon
    Fmissions = Store{FiringMission}(sim)								  # missions for our battery
    acc_obs = Acoustic(name=:acoustic158, location=(100., 100.)) 		  # our acoustic sensor, not owned yet (!)
    rdr_obs = Radar(name=:radar158, location=(-100.,100.),  			  # our radar, not owned yet (!)
                    available=Store{Shot}(sim),
                    missions=Fmissions,
                    trackers=ConcurrentSim.Resource(sim, 1)
                    )
    FBy = Battery(FPlatoons, By=158, missions=Fmissions) 
    acc_obs.owner = FBy
    rdr_obs.owner = FBy

    
    ## Foes
    # Equipment used
    EMunType = MunType(name=:rocket, maxlethalrange=40.0, v_muzzle=500.)
    ECanType = CanonType(name=:GRAD, PED=50., PER=100., BL=40, mun=EMunType, 
                            reloadtime=Second(10), 
                            outactiontime=Second(70), 
                            inactiontime=Second(70))
    # Tactical elements
    ECanon = Canon(id=1, Pl='χ', By=10, ctype=ECanType,posn=[(7000.,8000.)]) # a single canon
    EPlatoons = [Platoon(sim,[ECanon], Pl='χ',By=10)] 						       # in a single platoon
    EBy = Battery(EPlatoons, By=10,                                     # enemy By, linked to our observers
                  missions=Store{FiringMission}(sim), 				       
                 accousticobserver=acc_obs,
                 radarobserver=rdr_obs) 
    
    ## Battlefield
    BF = Battlefield(sim, EBy, FBy)

    
    ### Missions
    ## Friends => Counter-By
    @process batterycycle(sim, BF, FBy)
    
    ## Foe => random taskings by Emissiongenerator
    @process Emissiongenerator(sim, EBy) # this generates missions for the enemy battery
    @process batterycycle(sim, BF, EBy)		 # this makes the battery do its thing (i.e. tasking to specific platoons)
    

 @info """
    Runing 1 Vs 1 demo

    Friends: $(FBy), $(ncanons(FBy)) canon(s), capacity: $(capacity(FBy)) shots
    Foes:    $(EBy), $(ncanons(EBy)) canon(s), capacity: $(capacity(EBy)) shots

    """

    run(sim, now()+Hour(3))
    

    return BF
end

function ncanons(b::Battery)
    mapreduce(length, sum, [pl.canons for pl in b.Pls])
end
"""
    oneVStwo()

CBy demo with one friendly and two adversary canons, no movement
"""
function oneVStwo()
    @info """
    Runing 1 Vs 2 demo

    """
    ### Define simulation
    sim = Simulation(now())
    
    ### Battle order
    ## Friends
    # Equipment used
    FMunType = MunType(name=:USM1HE, maxlethalrange=50.0, v_muzzle=485.)
    FCanType = CanonType(name=:GIAT, PED=12., PER=15., BL=20, mun=FMunType, 
                            reloadtime=Second(5), 
                            outactiontime=Second(60), 
                            inactiontime=Second(60))
    # Tactical elements
    FCanon = Canon(id=1, Pl='A', By=158, ctype=FCanType,posn=[(0.,0.)]) # a single canon
    FPlatoons = [Platoon(sim, [FCanon], Pl='A',By=158)] 						  # in a single platoon
    Fmissions = Store{FiringMission}(sim)								  # missions for our battery
    acc_obs = Acoustic(name=:acoustic158, location=(100., 100.)) 		  # our acoustic sensor, not owned yet (!)
    rdr_obs = Radar(name=:radar158, location=(-100.,100.),  			  # our radar, not owned yet (!)
                    available=Store{Shot}(sim),
                    missions=Fmissions,
                    trackers=ConcurrentSim.Resource(sim, 1)
                    )
    FBy = Battery(FPlatoons, By=158, missions=Fmissions) 
    acc_obs.owner = FBy
    rdr_obs.owner = FBy

    
    ## Foes
    # Equipment used
    EMunType = MunType(name=:rocket, maxlethalrange=40.0, v_muzzle=500.)
    ECanType = CanonType(name=:GRAD, PED=50., PER=100., BL=40, mun=EMunType, 
                            reloadtime=Second(10), 
                            outactiontime=Second(70), 
                            inactiontime=Second(70))
    # Tactical elements
    ECanons = [ Canon(id=1, Pl='χ', By=10, ctype=ECanType,posn=[(7000.,8000.)]);
                Canon(id=2, Pl='χ', By=10, ctype=ECanType,posn=[(7300.,8200.)])] # two enemy canons
    EPlatoons = [Platoon(sim, ECanons, Pl='χ',By=10)] 						       # in a single platoon
    EBy = Battery(EPlatoons, By=10,                                     # enemy By, linked to our observers
                  missions=Store{FiringMission}(sim), 				       
                 accousticobserver=acc_obs,
                 radarobserver=rdr_obs) 
    
    ## Battlefield
    BF = Battlefield(sim, EBy, FBy)

    
    ### Missions
    ## Friends => Counter-By
    @process batterycycle(sim, BF, FBy)
    
    ## Foe => random taskings by Emissiongenerator
    @process Emissiongenerator(sim, EBy) # this generates missions for the enemy battery
    @process batterycycle(sim, BF, EBy)		 # this makes the battery do its thing (i.e. tasking to specific platoons)
    
    ### Some logging settings
    mylogger = ConsoleLogger(stdout)
    ### Execute!
    with_logger(mylogger) do
        @info "Starting..."

        run(sim, now()+Hour(10))
        
    end
    @info EBy.missions.items
    @info [pl.missions.items for pl in EBy.Pls]
    @info FBy.missions.items
    return BF
end



"""
    minimover(sim::Environment, c::Canon)

helper functions the for canon moving demos demo
"""

@resumable function minimover(sim::Environment, c::Canon)
    for _ = 1:4
        @yield @process move(sim, c)
    end
end

@resumable function minimover(sim::Environment, p::Platoon)
    for _ = 1:4
        @info "$(nowDatetime(sim)) :\n$(prod(["canon $(c)\n" for c in p.canons]))"
        @yield @process move(sim, p)
    end
end

"""
    oneCanonmover()

Demo of a single canon moving
"""
function oneCanonmover()

    ### Define simulation
    sim = Simulation(now())
    
    ### Battle order
    ## Friends
    # Equipment used
    FMunType = MunType(name=:USM1HE, maxlethalrange=50.0, v_muzzle=485.)
    FCanType = CanonType(name=:GIAT, PED=12., PER=15., BL=20, mun=FMunType, 
                            reloadtime=Second(5), 
                            outactiontime=Second(60), 
                            inactiontime=Second(60))
    # Tactical elements: single canon with three main locations
    FCanon = Canon(id=1, Pl='A', By=158, ctype=FCanType,posn=[(0., 0.); (100., 0.); (50., 100.)])
    @info FCanon.canontype.v_mov
    
    # activate
    @process minimover(sim, FCanon)
    run(sim)
end

"""
    onePlmover()

Demo of a single platoon moving
"""
function onePlmover()
    ### Define simulation
    sim = Simulation(now())
    
    ### Battle order
    ## Friends
    # Equipment used
    FMunType = MunType(name=:USM1HE, maxlethalrange=50.0, v_muzzle=485.)
    FCanType = CanonType(name=:GIAT, PED=12., PER=15., BL=20, mun=FMunType, 
                            reloadtime=Second(5), 
                            outactiontime=Second(60), 
                            inactiontime=Second(60))
    # Tactical elements: single canon with three main locations
    FCanons = [ Canon(id=1, Pl='A', By=158, ctype=FCanType,posn=[(0., 0.); (100., 0.); (50., 100.)]);
                Canon(id=2, Pl='A', By=158, ctype=FCanType,posn=[(10., 0.); (115., 5.); (35., 100.)])]
    
    FP = Platoon(FCanons, Pl='A', By=158)
    # activate
    @process minimover(sim, FP)
    run(sim)
end

function twoVStwoMove()
    @info """
    Runing 2 Vs 2 demo with movement

    """
    ### Define simulation
    sim = Simulation(now())
    
    ### Battle order
    ## Friends
    # Equipment used
    FMunType = MunType(name=:USM1HE, maxlethalrange=50.0, v_muzzle=485.)
    FCanType = CanonType(name=:GIAT, PED=12., PER=15., BL=20, mun=FMunType, 
                            reloadtime=Second(5), 
                            outactiontime=Second(60), 
                            inactiontime=Second(60))
    # Tactical elements
    FCanons = [ Canon(id=1, Pl='A', By=158, ctype=FCanType,posn=[(0.,0.); (1000., 0.)] );
                Canon(id=2, Pl='A', By=158, ctype=FCanType,posn=[(50.,50.); (960., 30.)] )
                ]
    FPlatoons = [Platoon(sim, FCanons, Pl='A',By=158)] 						  # a single platoon with two canons
    Fmissions = Store{FiringMission}(sim)								  # missions for our battery
    acc_obs = Acoustic(name=:acoustic158, location=(100., 100.)) 		  # our acoustic sensor, not owned yet (!)
    rdr_obs = Radar(name=:radar158, location=(-100.,100.),  			  # our radar, not owned yet (!)
                    available=Store{Shot}(sim),
                    missions=Fmissions,
                    trackers=ConcurrentSim.Resource(sim, 1), scantime=Second(10)
                    )
    FBy = Battery(FPlatoons, By=158, missions=Fmissions) 
    acc_obs.owner = FBy
    rdr_obs.owner = FBy

    ## Foes
    # Equipment used
    EMunType = MunType(name=:rocket, maxlethalrange=40.0, v_muzzle=500.)
    ECanType = CanonType(name=:GRAD, PED=50., PER=100., BL=40, mun=EMunType, 
                            reloadtime=Second(10), 
                            outactiontime=Second(70), 
                            inactiontime=Second(70))
    # Tactical elements
    ECanons = [ Canon(id=1, Pl='χ', By=10, ctype=ECanType,posn=[(7000.,8000.); (7800., 8100.)]);
                Canon(id=2, Pl='χ', By=10, ctype=ECanType,posn=[(7300.,8200.); (7900., 8300.)])] # two enemy canons
    EPlatoons = [Platoon(sim, ECanons, Pl='χ',By=10)] 						       # in a single platoon
    EBy = Battery(EPlatoons, By=10,                                     # enemy By, linked to our observers
                  missions=Store{FiringMission}(sim), 				       
                 accousticobserver=acc_obs,
                 radarobserver=rdr_obs) 
    
    ## Battlefield
    BF = Battlefield(sim, EBy, FBy)

    
    ### Missions
    ## Friends => Counter-By
    @process batterycycle(sim, BF, FBy)
    
    ## Foe => random taskings by Emissiongenerator
    @process Emissiongenerator(sim, EBy) # this generates missions for the enemy battery
    @process batterycycle(sim, BF, EBy)		 # this makes the battery do its thing (i.e. tasking to specific platoons)
    
    ### Some logging settings
    mylogger = ConsoleLogger(stdout)
    ### Execute!
    with_logger(mylogger) do
        @info "Starting..."

        run(sim, now()+Hour(10))
        
    end
    @info EBy.missions.items
    @info [pl.missions.items for pl in EBy.Pls]
    @info FBy.missions.items
    return BF, EBy, FBy
end

"""
    fulldeployment()

Standard scenario with full deployment. 
12 (BEL) GIAT vs 6 (RUS) GRAD, all are moving. Both batteries use a 
"fire and scoot" strategy i.e. after a single barrage, they switch locations

The enemy runs a FFE mission every two hours, where they fire between 50 and 100 shots towards
a specific target.

returns a `Battlefield` that can be used for further analysis.
"""
function fulldeployment(;   N_F_Main=3,     # number of friendly main battery locations (1≤n≤3) 
                            N_F= 12,        # number of friendly pieces 
                            N_Pl_F=4,       # number of pieces per friendly platoon
                            d_F = 100,      # distance between friendly pieces
                            N_E_Main=3,     # number of enemy main battery locations (1≤n≤3) 
                            N_E = 6,        # number of enemy pieces,
                            N_Pl_E=3,       # number of pieces per enemy platoon
                            d_E =  50,      # distance between enemy locations
                            Flethalrange=50.,
                            FMunType = MunType(name=:USM1HE, maxlethalrange=Flethalrange, v_muzzle=485.),
                            FCanType = CanonType(name=:GIAT, PED=12., PER=15., BL=20, mun=FMunType, 
                                                reloadtime=Second(5), 
                                                outactiontime=Second(60), 
                                                inactiontime=Second(60)),
                            Elethalrange=40.,
                            EMunType = MunType(name=:rocket, maxlethalrange=Elethalrange, v_muzzle=500.),
                            ECanType = CanonType(name=:GRAD, PED=50., PER=100., BL=40, mun=EMunType, 
                                                    reloadtime=Second(10), 
                                                    outactiontime=Second(70), 
                                                    inactiontime=Second(70)),
                            kwargs...)
                            
    
    @info """
    full deployment demo with the following non-default settings:
    $(kwargs)
    """
    ### Define simulation
    sim = Simulation(now())

    ### Orientation
    ## Main battery locations
    FMainLocations_X, FMainLocations_Y = positiongenerator(1000., 1000.)
    EMainLocations_X, EMainLocations_Y = positiongenerator(2000., 9000.)
    ## global angle
    θ_glob = angle((mean(FMainLocations_X[1:N_F_Main]),mean(FMainLocations_Y[1:N_F_Main])), (mean(EMainLocations_X[1:N_E_Main]),mean(EMainLocations_Y[1:N_E_Main])))
    ## individual locations
    # N_F = 12 # number of friendly pieces
    #n_Pl_F = 4 # number of pieces per platoon
    #N_E = 6  # number of enemy pieces
    #n_Pl_E = 3
    #d_F = 100 # distance between friendly locations
    #d_E =  50 # distance between enemy locations
    pos_F = [linecoordinates(loc..., d_F, N_F, angle=θ_glob)  for loc in zip(FMainLocations_X[1:N_F_Main], FMainLocations_Y[1:N_F_Main])]
    pos_E = [linecoordinates(loc..., d_E, N_E, angle=-θ_glob) for loc in zip(EMainLocations_X[1:N_E_Main], EMainLocations_Y[1:N_E_Main])]

    ### Battle order
    ## Friends
    # Equipment used
    #FMunType = MunType(name=:USM1HE, maxlethalrange=Flethalrange, v_muzzle=485.)
    #FCanType = CanonType(name=:GIAT, PED=12., PER=15., BL=20, mun=FMunType, 
    #                        reloadtime=Second(5), 
    #                        outactiontime=Second(60), 
    #                        inactiontime=Second(60))
    # Tactical elements
    FCanons = [Canon(id=v, 
                     Pl=Char(65 + ((v-1) ÷ N_Pl_F)), 
                     By=158, 
                     ctype=FCanType,
                     posn=[pos_F[n][v] for n = 1:length(pos_F)]) for v in 1:N_F ]
    FPlatoons = [Platoon(sim, collect(subset); Pl=subset[1].Pl, By=158) for subset in Iterators.partition(FCanons, N_Pl_F)]
    Fmissions = Store{FiringMission}(sim)								    # missions for our battery

    acc_obs = Acoustic(name=:acoustic158, location=(1500., 6000.)) 		    # our acoustic sensor, not owned yet (!)
    rdr_obs = Radar(name=:radar158, location=(0.,2000.),  			        # our radar, not owned yet (!)
                    available=Store{Shot}(sim),
                    missions=Fmissions,
                    trackers=ConcurrentSim.Resource(sim, 1), scantime=Second(10) # 10 second scantime
                    )
    FBy = Battery(FPlatoons, By=158, missions=Fmissions) 
    acc_obs.owner = FBy
    rdr_obs.owner = FBy

    ## Foes
    # Equipment used
    #EMunType = MunType(name=:rocket, maxlethalrange=40.0, v_muzzle=500.)
    #ECanType = CanonType(name=:GRAD, PED=50., PER=100., BL=40, mun=EMunType, 
    #                        reloadtime=Second(10), 
    #                        outactiontime=Second(70), 
    #                        inactiontime=Second(70))
    # Tactical elements
    ECanons = [Canon(id=v, 
                     Pl=Char(966 + ((v-1) ÷ N_Pl_E)), 
                     By=10, 
                     ctype=ECanType,
                     posn=[pos_E[n][v] for n = 1:length(pos_E)]) for v in 1:N_E ]
    EPlatoons = [Platoon(sim, collect(subset); Pl=subset[1].Pl, By=10) for subset in Iterators.partition(ECanons, N_Pl_E)]
    EBy = Battery(  EPlatoons, By=10,                                     # enemy By, linked to our observers
                    missions=Store{FiringMission}(sim), 				       
                    accousticobserver=acc_obs,
                    radarobserver=rdr_obs) 

    ## Battlefield
    BF = Battlefield(sim, EBy, FBy)
    
    ### Missions
    ## Friends => Counter-By
    @process batterycycle(sim, BF, FBy)
    
    ## Foe => random taskings by Emissiongenerator
    @process Emissiongenerator(sim, EBy) # this generates missions for the enemy battery
    @process batterycycle(sim, BF, EBy)		 # this makes the battery do its thing (i.e. tasking to specific platoons)

    ### Some logging settings
    #mio = open("detaillog.txt", "w+")
    #mylogger = SimpleLogger(mio)
    
    ### Execute!
    #with_logger(mylogger) do
        @info "Starting..."

        run(sim)#, now()+Day(15))

        @info """overview:
        Firing capacity: $([capacity(c) for pl in EBy.Pls for c in pl.canons ])
        health status:   $([c.health for pl in EBy.Pls for c in pl.canons ])
        Mobility status: $([ismobile(c) for pl in EBy.Pls for c in pl.canons ])

        """
    #end
    #@info EBy.missions.items
    #@info [pl.missions.items for pl in EBy.Pls]
    #@info EBy.missions.items

    #@warn rdr_obs.freq, rdr_obs.scantime
    #close(mio)
    return BF, EBy, FBy

end

function limitedcaptest()
    @info """
    Runing limited capacity test
    """
    ### Define simulation
    sim = Simulation(now())

    ## Foes
    # Equipment used
    EMunType = MunType(name=:rocket, maxlethalrange=40.0, v_muzzle=500.)
    ECanType = CanonType(name=:GRAD, PED=50., PER=100., BL=40, mun=EMunType, 
                            reloadtime=Second(10), 
                            outactiontime=Second(70), 
                            inactiontime=Second(70))
    ECanType2 = CanonType(name=:GRAD, PED=50., PER=100., BL=23, mun=EMunType, 
                            reloadtime=Second(10), 
                            outactiontime=Second(70), 
                            inactiontime=Second(70))
    # Tactical elements
    ECanons = [ Canon(id=1, Pl='χ', By=10, ctype=ECanType,posn=[(7000.,8000.)]);
                Canon(id=2, Pl='χ', By=10, ctype=ECanType,posn=[(7300.,8200.)], health=0.1); 
                Canon(id=3, Pl='ϕ', By=10, ctype=ECanType,posn=[(7500.,8000.)]);
                Canon(id=4, Pl='ϕ', By=10, ctype=ECanType2,posn=[(7600.,8200.)], health=0.45)] # four enemy canons
    EPlatoons = [Platoon(sim, ECanons[1:2], Pl='χ',By=10);
                 Platoon(sim, ECanons[3:4], Pl='ϕ',By=10)] 						       # in a single platoon
    EBy = Battery(EPlatoons, By=10,                                     # enemy By, linked to our observers
                  missions=Store{FiringMission}(sim))#=, 				       
                 accousticobserver=acc_obs,
                 radarobserver=rdr_obs) =#
    
    ## Battlefield
    BF = Battlefield(sim, EBy)

    [capacity(c) for pl in EBy.Pls for c in pl.canons ]
    
    ### Missions
    @process Emissiongenerator(sim, EBy,nshots=160) # this generates missions for the enemy battery
    @process batterycycle(sim, BF, EBy)		 # this makes the battery do its thing (i.e. tasking to specific platoons)
    
    ### Some logging settings
    mylogger = ConsoleLogger(stdout)
    ### Execute!
    with_logger(mylogger) do
        @info "Starting..."

        run(sim, now()+Hour(3))
        
    end
    #@info EBy.missions.items
    #@info [pl.missions.items for pl in EBy.Pls]
    #@info FBy.missions.items
    return BF, EBy, FBy
end

"""
    totalhealth(BF)

Represent the evolution of the total health of a single battery during the simulation

returns (Vector{TimePeriod}, Vector{Float64})
"""
function totalhealth(BF, By=10)
    # extract elements for the battery
    elements = filter(x->x.By == By, BF.elements)
    # store cumulative damage
    cum_dam = Dict{DateTime, Float64}()
    for c in elements
        for point in BF.damage[c]
            cum_dam[point[1]] = get!(cum_dam, point[1], 0.) + point[2]
        end
    end
    # return x,y
    intres = sort([(moment, dam) for (moment, dam) in cum_dam], by=x->x[1])
    x = [v[1] for v in intres]
    y = [v[2] for v in intres]
    #@error "MAX y val: $(maximum(cumsum(y) ./ length(elements)))"
    return x - x[1], cumsum(y) ./ length(elements)
end

"""
    totalshots(BF)

Represent the evolution of the total numer of shots fired of a single battery during the simulation

returns (Vector{TimePeriod}, Vector{Float64})
"""
function totalshots(BF, By=10)
    x = BF.shotsfired[By] - BF.shotsfired[By][1]
    y = collect(1:length(x))
    return x, y
end

"""
    multianalysis(scenario::Function, n=10)

run a specific scenario `n` times and provide data to make an illustration
"""
function multianalysis(scenario::Function, n=10;kwargs...)
    # operationality - not used yet
    t_inops = Vector{Float64}(undef, n)
    t_destroyed = Vector{Float64}(undef, n)
    tvec = Vector{Int64}(undef, n)
    # damage taken
    t_dam = Dict{Int,Vector{Float64}}()
    dam =   Dict{Int,Vector{Float64}}()
    # shots fired
    t_s = Dict{Int,Vector{Float64}}()
    s =   Dict{Int,Vector{Int64}}()
    for i in 1:n
        # run single simulation
        res, _, _ = scenario(;kwargs...)
        # part linked to damage over time eval
        for bat in [10; 158]
            # damage taken
            x,y = totalhealth(res, bat)
            append!(get!(t_dam, bat, Float64[]), map(v->v.value/(1000*60*60),x))
            append!(get!(dam, bat, Float64[])  , y*100)
            # shots fired
            xs,ys = totalshots(res, bat)
            append!(get!(t_s, bat, Float64[]), map(v->v.value/(1000*60*60),xs))
            append!(get!(s,   bat, Int64[]  ), ys)
        end
        tvec[i] = length(res.shotsfired[158])
    end

    return t_dam, dam, t_s, s, tvec
end

#res = twoVStwoMove();Battlefield_evolution(res)
#res, _, _ = fulldeployment();

function multideployment(N_runs=100)
    # global runs
    res_t, res_dam, t_s, s = multianalysis(fulldeployment, N_runs)
    res_t2, res_dam2, t_s2, s2 = multianalysis(fulldeployment, N_runs, 
                                        N_f=12,N_F_Main=1,Flethalrange=50.)
    res_t3, res_dam3, t_s3, s3 = multianalysis(fulldeployment, N_runs, 
                                        N_f=12,N_F_Main=1,Flethalrange=100.)

                                
    # demo health status
    p = plot(title="Damage sustained \n(standard GRAD By, $(N_runs) simulations)", legend=:bottomright)
    scatter!(p, res_t[10], res_dam[10], label="default (3 Posn, lethal range = 50))", marker=:+)
    scatter!(p, res_t2[10], res_dam2[10], label="1 Posn, lethal range = 50", marker=:x)
    scatter!(p, res_t3[10], res_dam3[10], label="1 Posn, lethal range = 100", marker=:+)
    xlabel!(p, "Time [Hr]")
    ylabel!(p, "Enemy Battery damage [%]")

    # demo shots
    p2 = plot(title="Ammunition requirements \n(GIAT By, $(N_runs) simulations)", legend=:bottomright)
    scatter!(p2, t_s[158], s[158], label="default (3 Posn, lethal range = 50))", marker=:+)
    scatter!(p2, t_s2[158], s2[158], label="1 Posn, lethal range = 50", marker=:x)
    scatter!(p2, t_s3[158], s3[158], label="1 Posn, lethal range = 100", marker=:+)
    xlabel!(p2, "Time [Hr]")
    ylabel!(p2, "Friendly shots fired")

    # global picture
    Pfin = plot(p,p2,layout=(2,1), size=(800,800))
    xlims!([-0.5;12.5]...)
    xticks!(collect(0:2.5:12.5))
    return Pfin
end

"""
    multiCDF(scenario::Function; n::Int=10,kwargs...)

For a given scenario, compute the distribution of time to mobility kill and time to no longer operational
"""
function multiCDF(scenario::Function; n::Int=10,kwargs...)
	rangemaker(x) = range(minimum(x)*0.9, maximum(x)*1.1,length=1000)
	
	# disable logmsg
	Logging.disable_logging(Logging.Error)
	# initiate
	res_mobkill = zeros(Int, n) # time before mobility kill (in seconds)
	res_inops = zeros(Int, n)   # time before out of action (in seconds)
	# run all simulations
	for i = eachindex(res_inops)
		resBF,_,_ = scenario(;kwargs...)
		t,dam = totalhealth(resBF)
		ind_mobkill, inops_ind = findfirst(v->v>=1/2, dam), findfirst(v->v>=2/3, dam)
		res_mobkill[i] = round(t[ind_mobkill], Second).value
		res_inops[i] = round(t[inops_ind], Second).value
	end
	# generate expCDF	
	xmobkil = rangemaker(res_mobkill)
	xinops  = rangemaker(res_inops)
	mobkil_cdf, inops_cdf = ecdf(res_mobkill), ecdf(res_inops);

	# reset logging
	Logging.disable_logging(Logging.Debug)
	return xmobkil, res_mobkill, mobkil_cdf, xinops, res_inops, inops_cdf
end


"""
    scenario_1()

First scenario to consider: classic FA vs classic FA
"""
function scenario_1()
    # define Equipment
    Flethalrange = 50.
    FMunType = MunType(name=:USM1HE, maxlethalrange=Flethalrange, v_muzzle=485.)
    FCanType = CanonType(name=:GIAT, PED=12., PER=15., BL=20, mun=FMunType, 
                        reloadtime=Second(5), 
                        outactiontime=Second(60), 
                        inactiontime=Second(60))
    Elethalrange=40.
    EMunType = MunType(name=:rocket, maxlethalrange=Elethalrange, v_muzzle=500.)
    ECanType = CanonType(name=:GRAD, PED=50., PER=100., BL=40, mun=EMunType, 
                        reloadtime=Second(10), 
                        outactiontime=Second(70), 
                        inactiontime=Second(70))

    # define simulation
    ### Define simulation
    sim = Simulation(now())

    ### Orientation
    N_F_Main=3     # number of friendly main battery locations (1≤n≤3) 
    N_E_Main=3     # number of enemy main battery locations (1≤n≤3) 
    ## Main battery locations
    FMainLocations_X, FMainLocations_Y = positiongenerator(1000., 1000.)
    EMainLocations_X, EMainLocations_Y = positiongenerator(2000., 9000.)
    ## global angle
    θ_glob = angle((mean(FMainLocations_X[1:N_F_Main]),mean(FMainLocations_Y[1:N_F_Main])), (mean(EMainLocations_X[1:N_E_Main]),mean(EMainLocations_Y[1:N_E_Main])))
    ## individual locations
    N_F = 12 # number of friendly pieces
    N_Pl_F = 4 # number of pieces per platoon
    N_E = 6  # number of enemy pieces
    N_Pl_E = 3
    d_F = 100 # distance between friendly locations
    d_E =  50 # distance between enemy locations
    pos_F = [linecoordinates(loc..., d_F, N_F, angle=θ_glob)  for loc in zip(FMainLocations_X[1:N_F_Main], FMainLocations_Y[1:N_F_Main])]
    pos_E = [linecoordinates(loc..., d_E, N_E, angle=-θ_glob) for loc in zip(EMainLocations_X[1:N_E_Main], EMainLocations_Y[1:N_E_Main])]

    ### Battle order
    ## Friends
    FCanons = [Canon(id=v, 
                     Pl=Char(65 + ((v-1) ÷ N_Pl_F)), 
                     By=158, 
                     ctype=FCanType,
                     posn=[pos_F[n][v] for n = 1:length(pos_F)]) for v in 1:N_F ]
    FPlatoons = [Platoon(sim, collect(subset); Pl=subset[1].Pl, By=158) for subset in Iterators.partition(FCanons, N_Pl_F)]
    Fmissions = Store{FiringMission}(sim)								    # missions for our battery

    acc_obs = Acoustic(name=:acoustic158, location=(1500., 6000.)) 		    # our acoustic sensor, not owned yet (!)
    rdr_obs = Radar(name=:radar158, location=(0.,2000.),  			        # our radar, not owned yet (!)
                    available=Store{Shot}(sim),
                    missions=Fmissions,
                    trackers=ConcurrentSim.Resource(sim, 1), scantime=Second(10) # 10 second scantime
                    )
    FBy = Battery(FPlatoons, By=158, missions=Fmissions) 
    acc_obs.owner = FBy
    rdr_obs.owner = FBy
    ## Foes
    ECanons = [Canon(id=v, 
    Pl=Char(966 + ((v-1) ÷ N_Pl_E)), 
    By=10, 
    ctype=ECanType,
    posn=[pos_E[n][v] for n = 1:length(pos_E)]) for v in 1:N_E ]
    EPlatoons = [Platoon(sim, collect(subset); Pl=subset[1].Pl, By=10) for subset in Iterators.partition(ECanons, N_Pl_E)]
    EBy = Battery(  EPlatoons, By=10,                                     # enemy By, linked to our observers
                    missions=Store{FiringMission}(sim), 				       
                    accousticobserver=acc_obs,
                    radarobserver=rdr_obs)
    ## Battlefield
    BF = Battlefield(sim, EBy, FBy)
    
    ### Missions
    ## Friends => Counter-By
    @process batterycycle(sim, BF, FBy)
    
    ## Foes => random taskings by Emissiongenerator
    @process Emissiongenerator(sim, EBy) # this generates missions for the enemy battery
    @process batterycycle(sim, BF, EBy)	      
    
    ## Run simulation
    run(sim, now()+Hour(20))

    return BF

end

"""
    scenario_2()

Second scenario to consider: classic FA vs Mobile Aie
"""
function scenario_2()
    # define Equipment
    Flethalrange = 50.
    FMunType = MunType(name=:USM1HE, maxlethalrange=Flethalrange, v_muzzle=485.)
    FCanType = CanonType(name=:GIAT, PED=12., PER=15., BL=20, mun=FMunType, 
                        reloadtime=Second(5), 
                        outactiontime=Second(60), 
                        inactiontime=Second(60))
    Elethalrange=40.
    EMunType = MunType(name=:rocket, maxlethalrange=Elethalrange, v_muzzle=500.)
    ECanType = CanonType(name=:GRAD, PED=50., PER=100., BL=40, mun=EMunType, 
                        reloadtime=Second(5), 
                        outactiontime=Second(30), 
                        inactiontime=Second(30))

    # define simulation
    ### Define simulation
    sim = Simulation(now())

    ### Orientation
    N_F_Main=3     # number of friendly main battery locations (1≤n≤3) 
    N_E_Main=3     # number of enemy main battery locations (1≤n≤3) 
    ## Main battery locations
    FMainLocations_X, FMainLocations_Y = positiongenerator(1000., 1000.)
    EMainLocations_X, EMainLocations_Y = positiongenerator(2000., 9000.)
    ## global angle
    θ_glob = angle((mean(FMainLocations_X[1:N_F_Main]),mean(FMainLocations_Y[1:N_F_Main])), (mean(EMainLocations_X[1:N_E_Main]),mean(EMainLocations_Y[1:N_E_Main])))
    ## individual locations
    N_F = 12 # number of friendly pieces
    N_Pl_F = 4 # number of pieces per platoon
    N_E = 6  # number of enemy pieces
    N_Pl_E = 3
    d_F = 100 # distance between friendly locations
    d_E =  50 # distance between enemy locations
    pos_F = [linecoordinates(loc..., d_F, N_F, angle=θ_glob)  for loc in zip(FMainLocations_X[1:N_F_Main], FMainLocations_Y[1:N_F_Main])]
    pos_E = [linecoordinates(loc..., d_E, N_E, angle=-θ_glob) for loc in zip(EMainLocations_X[1:N_E_Main], EMainLocations_Y[1:N_E_Main])]

    ### Battle order
    ## Friends
    FCanons = [Canon(id=v, 
                     Pl=Char(65 + ((v-1) ÷ N_Pl_F)), 
                     By=158, 
                     ctype=FCanType,
                     posn=[pos_F[n][v] for n = 1:length(pos_F)]) for v in 1:N_F ]
    FPlatoons = [Platoon(sim, collect(subset); Pl=subset[1].Pl, By=158) for subset in Iterators.partition(FCanons, N_Pl_F)]
    Fmissions = Store{FiringMission}(sim)								    # missions for our battery

    acc_obs = Acoustic(name=:acoustic158, location=(1500., 6000.)) 		    # our acoustic sensor, not owned yet (!)
    rdr_obs = Radar(name=:radar158, location=(0.,2000.),  			        # our radar, not owned yet (!)
                    available=Store{Shot}(sim),
                    missions=Fmissions,
                    trackers=ConcurrentSim.Resource(sim, 1), scantime=Second(10) # 10 second scantime
                    )
    FBy = Battery(FPlatoons, By=158, missions=Fmissions) 
    acc_obs.owner = FBy
    rdr_obs.owner = FBy
    ## Foes
    ECanons = [Canon(id=v, 
    Pl=Char(966 + ((v-1) ÷ N_Pl_E)), 
    By=10, 
    ctype=ECanType,
    posn=[pos_E[n][v] for n = 1:length(pos_E)]) for v in 1:N_E ]
    EPlatoons = [Platoon(sim, collect(subset); Pl=subset[1].Pl, By=10) for subset in Iterators.partition(ECanons, N_Pl_E)]
    EBy = Battery(  EPlatoons, By=10,                                     # enemy By, linked to our observers
                    missions=Store{FiringMission}(sim), 				       
                    accousticobserver=acc_obs,
                    radarobserver=rdr_obs)
    ## Battlefield
    BF = Battlefield(sim, EBy, FBy)
    
    ### Missions
    ## Friends => Counter-By
    @process batterycycle(sim, BF, FBy)
    
    ## Foes => random taskings by Emissiongenerator
    @process Emissiongenerator(sim, EBy) # this generates missions for the enemy battery
    @process batterycycle(sim, BF, EBy)	      
    
    ## Run simulation
    run(sim, now()+Hour(20))

    return BF

end

"""
    scenario_3()

Third scenario to consider: classic FA vs Mobile Aie
"""
function scenario_3()
    # define Equipment
    Flethalrange = 50.
    FMunType = MunType(name=:USM1HE, maxlethalrange=Flethalrange, v_muzzle=485.)
    FCanType = CanonType(name=:GIAT, PED=12., PER=15., BL=20, mun=FMunType, 
                        reloadtime=Second(5), 
                        outactiontime=Second(60), 
                        inactiontime=Second(60))
    Elethalrange=40.
    EMunType = MunType(name=:rocket, maxlethalrange=Elethalrange, v_muzzle=500.)
    ECanType = CanonType(name=:GRAD, PED=50., PER=100., BL=40, mun=EMunType, 
                        reloadtime=Second(1), 
                        outactiontime=Second(5), 
                        inactiontime=Second(5))

    # define simulation
    ### Define simulation
    sim = Simulation(now())

    ### Orientation
    N_F_Main=3     # number of friendly main battery locations (1≤n≤3) 
    N_E_Main=3     # number of enemy main battery locations (1≤n≤3) 
    ## Main battery locations
    FMainLocations_X, FMainLocations_Y = positiongenerator(1000., 1000.)
    EMainLocations_X, EMainLocations_Y = positiongenerator(2000., 9000.)
    ## global angle
    θ_glob = angle((mean(FMainLocations_X[1:N_F_Main]),mean(FMainLocations_Y[1:N_F_Main])), (mean(EMainLocations_X[1:N_E_Main]),mean(EMainLocations_Y[1:N_E_Main])))
    ## individual locations
    N_F = 12 # number of friendly pieces
    N_Pl_F = 4 # number of pieces per platoon
    N_E = 6  # number of enemy pieces
    N_Pl_E = 3
    d_F = 100 # distance between friendly locations
    d_E =  50 # distance between enemy locations
    pos_F = [linecoordinates(loc..., d_F, N_F, angle=θ_glob)  for loc in zip(FMainLocations_X[1:N_F_Main], FMainLocations_Y[1:N_F_Main])]
    pos_E = [linecoordinates(loc..., d_E, N_E, angle=-θ_glob) for loc in zip(EMainLocations_X[1:N_E_Main], EMainLocations_Y[1:N_E_Main])]

    ### Battle order
    ## Friends
    FCanons = [Canon(id=v, 
                     Pl=Char(65 + ((v-1) ÷ N_Pl_F)), 
                     By=158, 
                     ctype=FCanType,
                     posn=[pos_F[n][v] for n = 1:length(pos_F)]) for v in 1:N_F ]
    FPlatoons = [Platoon(sim, collect(subset); Pl=subset[1].Pl, By=158) for subset in Iterators.partition(FCanons, N_Pl_F)]
    Fmissions = Store{FiringMission}(sim)								    # missions for our battery

    acc_obs = Acoustic(name=:acoustic158, location=(1500., 6000.)) 		    # our acoustic sensor, not owned yet (!)
    rdr_obs = Radar(name=:radar158, location=(0.,2000.),  			        # our radar, not owned yet (!)
                    available=Store{Shot}(sim),
                    missions=Fmissions,
                    trackers=ConcurrentSim.Resource(sim, 1), scantime=Second(10) # 10 second scantime
                    )
    FBy = Battery(FPlatoons, By=158, missions=Fmissions) 
    acc_obs.owner = FBy
    rdr_obs.owner = FBy
    ## Foes
    ECanons = [Canon(id=v, 
    Pl=Char(966 + ((v-1) ÷ N_Pl_E)), 
    By=10, 
    ctype=ECanType,
    posn=[pos_E[n][v] for n = 1:length(pos_E)]) for v in 1:N_E ]
    EPlatoons = [Platoon(sim, collect(subset); Pl=subset[1].Pl, By=10) for subset in Iterators.partition(ECanons, N_Pl_E)]
    EBy = Battery(  EPlatoons, By=10,                                     # enemy By, linked to our observers
                    missions=Store{FiringMission}(sim), 				       
                    accousticobserver=acc_obs,
                    radarobserver=rdr_obs)
    ## Battlefield
    BF = Battlefield(sim, EBy, FBy)
    
    ### Missions
    ## Friends => Counter-By
    @process batterycycle(sim, BF, FBy)
    
    ## Foes => random taskings by Emissiongenerator
    @process Emissiongenerator(sim, EBy) # this generates missions for the enemy battery
    @process batterycycle(sim, BF, EBy)	      
    
    ## Run simulation
    run(sim, now()+Hour(20))

    return BF

end

function multisim(scenario::Function;n::Int=10,kwargs...)
    rangemaker(x) = range(minimum(x)*0.9, maximum(x)*1.1,length=1000)
	
	# disable logmsg
	Logging.disable_logging(Logging.Error)
	# initiate
	res_mobkill = zeros(n) # time before mobility kill (in seconds)
	res_inops = zeros(n)   # time before out of action (in seconds)
	# run all simulations
	for i = eachindex(res_inops)
		res = scenario()
		t,dam = totalhealth(res)
		ind_mobkill, inops_ind = findfirst(v->v>=1/2, dam), findfirst(v->v>=2/3, dam)
        # if none found, will never happen
		res_mobkill[i] = isnothing(ind_mobkill) ? Inf : round(t[ind_mobkill], Second).value
		res_inops[i] =   isnothing(inops_ind)   ? Inf : round(t[inops_ind], Second).value
	end
    # reset logging
	Logging.disable_logging(Logging.Debug)

    return res_mobkill, res_inops
end

function compare_scenarios(scenarios::Function...; kwargs...)
    mobkil = Dict{Symbol,Vector}()
    inops  = Dict{Symbol,Vector}()
    for scenario in scenarios
        smob, sinop = multisim(scenario; kwargs...)
        mobkil[Symbol(scenario)] = smob
        inops[Symbol(scenario)] =  sinop
    end

    p_mobkill = plot(xlabel="duration [Hr]", ylabel="probability", title="mobility kill",ylims=(0,1.))
    for (scen, vals) in mobkil
        nvalid = count(x->!isinf(x), vals)
        if iszero(nvalid)
            plot!(label="$(scen) ($(nvalid) successful trials)")
        else
            histogram!(vals./3600, normalize=:probability, linecolor=:match, 
                    label="$(scen) ($(nvalid) successful trials)", linealpha=0.5)
        end
    end

    p_inops = plot(xlabel="duration [Hr]", ylabel="probability", title="out of order",ylims=(0,1.))#, legend=:outertopright)
    for (scen, vals) in inops
        nvalid = count(x->!isinf(x), vals)
        if iszero(nvalid)
            plot!(label="$(scen) ($(nvalid) successful trials)")
        else
            histogram!(vals./3600, normalize=:probability, linecolor=:match, 
                    label="$(scen) ($(nvalid) successful trials)", linealpha=0.5)
        end
    end

    return p_mobkill, p_inops
end



"""
    sensor_scenario(d::Float64)

Run a simulation with an acoustic sensor at a specified distance from adversary
"""
function sensor_scenario(d::Float64)
    # define Equipment
    Flethalrange = 50.
    FMunType = MunType(name=:USM1HE, maxlethalrange=Flethalrange, v_muzzle=485.)
    FCanType = CanonType(name=:GIAT, PED=12., PER=15., BL=20, mun=FMunType, 
                        reloadtime=Second(5), 
                        outactiontime=Second(5), 
                        inactiontime=Second(20))
    Elethalrange=40.
    EMunType = MunType(name=:rocket, maxlethalrange=Elethalrange, v_muzzle=500.)
    ECanType = CanonType(name=:GRAD, PED=50., PER=100., BL=40, mun=EMunType, 
                        reloadtime=Second(5), 
                        outactiontime=Second(20), 
                        inactiontime=Second(20))

    # define simulation
    ### Define simulation
    sim = Simulation(now())

    ### Orientation
    N_F_Main=3     # number of friendly main battery locations (1≤n≤3) 
    N_E_Main=3     # number of enemy main battery locations (1≤n≤3) 
    ## Main battery locations
    FMainLocations_X, FMainLocations_Y = positiongenerator(1000., 1000.)
    EMainLocations_X, EMainLocations_Y = positiongenerator(2000., 9000.)
    ## global angle
    θ_glob = angle((mean(FMainLocations_X[1:N_F_Main]),mean(FMainLocations_Y[1:N_F_Main])), (mean(EMainLocations_X[1:N_E_Main]),mean(EMainLocations_Y[1:N_E_Main])))

    acc_location = (mean(EMainLocations_X[1:N_E_Main]) + d*cos(θ_glob), mean(EMainLocations_Y[1:N_E_Main]) + d*sin(θ_glob))

    #@info "distance: $(sqrt((acc_location[1] - mean(EMainLocations_X[1:N_E_Main]))^2 + (acc_location[2] - mean(EMainLocations_Y[1:N_E_Main]))^2))"
    ## individual locations
    N_F = 12 # number of friendly pieces
    N_Pl_F = 4 # number of pieces per platoon
    N_E = 6  # number of enemy pieces
    N_Pl_E = 3
    d_F = 100 # distance between friendly locations
    d_E =  50 # distance between enemy locations
    pos_F = [linecoordinates(loc..., d_F, N_F, angle=θ_glob)  for loc in zip(FMainLocations_X[1:N_F_Main], FMainLocations_Y[1:N_F_Main])]
    pos_E = [linecoordinates(loc..., d_E, N_E, angle=-θ_glob) for loc in zip(EMainLocations_X[1:N_E_Main], EMainLocations_Y[1:N_E_Main])]

    ### Battle order
    ## Friends
    FCanons = [Canon(id=v, 
                     Pl=Char(65 + ((v-1) ÷ N_Pl_F)), 
                     By=158, 
                     ctype=FCanType,
                     posn=[pos_F[n][v] for n = 1:length(pos_F)]) for v in 1:N_F ]
    FPlatoons = [Platoon(sim, collect(subset); Pl=subset[1].Pl, By=158) for subset in Iterators.partition(FCanons, N_Pl_F)]
    Fmissions = Store{FiringMission}(sim)								    # missions for our battery

    acc_obs = Acoustic(name=:acoustic158, location=acc_location) 		    # our acoustic sensor, not owned yet (!)
    rdr_obs = Radar(name=:radar158, location=(0.,2000.),  			        # our radar, not owned yet (!)
                    available=Store{Shot}(sim),
                    missions=Fmissions,
                    trackers=ConcurrentSim.Resource(sim, 1), scantime=Second(10) # 10 second scantime
                    )
    FBy = Battery(FPlatoons, By=158, missions=Fmissions) 
    acc_obs.owner = FBy
    rdr_obs.owner = FBy
    ## Foes
    ECanons = [Canon(id=v, 
    Pl=Char(966 + ((v-1) ÷ N_Pl_E)), 
    By=10, 
    ctype=ECanType,
    posn=[pos_E[n][v] for n = 1:length(pos_E)]) for v in 1:N_E ]
    EPlatoons = [Platoon(sim, collect(subset); Pl=subset[1].Pl, By=10) for subset in Iterators.partition(ECanons, N_Pl_E)]
    EBy = Battery(  EPlatoons, By=10,                                     # enemy By, linked to our observers
                    missions=Store{FiringMission}(sim), 				       
                    accousticobserver=acc_obs,
                    radarobserver=rdr_obs)
    ## Battlefield
    BF = Battlefield(sim, EBy, FBy)
    
    ### Missions
    ## Friends => Counter-By
    @process batterycycle(sim, BF, FBy)
    
    ## Foes => random taskings by Emissiongenerator
    @process Emissiongenerator(sim, EBy) # this generates missions for the enemy battery
    @process batterycycle(sim, BF, EBy)	      
    
    ## Run simulation
    run(sim, now()+Hour(20))

    return BF

end

function distance_study(drange,n::Int=10)
    # disable logmsg
	Logging.disable_logging(Logging.Error)

    p_inops = plot()
    #traces = []
    for d in drange    
        # initiate
        res_mobkill = zeros(n) # time before mobility kill (in seconds)
        res_inops = zeros(n)   # time before out of action (in seconds)
        # run all simulations
        for i = eachindex(res_inops)
            res = sensor_scenario(d)
            t,dam = totalhealth(res)
            ind_mobkill, inops_ind = findfirst(v->v>=1/2, dam), findfirst(v->v>=2/3, dam)
            # if none found, will never happen
            res_mobkill[i] = isnothing(ind_mobkill) ? Inf : round(t[ind_mobkill], Second).value
            res_inops[i] =   isnothing(inops_ind)   ? Inf : round(t[inops_ind], Second).value
        end
        #push!(traces, res_inops)
        #@logmsg LogLevel(10000) res_inops
        nvalid = count(x->!isinf(x), res_inops)
        if iszero(nvalid)
            boxplot!([0.;0], label="DNF")
        else
            valids = filter(isfinite,res_inops ./3600)
            boxplot!(valids, label="$(length(valids))/$(n) successes")
        end
    end
    plot!(xlabel="distance to enemy [m]", ylabel="time to non-operational [Hr]", title="sensor location",
                    xticks=(collect(1:length(drange)), ["$(round(Int,v))" for v in drange]))

    # reset logging
	Logging.disable_logging(Logging.Debug)
    return p_inops
end


function damage_evolution(bf::Battlefield)
    t,h = totalhealth(bf, 158)
	p = plot(t, h, linetype=:steppost, label="Friends",marker=:circle, color=:green, legend=:topleft)
	t,h = totalhealth(bf, 10)
	plot!(t, h, linetype=:steppost, label="Foes", color=:red, legend=:topleft)
	
	tval = map(x->x.value, t)
	xticks = collect(range(0, maximum(tval), length=3))
	xticks!(xticks)
	xticks!(xticks, ["$(round.(Millisecond.(round.(Int,x)), Hour))" for x in xticks])
	ylabel!("damage sustained [relative]")
	xlabel!("time")
	title!("Damage over time")

    return p
end