# ------------------------------------------------- #
#         CHANGE ONLY THIS (IF NEEDED)              #
# ------------------------------------------------- #
# set the path
const git_path_windows = "C:\\Program Files\\Git\\bin\\git.exe"



# ------------------------------------------------- #
#            DO NOT CHANGE THIS                     #
# ------------------------------------------------- #
using Pkg
# change pwd 
cd(joinpath(dirname(@__FILE__),".."))
# activate environment
using Git
Pkg.activate(pwd())
# fetch package updates
Pkg.update()
# fetch git updates
if Sys.iswindows()
    Git.run(`$(git_path_windows) stash`)
    Git.run(`$(git_path_windows) config pull.rebase false`)
    Git.run(`$(git_path_windows) pull`)
else
    Git.run(`$(git()) stash`)
    Git.run(`$(git()) config pull.rebase false`)
    Git.run(`$(git()) pull`)
end