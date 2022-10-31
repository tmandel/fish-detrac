# Run this script once to split the detrac test list into batches
import sys
import random
import os

if len(sys.argv) < 3:
    print("usage: {} seqPrefix numOfFiles".format(sys.argv[0]))
    exit(2)


origFileName = "./evaluation/seqs/"+sys.argv[1]+".txt"

desiredBatchCount = int(sys.argv[2])

os.system('rm ./evaluation/seqs/sublist*')

combinedList = []
with open(origFileName) as inputFile:
    for line in inputFile:
        combinedList.append(line.strip())
    
random.shuffle(combinedList)

seqCount = 0
batchCount = 0
subList = []
for seq in combinedList:
    subList.append(seq)
    seqCount += 1
    if(seqCount >= ((batchCount+1)/desiredBatchCount) * len(combinedList) or seqCount == len(combinedList)):
        batchCount += 1
        with open("./evaluation/seqs/sublist-test-{}.txt".format(batchCount), 'w') as outputFile:
            for sequence in subList:
                outputFile.writelines(sequence + '\n')
        subList = []
            
            
