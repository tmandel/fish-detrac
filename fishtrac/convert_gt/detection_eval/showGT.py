import scipy.io
import sys
import numpy as np
import showOnVideo
#print(scipy.io.loadmat('02_Oct_18_Vid-3.mat'))

def convertFile(outprefix):
    matContents = scipy.io.loadmat(outprefix + ".mat")
    gtInfo = matContents['gtInfo']
    x = gtInfo['X'][0][0]
    x=x.astype('int')
    y = gtInfo['Y'][0][0]
    y=y.astype('int')
    (numFrame, numCars)=y.shape
    #print("numFrame", numFrame)
    #print("numCars", numCars)

    h = gtInfo['H'][0][0]
    h=h.astype('int')
    w = gtInfo['W'][0][0]
    w=w.astype('int')
    xNew = list(x)

    yNew = list(y)

    wNew = list(w)
    hNew = list(h)
    for i in range(len(xNew)):
        xNew[i] = xNew[i] - (wNew[i]/2)
    for i in range(len(yNew)):
        yNew[i] = yNew[i] - (hNew[i])

    hfname = outprefix + "_H.txt"
    wfname = outprefix + "_W.txt"
    lxfname = outprefix + "_LX.txt"
    lyfname = outprefix + "_LY.txt"
    #output csv files
    hf = open(hfname, "w+")
    wf = open(wfname, "w+")
    xf = open(lxfname, "w+")
    yf = open(lyfname, "w+")

    for f in range(numFrame):
        #print('frame: ', f)
        hf.write(",".join(map(str, hNew[f])) + "\n")
        wf.write(",".join(map(str, wNew[f])) + "\n")
        xf.write(",".join(map(str, xNew[f])) + "\n")
        yf.write(",".join(map(str, yNew[f])) + "\n")

    hf.close()
    wf.close()
    xf.close()
    yf.close()
    return (hfname, wfname, lxfname, lyfname)

if __name__ == "__main__":
    if len(sys.argv) < 2:
        print("Usage: showGT videoFile.mp4")
    videoFile = sys.argv[1]
    outPrefix = videoFile[:-4]
    (h, w, x, y) = convertFile(outPrefix)
    bigList = showOnVideo.reformatOutput(x,y,h,w)
    showOnVideo.compileVideo(videoFile, (outPrefix + "_GT.mp4"), bigList, "GT")
	
	
	
