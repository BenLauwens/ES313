### A Pluto.jl notebook ###
# v0.14.7

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

# ╔═╡ 295178e0-ebb3-11ea-1213-b531a8ef5828
using NativeSVG

# ╔═╡ 880bced0-ebb3-11ea-0cdf-f3f1c399de51
using Random

# ╔═╡ fb1cdbe0-ebb2-11ea-1034-a3632723963b
md"""# Game of Life

Port of [Think Complexity chapter 6](http://greenteapress.com/complexity2/html/index.html) by Allen Downey."""

# ╔═╡ 2cf79d80-ebb3-11ea-2ce7-85ca9f3edc7d
md"""Conway's Game of Life (GoL) is a 2 dimensional CA that turns out to be universal.

## Conway's GOL

- The cells in GoL are arranged in a 2-D grid, that is, an array of rows and columns. Usually the grid is considered to be infinite, but in practice it is often “wrapped”; that is, the right edge is connected to the left, and the top edge to the bottom.

- Each cell in the grid has two states — live and dead — and 8 neighbors — north, south, east, west, and the four diagonals. This set of neighbors is sometimes called a “Moore neighborhood”.

- Like the 1-D CAs in the previous chapters, GoL evolves over time according to rules, which are like simple laws of physics.

- In GoL, the next state of each cell depends on its current state and its number of live neighbors. If a cell is alive, it stays alive if it has 2 or 3 neighbors, and dies otherwise. If a cell is dead, it stays dead unless it has exactly 3 neighbors.

- This behavior is loosely analogous to real cell growth: cells that are isolated or overcrowded die; at moderate densities they flourish.

## Implementation

rule:"""

# ╔═╡ 316e5890-ebb3-11ea-247c-5104c109f9d8
function applyrulegameoflife(bits::BitArray{2})
    (nr_y, nr_x) = size(bits)
    out = falses(nr_y, nr_x)
    for y in 2:nr_y-1
        for x in 2:nr_x-1
            if bits[y, x]
                if 2 ≤ count(v->v, bits[y-1:y+1,x-1:x+1]) - 1 ≤ 3
                    out[y, x] = true
                end
            else
                if count(v->v, bits[y-1:y+1,x-1:x+1]) == 3
                    out[y, x] = true
                end
            end
        end
    end
    out
end

# ╔═╡ 66432050-ebb3-11ea-3c37-e37390422780
md"visulatisation:"

# ╔═╡ 701c7d10-ebb3-11ea-19d8-7f9587aee599
function visualize2dim(bits::BitArray{2}, dim)
    (nr_y, nr_x) = size(bits)
    width = dim * (nr_x - 1)
    height = dim * (nr_y - 1)
    Drawing(width = width, height = height) do
        for (j, y) in enumerate(2:nr_y-1)
            for (i, x) in enumerate(2:nr_x-1)
                fill = if bits[y, x] "grey" else "lightgrey" end
                rect(x = i*dim, y = j*dim, width = dim, height = dim, fill = fill)
            end
        end
    end
end

# ╔═╡ 7b710820-ebb3-11ea-3947-4548d61acafb
md"example:"

# ╔═╡ 40c8bf02-ebb4-11ea-2a2f-eff487a4a30f
mutable struct Gol
	bits :: BitArray{2}
	function Gol(xdim::Int64, ydim)
		new(falses(xdim, ydim))
	end
end

# ╔═╡ a6813e30-ebb4-11ea-2cfc-cfa8e82a0b54
function goltest()
	gol = Gol(12, 12)
	gol.bits[2:11,2:11] = reshape(bitrand(100), (10,10))
	gol
end

# ╔═╡ b725ed00-ebb7-11ea-19a0-2ff7e4729780
gol = goltest();

# ╔═╡ 69dae5b0-ebb6-11ea-0464-47c13136f76d
visualize2dim(gol.bits, 30)

# ╔═╡ 07986fe0-ebb5-11ea-3f52-2daa2bad7f22
function applyrule(gol::Gol)
	gol.bits = applyrulegameoflife(gol.bits)
