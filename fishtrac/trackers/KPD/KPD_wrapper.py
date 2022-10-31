import sys
import os
import scipy.io
import kpd_tracker as kpd
import csv
import cv2
import showOnVideo
import outputDetectorPredictions as opd
import numpy as np
from keras_retinanet import models


print(sys.argv)

if len(sys.argv) < 1:
    print("Usage: KPD_wrapper.py vidPath")
    sys.exit(2)
model = models.load_model(opd.get_modelPath(), backbone_name='resnet50')
vid = cv2.VideoCapture(sys.argv[1])
images = []
bigList = []
frameNum = 0
while vid.isOpened():
    ret, frame = vid.read()
    if not ret:
        break
    print("Reading frame",frameNum+1)
    images.append(frame)
    bboxScoreList = []
    frameHeight, frameWidth, layers = frame.shape
    boxes, scores, labels = opd.get_predicted_boxes(model, frame)
    for box, score, label in zip(boxes[0], scores[0], labels[0]):
        if score < 0:
            break
        b = box.astype(int)
        (x1,y1,x2,y2) = b
        height = y2 - y1
        width = x2 - x1
        reformatted_b = (x1,y1,width,height)
        while len(bigList) < frameNum+1:
            bigList.append([])
        bigList[frameNum].append((reformatted_b, score))
    frameNum += 1


vid.release()
cv2.destroyAllWindows()        

# f = open(sys.argv[1],"r")
# reader = csv.reader(f)

# bigList = []

# for row in reader:
    # f = int(row[0])
    # bbox = (float(row[2]), float(row[3]), float(row[4]), float(row[5]))
    # score = float(row[6])
    # while len(bigList) < f:
        # bigList.append([])
    # bigList[f-1].append((bbox, score))

numFrames = len(bigList)

# if len(sys.argv) == 7:
    # ignoreRegions = sys.argv[6].split(',')
    # igr = []
    # for i in range(0,len(ignoreRegions),4):
        # row = []
        # for j in range(4):
            # row.append(float(ignoreRegions[i+j]))
        # igr.append(row)
    # frameWidth = int(sys.argv[4])
    # frameHeight = int(sys.argv[5])
# elif len(sys.argv) == 6:
    # frameWidth = int(sys.argv[4])
    # frameHeight = int(sys.argv[5])
    # igr = None
# elif len(sys.argv) == 4:
    # vid = cv2.VideoCapture(sys.argv[3])
    # frameHeight = vid.get(cv2.CAP_PROP_FRAME_HEIGHT)
    # frameWidth = vid.get(cv2.CAP_PROP_FRAME_WIDTH)
    # igr=None
# else:
    # image = cv2.imread(imgPath+'/img00001.jpg')
    # height, width, _ = image.shape
    # if len(sys.argv) == 5:
        # frameWidth = int(sys.argv[4])
        # frameHeight = height
    # else:
        # frameWidth = width
        # frameHeight = height
    # igr = None

time, trackList = kpd.track_kpd_vid(bigList, numFrames, frameWidth, frameHeight, images)

# scipy.io.savemat("results.mat", {"speed":speed, 'trackList':trackList})
# #showOnVideo.compileVideo(sys.argv[1], 'results.mp4', bigList, 'KPD')
# mat = scipy.io.loadmat('results.mat')
# trackList = mat['trackList']

# (_,_,_,_,totalFrames,totalId) = trackList.max(axis=0)
# int(totalFrames)
maxFrames = 0
maxID = 0
for row in trackList:
    if row[4] > maxFrames:
        maxFrames = row[4]
    if row[5] > maxID:
        maxID = row[5]
matrixShape = (int(maxFrames),int(maxID))
lx = np.zeros(matrixShape)
ly = np.zeros(matrixShape)
wi = np.zeros(matrixShape)
hi = np.zeros(matrixShape)


for rows in trackList:
    (x,y,w,h,f,i) = rows
    lx[int(f-1)][int(i-1)] = x
    ly[int(f-1)][int(i-1)] = y
    wi[int(f-1)][int(i-1)] = w
    hi[int(f-1)][int(i-1)] = h

np.savetxt('results_LX.txt', lx, delimiter=',')
np.savetxt('results_LY.txt', ly, delimiter=',')
np.savetxt('results_W.txt', wi, delimiter=',')
np.savetxt('results_H.txt', hi, delimiter=',')

bigList = showOnVideo.reformatOutput('results_LX.txt','results_LY.txt','results_H.txt','results_W.txt')
showOnVideo.compileVideo(sys.argv[1], 'results.mp4', bigList, 'KPD')
