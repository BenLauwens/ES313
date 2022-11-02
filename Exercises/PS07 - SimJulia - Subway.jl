### A Pluto.jl notebook ###
# v0.19.14

using Markdown
using InteractiveUtils

# ╔═╡ 25686b8e-3002-413b-afa1-837676a90e71
begin
	using Pkg
	cd(joinpath(dirname(@__FILE__),".."))
    Pkg.activate(pwd())
	using Logging
	# for simulation
	using Distributions
	using SimJulia, ResumableFunctions
end

# ╔═╡ 08866503-14a2-4b5b-83ef-ae4518f4f195
html"""
 <! -- this adapts the width of the cells to display its being used on -->
<style>
	main {
		margin: 0 auto;
		max-width: 2000px;
    	padding-left: max(160px, 10%);
    	padding-right: max(160px, 10%);
	}
</style>
"""

# ╔═╡ 945097a6-569d-11ec-2abf-bb91b24a4fab
md"""
# Subway line
Study a subway line with a fixed number of stations (e.g. 10). We sill use simulation to:
* Analyze the robustness of train timetables.
* Estimate the capacity of the line.

## General framework
The two main variables come into play with respect to punctuality:
1. Runnning time: the trajectory time between two subsequent stops. In general this show less variability than the dwell times since they depend mainly on technical restrictions.
2. Dwell time: the time the train occupies the station. This is a random process that depends on the number and behaviour of the passengers as well as the action of closing the door and departure/take-off carried out manually by the drivers. In addition, these dwell times depend on the physical design of the station (width and length of the station, accesses to the platforms, etc.), since the passengers can concentrate in certain points of the station making access to the train difficult.

The passengers' arrival to the metro stations is also a random process, and the number of passengers waiting in the station for a train increases with the time interval between consecutive trains. If no control action is applied, when a delayed train arrives the number of passengers waiting at the station is increased, thus dwell time could be greater than nominal and the train delay increases also. This accumulated effect makes the system unstable, provoking, in turn, delays in the following trains and disruptions in the functioning of the line. These imbalances have to be corrected by means of control actions.

## Modelisation details
* Consider a closed metro circuit, i.e. the trains drive around in "circles". A person that gets on the metro has a probability to choose on of the destinations. You can use historical data to determine these.
* The trains a have a total capacity of $196+532$ places.
* To take into account the fact that there are trains driving in both directions, you should limit the stations that the people are selecting (i.e. they pick the shortest route).

## Objectives
* Basic: 
    * simulate a subway line, with a certain number of stops. 
    * At each stop an amount of people get on or of. If the wagon is full, people wait at the stop for the next one. For a trip to be comfortable (not cramped), the train should be below ``80\%`` of its maximal capacity.

* Advanced:
    * The build-up of people at each stop may depend on the time of day. Optimize the subway frequency to avoid people having to wait.
    * Are there times when a trip will always be uncomfortable?

* Challenges: 
    * Include more or less frequented stations, include delays linked to people trying to go above the maximal train capacity and the subsequent build-up of people and increased waiting times for the other stops.
"""

# ╔═╡ 59f44666-368b-460f-8082-58fb4e7d7a56
begin
	# all the stops in order with associated probabilities
	const stops = ["Bruxelles central","Parc","Arts-Loi","Maelbeek","Schuman", "Merode", "Montgomery"]
	const linedic = Dict(stops[i] => i for i in 1:length(stops))
	const sprob = [0.2, 0.1, 0.2, 0.1, 0.2, 0.05, 0.15]
	
	# own types
	"""Client of the subway network"""
	mutable struct Person
	    depature::String
	    destination::String
	end
	
	"""Station of the subway network"""
	mutable struct Station
	    name::String
	    queue::Store{Person}
	end
	
	"""The train carrying it all"""
	mutable struct Train
	    usage::Container
	    passengers::Dict{String,Int}
	    function Train(sim,N::Int)
	        train = new()
	        train.usage = SimJulia.Container(sim,N)
	        train.passengers = Dict(stops[i] => 0 for i in 1:length(stops))
	        return train
	    end
	end
