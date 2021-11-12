import numpy

from MIP import *
from auxiliary import *


####################################################################################################
#
# INTERFACE CLASS FOR ORACLES
#
####################################################################################################

class ORACLE:
    '''
    interface class to oracles for concrete classes of problems

    class variables:
    instantiation - oracle class of concrete problem
    obj           - objective vector of concrete problem
    inner_radius  - radius of inner ball of concrete problem
    '''

    def __init__(self, instancefile, problemtype, solver):
        '''
        initializes interface class
        instancefile - path to file encoding instance
        problemtype  - type of problem for which an oracle is defined
        solver       - solver used by oracles
        '''

        if problemtype == "matching":
            self.instantiation = MATCHINGORACLE(instancefile, solver, False)
        elif problemtype == "weightmatching":
            self.instantiation = MATCHINGORACLE(instancefile, solver, True)
        elif problemtype == "stableset":
            self.instantiation = STABLESETORACLE(instancefile, solver, False)
        elif problemtype == "weightstableset":
            self.instantiation = STABLESETORACLE(instancefile, solver, True)

        self.obj = self.instantiation.get_obj()
        self.inner_radius = self.instantiation.get_inner_radius()

    def get_obj(self):
        '''
        returns objective vector
        '''
        return self.obj

    def get_inner_radius(self):
        '''
        returns radius of inner ball
        '''
        return self.inner_radius

    def get_standard_cuts(self):
        '''
        return standard cuts of problem
        '''
        return self.instantiation.get_standard_cuts()

    def separate_point(self, point, precision):
        '''
        separates a given point up to a certain precision
        point     - point to separate
        precision - precision to decide whether a violated cut exists
        '''
        return self.instantiation.separate_point(point, precision)



####################################################################################################
#
# INSTANTIATIONS OF ORACLES
#
####################################################################################################


class MATCHINGORACLE:
    '''
    separation oracle class for the matching problem

    class variables:
    nodes            - list of nodes of underlying graph
    edge_list        - edge list of underlying graph
    obj              - objective of problem instance
    solver           - solver used by the oracle
    inner_radius     - radius of inner ball of concrete problem
    separation_model - optimization model to generate cuts
    nodevars         - node variables of separation model
    edgevars         - edge variables of separation model
    parvar           - parity variable of separation model
    degree_conss     - degree constraints
    '''

    def __init__(self, instancefile, solver, weighted):
        '''
        initializes matching oracle class
        instancefile - path to file encoding instance
        solver       - solver used by oracles
        weighted     - whether we shall generate our own objective function
        '''

        # read instance
        self.nodes, self.edge_list, self.obj = read_graph_from_file(instancefile)
        self.solver = solver
        self.inner_radius = inner_radius_simplex(len(self.edge_list))

        if weighted:
            self.obj = compute_edge_weights(self.nodes, self.edge_list)

        self.degree_conss = compute_degree_conss(self.nodes, self.edge_list)

        self.separation_model, self.nodevars, self.edgevars, self.parvar\
            = matching_create_sepamodel(self.nodes, self.edge_list, solver)

    def get_obj(self):
        '''
        returns objective vector
        '''
        return self.obj

    def get_inner_radius(self):
        '''
        returns radius of inner ball
        '''
        return self.inner_radius

    def get_standard_cuts(self):
        '''
        return degree constraints
        '''
        return self.degree_conss

    def separate_point(self, point, precision):
        '''
        separates a given point up to a certain precision
        point     - point to separate
        precision - precision to decide whether a violated cut exists
        '''

        model = self.separation_model
        nodevars = self.nodevars
        edgevars = self.edgevars
        parvar = self.parvar
        solver = self.solver
        edge_list = self.edge_list
        nodes = self.nodes

        # separate odd set inequalities
        vars = edgevars + [parvar]
        coefs = point + [-1]
        change_objective(model, solver, vars, coefs, 1)
        update_model(model, solver)
        model.optimize()

        max_violation = get_obj_val(model, solver)
        res = []
        if max_violation > precision:
            # there is a violated odd set inequality

            sol = get_solution(model, solver)
            nodes_oddset = [i for i in range(len(nodevars))
                            if get_sol_val(model, solver, sol, nodevars[i]) > 0.5]

            # we scale the inequality such that the right-hand side is 1
            scale = 2 / (len(nodes_oddset) - 1)

            for i in range(len(edgevars)):
                if edge_list[i][0] - 1 in nodes_oddset and edge_list[i][1] - 1 in nodes_oddset:
                    res.append(scale)
                else:
                    res.append(0)

        # check whether degree constraints are violated
        max_degree = -1
        for v in nodes:
            val = 0
            for e in range(len(edge_list)):
                if v in edge_list[e]:
                    val += point[e]

            violation = val - 1

            if violation > max(max_violation, precision):
                max_degree = v
                max_violation = violation

        # if a degree constraint is more violated than an odd set constraint, update cut
        if max_degree != -1:
            res = []
            for e in range(len(edge_list)):
                if max_degree in edge_list[e]:
                    res.append(1)
                else:
                    res.append(0)
        return res


class STABLESETORACLE:
    '''
    separation oracle class for the stable set problem

    class variables:
    nodes              - list of nodes of underlying graph
    counter_edge_list  - edge list of complement of underlying graph
    obj                - objective of problem instance
    solver             - solver used by the oracle
    inner_radius       - radius of inner ball of concrete problem
    separation_model   - optimization model to generate cuts
    nodevars           - node variables of separation model
    counter_edge_conss - list of edge constraints in complement graph
    '''

    def __init__(self, instancefile, solver, weighted):
        '''
        initializes stable set oracle class
        instancefile - path to file encoding instance
        solver       - solver used by oracles
        weighted     - whether we shall generate our own objective function
        '''

        # read instance
        self.nodes, self.edge_list, self.obj = read_graph_from_file(instancefile)
        self.obj = self.obj[:len(self.nodes)]
        self.solver = solver
        self.inner_radius = inner_radius_simplex(len(self.nodes))

        if weighted:
            self.obj = compute_node_weights(self.nodes, self.edge_list)

        self.edge_conss = compute_edge_conss(self.nodes, self.edge_list)

        self.separation_model, self.nodevars\
            = stableset_create_sepamodel(self.nodes, self.edge_list, solver)

    def get_obj(self):
        '''
        returns objective vector
        '''
        return self.obj

    def get_inner_radius(self):
        '''
        returns radius of inner ball
        '''
        return self.inner_radius

    def get_standard_cuts(self):
        '''
        return edge constraints of complement graph
        '''
        return self.edge_conss

    def separate_point(self, point, precision):
        '''
        separates a given point up to a certain precision
        point     - point to separate
        precision - precision to decide whether a violated cut exists
        '''

        model = self.separation_model
        nodevars = self.nodevars
        nodes = self.nodes
        solver = self.solver

        # separate clique inequalities
        change_objective(model, solver, nodevars, point, 1)
        update_model(model, solver)
        model.optimize()

        # there is a violated clique inequality
        res = []
        if get_obj_val(model, solver) - 1 > precision:
            sol = get_solution(model, solver)
            for i in range(len(nodevars)):
                if get_sol_val(model, solver, sol, nodevars[i]) > 0.5:
                    res.append(1)
                else:
                    res.append(0)

        return res
