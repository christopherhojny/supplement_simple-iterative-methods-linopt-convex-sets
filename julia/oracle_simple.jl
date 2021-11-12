struct SimpleOracle
    # mandatory for each oracle
    initineqs
    initeqs
    obj
    R
    feastol
    # additional data here
    ineqs
end

function separate_simple(soracle, point)
    for ineq in soracle.ineqs
        if dot(ineq[1:end-1], point) > ineq[end] + soracle.feastol
            return true, ineq, nothing
        end
    end
    return false, nothing, nothing
end
