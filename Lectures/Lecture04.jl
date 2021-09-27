### A Pluto.jl notebook ###
# v0.16.1

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

# ╔═╡ fe5b0068-f67d-11ea-11e2-5925e8699ff0
# Explicit use of own environment instead of a local one for each notebook
begin
	using Pkg
	cd(joinpath(dirname(@__FILE__),".."))
    Pkg.activate(pwd())
    using NativeSVG
	using Plots
end

# ╔═╡ f260f2c2-f67d-11ea-0132-4523bff8cea4
md"""# Self-Organized Criticality

Port of [Think Complexity chapter 8](http://greenteapress.com/complexity2/html/index.html) by Allen Downey."""

# ╔═╡ 1839ed8c-f67e-11ea-2c86-8954fe2d6dd5
md"""## Critical Systems

Many critical systems demonstrate common behaviors:

- Fractal geometry: For example, freezing water tends to form fractal patterns, including snowflakes and other crystal structures. Fractals are characterized by self-similarity; that is, parts of the pattern are similar to scaled copies of the whole.

- Heavy-tailed distributions of some physical quantities: For example, in freezing water the distribution of crystal sizes is characterized by a power law.

- Variations in time that exhibit pink noise: Complex signals can be decomposed into their frequency components. In pink noise, low-frequency components have more power than high-frequency components. Specifically, the power at frequency f is proportional to 1/f.

Critical systems are usually unstable. For example, to keep water in a partially frozen state requires active control of the temperature. If the system is near the critical temperature, a small deviation tends to move the system into one phase or the other."""

# ╔═╡ 2210e0ae-f67e-11ea-3052-87bff5a116fa
md"""## Sand Piles

The sand pile model was proposed by Bak, Tang and Wiesenfeld in 1987. It is not meant to be a realistic model of a sand pile, but rather an abstraction that models physical systems with a large number of elements that interact with their neighbors.

The sand pile model is a 2-D cellular automaton where the state of each cell represents the slope of a part of a sand pile. During each time step, each cell is checked to see whether it exceeds a critical value, `K`, which is usually 3. If so, it “topples” and transfers sand to four neighboring cells; that is, the slope of the cell is decreased by 4, and each of the neighbors is increased by 1. At the perimeter of the grid, all cells are kept at slope 0, so the excess spills over the edge.

Bak, Tang and Wiesenfeld initialize all cells at a level greater than `K` and run the model until it stabilizes. Then they observe the effect of small perturbations: they choose a cell at random, increment its value by 1, and run the model again until it stabilizes.

For each perturbation, they measure `T`, the number of time steps the pile takes to stabilize, and `S`, the total number of cells that topple.

Most of the time, dropping a single grain causes no cells to topple, so `T=1` and `S=0`. But occasionally a single grain can cause an avalanche that affects a substantial fraction of the grid. The distributions of `T` and `S` turn out to be heavy-tailed, which supports the claim that the system is in a critical state.

They conclude that the sand pile model exhibits “self-organized criticality”, which means that it evolves toward a critical state without the need for external control or what they call “fine tuning” of any parameters. And the model stays in a critical state as more grains are added.

In the next few sections I replicate their experiments and interpret the results."""

# ╔═╡ 2a6c14b2-f67e-11ea-0ad1-db86beb0602a
md"""## Implementation"""

# ╔═╡ 539a8576-f67e-11ea-07ba-b11f07f7ad39
function applytoppling(array::Array{Int64, 2}, K::Int64=3)
    out = copy(array)
    (ydim, xdim) = size(array)
    numtoppled = 0
    for y in 2:ydim-1
        for x in 2:xdim-1
            if array[y,x] > K
                numtoppled += 1
                out[y-1:y+1,x-1:x+1] += [0 1 0;1 -4 1;0 1 0]
            end
        end
    end
    out[1,:] .= 0
    out[end, :] .= 0
    out[:, 1] .= 0
    out[:, end] .= 0
    out, numtoppled
end

