# ------------------------------------------------- #
#         CHANGE ONLY THIS (IF NEEDED)              #
# ------------------------------------------------- #

# set the proxy server setting if required (on CDN)
#ENV["HTTP_PROXY"] = "http://CDNUSER:CDNPSW@dmzproxy005.idcn.mil.intra:8080"
# set the path
downloadfolder = joinpath(homedir(),"Documents")


# ------------------------------------------------- #
#            DO NOT CHANGE THIS                     #
# ------------------------------------------------- #

# add GitCommand
using Pkg
using Logging

!ispath(downloadfolder) ? mkdir(downloadfolder) : nothing
cd(downloadfolder)

@info "Installing Git tools for Julia $(VERSION)..."

VERSION < v"1.6" ? (Pkg.add("GitCommand"), using GitCommand) : (Pkg.add("Git"), using Git)
@info "Downloading course material into $(downloadfolder)"
try
    if VERSION < v"1.6"
        GitCommand.git() do git
            run(`$git clone https://github.com/BenLauwens/ES313.git`)
        end
    else
        run(`$(git()) clone https://github.com/BenLauwens/ES313.git`)
    end
    @info "Download complete"
catch err
    @warn "Something went wrong, check one of the following:\n  - .gitignore file location\n  - destination folder already a git repository"
    @info err
end

 
# Install & download required packages into environment
cd(joinpath(downloadfolder,"ES313"))
Pkg.activate(".")
@info "Downloading required packages"
Pkg.instantiate()
@info "Checking for package updates"
Pkg.update()


# overview of install instruction per package (covered in Project.toml)
#=
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
Pkg.add(PackageSpec(url="https://github.com/B4rtDC/GeneralQP.jl"))
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
=#