### A Pluto.jl notebook ###
# v0.19.11

using Markdown
using InteractiveUtils

# ╔═╡ 8e3917d6-ec62-11ea-0c16-7d2749432dd1
begin
	# Pkg needs to be used to force Pluto to use the current project instead of making an environment for each notebook
	using Pkg
	cd(joinpath(dirname(@__FILE__),".."))
    Pkg.activate(pwd())
	
	using PlutoUI
	using Distributions
	using LaTeXStrings
	using Plots
	using StatsPlots
	using Measures
	using Dates
	#using JLD # removed because JLD does not work on CDN
end

# ╔═╡ 9f0fff31-d180-499b-b8a4-27d09f9311c2
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

# ╔═╡ 02c1eefc-ec63-11ea-35cc-83d7cffdc592
md"""
# Basics
Small refresher on function definition, methods & multiple dispatch:
"""

# ╔═╡ 5b3db6f3-38be-4be2-9b66-b4ddd6c049bb
begin
	"""
		foo(x::T,y::T;  mult=oneunit(T)) where {T<:Number}
	
	add two numbers `x` and `y` and multiple the result by `mult`
	"""
	function foo(x::T,y::T, mult=oneunit(T)) where {T<:Number}
		return (x + y) * mult
	end

	"""
		foo(x::String, y::String)

	Combine `::String` `x` and `y`
	"""
	function foo(x::String, y::String)
		return x*y
	end

	"""
		foo(x::String, y::Integer)

	Repeat a `::String` `x` `y` times
	"""
	function foo(x::String, y::Integer)
		x^y
	end

end

# ╔═╡ a9547c5c-09e4-4336-b3d2-62e93efb15ac
with_terminal() do
	for (method, args) in zip(methods(foo), [(1,2,4); ("175","POL"); ("PO",2)])
		println(method)
		println("foo($(join(args,", "))) = $(foo(args...))  (this is a ::$(typeof(foo(args...))))")
	end
	println("\nBroadcasting using the dot syntax:")
	broadcast_result = foo.(["$(i)" for i in 173:178], "POL")
	println("""\tfoo.(["\$(i)" for i in 173:178], "POL")\n\t = $(broadcast_result) (this is a ::$(typeof(broadcast_result)))""") 
end

# ╔═╡ 3d032a3c-58e0-41ee-b369-4c14b79f2ad2


# ╔═╡ 59cd14ec-bda2-4342-b087-2c4640787c87
md"""
Remark: for data storage and access, you can use the [JLD2 package](https://github.com/JuliaIO/JLD2.jl)). E.g.
```Julia
using JLD2
x = [1,2]
y = Dict("a"=>20, "b"=>30)
# store values
save("mydatadump.jld", "var1", x, "var2", y)
# load specific value
z = load("mydatadump.jld", "var1")
# verify equality
@assert all(z .== x)
```
"""

