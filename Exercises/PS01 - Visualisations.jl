### A Pluto.jl notebook ###
# v0.15.1

using Markdown
using InteractiveUtils

# ╔═╡ 8e3917d6-ec62-11ea-0c16-7d2749432dd1
begin
	using Distributions
	using LaTeXStrings
	using Plots
	using StatsPlots
	using Measures
	using Dates
	#using JLD # removed because JLD does not work on CDN
end

# ╔═╡ 9f0fff31-d180-499b-b8a4-27d09f9311c2
# Make cells wider
html"""<style>
/*              screen size more than:                     and  less than:                     */
@media screen and (max-width: 699px) { /* Tablet */ 
  /* Nest everything into here */
    main { /* Same as before */
        max-width: 1200px !important; /* Same as before */
        margin-right: 100px !important; /* Same as before */
    } /* Same as before*/

}

@media screen and (min-width: 700px) and (max-width: 1199px) { /* Laptop*/ 
  /* Nest everything into here */
    main { /* Same as before */
        max-width: 1200px !important; /* Same as before */
        margin-right: 100px !important; /* Same as before */
    } /* Same as before*/
}

@media screen and (min-width:1200px) and (max-width: 1920px) { /* Desktop */ 
  /* Nest everything into here */
    main { /* Same as before */
        max-width: 1200px !important; /* Same as before */
        margin-right: 100px !important; /* Same as before */
    } /* Same as before*/
}

@media screen and (min-width:1921px) { /* Stadium */ 
  /* Nest everything into here */
    main { /* Same as before */
        max-width: 1200px !important; /* Same as before */
        margin-right: 100px !important; /* Same as before */
    } /* Same as before*/
}
</style>
"""

