### A Pluto.jl notebook ###
# v0.19.11

using Markdown
using InteractiveUtils

# This Pluto notebook uses @bind for interactivity. When running this notebook outside of Pluto, the following 'mock version' of @bind gives bound variables a default value (instead of an error).
macro bind(def, element)
    quote
        local iv = try Base.loaded_modules[Base.PkgId(Base.UUID("6e696c72-6542-2067-7265-42206c756150"), "AbstractPlutoDingetjes")].Bonds.initial_value catch; b -> missing; end
        local el = $(esc(element))
        global $(esc(def)) = Core.applicable(Base.get, el) ? Base.get(el) : iv(el)
        el
    end
end

# ╔═╡ 5312be7e-edd8-11ea-34b0-7581fc4b7126
begin
	# Pkg needs to be used to force Pluto to use the current project instead of making an environment for each notebook
	using Pkg
	cd(joinpath(dirname(@__FILE__),".."))
    Pkg.activate(pwd())
    
	using Distributions, LinearAlgebra, InteractiveUtils
	using PlutoUI
	using Plots
	
	const mycmap = cgrad([ 	RGBA(0/255,0/255,0/255),
    						RGBA(0/255,0/255,255/255),
   				 			RGBA(255/255,0/255,0/255),
    						RGBA(0/255,255/255,0/255),
    						RGBA(255/255,255/255,0/255),
    						RGBA(255/255,0/255,255/255),
							RGBA(255/255,255/255,255/255),
    						RGBA(0/255,255/255,255/255)]) ;

	nothing
end

# ╔═╡ 1e9ecd99-5a36-448f-9b07-71a070655c0f
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

The colors shown in the initial position image can created by using the colormap that was defined at the beginning of the notebook:
```Julia
plt = heatmap(yflip=true,color=mycmap,size=(600,600), title="Langton loop")
```

An animated result is available in `./Exercises/img/Langton.gif`.

$(PlutoUI.LocalResource("./Exercises/img/Langton.gif"))
"""

# ╔═╡ b6e7f9a2-50eb-45e4-8a1a-3eefd591dc6a
md"""## Getting started"""

# ╔═╡ 645c43fe-e45a-403b-b792-88cae66503c5
md"""
### Understanding the rules
"""

# ╔═╡ b1d05970-3660-434a-b4a6-38cf867a9a99
"""
	addrule!(d::Dict, rule::String; debug=false)

Function to parse a specific rule and write out the result into the dictionary d. Returns a 3-tuple of current state, neighbors and future state.
"""
function addrule!(d::Dict, rule::String; debug=false)
	# parsing of the line (which is a ::String)
	current_state = parse(Int,rule[1])
	neighbors = parse.(Int,split(rule[2:end-1],""))
	next_state = parse(Int,rule[end])
	debug && println("original: $(rule), current: $(current_state), neighbors: $(neighbors), next: $(next_state)")

	# storing the result
	get!(d, current_state, Dict()) # instantiate the dict should it not exist yet
	# also account for circular permutations of the neighbors
	permutations = [circshift(neighbors, i) for i in 0:3]
	for v in permutations
		d[current_state][v] = next_state
	end

	return (current_state, neighbors, next_state)
end

# ╔═╡ eab8e8f9-8528-460c-bdee-94fcbbc49d8e
"""
	rules(p::String)

Obtain the rules that are applicable for our problem. We read the entire file and for each line we obtain the current state, the neighbors and the future state. We also account for all the possible circular permutations that can occurs. 

The function returns a nested dictionary: [current state] => Dict([neigbors] => [future state])
"""
function rules(p::String; debug=false)
		d = Dict()
		for rule in readlines(p)
			addrule!(d, rule; debug)
		end

		return d
end

# ╔═╡ 1a0c018d-63bf-4ef3-a13b-49c02af54a2e
addrule!(Dict(), "012347")

# ╔═╡ 283b2f11-0eee-4e65-ae3b-411e6ff4d9b2
rules("./Exercises/data/Langtonsrules.txt")

# ╔═╡ 8bccf289-3c97-4d87-a5bf-099b6de50e03
rules("./Exercises/data/Langtonsrules.txt")[0][[0;0;0;0]]

