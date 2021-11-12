using Dates
using DecisionTree
using Gurobi
using JuMP
using LinearAlgebra
using Plots

include("analytic.jl")
include("cutloop.jl")
include("data.jl")
include("ellipsoid.jl")
include("generate_plots_and_statistics.jl")
include("graph.jl")
include("loop.jl")
include("our.jl")
include("oracle_simple.jl")
include("oracle_matching.jl")
include("oracle_maxcut.jl")
include("oracle_lpboost.jl")


function main(args)

    #
    # PARAMETERS ------------------------------------------------------------------
    #
    feastol = 0.001
    opttol = 0.001
    maxiter = 500
    plot_data = false
    relative = false
    print_statistics = false
    verbose = false
    statistics_file = ""
    withinitlbs = false
    initlbscale = 1.0
    issmart = true

    #
    # READ OPTIONS
    #
    if "-p" in args
        plot_data = true
        run(`mkdir -p plots`)   # ensure that plots directory exists
    end
    if "-r" in args
        relative = true
    end
    if "-s" in args
        print_statistics = true
    end
    if "-v" in args
        verbose = true
    end
    if "-w" in args
        statistics_file = "stats_" * replace(replace(string(now()), "." => "-"), ":" => '-') * ".out"
        run(`mkdir -p statistics`)   # ensure that statistics directory exists
    end
    if "-i" in args
        withinitlbs = true
    end
    if "-ii" in args
        initlbscale = 0.99
    end
    if "-ns" in args
        issmart = false
    end

    #
    # TESTING ---------------------------------------------------------------------
    #
    names, files, ors, seps, initlbs = get_data()
    methods = ["cutloop", "ellipsoid", "analytic", "our"]

    for i in 1:length(names)
        name, instances, or, separate, lbs = names[i], files[i], ors[i], seps[i], initlbs[i]
        println("Test set: ", name)

        for j = 1:length(instances)
            println("Instance: ", instances[j])
            initlb = withinitlbs ? lbs[j] : nothing

            oracle = or(instances[j], feastol, issmart)

            instancename = split(split(instances[j], "/")[end], ".")[1]
            if plot_data
                ellipsoid_plot = plot(title = instancename, xlabel = "number of iterations", ylabel = "primal/dual bound", legend = :bottomright)
                noellipsoid_plot = plot(title = instancename, xlabel = "number of iterations", ylabel = "primal/dual bound", legend = :bottomright)
            end

            for method in methods
                println("Method: ", method)
                if method == "analytic"
                    funcs = analytic_initialize, analytic_nextpoint, analytic_add_ineq!, analytic_update_lb!
                elseif method == "ellipsoid"
                    funcs = ellipsoid_initialize, ellipsoid_nextpoint, ellipsoid_add_ineq!, ellipsoid_update_lb!
                elseif method == "our"
                    funcs = our_initialize, our_nextpoint, our_add_ineq!, our_update_lb!
                elseif method == "cutloop"
                    funcs = cutloop_initialize, cutloop_nextpoint, cutloop_add_ineq!, cutloop_update_lb!
                end

                initialize, nextpoint, add_ineq!, update_lb! = funcs
                lower_bounds, upper_bounds = loop(oracle, separate, maxiter, opttol, initialize, nextpoint, add_ineq!, update_lb!, initlb, initlbscale, verbose)

                if plot_data
                    extend_plot([1:length(upper_bounds)], upper_bounds, method, true, lbs[j], relative, opttol, ellipsoid_plot, true)
                    extend_plot([1:length(lower_bounds)], lower_bounds, method, false, lbs[j], relative, opttol, ellipsoid_plot, true)
                    extend_plot([1:length(upper_bounds)], upper_bounds, method, true, lbs[j], relative, opttol, noellipsoid_plot, false)
                    extend_plot([1:length(lower_bounds)], lower_bounds, method, false, lbs[j], relative, opttol, noellipsoid_plot, false)
                end
                generate_statistics(print_statistics, upper_bounds, lower_bounds, instancename, method, lbs[j], relative, statistics_file)
            end

            if plot_data
                savefig(ellipsoid_plot, "plots/" * instancename * ".pdf")
                savefig(noellipsoid_plot, "plots/noellipsoid_" * instancename * ".pdf")
            end
        end
    end
end

main(ARGS)
