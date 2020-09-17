### A Pluto.jl notebook ###
# v0.11.14

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

# ╔═╡ 0f2dea90-f7ff-11ea-3a2a-3b4ff3176ff4
	mycmap = cgrad([RGBA(0/255,0/255,0/255),
    RGBA(0/255,0/255,255/255),
    RGBA(255/255,0/255,0/255),
    RGBA(0/255,255/255,0/255),
    RGBA(255/255,255/255,0/255),
    RGBA(255/255,0/255,255/255),
    RGBA(255/255,255/255,255/255),
    RGBA(0/255,255/255,255/255)])

# ╔═╡ a7902b40-f7eb-11ea-24e8-49b97db4e0f8
md"""
Choses à faire aujourd'hui:
* rectifier les couleurs
* incorporer la situation intiale dans un monde plus grand
* actualiser l'état
* générer une animation
"""

# ╔═╡ fb6968b0-f7fc-11ea-3b8c-9f8aeb89eb49
# créer le monde
function genworld(EI, dims)
	ssize = size(EI)
	#println(ssize .> dims)
	#println(typeof(ssize .> dims))
	if any(ssize .> dims)
		error("le monde est trop petit...")
	end
	# initialisation
	monde = zeros(Int,dims...)
	# incorporer EI
	i = round(Int,(dims[1] - ssize[1])/2) +1
	j = round(Int,(dims[2] - ssize[2])/2) +1
	monde[i:i+ssize[1]-1, j:j+ssize[2]-1] = EI
	
	return monde
end

# ╔═╡ faa26f2e-f7fc-11ea-0689-35a9fe9702ca
genworld(depart, (14,25))

# ╔═╡ fde2e240-f7fe-11ea-0ea2-377c6e99f379
heatmap(genworld(depart, (40,60)), yflip=true, color=mycmap, size=(250,200))

# ╔═╡ dd0c8d90-f7ff-11ea-0e50-d5eea9756d0c
# mise à jour
function update(monde, regles)
	neuf = zeros(Int, size(monde)...)
	for i in 2:size(monde,1)-1
		for j in 2:size(monde,2)-1
			neuf[i,j] = regles[(monde[i,j],[monde[i-1,j], monde[i,j+1], monde[i+1,j], monde[i,j-1]])]
		end
	end
	return neuf
end

# ╔═╡ 7645dd3e-f800-11ea-1dbd-55d7af40fb49
monde = genworld(depart, (12,20));

# ╔═╡ 8b03ec40-f800-11ea-1885-8b78f155da83
monde_v2 = update(monde,d)

# ╔═╡ ab35a710-f800-11ea-1e6f-8fdeffc51470
monde .== monde_v2

# ╔═╡ 03be2470-f801-11ea-153d-4fa68edc60f0
# combiner le tout
mutable struct Langton
	etat::Array{Int,2}
	regles::Dict
end

# ╔═╡ 236f210e-f802-11ea-1c0a-a96757d124ee
begin
	import Base.show
	function show(io,IO,L::Langton)
		print(io,"Langton instance de taille $(size(L.etat)) avec $(length(L.regles)) règles")
	end
end


# ╔═╡ 37fc5180-f801-11ea-0280-211d18e7a5c0
function langton(fei::String, fr::String, dims::Tuple=(12,20))
	regles = readrules(fr)
	r = readlines(fei)
	depart = permutedims(hcat([parse.(Int, split(line,"")) for line in r]...))
	monde = genworld(depart, dims)
	return Langton(monde, regles)
end

# ╔═╡ 9e6cd610-f801-11ea-3928-35eadc58071e
L = langton("./data/Langtonstart.txt","./data/Langtonsrules.txt")

# ╔═╡ 1fc5a110-f802-11ea-3546-ffd6cfd1ac18
L

# ╔═╡ 021d2930-f802-11ea-3e0c-673994053432
L

# ╔═╡ 260e5270-f801-11ea-03d7-27e618b8da3c
Langton(monde, d)

# ╔═╡ Cell order:
# ╟─ea01ac60-f27d-11ea-13ee-f568175af295
# ╠═0db200ec-f27e-11ea-1950-a9d7e61afa63
# ╠═5973e55e-f27e-11ea-353c-41dab383b09d
# ╠═900ea8e2-f27e-11ea-3761-b108c219efc0
# ╠═a84c5c4c-f27e-11ea-304d-b54ef4bfdd80
# ╠═c11d3ce6-f27e-11ea-3e1d-bb7e6080bd82
# ╟─e7e5143e-f27e-11ea-3335-378eb2a0ffa1
# ╠═8d5bd6e0-f280-11ea-05a6-bbaa78cfaecd
# ╠═0cf36016-f27f-11ea-2165-bda0d94fa9da
# ╠═f11e8d0c-f281-11ea-32bd-1d9a3426aba8
# ╠═6af82be0-f281-11ea-317d-d349315bfe91
# ╠═8a4a4332-f281-11ea-23bd-c35f9ef897c9
# ╠═92a12de8-f281-11ea-1d6c-97f1edfa3156
# ╠═07913c56-f282-11ea-0e39-b950958fbe77
# ╠═7da308ac-f282-11ea-3f24-95dc931f0456
# ╠═804f6ffa-f282-11ea-1d17-ed258755405c
# ╠═0f2dea90-f7ff-11ea-3a2a-3b4ff3176ff4
# ╟─a7902b40-f7eb-11ea-24e8-49b97db4e0f8
# ╠═fb6968b0-f7fc-11ea-3b8c-9f8aeb89eb49
# ╠═faa26f2e-f7fc-11ea-0689-35a9fe9702ca
# ╠═fde2e240-f7fe-11ea-0ea2-377c6e99f379
# ╠═dd0c8d90-f7ff-11ea-0e50-d5eea9756d0c
# ╠═7645dd3e-f800-11ea-1dbd-55d7af40fb49
# ╠═8b03ec40-f800-11ea-1885-8b78f155da83
# ╠═ab35a710-f800-11ea-1e6f-8fdeffc51470
# ╠═03be2470-f801-11ea-153d-4fa68edc60f0
# ╠═1fc5a110-f802-11ea-3546-ffd6cfd1ac18
# ╠═236f210e-f802-11ea-1c0a-a96757d124ee
# ╠═37fc5180-f801-11ea-0280-211d18e7a5c0
# ╠═021d2930-f802-11ea-3e0c-673994053432
# ╠═9e6cd610-f801-11ea-3928-35eadc58071e
# ╠═260e5270-f801-11ea-03d7-27e618b8da3c
