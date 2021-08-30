### A Pluto.jl notebook ###
# v0.14.7

using Markdown
using InteractiveUtils

# ╔═╡ bef0f870-eb91-11ea-02b6-dd0f1a40947c
md"# Introduction"

# ╔═╡ e6959750-eb91-11ea-3aea-519bdec8f9f6
md"""## Who are we?

Lecturer: LCL IMM Ben Lauwens / D30.20 / [ben.lauwens@mil.be]()

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

- 31/08: Cellular Automaton + Game of Life
- 01/09: Year Coord
- 14/09: Physical Modelling + Self-Organization
- 21/09: Optimisation Techniques
- 22/09: Linear Programming I
- 28/09: Linear Programming II + Applications I
- 29/09: Applications of Linear Programming II
- 19/10: Introduction to Discrete Event Simulation
- 20/10: Process Driven DES: SimJulia I
- 26/10: Process Driven DES II + Applications I
- 27/10: Applications with SimJulia II

### Practice

- 07/09: Visualisation
- 08/09: Cellular Automaton
- 15/09: Game of Life
- 05/10: Physical Modelling + Self-Organization
- 06/10: Optimisation Techniques I
- 12/10: Optimisation Techniques II + Linear Programming I
- 13/10: Linear Programming II
- 09/11: Introduction to Discrete Event Simulation
- 10/11: Process Driven DES: SimJulia I
- 16/11: Process Driven DES II + Applications with SimJulia I
- 17/11: Applications with SimJulia II
- 24/11: Performance

### Project

- 09/11: List of projects available
- we are available during contact hours
- 23/11: obligatory meeting: understanding of the problem
- 07/12: obligatory meeting: progress"""

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
pkg"add PlutoUI"
```

- Start Pluto:

```julia
using Pluto
Pluto.run()
```
"""

# ╔═╡ Cell order:
# ╟─bef0f870-eb91-11ea-02b6-dd0f1a40947c
# ╟─e6959750-eb91-11ea-3aea-519bdec8f9f6
# ╟─0f6a2ab2-eb92-11ea-2a06-0d9b69dd1358
# ╟─29d92270-eb92-11ea-374f-45b11865dd9a
# ╟─ee8e57c0-eb92-11ea-193a-5bfcf7800d99
# ╟─0b3e8cf2-eb93-11ea-140d-35c9f1074ea9
# ╟─5fe3a710-ebbe-11ea-3987-3fec2c7f3057
