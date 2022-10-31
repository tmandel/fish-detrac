#!C:\Users\NSF\.conda\envs\tf_gpu
from time import time
import numpy as np
import random
import math
import sys
from numpy import ma
from util import load_mot, iou, interp_tracks
import cv2
#from cv2 import optflow
from matplotlib import pyplot as plt
from scipy.stats import norm

MIN_START_CONFIDENCE = 0.0 #If all boxes on a track have less than this, do not include



def toCornerForm(box):
	x,y,w,h = box
	return (x, y, x+w, y+h)

def boxOverlap(box1, box2):
	if box1 is None or box2 is None:
		return False # edge case
	#get coordinates from boxes
	col1box1, row1box1, col2box1, row2box1 = toCornerForm(box1)
	col1box2, row1box2, col2box2, row2box2 = toCornerForm(box2)

	#get intersection rectangle coords
	colA = max(col1box1, col1box2)
	rowA = max(row1box1, row1box2)
	colB = min(col2box1, col2box2)
	rowB = min(row2box1, row2box2)

	#check if overlapped
	if colB <= colA:
		return False
	if rowB <= rowA:
		return False

	return True



def scaleBox( box, fw, fh, scaleUpOrDown):
	x1,y1,owidth, oheight = map(int,  box)
	if scaleUpOrDown == 'down':
		scale = 300/max(fw, fh)
	elif scaleUpOrDown == 'up':
		scale = max(fw, fh)/300
	else:
		print('FAILURE TO SCALE BOX, choose "up" or "down"')
		quit()
	width = int(owidth * scale)
	height = int(oheight * scale)
	x1 = int(x1 * scale)
	y1 = int(y1 * scale)
	return (x1,y1,width, height)




def getNewBoxColorTracker( newImage, frameIndex, tracker, frameWidth, frameHeight, direction):
	"""note to Mark: need two indices to log which frames we have already updated,
	if that frame was updated and we didnt choose it, that frame is cached so that
	we can return it next time without updating(and thereby skewing)
	tracker a second time with same frame
	"""
	#our image format is a numpy array, we need to convert this to an opencv formatted image
	#FORWARD
	located=True
	if direction == 'forward':
		if tracker['highestFrameIndex'] == frameIndex:
			newBox = tracker['highestCachedBox']
			#print('getNewColorTracker::used Cached Box forward')
		else:
			located, newBox = tracker['forwardTracker'].update(newImage)
			if not located:
				newBox=None
				#print('Not Located')
			tracker['highestCachedBox'] = newBox
			tracker['highestFrameIndex'] = frameIndex
	#BACKWARD
	else:
		if tracker['lowestFrameIndex'] == frameIndex:
			newBox = tracker['lowestCachedBox']
			#print('getNewColorTracker::used Cached Box backward')
		else:
			located, newBox = tracker['backwardTracker'].update(newImage)
			if not located:
				newBox=None
				#print('Not Located')
			tracker['lowestCachedBox'] = newBox
			tracker['lowestFrameIndex'] = frameIndex
	if newBox is not None:
		newBox = scaleBox(newBox, frameWidth, frameHeight, 'up')
	return newBox

def initExternalTracker( startFrameIndex, startImage, startBox):
	#Instantiate KCF tracker
	forwardTracker = cv2.TrackerKCF_create()
	possibleFor = forwardTracker.init(startImage, startBox)
	#if not possibleFor:
		#print('Line 1498, cv.tracker.init failed')
	backwardTracker = cv2.TrackerKCF_create()
	possibleBack=backwardTracker.init(startImage, startBox)
	#if not possibleBack:
		#print('Line 1498, cv.tracker.init failed')
	#create dictionary
	visTracker = {}
	visTracker['forwardTracker'] = forwardTracker
	visTracker['backwardTracker'] = backwardTracker
	visTracker['highestFrameIndex'] = startFrameIndex  #these indices are used in getNewBoxColorTracker to remember which frames we have already viewed
	visTracker['lowestFrameIndex'] = startFrameIndex
	visTracker['highestCachedBox'] = None
	visTracker['lowestCachedBox'] = None

	return visTracker

def generateSingleTrackKCF(startingIndex, numFrames, bbox, images, frameWidth, frameHeight):
	#startingIndex is zero indexed
	track = []
	entry = (startingIndex+1, bbox)
	track.append(entry)
	newBox = None
	#instantiate tracker
	trackerStartBox = scaleBox(bbox, frameWidth, frameHeight, 'down')
	trackerKCF = initExternalTracker(startingIndex, images[startingIndex], trackerStartBox)
	backwardIndex = startingIndex
	forwardIndex = startingIndex+1
	#look forward
	while backwardIndex > 0:
		backwardIndex-=1
		newBox = getNewBoxColorTracker(images[backwardIndex], backwardIndex, trackerKCF, frameWidth, frameHeight, 'backward')
		entry = (backwardIndex+1, newBox)
		if newBox is not None:
			track.insert(0, entry)
		else:
			break
	#look backward
	while forwardIndex < numFrames:
		newBox = getNewBoxColorTracker(images[forwardIndex], forwardIndex, trackerKCF, frameWidth, frameHeight, 'forward')
		entry = (forwardIndex+1, newBox)
		if newBox is not None:
			track.append(entry)
		else:
			break
		forwardIndex+=1

	return track


