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

# ╔═╡ 1d6260d4-f663-11ea-03da-efe9ed63f9bd
using NativeSVG

# ╔═╡ 22d23c18-f66f-11ea-2056-71e534b3bf1d
using Pkg # one time

# ╔═╡ 4e03615a-f66f-11ea-244f-85f4c21a111b
using Plots

# ╔═╡ e6ff0e98-f662-11ea-03a7-e3d09e6272a6
md"""# Physical Modelling

Port of [Think Complexity chapter 7](http://greenteapress.com/complexity2/html/index.html) by Allen Downey."""

# ╔═╡ 2abf49e0-f663-11ea-25f3-2f9229de732e
md"""## Diffusion

In 1952 Alan Turing published a paper called “The chemical basis of morphogenesis”, which describes the behavior of systems involving two chemicals that diffuse in space and react with each other. He showed that these systems produce a wide range of patterns, depending on the diffusion and reaction rates, and conjectured that systems like this might be an important mechanism in biological growth processes, particularly the development of animal coloration patterns.

Turing’s model is based on differential equations, but it can be implemented using a cellular automaton.

Before we get to Turing’s model, we’ll start with something simpler: a diffusion system with just one chemical. We’ll use a 2-D CA where the state of each cell is a continuous quantity (usually between 0 and 1) that represents the concentration of the chemical.

We’ll model the diffusion process by comparing each cell with the average of its neighbors. If the concentration of the center cell exceeds the neighborhood average, the chemical flows from the center to the neighbors. If the concentration of the center cell is lower, the chemical flows the other way.

We’ll use a diffusion constant, `r`, that relates the difference in concentration to the rate of flow:"""

# ╔═╡ 40373f12-f663-11ea-256c-abd1458a8e85
function applydiffusion(array::Array{Float64, 2}, r::Float64=0.1)
    nr_y, nr_x = size(array)
    out = deepcopy(array)
    for y in 2:nr_y-1
        for x in 2:nr_x-1
            c = array[y-1, x] + array[y, x-1] + array[y, x+1] + array[y+1, x] - 4*array[y, x]
            out[y, x] += r*c
        end
    end
    out
end

# ╔═╡ 52f4e280-f663-11ea-38a4-c52a7b06b564
md"""visualisation:"""

# ╔═╡ 61437b46-f663-11ea-12c6-2ff992812dca
function visualizearray(array::Array{Float64, 2}, dim)
    (nr_y, nr_x) = size(array)
    width = dim * (nr_x - 1)
    height = dim * (nr_y - 1)
    Drawing(width=width, height=height) do
		for (j, y) in enumerate(2:nr_y-1)
			for (i, x) in enumerate(2:nr_x-1)
				gray = 80*(1-array[y, x])+10
				fill = "rgb($gray%,$gray%,$gray%"
				rect(x=i*dim, y=j*dim, width=dim, height=dim, fill=fill)
			end
		end
	end
end

# ╔═╡ 7f66f30e-f667-11ea-34e8-d315ed180b75


# ╔═╡ 358ac3e2-f666-11ea-2058-11eedeabff5f
mutable struct Diffusion
	array :: Array{Float64, 2}
	function Diffusion()
		diffusion = new(zeros(Float64, 11, 11))
		diffusion.array[5:7, 5:7] = ones(Float64, 3, 3)
		diffusion
	end
end

# ╔═╡ 863a3fa4-f664-11ea-2597-8f18f2a862ac
diffusion = Diffusion();

# ╔═╡ 966fc752-f666-11ea-1794-195433f4cce5
visualizearray(diffusion.array, 30)

# ╔═╡ b0148fb4-f664-11ea-2d64-976658b08661
@bind togglediffusion html"<input type=button value='Next'>"

# ╔═╡ b25969c4-f665-11ea-222b-df9786a710d2
if togglediffusion === "Next"
	diffusion.array = applydiffusion(diffusion.array)
	visualizearray(diffusion.array, 30)
end

# ╔═╡ 95dc78e8-f667-11ea-1c07-8f5cc11b011b
begin
	for _ in 1:1000
    	diffusion.array = applydiffusion(diffusion.array)
	end
	visualizearray(diffusion.array, 30)
end

