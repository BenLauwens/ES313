# ------------------------------------------------- #
#         CHANGE ONLY THIS (IF NEEDED)              #
# ------------------------------------------------- #

# set the proxy server setting if required (on CDN)
ENV["HTTP_PROXY"] = "http://CDNUSER:CDNPSW@dmzproxy005.idcn.mil.intra:8080"
# set the path
downloadfolder = joinpath(homedir(),"Documents")

# ------------------------------------------------- #
#            DO NOT CHANGE THIS                     #
# ------------------------------------------------- #
using Pkg

!ispath(downloadfolder) ? mkdir(downloadfolder) : nothing
cd(downloadfolder)

@info "Installing Git tools for Julia $(VERSION)..."
Pkg.add("Git")
using Git

@info "Downloading course material into $(downloadfolder)"
try
    run(`$(git()) clone https://github.com/BenLauwens/ES313.git`)
    @info "Download complete"
catch err
    @warn "Something went wrong, check one of the following:\n  - .gitignore file location\n  - destination folder already is a git repository"
    @info err
end

# Install & download required packages into environment
cd(joinpath(downloadfolder,"ES313"))
Pkg.activate(pwd())
@info "Downloading required packages"
Pkg.instantiate()
@info "Finished"