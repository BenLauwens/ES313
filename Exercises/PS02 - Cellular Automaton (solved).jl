### A Pluto.jl notebook ###
# v0.11.14

using Markdown
using InteractiveUtils

# This Pluto notebook uses @bind for interactivity. When running this notebook outside of Pluto, the following 'mock version' of @bind gives bound variables a default value (instead of an error).
macro bind(def, element)
    quote
        local el = $(esc(element))
        global $(esc(def)) = Core.applicable(Base.get, el) ? Base.get(el) : missing
        el
    end
end

# ╔═╡ ed18a0c0-edcd-11ea-2711-513d9794818f
using PlutoUI

# ╔═╡ 4809cdbe-edcf-11ea-1636-6536cb819503
using Plots

# ╔═╡ 7f2f3e48-edbe-11ea-091f-2f2ff57dad10
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

$(PlutoUI.LocalResource("./img/Langtonstart.png"))

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

An animated result is available in `./img/Langton.gif`.

$(PlutoUI.LocalResource("./img/Langton.gif"))
"""

# ╔═╡ 7cc79f7a-edc2-11ea-21b1-7b12d56c43d9
md"""
## Reading the input
"""

# ╔═╡ 70110fca-edc0-11ea-11a2-318a89777b18
"""
	addrule!(ruledic::Dict, rule::String)

Add a rule to a rule dictionary
"""
function addrule!(ruledic::Dict, rule::String)
	# Parse rules
	current = parse(Int, rule[1])
	neighbors = parse.(Int, split(rule[2:5],""))
	next = parse(Int, rule[6])
	# Include all possible rotations
	for rotation in [circshift(neighbors, i) for i in 0:3]
		get!(get!(ruledic, current, Dict(rotation=>next)), rotation, next)
	end
end

# ╔═╡ a33b09fc-edbe-11ea-3fc1-9b9f1297c1ca
"""
	getrules(path::String)

Read Langton's rules from a file.

Data structure of rule dictionary `d`:

	d[current_state] => Dict( [top, right, bottom, left] => next_state)

# Examples
```julia
ruledict = getrule("/path/to/file/Langtonsrules.txt")
```
"""
function getrules(path::String)
	rules = readlines("./data/Langtonsrules.txt")
	ruledict = Dict()
	for rule in rules
		addrule!(ruledict, rule)
	end
	
	return ruledict
end


# ╔═╡ 9c164a56-edc0-11ea-0f92-e3f54d35a29a
rd = getrules("./data/Langtonsrules.txt");

# ╔═╡ 1c25be5e-edc2-11ea-1b4f-5dfd19c82cea
md"""
# Implementation
## Initial state generation
"""

# ╔═╡ a2ec1482-edbe-11ea-197d-ef0321695cc6
"""
	genstate(path::String, dims::Tuple{Int64,Int64})

Generate starting state of size `dims`for Langton's loops from file located in `path`.
"""
function genstate(path::String, dims::Tuple{Int64,Int64})
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

# ╔═╡ e7463276-edd1-11ea-2e23-a15ad8315476
A = genstate("./data/Langtonstart.txt",(14,20))

# ╔═╡ c4052f60-edd1-11ea-1a4c-b38000041683
md"""
## New state generation
"""

# ╔═╡ 9a7a4a94-edc8-11ea-07e4-a3f5b5c0852e
"""
	applyrule(A::Array{Int64,2}, ruledic::Dict)

Apply a rule on the array A of size 3x3 using Neuman neighborhood and a set of rules.
"""
function applyrule(A::Array{Int64,2}, ruledic::Dict)
	current = A[5]
	neighbors = A[[4,8,6,2]]
	return ruledic[current][neighbors]
end

# ╔═╡ f8e87a8e-edc7-11ea-12f5-4d8259bb4b84
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

# ╔═╡ 332fe1a4-edc9-11ea-3219-1d86b205e971
newstate(A, rd) .== A

# ╔═╡ 06143996-edd2-11ea-0223-577f141a60a4
md"""
## Bring it all together
To be able to update the state of the world at each iteration, we store the state in our own structure that we call `Langton`. This structure has two fields: the current state of the world and the rules it adheres to.
"""

# ╔═╡ 86e49444-edcf-11ea-070a-3b6b9178fddf
mutable struct Langton
	state::Array{Int64,2}
	rules::Dict
end

# ╔═╡ 30c1a8be-edd1-11ea-213d-994b209543e2
"""
	langton(startpath::String, rulepath::String)

