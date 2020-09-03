### A Pluto.jl notebook ###
# v0.11.10

using Markdown
using InteractiveUtils

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
"""

# ╔═╡ a92dec02-edba-11ea-250f-4d872a29f74d


# ╔═╡ Cell order:
# ╟─a813912a-edb3-11ea-3b13-23da723cb488
# ╠═a92dec02-edba-11ea-250f-4d872a29f74d
