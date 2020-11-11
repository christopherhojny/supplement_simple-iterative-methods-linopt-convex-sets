import numpy

from MIP import *

####################################################################################################
#
# FUNCTIONS RELATED TO GRAPHS
#
####################################################################################################

def read_graph_from_file(filename):
    """
    reads a (possibly) weighted graph in DIMACS format from file
    filename - path to file encoding instance
    """

    f = open(filename, "r")

    nodes = []
    edge_list = []
    obj = []

    for line in f:
        line = line.strip()
        if line.startswith("p"):
            nodes = list(range(1, int(line.split(" ")[2]) + 1))
        if line.startswith("e"):
            data = line.split(" ")
            i = int(data[1])
            j = int(data[2])
            e = (i, j) if i < j else (j, i)
            objcoef = 1.0 if len(data) <= 3 else float(data[3])
            edge_list.append(e)
            obj.append(objcoef)
    f.close()

    return nodes, edge_list, obj


def compute_edge_weights(nodes, edges):
    '''
    Computes edge weights of a graph.
    An edge {u,v} is assigned the weight degree(u) + degree(v).

    nodes - list of nodes
    edges - list of edges
    '''

    degrees = {}
    for (u,v) in edges:
        if u in degrees:
            degrees[u] += 1
        else:
            degrees[u] = 1
        if v in degrees:
            degrees[v] += 1
        else:
            degrees[v] = 1

    obj = []
    for (u,v) in edges:
        obj.append(degrees[u] + degrees[v])

    return obj

def compute_node_weights(nodes, edges):
    '''
    Computes node weights of a graph.
    A node v is assigned the weight degree(v).

    nodes - list of nodes
    edges - list of edges of the graph
    '''

    degrees = {}
    for (u,v) in edges:
        if u in degrees:
            degrees[u] += 1
        else:
            degrees[u] = 1
        if v in degrees:
            degrees[v] += 1
        else:
            degrees[v] = 1

    obj = []
    for v in nodes:
        if v in degrees:
            obj.append(degrees[v])
        else:
            obj.append(0)

    return obj


def get_ub_conss(dim):
    '''
    get list of left-hand sides of upper bound constraints for a specified dimension
    dim - dimension
    '''
    conss = []
    for i in range(dim):
        cons = dim * [0]
        cons[i] = 1
        conss.append(cons)

    return conss

def compute_degree_conss(nodes, edge_list):
    '''
    generates list of left-hand sides of degree constraints for a given graph
    nodes     - nodes in graph
    egde_list - list of edges in graph
    '''
    conss = []
    for v in nodes:
        cons = []
        for e in range(len(edge_list)):
            if v in edge_list[e]:
                cons.append(1)
            else:
                cons.append(0)
        conss.append(cons)

    return conss

def compute_edge_conss(nodes, edge_list):
    '''
    generates list of left-hand sides of edge constraints for a given graph
    nodes     - nodes in graph
    egde_list - list of edges in graph
    '''
    conss = []
    for i in range(len(edge_list)):
        cons = len(nodes) * [0]
        cons[edge_list[i][0] - 1] = 1
        cons[edge_list[i][1] - 1] = 1
        conss.append(cons)

    return conss

####################################################################################################
#
# FUNCTIONS FOR SETTING UP SEPARATION MODELS
#
####################################################################################################

def matching_create_sepamodel(nodes, edge_list, solver):
    """
    Creates an IP model to separate odd set inequalities for the matching polytope.
    To separate a point x, the used model is

    max sum_{e in Edges} x_e * e_e - parvar
    st  e_{uv} <= v_u                           for each edge {u,v}
        e_{uv} <= v_v                           for each edge {u,v}
        v_u + v_v <= 1 + e_{uv}                 for each edge {u,v}
        sum_{v in Nodes} v_v = 2 * parvar + 1
        e,v binary, parvar integer

    Note that the objective in the model below is not correct, because it will be adapted
    when a separation candidate is specified.

    nodes     - list of nodes
    edge_list - list of edges (assumption: nodes are labeled 1,...,n)
    solver    - solver used by the separation oracle
    """

    model = create_model(solver)

    # add variables to the model
    nodevars = [create_var(model, solver, vtype="B", obj=0.0, name="v%d" % i)
                for i in range(len(nodes))]
    edgevars = [create_var(model, solver, vtype="B", obj=0.0, name="e%d" % i)
                for i in range(len(edge_list))]
    parvar = create_var(model, solver, vtype="I", obj=-1.0, name="parvar")

    # add constraints to the model
    add_cons(model, solver, sum(nodevars[i] for i in range(len(nodes))) == 2 * parvar + 1,
             name="select_odd_set")

    for k in range(len(edge_list)):
        i = edge_list[k][0]
        j = edge_list[k][1]
        add_cons(model, solver, edgevars[k] <= nodevars[i-1], name="edge_{}_{}_1".format(i, j))
        add_cons(model, solver, edgevars[k] <= nodevars[j-1], name="edge_{}_{}_2".format(i, j))
        add_cons(model, solver, nodevars[i-1] + nodevars[j-1] <= edgevars[k] + 1,
                 name="edge_{}_{}_3".format(i, j))

    set_model_sense(model, solver, 1)
    hide_output(model, solver)
    update_model(model, solver)

    return model, nodevars, edgevars, parvar


