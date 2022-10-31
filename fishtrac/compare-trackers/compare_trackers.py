import csv
import sys
import os
import traceback

#def did_tracker_timeout(tracker, seq, thresh)

def get_timeout_failure(resultsDir, tracker, thresh, seq):
    
    additionalInfoFileName = '{}{}/R-CNN/{}_additional_info.txt'.format(resultsDir, tracker, seq)

    additionalInfo = None 
    timeout = 0
    failure = 0
    with open(additionalInfoFileName, 'r') as f:
        additionalInfo = csv.reader(f)

        if not additionalInfo:
            print("ERROR: Could not find additional info file")
            print(additionalInfoFileName)
            sys.exit(-1)
    
        for row in additionalInfo:
            if not row:
                break
            elif row[0] == str(thresh):
                timeout = row[-2]
                failure = row[-1]
                break

    return timeout, failure

def get_speed(resultsDir, tracker, thresh, seq):

    speedDir = '{}{}/R-CNN/{}/{}_speed.txt'.format(resultsDir, tracker, thresh, seq)
    speed = 0

    with open(speedDir, 'r') as f:
        speed = float(f.read()[:-1])

    print('speed:', speed)
    
    return speed

def compare_trackers(trackerList, seqList, resultsDir, userThreshSelection):

    fullThreshList = ["{:.1f}".format(i*.1) for i in range(10)]
    print(fullThreshList)
    bestThreshDict = {}

    for tracker in trackerList:
        if(userThreshSelection):
            bestThreshDict[tracker] = userThreshSelection
        else:
            bestThreshFile = resultsDir + 'best_thresholds/' + tracker + '_best_thresh.txt'
            with open(bestThreshFile) as f:
                bestThreshDict[tracker] = f.read()
    print(bestThreshDict)

    output = []

    csvOutFile = 'comparison_results.csv'
    csvOut = open(csvOutFile, 'w')
    csvWriter = csv.writer(csvOut, delimiter=',', quotechar='"', quoting=csv.QUOTE_MINIMAL)
    header = ['sequence','tracker', 'thresh', 'Rcll', 'Prcn', 'FAR', 'GT', 'MT', 'PT', 'ML', 'FP', 'FN', 'IDs', 'FM', 'MOTA', 'MOTP', 'MOTAL', 'Speed', 'Timeout', 'Failure']
    csvWriter.writerow(header)
    for seq in seqList:
        output.append(seq)
        for tracker in trackerList:
            output.append(tracker)
            scores = []
            scoreFile = resultsDir + tracker + '/R-CNN/' + seq + '_mot_result.txt'
            print(scoreFile)
            try:
                with open(scoreFile) as csvInFile:
                    csvReader = csv.reader(csvInFile, delimiter=',', quotechar='|')
                    for row in csvReader:
                        #print('row',row)
                        #print(bestThreshDict[tracker])
                        #if tracker has no results at or above this threshold, row will be an empty list
                        if not row:
                            #print('no results above this threshold')
                            continue
                        #tracker did not timeout
                        elif row[0][:3] == bestThreshDict[tracker][:3]:
                            csvRow = [seq,tracker]
                            #print(row)
                            for score in row:
                                output.append(score)
                                csvRow.append(score)
                            speed = get_speed(resultsDir, tracker, bestThreshDict[tracker][:3], seq)
                            csvRow.append('{:.2f}'.format(speed))

                            timeout, failure = get_timeout_failure(resultsDir, tracker, bestThreshDict[tracker][:3], seq)
                            csvRow.append(timeout)
                            csvRow.append(failure)
                            csvWriter.writerow(csvRow)

            except Exception as e:
                print(tracker)
                print('error in fetching results for', tracker, seq)
                print(e)
                traceback.print_exc()
                exit(-1)
    csvOut.close()

    evalFile = 'comparison_results.txt'
    out = open(evalFile, 'w')
    for row in output:
        #print(row)
        if isinstance(row, str):
            out.write(row)
            out.write('\n')
            continue
        labels = ['Thresh', 'Recall', 'Precision', 'FAR', 'GT', 'MT', 'PT', 'ML', 'FP', 'FN', 'IDs', 'FM', 'MOTA', 'MOTP', 'MOTAL', 'Speed']
        header = ''
        evaluation = ''
        for score, label in zip(row, labels):
            header += '{:^9}'.format(label)
            score = '{:.2f}'.format(float(score))
            evaluation += '{:^9}'.format(score)

        scoreStr = header + '\n' + evaluation + '\n'
        out.write(scoreStr)
    out.close()

def get_seq_list(seqFileName):
    seqDir = '../evaluation/seqs/'
    seqList = []
    with open(seqDir + seqFileName + '.txt', 'r') as f:
        csvReader = csv.reader(f,delimiter=',')
        seqList = [row[0] for row in csvReader]
    print(seqList)
    return(seqList)



if __name__ == "__main__":

    trackerSet = ['KPD', 'GOG', 'CMOT', 'RMOT', 'VIOU', 'KIOU', 'KCF']
    seqList = []
    if len(sys.argv) < 3:
        print('\nusage: {} <seqFilePrefix> <resultsDir> <thresh/best> <"trackerList"(eg "KPD GOG CMOT") or all> '.format(sys.argv[0]))
        print('Note: separate list of trackers by spaces and enclose with quotations\n')
        sys.exit(-1)
    else:
        

        if sys.argv[4].lower() != 'all':
            trackerSet = sys.argv[4].split()
        seqFilePrefix = sys.argv[1] 
        resultsDir = sys.argv[2]
        thresh = None 
        if sys.argv[3].lower() != 'best':
            thresh = sys.argv[3]

        seqList = get_seq_list(seqFilePrefix) 
        print(trackerSet)
        print(seqList)
        print('RESULTS DIRECTORY:', resultsDir)


    compare_trackers(trackerSet, seqList, resultsDir, thresh)

