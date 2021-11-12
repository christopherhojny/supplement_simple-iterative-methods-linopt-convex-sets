function extend_plot(xvals, yvals, method, is_upper_bound, opt, relative, tol, the_plot, plot_ellipsoid)

    # select colors for methods
    if method == "cutloop"
        color = "red"
    elseif method == "ellipsoid"
        color = "green"
    elseif method == "analytic"
        color = "orange"
    elseif method == "our"
        color = "blue"
    end

    # select opacity of lines
    if is_upper_bound
        opacity = 1.5
    else
        opacity = 0.5
    end

    # specify label of data series
    if is_upper_bound
        lab = method
    else
        lab = ""
    end

    # don't print primal information for the cut loop
    if method == "cutloop" && !is_upper_bound
        return nothing
    end

    # don't print ellipsoid if specified this way
    if method == "ellipsoid" && !plot_ellipsoid
        return nothing
    end

    # compute the number of digits according to tolerance
    ndigits = floor(Int, log(10, 1/tol))

    # whether we plot relative data
    if relative && !isnan(opt)
        # take care of optimally initialized data
        if yvals[1] == opt
            myyvals = [0 for i = 1:length(yvals)]
        else
            myyvals = [round(yvals[i], digits=ndigits) for i = 1:length(yvals)]
            opt = round(opt, digits=ndigits)
            if is_upper_bound
                myyvals = [round( (myyvals[i] - opt) / (myyvals[1] - opt), digits=ndigits) for i = 1:length(yvals)]
            else
                myyvals = [round(-(myyvals[i] - opt) / (myyvals[1] - opt), digits=ndigits) for i = 1:length(yvals)]
            end
        end
        plot!(the_plot, xvals, myyvals, label = lab, linecolor = color, linealpha = opacity)
    else
        myyvals = [round(yvals[i], digits=ndigits) for i = 1:length(yvals)]
        plot!(the_plot, xvals, myyvals, label = lab, linecolor = color, linealpha = opacity)
    end
    
    return nothing
end

function generate_statistics(do_run, upper_bounds, lower_bounds, name, method, opt, relative, statistics_file)

    # don't do anything if we don't run
    if !do_run
        return nothing
    end

    primal_integral = 0
    dual_integral = 0
    primal_dual_integral = 0

    # compute relative or absolute upper/lower bounds
    if !isnan(opt)
        if relative
            # take care of optimal initialization
            if upper_bounds[1] == opt
                upper = [0 for i = 1:length(upper_bounds)]
            else
                upper = [(upper_bounds[i] - opt) / (upper_bounds[1] - opt) for i = 1:length(upper_bounds)]
            end
            if lower_bounds[1] == opt
                lower = [0 for i = 1:length(lower_bounds)]
            else
                lower = [(lower_bounds[i] - opt) / (lower_bounds[1] - opt) for i = 1:length(lower_bounds)]
            end
        else
            upper = [upper_bounds[i] - opt for i = 1:length(upper_bounds)]
            lower = [opt - lower_bounds[i] for i = 1:length(lower_bounds)]
        end

        for i = 1:length(upper_bounds)
            primal_integral += lower[i]
            dual_integral += upper[i]
            primal_dual_integral += lower[i] + upper[i]
        end
    else
        primal_integral = NaN
        dual_integral = NaN
        for i = 1:length(upper_bounds)
            primal_dual_integral += upper_bounds[i] - lower_bounds[i]
        end
    end

    # write or print statistics
    if cmp(statistics_file, "") != 0
        open("statistics/" * statistics_file, "a") do io
            println(io, method, " ", name, ": its = ", length(upper), ", ub = ", upper_bounds[end], ", lb = ", lower_bounds[end],
                    ", PI = ", primal_integral, ", DI = ", dual_integral, ", PDI = ", primal_dual_integral)
        end
    else
        println(method, " ", name, ": its = ", length(upper), ", ub = ", upper_bounds[end], ", lb = ", lower_bounds[end],
                ", PI = ", primal_integral, ", DI = ", dual_integral, ", PDI = ", primal_dual_integral)
    end

    return nothing
end
