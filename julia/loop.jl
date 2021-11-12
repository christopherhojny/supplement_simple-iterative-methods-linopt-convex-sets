function loop(oracle, separate, maxiter, opttol, initialize, nextpoint, add_ineq!, update_lb!, initlb=nothing, initlbscale=1.0, verbose=false)
    @assert(0.999 < norm(oracle.obj) < 1.001)

    # initialize some lower bound
    current_lower_bound = initlb == nothing ? -oracle.R * norm(oracle.obj) : -oracle.R * norm(oracle.obj) * (1 - initlbscale) + initlbscale * initlb

    # set up LP for computing upper bounds
    ubmodel = Model(Gurobi.Optimizer)
    set_silent(ubmodel)
    n = length(oracle.obj)
    @variable(ubmodel, x[1:n])
    for a in oracle.initineqs
        @constraint(ubmodel, dot(a[1:end-1], x) <= a[n+1])
    end
    for a in oracle.initeqs
        @constraint(ubmodel, dot(a[1:end-1], x) == a[n+1])
    end
    @objective(ubmodel, Max, dot(oracle.obj, x))

    # remember lower and upper bounds for statistics
    lower_bounds = []
    upper_bounds = []

    # collect necessary data for the nextpoint procedure
    data = initialize(oracle, current_lower_bound, ubmodel)

    # run loop
    cnt = 1
    while cnt <= maxiter
        # remember current lower bound
        push!(lower_bounds, current_lower_bound)

        # compute current upper bound
        optimize!(ubmodel)
        push!(upper_bounds, objective_value(ubmodel))

        if verbose
            println("(", cnt, ") lower bound (primal), upper bound (dual) = ", current_lower_bound, ", ", upper_bounds[end])
        end

        # stop if gap is small
        if upper_bounds[end] < current_lower_bound + opttol
            break
        end

        # compute next point (we assume that this point satisfies all initial equations)
        x = nextpoint(data)

        # check if x satisfies the initial inequalities
        found, ineq = separate_initineqs(oracle, x)
        if found
            # add initial inequality again to oracle (no need to add it to ubmodel)
            add_ineq!(data, ineq)
        # next, check if the objective value of x is at least the current lower bound
        elseif dot(oracle.obj, x) < current_lower_bound
            update_lb!(data, current_lower_bound)
        else        
            # query oracle with that point
            is_violated, ineq, feaspoint = separate(oracle, x)

            # the oracle might return some (other) feasible point, which might give a better lower bound
            if feaspoint != nothing
                current_lower_bound = max(current_lower_bound, dot(oracle.obj, feaspoint))
                update_lb!(data, current_lower_bound)
            end

            # if x is feasible, it might give a better lower bound
            if !is_violated
                current_lower_bound = max(current_lower_bound, dot(oracle.obj, x))
                update_lb!(data, current_lower_bound)
            end
            if ineq != nothing
                add_ineq!(data, ineq)
                @constraint(ubmodel, dot(ineq[1:end-1], all_variables(ubmodel)) <= ineq[end])
            end
        end

        cnt += 1
    end

    return lower_bounds, upper_bounds
end

function separate_initineqs(oracle, point)
    for ineq in oracle.initineqs
        if dot(ineq[1:end-1], point) > ineq[end] + oracle.feastol
            return true, ineq
        end
    end
    return false, nothing
end