def trackKCF(detections, numFrames, frameWidth, frameHeight, images):
	#print(totalSidesG[0].isReady())
	allTracks = []
	trackBoxes = {} #(frame, box) -- frame is one indexed
	maxConfidence = 1.0
	confidences=[]#debugging
	while maxConfidence > MIN_START_CONFIDENCE:# and len(allTracks)<11:
		maxConfidence = 0.0
		maxBox = None
		maxFrame = None
		for f in range(len(detections)):
			for (box, score) in detections[f]: #zero indexed
				overlap=False
				frame = f+1
				#print("Box lookup", (frame,box), boxesUsed)
				#percentBig = 1.5
				#x, y, w, h = makeBiggerBox(box, percentBig)
				#percentOff, offScreen = percentOffScreen(x,y,w,h, frameWidth, frameHeight)
				if frame not in trackBoxes:
					#print('empty frame')
					trackBoxes[frame] = []
				else:
					for tBox in trackBoxes[frame]:
						if boxOverlap(box, tBox):
							#print('overlap', frame)
							overlap=True
							break
				if score > maxConfidence and not overlap:
					#print('got Box')
					maxConfidence = score
					maxBox = box
					maxFrame = frame


		if maxConfidence > MIN_START_CONFIDENCE:
			#print("choosing box with confidence", maxConfidence)

			confidences.append((maxFrame, maxConfidence))
			#print("maxFrame: ", maxFrame)
			track = generateSingleTrackKCF(maxFrame-1, numFrames, maxBox, images, frameWidth, frameHeight)
			for (i,b) in track:
				#print('I,B***', i,b)
				#if(b[2]>(frameWidth/3)):
				if i not in trackBoxes:
					#print('empty frame ', i)
					trackBoxes[i] = []
				trackBoxes[i].append(b)
			if track is None:
				#print("Skipping")
				continue
			allTracks.append(track)
			#print("Final track #"+str(len(allTracks)-1), track)
	return allTracks



def load_frames(numFrames, frameWidth, frameHeight, imgPath):

	fgbg = cv2.createBackgroundSubtractorMOG2()

	scale = 300/max(frameWidth, frameHeight)

	frames = []
	for count in range(numFrames):
		imgNum = str(count+1).zfill(5)
		filename = "../."+imgPath + "img" + str(imgNum) + ".jpg"
		#print(filename)

		#print(filename)
		img = cv2.imread(filename)

		#fgmask = fgbg.apply(img)
		#plt.imshow(fgmask)
		#plt.show()
		img = cv2.resize(img, (0,0), fx=scale, fy=scale)
		#img = cv2.cvtColor(img, cv2.COLOR_BGR2HSV)
		#img = img.astype(np.dtype('float64'))
		#img *= 1./255


		frames.append(img)
	return frames

def track_kpd_matlab_wrapper(detections, numFrames, frameWidth, frameHeight, imgPath):

	start = time()
	images = load_frames(numFrames, frameWidth,frameHeight, imgPath )
	tracks = trackKCF(detections, numFrames, frameWidth, frameHeight, images)

	end = time()

	idx = 1
	out = []
	for track in tracks:
		for frame, box in track:
			(x1, y1, w,h) = box
			offScreen = True
			xRightOnScreen = x1+w
			xLeftOnScreen = frameWidth - x1
			yTopOnScreen = y1+h
			yBottomOnScreen = frameHeight - y1
			xOnScreen = min([xRightOnScreen, xLeftOnScreen, w]) # x value indicates part of a box on screen. (larger min value indicates that the box may not be cut off)
			yOnScreen = min([yTopOnScreen, yBottomOnScreen, h])
			xOnePercent = frameWidth * 0.01 # 1% of x-axis screen
			yOnePercent = frameHeight * 0.01

			if xOnScreen > xOnePercent and yOnScreen > yOnePercent: # more than 1% of a box should be on screen
				out.append([float(x1), float(y1), float(w), float(h), float(frame), float(idx)])
				#print('including box', box)
			else:
				out.append([float(0), float(0), float(0), float(0), float(frame), float(idx)]) # 0 indicates that the fish is not tracked
				#print('excluding box', box)
		idx += 1

	num_frames = len(detections)

	# this part occasionally throws ZeroDivisionError when evaluated in the DETRAC toolkit without the except clause
	try:
		speed = num_frames / (end - start)
	except:
		speed = num_frames / 0.1

	#print("done!")
	return speed, out