# ╔═╡ 5c141fe6-f67e-11ea-343f-bf6e672aa0ca
function visualizepile(array::Array{Int64, 2}, dim, scale)
    (ydim, xdim) = size(array)
    width = dim * (xdim - 1)
    height = dim * (ydim - 1)
    Drawing(width=width, height=height) do
		for (j, y) in enumerate(2:ydim-1)
			for (i, x) in enumerate(2:xdim-1)
				gray = 100*(1-array[y,x]/scale)
				fill = "rgb($gray%,$gray%,$gray%"
				rect(x=i*dim, y=j*dim, width=dim, height=dim, fill=fill)
			end
		end
	end
end

# ╔═╡ b95e615e-f67e-11ea-3d58-b5166ea2c0ca
function steptoppling(array::Array{Int64, 2}, K::Int64=3)
    total = 0
    i = 0
    while true
        array, numtoppled = applytoppling(array, K)
        total += numtoppled
        i += 1
        if numtoppled == 0
            return array, i, total
        end
    end
end

# ╔═╡ ff579efa-f67e-11ea-0f08-999fb18421c3
mutable struct Pile
	array::Array{Int64, 2}
	function Pile(dim::Int64, initial::Int64)
		pile = zeros(Int64, dim, dim)
		pile[2:end-1, 2:end-1] = initial * ones(Int64, dim-2, dim-2)
		new(pile)
	end
end

# ╔═╡ a1683e6e-f67f-11ea-2b79-8552ffaa92e3
pile20 = Pile(22, 10);

# ╔═╡ af120f36-f67f-11ea-2825-e14581e0ded8
visualizepile(pile20.array, 30, 10)

# ╔═╡ d04bea1e-f67f-11ea-1bc8-5bbd9a7666f0
begin
	pile20.array, steps, total = steptoppling(pile20.array);
	steps, total
end

# ╔═╡ f3adf3f8-f67f-11ea-2a18-7d2f8d93e817
visualizepile(pile20.array, 30, 10)

# ╔═╡ fa60b5aa-f67f-11ea-3ec0-bfaf222f3415
md"""With an initial level of 10, this sand pile takes 332 time steps to reach equilibrium, with a total of 53,336 topplings. The figure shows the configuration after this initial run. Notice that it has the repeating elements that are characteristic of fractals. We’ll come back to that soon."""

# ╔═╡ ef1f49cc-f67f-11ea-04e9-817d6bc2c902
function drop(array::Array{Int64, 2})
    (ydim, xdim) = size(array)
    y = rand(2:ydim-1)
    x = rand(2:xdim-1)
    array[y,x] += 1
    array
end

# ╔═╡ 6f3dcd7c-f680-11ea-2929-f94b53bd7a67
function runtoppling(array::Array{Int64, 2}, iter=200)
    array, steps, total = steptoppling(array, 3)
    for _ in 1:iter
        array = drop(array)
        array, steps, total = steptoppling(array, 3)
    end
    array
end

# ╔═╡ 79230ffa-f680-11ea-3432-4d50e71a2935
@bind toggletoppling html"<input type=button value='Next'>"

# ╔═╡ b1472044-f67e-11ea-0c87-5be8f6114fef
if toggletoppling === "Next"
	for _ in 1:10
		pile20.array = drop(pile20.array)
    	pile20.array, steps, total = steptoppling(pile20.array)
	end
	visualizepile(pile20.array, 30, 10)
end

# ╔═╡ 082bbb5c-f681-11ea-007a-f5a8df45b69d
md"""The figure shows the configuration of the sand pile after dropping 200 grains onto random cells, each time running until the pile reaches equilibrium. The symmetry of the initial configuration has been broken; the configuration looks random."""

# ╔═╡ 0d14ce24-f681-11ea-1637-5f4cf290f81d
begin
	for _ in 1:200
    	pile20.array = drop(pile20.array)
    	pile20.array, steps, total = steptoppling(pile20.array)
	end
	visualizepile(pile20.array, 30, 10)
end

# ╔═╡ 39100fb6-f681-11ea-0e1e-693359773c9c
md"""Finally the figure shows the configuration after 400 drops. It looks similar to the configuration after 200 drops. In fact, the pile is now in a steady state where its statistical properties don’t change over time. I’ll explain some of those statistical properties in the next section."""