# ╔═╡ 334f0860-8ee1-4592-a362-e0e8cc1a21da
md"""
### Obtaining the starting situation
"""

# ╔═╡ e17b8cbf-4abb-41d9-8774-b53dc3aa4298
"""
	genstate(path::String, dims::Tuple{Int64,Int64})

Generate starting state of size `dims` for Langton's loops from file located in `path`.

The input is placed at the center.
"""
function genstate(path::String, dims::Tuple{Int64,Int64}=(12,17))
	# Load start layout
	input = permutedims(hcat([parse.(Int, split(line,"")) for line in readlines(path)]...))
	# Check dimensions (at least one layer of zeros around the input)
	@assert all(dims .> (size(input)) .+ (1,1))
	# Make global array
	A = zeros(Int,dims)
	# Put initial array in center of large array
	dsize = dims .- size(input)
	domrows = round.(Int,dsize[1]/2) + 1:round(Int,dsize[1]/2)+size(input,1)
	domcols = round.(Int,dsize[2]/2) + 1:round(Int,dsize[2]/2)+size(input,2)
	A[domrows, domcols] = input
	
	return A
end

# ╔═╡ 50fc17c1-13a3-4c2a-a828-5c7192a84dcc
genstate("./Exercises/data/Langtonstart.txt")

# ╔═╡ 1d542a92-d75d-4bf0-b2fe-37f30202a68d
heatmap(genstate("./Exercises/data/Langtonstart.txt"), yflip=true,color=mycmap,size=(300,300), title="Langton start situation")

# ╔═╡ f31f3bba-23d7-42ea-bcbb-df06774fcf49
md"""
### Generating a new state
"""

# ╔═╡ c330993e-8c5f-49a4-bca9-beab4657a201
"""
	applyrule(A::Array{Int64,2}, ruledic::Dict)

Apply a rule on the array A of size 3x3 using Neuman neighborhood and a set of rules.
"""
function applyrule(A::Array{Int64,2}, ruledic::Dict)
	current = A[5]
	neighbors = A[[4,8,6,2]]
	return ruledic[current][neighbors]
end

# ╔═╡ a35721fb-947e-4144-b861-0620487be9b6
"""
	newstate(A::Array{Int64,2}, ruledic::Dict)

Based on a set of rules in a `ruledic` and a current state `A`, generate a new state.

"""
function newstate(A::Array{Int64,2}, ruledic::Dict)
	# Initialise new state
	R = zeros(Int, size(A))
	# Determine new states
	for i in 2:(size(A,1)-1)
		for j in 2:(size(A,2)-1)
			R[i,j] = applyrule(A[i-1:i+1, j-1:j+1], ruledic)
		end
	end
	
	return R
end

# ╔═╡ 32c1b6d7-48c0-4068-904b-a03cc3114c7e
newstate(genstate("./Exercises/data/Langtonstart.txt"), rules("./Exercises/data/Langtonsrules.txt"))

# ╔═╡ 6c75e759-0b7e-485e-91d3-1a2c6164a0f8
plot( heatmap(genstate("./Exercises/data/Langtonstart.txt"), yflip=true,color=mycmap, title="Langton start situation"),
	heatmap(newstate(genstate("./Exercises/data/Langtonstart.txt"), rules("./Exercises/data/Langtonsrules.txt")), yflip=true,color=mycmap, title="Langton one iteration"),size=(600,300)
)

# ╔═╡ 2066d962-db1c-414d-9c36-a77ddedd2a7d
md"""
## Bring it all together
"""

# ╔═╡ d0ff5030-d067-4451-b0cf-07144399bb27
"""
	Langton

DataType used to represented a Langton loop
"""
struct Langton
	state::Array{Int64,2}
	rules::Dict
	function Langton(startpath::String, rulepath::String, dims::Tuple{Int,Int}=(20,20))
		startstate = genstate(startpath, dims)
		ruledict = rules(rulepath)
		
		return new(startstate, ruledict)
	end
end

# ╔═╡ eba86c45-7dce-430c-a67c-1ba7af403180
Langton("./Exercises/data/Langtonstart.txt","./Exercises/data/Langtonsrules.txt")

# ╔═╡ 4488f2a8-48b0-497e-bdbb-abf1da71a4bc
Base.show(io::IO, L::Langton) = print(io, "Langton instance of size ($(size(L.state,1)),$(size(L.state,2)))")

