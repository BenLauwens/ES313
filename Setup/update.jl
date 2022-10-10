using Pkg
# change pwd 
cd(joinpath(dirname(@__FILE__),".."))
# activate environment
using Git
Pkg.activate(pwd())
# fetch package updates
Pkg.update()
# fetch git updates
Git.run(`$(git()) stash`)
Git.run(`$(git()) config pull.rebase false`)
Git.run(`$(git()) pull`)