# ╔═╡ 42cc5096-f681-11ea-0744-5d078169fd28
md"""## Heavy-Tailed Distributions

If the sand pile model is in a critical state, we expect to find heavy-tailed distributions for quantities like the duration and size of avalanches. So let’s take a look.

I’ll make a larger sand pile, with n=50 and an initial level of 30, and run until equilibrium:"""

# ╔═╡ 4f12ad3c-f681-11ea-31e4-1ddc4d78694e
pile50 = Pile(50, 30);

# ╔═╡ b7a0ce92-f681-11ea-02f4-a1c18dc06c73
md"""Next, I’ll run 100,000 random drops."""

# ╔═╡ c38c4bb4-f681-11ea-2569-85142c07e21e
durations, avalanches = begin
	durations = Int64[]
	avalanches = Int64[]
	for _ in 1:100000
		pile50.array = drop(pile50.array)
		pile50.array, steps, total = steptoppling(pile50.array)
		push!(durations, steps)
		push!(avalanches, total)
	end
	filter(steps->steps>1, durations), filter(total->total>0, avalanches);
end

# ╔═╡ 00597288-f682-11ea-31d4-278441aaca2c
md"""A large majority of drops have duration 1 and no toppled cells; if we filter them out before plotting, we get a clearer view of the rest of the distribution.

We build a histogram with the durations/avalanches as keys and their occurences as values."""

# ╔═╡ 19c9c10a-f682-11ea-235a-1b78e0af52b4
function hist(array)
    h = Dict()
    for v in array
        h[v] = get!(h, v, 0) + 1
    end
    h
end

# ╔═╡ 5e3575ee-f682-11ea-3df7-5f4b9439c646
md"""We plot the probabilities of each value of the durations / avalanches with loglog axes."""

# ╔═╡ 71e25a5a-f682-11ea-006f-abcdefc354c2
let
	h = hist(durations)
	total = sum(values(h))
	x = Int64[]
	y = Float64[]
	for i in 2:maximum(collect(keys(h)))
		v = get(h, i, 0)
		if v ≠ 0
			push!(x, i)
			push!(y, v/total)
		end
	end
	plot(x, y, xaxis=:log, yaxis=:log, label="Durations")
	h = hist(avalanches)
	total = sum(values(h))
	x = Int64[]
	y = Float64[]
	for i in 1:maximum(collect(keys(h)))
		v = get(h, i, 0)
		if v ≠ 0
			push!(x, i)
			push!(y, v/total)
		end
	end
	plot!(x, y, xaxis=:log, yaxis=:log, label="Avalanches")
	x = collect(1:5000)
	plot!(x, 1 ./ x, label="slope -1")
end

# ╔═╡ 93ff6fce-f682-11ea-375f-691a773a4015
md"""For values between 1 and 100, the distributions are nearly straight on a log-log scale, which is characteristic of a heavy tail. The gray lines in the figure have slopes near -1, which suggests that these distributions follow a power law with parameters near α=1.

For values greater than 100, the distributions fall away more quickly than the power law model, which means there are fewer very large values than the model predicts. One possibility is that this effect is due to the finite size of the sand pile; if so, we might expect larger piles to fit the power law better."""

# ╔═╡ 89a1673a-f682-11ea-3839-a13baae73084
md"""## Fractals

Another property of critical systems is fractal geometry. The initial configuration resembles a fractal, but you can’t always tell by looking. A more reliable way to identify a fractal is to estimate its fractal dimension, as we saw in previous lectures.

I’ll start by making a bigger sand pile, with `n=131` and initial level 22."""

# ╔═╡ e3bc11fc-f682-11ea-092b-df0887d4e0b1
pile131 = Pile(133, 22);

# ╔═╡ 011377c2-f683-11ea-0bf0-9f3f1ee4d0d2
let
	pile131.array, steps, total = steptoppling(pile131.array)
	steps, total
end

# ╔═╡ 44db4192-f683-11ea-385a-692911a834bd
visualizepile(pile131.array, 4, 10)