# ╔═╡ cc63ab4a-af74-4a78-846f-858e6ade0c1f
Langton("./Exercises/data/Langtonstart.txt","./Exercises/data/Langtonsrules.txt")

# ╔═╡ d0453bc3-5400-445f-a5d7-e0cb420c2dd3
"""
evolve!(L::Langton)

Do a single iteration of the Langton loop game of life
"""
function evolve!(L::Langton)
	L.state .= newstate(L.state, L.rules)
	return
end

# ╔═╡ e840b89c-332f-4b0e-b9d0-bf6863672aca
L = Langton("./Exercises/data/Langtonstart.txt",
			"./Exercises/data/Langtonsrules.txt",
			(40,40))

# ╔═╡ b601d119-71c4-443a-83a4-fb733e299994
evolve!(L)

# ╔═╡ c6efe180-a58a-420a-a79d-484816ec38ba
md"""
## Visualize the results
"""

# ╔═╡ e4900928-8f04-4882-bcfc-d11d1601729c
const heatmapsettings = Dict(:yflip=>true, :color=>mycmap, :axis=>false, :size=>(500,350));

# ╔═╡ c49fe159-299b-42a4-a5d0-e6936e1e8e41
heatmap(L.state; heatmapsettings...)

# ╔═╡ fda92cba-4828-4b65-9866-2d24a8fc26ae
md"""
## Evolution
"""

# ╔═╡ 15bf1c75-55d3-449a-999a-cc83b87e38a3
V = Langton("./Exercises/data/Langtonstart.txt",
			"./Exercises/data/Langtonsrules.txt",
			(100,100))

# ╔═╡ e4422479-4a62-44c3-b981-14dd3df40d3b
@bind langtonnext html"<input type=button value='Next Langton iteration'>"

# ╔═╡ 1ef554e1-25fd-4bb7-839d-dfc36388aece
if langtonnext === "Next Langton iteration"
	evolve!(V)
	heatmap(V.state; heatmapsettings...)
else
	heatmap(V.state, size=(500,350); heatmapsettings...)
end

# ╔═╡ f2b803fd-bd73-4bef-a6b1-a24e02bd545b
# make an animation (can take some time)
begin
	K = Langton("./Exercises/data/Langtonstart.txt",
				"./Exercises/data/Langtonsrules.txt",
				(250,250))
	anim = @animate for i in 1:1500
		evolve!(K)
		if i % 5 == 0
			heatmap(K.state; heatmapsettings...)
		end
	end
end

# ╔═╡ 24af7dbf-4c52-4272-83fe-d6605050dd6e
	gif(anim, "./Exercises//mylangton.gif", fps=30)

# ╔═╡ 86e89ddf-f74c-434d-9b70-c8bdf2b874ef
gif(anim)

# ╔═╡ 4f1ac264-51cf-467e-b336-9c8610dbdb22
md"""
## Analysis
* Are you happy with the result?
* What are weaknesses of our implementation?
"""

# ╔═╡ 8593d576-7d39-4f23-b9cc-f259e74dfc30
md"""
#  Lava flow
A vulcano is erupting on an island. We know the island's topology (shown below). We make the following assumptions:
* all lava that will flow out is initially located on the point of origin.
* lava moves according to the following rules:
   - if a lower zone is adjacent to the tile with the lava: lava flows from high to low. If multiple lower locations are present, lave moves from high to low, but proportional to the altitude difference.
   - if no adjacent tiles are lower, lava will be distributed across all tiles of the same altitude.

We try to determine how the lava will flow across the island.


"""

