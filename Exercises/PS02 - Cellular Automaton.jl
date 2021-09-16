### A Pluto.jl notebook ###
# v0.16.0

using Markdown
using InteractiveUtils

# ╔═╡ 5312be7e-edd8-11ea-34b0-7581fc4b7126
begin
	using Pkg
	cd(joinpath(dirname(@__FILE__),".."))
    Pkg.activate(pwd())
    using Distributions, LinearAlgebra, Plots, InteractiveUtils
	using PlutoUI
end

# ╔═╡ a813912a-edb3-11ea-3b13-23da723cb488
md"""
# Cellular Automaton - Langton's Loops
## General description
Langton's loops are a particular "species" of artificial life in a 2D cellular automaton created in 1984 by Christopher Langton. They consist of a loop of cells containing genetic information, which flows continuously around the loop and out along an "arm" (or pseudopod), which will become the daughter loop. The "genes" instruct it to make three left turns, completing the loop, which then disconnects from its parent.

A single cell has 8 possible states (0,1,...,7). Each of these values can be interpreted a shown below:

|state|role|color|description|
|-----|----|-----|-----------|
| 0 | background | black | empty state |
| 1 | core | blue | fill tube & 'conduct' |
| 2 | sheat | red | boundary container of the gene in the loop |
| 3 | - | green | support left turning; bonding two arms; generating new off-shoot; cap off-shoot |
| 4 | - | yellow | control left-turning & finishing a sprouted loop |
| 5 | - | pink| Disconnect parent from offspring |
| 6 | - | white | Point to where new sprout should start; guide sprout; finish sprout growth |
| 7 | - | cyan| Hold info. on straight growth of arm & offspring |


All cells update synchronously to a new set in function of their own present state and their symmetrical [von Neumann neighborhood](https://en.wikipedia.org/wiki/Von_Neumann_neighborhood) (using a rule table cf. rules.txt).

The rule is applied symmetrically, meaning that e.g. 4 neighbours in the states 3-2-1-0 is the same as 0-3-2-1 (and all other rotations thereof).

## Starting configuration
The initial configuration is shown in `./img/Langtonstart.png`. The numerically, this matches the array below. This array is also stored in `./data/Langtonstart.txt`.
```
022222222000000 
217014014200000
202222220200000
272000021200000
212000021200000
202000021200000
272000021200000
212222221222220
207107107111112
022222222222220
```

$(PlutoUI.LocalResource("./Exercises/img/Langtonstart.png"))

## Rules
A rule e.g. '123456' is interpreted in the following way: 'Current-Top-Right-Bottom-Left-Next' i.e.  a cell currently in state 1 with neighbours 2,3,4 & 5 (and all possible rotations thereof) will become state 6 in the next iteration. The different rules can be found in `Langtonsrules.txt`.

## Problem solution
We split the problem in a series of subproblems:
* transforming the rule list (.txt) to someting usable (function)
* creating the standard layout
* identifying the neighbours of a cel
* visualising the result


___

The colors shown in the initial position image can created by using the following colormap:
```Julia
using Plots
mycmap = ColorGradient([RGBA(0/255,0/255,0/255),
    RGBA(0/255,0/255,255/255),
    RGBA(255/255,0/255,0/255),
    RGBA(0/255,255/255,0/255),
    RGBA(255/255,255/255,0/255),
    RGBA(255/255,0/255,255/255),
    RGBA(255/255,255/255,255/255),
    RGBA(0/255,255/255,255/255)]);

plt = heatmap(yflip=true,color=mycmap,size=(600,600), title="Langton loop")
```

An animated result is available in `./Exercises/img/Langton.gif`.

$(PlutoUI.LocalResource("./Exercises/img/Langton.gif"))
"""

# ╔═╡ b6e7f9a2-50eb-45e4-8a1a-3eefd591dc6a
md"""## FR 08 Sep"""

