### A Pluto.jl notebook ###
# v0.11.14

using Markdown
using InteractiveUtils

# ╔═╡ 7950392c-f279-11ea-16cd-117125c04757
using Plots

# ╔═╡ 6be0aea8-f273-11ea-20a8-b9e192d2df7c
md"""# PW - N
Langton
* werk lokaal
* ken uw computer (waar staat mijn data/waar staat mijn notebook/waar ben ik aan het werk?)
"""


# ╔═╡ 76aac224-f273-11ea-38d8-81a3efd97984
# waar ben ik an het werken
pwd()

# ╔═╡ f1476d90-f274-11ea-20a1-1dd4670be6d9
# wat bestaat er in mijn pwd?
readdir(pwd())

# ╔═╡ 930cbd5a-f273-11ea-1ef5-1324cc695386
# relatief path
readdir("./data/")

# ╔═╡ 13990aea-f275-11ea-363d-8b94278d165e
# absoluut path
readdir("/Users/bart/Documents/Stack/ES313/ES313.jl/Exercises/data/")

# ╔═╡ b6f1587a-f273-11ea-0cd3-5b035ae9d0e4
r = readlines("./data/Langtonsrules.txt")

# ╔═╡ 1886dc3e-f276-11ea-234d-6d4368d5e6eb
split(r[1],"")

# ╔═╡ c1ff5738-f275-11ea-3dd2-b9e753043688
begin 
	res = parse.(Int,split(r[1],""))
	current = res[1]
	neighbors = res[2:5]
	next = res[6]
	println("current $(current) with neighbords $(neighbors) becomes $(next)")
end

# ╔═╡ 8097b168-f276-11ea-389b-358431906bc8
function getrules(path::String)
	r = readlines(path)
	# initiate rule dict
	d = Dict()
	for rule in r
		# parse rule
		res = parse.(Int,split(rule,""))
		current = res[1]
		neighbors = res[2:5]
		next = res[6]
		# add rule to dict
		for i in 0:3
			println("current $(current) with neighbords $(neighbors) becomes $(next)")
			get!(get!(d,current,Dict(circshift(neighbors,i)=>next)), circshift(neighbors,i), next)
		end
	end
	d
end

# ╔═╡ be1dcdb8-f278-11ea-0794-f7497b0283e0
d =getrules("./data/Langtonsrules.txt")

# ╔═╡ 13d8d032-f278-11ea-21a1-7327e1e5f8ed
d[1][[1,0,2,2]]

# ╔═╡ ec80dad8-f278-11ea-0f69-7fc4b77a4853
readlines("./data/Langtonstart.txt")

# ╔═╡ 064d8dee-f279-11ea-393a-154c73a1bc9b
# inlezen startsitutie
begin
	s = readlines("./data/Langtonstart.txt")
	start = permutedims( hcat( [parse.(Int,split(line,"")) for line in s]...) )
end

# ╔═╡ 7d196e40-f279-11ea-09be-1b2902d25369
begin
	mycmap = cgrad([RGBA(0/255,0/255,0/255),
    RGBA(0/255,0/255,255/255),
    RGBA(255/255,0/255,0/255),
    RGBA(0/255,255/255,0/255),
    RGBA(255/255,255/255,0/255),
    RGBA(255/255,0/255,255/255),
    RGBA(255/255,255/255,255/255),
    RGBA(0/255,255/255,255/255)]);
	heatmap(start, yflip=true, color=mycmap)
end

# ╔═╡ 6de438f0-f7eb-11ea-0932-cfa0f78d7cd4
md"""resterende taken van vandaag:
* implementeren van startsituatie in groter veld
* updates realiseren
* animeren
"""

# ╔═╡ f039e0e0-f7f3-11ea-3385-bf1224bda003
size(start)

# ╔═╡ 3f646880-f7f3-11ea-1b48-9386ca64e247
# creëren vd wereld - start in midden
function genworld(start, dims)
	# input check
	ssize = size(start)
	if any(ssize .>= dims)
		error("world dimensions not OK")
	end
	# initialisatie
	world = zeros(Int,dims...)
	# vullen
	i = round(Int,(dims[1] - ssize[1])/2) + 1
	j = round(Int,(dims[2] - ssize[2])/2) + 1
	world[i:i+ssize[1]-1, j:j+ssize[2]-1] = start
	
	return world
end


# ╔═╡ 42662f70-f7f6-11ea-27d5-7d9c6a3d289a
size(start)

# ╔═╡ af920f40-f7f3-11ea-0487-1352825d5983
world = genworld(start,(14,20))

# ╔═╡ 66be144e-f7f6-11ea-31a0-f9f5407a8e79