end

# ╔═╡ 7e3f5306-cc3a-4c8b-b13f-d0dc57579a26
begin
# functions
	"""
	Returns a destination station from a given start point. 
	The returned station will be beyond the current one 
	Remark: currently only works for upward traffic.
	
	=> updated for cyclic use
	"""
	function stationselector(station::Station)
	    maxdim = length(stops)
	    # parameter for lookahead
	    nahead = maxdim÷2 + 1
	    # retrieve current position
	    pos = linedic[station.name]
	    # retrieve associated probabilities of the next stops
	    p = sprob[mapper.((pos+1):(pos+nahead),maxdim)] ./ sum(sprob[mapper.((pos+1):(pos+nahead),maxdim)])
	    # determine next stop
	    stops[mapper.(pos + rand(Categorical(p)),maxdim)]
	end
	
	
	"""to assure cyclic indices"""
	function mapper(x,maxdim)
	    ctl = x%maxdim
	    if ctl > 0
	        return ctl
	    elseif ctl <= 0
	        return maxdim+ctl
	    end
	end

	# Generating function
	"""Generates Persons in a station at a given rate (x per time unit) """
	
	@resumable function genpers(sim::Simulation, station::Station,rate=1)
	    while true
	        @yield timeout(sim,1/rate)
	        # new person
	        p = Person(station.name,stationselector(station))
	        # adding to the queue
	        put(station.queue, p)
	    end
	end
	
	@resumable function metro(sim::Simulation,train::Train,stoplist::Array{Station,1})
	    m = 1
	    while true
	        stop = stoplist[mapper(m,length(stoplist))]
	        @yield timeout(sim,10)
	        
	        # [to do: incorporate dwell time based on the 
	        #  characteristics of the platform, train usage etc.]
	        
	        #@info "currently @ $(stop.name) on time $(sim.time)"
	        # determine how many people get off and update available space
	        out = train.passengers[stop.name] 
	        train.usage.level -= out            # global occupation
	        train.passengers[stop.name] -= out  # levels per stop
	        #@info "$out people get off @ $(stop.name)"
	        # determine available space
	        free = train.usage.capacity - train.usage.level
	        #@info "$free people can get in @ $(stop.name)"
	        # determine who gets on to where
	        nwait = length(stop.queue.items)
	        #@info "Currently waiting @ $(stop.name): $(nwait)"
	        #@info "we should pick up $(min(free, nwait)) persons"
	        @info "Arriving @ $(stop.name) on time $(sim.time) ($(train.usage.level)/$(train.usage.capacity) used)
	    $out people get off @ $(stop.name)
	    $(nwait) people are waiting to get in @ $(stop.name)
	    There are $(free) available seats"
	        if nwait > free
	            @warn "More people waiting than there is available space @ $(stop.name)"
	        end
	        # embark all the persons currently at the station
	        for i in 1:min(free, nwait)
	            a = @yield get(stop.queue)
	            train.passengers[a.destination] += 1
	            train.usage.level += 1
	        end
	        m += 1
	    end
	end
end

# ╔═╡ c2f3335b-40df-4edf-83fb-1d09f7faf78f
begin
	sim = Simulation()
	# a single station and list
	stoplist = [Station(stops[i], Store{Person}(sim)) for i in 1:length(stops)]
	# a single train
	t = Train(sim,700)
	# client generation at each station
	for s in stoplist
	    @process genpers(sim,s,rand(Uniform(0,2)))
	end
	#running the train
	@process metro(sim,t,stoplist)
	run(sim,200)
end

# ╔═╡ Cell order:
# ╟─08866503-14a2-4b5b-83ef-ae4518f4f195
# ╟─25686b8e-3002-413b-afa1-837676a90e71
# ╟─945097a6-569d-11ec-2abf-bb91b24a4fab
# ╠═59f44666-368b-460f-8082-58fb4e7d7a56
# ╠═7e3f5306-cc3a-4c8b-b13f-d0dc57579a26
# ╠═c2f3335b-40df-4edf-83fb-1d09f7faf78f
