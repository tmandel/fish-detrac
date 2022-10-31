import cv2
import os
from tkinter.filedialog import askopenfilename
from matplotlib import pyplot as plt
from zipfile import ZipFile
import io


def extractFrames(videoFile):
    print("Reading video file")
    cap = cv2.VideoCapture(videoFile)
    count = 0
    #list of lists of boxes for all frames
    bboxesFrameList = []
    zipf = ZipFile(str(videoFile)[:-4] + ".zip", "w")
    ocount = 0;

    while cap.isOpened():
        if count % 10 == 0:
            print("Reading frame", count)

        #capture frame-by-frame
        ret, frameRGB = cap.read()

        if ret == True:
            #list of boxes and scores for one frame
            bboxScoreList = []
            frame = frameRGB[:, :, ::-1].copy()
           
        else:
            break

        
        imgNum = str(count)
        #dirName = str(videoFile)[:-4]
        # if not os.path.exists(dirName):
        #    os.makedirs(dirName)
        filename =  str(imgNum) + ".jpg"
        buf = io.BytesIO()
        plt.imsave(buf, frame/255., format='jpg')
        
        zipf.writestr(filename, buf.getvalue())
        buf.close()
        count += 1

    cap.release()
    cv2.destroyAllWindows()
    zipf.close()
    print("Total frames:",count)

videoFile = askopenfilename(title="Please select the video to convert", initialdir=".")
extractFrames(videoFile)

