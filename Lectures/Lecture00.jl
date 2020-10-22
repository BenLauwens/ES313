### A Pluto.jl notebook ###
# v0.11.10

using Markdown
using InteractiveUtils

# ╔═╡ bef0f870-eb91-11ea-02b6-dd0f1a40947c
md"# Introduction"

# ╔═╡ e6959750-eb91-11ea-3aea-519bdec8f9f6
md"""## Who are we?

Lecturer: MAJ IMM Ben Lauwens / D30.20 / [ben.lauwens@mil.be]()

Assistant: CPN Bart De Clerck / D30.20 / [bart.declerck@mil.be]()"""

# ╔═╡ 0f6a2ab2-eb92-11ea-2a06-0d9b69dd1358
md"""## Why Modelling and Simulation

- What is modelling?

- What is simulation?

Reality is often too complex to calculate ..."""

# ╔═╡ 29d92270-eb92-11ea-374f-45b11865dd9a
md"""## Documentations

All slides can be found on github: [https://github.com/BenLauwens/ES313.jl.git]()."""

# ╔═╡ ee8e57c0-eb92-11ea-193a-5bfcf7800d99
md"""## Schedule

### Theory

- 01/09: Cellular Automaton + Game of Life
- 02/09: Year Coord
- 15/09: Physical Modelling + Self-Organization
- 22/09: Optimisation Techniques
- 23/09: Linear Programming I
- 29/09: Linear Programming II + Applications I
- 30/09: Applications of Linear Programming II
- 20/10: Introduction to Discrete Event Simulation
- 21/10: Process Driven DES: SimJulia I
- 27/10: Process Driven DES II + Applications I
- 04/11: Applications with SimJulia II

### Practice

- 08/09: Visualisation
- 09/09: Cellular Automaton (Langton loops)
- 16/09: Physical Modelling + Self-Organization (phase transitions)
- 06/10: Optimisation Techniques I
- 07/10: Optimisation Techniques II + Linear Programming I
- 13/10: Linear Programming II
- 14/10: Introduction to Discrete Event Simulation I
- 28/10: Process Driven DES: SimJulia I + Projects Introduction
- 10/11: Applications with SimJulia II

Remarks: 
- 03/11 => -2 Hr (SimJulia II)
- 11/11 => -1 Hr (Performance)


### Project

- 11/11: List of projects available
- we are available during contact hours
- 17/11: obligatory meeting: understanding of the problem
- 01/12: obligatory meeting: progress"""

# ╔═╡ 0b3e8cf2-eb93-11ea-140d-35c9f1074ea9
md"""## Evaluation

Test: Oct - 2Hr
- Cellular Automaton + Game of Life
- Physical Modelling + Self-Organization

Examen: Project with Oral Defense
- Visualisation
- Optimisation Techniques
- Linear Programming
- Discrete Event Simulation"""

# ╔═╡ 5fe3a710-ebbe-11ea-3987-3fec2c7f3057
md"""## Julia

- Install Julia on CDN laptop
- Install Notepad++ on CDN laptop
- Start Julia and install Pluto:

```julia
using Pkg
pkg"add Pluto"
```

- Start Pluto:

```julia
using Pluto
Pluto.run(8888)
```

- Open [https://localhost:8888]()"""

# ╔═╡ Cell order:
# ╟─bef0f870-eb91-11ea-02b6-dd0f1a40947c
# ╟─e6959750-eb91-11ea-3aea-519bdec8f9f6
# ╟─0f6a2ab2-eb92-11ea-2a06-0d9b69dd1358
# ╟─29d92270-eb92-11ea-374f-45b11865dd9a
# ╟─ee8e57c0-eb92-11ea-193a-5bfcf7800d99
# ╟─0b3e8cf2-eb93-11ea-140d-35c9f1074ea9
# ╟─5fe3a710-ebbe-11ea-3987-3fec2c7f3057
