import numpy

try:
    from pyscipopt import Model as ScipModel
except ImportError:
    pass

try:
    from gurobipy import Model as GrbModel
    from gurobipy import GRB
except ImportError:
    pass

####################################################################################################
#
# MIP SOLVER FUNCTIONS
#
####################################################################################################

def create_num_model(solver):
    '''
    creates empty model with low numerical precision
    solver - solver to be used
    '''
    if solver == "scip":
        model = ScipModel()
        model.setRealParam("numerics/feastol", 0.0001)
        model.setRealParam("numerics/dualfeastol", 0.0001)
        model.setRealParam("limits/gap", 0.0001)
        model.setRealParam("limits/absgap", 1e-5)
        return model
    return GrbModel();

def create_model(solver):
    '''
    creates empty model
    solver - solver to be used
    '''
    if solver == "scip":
        return ScipModel()
    return GrbModel();


def create_var(model, solver, vtype="B", obj=0.0, name="", lb=0.0):
    '''
    creates variable and adds it to a model
    model  - model to which variable is added
    solver - solver to be used
    vtype  - (optional) variable type ("B", "I", "C")
    obj    - (optional) objective coefficient
    name   - (optional) variable name
    lb     - (optional) lower bound
    '''
    if solver == "scip":
        return model.addVar(vtype=vtype, obj=obj, name=name, lb=lb)
    else:
        mytype = GRB.BINARY
        if vtype == "I":
            mytype = GRB.INTEGER
        elif vtype == "C":
            mytype = GRB.CONTINUOUS

        return model.addVar(vtype=mytype, obj=obj, name=name, lb=lb)

def add_cons(model, solver, expr, name):
    '''
    adds constraint to a model
    model  - model to which constraint is added
    solver - solver to be used
    expr   - linear or nonlinear expression used as constraint
    name   - constraint name
    '''
    if solver == "scip":
        model.addCons(expr, name=name)
    else:
        model.addConstr(expr, name=name)

def add_cut(model, solver, expr, name):
    '''
    adds a cut to a model
    model  - model to which constraint is added
    solver - solver to be used
    expr   - linear or nonlinear expression used as cut
    name   - cut name
    '''
    if solver == "scip":
        model.freeTransform()
        model.addCons(expr, name=name)
    else:
        model.addConstr(expr, name=name)

def set_model_sense(model, solver, sense):
    '''
    sets the objective sense of the model
    model  - model to change the objective sense for
    solver - solver to be used
    sense  - positive number for maximization, else minimization
    '''
    if solver == "scip":
        if sense > 0:
            model.setMaximize()
        else:
            model.setMinimize()
    else:
        if sense > 0:
            model.ModelSense = GRB.MAXIMIZE
        else:
            model.ModelSense = GRB.MINIMIZE

def hide_output(model, solver):
    '''
    hide optimization output
    model  - model whose output shall be hidden
    solver - solver to be used
    '''
    if solver == "scip":
        model.hideOutput()
    else:
        model.Params.OutputFlag = 0

def update_model(model, solver):
    '''
    update model by previous changes
    model  - model to be updated
    solver - solver to be used
    '''
    if solver == "gurobi":
        model.update()

def get_obj_val(model, solver):
    '''
    returns optimal objective value
    model  - model to extract objective value from
    solver - solver to be used
    '''
    if solver == "scip":
        if model.getStatus() == "unbounded" or model.getStatus() == "inforunb":
            return numpy.nan
        return model.getObjVal()

    if model.Status > 2:
        return numpy.nan
    return model.ObjVal

def get_solution(model, solver):
    '''
    returns optimal solution
    model  - model to extract solution from
    solver - solver to be used
    '''
    if solver == "scip":
        return model.getBestSol()
    return None

def get_solution_array(model, solver, vars):
    '''
    returns optimal solution as an array
    model  - model to extract solution from
    solver - solver to be used
    '''
    if solver == "gurobi":
        if model.Status > 2:
            return [numpy.nan for v in model.getVars()]
        else:
            return [v.X for v in model.getVars()]
    return [get_sol_val(model, solver, get_solution(model, solver), v) for v in vars]

def get_sol_val(model, solver, sol, var):
    '''
    returns value of variable in a solution
    model  - model to extract solution value from
    solver - solver to be used
    sol    - solution from which value is extracted
    var    - variable to get value for
    '''
    if solver == "scip":
        return model.getSolVal(sol, var)

    return var.X

def change_objective(model, solver, vars, coefs, sense):
    '''
    changes the objective function
    model  - model for which the objective has to be changed
    solver - solver to be used
    vars   - variables contributing to objective
    coefs  - coefficients of variables
    sense  - positive number for maximization, else minimization
    '''
    if solver == "scip":
        model.freeTransform()
        if sense > 0:
            model.chgReoptObjective(sum(coefs[i] * vars[i] for i in range(len(coefs))),
                                    sense="maximize")
        else:
            model.chgReoptObjective(sum(coefs[i] * vars[i] for i in range(len(coefs))),
                                    sense="minimize")
    else:
         model.setObjective(sum(coefs[i] * vars[i] for i in range(len(coefs))))


def infinity(model, solver):
    '''
    return infinity
    model  - model for which infinity shall be determined
    solver - solver to be used
    '''
    if solver == "scip":
        return model.infinity()
    else:
        return GRB.INFINITY