# ╔═╡ c03905f2-f667-11ea-3484-b111f7c14f60
md"""## Reaction-Diffusion

Now let’s add a second chemical."""

# ╔═╡ cf7c1a2c-f667-11ea-358f-df431ec27476
function applyreactiondiffusion(
        a::Array{Float64, 2}, 
        b::Array{Float64, 2}, 
        ra::Float64=0.5, rb::Float64=0.25, 
        f::Float64=0.055, k::Float64=0.062)
    nr_y, nr_x = size(a)
    a_out = deepcopy(a)
    b_out = deepcopy(b)
    for y in 2:nr_y-1
        for x in 2:nr_x-1
            reaction = a[y, x] * b[y, x]^2
            ca = 0.25*(a[y-1, x] + a[y, x-1] + a[y, x+1] + a[y+1, x]) - a[y, x]
            cb = 0.25*(b[y-1, x] + b[y, x-1] + b[y, x+1] + b[y+1, x]) - b[y, x]
            a_out[y, x] += ra*ca - reaction + f * (1 - a[y, x])
            b_out[y, x] += rb*cb + reaction - (f+k) * b[y, x]
        end
    end
    a_out, b_out
end

# ╔═╡ 0a815d80-f668-11ea-0dd3-9155b36a4134
md"""- `ra`: The diffusion rate of A (analogous to `r` in the previous section).
- `rb`: The diffusion rate of B. In most versions of this model, `rb` is about half of `ra`.
- `f`: The “feed” rate, which controls how quickly A is added to the system.
- `k`: The “kill” rate, which controls how quickly B is removed from the system.

`ca` and `ca` are the result of applying a diffusion kernel to A and B. Multiplying by `ra` and `rb` yields the rate of diffusion into or out of each cell.

The term `a*b^2` represents the rate that A and B react with each other. Assuming that the reaction consumes A and produces B, we subtract this term in the first equation and add it in the second.

The term `f * (1-a)` determines the rate that A is added to the system. Where A is near 0, the maximum feed rate is `f`. Where A approaches 1, the feed rate drops off to zero.

Finally, the term `(f+k) * b` determines the rate that B is removed from the system. As B approaches 0, this rate goes to zero.

As long as the rate parameters are not too high, the values of A and B usually stay between 0 and 1."""

# ╔═╡ 23f98030-f668-11ea-389b-ff911adaadfd
mutable struct ReactionDiffusion
	a::Array{Float64, 2}
    b::Array{Float64, 2}
	function ReactionDiffusion()
		reactiondiffusion = new(ones(Float64, 258, 258), rand(Float64, 258, 258)*0.1)
		reactiondiffusion.b[129-12:129+12, 129-12:129+12] += ones(Float64, 25, 25)*0.1
		reactiondiffusion
	end
end

# ╔═╡ 3c706f38-f669-11ea-2266-f743535073b5
reactiondiffusion = ReactionDiffusion();

# ╔═╡ 1b551fc2-f669-11ea-0d2f-ad0e089592d8
visualizearray(reactiondiffusion.b, 2)

# ╔═╡ e1988846-f668-11ea-1b26-8f7dca1bb4e7
@bind togglereactiondiffusion html"<input type=button value='Next'>"

# ╔═╡ dda066c0-f668-11ea-3096-bdea16f40db7
# f = 0.035, 0.055, 0.039 k = 0.057, 0.062, 0.065
if togglereactiondiffusion === "Next"
	for _ in 1:500
		reactiondiffusion.a, reactiondiffusion.b = applyreactiondiffusion(reactiondiffusion.a, reactiondiffusion.b, 0.5, 0.25, 0.035, 0.057)
	end
	visualizearray(reactiondiffusion.b, 2)
end

# ╔═╡ 1734b35e-f66a-11ea-10b4-317d12008809
md"""Since 1952, observations and experiments have provided some support for Turing’s conjecture. At this point it seems likely, but not yet proven, that many animal patterns are actually formed by reaction-diffusion processes of some kind."""

