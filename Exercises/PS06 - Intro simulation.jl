### A Pluto.jl notebook ###
# v0.19.12

using Markdown
using InteractiveUtils

# ╔═╡ b77c944b-88e4-421d-a629-0d96bf95ea70
begin
	using Pkg
	cd(joinpath(dirname(@__FILE__),".."))
    Pkg.activate(pwd())
	# Simulation packages
	using Distributions, HypothesisTests
	# Plotting packages
	using StatsPlots, LaTeXStrings, Measures
end

# ╔═╡ 86a87f27-7b57-4420-8cef-836ac531a254
html"""
 <! -- this adapts the width of the cells to display its being used on -->
<style>
	main {
		margin: 0 auto;
		max-width: 2000px;
    	padding-left: max(160px, 10%);
    	padding-right: max(160px, 10%);
	}
</style>
"""

# ╔═╡ bcbed56c-0c94-11eb-0e8c-2de8d1a20f47
md"""

# Simulation - a small intro


## General approach
When a simulation is used to answer a question or to solve a problem, the following steps are involved:
* Formulate the problem and plan the study
* Collect the data and formulate the simulation model
* Check the accuracy of the simulation model (assumptions, limitations etc.)
* Construct a computer program
* Test the validity of the simulation model
* Plan the simulations to be performed
* Conduct the simulation runs and analyze the results
* Present the conclusions

During this practical session, we will run small simulations going over all these steps.


"""

# ╔═╡ 349b8586-0c96-11eb-2e7b-5b3230d1cf27
md"""
## Casino game
A casino offers a coin flipping game with the following rules:
1. Each play of the game involves repeatedly flipping an unbiased coin 
2. The game stops when the difference between the number of heads tossed and the number of tails is 3
3. If you decide to play, each flip costs you € 1. You are not allowed to quit during a play of the game.
4. You receive € 8 at the end of each play of the game.


The problem at hand is to decide whether to play or not and to get an idea of the expected gains and the length of each game. We might also look into the required simulation size and into a parametric study (e.g. influence of the required difference between heads/tails and/or the default gain).

*Tip:* it can be analytically proven that the true mean of the number of flips required for a play of this game is 9. 


##### Steps in the simulation process

###### Formulate the problem and plan the study:
the problem is described in a clear way (cf. suppra). Given these rules, we want to find out
1. if it is a good idea to play
2. the value of the expected profit

###### Collect the data and formulate the simulation model:
Let $X$ be the outcome of one coin flip $\Rightarrow X\sim \mathcal{Be}(1/2)$

###### Check the accuracy of the simulation model:
Our model is complete, we make no assumptions

###### Construct a computer program
"""

# ╔═╡ 3a20552e-0c97-11eb-3f0d-2586b1bb46ed
begin
	"""
		game(limit::Int=3)
	
	Play a game for a given limit. Returns a dict with the scores and the game length
	"""
	function game(limit::Int=3)
		d = Dict("heads"=>0, "tails"=>0, "length"=>0)
		while abs(d["heads"] - d["tails"]) < limit 
			d["length"] += 1
			if rand()<=1/2
				d["heads"]+=1
			else
				d["tails"]+=1
			end
		end
		
		return d
	end
	
	"""
		sim(N::Int=1000; limit::Int=3)
	
	run a simulation of the game. 
	"""
	function sim(N::Int=1000; limit::Int=3, gain::Real=8)
		L = Array{Int64,1}()
		G = Array{Int64,1}()
		for _ in 1:N
			g = game(limit)
			push!(L,g["length"])
			push!(G,gain - g["length"])
		end
		
		return L,G
	end

	nothing
end

# ╔═╡ b1bae776-0dfe-11eb-291b-53f9a87c4a41
# other method of creating a game
begin
	mutable struct Game
		heads::Int
		tails::Int
		length::Int
	end
	
	function play!(g::Game, limit::Int=3)
		while abs(g.heads - g.tails) < limit 
			g.length += 1
			if rand()<=1/2
				g.heads += 1
			else
				g.tails += 1
			end
			
		end
		
		return g
	end
	
	g = Game(0,0,0)
	play!(g)
