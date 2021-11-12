# Content

This repository contains code used for two different articles:

1) A Simple Method for Convex Optimization in the Oracle Model

and

2) Simple Iterative Methods for Linear Optimization over Convex Sets

both by Daniel Dadush, Christopher Hojny, Sophie Huiberts, and Stefan
Weltge. The code of Article 1 is written in Julia, whereas the code of
Article 2 is a Python implementation. The different codes are, for
this reason, contained in the subdirectories "julia" and "python",
respectively. Note that Article 2 is a previous version of Article 1
discussing a different algorithm. Thus, the Julia and Python codes do
not implement the same algorithm.

# 1) A Simple Method for Convex Optimization in the Oracle Model

Additional information about the code for the article

   A Simple Method for Convex Optimization in the Oracle Model
   by Daniel Dadush, Christopher Hojny, Sophie Huiberts, and Stefan Weltge.

## I PREREQUISITES

To run the code, you need a working installation of

- Julia;
- Gurobi and its Julia interface via JuMP.

Information on Gurobi can be found at https://www.gurobi.com/.
JuMP can be found at https://github.com/jump-dev/Gurobi.jl.

Required Julia packages for the main code are

- Dates;
- DecisionTree;
- Gurobi;
- JuMP;
- LinearAlgebra;
- Plots.


## II STEPS OF THE CODE

1. To run the program, enter "julia main.jl". This will run all test instances
   listed in "data.jl" using standard parameters.

   Additional parameters can be specified via:

   -p  generate plots, which are stored in "plots/"
   -r  use relative gaps rather than absolute gaps to generate plots
   -s  print statistics
   -v  print log messages
   -w  write statistics to "statistics/"; each statistics file gets
       a time stamp to distinguish different runs
   -i  initialize lower bound by (optimal) value given in "data.jl"
   -ii use almost optimal initialization
   -ns disable smart oracles

2. The problems are created and solved using externally defined oracles.


### III STRUCTURE OF THE CODE

The code separates the main algorithm and the definition of the oracles to
be called and the relaxations to be solved. This allows to easily extend
the code to be able to deal with further problem classes. In Section V
we explain how to extend the code, whereas this section explains its general
structure. We illustrate the functionality of the classes that have to
be provided by a user using matching as an example.

main.jl contains the main routine of the algorithm. Basic
parameters are defined, a cutting plane loop is called using different oracles
for generating new cuts, and the statistics/plots are generated. Oracle calls
and manipulations of LP relaxations are implemented in external classes.

loop.py implements the separation loop.

the four different methods to generate separation candidates are implemented in

analytic.jl
cutloop.jl
ellipsoid.jl
our.jl

using the analytic center, LP solution, midpoint of elliposoid, and the
point suggested by the conic algorithm as separation candidate

each problem class has its own oracle; for our tests we use

oracle_lpboost.jl
oracle_matching.jl
oracle_maxcut.jl

data.jl contains the data used for our experiments

generate_plots_and_statistics.jl contains methods to generate plots and
statistics

graph.jl contains methods to read and write graphs for the
matching problems


cutloop.py implements a cutting plane procedure.


## IV REPRODUCING EXPERIMENTS

To reproduce the experiments, call our code with the following parameters

   julia main.jl -p -r -s -w
   julia main.jl -p -r -s -w -i
   julia main.jl -p -r -s -w -ii
   julia main.jl -p -r -s -w -ns

To be able to run the code successfully, the instances of LPboost and
from Color02 need to be generated as described in

   instances/lpboost/notes.txt
   instances/lpboost/color02.txt

If you want to run the code only on the instances provided in this
repository, you need to replace "data.jl" by "data_selection.jl".

## V EXTENDING THE CURRENT IMPLEMENTATION

To extend the existing code to solve further problem classes, the user
has to provide a new oracle, and has to tell the main code when to
call the new oracle. In the following, we assume that the type <type>
will be used to identify the new problem type.

1. Defining a New Oracle

   A new oracle has to be defined via implementing a struct and two
   functions.

   The struct contains all data required by the oracle; mandatory data
   is

   - initineqs inequalities present in the initial relaxation
   - initeqs   equations present in the initial relaxation
   - obj       the objective of the problem
   - R         radius of an origin-centered ball containing the region
     	       described by the oracle
   - feastol   feasibility tolerance to decide whether violated
     	       inequality exists

   The necessary functions are a constructor that reads an instance
   from a file and sets the data of the struct as well as a function
   that separates additional inequalities. In the following, we call
   these functions CONSTRUCTOR and SEPARATOR, respectively.