# ╔═╡ 66ddeb8c-f683-11ea-3a68-6f1e4f0f5cc0
md"""It takes 28,379 steps for this pile to reach equilibrium, with more than 200 million cells toppled.
To see the resulting pattern more clearly, I select cells with levels 0, 1, 2, and 3, and plot them separately:"""

# ╔═╡ 769bfda2-f683-11ea-1103-7302a19f909f
function visualizepileonekind(pile, dim, val)
    (ydim, xdim) = size(pile)
    width = dim * (xdim - 1)
    height = dim * (ydim - 1)
    Drawing(width=width, height=height) do
		for (j, y) in enumerate(2:ydim-1)
			for (i, x) in enumerate(2:xdim-1)
				if pile[y,x] == val
					rect(x=i*dim, y=j*dim, width=dim, height=dim, fill="gray")
				end
			end
		end
	end
end

# ╔═╡ bc1f2d22-f683-11ea-1dcc-21b4e3a235d2
visualizepileonekind(pile131.array, 4, 0) # 0, 1, 2, 3

# ╔═╡ d0a5d958-f683-11ea-0f60-2189804eedd2
md"""Visually, these patterns resemble fractals, but looks can be deceiving. To be more confident, we can estimate the fractal dimension for each pattern using box-counting.

We’ll count the number of cells in a small box at the center of the pile, then see how the number of cells increases as the box gets bigger. Here’s my implementation:"""

# ╔═╡ dc3aa8ac-f683-11ea-07a3-1dd0b339ed20
function countcells(pile, val)
    (ydim, xdim) = size(pile)
    ymid = Int((ydim+1)/2)
    xmid = Int((xdim+1)/2)
    res = Int64[]
    for i in 0:Int((ydim-1)/2)-1
        push!(res, 1.0*count(x->x==val, pile[ymid-i:ymid+i,xmid-i:xmid+i]))
    end
    res
end

# ╔═╡ cf14e6b0-f683-11ea-22d8-51ac2e84ae1f
let 
	level = 0
	(ydim, xdim) = size(pile131.array)
	m = Int((ydim-1)/2)
	res = filter(x->x>0, countcells(pile131.array, level))
	n = length(res)
	plot(1:2:2*m-1, 1:2:2*m-1, xaxis=:log, yaxis=:log, label="d = 1")
	plot!(1:2:2*m-1, (1:2:2*m-1).^2, xaxis=:log, yaxis=:log, label="d = 2")
	plot!(1+2*(m-n):2:2*m-1, res, xaxis=:log, yaxis=:log, label="level $level")
	level = 1
	res = filter(x->x>0, countcells(pile131.array, level))
	n = length(res)
	plot!(1+2*(m-n):2:2*m-1, res, xaxis=:log, yaxis=:log, label="level $level")
	level = 2
	res = filter(x->x>0, countcells(pile131.array, level))
	n = length(res)
	plot!(1+2*(m-n):2:2*m-1, res, xaxis=:log, yaxis=:log, label="level $level")
	level = 3
	res = filter(x->x>0, countcells(pile131.array, level))
	n = length(res)
	plot!(1+2*(m-n):2:2*m-1, res, xaxis=:log, yaxis=:log, label="level $level", legend=:topleft)
end

# ╔═╡ 1d2387c6-f684-11ea-28cc-bb2ad15a66ab
md"""On a log-log scale, the cell counts form nearly straight lines, which indicates that we are measuring fractal dimension over a valid range of box sizes.

To estimate the slopes of these lines, we have to fot a line to the data by linear regression"""

# ╔═╡ cd1481b0-f683-11ea-3e20-2b9af0d081f5
function linres(x, y)
    n = length(x)
    mx = sum(x) / n
    my = sum(y) / n
    beta = sum((x.-mx).*(y.-my))/sum((x.-mx).^2)
    alfa = my - beta * mx
    alfa, beta
end

