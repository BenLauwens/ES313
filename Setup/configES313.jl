#!/usr/bin/env julia

using Pkg
Pkg.update()
Pkg.add("IJulia")
Pkg.add("Plots")
Pkg.add("Distributions")
Pkg.add("LaTeXStrings")
Pkg.add("StatsPlots")
Pkg.add("Measures")
Pkg.add("JLD2")
Pkg.add("SimJulia")
Pkg.add(PackageSpec(url="https://github.com/BenLauwens/NativeSVG.jl"))


using IJulia
jupyterlab()