2. Including the Oracle

   The standard implementation can be extended by adding the new
   instances to be solved together with the corresponding oracle to
   "data.jl" via

   push!(names, "new problem type")
   push!(files, ["/path/to/instance1", ... , "/path/to/instanceN"])
   push!(ors, CONSTRUCTOR)
   push!(seps, SEPARATOR)

   and including the new oracle in "main.jl".



# 2) Simple Iterative Methods for Linear Optimization over Convex Sets

Additional information about the code for the article

   Simple Iterative Methods for Linear Optimization over Convex Sets
   by Daniel Dadush, Christopher Hojny, Sophie Huiberts, and Stefan Weltge.


## I PREREQUISITES

To run the code, you need a working installation of

- Python;
- SCIP 7 and its Python interface OR Gurobi and its Python interface.

Installation details for SCIP and its Python interface can be found at
https://www.scipopt.org/ and https://github.com/SCIP-Interfaces/PySCIPOpt.
Information on Gurobi can be found at https://www.gurobi.com/.

Required Python packages for the main code are

- math;
- matplotlib.pyplot;
- numpy;
- os;
- sys;
- time.

For generating instances of the matching problem, also the following
packages are required.

- anytree;
- anytree.util;
- random.

In the following, we assume that all Python commands invoke Python 3. If
your operating system does not call Python 3 using the "python" command,
you need to adapt the respective occurences.


## II STEPS OF THE CODE

1. To run the program, enter
   "python compare.py --file=</path/to/file> --type=<problemtype>"
   to specify the instance file and which problem shall be solved. Currently
   supported problem types are "matching", "weightmatching", "stableset",
   and "weightstableset".

   Additional parameters can be specified via:

   --precision=<value used for numerical comparisons>
   --maxiter=<iteration limit>
   --solver=<scip|gurobi>
   --nosilent (to print logs to terminal)
   --corrfreq=<frequency of fully corrective steps>
   --initconns=<0|1|2> (to specify which initial constraint are used;
                        0: no, 1: upper bound, 2: upper bound + basic)

