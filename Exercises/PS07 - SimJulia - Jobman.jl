#=
We want to simulate a setting in which different jobs are generated. These jobs can have different priorities. 
Each day we will look for tasks that are scheduled. The ones with the highest priority are done first.

The `Job` object describes a task by its number id, its priority and the time it takes to complete.

The `work` function check if there are jobs to be done. If so, it takes the one with the highest priority and
treats them. If a job cannot be done in one day, it is put back in the queue, but with the highest priority
and a modified remaining duration.

This application illustrates how you can work with stores and priorities and work with time.
=#

using SimJulia

mutable struct Job
    number::Int             # job identification
    prio::Int               # priority (0: normal, 1: high, 2: super high (i.e. unfinished))
    duration                # standard time delta when working with datetime
    start                   # moment task started
    stop                    # moment when finished
    finished::Bool          # task terminated
    # only intialise required fields
    function Job(number; prio::Int=0, duration)
        j = new()
        j.number = number
        j.prio = prio
        j.duration = duration
        return j
    end
end

Base.show(io::IO, j::Job) = print(io, "Job $(j.number) (prio: $(j.prio), duration: $(j.duration))")

@resumable function work(sim::Environment, tasks::Store{Job}, completed::Store{Job})
    while true
        if count(t -> t.prio == 2, keys(tasks.items)) > 0
            @info "$(now(sim)) - VERY HIGH prio task(s) found"
            current = @yield get(tasks, t -> t.prio == 2)
        elseif count(t -> t.prio == 1, keys(tasks.items)) > 0
            @info "$(now(sim)) - HIGH prio task(s) found"
            current = @yield get(tasks, t -> t.prio == 1)
        elseif count(t -> t.prio == 0, keys(tasks.items)) > 0
            @info "$(now(sim)) - default prio task(s) found"
            current = @yield get(tasks, t -> t.prio == 0)
        else
            @info "$(now(sim)) - Nothing to do!"
            current = nothing
        end    

        # next day if no work
        if isnothing(current)
            @yield timeout(sim, 24)
        
        # proces the task(s)
        else
            @info "$(now(sim)) - working on task $(current)"
            current.start = now(sim)
            if (current.start + current.duration) % 24 > 16
                @info "$(now(sim)) - not enough time for task $(current)"
                # calculate remaining time
                dt =  current.duration - ((current.start + current.duration) % 24 - 16)
                # add remaing part of task on next day with super high prio
                current.duration -= dt
                current.prio = 2
                @yield put(tasks, current)
                # move on to end of day
                @yield timeout(sim, 16 - now(sim))
                @info "$(now(sim)) - end of day!"
                @yield timeout(sim, 16)
            else
                @yield timeout(sim, current.duration)
                current.stop = now(sim)
                current.finished = true
                @info "$(now(sim)) - task $(current) is done!"
                @yield put(completed, current)
            end
        end
    end
end

function jobman()
    @info "\nPS07 - SimJulia - Jobman\n\n"
    sim = Simulation(8)
    jobs = Store{Job}(sim)
    completedjobs = Store{Job}(sim)
    # add some jobs
    for i in 1:10
        put(jobs, Job(i, prio=rand([0,1]), duration = 10))
    end
    @info """Starting task list:\n$(join(["- $(t)" for t in keys(jobs.items)],"\n"))"""
    @process work(sim, jobs, completedjobs)
    run(sim, 50)

    @info """$(length(completedjobs.items)) completed tasks: \n$(join(["- $(t)" for t in keys(completedjobs.items)],"\n"))\n"""
    @info "$(length(jobs.items)) planned tasks: \n$(join(["- $(t)" for t in keys(jobs.items)],"\n"))\n"
end

jobman()