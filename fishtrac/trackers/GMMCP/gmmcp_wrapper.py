
import sys
import os
import scipy.io
import numpy as np
import random
import convertGMMCPRes as convert

print(sys.argv)

def generateRandomBox(frameWidth, frameHeight):
    x = random.randint(0, frameWidth)
    y = random.randint(0, frameHeight)
    score = 1.0 #set score for dummy box to 1 - GMMCP doesn't use this anyway
    b = (x,y,x+1, y+1)#.astype(int)
    bboxScoreList = [(b, score)]#Dummy box
    return bboxScoreList

def formatBBList(arr, frameWidth, frameHeight,numFrames):
    bigList = []
    numRows = len(arr)  #Rows = frame_num, detection_idx, x, y, w, h, prob
    numCols = len(arr[0]) #Colums = number of detections
    print('numRows: ', numRows)
    print('numCols: ', numCols)
    for colNum in range(numCols):
        frameNum = int(arr[0][colNum])
        #print("frameNum is", frameNum)
        detection_idx = int(arr[1][colNum])
        x1 = float(arr[2][colNum])
        y1 = float(arr[3][colNum])
        width = float(arr[4][colNum])
        height = float(arr[5][colNum])
        prob = float(arr[6][colNum])
        
        x2 = x1 + width
        y2 = y1 + height
        
        bbox = (x1, y1, x2, y2)
        score = float(arr[6][colNum])
        while len(bigList) < (frameNum-1):
            #print('Warning: Frame {} has no good detections!'.format(len(bigList)+1))
            bigList.append(generateRandomBox(frameWidth, frameHeight))
        if len(bigList) < frameNum:
            bigList.append([])
        try:
            bigList[frameNum-1].append((bbox, score))
        except Exception as err:
            print(err)
            print('Likely cant find a detection for frame ', frameNum)
            print(len(bigList))
            print(arr)
            exit(-1)
    while len(bigList) < numFrames: 
        #print('Warning: Frame {} has no good detections!'.format(len(bigList)+1))
        bigList.append(generateRandomBox(frameWidth, frameHeight))
    return bigList


def convertMatToBBList(arr):
    bigList = []
    numDetections = 0
    for i in range(len(arr[0])):
        if arr[0][i] > arr[0][i+1]:
            numDetections = i+1
            break

    idx = 0
    for i in range(7):
        littleList = []
        """
        while idx < (numDetections*(i+1)):    cap.release()
    cv2.destroyAllWindows()


    cap.release()
    cv2.destroyAllWindows()
        """

        while idx < (numDetections*(i+1)):
            littleList.append(float(arr[0][idx]))
            idx+=1
        bigList.append(littleList)
    return bigList
    """
    (numRows, numCols) = arr.shape
    for r in range(numRows):
        f = int(arr[r,0])
        #arr[r,1] is redundant
        bbox = (float(arr[r,2]), float(arr[r,3]), float(arr[r,4]), float(arr[r,5]))
        score = float(arr[r,6])
        if len(bigList) < f:
            bigList.append([])
        bigList[f-1].append((bbox, score))
    return bigList
    """



def writeMatFile(bboxesFrameList, sequenceName):
    outputPath = ""
    gmmcpBBoxList = []
    for f in range(len(bboxesFrameList)):
        frameList = []
        for (box, score) in bboxesFrameList[f]:
            (x1,y1,x2,y2) = box
            frameList.append([x1,y1,x2,y2,score])
        gmmcpBBoxList.append(np.array(frameList, dtype=np.float64))
    
    print("array length is", len(gmmcpBBoxList))
    print("array size of first row is", gmmcpBBoxList[0].shape)
    detectionDict = {}
    detectionDict["detections"] = np.array(gmmcpBBoxList, dtype=np.object)
    
    
    print("detection shape is:", detectionDict["detections"].shape)
    print("detection first row is:", detectionDict["detections"][0])
        
    scipy.io.savemat("{}{}.mat".format(outputPath, sequenceName), detectionDict)
        



if len(sys.argv) < 5:
    print("Usage: gmmcp_wrapper.py detectionsFile numFrames frameWidth frameHeight imgPath")
    sys.exit(2)

#Clear out the results from last time, if any
if os.path.exists('GMMCP_LX.txt'):
    os.system('rm GMMCP_LX.txt')
    os.system('rm GMMCP_LY.txt')
    os.system('rm GMMCP_W.txt')
    os.system('rm GMMCP_H.txt')

#Clear the temporary directory    
tmpPath = './GMMCP_Tracker/tmpData/'
if os.path.exists(tmpPath):
    os.system('rm -r ' + tmpPath)
os.system('mkdir ' + tmpPath)

numFrames = int(sys.argv[2])
frameWidth = int(sys.argv[3])
frameHeight = int(sys.argv[4])
imgPath = sys.argv[5]

trackingResultsPath = './GMMCP_Tracker/trackingResults/DETRAC/'
if os.path.exists(trackingResultsPath):
    os.system('rm -r ' + trackingResultsPath)#Remove trackingResults directory for sequence before running gmmcp

d = scipy.io.loadmat(sys.argv[1])

detections = convertMatToBBList(d['detects'])
detections = formatBBList(detections, frameWidth, frameHeight, numFrames)
print("Converted to bbList with",len(detections), "elements")

# This SHOULD be hardcoded - we don't want to worry about conflicts here
writeMatFile(detections, "DETRAC-detections")

#Write to config file
with open('GMMCP_Tracker/config.txt', 'w') as configFile:
    configFile.write("../../../" + imgPath[2:] + '\n') ####3)
print('configFile written')
#RUN TRACKER
print('running tracker')
os.system('cd GMMCP_Tracker && flatpak run org.octave.Octave main.m')  # TODO: configure octave path?
print('tracking complete')

detracResFile = './' 

#Convert tracker result file into a format we can evaluate with DETRAC
resmatFile = trackingResultsPath + 'trackRes.mat' #This is the file name which is produced by main.m, we need to turn it into a format that DETRAC understands
bboxScoreIdList = convert.readMatFile(resmatFile)

GMMCP_LX = detracResFile + 'GMMCP_LX.txt' #generated files for input to DETRAC
GMMCP_LY = detracResFile + 'GMMCP_LY.txt'
GMMCP_H = detracResFile + 'GMMCP_H.txt'
GMMCP_W = detracResFile + 'GMMCP_W.txt'
convert.writeDETRACFiles(bboxScoreIdList, GMMCP_LX, GMMCP_LY, GMMCP_H, GMMCP_W) #Here is where the conversion actually happens ####5) and ####6)


os.system('rm GMMCP_Tracker/completed.txt')






#scipy.io.savemat("results.mat", {"speed":speed, 'trackList':trackList})
