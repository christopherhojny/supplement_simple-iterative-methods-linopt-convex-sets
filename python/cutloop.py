from oracles import *
from problems import *

import numpy
import time

def cut_loop_LP(problem, oracle, precision, maxiter, lbopt=-1):
    '''
    runs standard cut loop to solve an IP
    problem   - LP relaxation of problem instance
    oracle    - oracle to generate cuts for problem instance
    precision - precision used to decide whether violated cuts exist
    maxiter   - maximum number of iterations of cut loop
    lbopt     - (optional) lower bound on the optimal objective value
    '''

    cnt = 0
    obj_vals = []

    # the cut loop
    starttime = time.time()
    while cnt < maxiter:
        cnt += 1

        # solve the LP relaxation
        obj_val = problem.optimize()
        x = problem.get_opt_solution()
        obj_vals.append(obj_val)

        # separate LP solution
        cons = oracle.separate_point(x, precision)

        # if not violated cut exists or we have hit the lower bound, break
        if len(cons) == 0 or isGE([lbopt], [obj_val], precision):
            break

        # update LP relaxation by separated cut
        problem.add_cut(cons)

    endtime = time.time()

    # print statistics
    print("nLPiterations\t%d" % cnt)
    print("LPtime\t%f" % (endtime - starttime))

    return obj_vals