def stableset_create_sepamodel(nodes, edges, solver):
    """
    Creates an IP model to separate clique inequalities for the stable set polytope.
    To separate a point x, the used model is

    max sum_{v in Edges} x_v * v_v - 1
    st  v_u + v_v <= 1   for each edge {u,v} of the complement graph
        v binary

    Note that the objective in the model below is not correct, because it will be adapted
    when a separation candidate is specified.

    nodes  - list of nodes
    edges  - list of edges of graph (assumption: nodes are labeled 1,...,n)
    solver - solver used by the separation oracle
    """

    # computes edges of complement graph
    local_edges = list(edges)
    for i in range(len(local_edges)):
        pair = list(local_edges[i])
        pair.sort()
        local_edges[i] = pair
    local_edges.sort()

    counter_edges = []
    for u in range(1,len(nodes)+1):
        for v in range(u+1,len(nodes)+1):
            if not [u,v] in local_edges:
                counter_edges.append([u,v])

    model = create_model(solver)

    # add variables to the model
    nodevars = [create_var(model, solver, vtype="B", obj=0.0, name="v%d" % i)
                for i in range(len(nodes))]

    # add constraints to the model
    for i in range(len(counter_edges)):
        u = counter_edges[i][0] - 1
        v = counter_edges[i][1] - 1
        add_cons(model, solver, nodevars[u] + nodevars[v] <= 1, name="nonedge_{}_{}".format(u, v))

    set_model_sense(model, solver, 1)
    hide_output(model, solver)
    update_model(model, solver)

    return model, nodevars

####################################################################################################
#
# FUNCTIONS FOR SETTING UP LP RELAXATIONS
#
####################################################################################################

def matching_create_model(nodes, edge_list, objcoefs, solver, initconss):
    """
    Creates a superpolytope of the matching polytope using constraints from a specified list.
    nodes     - nodes of the underlying graph
    edge_list - list of edges of the underlying graph
    objcoefs  - objective coefficients of edges
    solver    - solver used to solve relaxation
    initconss - {0,1,2} to encode whether no/box/degree constraints shall be used
                to initialize the superpolytope
    """

    model = create_model(solver)

    # add variables to the model
    edgevars = [create_var(model, solver, vtype="C", lb=-infinity(model, solver),
                           obj=objcoefs[i], name="e%d" % i) for i in range(len(edge_list))]

    if initconss >= 1:
        # add box constraints
        for i in range(len(edgevars)):
            add_cons(model, solver, edgevars[i] <= 1, "ub_%d" % i)
            add_cons(model, solver, edgevars[i] >= 0, "lb_%d" % i)

    if initconss == 2:
        # add degree constraints
        for i in range(len(nodes)):
            cons = [j for j in range(len(edge_list)) if i+1 in edge_list[j]]
            if len(cons) > 0:
                add_cons(model, solver, sum(edgevars[j] for j in cons) <= 1, "degree_%d" % i)

    set_model_sense(model, solver, 1)
    hide_output(model, solver)
    update_model(model, solver)

    return model, edgevars

def stableset_create_model(nodes, edge_list, objcoefs, solver, initconss):
    """
    Creates a superpolytope of the stable set polytope using constraints from a specified list.
    nodes     - nodes of the underlying graph
    edge_list - list of edges of the underlying graph
    objcoefs  - objective coefficients of edges
    solver    - solver used to solve relaxation
    initconss - {0,1,2} to encode whether no/box/edge constraints shall be used
                to initialize the superpolytope
    """

    model = create_model(solver)

    # add variables to the model
    nodevars = [create_var(model, solver, vtype="C", obj=objcoefs[i], name="v%d" % i)
                for i in range(len(nodes))]

    # add constraints to the model
    if initconss >= 1:
        # add box constraints
        for i in range(len(nodevars)):
            add_cons(model, solver, nodevars[i] <= 1, "ub_%d" % i)
            add_cons(model, solver, nodevars[i] >= 0, "lb_%d" % i)

    if initconss == 2:
        # add edge constraints
        for i in range(len(edge_list)):
            u = edge_list[i][0] - 1
            v = edge_list[i][1] - 1
            add_cons(model, solver, nodevars[u] + nodevars[v] <= 1, "edge_%d_%d" % (u,v))


    set_model_sense(model, solver, 1)
    hide_output(model, solver)
    update_model(model, solver)

    return model, nodevars

####################################################################################################
#
# MISCELLANEOUS FUNCTIONS
#
####################################################################################################



def inner_radius_simplex(dim):
    """
    computes the inner radius of the standard simplex in dimension dim
    """
    return 1/numpy.sqrt(dim)

def silentprint(arg, silent):
    '''
    prints an argument to the terminal if not silent
    arg    - argument to print
    silent - whether arg shall not printed
    '''

    if not silent:
        print(arg)

def isGE(a, b, precision):
    '''
    checks whether each entry of one lists of numbers is at least as large as the corresponding
    entry of a second list (up to a specified precision)
    a         - first list of numbers
    b         - second list of numbers
    precision - precision to use
    '''

    if min( list((a[i] - b[i]) for i in range(len(a))) ) >= -precision:
        return True

    return False

def closest_point_linesegment(a, b, target):
    '''
    computes the point on a line segment that is closest to a target point
    a      - first end point of line segment
    b      - second end point of line segment
    target - target vector
    '''

    # compute closest point on line
    num = sum((b[i] - a[i])*(target[i] - a[i]) for i in range(len(a)))

    denom = sum((b[i] - a[i])**2 for i in range(len(a)))

    # handle the case that a and b are the same
    if denom <= 0.00001:
        return a

    alpha = num / denom

    # the closest point is contained on the line segment
    if alpha <= 1 and alpha >= 0:
        return [((1-alpha) * a[i] + alpha * b[i]) for i in range(len(a))]

    # closest point is on the boundary of line segment
    if alpha > 1:
        return b
    return a
