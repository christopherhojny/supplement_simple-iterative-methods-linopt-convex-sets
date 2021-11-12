#!/usr/bin/env bash
# specify test data
PREC=0.001
FREQS=( 1 10 )
INITCONSS=( 1 2 )
SOLVER=gurobi
MAXITER=1000
STABLEINSTANCES=( mug100_1.col mug100_25.col queen10_10.col 4-FullIns_3.col games120.col queen11_11.col\
			 DSJC125.1.col DSJC125.5.col miles250.col miles500.col\
			 miles750.col miles1000.col miles1500.col anna.col queen12_12.col 2-Insertions_4.col )

MATCHINGINSTANCES=( 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 )

declare -A OPTVAL
OPTVAL=( [stablesetmug100_1.col]=37.166666666666664 [stablesetmug100_25.col]=38.0 [stablesetqueen10_10.col]=10.0\
				[stableset4-FullIns_3.col]=55.0 [stablesetgames120.col]=22.0 [stablesetqueen11_11.col]=11.0\
				[stablesetDSJC125.1.col]=43.1408510638298 [stablesetDSJC125.5.col]=15.37608584906174\
				[stablesetmiles250.col]=44.0 [stablesetmiles500.col]=18.5\
				[stablesetmiles750.col]=12.0 [stablesetmiles1000.col]=8.0 [stablesetmiles1500.col]=5.0\
				[stablesetanna.col]=80.0 [stablesetqueen12_12.col]=12.0 [stableset2-Insertions_4.col]=74.5\
			       [stablesetmyciel5.col]=23.0 [stablesetjean.col]=38.0 [stablesetqueen6_6.col]=6.0\
			       [matching1.col]=30.0 [matching2.col]=33.0 [matching3.col]=36.0 [matching4.col]=39.0\
			       [matching5.col]=42.0 [matching6.col]=45.0 [matching7.col]=48.0 [matching8.col]=51.0\
			       [matching9.col]=54.0 [matching10.col]=57.0 [matching11.col]=60.0 [matching12.col]=63.0\
			       [matching13.col]=66.0 [matching14.col]=69.0 [matching15.col]=72.0 [matching16.col]=75.0\
       )

TIMESTAMP=`date +"%y_%d_%m_%H-%M-%S"`

# create directories for storing results
mkdir -p results
mkdir -p plots
mkdir -p logs


# tests for different frequencies with standard initialization
OUTFILE="results/results_frequencies_standard.out"

# check whether file already exists, if yes: save it
if test -f "$OUTFILE"; then
    mv $OUTFILE $OUTFILE-old$TIMESTAMP
fi
touch $OUTFILE

echo "@01 FREQ TESTS FOR DIFFERENT FREQUENCIES STANDARD INITIALIZATION" >> $OUTFILE
echo "@02 matching" >> $OUTFILE
echo "frequency tests for matching" >> $OUTFILE
for F in ${FREQS[@]}
do
    echo "@03 frequency ${F}" >> $OUTFILE
    for I in ${MATCHINGINSTANCES[@]}
    do
	echo "@04 matching${I}.col" >> $OUTFILE
	python compare.py --precision=$PREC --file=matching/matching$I.col --maxiter=$MAXITER --corrfreq=$F --initconss=2 --type=matching --solver=$SOLVER >> $OUTFILE
    done
done
echo "@02 stable set" >> $OUTFILE
echo "frequency tests for stable set" >> $OUTFILE
for F in ${FREQS[@]}
do
    echo "@03 frequency ${F}" >> $OUTFILE
    for I in ${STABLEINSTANCES[@]}
    do
	echo "@04 ${I}" >> $OUTFILE
	python compare.py --precision=$PREC --file=Color02/$I --maxiter=$MAXITER --corrfreq=$F --initconss=2 --type=stableset --solver=$SOLVER >> $OUTFILE
    done
done

# tests for different frequencies with optimal initialization
OUTFILE="results/results_frequencies_optimal.out"

