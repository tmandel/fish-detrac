import cv2
import os, sys
from os.path import isfile, join
import numpy as np
from tkinter.filedialog import askopenfilename
from matplotlib import pyplot as plt

def rewriteVideo(videoFile):
    print("Reading video file")
    cap = cv2.VideoCapture(videoFile)
    count = 1
    #list of lists of boxes for all frames
    bboxesFrameList = []
    height = None
    width = None

    while cap.isOpened():
        if count % 10 == 0:
            print("Reading frame", count)

        #capture frame-by-frame
        ret, frameRGB = cap.read()
        

        if not ret:
            break

        frameRGB = cv2.cvtColor(frameRGB, cv2.COLOR_BGR2RGB)
        height, width, layers = frameRGB.shape
        
        # uncomment to save frames as images
        imgNum = str(count).zfill(5)
        dirName = str(videoFile)[:-4]
        if not os.path.exists(dirName):
            os.makedirs(dirName)
        filename = dirName + "/img" + str(imgNum) + ".jpg"
        plt.imsave(filename, frameRGB/255.)
        count += 1

    cap.release()
    cv2.destroyAllWindows()
    print("Total frames:",count)
    return height, width


#main

if __name__ == "__main__":
	videoFile = askopenfilename(title="Please select the video to convert", initialdir=".")
	rewriteVideo(videoFile)