# ╔═╡ c8b9148a-f683-11ea-2fad-d7483faa2329
let
	level = 0
	(ydim, xdim) = size(pile131.array)
	m = Int((ydim-1)/2)
	res = filter(x->x>0, countcells(pile131.array, level))
	n = length(res)
	linres(log.(1.0*collect(1+2*(m-n):2:2*m-1)), log.(res))
end

# ╔═╡ 5633e222-f684-11ea-3106-2bd51ce7d45e
md"""The estimated fractal dimensions are:

0. 1.868
1. 3.494
2. 1.784
3. 2.081"""

# ╔═╡ Cell order:
# ╟─f260f2c2-f67d-11ea-0132-4523bff8cea4
# ╠═fe5b0068-f67d-11ea-11e2-5925e8699ff0
# ╟─1839ed8c-f67e-11ea-2c86-8954fe2d6dd5
# ╟─2210e0ae-f67e-11ea-3052-87bff5a116fa
# ╟─2a6c14b2-f67e-11ea-0ad1-db86beb0602a
# ╠═539a8576-f67e-11ea-07ba-b11f07f7ad39
# ╠═5c141fe6-f67e-11ea-343f-bf6e672aa0ca
# ╠═b95e615e-f67e-11ea-3d58-b5166ea2c0ca
# ╠═ff579efa-f67e-11ea-0f08-999fb18421c3
# ╠═a1683e6e-f67f-11ea-2b79-8552ffaa92e3
# ╠═af120f36-f67f-11ea-2825-e14581e0ded8
# ╠═d04bea1e-f67f-11ea-1bc8-5bbd9a7666f0
# ╠═f3adf3f8-f67f-11ea-2a18-7d2f8d93e817
# ╟─fa60b5aa-f67f-11ea-3ec0-bfaf222f3415
# ╠═ef1f49cc-f67f-11ea-04e9-817d6bc2c902
# ╠═6f3dcd7c-f680-11ea-2929-f94b53bd7a67
# ╠═79230ffa-f680-11ea-3432-4d50e71a2935
# ╠═b1472044-f67e-11ea-0c87-5be8f6114fef
# ╟─082bbb5c-f681-11ea-007a-f5a8df45b69d
# ╠═0d14ce24-f681-11ea-1637-5f4cf290f81d
# ╟─39100fb6-f681-11ea-0e1e-693359773c9c
# ╟─42cc5096-f681-11ea-0744-5d078169fd28
# ╠═4f12ad3c-f681-11ea-31e4-1ddc4d78694e
# ╟─b7a0ce92-f681-11ea-02f4-a1c18dc06c73
# ╠═c38c4bb4-f681-11ea-2569-85142c07e21e
# ╟─00597288-f682-11ea-31d4-278441aaca2c
# ╠═19c9c10a-f682-11ea-235a-1b78e0af52b4
# ╟─5e3575ee-f682-11ea-3df7-5f4b9439c646
# ╠═71e25a5a-f682-11ea-006f-abcdefc354c2
# ╟─93ff6fce-f682-11ea-375f-691a773a4015
# ╟─89a1673a-f682-11ea-3839-a13baae73084
# ╠═e3bc11fc-f682-11ea-092b-df0887d4e0b1
# ╠═011377c2-f683-11ea-0bf0-9f3f1ee4d0d2
# ╠═44db4192-f683-11ea-385a-692911a834bd
# ╟─66ddeb8c-f683-11ea-3a68-6f1e4f0f5cc0
# ╠═769bfda2-f683-11ea-1103-7302a19f909f
# ╠═bc1f2d22-f683-11ea-1dcc-21b4e3a235d2
# ╟─d0a5d958-f683-11ea-0f60-2189804eedd2
# ╠═dc3aa8ac-f683-11ea-07a3-1dd0b339ed20
# ╠═cf14e6b0-f683-11ea-22d8-51ac2e84ae1f
# ╟─1d2387c6-f684-11ea-28cc-bb2ad15a66ab
# ╠═cd1481b0-f683-11ea-3e20-2b9af0d081f5
# ╠═c8b9148a-f683-11ea-2fad-d7483faa2329
# ╟─5633e222-f684-11ea-3106-2bd51ce7d45e
