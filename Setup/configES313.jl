#!/usr/bin/env julia

using Pkg
Pkg.update()

# General
Pkg.add("Logging")
Pkg.add("Dates")
Pkg.add("Statistics")
Pkg.add("Distributions")
Pkg.add("HypothesisTests")
Pkg.add("CSV")
Pkg.add("JLD2")

# Plots
Pkg.add("Plots")
Pkg.add("StatsPlots")
Pkg.add("LaTeXStrings")
Pkg.add("Measures")
Pkg.add(PackageSpec(url="https://github.com/BenLauwens/NativeSVG.jl.git"))

# Optimisation
Pkg.add("JuMP")
Pkg.add("GLPK")
Pkg.add("Tulip")
Pkg.add("Optim")

if VERSION < VersionNumber(1,3)
    # For version 1.2
    Pkg.add(PackageSpec(url="https://github.com/oxfordcontrol/GeneralQP.jl"))
else
    # For latest versions
    Pkg.add(PackageSpec(url="https://github.com/B4rtDC/GeneralQP.jl"))
end
#Pkg.add("NLopt") # not CDN compatible (CMake fails to build)
Pkg.add("Ipopt")

# Discrete event simulation
Pkg.add("ResumableFunctions")
Pkg.add("SimJulia")

# Notebooks
Pkg.add("Pluto")
Pkg.add("PlutoUI")

# Performance
Pkg.add("BenchmarkTools")