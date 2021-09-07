### A Pluto.jl notebook ###
# v0.15.1

using Markdown
using InteractiveUtils

# ╔═╡ 5312be7e-edd8-11ea-34b0-7581fc4b7126
using PlutoUI

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

# ╔═╡ a92dec02-edba-11ea-250f-4d872a29f74d
versioninfo()

# ╔═╡ 00000000-0000-0000-0000-000000000001
PLUTO_PROJECT_TOML_CONTENTS = """
[deps]
PlutoUI = "7f904dfe-b85e-4ff6-b463-dae2292396a8"

[compat]
PlutoUI = "~0.7.9"
"""

# ╔═╡ 00000000-0000-0000-0000-000000000002
PLUTO_MANIFEST_TOML_CONTENTS = """
# This file is machine-generated - editing it directly is not advised

[[Base64]]
uuid = "2a0f44e3-6c83-55bd-87e4-b1978d98bd5f"

[[Dates]]
deps = ["Printf"]
uuid = "ade2ca70-3891-5945-98fb-dc099432e06a"

[[InteractiveUtils]]
deps = ["Markdown"]
uuid = "b77e0a4c-d291-57a0-90e8-8db25a27a240"

[[JSON]]
deps = ["Dates", "Mmap", "Parsers", "Unicode"]
git-tree-sha1 = "8076680b162ada2a031f707ac7b4953e30667a37"
uuid = "682c06a0-de6a-54ab-a142-c8b1cf79cde6"
version = "0.21.2"

[[Logging]]
uuid = "56ddb016-857b-54e1-b83d-db4d58db5568"

[[Markdown]]
deps = ["Base64"]
uuid = "d6f4376e-aef5-505a-96c1-9c027394607a"

[[Mmap]]
uuid = "a63ad114-7e13-5084-954f-fe012c677804"

[[Parsers]]
deps = ["Dates"]
git-tree-sha1 = "438d35d2d95ae2c5e8780b330592b6de8494e779"
uuid = "69de0a69-1ddd-5017-9359-2bf0b02dc9f0"
version = "2.0.3"

[[PlutoUI]]
deps = ["Base64", "Dates", "InteractiveUtils", "JSON", "Logging", "Markdown", "Random", "Reexport", "Suppressor"]
git-tree-sha1 = "44e225d5837e2a2345e69a1d1e01ac2443ff9fcb"
uuid = "7f904dfe-b85e-4ff6-b463-dae2292396a8"
version = "0.7.9"

[[Printf]]
deps = ["Unicode"]
uuid = "de0858da-6303-5e67-8744-51eddeeeb8d7"

[[Random]]
deps = ["Serialization"]
uuid = "9a3f8284-a2c9-5f02-9a11-845980a1fd5c"

[[Reexport]]
git-tree-sha1 = "45e428421666073eab6f2da5c9d310d99bb12f9b"
uuid = "189a3867-3050-52da-a836-e630ba90ab69"
version = "1.2.2"

[[Serialization]]
uuid = "9e88b42a-f829-5b0c-bbe9-9e923198166b"

[[Suppressor]]
git-tree-sha1 = "a819d77f31f83e5792a76081eee1ea6342ab8787"
uuid = "fd094767-a336-5f1f-9728-57cf17d0bbfb"
version = "0.2.0"

[[Unicode]]
uuid = "4ec0a83e-493e-50e2-b9ac-8f72acf5a8f5"
"""

# ╔═╡ Cell order:
# ╠═5312be7e-edd8-11ea-34b0-7581fc4b7126
# ╟─a813912a-edb3-11ea-3b13-23da723cb488
# ╠═a92dec02-edba-11ea-250f-4d872a29f74d
# ╟─00000000-0000-0000-0000-000000000001
# ╟─00000000-0000-0000-0000-000000000002
