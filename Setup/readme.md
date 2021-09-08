# ES313 - Quickstart guide
This is a small guide intended to put you on your way for this course. We will be working with Julia v1.5.3 for all applications. This is also the version you have on your CDN computer. It is recommended that you do all this before attending class, because the installation might take a while. A speedy and stable internet connection is an added value.

We try to make sure that the installation and configuration runs as smoothly as possible with a minimum of effort on your part. These guidelines work for both Windows, MacOS & Linux. Occasionally there is a small difference between the platforms that will be made clear during this walkthrough. This guide has been successfully tested on Windows 10 (CDN) & MacOS Big Sur.

## Tools
* You will be using the Julia REPL in combination with a Pluto notebook.
* For code development you could use Notepad++ (available in the software center). There is a [Julia language extension](https://github.com/JuliaEditorSupport/julia-NotepadPlusPlus) available for Notepad++.
## CDN computer (behind proxy)
### Getting started (do this once)
1. Install Julia from the software center. 
2. Copy the configuration script from [here](https://raw.githubusercontent.com/BenLauwens/ES313/master/Setup/configES313.jl) and store it as a .jl file (e.g. with Notepad++). Things to modify by yourself:
    * The location where you want the course documentation to be downloaded. This defaults to `C:\\Users\\YourAccount\\ES313` on Windows and `/Users/YouAccount/ES313` on Mac.
    * The proxy settings (CDN proxy is used by default). If you are not behind a proxy, disable this line by changing it into a comment.

        **Note: during the tests, no explicit CDN account info was passed along and it worked, so only include your own credentials if there appears to be a problem.**
3. Download the .gitconfig  from [here](https://raw.githubusercontent.com/BenLauwens/ES313/master/Setup/.gitconfig) and store it as a .gitignore file (e.g. with Notepad++) on the following locations:
    * `C:\\Users\\YourAccount\\`
    * `U:\\` (CDN only)
    
        **Note: This is only required for the CDN machine when behind a proxy.**
2. Run the script `configES313.jl` from the Julia REPL. This will install the `GitCommand` package and subsequently proceed to fetch the git repository for the course in the required folder.
    ```Julia
    include("C:\\path\\to\\folder name with a space\\configES313.jl") # on Windows
    include("path/to/configES313.jl") # on Mac
    ```
### Staying up-to-date (run when needed)
1. Run the update script from the Setup folder. This will fetch updates from GitHub and sync them with your local files. Local changes in a file are stashed before the update is pulled. Please note that you will no longer see any local changes after the update, they are however not gone, but stashed.
    ```Julia
    include("C:\\path\\to\\folder name with a space\\ES313\\setup\\update.jl") # on Windows
    include("path/to/ES313/setup/update.jl") # on Mac
    ```
    For your own sanity, the most straightforward way that will allow you to stay synced and at the same time  have your own file to work in, is to rename the notebook from within Pluto as soon as you open it for the first time. Any updates from our side will get to you when syncing, and you can still work in a separate document if you wish.
### Doing some work (run when you want to work)
1. Run the script to start the Pluto notebook. This will automatically start the notebook server using its default settings, which should open a new tab in your browser. If no window opens, you can always copy the explicit link from the REPL.
    ```Julia
    include("C:\\path\\to\\folder name with a space\\ES313\\setup\\start.jl") # on Windows
    include("path/to/ES313/setup/start.jl") # on Mac
    ```
2. By default the present working directory is changed to the one for this course, this means that you can open every single notebook simply by using a relative path e.g. `./Exercises/PS01 - Visualisation.jl` or `./Lectures/Lecture00.jl`. After typing `./`, you can even use the tab key for autocomplete.

### Troubleshooting
* Should you experience troubles with the installation, you can always delete the files in `C:\\Users\\YourAccount\\.julia\\` and then repeat the getting started sequence.
* When you are not behind the proxy, most things should work without much trouble. Should you encounter a problem, you can always comment that line the sets the environment variable with respect to the proxy.



## Personal computer
On both Windows and Mac, the procedure is highly similar to the CDN procedure. The only difference is the absence of the proxy server. You can deactivate the use of a proxy server by commenting the appropriate line in the `configES313.jl` file and not using the `.gitignore` file. for both operating systems you start from the Julia REPL by including the appropriate file.



##  Overview of packages
List of different packages that will be used for this course:

General:
* [Logging](https://docs.julialang.org/en/v1.2/stdlib/Logging/#)
* [Dates](https://docs.julialang.org/en/v1.2/stdlib/Dates/)
* [Statistics](https://docs.julialang.org/en/v1.2/stdlib/Statistics/)
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
* [JuMP](https://jump.dev/JuMP.jl/v0.19.0/index.html)
* [GLPK](https://github.com/jump-dev/GLPK.jl)
* [Optim](https://julianlsolvers.github.io/Optim.jl/stable/)
* [GeneralQP](https://github.com/oxfordcontrol/GeneralQP.jl)
* [NLopt](https://github.com/JuliaOpt/NLopt.jl) (won't work on CDN, not installed by default)
* [Ipopt](https://ipoptjl.readthedocs.io/en/latest/ipopt.html)

Discrete event simulation:
* [ResumableFunctions](https://github.com/BenLauwens/ResumableFunctions.jl)
* [SimJulia](https://github.com/BenLauwens/SimJulia.jl)

Notebooks:
* [Pluto](https://github.com/fonsp/Pluto.jl)
* [PlutoUI](https://github.com/fonsp/PlutoUI.jl)