# ╔═╡ 4a098770-f7f8-11ea-2335-0d281a74ae3d
"""
	updateworld!(world, rules)

update the current world (modifying it)
"""
function updateworld!(world, rules)
	# nieuwe staat initialiseren
	newworld = zeros(Int, size(world))
	# voor iedere locatie nieuwe toestand bepalen
	for i in 2:size(world,1)-1
		for j in 2:size(world,2)-1
			newworld[i,j] = rules[world[i,j]][[world[i-1,j],world[i,j+1],world[i+1,j], world[i,j-1]]]
		end
	end
	@show world .== newworld
	world = copy(newworld)
end

# ╔═╡ 9a2138c0-f7f8-11ea-3a7d-87737a676985
begin
	updateworld!(world, d)
	world
end

# ╔═╡ e2ec52b0-f7f8-11ea-0f27-237ed18a5dc6
typeof(updateworld!(world,d))

# ╔═╡ bb636410-f7f6-11ea-177d-8d31331fe198
function updateworld(world, rules)
	# nieuwe staat initialiseren
	newworld = zeros(Int, size(world))
	# voor iedere locatie nieuwe toestand bepalen
	for i in 2:size(world,1)-1
		for j in 2:size(world,2)-1
			newworld[i,j] = rules[world[i,j]][[world[i-1,j],world[i,j+1],world[i+1,j], world[i,j-1]]]
		end
	end
	return newworld
end

# ╔═╡ 7d265b70-f7f7-11ea-3893-a3262c84ccbe
heatmap(updateworld(world, d), yflip=true, color=mycmap, size=(200,250))

# ╔═╡ b80b6a00-f7f7-11ea-3be5-9b94c64f465a
heatmap(world, yflip=true, color=mycmap, size=(200,250))

# ╔═╡ a5799ef0-f7f9-11ea-01fa-5b10e3cd3d24
function changeme!(A)
	B = similar(A)
	for i in eachindex(A)
		B[i] = A[i] + sum(i)
	end
	A = deepcopy(B)
end

# ╔═╡ a551cb9e-f7f9-11ea-345f-0f23a31af889
A = ones(Int, 4,4)

# ╔═╡ a543e8f0-f7f9-11ea-23ad-c195f4ba1172
for i in 1:10
	changeme!(A)
	println(A)
end

# ╔═╡ 0b0d09f0-f7fa-11ea-2091-5b2b8608911e
changeme!(A)

# ╔═╡ Cell order:
# ╠═6be0aea8-f273-11ea-20a8-b9e192d2df7c
# ╠═76aac224-f273-11ea-38d8-81a3efd97984
# ╠═f1476d90-f274-11ea-20a1-1dd4670be6d9
# ╠═930cbd5a-f273-11ea-1ef5-1324cc695386
# ╠═13990aea-f275-11ea-363d-8b94278d165e
# ╠═b6f1587a-f273-11ea-0cd3-5b035ae9d0e4
# ╠═1886dc3e-f276-11ea-234d-6d4368d5e6eb
# ╠═c1ff5738-f275-11ea-3dd2-b9e753043688
# ╠═8097b168-f276-11ea-389b-358431906bc8
# ╠═be1dcdb8-f278-11ea-0794-f7497b0283e0
# ╠═13d8d032-f278-11ea-21a1-7327e1e5f8ed
# ╠═ec80dad8-f278-11ea-0f69-7fc4b77a4853
# ╠═064d8dee-f279-11ea-393a-154c73a1bc9b
# ╠═7950392c-f279-11ea-16cd-117125c04757
# ╠═7d196e40-f279-11ea-09be-1b2902d25369
# ╟─6de438f0-f7eb-11ea-0932-cfa0f78d7cd4
# ╠═f039e0e0-f7f3-11ea-3385-bf1224bda003
# ╠═3f646880-f7f3-11ea-1b48-9386ca64e247
# ╠═42662f70-f7f6-11ea-27d5-7d9c6a3d289a
# ╠═af920f40-f7f3-11ea-0487-1352825d5983
# ╠═66be144e-f7f6-11ea-31a0-f9f5407a8e79
# ╠═9a2138c0-f7f8-11ea-3a7d-87737a676985
# ╠═e2ec52b0-f7f8-11ea-0f27-237ed18a5dc6
# ╠═4a098770-f7f8-11ea-2335-0d281a74ae3d
# ╠═bb636410-f7f6-11ea-177d-8d31331fe198
# ╠═7d265b70-f7f7-11ea-3893-a3262c84ccbe
# ╠═b80b6a00-f7f7-11ea-3be5-9b94c64f465a
# ╠═a5799ef0-f7f9-11ea-01fa-5b10e3cd3d24
# ╠═a551cb9e-f7f9-11ea-345f-0f23a31af889
# ╠═a543e8f0-f7f9-11ea-23ad-c195f4ba1172
# ╠═0b0d09f0-f7fa-11ea-2091-5b2b8608911e
