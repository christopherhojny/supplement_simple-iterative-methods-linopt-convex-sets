mutable struct AnalyticData
    obj
    liftpoint
    projineq
    center
    A
    b
    R
end

function analytic_initialize(oracle, lb, ubmodel)
    # see ellipsoid.jl
    if length(oracle.initeqs) > 0
        A = hcat((eq[1:end-1] for eq in oracle.initeqs)...)'
        b = vcat((eq[end] for eq in oracle.initeqs)...)
        u = A\b
        T = nullspace(A)
        n = size(T, 2)
    else
        n = length(oracle.obj)
        T = Matrix(I, n, n)
        u = zeros(n)
    end

    function liftpoint(z)
        return T * z + u
    end

    function projineq(ineq)
        return vcat(T' * ineq[1:end-1], ineq[end] - dot(ineq[1:end-1], u))
    end

    R = oracle.R + norm(u)
    center = zeros(n) # current analytic center

    # put (projections of) initial inequalities as well as objective cutoff into A,b
    A = zeros(Float64, length(oracle.initineqs), n)
    b = zeros(Float64, length(oracle.initineqs))
    for i in 1:length(oracle.initineqs)
        pineq = projineq(oracle.initineqs[i])
        for j in 1:n
            A[i,j] = pineq[j]
        end
        b[i] = pineq[end]
    end

    # put objectife cutoff first
    objineq = projineq([-oracle.obj; -lb])
    A = [objineq[1:end-1]'; A]
    b = [objineq[end]; b]

    return AnalyticData(oracle.obj, liftpoint, projineq, center, A, b, R)
end

# computes the analytic center of known constraints together with obj * x >= lb
function analytic_nextpoint(data)
    oldcenter = copy(data.center)
    success = analytic_center!(data.A, data.b, data.R, data.center)

    # to not modify the cut loop for statisitcal purposes, enter an "infinite" loop
    if !success
        data.center = copy(oldcenter)
        return data.liftpoint(oldcenter)
    end

    return data.liftpoint(data.center)
end

function analytic_add_ineq!(data, ineq)
    pineq = data.projineq(ineq)
    data.A = [data.A; pineq[1:end-1]']
    data.b = [data.b; pineq[end]]
end

function analytic_update_lb!(data, lb)
    objineq = data.projineq([-data.obj; -lb])
    data.b[1] = objineq[end] # objective cutoff is at first position; be careful if pruning is used!
end

function analytic_center!(A::AbstractMatrix, b::AbstractVector, r::Number, x::AbstractVector; verbose=true, grad_atol=1e-8, maxiter=50, α = 0.9)
    # Riley Badenbroek's implementation for computing the analytic center using an infeasible start Newton method
    # source: https://github.com/rileybadenbroek/CopositiveAnalyticCenter.jl
    #
    # Modifications: try-catch block around "\" operator and changed return value from nothing to true/false
    #

    #------------------------------------------------------------------------------------
    # MIT License

    # Copyright (c) 2020 Riley Badenbroek

    # Permission is hereby granted, free of charge, to any person obtaining a copy
    # of this software and associated documentation files (the "Software"), to deal
    # in the Software without restriction, including without limitation the rights
    # to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
    # copies of the Software, and to permit persons to whom the Software is
    # furnished to do so, subject to the following conditions:

    # The above copyright notice and this permission notice shall be included in all
    # copies or substantial portions of the Software.

    # THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
    # IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
    # FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
    # AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
    # LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
    # OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
    # SOFTWARE.
    #------------------------------------------------------------------------------------

    (m,n) = size(A)
    if m == 0
        # If there are no constraints yet, we do not modify x
        return true
    end
    d = r - norm(x) > sqrt(eps(Float64)) ? r^2 - x'*x : 1.
    s = [b[i] - A[i,:]'*x > sqrt(eps(Float64)) ? b[i] - A[i,:]'*x : 1. for i=1:m]
    κ = 1.
    λ = zeros(m)
    iter = 1
    LHS = Matrix{Float64}(undef, n, n)
    rhs = Vector{Float64}(undef, n)
    Δx = Vector{Float64}(undef, n)
    Δs = Vector{Float64}(undef, m)
    Δλ = Vector{Float64}(undef, m)
    while iter <= maxiter
        rhs .= ((r^2 - x'*x - d)/d^2 - 1. /d) * 2. * x + A'*(-1. ./ s + (s.^-2) .* (-s + b - A*x))
        LHS .= 4. / d^2 * x*x' + A' * ((s.^-2) .* A)
        for i in 1:n
            LHS[i,i] += 2. * κ
        end
        try
            Δx .= LHS \ rhs
        catch
            break
        end
        Δd  = -d + r^2 - x'*x - 2. *x'*Δx
        Δs .= -s + b - A*x - A*Δx
        Δκ  = -κ + 1. / d - Δd / d^2
        Δλ .= -λ + 1. ./ s - Δs ./ (s.^2)
        # Let res(t) be the residual norm if we take step size t
        res = t -> norm_Lagrange_gradient(A,b,r, x+t*Δx, d+t*Δd, s+t*Δs, κ+t*Δκ, λ+t*Δλ)
        res0 = res(0)
        maxt = 1.
        t = min(maxt,
            any(Δs .< 0) ? α*minimum(-s[i]/Δs[i] for i in 1:m if Δs[i] < 0) : maxt,
            Δd < 0 ? -α*d/Δd : maxt,
            Δκ < 0 ? -α*κ/Δκ : maxt
        )

        if res0 <= min(grad_atol, res(t)) && all(λ .>= 0)
            # We have approximated the analytic center as well as we can; going
            # on is pointless
            return true
        end
        x .+= t*Δx
        d  += t*Δd
        s .+= t*Δs
        κ  += t*Δκ
        λ .+= t*Δλ
        if iter == maxiter && res(t) <= grad_atol && all(λ .>= 0)
            # We have reached the final iteration, and we are beneath the
            # tolerance. Perhaps we could approximate the analytic center to
            # higher accuracy by continuing, but this is also fine.
            return true
        end
        iter += 1
    end
    println("failed to compute analytic center")
    if any(A*x .>= b)
        println("x is not even feasible for current inequalities")
        return false
    end

    return true
end

function norm_Lagrange_gradient(A::AbstractMatrix,b::AbstractVector,r::Number, x::AbstractVector, d::Number, s::AbstractVector, κ::Number, λ::AbstractVector)
    # source: Riley Badenbroek, https://github.com/rileybadenbroek/CopositiveAnalyticCenter.jl
    v1 = 2*κ * x + A' * λ
    v2 = -1 ./ s + λ
    v3 = s - b + A*x
    normsq = v1'*v1 + (-1. / d + κ)^2 + v2'*v2 + (d - r^2 + x'*x)^2 + v3'*v3
    return sqrt(normsq)
end