# ╔═╡ 4952beb6-bd46-4d4d-ac87-0678f6a240bc
const W = [0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0; 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0; 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0; 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0; 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0; 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0; 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0; 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0; 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0; 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0; 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0; 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0; 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0; 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0; 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0; 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0; 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 6 7 7 7 6 5 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0; 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 6 8 10 11 12 11 9 7 5 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0; 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 6 8 11 14 16 17 17 15 13 10 7 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0; 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 6 10 14 19 22 25 25 24 21 16 12 8 5 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0; 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 7 11 17 23 29 33 35 34 31 26 20 14 9 5 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0; 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 7 12 19 26 34 41 46 47 44 38 30 22 15 9 5 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0; 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 7 12 19 29 39 49 56 60 59 53 44 34 24 15 9 5 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0; 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 6 11 19 29 41 54 65 72 74 69 60 48 35 24 15 8 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0; 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 5 10 17 28 41 56 71 82 87 85 77 64 49 34 22 13 7 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0; 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 8 15 25 39 55 72 87 97 99 93 80 64 47 32 20 11 6 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0; 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 6 12 21 34 51 69 87 101 107 105 95 79 60 42 27 16 9 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0; 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 9 17 29 44 63 82 99 109 112 105 91 72 53 36 22 13 7 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0; 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 7 13 22 36 53 72 91 105 112 109 99 82 63 44 29 17 9 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0; 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 9 16 27 42 60 79 95 105 107 101 87 69 51 34 21 12 6 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0; 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 6 11 20 32 47 64 80 93 99 97 87 72 55 39 25 15 8 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0; 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 7 13 22 34 49 64 77 85 87 82 71 56 41 28 17 10 5 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0; 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 8 15 24 35 48 60 69 74 72 65 54 41 29 19 11 6 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0; 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 5 9 15 24 34 44 53 59 60 56 49 39 29 19 12 7 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0; 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 5 9 15 22 30 38 44 47 46 41 34 26 19 12 7 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0; 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 5 9 14 20 26 31 34 35 33 29 23 17 11 7 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0; 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 5 8 12 16 21 24 25 25 22 19 14 10 6 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0; 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 7 10 13 15 17 17 16 14 11 8 6 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0; 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 5 7 9 11 12 11 10 8 6 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0; 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 5 5 5 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 5 6 7 7 7 6 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0; 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 6 7 8 9 9 9 8 7 6 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0; 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 7 9 11 13 14 15 15 14 12 10 8 6 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0; 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 7 10 13 16 19 22 23 23 22 19 16 13 10 7 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0; 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 6 9 13 18 23 27 31 34 34 33 30 25 20 15 11 7 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0; 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 7 11 16 23 30 36 42 46 48 47 43 37 30 23 17 12 8 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0; 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 8 13 20 28 37 46 54 60 63 62 58 51 42 33 24 17 11 7 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0; 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 5 9 15 22 32 43 54 65 73 78 78 74 66 56 44 33 24 16 11 7 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0; 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 5 9 15 24 34 47 61 74 85 92 93 90 81 70 56 43 31 22 15 10 7 5 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0; 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 5 9 15 24 35 49 64 79 92 101 105 102 94 82 67 52 39 28 19 13 10 7 6 6 5 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0; 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 5 9 15 23 35 49 65 81 96 106 112 111 103 91 76 61 46 34 24 17 13 10 9 8 8 7 7 6 5 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0; 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 8 14 22 33 47 63 79 94 106 113 114 108 97 82 67 52 39 29 22 17 14 13 12 11 10 9 8 7 6 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0; 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 8 13 21 31 44 59 75 90 102 110 112 107 98 85 70 55 43 33 26 21 19 17 16 15 14 13 11 10 8 6 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0; 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 8 12 20 29 41 55 70 84 96 104 106 103 95 84 71 58 46 37 31 26 24 22 21 20 18 17 15 13 10 8 6 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0; 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 8 12 19 28 39 52 66 79 90 97 100 98 91 81 70 59 49 41 35 32 30 28 27 25 24 21 19 16 13 10 8 6 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0; 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 8 13 20 28 39 52 65 77 87 93 95 93 87 78 69 59 51 45 40 38 36 35 33 32 29 26 23 19 16 12 10 7 5 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0; 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 8 14 21 30 41 53 66 78 87 92 94 91 85 77 69 60 54 49 46 44 43 42 40 38 35 31 27 23 19 15 11 8 6 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0; 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 5 9 15 22 32 44 57 70 82 90 95 96 93 87 79 70 63 57 54 51 50 50 49 47 44 41 36 31 26 21 17 12 9 6 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0; 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 5 9 15 24 34 47 61 75 88 97 102 102 99 92 83 75 68 62 59 57 57 56 55 53 50 46 41 35 29 23 18 14 10 7 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0; 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 5 9 16 24 36 49 65 80 94 104 110 110 106 99 90 81 73 68 64 63 62 62 61 58 55 50 44 37 31 25 19 14 10 7 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0; 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 5 9 15 24 35 50 66 82 98 109 116 118 114 107 97 88 79 73 70 68 67 66 64 62 58 52 46 39 32 25 20 15 10 7 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0; 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 8 14 22 34 48 64 81 98 111 119 122 120 113 103 94 85 78 74 71 70 69 67 63 59 53 46 39 32 25 19 14 10 7 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0; 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 7 12 20 30 44 60 77 93 107 117 121 120 115 106 97 88 81 76 73 71 69 67 63 58 52 45 38 31 24 18 14 10 7 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0; 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 6 10 17 26 38 52 68 84 99 109 115 116 112 105 96 88 81 76 72 70 67 64 60 55 49 43 36 29 22 17 12 9 6 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0; 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 8 13 21 31 43 58 72 86 97 103 106 104 99 92 84 78 73 69 66 64 60 56 51 45 39 32 26 20 15 11 8 5 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0; 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 6 10 16 24 34 46 59 71 81 88 92 91 88 83 77 72 68 64 61 58 55 51 46 40 34 28 23 18 13 9 7 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0; 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 7 11 17 25 35 45 55 64 71 75 77 75 72 68 64 60 57 54 51 48 44 39 34 29 24 19 15 11 8 5 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0; 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 8 12 18 25 33 41 48 55 59 61 61 59 57 54 51 48 46 43 40 37 33 29 24 20 16 12 9 6 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0; 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 8 12 17 23 29 35 40 44 46 47 47 45 44 42 40 38 35 33 30 27 23 19 16 12 9 7 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0; 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 7 11 15 19 24 28 31 34 35 35 35 34 33 31 30 28 26 23 21 18 15 12 9 7 5 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0; 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 7 9 12 15 18 21 23 25 25 26 25 25 24 23 21 20 18 16 13 11 9 7 5 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0; 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 6 8 10 12 14 16 17 18 18 18 18 17 17 16 14 13 11 10 8 6 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0; 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 6 7 9 10 11 12 12 13 13 12 12 11 10 9 8 7 5 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0; 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 5 6 7 8 8 8 9 8 8 8 7 6 5 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0; 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 5 5 6 6 5 5 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0; 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0; 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0; 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0; 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0; 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0; 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0; 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0; 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0; 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0; 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0; 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0; 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0; 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0; 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0; 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0; 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0; 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0; 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0; 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0; 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0; 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0; 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0; 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0; 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0; 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0; 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0];nothing