end

# ╔═╡ 9506b6e0-ebb3-11ea-1922-c36f37f7fdce
visualize2dim(applyrule(gol), 30)

# ╔═╡ e6284c30-ebb5-11ea-3861-f5253bd5ace2
md"""## Life Patterns

A number of stable patterns are likely to appear.

### Beehive

A stable pattern."""

# ╔═╡ f465ed72-ebb5-11ea-2178-0928e7650f7e
function Beehive()
	beehive = Gol(5, 6)
	beehive.bits[2,3:4] = [true, true]
	beehive.bits[3,2] = true
	beehive.bits[3,5] = true
	beehive.bits[4,3:4] = [true, true]
	beehive
end

# ╔═╡ 5c8d97de-ebb6-11ea-1a01-651fceb86eb5
beehive = Beehive();

# ╔═╡ a515e600-ebc2-11ea-3691-553176d1a9cb
visualize2dim(applyrule(beehive), 30)

# ╔═╡ b0790d80-ebb6-11ea-3423-1fa5c38fd3a4
md"""### Toad

An oscillating pattern. The toad has a period of 2 timesteps."""

# ╔═╡ 8d274e00-ebb6-11ea-1a22-bdb17e0513c7
function Toad()
	toad = Gol(6, 6)
	toad.bits[3,3:5] = [true, true, true]
	toad.bits[4,2:4] = [true, true, true]
	toad
end

# ╔═╡ f7491ac0-ebb6-11ea-17d9-a99a458757d9
toad = Toad();

# ╔═╡ fbe70ce0-ebb6-11ea-2bec-8754663e7ef3
visualize2dim(applyrule(toad), 30)

# ╔═╡ 059206a0-ebb7-11ea-02e0-11ff007b95b2
md"""### Glider

Oscillation pattern that shift in space. After a period of 4 steps, the glider is back in the starting configuration, shifted one unit down and to the right."""

# ╔═╡ 584f18f0-ebb8-11ea-235c-8918cb8023bc
function Glider()
	glider = Gol(8, 8)
	glider.bits[2,3] = true
	glider.bits[3,4] = true
	glider.bits[4,2:4] = [true, true, true]
	glider
end

# ╔═╡ 83e4ef32-ebb8-11ea-3a43-7556b2cf10c7
glider = Glider();

# ╔═╡ ac886070-ebb8-11ea-1742-c9449ca01d7e
visualize2dim(glider.bits, 30)

# ╔═╡ 87ad41d0-ebb8-11ea-3e4d-5f76f10c6888
@bind toggleglider html"<input type=button value='Next'>"

# ╔═╡ 9dd17080-ebb8-11ea-11df-cfe66b93af90
if toggleglider === "Next"
	visualize2dim(applyrule(glider), 30)
else
	visualize2dim(glider.bits, 30)
end

# ╔═╡ 307f6080-ebba-11ea-210c-0182eece50c2
md"""## Methusalems

From most initial conditions, GoL quickly reaches a stable state where the number of live cells is nearly constant (possibly with some oscillation).

But there are some simple starting conditions that yield a surprising number of live cells, and take a long time to settle down. Because these patterns are so long-lived, they are called “Methusalems”.

One of the simplest Methusalems is the r-pentomino, which has only five cells, roughly in the shape of the letter 'r'."""

# ╔═╡ 90bba610-ebbb-11ea-369a-936b36d2e26f
function R_Pentomino()
	r_pentomino = Gol(66, 66)
	r_pentomino.bits[28,28:29] = [true, true]
	r_pentomino.bits[29,27:28] = [true, true]
	r_pentomino.bits[30,28] = true
	r_pentomino
end

# ╔═╡ 21cbba00-ebbc-11ea-2a6c-2f7561ea8c71
r_pentomino = R_Pentomino();

# ╔═╡ e3af2720-ebbb-11ea-0458-f51595107c9c
@bind togglerpentomino html"<input type=button value='Next'>"

