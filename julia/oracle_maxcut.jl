struct MaxCutOracle
    # mandatory for each oracle
    initineqs
    initeqs
    obj
    R
    feastol
    # additional data here
    smart
end

function MaxCutOracle(filename, feastol, smart=true)
    nodes, edges, weights = read_graph(filename)
    n = length(nodes)
    @assert(nodes == [i for i in 1:n])

    function idx(i, j)
        return (i - 1) * n + j
    end

    initeqs = []
    # Xii = 1
    for i in 1:n
        eq = zeros(n^2 + 1)
        eq[idx(i, i)] = 1
        eq[end] = 1
        push!(initeqs, eq)
    end

    # Xij = Xji for i < j
    for i in 1:n
        for j in i + 1:n
            eq = zeros(n^2 + 1)
            eq[idx(i, j)] = 1
            eq[idx(j, i)] = -1
            push!(initeqs, eq)
        end
    end

    initineqs = []
    # Xij <= 1 for i < j
    for i in 1:n
        for j in i + 1:n
            ineq = zeros(n^2 + 1)
            ineq[idx(i, j)] = 1
            ineq[end] = 1
            push!(initineqs, ineq)
        end
    end

    # Xij >= -1 for i < j
    for i in 1:n
        for j in i + 1:n
            ineq = zeros(n^2 + 1)
            ineq[idx(i, j)] = -1
            ineq[end] = 1
            push!(initineqs, ineq)
        end
    end

    obj = zeros(n^2)
    for k in 1:length(edges)
        i, j = edges[k]
        w = weights[k]
        obj[idx(i, j)] = -w
        obj[idx(j, i)] = -w
    end
    obj = obj / norm(obj)
    R = n

    MaxCutOracle(initineqs, initeqs, obj, R, feastol, smart)
end

function separate_maxcut(mcoracle, point)
    n = convert(Int64, round(sqrt(length(point))))
    A = Symmetric(reshape(point, n, n))
    λ, v = min_eig_val_vec(A)
    ineq = hcat(vec_to_lhs(v), [0])

    if λ < -mcoracle.feastol
        id = [i == j ? 1 : 0 for i in 1:n for j in 1:n]
        μ = λ / (λ - 1)
        feaspoint = mcoracle.smart ? [μ * id[i] + (1 - μ) * point[i] for i in 1:n^2] : nothing
        return true, ineq, feaspoint
    end

    return false, ineq, nothing
end

function min_eig_val_vec(A)
    return eigmin(A), eigen(A, 1:1).vectors
end

function vec_to_lhs(v)
    w = reshape(- v * v', 1, length(v)^2)
    return [a for a in w]
end