# ╔═╡ 4db8bbe8-845c-4fb9-8faa-749b2d45147b
md"""
The matrix W holds the altitude data. An illustration is provided to show you the topological map.
"""

# ╔═╡ f80911a5-cf14-4e82-aac2-5aa817deb69a
heatmap(W, c=:gist_earth, clims=(0,150), title="Altitude map [m]", size=(400,400))

# ╔═╡ 2d28bb56-019c-4198-bdd5-220f2cbd883e
md"""
## Your solution
You should include the following details:
- how will you do this
- some tests to assert everything works as intended
- be aware of the limitations

As an additional question, you might want to think about how you could incorporate the fact that lava hardens as it cools down.

"""

# ╔═╡ 2ee542c5-f5e7-478a-8832-92c0f1c41e7a


# ╔═╡ 1bf90bd6-3e8c-45ca-9357-ae047cb29f39
md"""
# Ant world
Consider a world with food at some locations. At the center of the world there is a nest of ants. At a certain frequency, an ant climnbs out of the nest and goes looking for food. While searching for food, the ant can go forwards, forwards-left and forwards-right. The ant also leaves a trace of pheromones behind so it can find its way back should it encounter food. After having discovered food, the ant turns around and tries to go back home, while leaving another pheromone to indicate that food was found. The more pheromone a specific location has, the more likely it is to be selected. Try to implement and visualize this process. You should observe the emergence of "ant highways" after a number of iterations.

## Your solution
You should include the following details:
- how will you do this
- some tests to assert everything works as intended
- be aware of the limitations

As an additional question, you might want to think about how you could incorporate the fact pheromones are volatile, and thus the concentration evolves over time.
"""

