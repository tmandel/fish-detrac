from tkinter.filedialog import askopenfilename
import vatic_to_csv_and_mat
import videoToFolder
import showOnVideo
import os
from os import path



videoFile = askopenfilename(title="Please select the video", initialdir=".")
prefix = videoFile[:-4]
annotations = prefix + ".xml"

#Check if video has annotations
if path.exists(annotations) == False :
    frameHeight, frameWidth = videoToFolder.rewriteVideo(videoFile)
    print("Does not exists")
else :

    #convert to csv and mat
    (hf, wf, xf, yf) = vatic_to_csv_and_mat.convertFile(annotations, prefix)

    #convert video to folder of images
    frameHeight, frameWidth = videoToFolder.rewriteVideo(videoFile)

    #takes in outputs from DETRAC (could also ground truth) and puts it into bbox-score-id
    bigList = showOnVideo.reformatOutput(xf, yf, hf, wf)

    #os.system('python showGT.py ' + videoFile)

    newVideo = prefix + "_GT.mp4"
    #takes in original frame images [from image dir] (takes in bbox-id-list) draws colored bounding box
    showOnVideo.compileVideo(videoFile,newVideo, bigList,"GT")
