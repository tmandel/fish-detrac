# File added by Travis Mandel to make the tracker work with the FISHTRAC codebase
import csv

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
