using Pkg
# change pwd 
cd(joinpath(dirname(@__FILE__),".."))
# activate environment
VERSION < v"1.6" ? (using GitCommand) : (using Git)
Pkg.activate(pwd())
# fetch package updates
Pkg.update()
# fetch git updates
if VERSION < v"1.6"
    git() do git
        # stash local changes
        GitCommand.run(`$git stash`)
        GitCommand.run(`$git config pull.rebase false`)
        # if on CDN 
        #run(`$git config --global http.proxy http://CDNusername:CDNpassword@dmzproxy005.idcn.mil.intra:8080`)
        GitCommand.run(`$git pull`)
    end
else
    Git.run(`$(git()) stash`)
    Git.run(`$(git()) config pull.rebase false`)
    Git.run(`$(git()) pull`)
end


