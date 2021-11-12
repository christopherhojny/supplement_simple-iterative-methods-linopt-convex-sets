mutable struct EllipsoidData
    liftpoint
    projlhs
    obj
    n
    z
    D
end

function ellipsoid_initialize(oracle, lb, ubmodel)
    # actual space: x
    # projected space: z (parametrization of the space defined by the initial equations)
    # T is a matrix containing an orthonormal basis of the kernel of the matrix defined by the initial equations
    # u is a particular solution of the initial equations
    # So, x (in the actual space) satisfies the initial equations if and only if
    # x = T * z + u
    # Note that x satisfies
    # <a,x> <= b
    # if and only if
    # <T'a,z> <= b - <a,u>.
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

    function projlhs(lhs)
        return T' * lhs
    end

    z = zeros(n)
    D = Matrix((oracle.R + norm(u)) * I, n, n)

    return EllipsoidData(liftpoint, projlhs, oracle.obj, n, z, D)
end

function ellipsoid_nextpoint(data)
    return data.liftpoint(data.z)
end

function ellipsoid_add_ineq!(data, ineq)
    # only update if inequality is violated by center
    if dot(data.liftpoint(data.z), ineq[1:end-1]) > ineq[end]
        a = -data.projlhs(ineq[1:end-1])
        update_ellipsoid(data, a)
    end
end

function ellipsoid_update_lb!(data, lb)
    a = data.projlhs(data.obj)
    update_ellipsoid(data, a)
end

function update_ellipsoid(data, a)
    D = data.D
    n = data.n
    anorm = a / sqrt(a' * D * a)
    Danorm = D * anorm / (n+1)
    data.z .+= Danorm
    D .*= n^2 / (n^2 - 1)
    D .+= - 2 * n^2 / (n - 1) * Danorm * Danorm'
    if !issymmetric(D)
        D = 0.5 * (D + D')
    end
    data.D = D
end