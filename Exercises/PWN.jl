### A Pluto.jl notebook ###
# v0.11.12

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
	mycmap = ColorGradient([RGBA(0/255,0/255,0/255),
    RGBA(0/255,0/255,255/255),
    RGBA(255/255,0/255,0/255),
    RGBA(0/255,255/255,0/255),
    RGBA(255/255,255/255,0/255),
    RGBA(255/255,0/255,255/255),
    RGBA(255/255,255/255,255/255),
    RGBA(0/255,255/255,255/255)]);
	heatmap(start, yflip=true, color=mycmap)
end

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