# check whether file already exists, if yes: save it
if test -f "$OUTFILE"; then
    mv $OUTFILE $OUTFILE-old$TIMESTAMP
fi
touch $OUTFILE

echo "@01 FREQ TESTS FOR DIFFERENT FREQUENCIES OPTIMAL INITIALIZATION" >> $OUTFILE
echo "@02 matching" >> $OUTFILE
echo "frequency tests for matching" >> $OUTFILE
for F in ${FREQS[@]}
do
    echo "@03 frequency ${F}" >> $OUTFILE
    for I in ${MATCHINGINSTANCES[@]}
    do
	echo "@04 matching${I}.col" >> $OUTFILE
	python compare.py --precision=$PREC --file=matching/matching$I.col --maxiter=$MAXITER --corrfreq=$F --initconss=2 --type=matching --solver=$SOLVER --lbopt=${OPTVAL[matching$I.col]} >> $OUTFILE
    done
done
echo "@02 stable set" >> $OUTFILE
echo "frequency tests for stable set" >> $OUTFILE
for F in ${FREQS[@]}
do
    echo "@03 frequency ${F}" >> $OUTFILE
    for I in ${STABLEINSTANCES[@]}
    do
	echo "@04 ${I}" >> $OUTFILE
	python compare.py --precision=$PREC --file=Color02/$I --maxiter=$MAXITER --corrfreq=$F --initconss=2 --type=stableset --solver=$SOLVER --lbopt=${OPTVAL[stableset$I]} >> $OUTFILE
    done
done


# # tests for different constraints used in fully corrective step
OUTFILE="results/results_initconss.out"

# check whether file already exists, if yes: save it
if test -f "$OUTFILE"; then
    mv $OUTFILE $OUTFILE-old$TIMESTAMP
fi
touch $OUTFILE

echo "@01 INITCONSS TESTS FOR INITIAL CONSTRAINTS" >> $OUTFILE
echo "@02 matching" >> $OUTFILE
echo "initconss tests for matching" >> $OUTFILE
for IC in ${INITCONSS[@]}
do
    echo "@03 initconss ${IC}" >> $OUTFILE
    for I in ${MATCHINGINSTANCES[@]}
    do
	echo "@04 matching${I}.col" >> $OUTFILE
	python compare.py --precision=$PREC --file=matching/matching$I.col --maxiter=$MAXITER --corrfreq=1 --initconss=$IC --type=matching --solver=$SOLVER >> $OUTFILE
    done
    echo "@03opt initconss ${IC}" >> $OUTFILE
    for I in ${MATCHINGINSTANCES[@]}
    do
	echo "@04 matching${I}.col" >> $OUTFILE
	python compare.py --precision=$PREC --file=matching/matching$I.col --maxiter=$MAXITER --corrfreq=1 --initconss=$IC --type=matching --solver=$SOLVER --lbopt=${OPTVAL[matching$I.col]} >> $OUTFILE
    done
done
echo "@02 stable set" >> $OUTFILE
echo "initconss tests for stable set" >> $OUTFILE
for IC in ${INITCONSS[@]}
do
    echo "@03 initconss ${IC}" >> $OUTFILE
    for I in ${STABLEINSTANCES[@]}
    do
	echo "@04 ${I}" >> $OUTFILE
	python compare.py --precision=$PREC --file=Color02/$I --maxiter=$MAXITER --corrfreq=1 --initconss=$IC --type=stableset --solver=$SOLVER >> $OUTFILE
    done
    echo "@03opt initconss ${IC}" >> $OUTFILE
    for I in ${STABLEINSTANCES[@]}
    do
	echo "@04 ${I}" >> $OUTFILE
	python compare.py --precision=$PREC --file=Color02/$I --maxiter=$MAXITER --corrfreq=1 --initconss=$IC --type=stableset --solver=$SOLVER --lbopt=${OPTVAL[stableset$I]} >> $OUTFILE
    done
done
