import numpy

from MIP import *
from auxiliary import *


####################################################################################################
#
# INTERFACE CLASSES FOR PROBLEMS AND AUXILIARY PROBLEMS
#
####################################################################################################


class PROBLEM:
    '''
    interface class to classes of concrete problems

    class variables:
    instantiation - class of concrete problem
    '''

    def __init__(self, instancefile, problemtype, solver, initconss):
        '''
        initializes interface class
        instancefile - path to file encoding instance
        problemtype  - type of problem for which the class is defined
        solver       - solver used to solve the problem
        initconss    - {0,1,2} to encode whether no/box/standard constraints shall be
                       included in model
        '''

        if problemtype == "matching":
            self.instantiation = MATCHINGPROBLEM(instancefile, solver, initconss, False)
        elif problemtype == "weightmatching":
            self.instantiation = MATCHINGPROBLEM(instancefile, solver, initconss, True)
        elif problemtype == "stableset":
            self.instantiation = STABLESETPROBLEM(instancefile, solver, initconss, False)
        elif problemtype == "weightstableset":
            self.instantiation = STABLESETPROBLEM(instancefile, solver, initconss, True)

    def add_cut(self, cut):
        '''
        adds cut to problem
        cut - cut to be added
        '''
        self.instantiation.add_cut(cut)

    def optimize(self):
        '''
        returns the optimal solution value of the problem
        '''
        return self.instantiation.optimize()

    def get_opt_solution(self):
        '''
        returns an optimal solution of the problem
        '''
        return self.instantiation.get_opt_solution()

class AUXPROBLEM:
    '''
    interface class to classes of concrete problems

    class variables:
    instantiation - class of concrete problem
    '''

    def __init__(self, data, problemtype, solver):
        '''
        initializes interface class
        data         - data needed to initialize the concrete problem class
        problemtype  - type of problem for which the class is defined
        solver       - solver used to solve the problem
        '''

        if problemtype == "lineprojection":
            self.instantiation = LINEPROJECTION(data[0], data[1], data[2], solver)
        elif problemtype == "closestpoint":
            self.instantiation = CLOSESTPOINTPROJECTION(data[0], data[1], data[2], solver)

    def solve(self):
        '''
        solves the auxiliary problem
        '''
        return self.instantiation.solve()




####################################################################################################
#
# INSTANTIATIONS OF PROBLEM CLASSES
#
####################################################################################################


class MATCHINGPROBLEM:
    '''
    class of matching problem

    class variables:
    nodes     - nodes of the underlying graph
    edge_list - list of edges of underlying graph
    obj       - objective vector
    solver    - solver used to solve the problem
    model     - LP relaxation model of matching problem
    edgevars  - edge variables in model
    '''

    def __init__(self, instancefile, solver, initconss, weighted):
        '''
        initializes matching problem class
        instancefile - path to file encoding instance
        solver       - solver used by oracles
        initconss    - {0,1,2} to encode whether no/box/standard constraints shall be
                       included in model
        weighted     - whether we shall generate our own objective function
        '''

        # read instance
        self.nodes, self.edge_list, self.obj = read_graph_from_file(instancefile)
        self.solver = solver

        if weighted:
            self.obj = compute_edge_weights(self.nodes, self.edge_list)

        self.model, self.edgevars = matching_create_model(self.nodes, self.edge_list,
                                                          self.obj, solver, initconss)

    def optimize(self):
        '''
        returns the optimal solution value of the problem
        '''

        model = self.model
        model.optimize()

        return get_obj_val(model, self.solver)

    def get_opt_solution(self):
        '''
        returns an optimal solution of the problem
        '''

        model = self.model
        model.optimize()

        return get_solution_array(model, self.solver, self.edgevars)


    def add_cut(self, coefs):
        '''
        adds cut to problem
        coefs - coefficients of the cut to be added
        '''
        add_cut(self.model, self.solver, sum(coefs[i] * self.edgevars[i]
                                             for i in range(len(coefs))) <= 1 , "")