# ╔═╡ 79bfb454-a11a-42cb-b94d-dec0eb04cd31
"""
	Ant

Generate an ant on location (x,y) with a direction. This is a `Bool`, where 1 = up, 0 = down
"""
mutable struct Ant
	x::Int
	y::Int
	dir::Bool
end

# ╔═╡ 4ba2cb98-e019-4009-adc4-e1f7254292b2
"""
	Antworld

The world of the ants. Holds the feromones when hunting for food in `feromone_hunt` and those linked the finding food in `feromone_food`. Fermone values are stored as integers. Food locations are stored is `food_locations`.
"""
struct Antworld
	feromone_hunt::Dict
	feromone_food::Dict
	food_locations::Set
	function Antworld(; feromone_hunt = Dict{Tuple{Int64, Int64}, Int64}(),  
						feromone_food = Dict{Tuple{Int64, Int64}, Int64}(),
						food_locations = Set{Tuple{Int64, Int64}}())
		return new(feromone_hunt, feromone_food, food_locations)
	end
end

# ╔═╡ c28f1388-d534-4777-b1e3-bc0a1eafd0d9
Base.show(io::IO, a::Ant) = print(io, """🐜@($(a.x), $(a.y)) going $(a.dir ? "⬆" : "⬇")""")

# ╔═╡ 720bce28-71d0-41a4-bafd-a180a184e5fc
# constant used for change in x direction
const Δx = [-1;0;1]

# ╔═╡ 77142da6-bad9-418a-80ef-e7629885d61e
"""
	move_ant_naive!(a::Ant)

implements the random walk of the ant accounting for its direction.
"""
function move_ant_naive!(a::Ant)
	a.y += a.dir ? 1 : -1
	a.x += rand(Δx)
	return nothing
end

# ╔═╡ 20fbd7ac-05a0-4a5b-9521-05be4ca9b561
"""
	next_Δx(a,b,c)

Given the feromone counts a, b and c on the left, forward and right position with respect to the movement direction of the ant, 
pick the next lation
"""
function next_Δx(a,b,c; α=1.)
	# probability distribution
	dist = cumsum([(1+α*a)/(3+α*(a+b+c)); (1+α*b)/(3+α*(a+b+c)); (1+α*c)/(3+α*(a+b+c))])

	# pick random value from Δx
	return Δx[findfirst( rand() .<= dist)]
end

# ╔═╡ cedbddc2-6446-4790-91dd-03ea98f80fc3
"""
	move_ant!(a::Ant, w::Antworld)

implements ant movement accounting for its direction and the world.
"""
function move_ant!(a::Ant, w::Antworld)
	# feromone placement (depends on the direction)
	# when going up:
	if a.dir
		# get!(w.feromone_hunt, (a.x, a.y), 0) is to avoid having errors in case the value does not exist yet
		w.feromone_hunt[(a.x, a.y)] = get!(w.feromone_hunt, (a.x, a.y), 0)  + 1 
		# determine the next x location
		a.x += next_Δx( get(w.feromone_food, (a.x-1, a.y+1), 0), 
						get(w.feromone_food, (a.x,   a.y+1), 0),
						get(w.feromone_food, (a.x+1, a.y+1), 0))
	# when going down
	else
		# leave feromone
		w.feromone_food[(a.x, a.y)] = get!(w.feromone_food, (a.x, a.y), 0)  + 1 
		# detemrine the next x location (note, when looking down, the order changes)
		a.x += next_Δx( get(w.feromone_food, (a.x+1, a.y-1), 0), 
						get(w.feromone_food, (a.x,   a.y-1), 0),
						get(w.feromone_food, (a.x-1, a.y-1), 0))
	end
	
	# next y location
	a.y += a.dir ? 1 : -1
	
	# check if I'm on food and flip the direction
	if (a.x, a.y) ∈ w.food_locations
		a.dir = !a.dir # Note: by flipping this you can also turn away in the wrong direction in a multi food world
	end
	
end

# ╔═╡ 22729fda-0111-4f54-9408-c552d213eb89
let
	# make a simple ant with simple movement
	myant = Ant(0, 0, true)
	println(myant)
	move_ant_naive!(myant); 
	println(myant)
end

