function write_random_weighted_graph(n, filename)
    f = open(filename, "w")
    for i in 1:n
        for j in i+1:n
            write(f, string(i), ",", string(j), ",", string(rand(Float64)), "\n")
        end
    end
    close(f)
end

function write_random_triangles(n, numtriangles, filename)
    f = open(filename, "w")
    for t in 1:numtriangles
        i = rand(1:n)
        j = rand(1:n)
        while i == j
            j = rand(1:n)
        end
        k = rand(1:n)
        while k == i || k == j
            k = rand(1:n)
        end
        write(f, string(i), ",", string(j), ",1\n")
        write(f, string(i), ",", string(k), ",1\n")
        write(f, string(j), ",", string(k), ",1\n")
    end
    close(f)
end

function read_graph(filename)
    f = open(filename)
    lines = readlines(f)
    close(f)
    edges = []
    weights = []
    for line in lines
        a = split(line, ",")
        e = (parse(Int, a[1]), parse(Int, a[2]))
        if e ∉ edges # ignore duplicate edges
            push!(edges, e)
            push!(weights, parse(Float64, a[3]))
        end
    end
    nodes = unique([v for e in edges for v in e])

    return nodes, edges, weights
end