# ╔═╡ 8e6ae30a-e6e3-4d8b-b096-3db23ac01060
begin
	function regles(p::String)
		d = Dict()
		for rule in readlines(p)
			etat_actuel = parse(Int,rule[1])
			voisins = parse.(Int,split(rule[2:end-1],""))
			etat_futur = parse(Int,rule[end])

			println("etat_actuel: $(etat_actuel), voisins: $(voisins), next: $(etat_futur)")

			get!(d, etat_actuel, Dict())
			for v in [circshift(voisins,i) for i in 0:3]
				d[etat_actuel][v] = etat_futur
			end
		end

		d
	end
	
	function monde(p::String)
		m = zeros(Int,50,50)
		start = hcat(map(x->parse.(Int,x),split.(readlines(p),""))...)'
		m[20:20+size(start,1)-1, 20:20+size(start,2)-1] = start
		return m
	end
	
	function transition(etat::Int, voisins::Vector{Int}, regles::Dict)
		return regles[etat][voisins]
	end
	
	function mesvoisins(monde::Array, i::Int, j::Int)
		return [monde[i-1,j]; monde[i,j+1]; monde[i+1,j]; monde[i,j-1]]
	end
	
	function iteration!(monde_t::Array, monde_tnext::Array, regles::Dict)
		n,m = size(monde_t)
		for i = 2:n-1
			for j = 2:m-1
				monde_tnext[i,j] = transition(monde_t[i,j], mesvoisins(monde_t,i,j), regles)
			end
		end

	end
end

# ╔═╡ 2a14448f-e761-4b7a-b0c1-4808e1d17d95
R = regles("./Exercises/data/Langtonsrules.txt");

# ╔═╡ 548b40b4-4a5d-4a00-93d6-5bd5aebb1db7
M = monde("./Exercises/data/Langtonstart.txt");

# ╔═╡ 09c14ddd-27a0-4de5-8b8e-d187714e2290
transition(0,[2; 5; 2; 1], R)

# ╔═╡ fd6b0ccb-d0bf-4731-8520-362242ef2321
heatmap(M, yflip=true,size=(400,400), title="Langton départ")

# ╔═╡ 441f27a4-5819-4abf-9e6f-c5fb6a888e3d
begin
	mutable struct MonLangton
		monde::Array{Int64, 2}
		mondefutur::Array{Int64, 2}
		regles::Dict
		function MonLangton(fichiermonde::String, fichierregles::String)
			m = monde(fichiermonde);
			lesregles =  regles(fichierregles);
			return new(m, deepcopy(m), lesregles)
		end
	end
	
	Base.show(io::IO, L::MonLangton) = print(io, "Structure Langton (taille du monde: $(size(L.monde)))")
	
	function evolue!(L::MonLangton)
		iteration!(L.monde, L.mondefutur, L.regles)
		L.monde .= L.mondefutur
	end
	
	function visualise(L::MonLangton)
		heatmap(L.monde, yflip=true,size=(400,400), title="Langton")
	end
	
	LL = MonLangton("./Exercises/data/Langtonstart.txt", "./Exercises/data/Langtonsrules.txt")
end

# ╔═╡ f93794a7-feaf-454f-8c11-7b51818fcb52
begin
	evolue!(LL)
	visualise(LL)
end

# ╔═╡ f63722e3-561b-4125-a629-fc9eb0cdc7de
md"""## NL 08 Sep"""

# ╔═╡ ff900625-8fa9-4481-888d-adf467a7383b
md"""
* 2 matrices voor 'wereld'
* enkel gedeelte van de wereld bekijken (?)
* randeffect!
* permutatie regels
"""

# ╔═╡ 79a80023-2252-409e-a42d-4279254dd0f1
begin
	"""
		regellezer(p)

	lees textbestande van regels en maak een Dict
	"""
	function regellezer(p::String)
		d = Dict()

		for line in readlines(p)
			raw = split(line,"")
			current_state = parse(Int,raw[1])
			neighbors = parse.(Int,raw[2:end-1])
			future_state = parse(Int,raw[end])

			println("current_state= $(current_state), neighbors= $(neighbors), future_state=$(future_state)")
			get!(d, current_state, Dict())
			for neigh in [circshift(neighbors,i) for i in 0:3]
				d[current_state][neigh] = future_state
			end
		end

		return d
	end
	
	function langtonstart(p::String)
		start = hcat(map(x->parse.(Int,x),split.(readlines(p),""))...)'
		world = zeros(Int, 50,50)
		# place start in world
		world[20:20+size(start,1)-1, 20:20+size(start,2)-1] = start
		return world
	end
	
	function future(current_state::Int, neighbors::Vector{Int}, rules::Dict)
		return rules[current_state][neighbors]
	end
	
	function get_neigh(w::Array, i::Int, j::Int)
		return [w[i-1,j]; w[i,j+1]; w[i+1,j]; w[i, j-1]]
	end
	
	function single_iteration!(current_world::Array, future_world::Array, rules::Dict)
		n,m = size(current_world) # dimensions
		for i = 2:n-1
			for j = 2:m-1
				future_world[i,j] = future(current_world[i,j], get_neigh(current_world,i,j), rules)
			end
		end
	end
	