# ╔═╡ 650f5346-ec62-11ea-3007-bded07c572b4
md"
# Visualisations
This notebook demonstrates how different types of visualisations and customisations can be realised. The following packages are required:
* [Distributions](https://juliastats.github.io/Distributions.jl/stable/) (for everything related to probability distributions)
* [Plots](http://docs.juliaplots.org/latest/) (for the basic plotting needs)
* [LaTeXStrings](https://github.com/stevengj/LaTeXStrings.jl) (for LaTeX-style text in plots)
* [StatsPlots](https://github.com/JuliaPlots/StatsPlots.jl) (drop-in for Plots, focused on statistical plots e.g. histograms, boxplots etc.)
* [Measures](https://github.com/JuliaGraphics/Measures.jl) (for specific measurements e.g. mm, px etc.)
* [Dates](https://docs.julialang.org/en/v1/stdlib/Dates/index.html) (for datetime functionality)

For an in-depth overview of everything that is possible, please refer to the package  documentation. The illustrations below are intented to show the most common tasks and are by no means exhaustive.
"

# ╔═╡ 02c1eefc-ec63-11ea-35cc-83d7cffdc592
md"""
# Basics
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

# ╔═╡ 76d56f00-5217-4906-9361-7188ee65968b
md"""
Small refresher on function definition, methods & multiple dispatch:
"""

# ╔═╡ 5b3db6f3-38be-4be2-9b66-b4ddd6c049bb
begin
	"""
		foo(x,y; kw1)
	
	small demo function
	"""
	function foo(x::T,y::T; kw1=oneunit(T)) where {T<:Number}
		return (x + y) * kw1
	end
	
	function foo(x::String, y::String)
		return x*y
	end
	
	function foo(x::String, y::Integer)
		x^y
	end
	
	function foo(v::Vector{T}, y::T) where {T<:Number}
		return
	end
end

# ╔═╡ 7f8e306c-fd69-43b7-8142-b7d6feb6c0ea
typeof(foo(Float16(2.),Float16(2.)))

# ╔═╡ e3ea183c-4fb4-4b59-aaa6-de60e9ab8e2d
foo("PO",2)

# ╔═╡ 23a8e574-1da5-48c9-afbf-888a8b1d8b2b
methods(foo)

# ╔═╡ b813bcb4-b055-4b9f-b9d7-82464a67b934
md"""### Basic plotting
"""

# ╔═╡ 7aab6b96-ec63-11ea-3bfb-3352ff34b218
x = range(0,stop=10)

# ╔═╡ 7efb1dd5-0c53-4896-b91a-1e7d85941f66
collect(x)

# ╔═╡ 80435a32-ec63-11ea-18b3-61d3d41b396d
plot(x,x,size=(300,300),label="y = x")

# ╔═╡ a16e752a-ec63-11ea-1844-7fb87dcdbc97
let
	plot(x,-(x .- 6).^2 .+ 6,size=(500,300), label=L"y=-(x - 6)^2 + 6",legend=:topleft, marker=:square)
	plot!([0, 6, 6],[6, 6, 0],label="",linestyle=:dash,linecolor=:black)   # add another series to same figure (not shown in legend)
	title!("Parabola with LaTeX-style legend\n and markers",titlefontsize=10)
	xlabel!(L"x")
	ylabel!(L"f(x)")
	# customising the axis ticks
	yticks!([0, 2, 4, 6, 8, 10],[L"0", L"2", L"4", L"y_{max} (6)", L"8", L"10"])
	xticks!(range(0,maximum(x),step=2),[L"0", L"2", L"4", L"6 (x_{opt})", L"8", L"10"])
	# customizing the limits
	ylims!(0,10)
end

# ╔═╡ baff4686-ec63-11ea-1338-75dca08c7de2
md"If you want only a point cloud, a scatter plot might be more appropriate:"

# ╔═╡ bc751234-ec63-11ea-0fb6-e781763a22df
scatter(x,x,label="datapoints",legend=:topleft,size=(300,300))

# ╔═╡ bc5f7adc-ec63-11ea-1a26-a9a35bee147e
md"Other types of plots are possibly suited as well"

# ╔═╡ bc47c360-ec63-11ea-3c83-6517823915e7
begin		Plots.bar(x,x.^2,orientation=:v,label="data",legend=:topleft,bar_width=0.1,grid=false)
	xticks!(range(0,maximum(x),step=2))
	xlabel!(L"x")
	ylabel!(L"f(x)=x^2")
	title!("bar chart (no grid)")
end

# ╔═╡ bc2ede4a-ec63-11ea-2764-bb1f2e6f5885
begin
	Plots.pie(["Class $(i)" for i in x],x,bottom_margin=5mm)
	title!("pie chart (extra margin for label readability)")
end

# ╔═╡ fda0cf78-ec63-11ea-0012-2ddb44467f3e
md"Sometimes you might want to change the direction of an axis. The example below shows how this can be done. The y-axis is done in a similar way. Using simply `flip` inverts both axes.

When passing a vector of the same length of the data as argument to markersize, you can give each marker a specific size. The same goes for fill and color options."

# ╔═╡ fd72acc2-ec63-11ea-012d-7b9ff452241f
plot(x,x,xflip=true, label="",
    marker=:circle,
    markersize=x, 
    markeralpha = 3*x ./4  ./ maximum(x),
    markercolor = rand([:blue, :red, :yellow, :green, :black],length(x))
)

# ╔═╡ fd5f008c-ec63-11ea-131c-11b728095a8a
md"### Example  - subplots
In some cases, it is wishful to show multiple graphs on the same figure. This can be done either by a simple rectangular layout, or following a more advanced lay-out (seen below).

When setting options after the global plot, they will be applied to all subplots. Below this is used to have the same scale on the y-axis in both subplots.

1. Side-by-side lay-out:
"

# ╔═╡ fd4b49e0-ec63-11ea-23b6-d18af17f6219
begin
	p1 = plot(x,x,label=L"y=x",marker=:circle)
	p2 = plot(x, x.^2,label=L"y=x^2",marker=:circle)
	plot(p1,p2,layout=(1,2),title=["An overview" "of side by side plots"])
	ylims!(0, 200)
end

# ╔═╡ fd34e510-ec63-11ea-2bc4-17cd1d8fe2be
md"2. More advanced layouts:

    These are created with the `@layout` macro. The lay-out should be seen as a multidimensional array. Specific layouts can be obtained by using the curly brackets and specifying the desired dimensions for width and height. The example below creates a plot with three subplots divided over two rows. In the first row, p1 gets 30% of the total width and p2 gets the remaing 70%.
    
    Notice how we can pass the yscale (and most other) arguments as an argument to subplots that required similar scales.
"

# ╔═╡ fd1eeb34-ec63-11ea-2c76-433607b69721
let
	sharedylims = (0,200)
	p1 = plot(x,x,label=L"y=x",marker=:circle, ylims=sharedylims)
	p2 = plot(x, x.^2,label=L"y=x^2",marker=:circle,markersize=10, ylims=sharedylims)
	p3 = plot(x, x.^(1/2),label=L"y=\sqrt{x}",marker=:circle,markersize=1,ylims=(2,4))
	xticks!(range(0,stop=10))
	l = @layout [ [a{0.3w} b{0.7w}]
				   c{0.25h}]
	p = plot(p1,p2,p3,layout=l,title=["(a)" "(b)" "(c)"])
end

# ╔═╡ fd0b42d2-ec63-11ea-1c4a-392ddd2b618f
md"""
### Example - Storing the result for a report
Sometimes, you want to export an illustration for use in a publication. Several file formats are available, but file format compatibility depends on the backend that is being used.

```Julia
savefig(p,"mysubplot.pdf") # saves as pdf
savefig(p,"mysubplot.png") # saves as png
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

	# note the usage of `xticks!` & `xlabel` to give both graphs the same layout with only one line
	plot(plot(range(0,stop=length(x0)-1),abs.(x0 .- 3),yscale=:log10,marker=:circle),
		 plot(range(0,stop=length(x0)-1),abs.(x0 .- 3),ylims=(0,2),marker=:circle),
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
	x = now(): Day(1) : now() + Month(1)
	y = rand(length(x))

	n = 5
	p1 = plot(x,y,title="default layout",grid=false,legend=false)
	p2 = plot(x,y,title="modified layout",xrotation=75,grid=false,legend=false)

	# specifying the tick format (cf. documentation)
	datexticks = [Dates.value(mom) for mom in x[1:n:end]]
	datexticklabels = Dates.format.(x,"YYYY u dd HH:MM")
	xticks!(datexticks,datexticklabels,tickfonthalign=:center)

	# final plot
	plot(p1,p2,size=(800,300),bottom_margin=23mm)

end

# ╔═╡ 4f21ca29-9419-4854-9d83-1bf4974c6fbe
[1;2] .+ [3 4]

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

# ╔═╡ df947306-c97d-4cb9-a55b-90df78e48362
grid

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
         layout=(2,2), size=(1000,1000); plotsettings...)
	# save externally
	for extension in ["png","pdf"]
		#savefig(p,joinpath(pwd(),"img/newblup.$(extension)"))
	end
	p
end

# ╔═╡ 11e03115-3076-4480-a4fb-5165a1d880f6


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
	#∂f∂x1(x) = x
	#🐢
	μ = 10; σ = 2
	μᵣ = 16
	d₀ = Normal(μ,σ)
	d₁ = Normal(μᵣ,σ)
	α = 0.025

	x = range(μ - 4σ,stop=μ + 7σ,length=100)
	x_crit = quantile(d₀,1-α)
	x_reject = range(x_crit,stop=maximum(x),length=100)
	x_accept = range(minimum(x),stop=maximum(x_crit),length=100)

	β = pdf(d₁,x_crit)
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
	plot(p1,p2,size=(800,400))  
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
	μ = 10; σ=2; n = 50
	d = Distributions.Normal(μ,σ)
	x = sort(rand(d,n))
	x_d = range(μ - 5σ,stop=μ + 5σ,length=100)

	p1 = plot(x_d, pdf.(d,x_d),label="true distribution",ylabel="\$ f_X(x) \$",xlabel="\$ x \$",title="PDF")
		 histogram!(x,normalize=true,label="sample",fillalpha=0.5,legend=:best)
	p2 = plot(x_d, cdf.(d,x_d),label="true distribution",ylabel="\$ F_X(x) \$",xlabel="\$ x \$",title="CDF")
		 plot!(x,range(1,stop=length(x))/length(x),legend=:bottomright,linetype=:step,label="sample")
	p3 = StatsPlots.qqplot(x,d,title="QQ-plot")
	plot(p1,p2,p3,size=(900,400),layout=(1,3),xlims=(μ - 5σ,μ + 5σ))
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
	d = Distributions.Uniform(10,20)
	x = rand(d,50)

	p1 = StatsPlots.histogram(x,grid=false,xlabel="x",ylabel="counts",legend=false,title="auto bin width")
	p2 = StatsPlots.histogram(x,grid=false,xlabel="x",ylabel="counts",legend=false,bins=10,title="fixed number of bins")
	p3 = StatsPlots.histogram(x,grid=false,xlabel="x",ylabel="counts",legend=false,bins=[10, 14, 14, 15, 16, 19, 20],title="imposed bin limits")
	p4 = StatsPlots.histogram(x,grid=false,xlabel="x",ylabel="counts",legend=false,title="auto bin width,normalized",normalize=true,ylims=(0,0.2))
	p5 = StatsPlots.histogram(x,grid=false,xlabel="x",ylabel="counts",legend=false,bins=10,title="fixed number of bins, normalized", 
							  normalize=true,ylims=(0,0.2))
	p6 = StatsPlots.histogram(x,grid=false,xlabel="x",ylabel="counts",legend=false,bins=[10, 14, 14, 15, 16, 19, 20],
								title="imposed bin limits, normalized", normalize=true,ylims=(0,0.2))
	p7 = StatsPlots.density(x,title="Kernel density estimate",ylabel="\$ \\hat{f}_X(x) \$",xlabel="\$ x \$")

	l = @layout [ [a b c]
				  [d e f]
				  g{0.6h}]
	plot(p1,p2,p3,p4,p5,p6,p7,layout=l,size=(900,500))
	plot!(titlefontsize=10, left_margin=5mm)
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
	p3 = plot(x,mu_hat,marker=:circle,ribbon=(lower,upper),label=L"\hat{\mu}")
	plot!(x,x,marker=:square,label="Real value")
	plot!(legend=:topleft)
	title!(L"95\% \; CI \;for\; \hat{\mu}")
	ylims!(0,20)

	plot(p1,p2,p3,layout=(1,3),size=(800,400))
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
	μ = range(1,step=2,length=5)
	d = Normal.(μ,1)
	x = [rand(dist,10) for dist in d]
	p1 = plot(x,legend=false)
	title!("Default colors")
	p2 = plot(x,color=[1 3 5 10 15],legend=false)
	title!("Forced colors")
	# using only two colors of the custom palette
	p3 = plot(x,color=[my_palette[1] my_palette[4]],legend=false)
 	P = plot(p1,p2,p3,layout=(1,3),size=(900,300),title=(["default colors" "forced colors"  "cylcing between only two colors"]),titlefontsize=10)
	P
end

# ╔═╡ 7a111b6a-ec66-11ea-3a5a-cd6de910dd00
md"""
## Tasks
* Play around a bit with plotting and different data respresentations.
* Generate a histogram representing the birthdays of your colleagues. Also make a kernel density estimation and show this as a transparant overlay on the same figure. Save as pdf and compare with the other language group.
* ...
"""

# ╔═╡ 79faeac0-ec66-11ea-1d6d-318ab749e232


# ╔═╡ 00000000-0000-0000-0000-000000000001
PLUTO_PROJECT_TOML_CONTENTS = """
[deps]
Dates = "ade2ca70-3891-5945-98fb-dc099432e06a"
Distributions = "31c24e10-a181-5473-b8eb-7969acd0382f"
LaTeXStrings = "b964fa9f-0449-5b57-a5c2-d3ea65f4040f"
Measures = "442fdcdd-2543-5da2-b0f3-8c86c306513e"
Plots = "91a5bcdd-55d7-5caf-9e0b-520d859cae80"
StatsPlots = "f3b207a7-027a-5e70-b257-86293d7955fd"

[compat]
Distributions = "~0.25.16"
LaTeXStrings = "~1.2.1"
Measures = "~0.3.1"
Plots = "~1.21.3"
StatsPlots = "~0.14.26"
"""

# ╔═╡ 00000000-0000-0000-0000-000000000002
PLUTO_MANIFEST_TOML_CONTENTS = """
# This file is machine-generated - editing it directly is not advised

[[AbstractFFTs]]
deps = ["LinearAlgebra"]
git-tree-sha1 = "485ee0867925449198280d4af84bdb46a2a404d0"
uuid = "621f4979-c628-5d54-868e-fcf4e3e8185c"
version = "1.0.1"

[[Adapt]]
deps = ["LinearAlgebra"]
git-tree-sha1 = "84918055d15b3114ede17ac6a7182f68870c16f7"
uuid = "79e6a3ab-5dfb-504d-930d-738a2a938a0e"
version = "3.3.1"

[[ArgTools]]
git-tree-sha1 = "bdf73eec6a88885256f282d48eafcad25d7de494"
uuid = "0dad84c5-d112-42e6-8d28-ef12dabb789f"
version = "1.1.1"

[[Arpack]]
deps = ["Arpack_jll", "Libdl", "LinearAlgebra"]
git-tree-sha1 = "2ff92b71ba1747c5fdd541f8fc87736d82f40ec9"
uuid = "7d9fca2a-8960-54d3-9f78-7d1dccf2cb97"
version = "0.4.0"

[[Arpack_jll]]
deps = ["Libdl", "OpenBLAS_jll", "Pkg"]
git-tree-sha1 = "e214a9b9bd1b4e1b4f15b22c0994862b66af7ff7"
uuid = "68821587-b530-5797-8361-c406ea357684"
version = "3.5.0+3"

[[Artifacts]]
deps = ["Pkg"]
git-tree-sha1 = "c30985d8821e0cd73870b17b0ed0ce6dc44cb744"
uuid = "56f22d72-fd6d-98f1-02f0-08ddc0907c33"
version = "1.3.0"

[[AxisAlgorithms]]
deps = ["LinearAlgebra", "Random", "SparseArrays", "WoodburyMatrices"]
git-tree-sha1 = "a4d07a1c313392a77042855df46c5f534076fab9"
uuid = "13072b0f-2c55-5437-9ae7-d433b7a33950"
version = "1.0.0"

[[Base64]]
uuid = "2a0f44e3-6c83-55bd-87e4-b1978d98bd5f"

[[Bzip2_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "c3598e525718abcc440f69cc6d5f60dda0a1b61e"
uuid = "6e34b625-4abd-537c-b88f-471c36dfa7a0"
version = "1.0.6+5"

[[Cairo_jll]]
deps = ["Artifacts", "Bzip2_jll", "Fontconfig_jll", "FreeType2_jll", "Glib_jll", "JLLWrappers", "LZO_jll", "Libdl", "Pixman_jll", "Pkg", "Xorg_libXext_jll", "Xorg_libXrender_jll", "Zlib_jll", "libpng_jll"]
git-tree-sha1 = "e2f47f6d8337369411569fd45ae5753ca10394c6"
uuid = "83423d85-b0ee-5818-9007-b63ccbeb887a"
version = "1.16.0+6"

[[ChainRulesCore]]
deps = ["Compat", "LinearAlgebra", "SparseArrays"]
git-tree-sha1 = "30ee06de5ff870b45c78f529a6b093b3323256a3"
uuid = "d360d2e6-b24c-11e9-a2a3-2a2ae2dbcce4"
version = "1.3.1"

[[Clustering]]
deps = ["Distances", "LinearAlgebra", "NearestNeighbors", "Printf", "SparseArrays", "Statistics", "StatsBase"]
git-tree-sha1 = "75479b7df4167267d75294d14b58244695beb2ac"
uuid = "aaaa29a8-35af-508c-8bc3-b662a17a0fe5"
version = "0.14.2"

[[ColorSchemes]]
deps = ["ColorTypes", "Colors", "FixedPointNumbers", "Random"]
git-tree-sha1 = "9995eb3977fbf67b86d0a0a0508e83017ded03f2"
uuid = "35d6a980-a343-548e-a6ea-1d62b119f2f4"
version = "3.14.0"

[[ColorTypes]]
deps = ["FixedPointNumbers", "Random"]
git-tree-sha1 = "024fe24d83e4a5bf5fc80501a314ce0d1aa35597"
uuid = "3da002f7-5984-5a60-b8a6-cbb66c0b333f"
version = "0.11.0"

[[Colors]]
deps = ["ColorTypes", "FixedPointNumbers", "Reexport"]
git-tree-sha1 = "417b0ed7b8b838aa6ca0a87aadf1bb9eb111ce40"
uuid = "5ae59095-9a9b-59fe-a467-6f913c188581"
version = "0.12.8"

[[Compat]]
deps = ["Base64", "Dates", "DelimitedFiles", "Distributed", "InteractiveUtils", "LibGit2", "Libdl", "LinearAlgebra", "Markdown", "Mmap", "Pkg", "Printf", "REPL", "Random", "SHA", "Serialization", "SharedArrays", "Sockets", "SparseArrays", "Statistics", "Test", "UUIDs", "Unicode"]
git-tree-sha1 = "727e463cfebd0c7b999bbf3e9e7e16f254b94193"
uuid = "34da2185-b29b-5c13-b0c7-acf172513d20"
version = "3.34.0"

[[CompilerSupportLibraries_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "8e695f735fca77e9708e795eda62afdb869cbb70"
uuid = "e66e0078-7015-5450-92f7-15fbd957f2ae"
version = "0.3.4+0"

[[Contour]]
deps = ["StaticArrays"]
git-tree-sha1 = "9f02045d934dc030edad45944ea80dbd1f0ebea7"
uuid = "d38c429a-6771-53c6-b99e-75d170b6e991"
version = "0.5.7"

[[DataAPI]]
git-tree-sha1 = "bec2532f8adb82005476c141ec23e921fc20971b"
uuid = "9a962f9c-6df0-11e9-0e5d-c546b8b5ee8a"
version = "1.8.0"

[[DataStructures]]
deps = ["Compat", "InteractiveUtils", "OrderedCollections"]
git-tree-sha1 = "7d9d316f04214f7efdbb6398d545446e246eff02"
uuid = "864edb3b-99cc-5e75-8d2d-829cb0a9cfe8"
version = "0.18.10"

[[DataValueInterfaces]]
git-tree-sha1 = "bfc1187b79289637fa0ef6d4436ebdfe6905cbd6"
uuid = "e2d170a0-9d28-54be-80f0-106bbe20a464"
version = "1.0.0"

[[DataValues]]
deps = ["DataValueInterfaces", "Dates"]
git-tree-sha1 = "d88a19299eba280a6d062e135a43f00323ae70bf"
uuid = "e7dc6d0d-1eca-5fa6-8ad6-5aecde8b7ea5"
version = "0.4.13"

[[Dates]]
deps = ["Printf"]
uuid = "ade2ca70-3891-5945-98fb-dc099432e06a"

[[DelimitedFiles]]
deps = ["Mmap"]
uuid = "8bb1440f-4735-579b-a4ab-409b98df4dab"

[[Distances]]
deps = ["LinearAlgebra", "Statistics", "StatsAPI"]
git-tree-sha1 = "9f46deb4d4ee4494ffb5a40a27a2aced67bdd838"
uuid = "b4f34e82-e78d-54a5-968a-f98e89d6e8f7"
version = "0.10.4"

[[Distributed]]
deps = ["Random", "Serialization", "Sockets"]
uuid = "8ba89e20-285c-5b6f-9357-94700520ee1b"

[[Distributions]]
deps = ["ChainRulesCore", "FillArrays", "LinearAlgebra", "PDMats", "Printf", "QuadGK", "Random", "SparseArrays", "SpecialFunctions", "Statistics", "StatsBase", "StatsFuns"]
git-tree-sha1 = "f4efaa4b5157e0cdb8283ae0b5428bc9208436ed"
uuid = "31c24e10-a181-5473-b8eb-7969acd0382f"
version = "0.25.16"

[[DocStringExtensions]]
deps = ["LibGit2"]
git-tree-sha1 = "a32185f5428d3986f47c2ab78b1f216d5e6cc96f"
uuid = "ffbed154-4ef7-542d-bbb7-c09d3a79fcae"
version = "0.8.5"

[[Downloads]]
deps = ["ArgTools", "LibCURL", "NetworkOptions"]
git-tree-sha1 = "135bf1896be424235eadb17474b2a78331567f08"
uuid = "f43a241f-c20a-4ad4-852c-f6b1247861c6"
version = "1.5.1"

[[EarCut_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "92d8f9f208637e8d2d28c664051a00569c01493d"
uuid = "5ae413db-bbd1-5e63-b57d-d24a61df00f5"
version = "2.1.5+1"

[[Expat_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "1402e52fcda25064f51c77a9655ce8680b76acf0"
uuid = "2e619515-83b5-522b-bb60-26c02a35a201"
version = "2.2.7+6"

[[FFMPEG]]
deps = ["FFMPEG_jll"]
git-tree-sha1 = "b57e3acbe22f8484b4b5ff66a7499717fe1a9cc8"
uuid = "c87230d0-a227-11e9-1b43-d7ebe4e7570a"
version = "0.4.1"

[[FFMPEG_jll]]
deps = ["Artifacts", "Bzip2_jll", "FreeType2_jll", "FriBidi_jll", "JLLWrappers", "LAME_jll", "LibVPX_jll", "Libdl", "Ogg_jll", "OpenSSL_jll", "Opus_jll", "Pkg", "Zlib_jll", "libass_jll", "libfdk_aac_jll", "libvorbis_jll", "x264_jll", "x265_jll"]
git-tree-sha1 = "3cc57ad0a213808473eafef4845a74766242e05f"
uuid = "b22a6f82-2f65-5046-a5b2-351ab43fb4e5"
version = "4.3.1+4"

[[FFTW]]
deps = ["AbstractFFTs", "FFTW_jll", "IntelOpenMP_jll", "Libdl", "LinearAlgebra", "MKL_jll", "Reexport"]
git-tree-sha1 = "1b48dbde42f307e48685fa9213d8b9f8c0d87594"
uuid = "7a1cc6ca-52ef-59f5-83cd-3a7055c09341"
version = "1.3.2"

[[FFTW_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "3676abafff7e4ff07bbd2c42b3d8201f31653dcc"
uuid = "f5851436-0d7a-5f13-b9de-f02708fd171a"
version = "3.3.9+8"

[[FillArrays]]
deps = ["LinearAlgebra", "Random", "SparseArrays", "Statistics"]
git-tree-sha1 = "a3b7b041753094f3b17ffa9d2e2e07d8cace09cd"
uuid = "1a297f60-69ca-5386-bcde-b61e274b549b"
version = "0.12.3"

[[FixedPointNumbers]]
deps = ["Statistics"]
git-tree-sha1 = "335bfdceacc84c5cdf16aadc768aa5ddfc5383cc"
uuid = "53c48c17-4a7d-5ca2-90c5-79b7896eea93"
version = "0.8.4"

[[Fontconfig_jll]]
deps = ["Artifacts", "Bzip2_jll", "Expat_jll", "FreeType2_jll", "JLLWrappers", "Libdl", "Libuuid_jll", "Pkg", "Zlib_jll"]
git-tree-sha1 = "35895cf184ceaab11fd778b4590144034a167a2f"
uuid = "a3f928ae-7b40-5064-980b-68af3947d34b"
version = "2.13.1+14"

[[Formatting]]
deps = ["Printf"]
git-tree-sha1 = "8339d61043228fdd3eb658d86c926cb282ae72a8"
uuid = "59287772-0a20-5a39-b81b-1366585eb4c0"
version = "0.4.2"

[[FreeType2_jll]]
deps = ["Artifacts", "Bzip2_jll", "JLLWrappers", "Libdl", "Pkg", "Zlib_jll"]
git-tree-sha1 = "cbd58c9deb1d304f5a245a0b7eb841a2560cfec6"
uuid = "d7e528f0-a631-5988-bf34-fe36492bcfd7"
version = "2.10.1+5"

[[FriBidi_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "0d20aed5b14dd4c9a2453c1b601d08e1149679cc"
uuid = "559328eb-81f9-559d-9380-de523a88c83c"
version = "1.0.5+6"

[[GLFW_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Libglvnd_jll", "Pkg", "Xorg_libXcursor_jll", "Xorg_libXi_jll", "Xorg_libXinerama_jll", "Xorg_libXrandr_jll"]
git-tree-sha1 = "a199aefead29c3c2638c3571a9993b564109d45a"
uuid = "0656b61e-2033-5cc2-a64a-77c0f6c09b89"
version = "3.3.4+0"

[[GR]]
deps = ["Base64", "DelimitedFiles", "GR_jll", "HTTP", "JSON", "Libdl", "LinearAlgebra", "Pkg", "Printf", "Random", "Serialization", "Sockets", "Test", "UUIDs"]
git-tree-sha1 = "182da592436e287758ded5be6e32c406de3a2e47"
uuid = "28b8d3ca-fb5f-59d9-8090-bfdbd6d07a71"
version = "0.58.1"

[[GR_jll]]
deps = ["Artifacts", "Bzip2_jll", "Cairo_jll", "FFMPEG_jll", "Fontconfig_jll", "GLFW_jll", "JLLWrappers", "JpegTurbo_jll", "Libdl", "Libtiff_jll", "Pixman_jll", "Pkg", "Qt5Base_jll", "Zlib_jll", "libpng_jll"]
git-tree-sha1 = "d59e8320c2747553788e4fc42231489cc602fa50"
uuid = "d2c73de3-f751-5644-a686-071e5b155ba9"
version = "0.58.1+0"

[[GeometryBasics]]
deps = ["EarCut_jll", "IterTools", "LinearAlgebra", "StaticArrays", "StructArrays", "Tables"]
git-tree-sha1 = "58bcdf5ebc057b085e58d95c138725628dd7453c"
uuid = "5c1252a2-5f33-56bf-86c9-59e7332b4326"
version = "0.4.1"

[[Gettext_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Libiconv_jll", "Pkg", "XML2_jll"]
git-tree-sha1 = "8c14294a079216000a0bdca5ec5a447f073ddc9d"
uuid = "78b55507-aeef-58d4-861c-77aaff3498b1"
version = "0.20.1+7"

[[Glib_jll]]
deps = ["Artifacts", "Gettext_jll", "JLLWrappers", "Libdl", "Libffi_jll", "Libiconv_jll", "Libmount_jll", "PCRE_jll", "Pkg", "Zlib_jll"]
git-tree-sha1 = "04690cc5008b38ecbdfede949220bc7d9ba26397"
uuid = "7746bdde-850d-59dc-9ae8-88ece973131d"
version = "2.59.0+4"

[[Grisu]]
git-tree-sha1 = "53bb909d1151e57e2484c3d1b53e19552b887fb2"
uuid = "42e2da0e-8278-4e71-bc24-59509adca0fe"
version = "1.0.2"

[[HTTP]]
deps = ["Base64", "Dates", "IniFile", "Logging", "MbedTLS", "NetworkOptions", "Sockets", "URIs"]
git-tree-sha1 = "60ed5f1643927479f845b0135bb369b031b541fa"
uuid = "cd3eb016-35fb-5094-929b-558a96fad6f3"
version = "0.9.14"

[[IniFile]]
deps = ["Test"]
git-tree-sha1 = "098e4d2c533924c921f9f9847274f2ad89e018b8"
uuid = "83e8ac13-25f8-5344-8a64-a9f2b223428f"
version = "0.5.0"

[[IntelOpenMP_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "d979e54b71da82f3a65b62553da4fc3d18c9004c"
uuid = "1d5cc7b8-4909-519e-a0f8-d0f5ad9712d0"
version = "2018.0.3+2"

[[InteractiveUtils]]
deps = ["Markdown"]
uuid = "b77e0a4c-d291-57a0-90e8-8db25a27a240"

[[Interpolations]]
deps = ["AxisAlgorithms", "ChainRulesCore", "LinearAlgebra", "OffsetArrays", "Random", "Ratios", "Requires", "SharedArrays", "SparseArrays", "StaticArrays", "WoodburyMatrices"]
git-tree-sha1 = "61aa005707ea2cebf47c8d780da8dc9bc4e0c512"
uuid = "a98d9a8b-a2ab-59e6-89dd-64a1c18fca59"
version = "0.13.4"

[[IrrationalConstants]]
git-tree-sha1 = "f76424439413893a832026ca355fe273e93bce94"
uuid = "92d709cd-6900-40b7-9082-c6be49f344b6"
version = "0.1.0"

[[IterTools]]
git-tree-sha1 = "05110a2ab1fc5f932622ffea2a003221f4782c18"
uuid = "c8e1da08-722c-5040-9ed9-7db0dc04731e"
version = "1.3.0"

[[IteratorInterfaceExtensions]]
git-tree-sha1 = "a3f24677c21f5bbe9d2a714f95dcd58337fb2856"
uuid = "82899510-4779-5014-852e-03e436cf321d"
version = "1.0.0"

[[JLLWrappers]]
deps = ["Preferences"]
git-tree-sha1 = "642a199af8b68253517b80bd3bfd17eb4e84df6e"
uuid = "692b3bcd-3c85-4b1f-b108-f13ce0eb3210"
version = "1.3.0"

[[JSON]]
deps = ["Dates", "Mmap", "Parsers", "Unicode"]
git-tree-sha1 = "8076680b162ada2a031f707ac7b4953e30667a37"
uuid = "682c06a0-de6a-54ab-a142-c8b1cf79cde6"
version = "0.21.2"

[[JpegTurbo_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "9aff0587d9603ea0de2c6f6300d9f9492bbefbd3"
uuid = "aacddb02-875f-59d6-b918-886e6ef4fbf8"
version = "2.0.1+3"

[[KernelDensity]]
deps = ["Distributions", "DocStringExtensions", "FFTW", "Interpolations", "StatsBase"]
git-tree-sha1 = "591e8dc09ad18386189610acafb970032c519707"
uuid = "5ab0869b-81aa-558d-bb23-cbf5423bbe9b"
version = "0.6.3"

[[LAME_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "df381151e871f41ee86cee4f5f6fd598b8a68826"
uuid = "c1c5ebd0-6772-5130-a774-d5fcae4a789d"
version = "3.100.0+3"

[[LZO_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "f128cd6cd05ffd6d3df0523ed99b90ff6f9b349a"
uuid = "dd4b983a-f0e5-5f8d-a1b7-129d4a5fb1ac"
version = "2.10.0+3"

[[LaTeXStrings]]
git-tree-sha1 = "c7f1c695e06c01b95a67f0cd1d34994f3e7db104"
uuid = "b964fa9f-0449-5b57-a5c2-d3ea65f4040f"
version = "1.2.1"

[[Latexify]]
deps = ["Formatting", "InteractiveUtils", "LaTeXStrings", "MacroTools", "Markdown", "Printf", "Requires"]
git-tree-sha1 = "a4b12a1bd2ebade87891ab7e36fdbce582301a92"
uuid = "23fbe1c1-3f47-55db-b15f-69d7ec21a316"
version = "0.15.6"

[[LazyArtifacts]]
deps = ["Pkg"]
git-tree-sha1 = "4bb5499a1fc437342ea9ab7e319ede5a457c0968"
uuid = "4af54fe1-eca0-43a8-85a7-787d91b784e3"
version = "1.3.0"

[[LibCURL]]
deps = ["LibCURL_jll", "MozillaCACerts_jll"]
git-tree-sha1 = "cdbe7465ab7b52358804713a53c7fe1dac3f8a3f"
uuid = "b27032c2-a3e7-50c8-80cd-2d36dbcbfd21"
version = "0.6.3"

[[LibCURL_jll]]
deps = ["LibSSH2_jll", "Libdl", "MbedTLS_jll", "Pkg", "Zlib_jll", "nghttp2_jll"]
git-tree-sha1 = "897d962c20031e6012bba7b3dcb7a667170dad17"
uuid = "deac9b47-8bc7-5906-a0fe-35ac56dc84c0"
version = "7.70.0+2"

[[LibGit2]]
deps = ["Printf"]
uuid = "76f85450-5226-5b5a-8eaa-529ad045b433"

[[LibSSH2_jll]]
deps = ["Libdl", "MbedTLS_jll", "Pkg"]
git-tree-sha1 = "717705533148132e5466f2924b9a3657b16158e8"
uuid = "29816b5a-b9ab-546f-933c-edad1886dfa8"
version = "1.9.0+3"

[[LibVPX_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "85fcc80c3052be96619affa2fe2e6d2da3908e11"
uuid = "dd192d2f-8180-539f-9fb4-cc70b1dcf69a"
version = "1.9.0+1"

[[Libdl]]
uuid = "8f399da3-3557-5675-b5ff-fb832c97cbdb"

[[Libffi_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "a2cd088a88c0d37eef7d209fd3d8712febce0d90"
uuid = "e9f186c6-92d2-5b65-8a66-fee21dc1b490"
version = "3.2.1+4"

[[Libgcrypt_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Libgpg_error_jll", "Pkg"]
git-tree-sha1 = "b391a18ab1170a2e568f9fb8d83bc7c780cb9999"
uuid = "d4300ac3-e22c-5743-9152-c294e39db1e4"
version = "1.8.5+4"

[[Libglvnd_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg", "Xorg_libX11_jll", "Xorg_libXext_jll"]
git-tree-sha1 = "7739f837d6447403596a75d19ed01fd08d6f56bf"
uuid = "7e76a0d4-f3c7-5321-8279-8d96eeed0f29"
version = "1.3.0+3"

[[Libgpg_error_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "ec7f2e8ad5c9fa99fc773376cdbc86d9a5a23cb7"
uuid = "7add5ba3-2f88-524e-9cd5-f83b8a55f7b8"
version = "1.36.0+3"

[[Libiconv_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "cba7b560fcc00f8cd770fa85a498cbc1d63ff618"
uuid = "94ce4f54-9a6c-5748-9c1c-f9c7231a4531"
version = "1.16.0+8"

[[Libmount_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "51ad0c01c94c1ce48d5cad629425035ad030bfd5"
uuid = "4b2f31a3-9ecc-558c-b454-b3730dcb73e9"
version = "2.34.0+3"

[[Libtiff_jll]]
deps = ["Artifacts", "JLLWrappers", "JpegTurbo_jll", "Libdl", "Pkg", "Zlib_jll", "Zstd_jll"]
git-tree-sha1 = "291dd857901f94d683973cdf679984cdf73b56d0"
uuid = "89763e89-9b03-5906-acba-b20f662cd828"
version = "4.1.0+2"

[[Libuuid_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "f879ae9edbaa2c74c922e8b85bb83cc84ea1450b"
uuid = "38a345b3-de98-5d2b-a5d3-14cd9215e700"
version = "2.34.0+7"

[[LinearAlgebra]]
deps = ["Libdl"]
uuid = "37e2e46d-f89d-539d-b4ee-838fcccc9c8e"

[[LogExpFunctions]]
deps = ["ChainRulesCore", "DocStringExtensions", "IrrationalConstants", "LinearAlgebra"]
git-tree-sha1 = "1f5097e3bce576e1cdf6dc9f051ab8c6e196b29e"
uuid = "2ab3a3ac-af41-5b50-aa03-7779005ae688"
version = "0.3.1"

[[Logging]]
uuid = "56ddb016-857b-54e1-b83d-db4d58db5568"

[[MKL_jll]]
deps = ["Artifacts", "IntelOpenMP_jll", "JLLWrappers", "LazyArtifacts", "Libdl", "Pkg"]
git-tree-sha1 = "c253236b0ed414624b083e6b72bfe891fbd2c7af"
uuid = "856f044c-d86e-5d09-b602-aeab76dc8ba7"
version = "2021.1.1+1"

[[MacroTools]]
deps = ["Markdown", "Random"]
git-tree-sha1 = "0fb723cd8c45858c22169b2e42269e53271a6df7"
uuid = "1914dd2f-81c6-5fcd-8719-6d5c9610ff09"
version = "0.5.7"

[[Markdown]]
deps = ["Base64"]
uuid = "d6f4376e-aef5-505a-96c1-9c027394607a"

[[MbedTLS]]
deps = ["Dates", "MbedTLS_jll", "Random", "Sockets"]
git-tree-sha1 = "1c38e51c3d08ef2278062ebceade0e46cefc96fe"
uuid = "739be429-bea8-5141-9913-cc70e7f3736d"
version = "1.0.3"

[[MbedTLS_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "0eef589dd1c26a3ac9d753fe1a8bcad63f956fa6"
uuid = "c8ffd9c3-330d-5841-b78e-0817d7145fa1"
version = "2.16.8+1"

[[Measures]]
git-tree-sha1 = "e498ddeee6f9fdb4551ce855a46f54dbd900245f"
uuid = "442fdcdd-2543-5da2-b0f3-8c86c306513e"
version = "0.3.1"

[[Missings]]
deps = ["DataAPI"]
git-tree-sha1 = "2ca267b08821e86c5ef4376cffed98a46c2cb205"
uuid = "e1d29d7a-bbdc-5cf2-9ac0-f12de2c33e28"
version = "1.0.1"

[[Mmap]]
uuid = "a63ad114-7e13-5084-954f-fe012c677804"

[[MozillaCACerts_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "f1662575f7bf53c73c2bbc763bace4b024de822c"
uuid = "14a3606d-f60d-562e-9121-12d972cd8159"
version = "2021.1.19+0"

[[MultivariateStats]]
deps = ["Arpack", "LinearAlgebra", "SparseArrays", "Statistics", "StatsBase"]
git-tree-sha1 = "8d958ff1854b166003238fe191ec34b9d592860a"
uuid = "6f286f6a-111f-5878-ab1e-185364afe411"
version = "0.8.0"

[[NaNMath]]
git-tree-sha1 = "bfe47e760d60b82b66b61d2d44128b62e3a369fb"
uuid = "77ba4419-2d1f-58cd-9bb1-8ffee604a2e3"
version = "0.3.5"

[[NearestNeighbors]]
deps = ["Distances", "StaticArrays"]
git-tree-sha1 = "16baacfdc8758bc374882566c9187e785e85c2f0"
uuid = "b8a86587-4115-5ab1-83bc-aa920d37bbce"
version = "0.4.9"

[[NetworkOptions]]
git-tree-sha1 = "ed3157f48a05543cce9b241e1f2815f7e843d96e"
uuid = "ca575930-c2e3-43a9-ace4-1e988b2c1908"
version = "1.2.0"

[[Observables]]
git-tree-sha1 = "fe29afdef3d0c4a8286128d4e45cc50621b1e43d"
uuid = "510215fc-4207-5dde-b226-833fc4488ee2"
version = "0.4.0"

[[OffsetArrays]]
deps = ["Adapt"]
git-tree-sha1 = "c870a0d713b51e4b49be6432eff0e26a4325afee"
uuid = "6fe1bfb0-de20-5000-8ca7-80f57d26f881"
version = "1.10.6"

[[Ogg_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "a42c0f138b9ebe8b58eba2271c5053773bde52d0"
uuid = "e7412a2a-1a6e-54c0-be00-318e2571c051"
version = "1.3.4+2"

[[OpenBLAS_jll]]
deps = ["CompilerSupportLibraries_jll", "Libdl", "Pkg"]
git-tree-sha1 = "0c922fd9634e358622e333fc58de61f05a048492"
uuid = "4536629a-c528-5b80-bd46-f80d51c5b363"
version = "0.3.9+5"

[[OpenSSL_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "71bbbc616a1d710879f5a1021bcba65ffba6ce58"
uuid = "458c3c95-2e84-50aa-8efc-19380b2a3a95"
version = "1.1.1+6"

[[OpenSpecFun_jll]]
deps = ["Artifacts", "CompilerSupportLibraries_jll", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "9db77584158d0ab52307f8c04f8e7c08ca76b5b3"
uuid = "efe28fd5-8261-553b-a9e1-b2916fc3738e"
version = "0.5.3+4"

[[Opus_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "f9d57f4126c39565e05a2b0264df99f497fc6f37"
uuid = "91d4177d-7536-5919-b921-800302f37372"
version = "1.3.1+3"

[[OrderedCollections]]
git-tree-sha1 = "85f8e6578bf1f9ee0d11e7bb1b1456435479d47c"
uuid = "bac558e1-5e72-5ebc-8fee-abe8a469f55d"
version = "1.4.1"

[[PCRE_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "1b556ad51dceefdbf30e86ffa8f528b73c7df2bb"
uuid = "2f80f16e-611a-54ab-bc61-aa92de5b98fc"
version = "8.42.0+4"

[[PDMats]]
deps = ["LinearAlgebra", "SparseArrays", "SuiteSparse"]
git-tree-sha1 = "4dd403333bcf0909341cfe57ec115152f937d7d8"
uuid = "90014a1f-27ba-587c-ab20-58faa44d9150"
version = "0.11.1"

[[Parsers]]
deps = ["Dates"]
git-tree-sha1 = "438d35d2d95ae2c5e8780b330592b6de8494e779"
uuid = "69de0a69-1ddd-5017-9359-2bf0b02dc9f0"
version = "2.0.3"

[[Pixman_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "6a20a83c1ae86416f0a5de605eaea08a552844a3"
uuid = "30392449-352a-5448-841d-b1acce4e97dc"
version = "0.40.0+0"

[[Pkg]]
deps = ["Dates", "LibGit2", "Libdl", "Logging", "Markdown", "Printf", "REPL", "Random", "SHA", "UUIDs"]
uuid = "44cfe95a-1eb2-52ea-b672-e2afdf69b78f"

[[PlotThemes]]
deps = ["PlotUtils", "Requires", "Statistics"]
git-tree-sha1 = "a3a964ce9dc7898193536002a6dd892b1b5a6f1d"
uuid = "ccf2f8ad-2431-5c83-bf29-c5338b663b6a"
version = "2.0.1"

[[PlotUtils]]
deps = ["ColorSchemes", "Colors", "Dates", "Printf", "Random", "Reexport", "Statistics"]
git-tree-sha1 = "9ff1c70190c1c30aebca35dc489f7411b256cd23"
uuid = "995b91a9-d308-5afd-9ec6-746e21dbc043"
version = "1.0.13"

[[Plots]]
deps = ["Base64", "Contour", "Dates", "Downloads", "FFMPEG", "FixedPointNumbers", "GR", "GeometryBasics", "JSON", "Latexify", "LinearAlgebra", "Measures", "NaNMath", "PlotThemes", "PlotUtils", "Printf", "REPL", "Random", "RecipesBase", "RecipesPipeline", "Reexport", "Requires", "Scratch", "Showoff", "SparseArrays", "Statistics", "StatsBase", "UUIDs"]
git-tree-sha1 = "2dbafeadadcf7dadff20cd60046bba416b4912be"
uuid = "91a5bcdd-55d7-5caf-9e0b-520d859cae80"
version = "1.21.3"

[[Preferences]]
deps = ["TOML"]
git-tree-sha1 = "00cfd92944ca9c760982747e9a1d0d5d86ab1e5a"
uuid = "21216c6a-2e73-6563-6e65-726566657250"
version = "1.2.2"

[[Printf]]
deps = ["Unicode"]
uuid = "de0858da-6303-5e67-8744-51eddeeeb8d7"

[[Qt5Base_jll]]
deps = ["Artifacts", "CompilerSupportLibraries_jll", "Fontconfig_jll", "Glib_jll", "JLLWrappers", "Libdl", "Libglvnd_jll", "OpenSSL_jll", "Pkg", "Xorg_libXext_jll", "Xorg_libxcb_jll", "Xorg_xcb_util_image_jll", "Xorg_xcb_util_keysyms_jll", "Xorg_xcb_util_renderutil_jll", "Xorg_xcb_util_wm_jll", "Zlib_jll", "xkbcommon_jll"]
git-tree-sha1 = "16626cfabbf7206d60d84f2bf4725af7b37d4a77"
uuid = "ea2cea3b-5b76-57ae-a6ef-0a8af62496e1"
version = "5.15.2+0"

[[QuadGK]]
deps = ["DataStructures", "LinearAlgebra"]
git-tree-sha1 = "12fbe86da16df6679be7521dfb39fbc861e1dc7b"
uuid = "1fd47b50-473d-5c70-9696-f719f8f3bcdc"
version = "2.4.1"

[[REPL]]
deps = ["InteractiveUtils", "Markdown", "Sockets"]
uuid = "3fa0cd96-eef1-5676-8a61-b3b8758bbffb"

[[Random]]
deps = ["Serialization"]
uuid = "9a3f8284-a2c9-5f02-9a11-845980a1fd5c"

[[Ratios]]
deps = ["Requires"]
git-tree-sha1 = "7dff99fbc740e2f8228c6878e2aad6d7c2678098"
uuid = "c84ed2f1-dad5-54f0-aa8e-dbefe2724439"
version = "0.4.1"

[[RecipesBase]]
git-tree-sha1 = "44a75aa7a527910ee3d1751d1f0e4148698add9e"
uuid = "3cdcf5f2-1ef4-517c-9805-6587b60abb01"
version = "1.1.2"

[[RecipesPipeline]]
deps = ["Dates", "NaNMath", "PlotUtils", "RecipesBase"]
git-tree-sha1 = "1f27772b89958deed68d2709e5f08a5e5f59a5af"
uuid = "01d81517-befc-4cb6-b9ec-a95719d0359c"
version = "0.3.7"

[[Reexport]]
git-tree-sha1 = "45e428421666073eab6f2da5c9d310d99bb12f9b"
uuid = "189a3867-3050-52da-a836-e630ba90ab69"
version = "1.2.2"

[[Requires]]
deps = ["UUIDs"]
git-tree-sha1 = "4036a3bd08ac7e968e27c203d45f5fff15020621"
uuid = "ae029012-a4dd-5104-9daa-d747884805df"
version = "1.1.3"

[[Rmath]]
deps = ["Random", "Rmath_jll"]
git-tree-sha1 = "86c5647b565873641538d8f812c04e4c9dbeb370"
uuid = "79098fc4-a85e-5d69-aa6a-4863f24498fa"
version = "0.6.1"

[[Rmath_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "1b7bf41258f6c5c9c31df8c1ba34c1fc88674957"
uuid = "f50d1b31-88e8-58de-be2c-1cc44531875f"
version = "0.2.2+2"

[[SHA]]
uuid = "ea8e919c-243c-51af-8825-aaa63cd721ce"

[[Scratch]]
deps = ["Dates"]
git-tree-sha1 = "0b4b7f1393cff97c33891da2a0bf69c6ed241fda"
uuid = "6c6a2e73-6563-6170-7368-637461726353"
version = "1.1.0"

[[SentinelArrays]]
deps = ["Dates", "Random"]
git-tree-sha1 = "54f37736d8934a12a200edea2f9206b03bdf3159"
uuid = "91c51154-3ec4-41a3-a24f-3f23e20d615c"
version = "1.3.7"

[[Serialization]]
uuid = "9e88b42a-f829-5b0c-bbe9-9e923198166b"

[[SharedArrays]]
deps = ["Distributed", "Mmap", "Random", "Serialization"]
uuid = "1a1011a3-84de-559e-8e89-a11a2f7dc383"

[[Showoff]]
deps = ["Dates", "Grisu"]
git-tree-sha1 = "91eddf657aca81df9ae6ceb20b959ae5653ad1de"
uuid = "992d4aef-0814-514b-bc4d-f2e9a6c4116f"
version = "1.0.3"

[[Sockets]]
uuid = "6462fe0b-24de-5631-8697-dd941f90decc"

[[SortingAlgorithms]]
deps = ["DataStructures"]
git-tree-sha1 = "b3363d7460f7d098ca0912c69b082f75625d7508"
uuid = "a2af1166-a08f-5f64-846c-94a0d3cef48c"
version = "1.0.1"

[[SparseArrays]]
deps = ["LinearAlgebra", "Random"]
uuid = "2f01184e-e22b-5df5-ae63-d93ebab69eaf"

[[SpecialFunctions]]
deps = ["ChainRulesCore", "LogExpFunctions", "OpenSpecFun_jll"]
git-tree-sha1 = "a322a9493e49c5f3a10b50df3aedaf1cdb3244b7"
uuid = "276daf66-3868-5448-9aa4-cd146d93841b"
version = "1.6.1"

[[StaticArrays]]
deps = ["LinearAlgebra", "Random", "Statistics"]
git-tree-sha1 = "3240808c6d463ac46f1c1cd7638375cd22abbccb"
uuid = "90137ffa-7385-5640-81b9-e52037218182"
version = "1.2.12"

[[Statistics]]
deps = ["LinearAlgebra", "SparseArrays"]
uuid = "10745b16-79ce-11e8-11f9-7d13ad32a3b2"

[[StatsAPI]]
git-tree-sha1 = "1958272568dc176a1d881acb797beb909c785510"
uuid = "82ae8749-77ed-4fe6-ae5f-f523153014b0"
version = "1.0.0"

[[StatsBase]]
deps = ["DataAPI", "DataStructures", "LinearAlgebra", "Missings", "Printf", "Random", "SortingAlgorithms", "SparseArrays", "Statistics", "StatsAPI"]
git-tree-sha1 = "8cbbc098554648c84f79a463c9ff0fd277144b6c"
uuid = "2913bbd2-ae8a-5f71-8c99-4fb6c76f3a91"
version = "0.33.10"

[[StatsFuns]]
deps = ["ChainRulesCore", "IrrationalConstants", "LogExpFunctions", "Reexport", "Rmath", "SpecialFunctions"]
git-tree-sha1 = "46d7ccc7104860c38b11966dd1f72ff042f382e4"
uuid = "4c63d2b9-4356-54db-8cca-17b64c39e42c"
version = "0.9.10"

[[StatsPlots]]
deps = ["Clustering", "DataStructures", "DataValues", "Distributions", "Interpolations", "KernelDensity", "LinearAlgebra", "MultivariateStats", "Observables", "Plots", "RecipesBase", "RecipesPipeline", "Reexport", "StatsBase", "TableOperations", "Tables", "Widgets"]
git-tree-sha1 = "e7d1e79232310bd654c7cef46465c537562af4fe"
uuid = "f3b207a7-027a-5e70-b257-86293d7955fd"
version = "0.14.26"

[[StructArrays]]
deps = ["Adapt", "DataAPI", "StaticArrays", "Tables"]
git-tree-sha1 = "1700b86ad59348c0f9f68ddc95117071f947072d"
uuid = "09ab397b-f2b6-538f-b94a-2f83cf4a842a"
version = "0.6.1"

[[SuiteSparse]]
deps = ["Libdl", "LinearAlgebra", "Serialization", "SparseArrays"]
uuid = "4607b0f0-06f3-5cda-b6b1-a6196a1729e9"

[[TOML]]
deps = ["Dates"]
git-tree-sha1 = "44aaac2d2aec4a850302f9aa69127c74f0c3787e"
uuid = "fa267f1f-6049-4f14-aa54-33bafae1ed76"
version = "1.0.3"

[[TableOperations]]
deps = ["SentinelArrays", "Tables", "Test"]
git-tree-sha1 = "019acfd5a4a6c5f0f38de69f2ff7ed527f1881da"
uuid = "ab02a1b2-a7df-11e8-156e-fb1833f50b87"
version = "1.1.0"

[[TableTraits]]
deps = ["IteratorInterfaceExtensions"]
git-tree-sha1 = "c06b2f539df1c6efa794486abfb6ed2022561a39"
uuid = "3783bdb8-4a98-5b6b-af9a-565f29a5fe9c"
version = "1.0.1"

[[Tables]]
deps = ["DataAPI", "DataValueInterfaces", "IteratorInterfaceExtensions", "LinearAlgebra", "TableTraits", "Test"]
git-tree-sha1 = "d0c690d37c73aeb5ca063056283fde5585a41710"
uuid = "bd369af6-aec1-5ad0-b16a-f7cc5008161c"
version = "1.5.0"

[[Test]]
deps = ["Distributed", "InteractiveUtils", "Logging", "Random"]
uuid = "8dfed614-e22c-5e08-85e1-65c5234f0b40"

[[URIs]]
git-tree-sha1 = "97bbe755a53fe859669cd907f2d96aee8d2c1355"
uuid = "5c2747f8-b7ea-4ff2-ba2e-563bfd36b1d4"
version = "1.3.0"

[[UUIDs]]
deps = ["Random", "SHA"]
uuid = "cf7118a7-6976-5b1a-9a39-7adc72f591a4"

[[Unicode]]
uuid = "4ec0a83e-493e-50e2-b9ac-8f72acf5a8f5"

[[Wayland_jll]]
deps = ["Artifacts", "Expat_jll", "JLLWrappers", "Libdl", "Libffi_jll", "Pkg", "XML2_jll"]
git-tree-sha1 = "dc643a9b774da1c2781413fd7b6dcd2c56bb8056"
uuid = "a2964d1f-97da-50d4-b82a-358c7fce9d89"
version = "1.17.0+4"

[[Wayland_protocols_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg", "Wayland_jll"]
git-tree-sha1 = "2839f1c1296940218e35df0bbb220f2a79686670"
uuid = "2381bf8a-dfd0-557d-9999-79630e7b1b91"
version = "1.18.0+4"

[[Widgets]]
deps = ["Colors", "Dates", "Observables", "OrderedCollections"]
git-tree-sha1 = "eae2fbbc34a79ffd57fb4c972b08ce50b8f6a00d"
uuid = "cc8bc4a8-27d6-5769-a93b-9d913e69aa62"
version = "0.6.3"

[[WoodburyMatrices]]
deps = ["LinearAlgebra", "SparseArrays"]
git-tree-sha1 = "59e2ad8fd1591ea019a5259bd012d7aee15f995c"
uuid = "efce3f68-66dc-5838-9240-27a6d6f5f9b6"
version = "0.5.3"

[[XML2_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Libiconv_jll", "Pkg", "Zlib_jll"]
git-tree-sha1 = "be0db24f70aae7e2b89f2f3092e93b8606d659a6"
uuid = "02c8fc9c-b97f-50b9-bbe4-9be30ff0a78a"
version = "2.9.10+3"

[[XSLT_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Libgcrypt_jll", "Libgpg_error_jll", "Pkg", "XML2_jll"]
git-tree-sha1 = "2b3eac39df218762d2d005702d601cd44c997497"
uuid = "aed1982a-8fda-507f-9586-7b0439959a61"
version = "1.1.33+4"

[[Xorg_libX11_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg", "Xorg_libxcb_jll", "Xorg_xtrans_jll"]
git-tree-sha1 = "5be649d550f3f4b95308bf0183b82e2582876527"
uuid = "4f6342f7-b3d2-589e-9d20-edeb45f2b2bc"
version = "1.6.9+4"

[[Xorg_libXau_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "4e490d5c960c314f33885790ed410ff3a94ce67e"
uuid = "0c0b7dd1-d40b-584c-a123-a41640f87eec"
version = "1.0.9+4"

[[Xorg_libXcursor_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg", "Xorg_libXfixes_jll", "Xorg_libXrender_jll"]
git-tree-sha1 = "12e0eb3bc634fa2080c1c37fccf56f7c22989afd"
uuid = "935fb764-8cf2-53bf-bb30-45bb1f8bf724"
version = "1.2.0+4"

[[Xorg_libXdmcp_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "4fe47bd2247248125c428978740e18a681372dd4"
uuid = "a3789734-cfe1-5b06-b2d0-1dd0d9d62d05"
version = "1.1.3+4"

[[Xorg_libXext_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg", "Xorg_libX11_jll"]
git-tree-sha1 = "b7c0aa8c376b31e4852b360222848637f481f8c3"
uuid = "1082639a-0dae-5f34-9b06-72781eeb8cb3"
version = "1.3.4+4"

[[Xorg_libXfixes_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg", "Xorg_libX11_jll"]
git-tree-sha1 = "0e0dc7431e7a0587559f9294aeec269471c991a4"
uuid = "d091e8ba-531a-589c-9de9-94069b037ed8"
version = "5.0.3+4"

[[Xorg_libXi_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg", "Xorg_libXext_jll", "Xorg_libXfixes_jll"]
git-tree-sha1 = "89b52bc2160aadc84d707093930ef0bffa641246"
uuid = "a51aa0fd-4e3c-5386-b890-e753decda492"
version = "1.7.10+4"

[[Xorg_libXinerama_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg", "Xorg_libXext_jll"]
git-tree-sha1 = "26be8b1c342929259317d8b9f7b53bf2bb73b123"
uuid = "d1454406-59df-5ea1-beac-c340f2130bc3"
version = "1.1.4+4"

[[Xorg_libXrandr_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg", "Xorg_libXext_jll", "Xorg_libXrender_jll"]
git-tree-sha1 = "34cea83cb726fb58f325887bf0612c6b3fb17631"
uuid = "ec84b674-ba8e-5d96-8ba1-2a689ba10484"
version = "1.5.2+4"

[[Xorg_libXrender_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg", "Xorg_libX11_jll"]
git-tree-sha1 = "19560f30fd49f4d4efbe7002a1037f8c43d43b96"
uuid = "ea2f1a96-1ddc-540d-b46f-429655e07cfa"
version = "0.9.10+4"

[[Xorg_libpthread_stubs_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "6783737e45d3c59a4a4c4091f5f88cdcf0908cbb"
uuid = "14d82f49-176c-5ed1-bb49-ad3f5cbd8c74"
version = "0.1.0+3"

[[Xorg_libxcb_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg", "XSLT_jll", "Xorg_libXau_jll", "Xorg_libXdmcp_jll", "Xorg_libpthread_stubs_jll"]
git-tree-sha1 = "daf17f441228e7a3833846cd048892861cff16d6"
uuid = "c7cfdc94-dc32-55de-ac96-5a1b8d977c5b"
version = "1.13.0+3"

[[Xorg_libxkbfile_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg", "Xorg_libX11_jll"]
git-tree-sha1 = "926af861744212db0eb001d9e40b5d16292080b2"
uuid = "cc61e674-0454-545c-8b26-ed2c68acab7a"
version = "1.1.0+4"

[[Xorg_xcb_util_image_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg", "Xorg_xcb_util_jll"]
git-tree-sha1 = "0fab0a40349ba1cba2c1da699243396ff8e94b97"
uuid = "12413925-8142-5f55-bb0e-6d7ca50bb09b"
version = "0.4.0+1"

[[Xorg_xcb_util_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg", "Xorg_libxcb_jll"]
git-tree-sha1 = "e7fd7b2881fa2eaa72717420894d3938177862d1"
uuid = "2def613f-5ad1-5310-b15b-b15d46f528f5"
version = "0.4.0+1"

[[Xorg_xcb_util_keysyms_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg", "Xorg_xcb_util_jll"]
git-tree-sha1 = "d1151e2c45a544f32441a567d1690e701ec89b00"
uuid = "975044d2-76e6-5fbe-bf08-97ce7c6574c7"
version = "0.4.0+1"

[[Xorg_xcb_util_renderutil_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg", "Xorg_xcb_util_jll"]
git-tree-sha1 = "dfd7a8f38d4613b6a575253b3174dd991ca6183e"
uuid = "0d47668e-0667-5a69-a72c-f761630bfb7e"
version = "0.3.9+1"

[[Xorg_xcb_util_wm_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg", "Xorg_xcb_util_jll"]
git-tree-sha1 = "e78d10aab01a4a154142c5006ed44fd9e8e31b67"
uuid = "c22f9ab0-d5fe-5066-847c-f4bb1cd4e361"
version = "0.4.1+1"

[[Xorg_xkbcomp_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg", "Xorg_libxkbfile_jll"]
git-tree-sha1 = "4bcbf660f6c2e714f87e960a171b119d06ee163b"
uuid = "35661453-b289-5fab-8a00-3d9160c6a3a4"
version = "1.4.2+4"

[[Xorg_xkeyboard_config_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg", "Xorg_xkbcomp_jll"]
git-tree-sha1 = "5c8424f8a67c3f2209646d4425f3d415fee5931d"
uuid = "33bec58e-1273-512f-9401-5d533626f822"
version = "2.27.0+4"

[[Xorg_xtrans_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "79c31e7844f6ecf779705fbc12146eb190b7d845"
uuid = "c5fb5394-a638-5e4d-96e5-b29de1b5cf10"
version = "1.4.0+3"

[[Zlib_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "320228915c8debb12cb434c59057290f0834dbf6"
uuid = "83775a58-1f1d-513f-b197-d71354ab007a"
version = "1.2.11+18"

[[Zstd_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "2c1332c54931e83f8f94d310fa447fd743e8d600"
uuid = "3161d3a3-bdf6-5164-811a-617609db77b4"
version = "1.4.8+0"

[[libass_jll]]
deps = ["Artifacts", "Bzip2_jll", "FreeType2_jll", "FriBidi_jll", "JLLWrappers", "Libdl", "Pkg", "Zlib_jll"]
git-tree-sha1 = "acc685bcf777b2202a904cdcb49ad34c2fa1880c"
uuid = "0ac62f75-1d6f-5e53-bd7c-93b484bb37c0"
version = "0.14.0+4"

[[libfdk_aac_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "7a5780a0d9c6864184b3a2eeeb833a0c871f00ab"
uuid = "f638f0a6-7fb0-5443-88ba-1cc74229b280"
version = "0.1.6+4"

[[libpng_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg", "Zlib_jll"]
git-tree-sha1 = "6abbc424248097d69c0c87ba50fcb0753f93e0ee"
uuid = "b53b4c65-9356-5827-b1ea-8c7a1a84506f"
version = "1.6.37+6"

[[libvorbis_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Ogg_jll", "Pkg"]
git-tree-sha1 = "fa14ac25af7a4b8a7f61b287a124df7aab601bcd"
uuid = "f27f6e37-5d2b-51aa-960f-b287f2bc3b7a"
version = "1.3.6+6"

[[nghttp2_jll]]
deps = ["Libdl", "Pkg"]
git-tree-sha1 = "8e2c44ab4d49ad9518f359ed8b62f83ba8beede4"
uuid = "8e850ede-7688-5339-a07c-302acd2aaf8d"
version = "1.40.0+2"

[[x264_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "d713c1ce4deac133e3334ee12f4adff07f81778f"
uuid = "1270edf5-f2f9-52d2-97e9-ab00b5d0237a"
version = "2020.7.14+2"

[[x265_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "487da2f8f2f0c8ee0e83f39d13037d6bbf0a45ab"
uuid = "dfaa095f-4041-5dcd-9319-2fabd8486b76"
version = "3.0.0+3"

[[xkbcommon_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg", "Wayland_jll", "Wayland_protocols_jll", "Xorg_libxcb_jll", "Xorg_xkeyboard_config_jll"]
git-tree-sha1 = "ece2350174195bb31de1a63bea3a41ae1aa593b6"
uuid = "d8fb68d0-12a3-5cfd-a85a-d49703b185fd"
version = "0.9.1+5"
"""

# ╔═╡ Cell order:
# ╟─9f0fff31-d180-499b-b8a4-27d09f9311c2
# ╟─650f5346-ec62-11ea-3007-bded07c572b4
# ╠═8e3917d6-ec62-11ea-0c16-7d2749432dd1
# ╟─02c1eefc-ec63-11ea-35cc-83d7cffdc592
# ╟─76d56f00-5217-4906-9361-7188ee65968b
# ╠═5b3db6f3-38be-4be2-9b66-b4ddd6c049bb
# ╠═7f8e306c-fd69-43b7-8142-b7d6feb6c0ea
# ╠═e3ea183c-4fb4-4b59-aaa6-de60e9ab8e2d
# ╠═23a8e574-1da5-48c9-afbf-888a8b1d8b2b
# ╟─b813bcb4-b055-4b9f-b9d7-82464a67b934
# ╠═7aab6b96-ec63-11ea-3bfb-3352ff34b218
# ╠═7efb1dd5-0c53-4896-b91a-1e7d85941f66
# ╠═80435a32-ec63-11ea-18b3-61d3d41b396d
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
# ╠═4f21ca29-9419-4854-9d83-1bf4974c6fbe
# ╟─ac923b84-ec64-11ea-31cd-278bce8566f7
# ╠═df947306-c97d-4cb9-a55b-90df78e48362
# ╠═ac7a0e38-ec64-11ea-3b16-e50c3ea51b7e
# ╟─ac629280-ec64-11ea-2f69-45e26a6cde89
# ╠═2409b193-bf0f-421f-bad0-815bfcf399cc
# ╠═0139c2d8-63fa-474e-8e9f-cf6093a266a4
# ╠═11e03115-3076-4480-a4fb-5165a1d880f6
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
# ╠═79faeac0-ec66-11ea-1d6d-318ab749e232
# ╟─00000000-0000-0000-0000-000000000001
# ╟─00000000-0000-0000-0000-000000000002
