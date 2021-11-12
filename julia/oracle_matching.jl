struct MatchingOracle
    # mandatory for each oracle
    initineqs
    initeqs
    obj
    R
    feastol
    # additional data here
    nodes
    edges
    weights
    model
    xvars
    zvars
    smart
end

function MatchingOracle(filename, feastol, smart=false)
    nodes, edges, weights = read_graph(filename)

    nedges = length(edges)
    initeqs = []
    initineqs = []
    for i in 1:nedges
        a = zeros(nedges + 1)
        a[i] = -1
        a[end] = 0
        push!(initineqs, a)
    end
    for v in nodes
        push!(initineqs, vcat([v in edges[i] ? 1 : 0 for i in 1:nedges], 1))
    end
    obj = weights / norm(weights)
    R = sqrt(nedges)

    model = Model(Gurobi.Optimizer)
    set_silent(model)
    @variable(model, x[edges], Bin)
    @variable(model, z[nodes], Bin)
    @variable(model, p >= 1, Int)
    for e in edges
        u,v = e
        @constraint(model, x[e] <= z[u])
        @constraint(model, x[e] <= z[v])
    end
    @constraint(model, sum(z[v] for v in nodes) == 2 * p + 1)

    MatchingOracle(initineqs, initeqs, obj, R, feastol, nodes, edges, weights, model, x, z, smart)
end

function separate_matching(moracle, point)
    edges = moracle.edges
    nodes = moracle.nodes
    x = moracle.xvars
    z = moracle.zvars
    model = moracle.model
    feastol = moracle.feastol

    @objective(model, Max, sum(point[i] * x[edges[i]] for i in 1:length(point)) - sum(z[v] for v in nodes) / 2)
    optimize!(model)

    U = [v for v in nodes if value(z[v]) > 0.5]
    a = [value(x[edges[i]]) > 0.5 ? 1 : 0 for i in 1:length(edges)]
    ineq = vcat(a, [(length(U) - 1) / 2])

    return dot(a, point) > (length(U) - 1) / 2 + feastol, ineq, nothing
end