end

# ╔═╡ a7e38b3d-0f77-4d7a-850b-05a215dc9154
rules = regellezer("./Exercises/data/Langtonsrules.txt");

# ╔═╡ d1dc3a77-582d-4ebe-a885-fc9fb881108d
future(1, [7;0;0;2], rules)

# ╔═╡ a73898cf-93f3-4056-9e25-ba88edc15551
w = langtonstart("./Exercises/data/langtonstart.txt");

# ╔═╡ 4ef5b3be-c3d4-472f-b8e8-a28478fa17ba
get_neigh(w,20,24)

# ╔═╡ 51ee2ea1-31dd-4ab1-a60b-f7f6c0883556
single_iteration!(w,deepcopy(w),rules)

# ╔═╡ d0c186c3-2ea7-4de3-b18d-d74319aac6e8
heatmap(w,yflip=true,size=(400,400), title="Langton loop")

# ╔═╡ 4e8d36ee-3434-4689-831e-36ce58637d74
begin
	mutable struct MyLangton
		worldnow::Array{Int64,2}
		worldfuture::Array{Int64,2}
		rules:: Dict
		function MyLangton(worldpath::String, rulepath::String)
			world = langtonstart(worldpath);
			rules = regellezer(rulepath);
			return new(world, deepcopy(world), rules)
		end
	end
	
	Base.show(io::IO, L::MyLangton) = print(io, "MyLangton object (world size: $(size(L.worldnow))")
	
	function evolve!(L::MyLangton)
		single_iteration!(L.worldnow, L.worldfuture, L.rules)
		# dit is nog niet af!
		L.worldnow .= L.worldfuture
		return
	end
	
	function illustrate(L::MyLangton)
		heatmap(L.worldnow,yflip=true,size=(400,400), title="Langton loop")
	end
	Lang = MyLangton("./Exercises/data/langtonstart.txt","./Exercises/data/Langtonsrules.txt")
end

# ╔═╡ feee03a9-dc8f-4654-a152-4b5607edffa6
Lang

# ╔═╡ 1542e2e6-97e7-4c8b-aea7-5c514f82015d
begin
	evolve!(Lang)
	illustrate(Lang)
end

# ╔═╡ Cell order:
# ╠═5312be7e-edd8-11ea-34b0-7581fc4b7126
# ╟─a813912a-edb3-11ea-3b13-23da723cb488
# ╟─b6e7f9a2-50eb-45e4-8a1a-3eefd591dc6a
# ╠═8e6ae30a-e6e3-4d8b-b096-3db23ac01060
# ╠═2a14448f-e761-4b7a-b0c1-4808e1d17d95
# ╠═548b40b4-4a5d-4a00-93d6-5bd5aebb1db7
# ╠═09c14ddd-27a0-4de5-8b8e-d187714e2290
# ╠═fd6b0ccb-d0bf-4731-8520-362242ef2321
# ╠═441f27a4-5819-4abf-9e6f-c5fb6a888e3d
# ╠═f93794a7-feaf-454f-8c11-7b51818fcb52
# ╟─f63722e3-561b-4125-a629-fc9eb0cdc7de
# ╟─ff900625-8fa9-4481-888d-adf467a7383b
# ╠═79a80023-2252-409e-a42d-4279254dd0f1
# ╠═a7e38b3d-0f77-4d7a-850b-05a215dc9154
# ╠═d1dc3a77-582d-4ebe-a885-fc9fb881108d
# ╠═4ef5b3be-c3d4-472f-b8e8-a28478fa17ba
# ╠═a73898cf-93f3-4056-9e25-ba88edc15551
# ╠═51ee2ea1-31dd-4ab1-a60b-f7f6c0883556
# ╠═d0c186c3-2ea7-4de3-b18d-d74319aac6e8
# ╠═4e8d36ee-3434-4689-831e-36ce58637d74
# ╠═feee03a9-dc8f-4654-a152-4b5607edffa6
# ╠═1542e2e6-97e7-4c8b-aea7-5c514f82015d