end

# ╔═╡ 65c6476c-0c98-11eb-2c7d-3bc3ba8d51e2
md"""
###### Test the validity of the simulation model
A game should stop when the difference between the amount of heads and tails equals 3
```julia
begin 
	g = game()
	@assert abs(g["heads"] - g["tails"]) == 3
end
```
"""

# ╔═╡ 5b08b538-0c97-11eb-0319-877b39c4c4ed
md"""
###### Plan the simulations to be performed
We will run a certain number of simulations. At this time we do not have additional information that we can use (optimal number to be determined later).
"""

# ╔═╡ 607e4392-0c98-11eb-0a9d-ddfab6b42b26
md"""
###### Conduct the simulation runs and analyze the results
"""

# ╔═╡ 75d35828-0c99-11eb-1888-e9e7be234e89
begin
	# get data for game length and gains
	L,G = sim()
end;

# ╔═╡ fae1e448-0c98-11eb-3721-dddb169e403f
# show results
plot(histogram(L,xlabel="Game length"),histogram(G,xlabel="Gains"),
     label="",grid=false,ylabel="Frequency",size=(600,250) ,bottom_margin=5mm)

# ╔═╡ a39a3a72-0c99-11eb-00df-e92eb7a6ce07
plot([boxplot(L,ylabel="Game length", ylims=(0,maximum(L)+4)),
	  boxplot(G,ylabel="Gains")]...,
     label="",grid=false,size=(300,250),xaxis=false)

# ╔═╡ ac87cb8a-0c9a-11eb-21d5-9981e408db29
md"""
#### Simulation length
Up to now we have worked with a simulation length 1000. We have no idea about the variation of each simulation result. We investigate this in order to find out how simulation length impacts our estimate.
"""

# ╔═╡ 1aa54e8a-0c9b-11eb-3b7c-f3be005991df
begin
	# evolution of the mean in function of the sample length
	x = Array{Int,1}()
	y = Array{Float64,1}()
	ntests = 30
	for N in 10 .^(1:5)
		for _ in 1:ntests
			(L,_) = sim(N,limit=3)
			push!(x,N)
			push!(y,mean(L))
		end
	end
end

# ╔═╡ 3236977a-0c9b-11eb-3875-2304eaec0a8e
begin
	scatter(x,y,xscale=:log10,
			xlabel="Number of games per simulation",
			ylabel="Average game length",title="",label="")
	plot!(x,9*ones(size(x)),color=:red,label="")
	title!("Towards optimal simulation length\n (30 datapoints per config)")
end

# ╔═╡ 7fafde70-0c9c-11eb-0403-9bfb6e42045b
md"""
#### Parametric study
suppose we consider a range of differences [2,4] and a range of gains [4, 12] where we play 1e5 games for each config.
"""

# ╔═╡ c8b107ba-0c9d-11eb-11c7-830d112ca82f
let
	Δ = 1:5
	Γ = 0:15
	N = Int(1e5)
	res = []
	i = 1
	for d in Δ
		for g in Γ
			_,G = sim(N; limit=d, gain=g)
			push!(res, mean(G))
		end
	end
	blup = reshape(res,:,length(Δ))
	p1 = heatmap(Δ, Γ, blup, xlabel="diff", ylabel="guaranteed gain", title="mean gain")
	p2 = heatmap(Δ, Γ, blup .>= 0, xlabel="diff", ylabel="guaranteed gain", title="positive gain")
	plot(p1,p2, size=(600, 300))
end

# ╔═╡ 0bfa3ffe-0c9a-11eb-2c99-3d8e57983c4c
md"""
###### Present the conclusions
We find that on average a game takes 9 turns, which will lead you to lose on average € 1. The game could be tempting given that in six out of ten cases the player will actually win (a small amount).
"""