# ╔═╡ 40f84b2e-f66a-11ea-1dc7-3ded9e11af06
md"""## Percolation

Percolation is a process in which a fluid flows through a semi-porous material. Examples include oil in rock formations, water in paper, and hydrogen gas in micropores. Percolation models are also used to study systems that are not literally percolation, including epidemics and networks of electrical resistors.

We’ll explore a 2-D CA that simulates percolation.

- Initially, each cell is either “porous” with probability `q` or “non-porous” with probability `1-q`.
- When the simulation begins, all cells are considered “dry” except the top row, which is “wet”.
- During each time step, if a porous cell has at least one wet neighbor, it becomes wet. Non-porous cells stay dry.
- The simulation runs until it reaches a “fixed point” where no more cells change state.

If there is a path of wet cells from the top to the bottom row, we say that the CA has a “percolating cluster”.

Two questions of interest regarding percolation are (1) the probability that a random array contains a percolating cluster, and (2) how that probability depends on `q`."""

# ╔═╡ 77dcd828-f66a-11ea-0942-c5d613d828b7
function applypercolation(array::Array{Float64, 2})
    nr_y, nr_x = size(array)
    out = deepcopy(array)
    for y in 2:nr_y-1
        for x in 2:nr_x-1
            if out[y, x] > 0.0
                c = array[y-1, x] + array[y, x-1] + array[y, x+1] + array[y+1, x]
                if c ≥ 0.5
                    out[y, x] = 0.5
                end
            end
        end
    end
    out
end

# ╔═╡ 818e5534-f66a-11ea-07b2-7722084e1e07
md"visualisation:"

# ╔═╡ 44c8b17a-f66b-11ea-39af-f554593e33eb
mutable struct Wall
	array::Array{Float64, 2}
	function Wall(n, q)
    	array = zeros(Float64, n+2, n+2)
		array[2, 2:n+1] = ones(Float64, n)*0.5
		array[3:n+1, 2:n+1] = rand(Float64, n-1, n)
		for y in 3:n+1
			for x in 2:n+1
				if array[y, x] < q
					array[y, x] = 0.1
				else
					array[y, x] = 0.0
				end
			end
		end
		new(array)
	end
end

# ╔═╡ d9ccf8f8-f66b-11ea-2c81-0d771c2e900e
wall = Wall(100, 0.62);

# ╔═╡ e492630e-f66b-11ea-3aed-f37a400243be
visualizearray(wall.array, 8)

# ╔═╡ e048231c-f66b-11ea-191d-8517a6c65bc5
@bind togglepercolation html"<input type=button value='Next'>"

# ╔═╡ 11847488-f66c-11ea-1aca-4b1613dbfb8e
if togglepercolation === "Next"
	wall.array = applypercolation(wall.array)
	visualizearray(wall.array, 8)
end

# ╔═╡ 3563b208-f66c-11ea-3c1a-77f799805d06
md"""## Phase Change

Now let’s test whether a random array contains a percolating cluster."""

# ╔═╡ 2b9c8a86-f66c-11ea-0447-1fb7ba83d3a1
function testpercolation(array::Array{Float64, 2}, vis=false)
    numberwet = count(x->x==0.5, array[3:101, 2:101])
    while true
        array = applypercolation(array)
        if count(x->x==0.5, array[101, 2:101]) > 0
			if vis
				return true, visualizearray(array, 8) 
			else
            	return true
			end
        end
        newnumberwet = count(x->x==0.5, array[3:101, 2:101])
        if numberwet == newnumberwet
            if vis
				return false, visualizearray(array, 8)
			else
            	return false
			end
        end
        numberwet = newnumberwet
    end
end

# ╔═╡ c71f0f24-f66c-11ea-0ba7-d765f3998ed9
let
	wall = Wall(100, 0.5)
	result, drawing = testpercolation(wall.array, true)
	drawing
end

# ╔═╡ e51771ec-f66c-11ea-1606-fd159b8d216f
md"""To estimate the probability of a percolating cluster, we generate many random arrays and test them."""

# ╔═╡ 1254b21a-f66e-11ea-2b36-7985687edd02
function estimateprob(;n=100, q=0.5, iters=100)
    t = Bool[]
    for _ in 1:iters
        wall = Wall(n, q)
        push!(t, testpercolation(wall.array))
    end
    count(x->x, t) / iters
end

