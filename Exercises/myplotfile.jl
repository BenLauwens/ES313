# myplotfile.jl
using Plots, Distributions
	
μ₁ = 10; μ₂ = 20; μ = [μ₁, μ₂]  # mean matrix
Σ = [1.0 0;0 3];                # covariance matrix (i.e. no correlation between the variables)
d = Distributions.MvNormal(μ,Σ) # multivariate normal distribution

# make a grid
ns = 3
nx = 21
ny = 31
X = range(μ₁ - ns*Σ[1,1], stop=μ₁ + ns*Σ[1,1],length=nx);
Y = range(μ₂ - ns*Σ[2,2], stop=μ₂ + ns*Σ[2,2],length=ny);

Z = permutedims(collect(Iterators.product(X,Y)))
Z = map(x->pdf(d,collect(x)), Z)

# common plot setting
plotsettings =  Dict(:xlims=>(0,20), :ylims=>(10,30), 
                 :xlabel=>"x", :ylabel=>"y")

p = plot(surface(X,Y,Z, color=:blues, title="surface plot"),
         surface(X,Y,Z, color=:blues_r, title="surface plot\n(reversed colors)"),
         contourf(X,Y,Z, title="contour plot"),
         heatmap(X,Y,Z, title="heatmap"), 
         layout=(2,2), size=(1200,1200); plotsettings...)

for extension in ["png","pdf"]
    savefig(p, "./img/myplot.$(extension)")
end