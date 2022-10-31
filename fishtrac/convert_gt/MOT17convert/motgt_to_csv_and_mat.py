import xml.etree.ElementTree as ET
import scipy.io
import sys
import numpy as np
import cv2
import csv

#print(scipy.io.loadmat('02_Oct_18_Vid-3.mat')

def finalize_track(frame_LX, frame_LY, frame_H, frame_W, out_LX, out_LY, out_H, seenFrames, idn):

    for f in range(len(frame_LX)):
        if f in seenFrames:
            continue
        #if f==515:
        #    print("frame 500  idn", idn)
        frame_LX[f].append(0)
        frame_LY[f].append(0)
        frame_H[f].append(0)
        frame_W[f].append(0)
        out_LX[f].append(0)
        out_LY[f].append(0)
        out_H[f].append(0)

def convertFile(videoPath, outprefix):

    #TODO: Get numFrames from seqinfo file
    numFrames = None 
    with open(videoPath+"/seqinfo.ini") as f:
        for line in f:
            if line.startswith("seqLength="):
                numFrames = int(line.split("=")[-1])
                break
                
    


    frame_LX = [] #frames to list of xs
    frame_LY = []
    frame_H = []
    frame_W = []

    out_LX = []
    out_LY = []
    out_H = []
    out_W = []

    while len(frame_LX) < numFrames:
        frame_LX.append([])
        frame_LY.append([])
        frame_H.append([])
        frame_W.append([])
        out_LX.append([])
        out_LY.append([])
        out_H.append([])
        out_W.append([])

    f = open(videoPath+"/gt/gt.txt", "r")
    
    currentIDIndex = 0
    seenFrames = set([]) #Frames seen for this ID
    skipID = False
    realTracks = 0

    reader = csv.reader(f)
    for row in reader:
        # all are ints excepot for visibility
        [frame,idn,left,top,width,height,include,cls] = map(int, row[:-1])
        visibility = float(row[-1])
        frame -= 1 #MOT indexes by 1
        
        if skipID is True and idn == currentIDIndex:
            if include == 1:
                print("Error, mixed include for idn", idn, "at frame", frame)
                sys.exit(1)
            continue

        if include != 1:
            if idn == currentIDIndex:
                print("Error, mixed include for idn", idn, "at frame", frame)
                sys.exit(1)
            if currentIDIndex>0 and not skipID:
                realTracks+=1
                finalize_track(frame_LX, frame_LY, frame_H, frame_W, out_LX, out_LY, out_H, seenFrames,currentIDIndex)
            seenFrames = set([]) #Frames seen for this ID
            currentIDIndex +=1 
            skipID= True
            #print("Include is ", include, "for idn", idn, "at frame", frame)
            continue
        #assert(include == 1)
        assert(cls == 1)
        if idn  == currentIDIndex+1:
            
            #start of new track
            
            if currentIDIndex > 0:
                if not skipID:
                    realTracks+=1
                    finalize_track(frame_LX, frame_LY, frame_H, frame_W, out_LX, out_LY, out_H, seenFrames,currentIDIndex)
            seenFrames = set([]) #Frames seen for this ID
            skipID = False

            currentIDIndex = idn

            print(idn) #object
        elif idn != currentIDIndex:
            print("Error! current ID is ", currentIDIndex, "but row contains idn", idn)
            sys.exit(1)            
      
        if frame in seenFrames:
            print('warning! single fish appears twice on same frame', idn)
            sys.exit(1)            
        seenFrames.add(frame)

        
        #if frame==515:
        #    print("frame 500  idn", idn)

        x1 = left
        x2 = left+width
        y1 = top
        y2 = top+height
        #we need to transform our coordinate format into
        #format that DETRAC expects
        frame_LX[frame].append(int((x1+x2)/2))
        frame_LY[frame].append(y2)
        frame_H[frame].append(y2-y1)
        frame_W[frame].append(x2-x1)
        out_LX[frame].append(x1)
        out_LY[frame].append(y1)
        out_H[frame].append(y2-y1)
        out_W[frame].append(x2-x1)

    if currentIDIndex > 0 and not skipID:
        realTracks+=1
        finalize_track(frame_LX, frame_LY, frame_H, frame_W, out_LX, out_LY, out_H, seenFrames,currentIDIndex)

        seenFrames = set([]) #Frames seen for this ID
            
    print("Number of included tracks", realTracks)

    #print("frameLX len", len(frame_LX))
    #print("element ",0,"len", len(frame_LX[0]))
    #print("element ",500,"len", len(frame_LX[500]))
    #for r in range(len(frame_LX)):
    #    if len(frame_LX[r]) != len(frame_LX[0]):
    #        print("element ",r,"len", len(frame_LX[r]))


    frameNums = np.array(range(1, len(frame_LX)+1),dtype='float64')
    X = np.array(frame_LX,dtype='float64')
    Y = np.array(frame_LY,dtype='float64')
    W = np.array(frame_W,dtype='float64')
    H = np.array(frame_H,dtype='float64')
    resStruct = {'X':X, 'Y':Y, 'H':H, 'W':W, 'frameNums':frameNums}
    scipy.io.savemat(outprefix+".mat", {'gtInfo':resStruct})


    '''
    hfname = outprefix + "_H.txt"
    wfname = outprefix + "_W.txt"
    lxfname = outprefix + "_LX.txt"
    lyfname = outprefix + "_LY.txt"
    #output csv files
    hf = open(hfname, "w+")
    wf = open(wfname, "w+")
    xf = open(lxfname, "w+")
    yf = open(lyfname, "w+")

    for f in range(len(frame_LX)):
        hf.write(",".join(map(str, out_H[f])) + "\n")
        wf.write(",".join(map(str, out_W[f])) + "\n")
        xf.write(",".join(map(str, out_LX[f])) + "\n")
        yf.write(",".join(map(str, out_LY[f])) + "\n")

    hf.close()
    wf.close()
    xf.close()
    yf.close()
    '''
    #return (hfname, wfname, lxfname, lyfname)

if __name__ == '__main__':
    if len(sys.argv) < 3:
        print("Usage:", sys.argv[0], " videoPath outputPath")
        sys.exit(2)
    videoPath = sys.argv[1]
    videoName = videoPath.split("/")[-1]
    print("Video name", videoName)
    outputPath = sys.argv[2]
    outPrefix = outputPath + videoName
    convertFile(videoPath, outPrefix)
