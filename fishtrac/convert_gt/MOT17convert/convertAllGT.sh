#/bin/bash

mkdir DETRAC-Train-Annotations-MAT/

for IMGDIR in ./trainSet/*
do

    echo $IMGDIR
    python motgt_to_csv_and_mat.py $IMGDIR DETRAC-Train-Annotations-MAT/ 
done
