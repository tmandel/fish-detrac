#!/bin/bash
echo "Usage: $0 [condaPath]"

if [[ $# -lt 1 ]]
then
    CONDA_BASE=$(conda config --show envs_dirs | grep "-" | head -n1 | sed -r 's/^\s+-\s+//')
else
    CONDA_BASE=$1
fi
echo "COnda base path is \"$CONDA_BASE\"" 
if ! [[ -f fishtrac-extras.zip ]]
then 
    echo "Please download fistrac-extras.zip before proceeding"
    exit 1
fi



cd fishtrac
mkdir DETRAC-images
mkdir DETRAC-Train-Detections
mkdir DETRAC-Train-Detections/R-CNN
mkdir DETRAC-Train-Annotations-MAT
mkdir results
mkdir results/best_thresholds
touch sequences.txt
mkdir ./trackers/DAN/results-DAN
sed -i "s|options.condaPath = '[^']*'|options.condaPath = '$CONDA_BASE'|" initialize_environment.m
gcc     timedEval.c   -o timedEval -lm
cd ..

unzip fishtrac-extras.zip

#Loading conda environments
conda env create -f fishtrac.yml
conda env create -f caffe_gpu.yml
conda env create -f DAN.yml
conda env create -f AOA_env.yml
conda env create -f vft_env.yml

./download_d3s.sh $CONDA_BASE

# SETUP FOR BENCHMARK EVAL
cd fishtrac/compare-trackers
ln -s ../evaluation/TrackEval/ TrackEval
#After this, you might need to setup octave
echo -e "=====================================ATTENTION!========================================================== \n Please run Octave, and enter the following commands: \n pkg install image-2.12.0.tar.gz \n pkg install io-2.6.3.tar.gz \n =====================================ATTENTION!=========================================================="


