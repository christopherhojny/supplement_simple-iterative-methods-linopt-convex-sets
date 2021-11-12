from oracles import *
from problems import *
from auxiliary import *

import numpy
import time


def packing_algorithm(oracle, precision, maxiter, corrective_freq, lbopt, initconss, solver,
                      verif_model, silent=True):
    '''
    runs our algorithm for packing problems
    oracle          - oracle to generate cuts for problem instance
    precision       - precision used to decide whether violated cuts exist/we are optimal
    maxiter         - maximum number of iterations
    corrective_freq - frequency of fully corrective steps
    lbopt           - lower bound on the optimal objective value
    initconss       - initial constraints for fully corrective step
    solver          - solver used by oracle
    verif_model     - model to verify termination criterion
    silent          - (optional) whether no output to the terminal shall be produced
    '''

    # get the objective coefficients and the radius of the inner ball
    obj = oracle.get_obj()

    # initialize parameters
    cur_gamma = lbopt
    cur_q = [0 for i in obj]
    cur_f = [val/cur_gamma for val in obj]

    # initialize null vector necessary for projection on line segment
    null_vector = [0 for i in obj]

    # initialize lists for generating statistics
    separated_cons = [cur_q]
    sepa_rounds = []
    found_solutions = []
    gamma_vals = [cur_gamma]
    all_f = [cur_f]
    all_q = [cur_q]

    iterationcnt = 0
    primalcnt = 0
    dualcnt = 0

    # the main loop
    starttime = time.time()
    while True:
        silentprint(["iteration", iterationcnt], silent)
        silentprint(["f", cur_f], silent)

        # stop if we have approximated f well enough
        if isGE(cur_q, cur_f, precision):
            dual_val = verif_model.optimize()

            # we are close enough to the primal value
            if dual_val / cur_gamma < 1.01:
                break

        # check whether we want to perform a fully corrective step
        fully_corrective = corrective_freq > 0 and iterationcnt % corrective_freq == 0

        # compute separation candidate x and try to separate it
        tau = sum ( (cur_f[i] - cur_q[i]) * (cur_f[i] + cur_q[i])
            for i in range(len(cur_f)) )
        assert( tau > 0 )
        x = [2 * (cur_f[i] - cur_q[i]) / tau for i in range(len(cur_f))]
        cons = oracle.separate_point(x, precision)

        if len(cons) == 0:
            # x is feasible
            found_solutions.append(x)
            silentprint("found solution", silent)

            # update gamma and f
            cur_gamma = sum(obj[i] * x[i] for i in range(len(obj)))
            cur_f = [val/cur_gamma for val in obj]

            if fully_corrective:
                projection = AUXPROBLEM([cur_f, separated_cons + initconss, True],
                                        "closestpoint", solver)
                cur_q = projection.solve()
            else:
                # project f onto line segment between q and 0
                cur_q = closest_point_linesegment(cur_q, null_vector, cur_f)

            primalcnt += 1

        else:

            # we have found a separating inequality
            separated_cons.append(cons)
            sepa_rounds.append(iterationcnt + 1)
            verif_model.add_cut(cons)
            silentprint("separated_cons", silent)
            silentprint(["cons", cons], silent)

            if fully_corrective:
                projection = AUXPROBLEM([cur_f, separated_cons + initconss, True],
                                        "closestpoint", solver)
                cur_q = projection.solve()
            else:
                # project f onto line segment between q and cons
                cur_q = closest_point_linesegment(cur_q, cons, cur_f)
            dualcnt += 1

        silentprint(["x", x], silent)
        silentprint(["cut", cons], silent)

        # compute componentwise minimum of f and q (theoretically not necessary in fully corrective
        # step, but avoids numerical difficulties due to solving a quadratic program)
        cur_q = [min(cur_q[i], cur_f[i]) for i in range(len(cur_q))]

        iterationcnt += 1
        gamma_vals.append(cur_gamma)
        all_f.append(cur_f)
        all_q.append(cur_q)

        if iterationcnt >= maxiter:
            silentprint("terminate early", silent)
            break

    endtime = time.time()

    # print statistics
    print("nPrimalDHHWiterations\t%d" % primalcnt)
    print("nDualDHHWiterations\t%d" % dualcnt)
    print("nDHHWiterations\t%d" % iterationcnt)
    print("DHHWtime\t%f" % (endtime - starttime))

    return cur_gamma, separated_cons, found_solutions, gamma_vals, sepa_rounds, all_f, all_q

