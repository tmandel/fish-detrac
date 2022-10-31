import csv
import cv2
#import keras
#from keras.preprocessing import image
#from keras_retinanet import models
import matplotlib.pyplot as plt
#from keras_retinanet.utils.image import read_image_bgr, preprocess_image, resize_image
from keras_retinanet.utils.visualization import draw_box, draw_caption
#from keras_retinanet.utils.colors import label_color
import os, sys
from os.path import isfile, join
import numpy as np
import random
#import mat4py
import scipy.io
from collections import defaultdict

def compileVideo(videoFile, newVideo, bboxList, width, height):
    count = 0
    fishIdToColorDict = {}
    #color = (255,0,255)
    print("Compiling video...")

    cap = cv2.VideoCapture(videoFile)
    fourcc = cv2.VideoWriter_fourcc(*'mp4v')
    video = cv2.VideoWriter(newVideo, fourcc, 29, (width, height))
    print("VideoWriter initiated...")
    while cap.isOpened():
        print("Writing boxes to frame", count)
        #capture frame-by-frame
        ret, frame = cap.read()
        
        if ret == True:
            #frame[:, :, ::-1].copy()
            draw = frame.copy()
            #draw = cv2.cvtColor(draw, cv2.COLOR_BGR2RGB)
                
            boxScoreIdList = bboxList[count]
            #(boxes, scores) = boxScoreFrameList

            
            for tup in boxScoreIdList:
                if len(tup) == 2: #detection only
                    box, score = tup
                    if score > 0.5:
                        r = 255
                        g = 0
                        b = 255
                        draw_box(draw, box, color=(r,g,b), thickness=5)
                else:  # detection + fish ID
                    box, score, fishID = tup
                    if fishID is None:
                        continue
                    if fishID not in fishIdToColorDict:
                        r = random.randint(0,255)
                        g = random.randint(0,255)
                        b = random.randint(0,255)
                        color = (r,g,b)
                        fishIdToColorDict[fishID] = color

                    #color = (255*score, 0, 255*score)
                    draw_box(draw, box, color=fishIdToColorDict[fishID], thickness=5)
            
                    caption = str(fishID)
                    print(caption)
                    draw_caption(draw, box, caption)
            
            video.write(draw)

            count += 1
        else:
            break

    cap.release()
    video.release()
    cv2.destroyAllWindows()



    
def reformatOutput(LX, LY, H, W):

    outLX = open(LX, "r")
    outLY = open(LY, "r")
    outH = open(H, "r")
    outW = open(W,"r")

    xList = list(csv.reader(outLX,delimiter=","))
    yList = list(csv.reader(outLY,delimiter=","))
    hList = list(csv.reader(outH,delimiter=","))
    wList = list(csv.reader(outW,delimiter=","))

    comboList = list(zip(xList,yList,hList,wList))

    bigList = []

    for x1List, y1List, h1List, w1List in comboList:
        frameList=[]
        for i in range(len(x1List)):
            if round(float(h1List[i])) == 0 or round(float(w1List[i])) == 0:
                continue
            
            x1 = round(float(x1List[i]))
            y1 = round(float(y1List[i]))
            x2 = x1 + round(float(w1List[i]))
            y2 = y1 + round(float(h1List[i]))
            bbox = (x1, y1, x2, y2)

            score = None

            fishID = i

            miniList = [bbox, score, fishID]

            frameList.append(miniList)

        bigList.append(frameList)
            
    outLX.close()
    outLY.close()
    outH.close()
    outW.close()

    return bigList

#main

if __name__ == "__main__":
    

    videoFile = 'V1_Leleiwi_26June19_0.mp4'
    resultFile = 'trackRes.mat'
    outputFile_LX = 'Vid3_LX.txt'# .txt are from DETRAC, .csv come from Max
    outputFile_LY = 'Vid3_LY.txt'
    outputFile_H = 'Vid3_H.txt'
    outputFile_W = 'Vid3_W.txt'
    imgDir = './02_Oct_18_Vid-3/'
    Eighty_LX = 'Eighty_LX.txt'# generated files for input to DETRAC
    Eighty_LY = 'Eighty_LY.txt'
    Eighty_H = 'EIghty_H.txt'
    Eighty_W = 'Eighty_W.txt'
    GMMCP_LX = 'GMMCP_LX.txt'# generated files for input to DETRAC
    GMMCP_LY = 'GMMCP_LY.txt'
    GMMCP_H = 'GMMCP_H.txt'
    GMMCP_W = 'GMMCP_W.txt'




    #takes in outputs from DETRAC (could also ground truth) and puts it into bbox-score-id
    bigList = reformatOutput(outputFile_LX, outputFile_LY, outputFile_H, outputFile_W)

    #takes in original frame images [from image dir] (takes in bbox-id-list) draws colored bounding box
    compileVideo(videoFile,bigList,1920,1080)
