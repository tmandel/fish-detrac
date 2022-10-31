#/bin/bash

mkdir DETRAC-images
for IMGDIR in ./trainSet/*
do

    VIDNAME=${IMGDIR##./trainSet/}
    echo $IMGDIR
    echo $VIDNAME
    mkdir DETRAC-images/${VIDNAME}

    for IMGPATH in ${IMGDIR}/img1/*.jpg
    do
        IMGFILE=${IMGPATH##${IMGDIR}/img1/0}
        #echo $IMGFILE
        NEWPATH=DETRAC-images/${VIDNAME}/img${IMGFILE}
        echo $NEWPATH
        cp $IMGPATH $NEWPATH
    done

    #Next line allows us to generate an .mp4 if needed
    #python mergeFrame.py DETRAC_Images/${VIDNAME}
done