# ╔═╡ dda2cd12-f66c-11ea-3f31-837c9a749b5c
estimateprob(q = 0.50)

# ╔═╡ 2b8081ae-f66e-11ea-28dd-d160aa6c80ef
md"""We can estimate the critical value more precisely using a random walk. Starting from an initial value of `q`, we construct a wall and check whether it has a percolating cluster. If so, `q` is probably too high, so we decrease it. If not, `q` is probably too low, so we increase it."""

# ╔═╡ 3d494330-f66e-11ea-118c-7f36892d863e
function findcritical(;n=100, q=0.5, iters=100)
    qs = [q]
    for _ in 1:iters
        wall = Wall(n, q)
        if testpercolation(wall.array)
            q -= 0.004
        else
            q += 0.004
        end
        push!(qs, q)
    end
    qs
end

# ╔═╡ 501878b4-f66e-11ea-270f-d7542715acbb
findcritical()

# ╔═╡ 59540966-f66e-11ea-2cac-6fac6c62910b
md"""With `n=100` the mean of `qs` is about 0.59; this value does not seem to depend on `n`.

The rapid change in behavior near the critical value is called a phase change by analogy with phase changes in physical systems, like the way water changes from liquid to solid at its freezing point.

A wide variety of systems display a common set of behaviors and characteristics when they are at or near a critical point. These behaviors are known collectively as critical phenomena."""

# ╔═╡ 87c7816a-f66e-11ea-02fe-1752fee2c7eb
md"""## Fractals

To understand fractals, we have to start with dimensions.

For simple geometric objects, dimension is defined in terms of scaling behavior. For example, if the side of a square has length `l`, its area is `l^2`. The exponent, 2, indicates that a square is two-dimensional. Similarly, if the side of a cube has length `l`, its volume is `l^3`, which indicates that a cube is three-dimensional.

More generally, we can estimate the dimension of an object by measuring some kind of size (like area or volume) as a function of some kind of linear measure (like the length of a side).

As an example, I’ll estimate the dimension of a 1-D cellular automaton by measuring its area (total number of “on” cells) as a function of the number of rows."""

# ╔═╡ af69c480-f66e-11ea-3e4a-1db5d58bdd7b
function inttorule1dim(val::UInt8)
    digs = BitArray(digits(val, base=2))
    for i in length(digs):7
        push!(digs, false)
    end
    digs
end

# ╔═╡ d6cab994-f66e-11ea-1734-dd3ab2d22e92
function applyrule1dim(rule::BitArray{1}, bits::BitArray{1})
    val = 1 + bits[3] + 2*bits[2] + 4*bits[1]
    rule[val]
end

# ╔═╡ daa15a5a-f66e-11ea-1983-51732624404b
function step1dim(x₀::BitArray{1}, rule::BitArray{1}, steps::Int64)
    xs = [x₀]
    len = length(x₀)
    for i in 1:steps
        x = copy(x₀)
        for j in 2:len-1
            x[j] = applyrule1dim(rule, xs[end][j-1:j+1])
        end
        push!(xs, x)
    end
    xs
end

# ╔═╡ e047f8b8-f66e-11ea-05af-398e5d22ccf8
function visualize1dim(res, dim)
    width = dim * (length(res[1]) + 1)
    height = dim * (length(res) + 1)
    Drawing(width = width, height = height) do
        for (i, arr) in enumerate(res)
            for (j, val) in enumerate(arr)
                fill = if val "grey" else "lightgrey" end
                rect(x = j*dim, y = i*dim, width = dim, height = dim, fill = fill)
            end
        end
    end
end

# ╔═╡ ea25224a-f66e-11ea-1c90-b30dba111177
begin
	x₀ = falses(65)
	x₀[33] = true
	res = step1dim(x₀, inttorule1dim(UInt8(18)), 31) # 20, 50, 18
	visualize1dim(res, 10)
end

# ╔═╡ 070b57aa-f66f-11ea-1a12-bd1529268d4f
md"""I’ll estimate the dimension of these CAs with the following function, which counts the number of on cells after each time step."""