# ╔═╡ da10cdd0-7e92-4e8b-9532-33d529d05f68
let
	# make a simple ant with simple movement
	myant = Ant(0, 0, true)
	myworld = Antworld()
	for _ = 1:2
		println(myant)
		move_ant!(myant, myworld); 
	end
	println(myant)
	myworld
end

# ╔═╡ 15d75ea9-7ca7-4210-8d40-c38154994e7e
Base.broadcastable(f::Antworld) = Ref(f) # to make an Antworld non-iterable (cf. docs)

# ╔═╡ cf09cb1b-edcd-4bc9-9d28-e2b53a56e04e
let
	# a demo with three ants
	myants = [Ant(0,0, true) for _ in 1:3]
	myworld = Antworld()
	for _ in 1:5
		move_ant!.(myants, myworld)
	end
	println(join(["$(ant)" for ant in myants], "\n"))
	myworld
end

# ╔═╡ 30b93916-0666-4b61-b141-459aa79786a1
"""
	antlife(n)

Run a small scale simulation for n iterations. A new ant spawns at each iteration. 
"""
function antlife(n=200; food_pos=Set([(1,20)]))
	myants = Ant[]

	myantworld = Antworld(food_locations=food_pos)
	for i = 1:n
		# spawn a new ant
		push!(myants, Ant(0,0,true))
		# move all the ants
		# Note: this move each ant after the other and not all of them at the same time. The latter option would required you to have a copy of the feromone states that will be updated. This can be done, but be aware of the difference between copy and deepcopy.
		move_ant!.(myants, myantworld)
		# check if ants should be removed, e.g. ants within a manhattan distance of 1 from the nest and with a negative y value are removed from the simulation
		to_keep = filter(ant -> ant.y >= 0 && abs(ant.x) >= 0, myants)
		myants = to_keep
	end

	return myants, myantworld
end

# ╔═╡ cc28df9c-965b-4c71-8f4c-a637c44735ee
"""
	showworld(w::Antworld; kind=:food)

Generate a plot for the feromone counts for the :food or the :hunt feromones
"""
function showworld(w::Antworld; kind=:food)
	if kind ==:food
		d = w.feromone_food
		t = "food feromones"
	elseif kind==:hunt
		d = w.feromone_hunt
		t = "hunting feromones"
	end
	# determine limits
	xmin, xmax = minimum(x[1] for x in keys(d)), maximum(x[1] for x in keys(d))
	ymin, ymax = minimum(x[2] for x in keys(d)), maximum(x[2] for x in keys(d))

	# generate matrix
	A = zeros(Int, xmax - xmin + 1, ymax - ymin + 1)
	for (coord, val) in d
		A[coord[1] - xmin + 1, coord[2] - ymin + 1] = val
	end
	
	# actual plot
	heatmap(log10.(permutedims(A)), yflip=false, title=t, color=:blues)
	xticks!(1:(xmax-xmin+1) ÷ 10:xmax-xmin+1, ["$(v)" for v in xmin:(xmax-xmin+1) ÷ 10:xmax])
	xlabel!("x")
	yticks!(1:(ymax-ymin+1) ÷ 10:ymax-ymin+1, ["$(v)" for v in ymin:(ymax-ymin+1) ÷ 10:ymax])
end

# ╔═╡ 96309e1f-ceec-4220-8d49-8575dd8de376
# actual simulation
ants, world = antlife(250, food_pos=Set([(7,25); (-7,25)]));

# ╔═╡ af4dbfb2-f38b-4b68-a9d6-bf9c5d0480f7
plot(showworld(world, kind=:food), showworld(world, kind=:hunt), size=(800,600), colorbar_title="log(feromonne)")

