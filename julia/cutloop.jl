function cutloop_initialize(oracle, lb, ubmodel)
    return all_variables(ubmodel)
end

function cutloop_nextpoint(data)
    vars = data
    return [value(v) for v in vars]
end

function cutloop_add_ineq!(data, ineq)
end

function cutloop_update_lb!(data, lb)
end