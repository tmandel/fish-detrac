#!/bin/bash
##### NOTE #####
## for this script to work as intended,
## you need to have a file called dont_copy.txt
## in the tracker folder which indicates what
## files should be linked to and not copied

#ARGS: tracker sequence
if [[ $# -lt 2 ]]
then
	echo usage: $0 TRACKER SEQUENCE
	exit 2
fi

TRACKER=$1
SEQUENCE=$2
# we are going to build this rsync command iteratively
COPY_COMMAND="rsync -a"
# this is the list of which files to exclude and symlink 
DONT_COPY_FILE=./trackers/${TRACKER}/dont_copy.txt

OLD_DIR=./trackers/${TRACKER}/
NEW_DIR=./trackers/${TRACKER}-${SEQUENCE}/

echo copying from $OLD_DIR to $NEW_DIR
# create new destination directory
mkdir $NEW_DIR

# read dont copy file
while read LINE
do	
	EXCLUDE=`basename $LINE`
	COPY_COMMAND="${COPY_COMMAND} --exclude ${EXCLUDE}"
done < $DONT_COPY_FILE

# tell rsync to copy from source to destination 
COPY_COMMAND="${COPY_COMMAND} ${OLD_DIR} ${NEW_DIR}"

#run rsync command
`$COPY_COMMAND`
echo $COPY_COMMAND

while read LINE
do	
	ln -s ${PWD}/${OLD_DIR}${LINE} ${NEW_DIR}${LINE}
done < $DONT_COPY_FILE


