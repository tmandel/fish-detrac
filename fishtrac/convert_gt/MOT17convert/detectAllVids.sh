#/bin/bash

for VIDNAME in ./DETRAC_Images/*.mp4
do
    python outputDetectorPredictions.py $VIDNAME 0.5 Ped 
done
