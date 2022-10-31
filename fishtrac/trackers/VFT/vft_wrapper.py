import sys
import os
import scipy.io
import numpy as np 
import csv
import two_stage_graph_rgbhist 

def saveTrackerResultsforEval(tracksFile, frameWidth, frameHeight, numFrames):
    """
    args:
         tracksFile(str) - name of file where VFT tracker wrote results, these will be converted
                           for detrac to read.
         frameWidth, frameHeight, numFrames (int)
    returns:
         NONE(writes results to output files VFT_LX.txt etc.)

    """
    print("Frame w x h = {} x {}".format(frameWidth, frameHeight))
    # store output from VFT in list (number of boxes by 5: frame, track, x,y,w,h)
    vftOutput = []
    numTracks = 0
    with open(tracksFile, 'r') as f:
       csvReader = csv.reader(f, delimiter=';')
       for row in csvReader:
           vftOutput.append(row)
           if(numTracks < int(row[1])):
               numTracks = int(row[1])

    # Initialize arrays to all zeros
    LX = np.zeros((numFrames, numTracks)) 
    LY = np.zeros((numFrames, numTracks)) 
    LW = np.zeros((numFrames, numTracks)) 
    LH = np.zeros((numFrames, numTracks)) 

    # Go through vftOutput and convert percentages to coordinates
    for row in vftOutput:
        frame = int(row[0]) - 1
        trackNum = int(row[1]) - 1
        xPct = float(row[2])
        yPct = float(row[3])
        wPct = float(row[4])
        hPct = float(row[5])
        
        x = xPct * frameWidth
        y = yPct * frameHeight
        w = wPct * frameWidth
        h = hPct * frameHeight
        y = y+(h/2) 

        LX[frame, trackNum] = x
        LY[frame, trackNum] = y
        LW[frame, trackNum] = w
        LH[frame, trackNum] = h

    # Save in format for DETRAC to read
    np.savetxt("VFT_LX.txt", LX, delimiter=',', fmt='%d')
    np.savetxt("VFT_LY.txt", LY, delimiter=',', fmt='%d')
    np.savetxt("VFT_W.txt", LW, delimiter=',', fmt='%d')
    np.savetxt("VFT_H.txt", LH, delimiter=',', fmt='%d')


def formatDetectionsForVFT(arr, frameWidth, frameHeight,numFrames):
    """
    args: 
    arr(list of bounding boxes) - 7 x Number of detections 
                                    frame, detection in frame idx,x, y , w, h, probability
        pixel width of frame(int)
        pixesl height of frame(int)
        number of frames(int) returns:
        detectionsForVFT(list of bounding boxes) - 5 x Number of detections
        frame, xc, xy, width, height (all percentage of frame)
    """

    numRows = len(arr)  # Rows = frame_num, detection_idx, x, y, w, h, prob
    numCols = len(arr[0]) # Columns = number of detections

    detectionsForVFT = []
    for colNum in range(numCols):
        frameNum = int(arr[0][colNum])
        detection_idx = int(arr[1][colNum]) #unused
        x1 = float(arr[2][colNum])
        y1 = float(arr[3][colNum])
        width = float(arr[4][colNum])
        height = float(arr[5][colNum])
        prob = float(arr[6][colNum]) #unused
        
        xc = (x1 + (width/2))/frameWidth
        yc = (y1 + (height/2))/frameHeight
        widthPct = float(arr[4][colNum])/frameWidth
        heightPct = float(arr[5][colNum])/frameHeight
        row = [frameNum, xc, yc, widthPct, heightPct]
        detectionsForVFT.append(row)

    return detectionsForVFT 


def convertDetectionsMatToBBList(arr):
    """
    converts detection array to list of bounding boxes
    """
    bigList = []
    numDetections = 0
    for i in range(len(arr[0])):
        if arr[0][i] > arr[0][i+1]:
            numDetections = i+1
            break

    idx = 0
    for i in range(7):
        littleList = []
        while idx < (numDetections*(i+1)):
            littleList.append(float(arr[0][idx]))
            idx+=1
        bigList.append(littleList)
    return bigList

         

if __name__ == "__main__":
    print("BEGIN VFT TRACKER")
    # Clear out the results from last time, if any
    if os.path.exists('VFT_LX.txt'):
        os.system('rm VFT_LX.txt')
        os.system('rm VFT_LY.txt')
        os.system('rm VFT_W.txt')
        os.system('rm VFT_H.txt')
    os.system('rm ./detections/*')

    # calculate img params
    numFrames = int(sys.argv[2])
    frameWidth = int(sys.argv[3])
    frameHeight = int(sys.argv[4])
    imgPath = sys.argv[5]

    # transform detections mat to list
    d = scipy.io.loadmat(sys.argv[1])
    detections = convertDetectionsMatToBBList(d['detects'])
    detectionsForVFT = formatDetectionsForVFT(detections, frameWidth, frameHeight, numFrames)
 
    seqName = os.path.basename((os.path.dirname(imgPath)))

    if not (os.path.exists("./detections/")):
        os.mkdir("./detections")
        
    if not (os.path.exists("./output/")):
        os.mkdir("./output/")
    
    # save file for tracker to read
    with open("./detections/{}.csv".format(seqName), 'w') as f:
        detectionsCSV = csv.writer(f, delimiter=',') 
        for row in detectionsForVFT:
            detectionsCSV.writerow(row)
    print("Calling tracker algorithm")
    
    imgPath = '../.' + imgPath
    # CALL TRACKER
    two_stage_graph_rgbhist.run( './detections/', "./output/",  imgPath, './tsgrgb.cfg')
     
    # write tracker results to csvs for DETRAC to evaluate
    saveTrackerResultsforEval("./output/{}/tracks.csv".format(seqName), frameWidth, frameHeight, numFrames)
    print("END VFT TRACKER")