Generate a Langton instance from a datapath and a rule path.
"""
function langton(startpath::String, rulepath::String, dims::Tuple{Int,Int}=(20,20))
	startstate = genstate(startpath, dims)
	rules = getrules(rulepath)
	return Langton(startstate, rules)
end

# ╔═╡ de815716-edd0-11ea-2aa4-2947edd59a5b
function Base.show(io::IO, L::Langton)
		print(io, "Langton instance of size ($(size(L.state,1)),$(size(L.state,2)))")
end

# ╔═╡ a4fcb1a0-edcf-11ea-2064-f98b76366564
function evolve!(L::Langton)
	L.state = newstate(L.state, L.rules)
	return
end

# ╔═╡ 831df7c6-edd0-11ea-2953-45fb165fbe39
L = langton("./data/Langtonstart.txt",
			"./data/Langtonsrules.txt",
			(40,40))

# ╔═╡ 771e3e48-edd2-11ea-3d54-7f4ff42d17d5
evolve!(L)

# ╔═╡ d1c86584-edc9-11ea-2625-fd57d88d5361
md"""
# Visualisation
"""

# ╔═╡ 61452a08-edcf-11ea-03c6-f57d9f7654b3
# custom color map
mycmap = cgrad([RGBA(0/255,0/255,0/255),
    RGBA(0/255,0/255,255/255),
    RGBA(255/255,0/255,0/255),
    RGBA(0/255,255/255,0/255),
    RGBA(255/255,255/255,0/255),
    RGBA(255/255,0/255,255/255),
    RGBA(255/255,255/255,255/255),
    RGBA(0/255,255/255,255/255)]);

# ╔═╡ be929684-edd2-11ea-3c43-15713eb52771
heatmapsettings = Dict(:yflip=>true, :color=>mycmap, :axis=>false, :size=>(500,350));

# ╔═╡ d5641580-edd3-11ea-395c-492e738dadae
md"""
## Evolution
"""

# ╔═╡ 028619c8-edd4-11ea-14b0-9521fb1ec9c6
V = langton("./data/Langtonstart.txt",
			"./data/Langtonsrules.txt",
			(100,100))

# ╔═╡ 5611da42-edd3-11ea-2be4-799902354f2f
@bind langtonnext html"<input type=button value='Next'>"

# ╔═╡ 5085fb2a-edcf-11ea-105b-7f56b7d558e7
if langtonnext === "Next"
	evolve!(V)
	heatmap(V.state; heatmapsettings...)
else
	heatmap(V.state, size=(500,350); heatmapsettings...)
end

# ╔═╡ 370c446a-edd4-11ea-02e9-fbe2925f4334
md"""
## Store as an animation
Disclaimer: this did not work on a CDN computer due to a problem with ffmpeg.exe. On non-CDN platforms, this worked as advertised.
"""

# ╔═╡ 506c0b34-edcf-11ea-1b7f-571d1cf12459
begin 
	K = langton("./data/Langtonstart.txt",
			"./data/Langtonsrules.txt",
			(250,250))
	anim = @animate for i in 1:1500
		evolve!(K)
		heatmap(K.state; heatmapsettings...)
	end
	
	gif(anim, "./img/mylangton.gif", fps=30)
end




# ╔═╡ Cell order:
# ╠═ed18a0c0-edcd-11ea-2711-513d9794818f
# ╟─7f2f3e48-edbe-11ea-091f-2f2ff57dad10
# ╟─7cc79f7a-edc2-11ea-21b1-7b12d56c43d9
# ╠═a33b09fc-edbe-11ea-3fc1-9b9f1297c1ca
# ╠═70110fca-edc0-11ea-11a2-318a89777b18
# ╠═9c164a56-edc0-11ea-0f92-e3f54d35a29a
# ╟─1c25be5e-edc2-11ea-1b4f-5dfd19c82cea
# ╠═a2ec1482-edbe-11ea-197d-ef0321695cc6
# ╠═e7463276-edd1-11ea-2e23-a15ad8315476
# ╟─c4052f60-edd1-11ea-1a4c-b38000041683
# ╠═9a7a4a94-edc8-11ea-07e4-a3f5b5c0852e
# ╠═f8e87a8e-edc7-11ea-12f5-4d8259bb4b84
# ╠═332fe1a4-edc9-11ea-3219-1d86b205e971
# ╟─06143996-edd2-11ea-0223-577f141a60a4
# ╠═86e49444-edcf-11ea-070a-3b6b9178fddf
# ╠═30c1a8be-edd1-11ea-213d-994b209543e2
# ╠═de815716-edd0-11ea-2aa4-2947edd59a5b
# ╠═a4fcb1a0-edcf-11ea-2064-f98b76366564
# ╠═831df7c6-edd0-11ea-2953-45fb165fbe39
# ╠═771e3e48-edd2-11ea-3d54-7f4ff42d17d5
# ╟─d1c86584-edc9-11ea-2625-fd57d88d5361
# ╠═4809cdbe-edcf-11ea-1636-6536cb819503
# ╠═61452a08-edcf-11ea-03c6-f57d9f7654b3
# ╠═be929684-edd2-11ea-3c43-15713eb52771
# ╟─d5641580-edd3-11ea-395c-492e738dadae
# ╠═028619c8-edd4-11ea-14b0-9521fb1ec9c6
# ╟─5611da42-edd3-11ea-2be4-799902354f2f
# ╟─5085fb2a-edcf-11ea-105b-7f56b7d558e7
# ╟─370c446a-edd4-11ea-02e9-fbe2925f4334
# ╠═506c0b34-edcf-11ea-1b7f-571d1cf12459
