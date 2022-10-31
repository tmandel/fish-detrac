import xml.etree.ElementTree as ET
import scipy.io
import sys
import numpy as np
import cv2

#print(scipy.io.loadmat('02_Oct_18_Vid-3.mat')

def convertFile(filename, outprefix):

    cap = cv2.VideoCapture(outprefix + '.mp4')
    numFrames = int(cap.get(cv2.CAP_PROP_FRAME_COUNT))
    print('numFrames', numFrames)

    root = ET.parse(filename).getroot()
    print(root)
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

    for fish in root.findall('./object'): #object represents track
        print(fish)#object
        seenFrames = set([])
        for poly in fish.findall('polygon'): #polygon represents bounding box
            frame = int(poly.find('t').text)
            if frame in seenFrames:
                print('warning! single fish appears twice on same frame')
            seenFrames.add(frame)

            #This loop is causing problems I believe - mark
            while frame >= len(frame_LX):
                frame_LX.append([])
                frame_LY.append([])
                frame_H.append([])
                frame_W.append([])
                out_LX.append([])
                out_LY.append([])
                out_H.append([])
                out_W.append([])

            xs = []
            for x in poly.findall('pt/x'):
                xs.append(int(x.text))
            ys = []
            for y in poly.findall('pt/y'):
                ys.append(int(y.text))
            x1 = min(xs)
            x2 = max(xs)
            y1 = min(ys)
            y2 = max(ys)
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


        for f in range(len(frame_LX)):
            if f in seenFrames:
                continue
            frame_LX[f].append(0)
            frame_LY[f].append(0)
            frame_H[f].append(0)
            frame_W[f].append(0)
            out_LX[f].append(0)
            out_LY[f].append(0)
            out_H[f].append(0)
            out_W[f].append(0)

    #print(len(frame_LX))
    #for row in frame_LX:
        #print(len(row))


    frameNums = np.array(range(1, len(frame_LX)+1),dtype='float64')
    X = np.array(frame_LX,dtype='float64')
    Y = np.array(frame_LY,dtype='float64')
    W = np.array(frame_W,dtype='float64')
    H = np.array(frame_H,dtype='float64')
    resStruct = {'X':X, 'Y':Y, 'H':H, 'W':W, 'frameNums':frameNums}
    scipy.io.savemat(outprefix+".mat", {'gtInfo':resStruct})



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
    return (hfname, wfname, lxfname, lyfname)
