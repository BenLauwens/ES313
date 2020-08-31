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
Pkg.add("JLD")
Pkg.add("JLD2")
# Plots
Pkg.add("Plots")
Pkg.add("StatsPlots")
Pkg.add("LaTeXStrings")
Pkg.add("Measures")
Pkg.add(PackageSpec(url="https://github.com/BenLauwens/NativeSVG.jl"))
# Optimisation
Pkg.add("JuMP")
Pkg.add("GLPK")
Pkg.add("Optim")
Pkg.add(PackageSpec(url="https://github.com/oxfordcontrol/GeneralQP.jl"))
Pkg.add("NLopt")
Pkg.add("Ipopt")
# Discrete event simulation
Pkg.add("ResumableFunctions")
Pkg.add("SimJulia")
# jupyterlab
Pkg.add("IJulia")

#using IJulia
#jupyterlab()