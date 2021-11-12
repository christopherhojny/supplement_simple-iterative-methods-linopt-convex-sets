#!/usr/bin/env bash

python generate_statistics_frequency.py ../logs
python generate_statistics_initconss.py ../logs
python generate_plot.py ../logs/matching2.col_prec_0.001000_corrfreq_1_initconss_2_solver_gurobi_matching.txt "frequency 1"
python generate_plot.py ../logs/matching2.col_prec_0.001000_corrfreq_10_initconss_2_solver_gurobi_matching.txt "frequency 10"
