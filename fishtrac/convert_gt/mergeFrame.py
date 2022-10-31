import cv2
import sys
import os
from tkinter.filedialog import askdirectory
from matplotlib import pyplot as plt
import matplotlib.image as mpimg

MAX_FRAMES = 300 #should be 300

def mergeVideo(targetDir):
    count = 0
    mcount = 0
    #color = (255,0,255)
    newVideo = str(targetDir) + ".mp4"
    print("Compiling video...")
    fourcc = cv2.VideoWriter_fourcc(*'mp4v')
    print(newVideo)    
    video = None
    num = 0
    while True:
        try: 
            num += 1
            imgID = str(num).zfill(5)
            fileName = str(targetDir)+ os.sep +'img'+ str(imgID) + '.jpg'

            img = mpimg.imread(fileName)

            img = img[:,:,::-1]  #Flipping RGB to BGR - needed for FISHTRAC

            (height, width, channels) = img.shape
            if video is None:
                video = cv2.VideoWriter(newVideo, fourcc, 24, (width, height))
                #frame[:, :, ::-1].copy()
            video.write(img)  
        except FileNotFoundError:
            break

    video.release()
    cv2.destroyAllWindows()
    
#targetDir = askdirectory(title="Please select the target directory", initialdir=".")
if len(sys.argv) < 2:
    print("Usage: python mergeFrame.py imageDirectory")
    sys.exit(2)
targetDir = sys.argv[1]
print(targetDir)
mergeVideo(targetDir)
