using Pkg
# change pwd 
cd(joinpath(dirname(@__FILE__),".."))
# activate environment
Pkg.activate(pwd())

using GitCommand
# fetch package updates
Pkg.update()
# fetch git updates
git() do git
    # stash local changes
    run(`$git stash`)
    #run(`$git config pull.rebase false`)
    # if on CDN 
    #run(`$git config --global http.proxy http://CDNusername:CDNpassword@dmzproxy005.idcn.mil.intra:8080`)
    run(`$git pull`)
end

