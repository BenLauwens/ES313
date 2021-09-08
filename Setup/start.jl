using Pkg
# change pwd 
cd(joinpath(dirname(@__FILE__),".."))
# activate environment
Pkg.activate(pwd())
@info pwd()
using Pluto
Pluto.run()