struct LPBoostOracle
    # mandatory for each oracle
    initineqs
    initeqs
    obj
    R
    feastol
    # additional data here
    features
    features_matrix
    labels
    smart
end

function LPBoostOracle(filename, feastol, smart=true)
    f = open(filename)
    lines = readlines(f)
    close(f)

    nu = parse(Float64, lines[1])
    labels = []
    features = []
    for line in lines[2:end]
        line = split(line, ",")
        push!(labels, parse(Int, line[1]))
        push!(features, [parse(Float64, x) for x in line[2:end]])
    end

    rows = length(features)
    cols = length(features[1])
    features_matrix = (reshape(vcat(features...), (cols, rows)))'

    n = length(features)
    D = 1 / (n * nu)
    R = sqrt(n * D^2 + 1)

    # recall that there is a single variable γ in [-1,1], and a λ_i variable for each feature point with 0 <= λ_i <= D, and sum_i λ_i = 1
    # γ is treated as the first variable
    # objective
    obj = vcat([1], zeros(n))

    # sum of λ variables is one
    initeqs = [vcat([0], ones(n + 1))]

    # γ is within -1 and 1
    initineqs = [vcat([1], zeros(n), [1])]
    push!(initineqs, vcat([-1], zeros(n), [1]))

    # each λ is within 0 and D
    for i in 1:n
        push!(initineqs, vcat(zeros(i), [1], zeros(n - i), [D]))    
        push!(initineqs, vcat(zeros(i), [-1], zeros(n - i + 1)))
    end

    LPBoostOracle(initineqs, initeqs, obj, R, feastol, features, features_matrix, labels, smart)
end

function separate_lpboost(lpboracle, point)
    features = lpboracle.features
    labels = lpboracle.labels

    γ = point[1]
    λ = point[2:end]

    stump = build_stump(labels, lpboracle.features_matrix, λ)
    lhs = [apply_tree(stump, features[i]) * labels[i] for i in 1:length(features)]
    score = dot(lhs, λ)

    feaspoint = lpboracle.smart ? vcat([-score], λ) : nothing
    ineq = vcat([1], lhs, [0])

    if score + γ > lpboracle.feastol
        return true, ineq, feaspoint
    end
    return false, ineq, feaspoint
end