# ╔═╡ 8df49b7e-0c9e-11eb-0048-9368c9d7bee9
md"""
## Project management
Suppose we want to simulate a industrial process that can be presented as the table shown below:

| Activity | Predecessors | Completion time |
|----------|--------------|---------------- |
| A | - | $\sim \mathcal{N}(6,1)$ |
| B | A | $\sim \mathcal{U}(6,10)$ |
| C | A | $\sim \mathcal{U}(1.5,2.5)$ |
| D | B,C | $\sim \mathcal{U}(1.5,3)$ |
| E | D | $\sim \mathcal{U}(3,6)$ |
| F | E | $\sim \mathcal{U}(2,5)$ |
| G | E | $\sim \mathcal{U}(3,5)$ |
| H | F,G | $\sim \mathcal{U}(4,7)$ |
| I | H | $\sim \mathcal{U}(5,7)$ |
| J | H | $\le 5$ |

We want to get an idea of:
1. the mean project completion time
2. the probability that the project will be finished in less than 36 time units
3. determine the critical subprocesses with a sensitivity chart (i.e. determine the impact of changing a specific subprocess on the completion time given all the others remain the same)

"""

# ╔═╡ 7aceebea-0d1d-11eb-05fa-d7374004b881
md"""
###### Formulate the problem and plan the study
The problem and the tasks are described above

###### Collect the data and formulate the simulation Model
Data model (coming from historical data) is known. The duration can be obtained from the a vector of duration times.

###### Construct a computer program
"""

# ╔═╡ 8f99cf60-0c9e-11eb-2b6d-b5ca5ed20a65
begin
	# completion time distributions
	D = [Normal(6,1); 
		Uniform(6,10); 
		Uniform(1.5,2.5); 
		Uniform(1.5,4); 		              		
		Uniform(3,6);
		Uniform(2,5); 
		Uniform(3,5); 
		Uniform(4,7); 
		Uniform(5,7); 
		Uniform(0,5)]
	
	# central positions (for sensitivity analysis)
	p = [6; 8; 2; 2.25; 4.5; 3.5; 4; 5.5; 6; 2.5]
	"""
		 duration(t::Array)

	generate a random sample from an array of distributions for the production process
	"""
	function duration(t::Array)
		t[1] + max(t[2],t[3]) + t[4] + t[5] + max(t[6], t[7]) + t[8] + max(t[9], t[10])
	end
	
	"""
		PM(N::Int)
	
	Run a Project Management simulation N times that returns a vector of duration times
	"""
	function PM(D::Array, N::Int=100)
		# Generate data
		S = [rand.(D) for _ in 1:N]
		# get durations
		return map(duration, S)
	end

	nothing;
end

# ╔═╡ 864b050c-0d1e-11eb-03d8-8ffcf23e019e
md"""
###### Check the accuracy of the simulation model (assumptions, limitations etc.)
We use a normal distribution for the first activity, so it is theoretically possible that a negative value for A occurs, which does not make sense. In a similar way, using a uniform distribution sets hard limits for task durations.

You can make testcases to assert the correctness of the result calculated by the duration function.
"""

# ╔═╡ f9562612-0d1e-11eb-1e16-bfa53760c18c
begin 
	v = [0 0 1 0 0 1 0 0 0 0] 
	@assert duration(v) ==  2
end

# ╔═╡ d18a68b2-0d20-11eb-0f39-150f9bc9e0e9
md"""
###### Plan the simulations to be performed
We will generate a sample of a given length an look at the experimental CDF.
"""

# ╔═╡ da7801bc-0ca0-11eb-0480-33f07e16c85b
let
	# idea mean value
	N = 1000; x = 36;
	res = PM(D,N)
	avg_D = mean(res)
	#  CDF
	p1 = StatsPlots.cdensity(res,label="Experimental CDF",legend=:bottomright)
	title!("P(X <= $(x)): $(sum(res .< x)/N)")
	
	plot!([avg_D; avg_D], [0; 1], line=:dash, label="mean duration $(round(avg_D,digits=2))")
	ylabel!("F_{X}(x) ")
	xlabel!("duration")
	# PDF
	p2 = StatsPlots.density(res, label="Experimental PDF")
	xlabel!("duration")
	ylabel!("f_{X}(x)")
	# total plot
	plot(p1, p2)
end

