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



def draw_caption2(image, box, caption):
    """ Draws a caption above the box in an image.
    # Arguments
        image   : The image to draw on.
        box     : A list of 4 elements (x1, y1, x2, y2).
        caption : String containing the text to draw.
    """
    b = np.array(box).astype(int)
    cv2.putText(image, caption, (b[0], b[1] - 10), cv2.FONT_HERSHEY_PLAIN, 5, (0, 0, 0), 6)
    cv2.putText(image, caption, (b[0], b[1] - 10), cv2.FONT_HERSHEY_PLAIN, 5, (255, 255, 255), 5)

def compileVideo(videoFile, newVideo, bboxList, methodName):
    count = 0
    fishIdToColorDict = {}
    #color = (255,0,255)
    print("Compiling video...")
    print('bboxList length:', len(bboxList))
    print('bbox[0] length', len(bboxList[0]))
    #random.seed(656565)
    cap = cv2.VideoCapture(videoFile)
    fourcc = cv2.VideoWriter_fourcc(*'mp4v')
    video = None
    #video = cv2.VideoWriter(newVideo, fourcc, 10, (width, height))
    print("VideoWriter initiated... running")
    while cap.isOpened():
        print("Writing frame", count)
        #capture frame-by-frame
        ret, frame = cap.read()
        if video is None:
            (height, width, numColor) = frame.shape
            video = cv2.VideoWriter(newVideo, fourcc, 24, (width, height))
            print(frame.shape)

        if ret == True:
            #frame[:, :, ::-1].copy()
            draw = frame.copy()
            #draw = cv2.cvtColor(draw, cv2.COLOR_BGR2RGB)

            boxScoreIdList = bboxList[count]
            #(boxes, scores) = boxScoreFrameList

            font                   = cv2.FONT_HERSHEY_SIMPLEX
            bottomLeftCornerOfText = (int(width*.05),int(height*.15))
            fontScale              = int(0.004*height)
            fontColor              = (255,255,255)
            lineThickness               = int(0.005*height)

            cv2.putText(draw,str(count), bottomLeftCornerOfText, font, fontScale, fontColor, lineThickness)

            bottomLeftCornerOfText = (int(width-width*.35),int(height*.15))
            cv2.putText(draw,methodName, bottomLeftCornerOfText, font, fontScale, fontColor, lineThickness)

            for tup in boxScoreIdList:
                if len(tup) == 2: #detection only
                    box, score = tup
                    if score > 0.5:
                        r = 255
                        g = 0
                        b = 255
                        draw_box(draw, box, color=(r,g,b), thickness=10)
                else:  # detection + fish ID

                    box, score, fishID = tup
                    if fishID is None:
                        continue
                    if fishID not in fishIdToColorDict:
                        cm = plt.get_cmap('gist_rainbow')
                        color = cm(random.random())
                       # m = 256
                        #r = random.randint(0,m)
                        #m -= r
                       # g = random.randint(0,m)
                       # m -= g
                        (r,g,b,a) = color
                        color = (r*255,g*255,b*255)
                        #print(color)
                        fishIdToColorDict[fishID] = color

                    #color = (255*score, 0, 255*score)
                    draw_box(draw, box, color=fishIdToColorDict[fishID], thickness=10)

                    caption = str(fishID)
                    draw_caption2(draw, box, caption)

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

    if len(sys.argv) < 5:
        print ("Usage: showOnVideo.py videoFile newVideo lx_file method")

        #python showOnVideo.py 02_Oct_18_Vid-3.mp4 light_fish_test.mp4 ..\results\GOG\R-CNN\0.2\02_Oct_18_Vid-3_LX.txt New_Method
        #python3 showOnVideo.py MVI_41073_0.mp4 car_test.mp4 ../results/GOG/R-CNN/0.2/MVI_41073_0.txt New_Method
        #Mark::python showOnVideo.py MVI_41073_0.mp4 car_test.mp4 ..\results\KPD\R-CNN\0.5\MVI_41073_0_LX.txt New_Method
        #Mark::python showOnVideo.py 02_Oct_18_Vid-3.mp4 light_fish_test.mp4 ..\results\KPD\R-CNN\0.5\02_Oct_18_Vid-3_LX.txt New_Method
        #Mark::python showOnVideo.py V1_Leleiwi_26June19_17.mp4 dark_fish_test.mp4 ..\results\KPD\R-CNN\0.5\V1_Leleiwi_26June19_17_LX.txt New_Method
        #Mark::python showOnVideo.py MVI_40141.mp4 kpd_40141.mp4 ..\results\KPD\R-CNN\0.5\MVI_40141_LX.txt KPD
    videoFile = sys.argv[1]
    newVideo = sys.argv[2]
    methodName = sys.argv[4]
    outputFile_LX = sys.argv[3]
    outputFile_LY = outputFile_LX[:-6] +"LY.txt"
    outputFile_H = outputFile_LX[:-6] +"H.txt"
    outputFile_W = outputFile_LX[:-6] +"W.txt"


    #takes in outputs from DETRAC (could also ground truth) and puts it into bbox-score-id
    bigList = reformatOutput(outputFile_LX, outputFile_LY, outputFile_H, outputFile_W)

    #print(bigList)
    #takes in original frame images [from image dir] (takes in bbox-id-list) draws colored bounding box
    compileVideo(videoFile, newVideo, bigList, methodName)
    #compileVideo(videoFile, newVideo,bigList,1920,1080, methodName)