class STABLESETPROBLEM:
    '''
    class of stable set problem

    class variables:
    nodes     - nodes of the underlying graph
    edge_list - list of edges of underlying graph
    obj       - objective vector
    solver    - solver used to solve the problem
    model     - LP relaxation model of stable set problem
    nodevars  - node variables in model
    '''

    def __init__(self, instancefile, solver, initconss, weighted):
        '''
        initializes stable set problem class
        instancefile - path to file encoding instance
        solver       - solver used by oracles
        initconss    - {0,1,2} to encode whether no/box/standard constraints shall be
                       included in model
        weighted     - whether we shall generate our own objective function
        '''

        # read instance
        self.nodes, self.edge_list, self.obj = read_graph_from_file(instancefile)
        self.obj = self.obj[:len(self.nodes)]
        self.solver = solver

        if weighted:
            self.obj = compute_node_weights(self.nodes, self.edge_list)

        self.model, self.nodevars = stableset_create_model(self.nodes, self.edge_list,
                                                           self.obj, solver, initconss)


    def optimize(self):
        '''
        returns the optimal solution value of the problem
        '''

        model = self.model
        model.optimize()

        return get_obj_val(model, self.solver)

    def get_opt_solution(self):
        '''
        returns an optimal solution of the problem
        '''

        model = self.model
        model.optimize()

        return get_solution_array(model, self.solver, self.nodevars)


    def add_cut(self, coefs):
        '''
        adds cut to problem
        coefs - coefficients of the cut to be added
        '''
        add_cut(self.model, self.solver, sum(coefs[i] * self.nodevars[i]
                                             for i in range(len(coefs))) <= 1 , "")


####################################################################################################
#
# INSTANTIATIONS OF AUXILIARY PROBLEM CLASSES
#
####################################################################################################


class CLOSESTPOINTPROJECTION:
    '''
    For a convex set A defined by points a_i and a target point t, the class allows to compute a
    point q in A and a point p such that q is as close as possible to t and either
    (1) p <= q, or
    (2) p = q.

    class variables:
    target            - target point
    conss             - points spanning the convex set A
    use_nonnegativity - True is we are in case (1), False otherwise
    solver            - solver used to solve the problem
    '''

    def __init__(self, target, conss, use_nonnegativity, solver):
        '''
        initializes the problem class
        target            - target point
        conss             - points spanning the convex set A
        use_nonnegativity - True is we are in case (1), False otherwise
        solver            - solver used to solve the problem
        '''
        self.target = target
        self.conss = conss
        self.use_nonnegativity = use_nonnegativity
        self.solver = solver


    def solve(self):
        '''
        solves the closest point on line segment problem
        '''
        target = self.target
        conss = self.conss
        use_nonnegativity = self.use_nonnegativity
        solver = self.solver

        model = create_num_model(solver)
        set_model_sense(model, solver, -1)

        # create variables
        objvar = create_var(model, solver, vtype="C", obj=1.0, name="obj", lb=-infinity(model, solver))
        conv_mults = [create_var(model, solver, vtype="C", obj=0.0, name="lambda%d" % i, lb=0.0)
                      for i in range(len(conss))]
        qvars = [create_var(model, solver, vtype="C", obj=0.0, name="q%d" % i,
                            lb=-infinity(model, solver)) for i in range(len(target))]

        # add constraints

        # q_i <= sum multipliers * coefficients (or == )
        if use_nonnegativity:
            for i in range(len(target)):
                add_cons(model, solver, qvars[i] <= sum(conss[c][i] * conv_mults[c]
                                                        for c in range(len(conss)) ),
                         "linkpmult%d" % i)
        else:
            for i in range(len(target)):
                add_cons(model, solver, qvars[i] == sum(conss[c][i] * conv_mults[c]
                                                        for c in range(len(conss)) ),
                         "linkpmult%d" % i)

        # bound on convex multipliers
        for i in range(len(conss)):
            add_cons(model, solver, conv_mults[i] <= 1, "ub_lambda%d" % i)
        add_cons(model, solver, sum(conv_mults[i] for i in range(len(conss))) == 1, "convex")

        # link objective
        add_cons(model, solver, sum(qvars[i]*qvars[i] - 2*qvars[i]*target[i]
                                    for i in range(len(target))) <= objvar, name = "objcons")

        hide_output(model, solver)
        update_model(model, solver)

        model.optimize()

        # extract solution
        solution = len(target) * [0]
        for c in range(len(conss)):
            for i in range(len(target)):
                solution[i] += conss[c][i] * get_sol_val(model, solver, get_solution(model, solver),
                                                         conv_mults[c])

        return solution