# ╔═╡ 3d5f9648-0d21-11eb-14c4-65704b349ed6
md"""
###### Conduct the simulation runs and analyze the results
We have obtained the results. We can do some additional testing such as validating the normality of our simulation data. 


The sensitivity analysis can be done by changing one-factor-at-a-time (OAT), to see what effect this produces on the output. I.e. we move one input variable, keeping others at their baseline (nominal) values and repeat this for each of the other inputs in the same way.
"""

# ╔═╡ d8b821a0-0d21-11eb-08bc-f7027b1cbea1
begin
	s = PM(D,1000)
	HypothesisTests.ExactOneSampleKSTest(s,Normal(mean(s),std(s)))
end

# ╔═╡ d89eb800-0d21-11eb-29d9-c119c9347dbc
begin 
	"""
		sensitivity(D, p, i::Int, N::Int=1000)
	
	Generate a sample where all values keep their baseline values with the exception of component i
	"""
	function sensitivity(D, p, i, N::Int=1000)
		# generate data
		data = [[p[1:i-1]; rand(D[i]); p[i+1:end]] for _ in 1:N]
		# return durations
		map(duration,data)
	end
	
	blup = [sensitivity(D,p, i) for i in 1:10]
	StatsPlots.boxplot(blup, label="")
	xlabel!("process step")
	ylabel!("duration boxplot")
	ylims!(30,40)
	xlims!(0,11)
	xticks!(collect(1:10))
	title!("Sensitivity analysis")
end

# ╔═╡ d148f3ea-0d21-11eb-2d67-f1f4c77248d5
md"""
###### Present the conclusions
With respect to the initial goals, we can conclude the following:
* the mean project completion time is around 37 time units
* the probability that the project will be finished in less than 36 time units is around 34%
* processes 3 and 10 do not impact the total project duration. Steps two and four account for the largest variability.
"""

# ╔═╡ Cell order:
# ╠═86a87f27-7b57-4420-8cef-836ac531a254
# ╠═b77c944b-88e4-421d-a629-0d96bf95ea70
# ╟─bcbed56c-0c94-11eb-0e8c-2de8d1a20f47
# ╟─349b8586-0c96-11eb-2e7b-5b3230d1cf27
# ╠═3a20552e-0c97-11eb-3f0d-2586b1bb46ed
# ╠═b1bae776-0dfe-11eb-291b-53f9a87c4a41
# ╟─65c6476c-0c98-11eb-2c7d-3bc3ba8d51e2
# ╟─5b08b538-0c97-11eb-0319-877b39c4c4ed
# ╟─607e4392-0c98-11eb-0a9d-ddfab6b42b26
# ╠═75d35828-0c99-11eb-1888-e9e7be234e89
# ╠═fae1e448-0c98-11eb-3721-dddb169e403f
# ╠═a39a3a72-0c99-11eb-00df-e92eb7a6ce07
# ╟─ac87cb8a-0c9a-11eb-21d5-9981e408db29
# ╠═1aa54e8a-0c9b-11eb-3b7c-f3be005991df
# ╠═3236977a-0c9b-11eb-3875-2304eaec0a8e
# ╟─7fafde70-0c9c-11eb-0403-9bfb6e42045b
# ╠═c8b107ba-0c9d-11eb-11c7-830d112ca82f
# ╟─0bfa3ffe-0c9a-11eb-2c99-3d8e57983c4c
# ╟─8df49b7e-0c9e-11eb-0048-9368c9d7bee9
# ╟─7aceebea-0d1d-11eb-05fa-d7374004b881
# ╠═8f99cf60-0c9e-11eb-2b6d-b5ca5ed20a65
# ╟─864b050c-0d1e-11eb-03d8-8ffcf23e019e
# ╠═f9562612-0d1e-11eb-1e16-bfa53760c18c
# ╟─d18a68b2-0d20-11eb-0f39-150f9bc9e0e9
# ╠═da7801bc-0ca0-11eb-0480-33f07e16c85b
# ╟─3d5f9648-0d21-11eb-14c4-65704b349ed6
# ╠═d8b821a0-0d21-11eb-08bc-f7027b1cbea1
# ╠═d89eb800-0d21-11eb-29d9-c119c9347dbc
# ╟─d148f3ea-0d21-11eb-2d67-f1f4c77248d5