2. We assume that the instances are encoded in a slight adaptation
   of the DIMACS format, i.e., rows starting with

   'c' mark comment lines
   'p edge' provide information on the instance (e.g., p edge 30 100
      encodes a graph with 30 vertices and 100 edges)
   'e' contain edges (e.g., 'e 1 2' encodes the edge {1, 2})
      it is possible to attach a third numerical value as edge weight

   We assume that all vertex labels are within the range {1, ..., #vertices}.

3. The problems are created and solved using externally defined oracles.


## III STRUCTURE OF THE CODE

The code separates the main algorithm and the definition of the oracles to
be called and the relaxations to be solved. This allows to easily extend
the code to be able to deal with further problem classes. In Section V
we explain how to extend the code, whereas this section explains its general
structure. We illustrate the functionality of the classes that have to
be provided by a user using matching as an example.

compare.py contains the main routine of the algorithm. Basic
parameters are defined, the packing algorithm and LP cutting plane loop
are called, and the experiments are evaluated. Oracle calls and manipulations
of LP relaxations are implemented in external classes.

packing.py implements the packing algorithm.

cutloop.py implements a cutting plane procedure.

oracles.py contains the interface between the oracles used by the packing
algorithm and the implementation of the oracles. The communication between
the packing algorithm and the oracles is organized via the interface class
ORACLE with its methods

- get_obj() to access the objective coefficient vector;
- get_inner_radius() to access the radius of an origin-centered ball contained
  in the feasible region defined by packing constraints;
- get_standard_cuts() to access standard cutting planes that are always
  used in a fully corrective step;
- separate_point(point, precision) to separate a point by an inequality that
  is violated by at least precision.

The concrete oracles can be implemented elsewhere and are referenced via the
interface class. For matching, the oracle thus has to be able to return
the edge weights using get_obj(); the radius of suitable ball, the standard
cuts that are contained in an initial relaxation (e.g., upper bound
constraints or degree constraints), and the oracle has to provide a function
that is able to separate a given point (e.g., using odd set inequalities).

problems.py provides access to a relaxation of the problem to be solved,
which contains just a subset of the constraints that can be found by the
oracle. These problems are mainly used to compute the value of the LP
relaxation in each iteration of the cutting plane method.
As for the oracles, problems.py implements an interface class for
the communication between the packing algorithm and the actual problems.
The interface class PROBLEM provides the methods

- add_cut(cut) to add a separated inequality to the current relaxation;
- optimize() to solve the current relaxation;
- get_opt_solution() to access an optimal solution.

The concrete realizations of these problems can be implemented elsewhere.
For matching, add_cut(cut) thus adds a cut to the an LP relaxation of
the matching problem, optimize() has to provide a routine that solves
the LP relaxation, and get_opt_solution() returns an optimal solution
of the current relaxation.

Moreover, problems.py provides methods to solve auxiliary problems for the
packing algorithm.

auxiliary.py implements auxiliary functions needed elsewhere in the
code, e.g., methods to read an instance from a file.

MIP.py provides basic interface methods to create optimization models
in SCIP and Gurobi.


## IV REPRODUCING EXPERIMENTS

To reproduce the experiments, we provided the bash script

   run_experiments.sh.

The instance files needed by the script either have to be placed into a
subdirectory "Color02" or the user has to create a symbolic link "Color02"
to the directory containing these files. The files can be downloaded from
https://mat.tepper.cmu.edu/COLOR02/. A list of the required instances
can be found in the header of the script. The instances used for the
matching problem can be found in the subdirectory "matching".

The script creates the directories "results", "plots", and "logs" to store
the logs of the test runs and plots to illustrate the progress on
primal/dual bounds, respectively.

To generate the tables used in the article, the subdirectory "scripts"
contains the bash script

   generate_data_paper.sh

which prints the LaTeX code of our tables to the terminal and creates
files containing the two plots used in the article. To be able to
call this script, one needs to call run_experiments.sh first to
guarantee that all necessary log files have been created.

The script generate_data_paper.sh calls further subscripts, which we
describe next. To generate the tables, one can use

   generate_statistics_frequency.py <logdir>
   generate_statistics_initconss.py <logdir>

where  <logdir> is the directory containing the logs per instance
(by default, this directory is the newly created "logs" subdirectory).

When these scripts are called with the respective arguments, the LaTeX
code for the used tables is printed to the terminal.

Plots similar to those used in the article can be generated by

   generate_plot.py <logfile> <title>

where <logfile> is one file containing the logs of a run (usually
in the newly created "logs" subdirectory) and the string <title>
for the title of the plot. The plot is stored as a file in the
directory from that the script is called.

Moreover, the script

   generate_matching_instances.py <nnodes> <noddsets> <sizeoddsets> <basename>
                                  <ident> <weighted>

can be used to generate instances for the matching problem. The graphs
are constructed as described in the article, where <nnodes>
is the number of nodes and <noddsets> is the number of odd sets
used in the construction. <sizeoddsets>> is the size of the sampled
odd sets and <basename> is the basic file name that is used to
store the instance. <ident> is the identifier attached to the
<basename> to distinguish between the instances; it is also used
to initialize a random seed to generate always the same random
instance. If <weighted> is 1, we can also generate instances
with particular edge weights.

To generate instances like in the article, the script has to be
called with arguments

   500 <30> 3 "matching" <1> 0

where <30> and <1> can be varied.


## V EXTENDING THE CURRENT IMPLEMENTATION

To extend the existing code to solve further problem classes, the user has
to provide a new oracle and relaxation, and has to tell the main code when
to call the new oracle/relaxation. In the following, we assume that the
type <type> will be used to identify the new problem type.

1. Defining a New Oracle

   A new oracle has to be defined that implements the four interface
   methods

   - get_obj();
   - get_inner_radius();
   - get_standard_cuts();
   - separate_point(point, precision).

   The interface class ORACLE has to be informed about the new oracle.
   To this end, the case distinction in ORACLE has to be extended by
   <type> to tell the code which oracle to call if a problem
   of type <type> shall be solved.

2. Defining a New Problem

   A new problem has to be defined that implements the three interface
   methods

   - add_cut(cut);
   - optimize();
   - get_opt_solution().

   The interface class PROBLEM has to be informed about the new problem.
   To this end, the case distinction in PROBLEM has to be extended by
   <type> to tell the code which problem to call if a problem
   of type <type> shall be solved.

   In the initialization of the new problem class, one can implement three
   different basic versions of the problem to add different classes of
   inequalities that need not be separated. The identifiers of these
   classes are 0, 1, and 2.

3. Telling the Code About a New Problem Type

   To tell the code about the new problem, extend the array "allowedtypes"
   in the main routine of compare.py with the identifier <type>.