# ╔═╡ 041baf7c-f66f-11ea-270b-2179bd949a67
function countcells(rule, n=501)
    x₀ = falses(2*n+3)
    x₀[n+2] = true
    res = step1dim(x₀, inttorule1dim(UInt8(rule)), n)
    cells = [1]
    for i in 2:n
        push!(cells, cells[end]+sum(line->count(cell->cell, line), res[i]))
    end
    cells
end

# ╔═╡ 3c3f1c66-f66f-11ea-30f6-a3c90bd8eee3
pkg"add Plots" # one time

# ╔═╡ 73fd7b5e-f66f-11ea-12cd-dd36181cf956
begin
	n = 501;
	rule = 20 # 20, 50, 18
	plot(1:n, 1:n, xaxis=:log, yaxis=:log, label="d = 1")
	plot!(1:n, (1:n).^2, xaxis=:log, yaxis=:log, label="d = 2")
	plot!(1:n, countcells(rule, n), xaxis=:log, yaxis=:log, label="rule $rule")
end

# ╔═╡ 81657f1a-f66f-11ea-183b-0ba3f1c3a38e
md"""Rule 20 (left) produces 3 cells every 2 time steps, so the total number of cells after $i$ steps is $y = 1.5i$. Taking the log of both sides, we have $\log y = \log 1.5 + \log i$, so on a log-log scale, we expect a line with slope 1. In fact, the estimated slope of the line is 1.01.

Rule 50 (center) produces i+1 new cells during the ith time step, so the total number of cells after $i$ steps is $y = i^2 + i$. If we ignore the second term and take the log of both sides, we have $\log y \approx 2 \log i$, so as $i$ gets large, we expect to see a line with slope 2. In fact, the estimated slope is 1.97.

Finally, for Rule 18 (right), the estimated slope is about 1.57, which is clearly not 1, 2, or any other integer. This suggests that the pattern generated by Rule 18 has a “fractional dimension”; that is, it is a fractal.

This way of estimating a fractal dimension is called box-counting."""

# ╔═╡ feefb6e4-f66f-11ea-2998-a30311bee9f4
md"""## Fractals and Percolation

Now let’s get back to percolation models.

To estimate their fractal dimension, we can run CAs with a range of sizes, count the number of wet cells in each percolating cluster, and then see how the cell counts scale as we increase the size of the array."""

# ╔═╡ 21d918ee-f670-11ea-0359-cbb1809bab9b
function percolationwet(array::Array{Float64, 2})
    numberwet = count(x->x==0.5, array[3:end-1, 2:end-1])
    while true
        array = applypercolation(array)
        if count(x->x==0.5, array[end-1, 2:end-1]) > 0
            break
        end
        newnumberwet = count(x->x==0.5, array[3:end-1, 2:end-1])
        if numberwet == newnumberwet
            break
        end
        numberwet = newnumberwet
    end
    numberwet
end

# ╔═╡ 3206914e-f670-11ea-3072-d162f584fbf0
let
	res = Float64[]
	sizes = 10:10:200
	q = 0.4 # 0.4, 0.8, 0.596
	for size in sizes
		wall = Wall(size, q)
		push!(res, percolationwet(wall.array))
	end
	plot(sizes, sizes, xaxis=:log, yaxis=:log, label="d = 1")
	plot!(sizes, (sizes).^2, xaxis=:log, yaxis=:log, label="d = 2")
	plot!(sizes, res, xaxis=:log, yaxis=:log, seriestype=:scatter, label="q = $q")
end

# ╔═╡ 4da9c3ba-f670-11ea-1627-d7c5e6b36742
md"""The dots show the number of cells in each percolating cluster. The slope of a line fitted to these dots is often near 1.85, which suggests that the percolating cluster is, in fact, fractal when `q` is near the critical value.

When `q` is larger than the critical value, nearly every porous cell gets filled, so the number of wet cells is close to `q * size^2`, which has dimension 2.

When `q` is substantially smaller than the critical value, the number of wet cells is proportional to the linear size of the array, so it has dimension 1."""

