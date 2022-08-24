using Pkg
# change pwd 
cd(joinpath(dirname(@__FILE__),".."))
# activate environment
Pkg.activate(pwd())
@info "Launching from $(pwd())"
using Pluto
Pluto.run()