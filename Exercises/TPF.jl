### A Pluto.jl notebook ###
# v0.11.12

using Markdown
using InteractiveUtils

# ╔═╡ 7da308ac-f282-11ea-3f24-95dc931f0456
using Plots

# ╔═╡ ea01ac60-f27d-11ea-13ee-f568175af295
md""" 
# TP - F
Bon à savoir:
* où suis-je en train de travailler?
* où se trouvent mes fichiers?
* comment fonctionne mon ordi?
"""

# ╔═╡ 0db200ec-f27e-11ea-1950-a9d7e61afa63
pwd()

# ╔═╡ 5973e55e-f27e-11ea-353c-41dab383b09d
readdir(pwd())

# ╔═╡ 900ea8e2-f27e-11ea-3761-b108c219efc0
# path relatif
readdir("./data/")

# ╔═╡ a84c5c4c-f27e-11ea-304d-b54ef4bfdd80
# path absolu
readdir("/Users/bart/Documents/Stack/ES313/ES313.jl/Exercises/data/")

# ╔═╡ c11d3ce6-f27e-11ea-3e1d-bb7e6080bd82
# lire un fichier tct


# ╔═╡ 8d5bd6e0-f280-11ea-05a6-bbaa78cfaecd


# ╔═╡ 0cf36016-f27f-11ea-2165-bda0d94fa9da
function readrules(path::String)
	r = readlines(path)
	d = Dict()
	for line in r
		# split line
		intermed = parse.(Int,split(line,""))
		actuel = intermed[1]
		voisins = intermed[2:5]
		suivant = intermed[6]
		for i in 0:3
			get!(d, (actuel, circshift(voisins,i)), suivant)
		end
	end
	d
end

# ╔═╡ f11e8d0c-f281-11ea-32bd-1d9a3426aba8
d = readrules("./data/Langtonsrules.txt")

# ╔═╡ 6af82be0-f281-11ea-317d-d349315bfe91
d[(3,[0,0,0,7])]

# ╔═╡ 8a4a4332-f281-11ea-23bd-c35f9ef897c9
X = [1,2,3,4]

# ╔═╡ 92a12de8-f281-11ea-1d6c-97f1edfa3156
readlines("./data/Langtonstart.txt")

# ╔═╡ 07913c56-f282-11ea-0e39-b950958fbe77
begin
	r = readlines("./data/Langtonstart.txt")
	depart = permutedims(hcat([parse.(Int, split(line,"")) for line in r]...))
end

# ╔═╡ e7e5143e-f27e-11ea-3335-378eb2a0ffa1
val = r[173]

# ╔═╡ 804f6ffa-f282-11ea-1d17-ed258755405c
heatmap(depart, yflip=true)

# ╔═╡ Cell order:
# ╟─ea01ac60-f27d-11ea-13ee-f568175af295
# ╠═0db200ec-f27e-11ea-1950-a9d7e61afa63
# ╠═5973e55e-f27e-11ea-353c-41dab383b09d
# ╠═900ea8e2-f27e-11ea-3761-b108c219efc0
# ╠═a84c5c4c-f27e-11ea-304d-b54ef4bfdd80
# ╠═c11d3ce6-f27e-11ea-3e1d-bb7e6080bd82
# ╠═e7e5143e-f27e-11ea-3335-378eb2a0ffa1
# ╠═8d5bd6e0-f280-11ea-05a6-bbaa78cfaecd
# ╠═0cf36016-f27f-11ea-2165-bda0d94fa9da
# ╠═f11e8d0c-f281-11ea-32bd-1d9a3426aba8
# ╠═6af82be0-f281-11ea-317d-d349315bfe91
# ╠═8a4a4332-f281-11ea-23bd-c35f9ef897c9
# ╠═92a12de8-f281-11ea-1d6c-97f1edfa3156
# ╠═07913c56-f282-11ea-0e39-b950958fbe77
# ╠═7da308ac-f282-11ea-3f24-95dc931f0456
# ╠═804f6ffa-f282-11ea-1d17-ed258755405c
