# ES313 - Quickstart guide
This is a small guide intended to put you on your way for this course. We will be working with Julia v1.8.x for all applications. This is also the version you have on your CDN computer. It is recommended that you do all this before attending class, because the installation might take a while. A speedy and stable internet connection is an added value.

We try to make sure that the installation and configuration runs as smoothly as possible with a minimum of effort on your part. These guidelines work for Windows, MacOS & Linux. Occasionally there is a small difference between the platforms that will be made clear during this walkthrough. This guide has been successfully tested on Windows 10 (CDN), MacOS Monterey and Ubuntu 22.04 LTS.

## Tools
* You will be using the Julia REPL in combination Pluto notebooks.
* For code development you could use Notepad++ or Visual Studio Code (available in the CDN software center). There is a Julia language extension ([Notepad++](https://github.com/JuliaEditorSupport/julia-NotepadPlusPlus)/[VS Code](https://code.visualstudio.com/docs/languages/julia)) available for both. We use Visual Studio Code for this course.


## Installation
The process detailed below will guide you through the installation of Julia and the necessary dependencies. It works for both your personnal computer and the CDN computer.

**CDN specfic remark**:
When connected to the CDN network, you are behind the CDN proxy. This can impact the installation process. For the most fluid user experience, we recommend that you install Julia
from the software center when connected to CDN and then connect to an open network (such as pubnet or eduroam) for the rest of the installation process.
### Getting started (do this once)
1. Install Julia
    * CDN computer: install Julia from the software center. **Note:** this requires you to be connected to CDN. 
    * Personal computer: download and install the appropriate Julia v1.8.x release from [JuliaLang](https://julialang.org/downloads/oldreleases/). You are free to choose a more recent version of Julia, but for optimal compatibility with the course, we recommend v1.8.x.
2. Copy the configuration script from [here](https://raw.githubusercontent.com/BenLauwens/ES313/master/Setup/configES313.jl) and store it as a .jl file (e.g. with Notepad++). Things to modify by yourself (if required):
    * If you are not behind a proxy, disable the line for the proxy settings by changing it into a comment, i.e.
        ```julia
        # set the proxy server setting if required (on CDN)
        ENV["HTTP_PROXY"] = "http://CDNUSER:CDNPSW@dmzproxy005.idcn.mil.intra:8080"
        ```
        should become
        ```julia
        # set the proxy server setting if required (on CDN)
        #ENV["HTTP_PROXY"] = "http://CDNUSER:CDNPSW@dmzproxy005.idcn.mil.intra:8080"
        ```

        **Notes:** 

            - during previous tests, no explicit CDN account info was passed along and it worked, so only include your own credentials if there appears to be a problem.

            - currently, GitHub is NOT accessible when connected to the CDN network, so the installation should be done while connected to another network.
    * The location where you want the course documentation to be downloaded. By default, the `ES313` folder will be installed in
        * `C:\\Users\\YourAccount\\Documents\\` on Windows 
        * `/Users/YourAccount/Documents/` on Mac
        * `/home/YourAccount/Documents/` on Linux

        if you want to use another path, you can change it, e.g.
        ```Julia
        joinpath(homedir(),"Documents","3Ba","Sem1","ES313")
        ```
        will download the course folder into 
        * `C:\\Users\\YourAccount\\Documents\\3Ba\\Sem1\\ES313` (Windows)
        *  `/Users/YourAccount/Documents/3Ba/Sem1/ES313` (MacOS)
        * `/home/YourAccount/3Ba/Sem1/ES313` (Linux)
    
3. **CURRENTLY NOT REQUIRED, only for the CDN computer when behind a proxy**. Download the .gitconfig  from [here](https://raw.githubusercontent.com/BenLauwens/ES313/master/Setup/.gitconfig) and store it as a .gitignore file (e.g. with Notepad++) on the following locations:
    * `C:\\Users\\YourAccount\\`
    * `U:\\`
    
        
2. Run the script `configES313.jl` from the Julia REPL. This will install the `Git.jl` package and subsequently proceed to fetch the git repository for the course in the required folder.
    ```Julia
    include("C:\\path\\to\\folder name with a space\\configES313.jl") # on Windows
    include("path/to/configES313.jl") # on Mac/Linux
    ```

You are now ready to start working on the course.

### Getting updates (run when needed)
Some lectures may get updates during the semester. If you have followed the installation process, you can get the most recent version of the lecture by running the update script.

1. Run the update script from the Setup folder. This will fetch updates from GitHub and sync them with your local files. Local changes in a file are stashed before the update is pulled. Please note that you will no longer see any local changes after the update, they are however not gone, but [stashed](https://git-scm.com/docs/git-stash).
    ```Julia
    include("C:\\path\\to\\folder name with a space\\ES313\\setup\\update.jl") # on Windows
    include("path/to/folder name with a space/ES313/setup/update.jl") # on Mac/Linux
    ```
    For your own sanity, the most straightforward way that will allow you to stay synced and at the same time have your own file to work in, is to rename the notebook and maybe move it in a working directory from within Pluto as soon as you open it for the first time.
### Doing some work (run when you want to work)
1. Run the script to start the Pluto notebook. This will automatically start the notebook server using its default settings, which should open a new tab in your browser. If no window opens, you can always copy the explicit link from the REPL.
    ```Julia
    include("C:\\path\\to\\folder name with a space\\ES313\\setup\\start.jl") # on Windows
    include("path/to/folder name with a space/ES313/setup/start.jl") # on Mac/Linux
    ```
    For MacOS/Linux users, you can also use the following command directly in the terminal (this required you to have added the `julia` to your `PATH`, cf. [Platform Specific Instructions](https://julialang.org/downloads/platform/)):
    ```bash
    julia path/to/ES313/setup/start.jl # on Mac/Linux
    ```
2. By default the present working directory is changed to the one for this course, this means that you can open every single notebook simply by using a relative path e.g. `./Exercises/PS01 - Visualisation.jl` or `./Lectures/Lecture00.jl`. After typing `./`, you can even use the tab key for autocomplete.

### Troubleshooting
* Should you experience troubles with the installation, you can always delete the files in `C:\\Users\\YourAccount\\.julia\\` (Windows), `/Users/YourAccount/.julia/`(Mac) or `/home/YourAccount/.julia` (Linux) and then repeat the getting started sequence.

##  Overview of packages used

General:
* [Logging](https://docs.julialang.org/en/v1.8/stdlib/Logging/)
* [Dates](https://docs.julialang.org/en/v1.8/stdlib/Dates/)
* [Statistics](https://docs.julialang.org/en/v1.8/stdlib/Statistics/)
* [Distributions](https://juliastats.org/Distributions.jl/stable/)
* [HypothesisTests](https://juliastats.org/HypothesisTests.jl/stable/)
* [CSV](https://juliadata.github.io/CSV.jl/stable/)
* [JLD](https://github.com/JuliaIO/JLD.jl) (won't work on CDN, not installed by default)
* [JLD2](https://github.com/JuliaIO/JLD2.jl)

Plotting:
* [Plots](http://docs.juliaplots.org/latest/)
* [StatsPlots](https://github.com/JuliaPlots/StatsPlots.jl)
* [LaTeXStrings](https://github.com/stevengj/LaTeXStrings.jl)
* [Measures](https://github.com/JuliaGraphics/Measures.jl)
* [NativeSVG](https://github.com/BenLauwens/NativeSVG.jl)

Optimization:
* [JuMP](https://jump.dev/JuMP.jl/stable/)
* [GLPK](https://github.com/jump-dev/GLPK.jl)
* [Optim](https://julianlsolvers.github.io/Optim.jl/stable/)
* [GeneralQP](https://github.com/oxfordcontrol/GeneralQP.jl)
* [NLopt](https://github.com/JuliaOpt/NLopt.jl) (won't work on CDN, not installed by default)
* [Ipopt](https://ipoptjl.readthedocs.io/en/latest/ipopt.html)

Discrete event simulation:
* [ResumableFunctions](https://github.com/JuliaDynamics/ResumableFunctions.jl)
* [ConcurrentSim](https://github.com/JuliaDynamics/ConcurrentSim.jl)

Notebooks:
* [Pluto](https://github.com/fonsp/Pluto.jl)
* [PlutoUI](https://github.com/fonsp/PlutoUI.jl)