from DAN_converter_scripts import convert_detections_to_DAN_input as convert_input
from DAN_converter_scripts import convert_DAN_results_to_detrac_input as convert_output
import sys
import os
import scipy.io
import numpy as np
import random
import csv

sys.path.append(os.path.abspath('./SST'))
import test_ua

print(sys.argv)

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
        



if len(sys.argv) < 6:
    print("Usage: dan_wrapper.py detectionsFile numFrames frameWidth frameHeight imgPath igrStr")
    sys.exit(2)

#TODO: Clear out the results from last time, if any
inputDir = './DAN-input/'
if os.path.exists(inputDir):
    os.system('rm -r ' + inputDir)
os.system('mkdir ' + inputDir)

detectionsDir = './DAN-input/detections/'
igrDir = './DAN-input/igr'
os.system('mkdir ' + detectionsDir)
os.system('mkdir ' + igrDir)

danOutputDir='./results-DAN/'
if os.path.exists(danOutputDir):
    os.system('rm -r ' + danOutputDir)

#Clear out the results from last time, if any
if os.path.exists('DAN_LX.txt'):
    os.system('rm DAN_LX.txt')
    os.system('rm DAN_LY.txt')
    os.system('rm DAN_W.txt')
    os.system('rm DAN_H.txt')


numFrames = int(sys.argv[2])
frameWidth = int(sys.argv[3])
frameHeight = int(sys.argv[4])
imgPath = '../../'+sys.argv[5]

#print('ignoreRegions:', ignoreRegions)
igrFile = None
if len(sys.argv) >= 7:
    ignoreRegions = sys.argv[6].split(',')
    igrFile=igrDir + "/MVI_99999.txt"
    with open(igrFile, "w") as f:
        writer = csv.writer(f)
        for i in range(0,len(ignoreRegions),4):
            row = []
            for j in range(4):
                row.append(float(ignoreRegions[i+j]))
            writer.writerow(row)



d = scipy.io.loadmat(sys.argv[1])
detections = convertMatToBBList(d['detects'])

detectFile = convert_input.convert_and_save_detections(detections, detectionsDir)
print("about to run")
seqName="DETRAC"
outFile = test_ua.run_DAN_once(imgPath, igrFile, detectFile, seqName, danOutputDir)
print("converting")
convert_output.convert_DAN_results_to_detrac_input(seqName, danOutputDir, '.', numFrames)
print("done")