# ╔═╡ 650f5346-ec62-11ea-3007-bded07c572b4
md"
# Visualisations
This notebook demonstrates how different types of visualisations and customisations can be realised. The following packages are used:
* [Plots](http://docs.juliaplots.org/latest/) (for the basic plotting needs)
* [Measures](https://github.com/JuliaGraphics/Measures.jl) (for specific measurements e.g. mm, px etc.)
* [LaTeXStrings](https://github.com/stevengj/LaTeXStrings.jl) (for LaTeX-style text in plots)
* [Dates](https://docs.julialang.org/en/v1/stdlib/Dates/index.html) (for datetime functionality)
* [Distributions](https://juliastats.github.io/Distributions.jl/stable/) (for everything related to probability distributions)
* [StatsPlots](https://github.com/JuliaPlots/StatsPlots.jl) (drop-in for Plots, focused on statistical plots e.g. histograms, boxplots etc.)


For an in-depth overview of everything that is possible, please refer to the package  documentation. The illustrations below are intented to show the most common tasks and are by no means exhaustive.
"

# ╔═╡ b813bcb4-b055-4b9f-b9d7-82464a67b934
md"""### Basic plotting
"""

# ╔═╡ 7aab6b96-ec63-11ea-3bfb-3352ff34b218
begin 
	x = range(0,stop=10);
	plot(x,x,size=(300,300),label="y = x")
end

# ╔═╡ a16e752a-ec63-11ea-1844-7fb87dcdbc97
begin
	# basic parabola plot
	plot(x, -(x .- 6).^2 .+ 6, size=(500,300), label=L"y=-(x - 6)^2 + 6", legend=:topleft, marker=:square)
	# add another series to same figure (not shown in legend). Note the `!`
	plot!([0, 6, 6], [6, 6, 0], label="", linestyle=:dash,linecolor=:black)   
	title!("Parabola with LaTeX-style legend\n and markers", titlefontsize=10)
	xlabel!(L"x")
	ylabel!(L"f(x)")
	# customising the axis ticks
	yticks!([0, 2, 4, 6, 8, 10],[L"0", L"2", L"4", L"y_{max} (6)", L"8", L"10"])
	xticks!(range(0,maximum(x),step=2),[L"0", L"2", L"4", L"6 (x_{opt})", L"8", L"10"])
	# customizing the axis £limits
	ylims!(0,10)
	xlims!(0,10)
end

# ╔═╡ baff4686-ec63-11ea-1338-75dca08c7de2
md"If you want only a point cloud, a scatter plot might be more appropriate:"

# ╔═╡ bc751234-ec63-11ea-0fb6-e781763a22df
scatter(x, x, label="datapoints", legend=:topleft, size=(300,300))

# ╔═╡ bc5f7adc-ec63-11ea-1a26-a9a35bee147e
md"Other types of plots are possibly suited as well"

# ╔═╡ bc47c360-ec63-11ea-3c83-6517823915e7
begin		
	Plots.bar(x, x.^2, orientation=:v, label="data", legend=:topleft, bar_width=0.1, grid=false)
	xticks!(range(0, maximum(x), step=2))
	xlabel!(L"x")
	ylabel!(L"f(x)=x^2")
	title!("bar chart (no grid)")
end

# ╔═╡ bc2ede4a-ec63-11ea-2764-bb1f2e6f5885
begin
	Plots.pie(["Class $(i)" for i in x],x,right_margin=5mm, legend_position=:outerright)
	title!("pie chart\nwith extra margin and outer legend")

end

# ╔═╡ fda0cf78-ec63-11ea-0012-2ddb44467f3e
md"Sometimes you might want to change the direction of an axis. The example below shows how this can be done. The y-axis is done in a similar way. Using simply `flip` inverts both axes.

When passing a vector of the same length of the data as argument to markersize, you can give each marker a specific size. The same goes for fill and color options."

# ╔═╡ fd72acc2-ec63-11ea-012d-7b9ff452241f
plot(x, x, xflip=true, label="",
    marker=:circle, markersize= sqrt.(100 .* x), 
    markeralpha = 3*x ./4  ./ maximum(x),
    markercolor = rand([:blue, :red, :yellow, :green, :black], length(x)),
	title="random colors, proportional size and marker alpha")

# ╔═╡ fd5f008c-ec63-11ea-131c-11b728095a8a
md"### Example  - subplots
In some cases, it is wishful to show multiple graphs on the same figure. This can be done either by a simple rectangular layout, or following a more advanced lay-out (seen below).

When setting options after the global plot, they will be applied to all subplots. Below this is used to have the same domain and x-ticks for the different subplots.
"

# ╔═╡ fd4b49e0-ec63-11ea-23b6-d18af17f6219
let
	# only used to hold the title (small hack)
	global_title = plot(title = "Standard subplot", grid=false, showaxis=false, ticks=false, bottom_margin = -10Plots.px)
	# common settings
	plotsettings = Dict(:marker => :circle, :ylims=>(0, 110), :legend_position => :topleft)
	# actual plots
	p1 = plot(x, x,   label=L"y=x",  title="straight line")
	p2 = plot(x, x.^2,label=L"y=x^2",title="parabola")
	subplots = plot(p1,p2; plotsettings...)
	# setting some setting afterwards (note: this affects all subplots)
	xlims!(subplots, 0,12)
	xticks!(subplots, 0:2:10)
	# final (global plot)
	p_final = plot(global_title, subplots, layout=@layout([A{0.01h}; B]) )
end

# ╔═╡ fd34e510-ec63-11ea-2bc4-17cd1d8fe2be
md"
More advanced layouts can be created with the `@layout` macro (already briefly seen in the previous example). The lay-out should be seen as a multidimensional array. Specific layouts can be obtained by using the curly brackets and specifying the desired dimensions for width and height. The example below creates a plot with three subplots divided over two rows. In the first row, p1 gets 30% of the total width and p2 gets the remaing 70%.
    
Notice how we can pass the yscale (and most other) arguments as an argument to subplots that required similar scales.
"

# ╔═╡ fd1eeb34-ec63-11ea-2c76-433607b69721
let
	# only used to hold the title (small hack)
	global_title = plot(title = "More advanced subplot", grid=false, showaxis=false, ticks=false, bottom_margin = -10Plots.px)
	# common settings
	sharedylims = (0,200)
	plotsettings = Dict(:marker => :circle, :legend_position => :topleft, :xlims => (0,11), :xticks => 0:2:10)
	# actual plots
	p1 = plot(x, x,   label=L"y=x",  			title="straight line", ylims=sharedylims)
	p2 = plot(x, x.^2,label=L"y=x^2", 			title="parabola", ylims=sharedylims)
	p3 = plot(x, x.^(1/2),label=L"y=\sqrt{x}", 	title="root of x",markersize=1, ylims=(0,4))
	# custom layout for the subplots
	L = @layout [ [a{0.3w} b{0.7w}]
				   c{0.25h}]
	subplots = plot(p1,p2,p3,; layout=L, plotsettings...)
	# final (global plot)
	p_final = plot(global_title, subplots, layout=@layout([A{0.01h}; B]) )
end

# ╔═╡ fd0b42d2-ec63-11ea-1c4a-392ddd2b618f
md"""
### Example - Storing the result for a report
Sometimes, you want to export an illustration for use in a publication. Several file formats are available, but file format compatibility depends on the backend that is being used.

```Julia
savefig(p_final,"mysubplot.pdf") # saves as pdf
savefig(p_final,"mysubplot.png") # saves as png
```
"""

# ╔═╡ fcf51cf8-ec63-11ea-31c1-03f8886d96a7
md"""
### Example - Working with logarithmic scales
For some applications, representing the information on a logarithmic scale gives a better overview of what is happening. Remark: if there is zero or negative data in the vector you are trying to plot, this will not work.

Consider for instance the successive approximations of a root with Newton's method: 
"""

# ╔═╡ fcdd0e44-ec63-11ea-2959-f12a7d18409e
let
	f = x -> x.^2 .- 9
	g = x -> x - f(x) ./ (2 .* x)
	x0 = [5.0]
	for i in 1:4
		push!(x0,g(x0[end]))
	end

	# note the usage of `xticks!`, `xlabel!`, `!ylabel` to give both graphs the same layout with only one line
	plot(plot(range(0,stop=length(x0)-1), abs.(x0 .- 3), 
			  yscale=:log10, marker=:circle, yticks= 10. .^ (-12:2:0), ylims=(10. .^ -12, 10.)),
		 plot(range(0,stop=length(x0)-1), abs.(x0 .- 3), ylims=(0,2), marker=:circle),
		 layout=(2,1),
		 title=["log10 scale y" "normal scale y"],
		 size=(600,300)
		 )

	plot!(grid=false,legend=false)
	xticks!(range(0, stop=length(x0)-1))
	ylabel!("Absolute error",yguidefont=8)
	xlabel!("Iteration",xguidefont=12)
end

# ╔═╡ acbe3270-ec64-11ea-1afd-2fdb2663cf4c
md"""
### Example - Using date/time in plots
When working with discrete event simulation, we often study the behavior in function of the time. Below is an illustration of using date/time in plots.

Suppose we want to represent a daily measurement. For readability, we desire to have ticks on the x-axis every n days.

Notice the extra instruction `bottom_margin=7mm` in the final plot. This offset is required to avoid cutting off part of the x-axis labels.
"""

# ╔═╡ aca85718-ec64-11ea-2d1a-21eb8d33c7ee
let
	# data generation
	x = now(): Day(1) : now() + Month(1)
	y = rand(length(x))

	# subplots
	plotsettings = Dict(:grid => false, :legend => false)
	p1 = plot(x,y,title="default layout"; plotsettings...)
	p2 = plot(x,y,title="modified layout",xrotation=75; plotsettings...)

	# specifying the tick format (cf. documentation)
	n = 5
	datexticks = [Dates.value(mom) for mom in x[1:n:end]]
	datexticklabels = Dates.format.(x,"u dd HH:MM")
	xticks!(datexticks, datexticklabels, tickfonthalign=:center)

	# final plot
	plot(p1,p2,size=(800,300),bottom_margin=23mm)
end

# ╔═╡ ac923b84-ec64-11ea-31cd-278bce8566f7
md"""
### Example
Suppose we have a measurement that should follow a multinomial normal distribution: 
``X \sim N(\bar{\mu},\Sigma)``, i.e. a measurement in a two-dimensional space. We want to represent this graphically. Severel options could be considered: a 3D-plot, a heatmap, a contour plot.
"""

# ╔═╡ ac7a0e38-ec64-11ea-3b16-e50c3ea51b7e
# Data generation
begin
	μ₁ = 10; μ₂ = 20; μ = [μ₁, μ₂]  # mean matrix
	Σ = [1.0 0;0 3];                # covariance matrix (i.e. no correlation between the variables)
	d = Distributions.MvNormal(μ,Σ) # multivariate normal distribution

	# make a grid (control)
	ns = 3
	nx = 21
	ny = 31
	X = range(μ₁ - ns*Σ[1,1], stop=μ₁ + ns*Σ[1,1], length=nx);
	Y = range(μ₂ - ns*Σ[2,2], stop=μ₂ + ns*Σ[2,2], length=ny);
	grid = (collect(Iterators.product(X,Y)))
	Zval = map(x->pdf(d,collect(x)), grid)
	
	# common plot setting
	plotsettings =  Dict(:xlims=>(0,20), :ylims=>(10,30), 
					     :xlabel=>"x", :ylabel=>"y")
	
	# vectors to plot
	XX = [v[1] for v in vec(grid)]
	YY = [v[2] for v in vec(grid)]
	ZZ = vec(Zval)
end

# ╔═╡ ac629280-ec64-11ea-2f69-45e26a6cde89
md"""Below you can see a 3D point cloud. Note that you need to provide elements of the same size (in this case an $(typeof(XX)) with dimensions $(size(XX))) """

# ╔═╡ 2409b193-bf0f-421f-bad0-815bfcf399cc
begin
	scatter3d(XX,YY,ZZ, label="$(d)"; plotsettings...)
end

# ╔═╡ 0139c2d8-63fa-474e-8e9f-cf6093a266a4
begin
	# generate figure itself
	p = plot(surface(XX,YY,ZZ, color=:blues, title="surface plot"),
             surface(XX,YY,ZZ, color=cgrad(:blues,rev=true), title="surface plot\n(reversed colors)"),
             contourf(X,Y,ZZ, title="contour plot"),
   		     heatmap(X,Y,Zval', title="heatmap"),
			 # settings that will be used
             layout=(2,2), size=(1000,1000); plotsettings...)
	# save externally
	for extension in ["png","pdf"]
		savefig(p,joinpath(pwd(),"Exercises/img/newblup.$(extension)"))
	end
	p
end

# ╔═╡ d7c20e82-ec65-11ea-1412-d39f97aae166
md"""
## Statistical plots
In the context of numerical simulations, it will be required to do some statistical exploitation of the generated data. A lot of specific statistical plotting recipes are grouped in the `StatsPlots` package.

### Example

We have a sample (`` X \sim \chi ^{2}_{k=3}``) that we want to visualize as a boxplot. The following keywords are available:
* `notch=false`: if a notch should be included in the box.
* `range=1.5`: multiple of the inter-quartile range that is used to determine outliers
* `whisker_width=:match`: width of the whiskers
* `outliers=true`: if outliers should be show on the plot
* `bar_width=0.8`: width of the boxplot

Most keywords that work with Plots also work here (as illustrated below)
"""

# ╔═╡ fa03f666-ec65-11ea-11ba-65868aaf856d
let
	k = 3; n = 40
	d = Distributions.Chisq(k)
	x = rand(d,n)

	plot(StatsPlots.boxplot(x,ylabel="observed measure",title="base layout"),
		 StatsPlots.boxplot(x,ylabel="observed measure",legend=false,grid=false,
							whisker_width = 0.2,
							title="modified representation",
							xlims=(0,2),xticks=(1,["sample 1"]),
							fillalpha=0.4,fillcolor=2,       # specifying different color for box and marker
						 	markershape=:square,
							markercolor=3,
							markersize=6,
							markeralpha=0.8
						   ),
		 size=(600,300))
end

# ╔═╡ f9efb41e-ec65-11ea-128a-77f4376ed9e4
md"""
### Example
We want to:
- visualize a probality distribution, both the PDF and the CDF, e.g $X\sim N \left( 10,2  \right)$.
- highlight some accents (annotations)
- gain additional understanding of the concept type II errors. For $\alpha = 0.025$ and for the following $H_0: E[X]<=10,H_1: E[X]>10$ and we are interested in the type II error if $E[X]=16$
"""

# ╔═╡ f9d800da-ec65-11ea-279b-4558590a769b
let
	# parameters
	μ = 10; σ = 2
	μᵣ = 16
	d₀ = Normal(μ,σ)
	d₁ = Normal(μᵣ,σ)
	α = 0.025
	# data/distribution generation
	x = range(μ - 4σ,stop=μ + 7σ,length=100)
	x_crit = quantile(d₀,1-α)
	x_reject = range(x_crit,stop=maximum(x),length=100)
	x_accept = range(minimum(x),stop=maximum(x_crit),length=100)
	β = pdf(d₁,x_crit)

	# actal plotting
	p1 = plot(x, pdf.(d₀,x),label="\$ PDF: X  \\sim \\mathcal{N} \\left( $μ, $σ \\right)   \$",legend=:top,color=:black,grid=false) # first PDF
		 plot!(x, pdf.(d₁,x),label="\$ PDF: X  \\sim \\mathcal{N} \\left( $μᵣ, $σ \\right)   \$",color=:black) # first PDF
		 plot!(x_reject,pdf.(d₀,x_reject),fillrange=0,fillalpha=0.5,color=2,label="Rejection region",linealpha=0 ) # fill rejection region
		 plot!(x_accept,pdf.(d₀,x_accept),fillrange=0,fillalpha=0.5,color=3,label="Acceptance region",linealpha=0 ) # fill rejection region
		 annotate!(μ, 0.21,"\$ H_0 \$")
		 annotate!(μᵣ, 0.21,"\$ H_1 \$")
		 title!("Acceptance & rejection region for \\alpha= $α ",titlefontsize=10)
		 ylims!(0,0.35)

	p2 = plot(x, pdf.(d₀,x),label="\$ PDF: X  \\sim \\mathcal{N} \\left( $μ, $σ \\right)   \$",color=:black,grid=false) # first PDF
		 plot!(x, pdf.(d₁,x),label="\$ PDF: X  \\sim \\mathcal{N} \\left( $μᵣ, $σ \\right)   \$",color=:black) # first PDF
		 plot!(x_reject,pdf.(d₀,x_reject),fillrange=0,fillalpha=0.5,color=2,label="Type I error",linealpha=0 ) # fill alpha region
		 plot!(x_accept,pdf.(d₁,x_accept),fillrange=0,fillalpha=0.5,color=1,label="Type II error",linealpha=0 ) # fill beta region
		 annotate!(μ, 0.21,"\$ H_0 \$")
		 annotate!(μᵣ, 0.21,"\$ H_1 \$")
		 annotate!(11, 0.04,"\$ \\beta \$")
		 annotate!(15, 0.04,"\$ \\alpha \$")
		 title!("Type I & Type II errors - For \\alpha = $α: \\beta = $(round(β,digits=2))",titlefontsize=10)
		 ylims!(0,0.35)
	
	subplots = plot(p1,p2,size=(800,400)) 
	global_title = plot(title = "A throwback to your statistics course", grid=false, showaxis=false, ticks=false, bottom_margin = -10Plots.px)
	# final result
	p_final = plot(global_title, subplots, layout=@layout([A{0.01h}; B]) )
end

# ╔═╡ f9c07316-ec65-11ea-33ef-7d3037547e69
md"""
# Example
We have data and we want to:
* show the emperical and theoretical PDF 
* show the emperical and theoretical CDF 
* get an idea to what extent the data matches a proposed distribution by means of a PP/QQ plot
"""

# ╔═╡ 4a754fca-ec66-11ea-3716-75e22e7cfed8
let
	# data/distribution generation
	μ = 10; σ=2; n = 50
	d = Distributions.Normal(μ,σ)
	x = sort(rand(d,n))
	x_d = range(μ - 5σ,stop=μ + 5σ,length=100)

	# actual plotting
	p1 = plot(x_d, pdf.(d,x_d),label="true distribution",ylabel="\$ f_X(x) \$",xlabel="\$ x \$",title="PDF")
		 histogram!(x,normalize=true,label="sample",fillalpha=0.5,legend=:best)
	p2 = plot(x_d, cdf.(d,x_d),label="true distribution",ylabel="\$ F_X(x) \$",xlabel="\$ x \$",title="CDF")
		 plot!(x,range(1,stop=length(x))/length(x),legend=:bottomright,linetype=:step,label="sample")
	p3 = StatsPlots.qqplot(x,d,title="QQ-plot")
	subplots = plot(p1,p2,p3,size=(900,400),layout=(1,3),xlims=(μ - 5σ,μ + 5σ))
 
	global_title = plot(title = "Another throwback to your statistics course", grid=false, showaxis=false, ticks=false, bottom_margin = -10Plots.px)
	# final result
	p_final = plot(global_title, subplots, layout=@layout([A{0.01h}; B]), left_margin=15Plots.px, bottom_margin=5mm)
end

# ╔═╡ 4a60fb9c-ec66-11ea-2582-a584b6ade23b
md"""
### Example

We have generated some data and want to make 
* a histogram representation (counts).
* a PDF estimation (percentages).
* a [kernel density estimation](https://en.wikipedia.org/wiki/Kernel_density_estimation).
"""

# ╔═╡ 4a4ad0c4-ec66-11ea-2fe0-7d446c995ea3
let
	# data and distribution generation
	d = Distributions.Uniform(10,20)
	x = rand(d,50)

	# actual plot
	plotsettings = Dict(:xlabel => "x", :legend => false, :ylabel => "counts", :grid => false)
	p1 = StatsPlots.histogram(x, title="auto bin width"; plotsettings...)
	p2 = StatsPlots.histogram(x, bins=10, title="fixed number of bins"; plotsettings...)
	p3 = StatsPlots.histogram(x, bins=[10, 14, 14, 15, 16, 19, 20], title="imposed bin limits"; plotsettings...)
	p4 = StatsPlots.histogram(x, normalize=true, ylims=(0,0.2), title="auto bin width,normalized"; plotsettings...)
	p5 = StatsPlots.histogram(x, bins=10, normalize=true, ylims=(0,0.2), title="fixed number of bins, normalized"; plotsettings...)
	p6 = StatsPlots.histogram(x, bins=[10, 14, 14, 15, 16, 19, 20], normalize=true, ylims=(0,0.2),
							  title="imposed bin limits, normalized"; plotsettings...)
	p7 = StatsPlots.density(x,title="Kernel density estimate", ylabel="\$ \\hat{f}_X(x) \$",xlabel="\$ x \$", label="")

	l = @layout [ [a b c]
				  [d e f]
				  g{0.6h}]
	plot(p1,p2,p3,p4,p5,p6,p7,layout=l,size=(900,600))
	subplots = plot!(titlefontsize=10, left_margin=5mm)
	global_title = plot(title = "Fun with histograms", grid=false, showaxis=false, ticks=false, bottom_margin = -10Plots.px)
	# final result
	p_final = plot(global_title, subplots, layout=@layout([A{0.01h}; B]), left_margin=15Plots.px, bottom_margin=5mm)
end

# ╔═╡ d7abc762-ec65-11ea-29fc-7188ba315fca
md"""
### Example - different representations of a sample
We generate random data $x\sim N \left( \mu,\sigma  \right)$ with $\mu = x, \sigma=\sqrt{x}$ for $x \in [2,10]$ and use several methods of representation.
"""

# ╔═╡ 7a55c97c-ec66-11ea-3d85-51615e70f1c1
let
	# Basic statistics and sampling
	α = 0.05                     # type 1 error
	n = 10                       # sample length
	x = range(2,stop=10,step=2)  #
	d = Normal.(x,sqrt.(x))      # array of distributions
	y = [rand(k,n) for k in d]   # actual sample of length n for each distribution
	mu_hat = mean.(y)            # 
	sigma =  std.(y)             #

	# Making a classic plot (raw data points)
	p1 = plot(repeat(x,inner=n),collect(Iterators.flatten(y)),
			  marker=:circle,linealpha=0,label="raw data points",legend=:topleft)
	plot!(x,x,marker=:square,label="Real value")
	title!("Raw data (n = $(n))")
	ylims!(0,20)

	# Making a boxplot plot
	p2 = boxplot(repeat(x,inner=n),collect(Iterators.flatten(y)),label="boxplot sample")
	plot!(x,x,marker=:square,label="Real value")
	plot!(legend=:topleft)
	title!("Boxplots")
	ylims!(0,20)

	# Making a ribbon plot (if normality is OK)
	upper = quantile(Normal(),1 - α/2) * sigma / sqrt(n)
	lower = upper
	p3 = plot(x,mu_hat,marker=:circle,ribbon=(lower,upper),label="μ̂")
	plot!(x,x,marker=:square,label="Real value")
	plot!(legend=:topleft)
	title!("95% CI for μ̂")
	ylims!(0,20)

	subplots = plot(p1,p2,p3,layout=(1,3),size=(800,400))
	global_title = plot(title = "Different representations of the same data", grid=false, showaxis=false, ticks=false, bottom_margin = -30Plots.px)
	# final result
	p_final = plot(global_title, subplots, layout=@layout([A{0.01h}; B]), left_margin=15Plots.px, bottom_margin=2mm)
end

# ╔═╡ 7a3fbc40-ec66-11ea-34f3-b3804f016b55
md"""
### Some Background - colors
The colors that will be used are associated with a palette, i.e. the way your plots will look in general (this includes background, frames, color palette etc. The default value is `:default` and the associated colorset has 17 colors. You can list these by using `palette(:default)`. When making a plot, you can also force to use color N° x by explicitly writing it as in integer. e.g `plot(x,color=1)`. A lot of colors have their own alias e.g. `:blue`

Should you plot more than 17 data series, the list starts again at the beginning. Should you require more for some reason, let's say 20, you can use `get_color_palette(:auto, plot_color(:default),20)`. 



"""

# ╔═╡ 0bfad805-2483-40d9-bd94-c76b2dcb238a
# custom color palette:
my_palette = palette([:green, :blue, :white, :red, :yellow],30)

# ╔═╡ 7a269742-ec66-11ea-1b40-9d8cce31f885
let
	# data and distribution settings
	μ = range(1,step=2,length=5)
	d = Normal.(μ,1)
	x = [rand(dist,10) for dist in d]

	# actual plots
	p1 = plot(x,legend=false,linewidth=5)
	title!("Default colors")
	# using only limited subset of colors
	p2 = plot(x,color=[1 3 5 10 15],legend=false,linewidth=5)
	title!("Forced colors")
	# using only two colors of the custom palette
	p3 = plot(x,color=[my_palette[1] my_palette[4]],legend=false,linewidth=5)

	# combine it all
 	subplots = plot(p1,p2,p3,layout=(1,3),size=(900,300),title=(["default colors" "forced colors"  "cylcing between only two colors"]),titlefontsize=10)
	global_title = plot(title = "Playing with colors", grid=false, showaxis=false, ticks=false, bottom_margin = -30Plots.px)
	# final result
	p_final = plot(global_title, subplots, layout=@layout([A{0.01h}; B]), left_margin=15Plots.px, bottom_margin=2mm)
end

# ╔═╡ 7a111b6a-ec66-11ea-3a5a-cd6de910dd00
md"""
## Tasks
* Play around a bit with plotting and different data respresentations.
* Generate a histogram representing the birthdays of your colleagues. Also make a kernel density estimation and show this as a transparant overlay on the same figure. Save as pdf and compare with the other language group.
* ...
"""

# ╔═╡ 1c2ac5e2-792f-4368-92dd-1e7dab3dd6ad
md"""
## More info
There is a lot of additional information available on the webpages of the different packages. Another other nice resource is [Interactive Visualization and Plotting with Julia](https://packtpublishing.github.io/Interactive-Visualization-and-Plotting-with-Julia/).


"""

# ╔═╡ 79faeac0-ec66-11ea-1d6d-318ab749e232


# ╔═╡ Cell order:
# ╠═9f0fff31-d180-499b-b8a4-27d09f9311c2
# ╠═8e3917d6-ec62-11ea-0c16-7d2749432dd1
# ╠═02c1eefc-ec63-11ea-35cc-83d7cffdc592
# ╠═5b3db6f3-38be-4be2-9b66-b4ddd6c049bb
# ╟─a9547c5c-09e4-4336-b3d2-62e93efb15ac
# ╠═3d032a3c-58e0-41ee-b369-4c14b79f2ad2
# ╟─59cd14ec-bda2-4342-b087-2c4640787c87
# ╟─650f5346-ec62-11ea-3007-bded07c572b4
# ╟─b813bcb4-b055-4b9f-b9d7-82464a67b934
# ╠═7aab6b96-ec63-11ea-3bfb-3352ff34b218
# ╠═a16e752a-ec63-11ea-1844-7fb87dcdbc97
# ╟─baff4686-ec63-11ea-1338-75dca08c7de2
# ╠═bc751234-ec63-11ea-0fb6-e781763a22df
# ╟─bc5f7adc-ec63-11ea-1a26-a9a35bee147e
# ╠═bc47c360-ec63-11ea-3c83-6517823915e7
# ╠═bc2ede4a-ec63-11ea-2764-bb1f2e6f5885
# ╟─fda0cf78-ec63-11ea-0012-2ddb44467f3e
# ╠═fd72acc2-ec63-11ea-012d-7b9ff452241f
# ╟─fd5f008c-ec63-11ea-131c-11b728095a8a
# ╠═fd4b49e0-ec63-11ea-23b6-d18af17f6219
# ╟─fd34e510-ec63-11ea-2bc4-17cd1d8fe2be
# ╠═fd1eeb34-ec63-11ea-2c76-433607b69721
# ╟─fd0b42d2-ec63-11ea-1c4a-392ddd2b618f
# ╟─fcf51cf8-ec63-11ea-31c1-03f8886d96a7
# ╠═fcdd0e44-ec63-11ea-2959-f12a7d18409e
# ╟─acbe3270-ec64-11ea-1afd-2fdb2663cf4c
# ╠═aca85718-ec64-11ea-2d1a-21eb8d33c7ee
# ╟─ac923b84-ec64-11ea-31cd-278bce8566f7
# ╠═ac7a0e38-ec64-11ea-3b16-e50c3ea51b7e
# ╟─ac629280-ec64-11ea-2f69-45e26a6cde89
# ╠═2409b193-bf0f-421f-bad0-815bfcf399cc
# ╠═0139c2d8-63fa-474e-8e9f-cf6093a266a4
# ╟─d7c20e82-ec65-11ea-1412-d39f97aae166
# ╠═fa03f666-ec65-11ea-11ba-65868aaf856d
# ╟─f9efb41e-ec65-11ea-128a-77f4376ed9e4
# ╠═f9d800da-ec65-11ea-279b-4558590a769b
# ╟─f9c07316-ec65-11ea-33ef-7d3037547e69
# ╠═4a754fca-ec66-11ea-3716-75e22e7cfed8
# ╟─4a60fb9c-ec66-11ea-2582-a584b6ade23b
# ╠═4a4ad0c4-ec66-11ea-2fe0-7d446c995ea3
# ╟─d7abc762-ec65-11ea-29fc-7188ba315fca
# ╠═7a55c97c-ec66-11ea-3d85-51615e70f1c1
# ╟─7a3fbc40-ec66-11ea-34f3-b3804f016b55
# ╠═0bfad805-2483-40d9-bd94-c76b2dcb238a
# ╠═7a269742-ec66-11ea-1b40-9d8cce31f885
# ╟─7a111b6a-ec66-11ea-3a5a-cd6de910dd00
# ╟─1c2ac5e2-792f-4368-92dd-1e7dab3dd6ad
# ╠═79faeac0-ec66-11ea-1d6d-318ab749e232