# ╔═╡ Cell order:
# ╟─e6ff0e98-f662-11ea-03a7-e3d09e6272a6
# ╠═1d6260d4-f663-11ea-03da-efe9ed63f9bd
# ╟─2abf49e0-f663-11ea-25f3-2f9229de732e
# ╠═40373f12-f663-11ea-256c-abd1458a8e85
# ╠═52f4e280-f663-11ea-38a4-c52a7b06b564
# ╠═61437b46-f663-11ea-12c6-2ff992812dca
# ╠═7f66f30e-f667-11ea-34e8-d315ed180b75
# ╠═358ac3e2-f666-11ea-2058-11eedeabff5f
# ╠═863a3fa4-f664-11ea-2597-8f18f2a862ac
# ╠═966fc752-f666-11ea-1794-195433f4cce5
# ╠═b0148fb4-f664-11ea-2d64-976658b08661
# ╠═b25969c4-f665-11ea-222b-df9786a710d2
# ╠═95dc78e8-f667-11ea-1c07-8f5cc11b011b
# ╟─c03905f2-f667-11ea-3484-b111f7c14f60
# ╠═cf7c1a2c-f667-11ea-358f-df431ec27476
# ╟─0a815d80-f668-11ea-0dd3-9155b36a4134
# ╠═23f98030-f668-11ea-389b-ff911adaadfd
# ╠═3c706f38-f669-11ea-2266-f743535073b5
# ╠═1b551fc2-f669-11ea-0d2f-ad0e089592d8
# ╠═e1988846-f668-11ea-1b26-8f7dca1bb4e7
# ╠═dda066c0-f668-11ea-3096-bdea16f40db7
# ╟─1734b35e-f66a-11ea-10b4-317d12008809
# ╟─40f84b2e-f66a-11ea-1dc7-3ded9e11af06
# ╠═77dcd828-f66a-11ea-0942-c5d613d828b7
# ╟─818e5534-f66a-11ea-07b2-7722084e1e07
# ╠═44c8b17a-f66b-11ea-39af-f554593e33eb
# ╠═d9ccf8f8-f66b-11ea-2c81-0d771c2e900e
# ╠═e492630e-f66b-11ea-3aed-f37a400243be
# ╠═e048231c-f66b-11ea-191d-8517a6c65bc5
# ╠═11847488-f66c-11ea-1aca-4b1613dbfb8e
# ╟─3563b208-f66c-11ea-3c1a-77f799805d06
# ╠═2b9c8a86-f66c-11ea-0447-1fb7ba83d3a1
# ╠═c71f0f24-f66c-11ea-0ba7-d765f3998ed9
# ╟─e51771ec-f66c-11ea-1606-fd159b8d216f
# ╠═1254b21a-f66e-11ea-2b36-7985687edd02
# ╠═dda2cd12-f66c-11ea-3f31-837c9a749b5c
# ╟─2b8081ae-f66e-11ea-28dd-d160aa6c80ef
# ╠═3d494330-f66e-11ea-118c-7f36892d863e
# ╠═501878b4-f66e-11ea-270f-d7542715acbb
# ╟─59540966-f66e-11ea-2cac-6fac6c62910b
# ╟─87c7816a-f66e-11ea-02fe-1752fee2c7eb
# ╠═af69c480-f66e-11ea-3e4a-1db5d58bdd7b
# ╠═d6cab994-f66e-11ea-1734-dd3ab2d22e92
# ╠═daa15a5a-f66e-11ea-1983-51732624404b
# ╠═e047f8b8-f66e-11ea-05af-398e5d22ccf8
# ╠═ea25224a-f66e-11ea-1c90-b30dba111177
# ╟─070b57aa-f66f-11ea-1a12-bd1529268d4f
# ╠═041baf7c-f66f-11ea-270b-2179bd949a67
# ╠═22d23c18-f66f-11ea-2056-71e534b3bf1d
# ╠═3c3f1c66-f66f-11ea-30f6-a3c90bd8eee3
# ╠═4e03615a-f66f-11ea-244f-85f4c21a111b
# ╠═73fd7b5e-f66f-11ea-12cd-dd36181cf956
# ╟─81657f1a-f66f-11ea-183b-0ba3f1c3a38e
# ╟─feefb6e4-f66f-11ea-2998-a30311bee9f4
# ╠═21d918ee-f670-11ea-0359-cbb1809bab9b
# ╠═3206914e-f670-11ea-3072-d162f584fbf0
# ╟─4da9c3ba-f670-11ea-1627-d7c5e6b36742