# ╔═╡ Cell order:
# ╟─1e9ecd99-5a36-448f-9b07-71a070655c0f
# ╠═5312be7e-edd8-11ea-34b0-7581fc4b7126
# ╟─a813912a-edb3-11ea-3b13-23da723cb488
# ╟─b6e7f9a2-50eb-45e4-8a1a-3eefd591dc6a
# ╟─645c43fe-e45a-403b-b792-88cae66503c5
# ╠═eab8e8f9-8528-460c-bdee-94fcbbc49d8e
# ╠═b1d05970-3660-434a-b4a6-38cf867a9a99
# ╠═1a0c018d-63bf-4ef3-a13b-49c02af54a2e
# ╠═283b2f11-0eee-4e65-ae3b-411e6ff4d9b2
# ╠═8bccf289-3c97-4d87-a5bf-099b6de50e03
# ╟─334f0860-8ee1-4592-a362-e0e8cc1a21da
# ╠═e17b8cbf-4abb-41d9-8774-b53dc3aa4298
# ╠═50fc17c1-13a3-4c2a-a828-5c7192a84dcc
# ╠═1d542a92-d75d-4bf0-b2fe-37f30202a68d
# ╟─f31f3bba-23d7-42ea-bcbb-df06774fcf49
# ╠═c330993e-8c5f-49a4-bca9-beab4657a201
# ╠═a35721fb-947e-4144-b861-0620487be9b6
# ╠═32c1b6d7-48c0-4068-904b-a03cc3114c7e
# ╟─6c75e759-0b7e-485e-91d3-1a2c6164a0f8
# ╟─2066d962-db1c-414d-9c36-a77ddedd2a7d
# ╠═d0ff5030-d067-4451-b0cf-07144399bb27
# ╠═eba86c45-7dce-430c-a67c-1ba7af403180
# ╠═4488f2a8-48b0-497e-bdbb-abf1da71a4bc
# ╠═cc63ab4a-af74-4a78-846f-858e6ade0c1f
# ╠═d0453bc3-5400-445f-a5d7-e0cb420c2dd3
# ╠═e840b89c-332f-4b0e-b9d0-bf6863672aca
# ╠═b601d119-71c4-443a-83a4-fb733e299994
# ╟─c6efe180-a58a-420a-a79d-484816ec38ba
# ╠═e4900928-8f04-4882-bcfc-d11d1601729c
# ╠═c49fe159-299b-42a4-a5d0-e6936e1e8e41
# ╟─fda92cba-4828-4b65-9866-2d24a8fc26ae
# ╠═15bf1c75-55d3-449a-999a-cc83b87e38a3
# ╟─e4422479-4a62-44c3-b981-14dd3df40d3b
# ╟─1ef554e1-25fd-4bb7-839d-dfc36388aece
# ╠═f2b803fd-bd73-4bef-a6b1-a24e02bd545b
# ╠═24af7dbf-4c52-4272-83fe-d6605050dd6e
# ╠═86e89ddf-f74c-434d-9b70-c8bdf2b874ef
# ╟─4f1ac264-51cf-467e-b336-9c8610dbdb22
# ╟─8593d576-7d39-4f23-b9cc-f259e74dfc30
# ╟─4952beb6-bd46-4d4d-ac87-0678f6a240bc
# ╟─4db8bbe8-845c-4fb9-8faa-749b2d45147b
# ╟─f80911a5-cf14-4e82-aac2-5aa817deb69a
# ╟─2d28bb56-019c-4198-bdd5-220f2cbd883e
# ╠═2ee542c5-f5e7-478a-8832-92c0f1c41e7a
# ╟─1bf90bd6-3e8c-45ca-9357-ae047cb29f39
# ╠═79bfb454-a11a-42cb-b94d-dec0eb04cd31
# ╠═4ba2cb98-e019-4009-adc4-e1f7254292b2
# ╠═c28f1388-d534-4777-b1e3-bc0a1eafd0d9
# ╠═720bce28-71d0-41a4-bafd-a180a184e5fc
# ╠═77142da6-bad9-418a-80ef-e7629885d61e
# ╠═cedbddc2-6446-4790-91dd-03ea98f80fc3
# ╠═20fbd7ac-05a0-4a5b-9521-05be4ca9b561
# ╠═22729fda-0111-4f54-9408-c552d213eb89
# ╠═da10cdd0-7e92-4e8b-9532-33d529d05f68
# ╠═15d75ea9-7ca7-4210-8d40-c38154994e7e
# ╠═cf09cb1b-edcd-4bc9-9d28-e2b53a56e04e
# ╠═30b93916-0666-4b61-b141-459aa79786a1
# ╠═cc28df9c-965b-4c71-8f4c-a637c44735ee
# ╠═96309e1f-ceec-4220-8d49-8575dd8de376
# ╠═af4dbfb2-f38b-4b68-a9d6-bf9c5d0480f7
