struct OurProb
    model # optimization model
    convcons # constraint stating that some variables should sum up to
    pcons # constraints defining the entries of 
    p # variables corresponding to the entries of p
    n # ambient dimension
    λ # coefficient of -f
    R
end

function our_initialize(oracle, lb, ubmodel)
    obj = oracle.obj
    γ = lb
    A = oracle.initineqs
    E = oracle.initeqs
    R = oracle.R
    
    model = Model(Gurobi.Optimizer)
    set_silent(model)
    n = length(obj)
    pcons = []

    f = vcat(obj, [γ])
    A = [a / norm(a[1:end-1]) for a in A]
    E = [e / norm(e[1:end-1]) for e in E]

    @variable(model, λ >= 0) # coefficient for target
    @variable(model, μ[A] >= 0) # coefficients for inequalities
    @variable(model, τ[E]) # coefficients for equations
    @variable(model, p[1:n+1]) # entries of resulting vector

    # μ and λ should form convex multipliers
    convcons = @constraint(model, λ + sum(μ[a] for a in A) == 1)

    # p must be a convex combination of inequalities and target plus a linear combination of equations
    for i in 1:n+1
        push!(pcons, @constraint(model, sum(a[i] * μ[a] for a in A) + sum(e[i] * τ[e] for e in E) - f[i] * λ - p[i] == 0))
    end

    # minimize "norm" of p
    @objective(model, Min, sum(p[i]^2 for i in 1:n) + p[n+1]^2 / R^2)

    return OurProb(model, convcons, pcons, p, n, λ, R)
end

function our_nextpoint(data)
    prob = data
    R = prob.R
    optimize!(prob.model)
    p = [value(prob.p[i]) for i in 1:prob.n+1]
    return -R^2/p[end] * p[1:end-1]
end

function our_add_ineq!(data, ineq)
    @assert(norm(ineq[1:end-1]) > 0)
    prob = data
    ineq = ineq / norm(ineq[1:end-1])
    x = @variable(prob.model, base_name="μ[$ineq]", lower_bound=0)
    set_normalized_coefficient(prob.convcons, x, 1)
    for i in 1:prob.n+1
        set_normalized_coefficient(prob.pcons[i], x, ineq[i])
    end
end

function our_update_lb!(data, lb)
    prob = data
    set_normalized_coefficient(prob.pcons[end], prob.λ, -lb)
end
