# Dependencies
using Distributions # not required per se
using Plots
using Logging
import Base: show, zero
# Constants
const states = ['U','N','A','F']
const cs = Dict('N'=>1/2, 'A'=>1/4, 'F'=>1/8)
# helper function for indices
inds(i,j) = CartesianIndex.([(i-1, j-1), (i,j-1), (i+1, j-1), 
            (i-1, j),             (i+1, j), 
            (i-1, j+1), (i,j+1), (i+1, j+1)])

"""
    Cell

Cell in our world. State should be one of 'U', 'N', 'A','F','B' for 
respectively Urban, Nature, Agriculture, Forest and Border.
"""
struct Cell
    state::Char
    age::Int
end
zero(::Type{Cell}) = Cell('b',0)
show(io::IO, c::Cell) = print(io, "($(c.state), $(c.age))")

"""
    getneigbors(world::Array{T,2}, i::Int,j::Int)

return the eight neighbors of the world in position (i,j)
"""
function getneigbors(world::Array{T,2}, i::Int,j::Int) where T
    return view(world, inds(i,j))
end

"""
    trfprob(c::Cell)

Return transformation probability for a non-urban to urban cell.
"""
function trfprob(c::Cell)
    return tanh((c.age+1/2)/40)
end

"""
    urbanisation(c::Cell, n)

return the next states for a cell and its neighbors

see also: [getneigbors](@ref)
"""
function urbanisation(c::Cell, n)
    # urban stays urban
    if c.state == 'U'
        @debug "Town gets older"
        return Cell('U', c.age + 1)
    # nature evolves to urban
    else
        # within mutation treshold
        if rand() < sum(map(trfprob, filter(x-> x.state =='U',n))) / 8 * cs[c.state]
            return Cell('U', 0)
            @info "Added new city!!!"
        # otherwise just age
        else
            @debug "$(c.state) gets older"
            return Cell(c.state, c.age + 1)
        end
    end
end

"""
    ruralisation(c::Cell, n)

return the next states for a cell and its neighbors

see also: [getneigbors](@ref)
"""
function ruralisation(c::Cell,n)
    # urban stays urban
    if c.state == 'U'
        @debug "Town gets older"
        return Cell(c.state, c.age + 1)
    # forest stays forest
    elseif c.state =='F'
        @debug "Forest grows older"
        return Cell(c.state, c.age + 1)
    # nature to forest
    elseif c.state == 'N'
        # within mutation treshold
        if rand() < 1/9 * tanh(c.age/20) * (1 + length(filter(x-> x.state =='F',n)) )
            @debug "NEW FOREST!!"
            return Cell('F',0)
        # otherwise just age
        else
            return Cell(c.state, c.age +1)
        end
    # agriculture to nature
    elseif c.state == 'A'
        if rand() < 1/8 * sum( map(x -> tanh(x.age / 10), filter(x-> x.state =='N',n) ) )
            @debug "NEW NATURE!!"
            return Cell('N',0)
        else
            return Cell(c.state, c.age +1)
        end
    end
end

"""
    update(c::Cell, n)

Given a cell and its neighbors, determine the next state
"""
function update(c::Cell, n)
    if rand() < 5/10
        return urbanisation(c, n)
    else
        return ruralisation(c,n)
    end
end

"""
    genworld(N::Int)

Generate an initial world (random composition) with a border.

statedist: default to uniform, but you can also use a custom distribution
"""
function genworld(N::Int; 
                 statedist=Categorical(1/length(states).* ones(length(states))))
    @debug statedist
    world = zeros(Cell, N+2, N+2)
    world[2:end-1, 2:end-1] .= reshape([Cell(states[rand(statedist)], 7) for _ in 1:N^2], N, :)
    return world
end

"""
    newworld!(w::Array{Cell,2}, nw::Array{Cell,2})

From a given world, determine the next state and return it.
"""
function newworld!(w::Array{Cell,2}, nw::Array{Cell,2})
    for i in 2:size(w,1)-1
        for j in 2:size(w,2)-1
            nw[i,j] = update(w[i,j], getneigbors(w, i, j))
        end
    end
    w .= nw
    return w
end

# actual program
function main(  N::Int=10, 
                d=Categorical(1/length(states).* ones(length(states)));
                nsteps::Int=100)
    w = genworld(N, statedist=d)
    nw = zeros(Cell, size(w))
    record = zeros(nsteps,4)
    for i in 1:nsteps
        newworld!(w, nw)
        record[i,1] = sum(map(x-> x.state == 'U', w)) / N^2
        record[i,2] = sum(map(x-> x.state == 'F', w)) / N^2
        record[i,3] = sum(map(x-> x.state == 'N', w)) / N^2
        record[i,4] = sum(map(x-> x.state == 'A', w)) / N^2
    end
    return record
end

# logger settings
Logging.global_logger(ConsoleLogger(stdout,Logging.Debug))
Logging.disable_logging(Logging.LogLevel(-1000))

# do it
@info "running main"
record = main(100)


# plotting (not was not required)
const cdict = Dict(65=>0, 70=>1, 78=>2, 85=>3, 98=>4)
const cmap = cgrad([    RGBA(222/255,166/255,53/255),       # agriculture brown
                        RGBA(80/255,118/255,40/255),        # forest green (dark)
                        RGBA(105/255,224/255,62/255),       # nature green (light)
                        RGBA(181/255,181/255,181/255),      # urban gray
                        RGBA(240/255,240/255,240/255)]);    # border off-white
const heatmapsettings = Dict(:yflip=>true, :color=>cmap, :axis=>false, :size=>(500,350), :clim=>(0,4));

"""
    plotworld(w::Array{Cell,2}; title::String="")

Make a heatmap of the world
"""
function plotworld(w::Array{Cell,2}; title::String="")
    return heatmap(map(x->cdict[Int(x.state)], w); title=title, heatmapsettings...)
end


"""
    testworld()

Generate a test world and show it
"""
function testworld()
    N = 7
    world = zeros(Cell, N+2, N+2)
    world[2:4, 2:4] = reshape([Cell('A', 0) for _ in 1:3^2], 3, :) # agricultre
    world[2:4, 6:8] = reshape([Cell('N', 0) for _ in 1:3^2], 3, :) # nature
    world[6:8, 2:4] = reshape([Cell('F', 0) for _ in 1:3^2], 3, :) # forest
    world[6:8, 6:8] = reshape([Cell('U', 0) for _ in 1:3^2], 3, :) # urban
    p = plotworld(world)
    title!("Testworld: [agriculture, nature; forest, urban]")
    return p
end

@info "plotting testworld"
display(testworld())
@info "plotting evolution"
plot(1:size(record,1), record, marker=:circle, ylims=(-0.05,1.05), 
    label=["urban" "forest" "nature" "agriculture"],
    xlabel="time [years]", ylabel="% of land usage")
