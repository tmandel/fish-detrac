import cv2
import os
from tkinter.filedialog import askopenfilename
from matplotlib import pyplot as plt

MAX_FRAMES = 300 #should be 300


def splitVideo(videoFile):
    count = 0
    mcount = 0
    fishIdToColorDict = {}
    #color = (255,0,255)
    newVideo = str(videoFile)[:-4] +"_" + str(mcount) + ".mp4"
    print("Compiling video...")

    cap = cv2.VideoCapture(videoFile)
    fourcc = cv2.VideoWriter_fourcc(*'mp4v')
    video = None 
    print("VideoWriter initiated...")
    while cap.isOpened():
        if count % 20 == 0:
           print("Writing frame", count)
        #capture frame-by-frame
        ret, frame = cap.read()
        
        
        if ret == True:
            (height, width, channels) = frame.shape
            if video is None:
                video = cv2.VideoWriter(newVideo, fourcc, 30, (width, height))
            #frame[:, :, ::-1].copy()
            
                
            
            video.write(frame)
            
            count += 1
            if count >= MAX_FRAMES:
                print("starting new video")
                video.release()
                count = 0
                mcount += 1
                newVideo = str(videoFile)[:-4] +"_" + str(mcount) + ".mp4"
                video = cv2.VideoWriter(newVideo, fourcc, 30, (width, height))

            
        else:
            break

    cap.release()
    video.release()
    cv2.destroyAllWindows()
    
videoFile = askopenfilename(title="Please select the video to split", initialdir=".")
splitVideo(videoFile)
