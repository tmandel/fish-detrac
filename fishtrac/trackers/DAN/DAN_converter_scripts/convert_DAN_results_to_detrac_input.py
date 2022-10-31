import csv
import sys
import scipy.io
import os
from .conversion_utils import read_seq_file

def read_DAN_Result(filename):
    #Dictionary keys are frame, values are lists
    bboxDict = {}
    maxFrameNum = 0
    #DAN stores results by frame, then by track
    with open(filename, 'r') as f:
        csvReader = csv.reader(f, delimiter = ' ')
        for row in csvReader:
            frame = row[0]
            track = row[1]
            x = round(float(row[2]))
            y = round(float(row[3]))
            w = round(float(row[4]))
            h = round(float(row[5]))
            boxTuple = (x, y, w, h)
            #BOX 
            infoWeNeed = [boxTuple, 1, int(track)]
            key = int(frame)
            #What is the highest frame with a track in it
            if key > maxFrameNum:
                maxFrameNum = key
            #Seen this frame before
            if key in bboxDict:
                bboxDict[key].append(infoWeNeed)
            #Have not seen a track in this frame before
            else:
                bboxDict[key] = [infoWeNeed]
            

    bboxList = []
    for f in range(1,maxFrameNum+1):
        bboxList.append(bboxDict.get(f,[]))

    return bboxList


def write_DETRAC_Files(bigList, LX, LY, H, W, numFrames):
    #takes in list of boxes in every frame and writes detrac formatted tracks to txt files

    xLists = []
    yLists = []
    hLists = []
    wLists = []
    maxFishID = 0
    for fnum in range(len(bigList)):
        frame = bigList[fnum]
        seen = []
        xLists.append([0] * maxFishID)
        yLists.append([0] * maxFishID)
        wLists.append([0] * maxFishID)
        hLists.append([0] * maxFishID)
        for box, score,fishID in frame:
            if fishID is None:
                continue
            if fishID > maxFishID:
                maxFishID = fishID
            while len(xLists[fnum]) < maxFishID:
                xLists[fnum].append(0)
                yLists[fnum].append(0)
                wLists[fnum].append(0)
                hLists[fnum].append(0)
            (x,y,w,h) = box
            #Special detrac input format
            xLists[fnum][fishID-1] = x + w/2
            yLists[fnum][fishID-1] = y + h
            wLists[fnum][fishID-1] = w
            hLists[fnum][fishID-1] = h


    #length of output must match length of video
    while len(xLists) < numFrames:
      xLists.append([0]*maxFishID)
      yLists.append([0]*maxFishID)
      wLists.append([0]*maxFishID)
      hLists.append([0]*maxFishID)

    #Every track must have an entry for every frame, even if the entry is zero 
    for fnum in range(len(xLists)):
        while len(xLists[fnum]) < maxFishID:
            xLists[fnum].append(0)
            yLists[fnum].append(0)
            wLists[fnum].append(0)
            hLists[fnum].append(0)

    
    #Write to csvs
    outLX = open(LX, "w+")
    outLY = open(LY, "w+")
    outH = open(H, "w+")
    outW = open(W,"w+")
    xWriter = csv.writer(outLX,delimiter=",")
    yWriter = csv.writer(outLY,delimiter=",")
    hWriter = csv.writer(outH,delimiter=",")
    wWriter = csv.writer(outW,delimiter=",")
    for xList, yList, wList, hList in zip(xLists,yLists,wLists,hLists):
        xWriter.writerow(xList)
        yWriter.writerow(yList)
        hWriter.writerow(hList)
        wWriter.writerow(wList)
    
    outLX.close()
    outLY.close()
    outH.close()
    outW.close()


def convert_DAN_results_to_detrac_input(sequenceName, resDir = 'DAN-raw-output', convertedDir = 'DETRAC-input', numFrames=None):
    
    #resDir = '../three-car-train-output'
    print("Converting results from unconverted directory: {}".format(resDir))
    print("to converted directory: {}".format(convertedDir))
    
        
    print("Video name:", sequenceName )
    print("Number of frames in this video:", numFrames)

    #for i in range(10):
    if True:
        #threshold
        #thresh = i * 0.1
        #print("Converting results for threshold:", thresh)

        #get specific results file
        resFile = '{}/{}.txt'.format(resDir, sequenceName)
        print("Reading DAN output:", resFile)
        if not os.path.exists(resFile):
            print("No output on {}".format(sequenceName))
            return

        #takes in DAN output and converts it to bbscore-id-list
        bboxScoreIdList = read_DAN_Result(resFile)
        
        #Now we have the results stored in a pertfectly formatted list to give to write_DETRAC_files
        saveDir = convertedDir
        if not os.path.exists(saveDir):
            print('could not find directory to save in:', saveDir)
            print('making DAN save directory')
            os.mkdir(saveDir)

        #This is where our converted results will be output
        savePath = saveDir + '/' 
        print("Outputting converted results to file:", savePath)

        #format save path
        if not os.path.exists(savePath):
            print('could not find DAN sequence directory:', savePath)
            print('making DAN save directory for this seq:', savePath)
            os.mkdir(savePath)
        DAN_LX = savePath + 'DAN_LX.txt'# generated files for input to DETRAC
        DAN_LY = savePath + 'DAN_LY.txt'
        DAN_H = savePath + 'DAN_H.txt'
        DAN_W = savePath + 'DAN_W.txt'

        #write bbox-score-id list out to a file which can be used as input to DETRAC
        print('Writing DETRAC files')
        write_DETRAC_Files(bboxScoreIdList, DAN_LX, DAN_LY, DAN_H, DAN_W, numFrames)


if __name__ == "__main__":
    if(len(sys.argv) < 2):
        print("Usage: {} sequenceList(ie. trainlist-full)/sequenceName [unconverted results dir] [converted results dir]".format(sys.argv[0]))
        sys.exit(2)
        
    #this where DAN saves its unconverted results after running(aka this is the source we need to convert)
    resDir = 'DAN-raw-output'
    if(len(sys.argv) >= 3):
            resDir = sys.argv[2]
    convertedDir = 'DETRAC-input'
    if(len(sys.argv) == 4):
        convertedDir = sys.argv[3]


    #if path does not exist to sequence file, assume user wants to convert single sequence
    if not os.path.exists("../../../evaluation/seqs/{}.txt".format(sys.argv[1])):
        seqList = [ sys.argv[1] ]

    else:
        #get seq list
        seqListName = sys.argv[1]
        seqList = read_seq_file(seqListName)

    print("Sequence list: {}".format(seqList))

    #convert each result in seq list
    for sequenceName in seqList:
        #This block is for getting number of frames in ground truth video
        annotationFileName = '../../../DETRAC-Train-Annotations-MAT/' + sequenceName + '.mat'
        numFrames = 0 
        if os.path.exists(annotationFileName):
            matContents = scipy.io.loadmat(annotationFileName)
            gtInfo = matContents['gtInfo']
            y = gtInfo['Y'][0][0]
            numFrames, numTracksGT = y.shape
        if(numFrames == 0):
            print("could not find annotation file for {}".format(sequenceName))
            sys.exit(-1)
        convert_DAN_results_to_detrac_input(sequenceName, resDir, convertedDir, numFrames)
    

