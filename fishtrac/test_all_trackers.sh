#!/bin/bash

# ON HPC: ./test_all_trackers.sh DAN VFT GOTURN-GPU KPD RMOT VIOU KIOU KCF MEDFLOW GOG IHTLS D3S
# ON Server: ./test_all_trackers.sh CMOT GMMCP AOA JPDA-M

TRACKER_LIST=$@
echo $TRACKER_LIST

#TRACKER_LIST=`ls ./trackers`

let SEQ_COUNT=0
for SEQ_FILE in ./evaluation/seqs/sublist-test*.txt
do
	if ! [[ -f $SEQ_FILE ]]
	then
		echo "Cannot find sequence files!  Run split_test_seq_list.py"
		exit 1
	fi
	TEST_LIST=`cat $SEQ_FILE`
	for SEQ in $TEST_LIST
	do
		MAT_FILE="./DETRAC-Train-Annotations-MAT/${SEQ}.mat"
		IMAGE_DIR="./DETRAC-images/${SEQ}/"
		DET_FILE="./DETRAC-Train-Detections/R-CNN/${SEQ}_Det_R-CNN.txt"

		# Check that all sequence files exist
		if  [[ ! -f $MAT_FILE ]];
		then
			echo $MAT_FILE does not exist.
            exit 1
		fi

		if [[ ! -d $IMAGE_DIR ]]
		then
			echo $IMAGE_DIR does not exist.
            exit 1
		fi
		#ls ${IMAGE_DIR}*.jpg

		if [[ ! -f $DET_FILE ]];
		then
			echo $DET_FILE does not exist.
            exit 1 
		fi
		let SEQ_COUNT=SEQ_COUNT+1
	done
done

echo "SEQUENCE COUNT IS $SEQ_COUNT"


for TRACKER in $TRACKER_LIST
do
	BEST_THRESH_FILE="./results/best_thresholds/${TRACKER}_best_thresh.txt"
	THRESH=`cat $BEST_THRESH_FILE`
	if [[ ! -n $THRESH ]]
	then
		echo $BEST_THRESH_FILE contains nothing, please finish training before testing...
		echo Run tracker on training set of videos over all thresholds, then run
		echo benchmark_evaluation.py on this tracker to determine the best threshold.
		exit -1
	fi	
	echo "Best threshold for $TRACKER is $THRESH"
done 

echo
echo ALL FILES NEEDED TO RUN TEST ARE PRESENT, TEST READY TO BEGIN
echo ENTER PASSCODE TO PROCEED...
PASS_CODE=""
echo

#read PASS_CODE
#if [[ $PASS_CODE != "PROCEED" ]]
#then
#	echo INCORRECT PASS CODE
#	exit 1
#fi


	

for TRACKER in $TRACKER_LIST
do
	BEST_THRESH_FILE="./results/best_thresholds/${TRACKER}_best_thresh.txt"
	THRESH=`cat $BEST_THRESH_FILE`
	if [[ ! -n $THRESH ]]
	then
		echo $BEST_THRESH_FILE contains nothing, please finish training before testing...
		echo Run tracker on training set of videos over all thresholds, then run
		echo benchmark_evaluation.py on this tracker to determine the best threshold.
		exit -1
	fi	

    set -x
	for SEQ_PATH in ./evaluation/seqs/sublist-test*.txt
	do
        SEQ_FILE=${SEQ_PATH##./*/}
        SEQ_FILE=${SEQ_FILE%%.*} 
		if [[ $TRACKER == "DAN" ]]
		then
			sbatch ./slurm/run_DAN_copy.slurm DAN $SEQ_FILE $THRESH
		elif [[ $TRACKER == "D3S" ]]	
		then
			sbatch ./slurm/run_d3s_copy.slurm D3S $SEQ_FILE $THRESH
		elif [[ $TRACKER == "VFT" ]]	
		then
			sbatch ./slurm/run_vft_copy.slurm VFT $SEQ_FILE $THRESH
		elif [[ $TRACKER == "GOTURN-GPU" ]]	
		then
			sbatch ./slurm/run_goturn_copy.slurm GOTURN-GPU $SEQ_FILE $THRESH
		elif [[ $TRACKER == "KPD" ]]	|| [[ $TRACKER == "RMOT" ]] || [[ $TRACKER == "VIOU" ]] || [[ $TRACKER == "KIOU" ]]|| [[ $TRACKER == "KCF" ]] || [[ $TRACKER == "GOG" ]] || [[ $TRACKER == "IHTLS" ]]
		then
			sbatch ./slurm/run_reg_copy.slurm $TRACKER $SEQ_FILE $THRESH
		elif [[ $TRACKER == "GMMCP" ]] || [[ $TRACKER == "CMOT" ]] || [[ $TRACKER == "AOA" ]] || [[ $TRACKER == "JPDA-M" ]] ||  [[ $TRACKER == "KPD_OPT" ]] ||  [[ $TRACKER == "TRANSCTR-CAR" ]] || [[ $TRACKER == "MEDFLOW" ]] 
		then
			#These four are run on a server with a different version of octave installed
            #echo "./runAOATest.sh $TRACKER $THRESH $SEQ_FILE"
           # ./runAOATest.sh $TRACKER $THRESH $SEQ_FILE
			 time python experiment_wrapper.py $TRACKER $THRESH $SEQ_FILE ~/my_octave/bin/octave timed copyTracker &> ${TRACKER}_${SEQ_FILE}_TEST.out
		fi
		
	done
done
