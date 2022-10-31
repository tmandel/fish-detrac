import io
import sys
from csv import reader

###############################################################################
#This script is for getting the row with the best mota score for a single tracker
#and sequence, once the tracker has run over multiple thresholds

"""
mot_result headers:
Thresh  Recall  Precision   FAR GT  MT  PT  ML  FP  FN  IDs FM  MOTA    MOTP    MOTAL
0       1       2           3   4   5   6   7   8   9   10  11  12      13      14
"""
def maxMOTArow(sequence, tracker):
    resultPath = '../results/' + tracker + '/R-CNN/' + sequence
    motResultFile = resultPath + '_mot_result.txt'
    resultList = []
    with open(motResultFile) as fSeq:
        csv_reader = reader(fSeq, delimiter=',')
        for row in csv_reader:
            resultList.append(row)


    maxMOTA = float(resultList[0][12])
    maxRow = resultList[0]
    for row in resultList:
        if float(row[12]) > maxMOTA:
            maxMOTA = float(row[12])
            maxRow = row

    bestThresh = '{:.1f}'.format(float(maxRow[0]))
    speed = 0
    seqLen = len(sequence)
    speedFile = resultPath[:-seqLen] + bestThresh + '/' + sequence + '_speed.txt'
    with open(speedFile, 'r') as fSpeed:
        speed = fSpeed.readline()
    maxRow.append(speed)

    labels = ['Thresh', 'Recall', 'Precision', 'FAR', 'GT', 'MT', 'PT', 'ML', 'FP', 'FN', 'IDs', 'FM', 'MOTA', 'MOTP', 'MOTAL', 'Speed']
    header = ''
    evaluation = ''
    for score, label in zip(maxRow, labels):
        header += '{:^9}'.format(label)
        score = '{:.2f}'.format(float(score)) #floating point precision formatting
        evaluation += '{:^9}'.format(score)

    scoreStr = header + '\n' + evaluation
    print(scoreStr)

    maxRowFile = resultPath + '_max_row.txt'
    f = open(maxRowFile, 'w')
    f.write(scoreStr)
    f.close()



if __name__ == "__main__":
    if len(sys.argv) < 3:
        print("Usage: ", sys.argv[0], '[sequence_name] [tracker_name]')
    sequence = sys.argv[1]
    tracker = sys.argv[2]
    maxMOTArow(sequence, tracker)