# ╔═╡ 0d6ce200-ebbc-11ea-25b4-e33be459e6a2
if togglerpentomino === "Next"
	visualize2dim(applyrule(r_pentomino), 8)
else
	visualize2dim(r_pentomino.bits, 8)
end

# ╔═╡ 91aa5660-ebbc-11ea-10d6-b59fff5e0272
let r_pentomino = deepcopy(r_pentomino)
	for _ in 1:1000
		r_pentomino.bits = applyrule(r_pentomino)
	end
	visualize2dim(r_pentomino.bits, 8)
end

# ╔═╡ f7a1b350-ebbc-11ea-3951-e7e1a6c3bd7b
md"""This configuration is final in the sense that all remaining patterns are either stable, oscillators or gliders that will never collide with another pattern.

There are initial patterns that never stabilize, eg. a gun or a puffer train

The Game of Life was proved Turing complete in 1982. Since then, several people have constructed GoL patterns that implement a Turing machine or another machine known to be Turing complete."""

# ╔═╡ Cell order:
# ╟─fb1cdbe0-ebb2-11ea-1034-a3632723963b
# ╠═295178e0-ebb3-11ea-1213-b531a8ef5828
# ╟─2cf79d80-ebb3-11ea-2ce7-85ca9f3edc7d
# ╠═316e5890-ebb3-11ea-247c-5104c109f9d8
# ╟─66432050-ebb3-11ea-3c37-e37390422780
# ╠═701c7d10-ebb3-11ea-19d8-7f9587aee599
# ╟─7b710820-ebb3-11ea-3947-4548d61acafb
# ╠═880bced0-ebb3-11ea-0cdf-f3f1c399de51
# ╠═40c8bf02-ebb4-11ea-2a2f-eff487a4a30f
# ╠═a6813e30-ebb4-11ea-2cfc-cfa8e82a0b54
# ╠═b725ed00-ebb7-11ea-19a0-2ff7e4729780
# ╠═69dae5b0-ebb6-11ea-0464-47c13136f76d
# ╠═07986fe0-ebb5-11ea-3f52-2daa2bad7f22
# ╠═9506b6e0-ebb3-11ea-1922-c36f37f7fdce
# ╟─e6284c30-ebb5-11ea-3861-f5253bd5ace2
# ╠═f465ed72-ebb5-11ea-2178-0928e7650f7e
# ╠═5c8d97de-ebb6-11ea-1a01-651fceb86eb5
# ╠═a515e600-ebc2-11ea-3691-553176d1a9cb
# ╟─b0790d80-ebb6-11ea-3423-1fa5c38fd3a4
# ╠═8d274e00-ebb6-11ea-1a22-bdb17e0513c7
# ╠═f7491ac0-ebb6-11ea-17d9-a99a458757d9
# ╠═fbe70ce0-ebb6-11ea-2bec-8754663e7ef3
# ╟─059206a0-ebb7-11ea-02e0-11ff007b95b2
# ╠═584f18f0-ebb8-11ea-235c-8918cb8023bc
# ╠═83e4ef32-ebb8-11ea-3a43-7556b2cf10c7
# ╠═ac886070-ebb8-11ea-1742-c9449ca01d7e
# ╠═87ad41d0-ebb8-11ea-3e4d-5f76f10c6888
# ╠═9dd17080-ebb8-11ea-11df-cfe66b93af90
# ╟─307f6080-ebba-11ea-210c-0182eece50c2
# ╠═90bba610-ebbb-11ea-369a-936b36d2e26f
# ╠═21cbba00-ebbc-11ea-2a6c-2f7561ea8c71
# ╟─e3af2720-ebbb-11ea-0458-f51595107c9c
# ╠═0d6ce200-ebbc-11ea-25b4-e33be459e6a2
# ╠═91aa5660-ebbc-11ea-10d6-b59fff5e0272
# ╟─f7a1b350-ebbc-11ea-3951-e7e1a6c3bd7b
