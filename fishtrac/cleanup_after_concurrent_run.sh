#!/bin/bash

if [[ $# -lt 2 ]]
then
	echo Usage: $0 tracker seq
	exit 2
fi
### TODO add debug prints

TRACKER=$1
SEQ=$2

currentResDir="./results/${TRACKER}-${SEQ}/R-CNN/"
finalResDir="./results/${TRACKER}/R-CNN/"

echo "Copying from ${currentResDir}"
cp ${currentResDir}*mot* $finalResDir
ls ${currentResDir}*mot*
cp ${currentResDir}*additional* $finalResDir
ls ${currentResDir}*additional* 
echo "Finished copying from results dir"

for DIR in `find ${currentResDir} -mindepth 1 -type d`
do
    echo $DIR
    THRESH=`basename $DIR`
    echo $THRESH
    if [[ ! -d ${finalResDir}${THRESH} ]]
    then
        mkdir ${finalResDir}${THRESH}
    fi
    cp $DIR/*${SEQ}* ${finalResDir}${THRESH}
done

rm -r ./results/${TRACKER}-${SEQ}
rm -r ./output/${TRACKER}-${SEQ}
rm -r ./trackers/${TRACKER}-${SEQ}
