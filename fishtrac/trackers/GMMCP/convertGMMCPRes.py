import csv
import sys


def readMatFile(filename):
    myFile = open(filename, "r")
    miniList = []
    bboxList = []

    bboxDict = {}
    
    for line in myFile:
        if line[0] == "#":
            continue
        elif line == "":
            continue
        else:
            lineList = line.split()
            if lineList == []:
                continue
            boxTuple = tuple(lineList[2:])
            (x1, y1, x2, y2) = boxTuple
            x1 = round(float(x1))
            y1 = round(float(y1))
            x2 = round(float(x2))
            y2 = round(float(y2))
            boxTuple = (x1, y1, x2, y2)
            #print(lineList)
            miniList = [boxTuple, 1, int(lineList[1])]
            key = int(lineList[0])
            if key in bboxDict:
                bboxDict[key].append(miniList) 
            else:
                bboxDict[key] = [miniList]
            #lineList = lineList[0:2]
            #lineList.append(boxTuple)

        #bboxList.append(lineList)
    maxFrame = None
    for key in bboxDict:
        if maxFrame is None or key > maxFrame:
            maxFrame = key

    for f in range(1,maxFrame+1):
        #print(f)
        bboxList.append(bboxDict.get(f,[]))
    #bboxList.append([[(0,0,0,0), 0, 0]])
    #print("dict:", len(bboxDict))
    #print("list:", len(bboxList))
    #print(bboxList)
    return bboxList


def writeDETRACFiles(bigList, LX, LY, H, W):

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
        #print(frame)
        for box, score,fishID in frame:
            if fishID is None:
                continue
            print (box, score,fishID)
            if fishID > maxFishID:
                maxFishID = fishID
            while len(xLists[fnum]) < maxFishID:
                xLists[fnum].append(0)
                yLists[fnum].append(0)
                wLists[fnum].append(0)
                hLists[fnum].append(0)
            (x1,y1,x2,y2) = box
            width = x2-x1
            height = y2-y1
            xLists[fnum][fishID-1] = x1+width/2
            yLists[fnum][fishID-1] = y1+height
            wLists[fnum][fishID-1] = width
            hLists[fnum][fishID-1] = height


    for fnum in range(len(xLists)):
        while len(xLists[fnum]) < maxFishID:
            xLists[fnum].append(0)
            yLists[fnum].append(0)
            wLists[fnum].append(0)
            hLists[fnum].append(0)

                
    
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




if __name__ == "__main__":
    if(len(sys.argv) < 2):
        print("Usage: convertGMMCPRes.py resultFile")
    resultFile = sys.argv[1]
    GMMCP_LX = 'conv_results/GMMCP_LX.txt'# generated files for input to DETRAC
    GMMCP_LY = 'conv_results/GMMCP_LY.txt'
    GMMCP_H = 'conv_results/GMMCP_H.txt'
    GMMCP_W = 'conv_results/GMMCP_W.txt'
    #takes in GMMCP output and converts it to bbscore-id-list
    bboxScoreIdList = readMatFile(resultFile)

    #write bbox-score-id list out to a file which can be used as input to DETRAC
    writeDETRACFiles(bboxScoreIdList, GMMCP_LX, GMMCP_LY, GMMCP_H, GMMCP_W)