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

def compileVideo(videoFile, newVideo, bboxList, width, height, cutoff):
	count = 0
	fishIdToColorDict = {}
	#color = (255,0,255)
	print("Compiling video...")

	cap = cv2.VideoCapture(videoFile)
	fourcc = cv2.VideoWriter_fourcc(*'mp4v')
	video = cv2.VideoWriter(newVideo, fourcc, 10, (width, height))
	print("VideoWriter initiated...")
	while cap.isOpened():
		print("Writing frame", count)
		#capture frame-by-frame
		ret, frame = cap.read()
		
		if ret == True:
			#frame[:, :, ::-1].copy()
			draw = frame.copy()
			#draw = cv2.cvtColor(draw, cv2.COLOR_BGR2RGB)
			
			if count >= len(bboxList):
				boxScoreIdList = []
			else:
				boxScoreIdList = bboxList[count]
			#(boxes, scores) = boxScoreFrameList

			font				   = cv2.FONT_HERSHEY_SIMPLEX
			bottomLeftCornerOfText = (100,200)
			fontScale			   = 5
			fontColor			   = (255,255,255)
			lineThickness				= 10

			cv2.putText(draw,str(count), bottomLeftCornerOfText, font, fontScale, fontColor, lineThickness)
			
			bottomLeftCornerOfText = (width-800,200)
			method = "Detec-"+str(cutoff)
			if cutoff <= 0.0000001:
				method = "Detec-All"
			cv2.putText(draw,method, bottomLeftCornerOfText, font, fontScale, fontColor, lineThickness)
			
			for tup in boxScoreIdList:
				if len(tup) == 2: #detection only
					box, score = tup
					if score > cutoff:
						#print(box)
						r = 255
						g = 0
						b = 255
						draw_box(draw, box, color=(r,g,b), thickness=5)
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
					draw_box(draw, box, color=fishIdToColorDict[fishID], thickness=5)
			
					caption = str(fishID)
					draw_caption(draw, box, caption)
			
			video.write(draw)

			count += 1
		else:
			break

	cap.release()
	video.release()
	cv2.destroyAllWindows()



#load saved detections
def loadDetections(detectionsFile):
	f = open(detectionsFile, "r")
	reader = csv.reader(f)
	retList = []
	for row in reader:
		frame = int(row[0])-1
		while frame >= len(retList):
			retList.append([])
		(x,y,w,h)= (int(float(row[2])), int(float(row[3])), int(float(row[4])), int(float(row[5]))) #x,y,w,h
		box = (x,y,x+w,y+h)
		#print(box)
		score = float(row[6])
		
		retList[frame].append((box,score))
	return retList
		


#main

if __name__ == "__main__":
	
	if len(sys.argv) < 5:
		print ("Usage: showDetections.py videoFile newVideo detectionsFile cutoff")
		#python showOnVideo.py 02_Oct_18_Vid-3.mp4 kpd_test.mp4 ..\results\KPD\R-CNN\0.2\02_Oct_18_Vid-3_LX.txt New_Method
		
	videoFile = sys.argv[1]
	newVideo = sys.argv[2]
	cutoff = float(sys.argv[4])
	detectionsFile = sys.argv[3]


	#takes in outputs from DETRAC (could also ground truth) and puts it into bbox-score-id
	bbList = loadDetections(detectionsFile)

	#print(bigList)
	#takes in original frame images [from image dir] (takes in bbox-id-list) draws colored bounding box
	#compileVideo(videoFile, newVideo,bbList,2304,1296, cutoff)
	compileVideo(videoFile, newVideo,bbList,1920,1080, cutoff)

