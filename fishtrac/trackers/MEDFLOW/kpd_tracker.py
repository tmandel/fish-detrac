#!C:\Users\NSF\.conda\envs\tf_gpu
from time import time
import numpy as np
import random
import math
import sys
from numpy import ma
from pykalman import KalmanFilter
from pykalman.utils import log_multivariate_normal_density
from pykalman.utils import get_params as kf_get_params
from util import load_mot, iou, interp_tracks
import cv2
#from cv2 import optflow
from matplotlib import pyplot as plt
from backgroundSubtractor import DifferenceWeightedSimilarity
from scipy.stats import norm

MIN_START_CONFIDENCE = 0.5 #If all boxes on a track have less than this, do not include
NUM_OBS = 6
MISSING_OBS = ma.masked
LOW_CONFIDENCE = 0.2

def getMissingVector():
	ret = np.ma.zeros(NUM_OBS)
	ret[:] = MISSING_OBS
	return ret
	
def isMissingVector(obsVec):
	return np.ma.is_masked(obsVec)

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

def uniformVariance(n):# n = b-a
	return (1.0/12.0) * n * n

def get_avg_detection_size(detections):
	totalWidth = 0
	totalHeight = 0
	count = 0
	for f in range(len(detections)):
		#print(detections[f])
		for box, score in detections[f]:
			(x1, y1, width, height) = box
			totalWidth += width*score
			totalHeight += height*score
			count += score
	return (totalWidth/count, totalHeight/count)
	
	
def get_initial_mean_and_cov(frameWidth, frameHeight, detections):
	avgWidth, avgHeight = get_avg_detection_size(detections)
	initial_mean=np.array([frameWidth/2, frameHeight/2,0,0, avgWidth,avgHeight])
	initial_cov = np.array([[uniformVariance(frameWidth), 0, 0, 0, 0, 0], \
								  [0, uniformVariance(frameHeight), 0, 0, 0,
0], \
								  [0, 0, 1, 0, 0, 0], \
								  [0, 0, 0, 1, 0, 0], \
								  [0, 0, 0, 0, 1, 0], \
								  [0, 0, 0, 0, 0, 1] ])
	return (initial_mean,initial_cov)
	
def setup_kf(frameWidth, frameHeight, detections):

	# The Kalman filter stores:
	#  x 
	#  y 
	#  v_x
	#  v_y
	#  width
	#  height
	
	trans = np.array([[1, 0, 1, 0, 0, 0], \
					  [0, 1, 0, 1, 0, 0], \
					  [0, 0, 1, 0, 0, 0], \
					  [0, 0, 0, 1, 0, 0], \
					  [0, 0, 0, 0, 1, 0], \
					  [0, 0, 0, 0, 0, 1] ]) #0.5 is arbitrary, could be any number unless we need velocity in intelligible units. Means "half pixels per frame"

	obs = np.array([[1, 0, 0, 0, 0, 0], \
					[0, 1, 0, 0, 0, 0], \
					[0, 0, 0, 0, 0, 0], \
					[0, 0, 0, 0, 0, 0], \
					[0, 0, 0, 0, 1, 0], \
					[0, 0, 0, 0, 0, 1] ]) #everything observed except for velocity

	transition_cov = np.array([[1, 0, 0, 0, 0, 0], \
							   [0, 1, 0, 0, 0, 0], \
							   [0, 0, 0.2, 0, 0, 0], \
							   [0, 0, 0, 0.2, 0, 0], \
							   [0, 0, 0, 0, 1,0], \
							   [0, 0, 0, 0, 0, 1] ])
#velocity varies more than position and size
	avgWidth, avgHeight = get_avg_detection_size(detections)
	observation_cov = np.array([[0.5, 0, 0, 0, 0, 0], \
								[0, 0.5, 0, 0, 0, 0], \
								[0, 0, 0, 0, 0, 0], \
								[0, 0, 0, 0, 0, 0], \
								[0, 0, 0, 0, 1, 0], \
								[0, 0, 0, 0, 0, 1] ]) #all pretty noisy

	
	
	(initial_mean,initial_cov) = get_initial_mean_and_cov(frameWidth, frameHeight, detections)
									   

					  
					  
	return KalmanFilter(transition_matrices=trans, observation_matrices=obs, \
			transition_covariance=transition_cov, observation_covariance=observation_cov, \
			initial_state_mean=initial_mean, initial_state_covariance=initial_cov )

def boxToKalmanObs(box):
	if box is None:
		return getMissingVector()
	(x1, y1, width, height) = box
	return np.ma.array([x1, y1, 0, 0, width,height]) #Zeros for velocity
	
def getObsDistance(obs1, obs2):
	return math.sqrt((obs1[0]- obs2[0])*(obs1[0]- obs2[0]) + (obs1[1]- obs2[1])*(obs1[1]- obs2[1]))

def getObsFromState(kf, pred_state, pred_state_cov):
	params = kf_get_params(kf)
	#print("obsmatrix shape", params['observation_matrices'].shape)
	observation_matrix = params['observation_matrices']
	observation_offset = params['observation_offsets']
	observation_covariance = params['observation_covariance']
	
	
	predicted_obs = ( \
		np.dot(observation_matrix, pred_state)  \
	)  # should be + observation_offset but is None in our case
	predicted_obs_cov = ( \
		np.dot(observation_matrix, np.dot(pred_state_cov, observation_matrix.T)) \
		+ observation_covariance \
	)
	return (predicted_obs, predicted_obs_cov)

def getObsProbKF(kf, pred_state, pred_state_cov, obs):
	#Seems too simple, but 
	
	#  1. Log likelihood is computed as the product of the filtered probabilites
	#  2.  Each filtered probability is based on the log_multivariate_normal_density
	#       of the observation mean and observation cov (taken with dto product from state
	#        covariance
	#  3. in our case states take the same form as observations
	# So I think this is correct....
	
	if obs[0] == MISSING_OBS:
		print("Error! Trying to clauclate prob of missing observatioN!!!")\
	
	
	(predicted_obs, predicted_obs_cov) = getObsFromState(kf, pred_state, pred_state_cov)
	return log_multivariate_normal_density(np.array(obs[np.newaxis,:]), 
										   predicted_obs[np.newaxis, :],
										   predicted_obs_cov[np.newaxis,:,:])

def checkMissing(curBest, kf, allDetections, states, state_covs,  lastIndex, dirHist, frameWidth,frameHeight):
	#print("kfprob", curBest['maxProbKF'])
	#print("kfprobexp", math.exp(curBest['maxProbKF']))
	
	missing = False
	(initial_mean,initial_cov) = get_initial_mean_and_cov(frameWidth, frameHeight, allDetections)
	initProb = getObsProbKF(kf, initial_mean,initial_cov, boxToKalmanObs(curBest['maxBox']))
	if initProb > curBest['maxProbKF']:
		missing = True # missing = True
		#print('fail due to 1')
	else:
		#Check Rule #2
		lastProb = getObsProbKF(kf, states[lastIndex], state_covs[lastIndex], boxToKalmanObs(curBest['maxBox']))
		if lastProb > curBest['maxProbKF']:
			missing = True
			#print('fail due to 2')
	return missing

def percentOffScreen(x, y, w, h, frameWidth, frameHeight):
	xRightOnScreen = x+w
	xLeftOnScreen = frameWidth - x
	yTopOnScreen = y+h
	yBottomOnScreen = frameHeight - y
	xOnScreen = min([xRightOnScreen, xLeftOnScreen, w]) # x value indicates part of a box on screen. (larger min value indicates that the box may not be cut off)
	yOnScreen = min([yTopOnScreen, yBottomOnScreen, h])
	percentOff = 1 - ((xOnScreen*yOnScreen) / (w*h))
	if xLeftOnScreen > 0 and yBottomOnScreen > 0 and xRightOnScreen < frameWidth and yTopOnScreen < frameHeight:
		outOfScreen = False
	else:
		outOfScreen = True
	return percentOff, outOfScreen

def makeBiggerBox(box, percentBig):
	x = box[0]
	y = box[1]
	w = box[2]
	h = box[3]

	wNew = percentBig*w
	hNew = percentBig*h
	xNew = x - (wNew - w)/2
	yNew = y - (hNew - h)/2
	return xNew, yNew, wNew, hNew
	


def getBestBox(atEnd, frameDetections, origCurBest, obsSeq, confSeq, kf, frameWidth, frameHeight, allDetections, frameImages, colorHist, dirHist, outerDirHist, frameIndex, medianFlowTracker, direction):
	#frameIndex(parameter) is one-indexed
	curBest = origCurBest.copy() #necessary to deal with bidirectional stuff
	#print('frameIndex', frameIndex)

	lastConf = None

	obsVec = np.ma.zeros((len(obsSeq)+1, NUM_OBS))
	if atEnd:
		for t in range(len(obsSeq)):
			obsVec[t] = obsSeq[t]
		obsVec[-1] = getMissingVector()
		lastConf = confSeq[-1]

	else:
		for t in range(len(obsSeq)):
			obsVec[t+1] = obsSeq[t]
		obsVec[0] = getMissingVector()
		lastConf = confSeq[0]

	if atEnd:
		(states, state_covs) = kf.filter(obsVec)
	else:
		(states, state_covs) = kf.smooth(obsVec)
	targetState = None
	targetStateCov = None 
	lastIndex = None
	lastFrameIndex = None
	if atEnd:
		targetState = states[-1]
		targetStateCov = state_covs[-1]
		lastIndex = -2
		lastFrameIndex = frameIndex-1
	else:
		targetState = states[0]
		targetStateCov = state_covs[0]
		lastIndex = 1
		lastFrameIndex = frameIndex+1
	
	#if len(obsSeq) == 1:
	#	kfProb = getObsProbKF(states[lastIndex], state_covs[lastIndex], obsVec[lastIndex]) 
	#	print("Baseline KF Prob is", math.exp(kfProb))

	#probability detector gives to box multiply by probability kalman gives to box
	for i in  range(len(frameDetections)):	
		(box,detectorProb) = frameDetections[i]
		kfProb = getObsProbKF(kf, targetState, targetStateCov,  boxToKalmanObs(box)) 
		overallProb = kfProb + math.log(detectorProb)  #multiply
		#if getObsDistance(targetState,box) < 100 and len(obsSeq) == 1:
			#print("Distance", getObsDistance(targetState,box), "kfProb", math.exp(kfProb), "detectorProb", detectorProb,"Overall prob: ", overallProb)
			#print("Target state", targetState, "targetStatecov", targetStateCov)
		#if overallProb < MIN_OBS_CONFIDENCE:
		#	continue
		if curBest['maxProb'] is None or curBest['maxProb'] < overallProb:
			curBest['maxProb'] = overallProb
			curBest['maxProbKF'] = kfProb
			curBest['maxProbDetect'] = detectorProb
			curBest['maxBox'] = box
			curBest['maxIndex'] = i
			curBest['maxAtEnd'] = atEnd
	#is curbest actually a good option, or is the box missing?
	# Rules:
	# 1. If had a higher chance of being initial state, reject
	# 2. If had a higher chance of being last state, reject

	missing = False
	if curBest['maxProb'] is not None and curBest['maxProbDetect'] < 0.99:
		#prevents going down to lower prob boxes - this is what we want!
		#if  curBest['maxProbDetect'] < 0.5* lastConf:
		#	missing = True
		missing = checkMissing( curBest, kf, allDetections,  states, state_covs, lastIndex, outerDirHist, frameWidth,frameHeight)
		#if -.1<curBest['maxProbDetect']<.1:
		#	print("problem in checkMissing")
		#	missing = True
	#TODO
	#print("settled on intermediate box with conf", curBest['maxProbDetect'] )
	
	#print(confSeq)
	debug = False
	#if 0.88805664 in confSeq:
		#print("fish 0 frame:", frameIndex)
		#if frameIndex == 134:
			#sys.exit(1)
	if atEnd:
		delta = -1
	else:
		delta = 1
	
	origLastIndex = lastIndex
	#find last real box - prevents "hiccups"
	skipFrames = 0
	while lastIndex >= -2 and lastIndex < len(obsVec) and \
		(isMissingVector(obsVec[lastIndex]) or -0.01 <= confSeq[lastIndex- delta] < 0.5) :
		#print("on index", frameIndex, "skipping past", lastIndex, " with conf ",confSeq[lastIndex- delta], "and frameindex",lastFrameIndex)
		lastIndex += delta
		lastFrameIndex  += delta
		skipFrames += 1
		#print(lastIndex,lastFrameIndex)
	
	#print("considering whether to use color box, lastIndex is", lastIndex)
	#print(lastIndex,lastFrameIndex, len(obsVec))
	if -.1 < curBest['maxProbDetect'] <.1:
		missing = True
	
	if True: 
		#Try color-based box
		(lx,ly,lvx,lvy,lw,lh) = obsVec[lastIndex]
		lastBox = (lx,ly,lw,lh)
		lastFrame = frameImages[lastFrameIndex-1]
		curFrame = frameImages[frameIndex-1]
		#print("first frame", lastFrameIndex, "cur Frame", frameIndex)
		
		newBox = getNewBoxColorTracker(curFrame, frameIndex, medianFlowTracker, frameWidth, frameHeight, direction)#uses cv2.tracker.medianflow 
		#newBox, newHist = getNewBoxOpticalFlow(lastBox, lastFrame, curFrame, colorHist, dirHist, None, frameWidth, frameHeight, skipFrames, debug) #trying to replace this with cv2 tracker
		#colorHist = newHist
		#print("newBox: ", newBox)
		#print(colorHist, 'colorHist')
		if debug:
			print("debug")
			plt.figure("frame " + str(frameIndex))
			plt.imshow(curFrame)
			plt.show()
		if newBox is not None:
			doChoose = False
			if missing:
				#print("is missing")
				doChoose = True
				
				#missing = False
				
			else:
				kfProb = getObsProbKF(kf, targetState, targetStateCov, boxToKalmanObs(newBox)) 
				
				#if less likely kf or switching from color to unlikely box
				#if kfProb > curBest['maxProbKF'] or (curBest['maxProbDetect'] < LOW_CONFIDENCE): #and confSeq[lastIndex- delta] == -1):
				#	doChoose = True
				#if (kfProb < curBest['maxProbKF'] or (curBest['maxProbDetect'] > LOW_CONFIDENCE)):
					#print("Prefer box with ", curBest['maxProbDetect'], " to color box, last index was ", confSeq[lastIndex- delta])
				#(x,y,w,h) = curBest['maxBox']
				#(x2,y2,w2,h2) = newBox
				
				#curBest['maxBox'] = newBox#((x+x2)/2, (y+y2)/2, (w+ w2)/2, (h+h2)/2)
			
			#choose color
			if doChoose: #and (curBest['maxProb'] is None or curBest['maxProb'] < overallProb):
				#print("chose a color box")
				curBest['maxProb'] = 0
				curBest['maxProbKF'] = getObsProbKF(kf, targetState, targetStateCov, boxToKalmanObs(box))   #TODO: should probably be fixed
				kfprobColor =  getObsProbKF(kf, targetState, targetStateCov, boxToKalmanObs(newBox))
				#print("kfprob-cdolor", kfprobColor)
				#print("kfprobexp-color",  math.exp(kfprobColor))
				curBest['maxProbDetect'] = -1
				curBest['maxBox'] =  newBox
				curBest['maxIndex'] = 0
				curBest['maxAtEnd'] = atEnd
				missing = False
	"""
		elif not missing:
			#couldn't find color so is missing?  Let's double check....
			#if -.1 < curBest['maxProbDetect'] <.1:
			#	missing = True
			if isMissingVector(obsVec[origLastIndex]):
				#make sure color matches
				(lx,ly,lw,lh) = lastBox
				(nx,ny,nw,nh) = curBest['maxBox']
				nBox = (nx,ny,lw,lh)
				try:
					newBox, _ = getNewBoxOpticalFlow(lastBox, lastFrame, curFrame, colorHist, dirHist, None, frameWidth, frameHeight, 0, debug, nextBox=nBox)
				except IndexError:  #things of diff shapes
					#print("IndexERROR!")
					newBox = None

				#print("Second time (in elif) newBox is =", newBox)
				if newBox is None:
					missing = True
					print("Line 404: missing=true")
				#else:
					#print("found corresponding box")
	"""
	x = states[lastIndex][0]
	y = states[lastIndex][1]
	w = states[lastIndex][4]
	h = states[lastIndex][5]
	lastPercentOff, outOfScreen = percentOffScreen(x,y,w,h, frameWidth, frameHeight)
	
	x = targetState[0]
	y = targetState[1]
	w = targetState[4]
	h = targetState[5]
	currentPercentOff, outOfScreen = percentOffScreen(x,y,w,h, frameWidth, frameHeight)
	#print("CurPercentOff:",currentPercentOff, "LastPercentOff:",lastPercentOff, "frameIndex:", frameIndex)
	#print('missing:', missing)

	offScreen=False #marks boolean
	if currentPercentOff > lastPercentOff:
		missing = True
		offScreen=True
		print("line 428: offscreen")
		
	
	if missing and curBest['maxAtEnd'] == atEnd:
		curBest = origCurBest
		print('set back to origCurBest')
		
		
	#Did not modify obseq, so ok not to remove
	return curBest, offScreen

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

def boxToImgCoords(box, fw, fh):
	if box is None:
		return None
	"""x1,y1,owidth, oheight = map(int,  box)
	scale = 300/max(fw, fh)
	width = int(owidth * scale)
	height = int(oheight * scale)
	x1 = int(x1 * scale)
	y1 = int(y1 * scale)"""
	return scaleBox(box, fw, fh, 'down')

def boxFromImgCoords(box, fw, fh):
	"""x1,y1,owidth, oheight = map(int,  box)
	scale = max(fw, fh)/300
	width = int(owidth * scale)
	height = int(oheight * scale)
	x1 = int(x1 * scale)
	y1 = int(y1 * scale)"""
	return scaleBox(box, fw, fh, 'up')

def cropOutBoxArea(box, img, fw, fh):  #Area centered on Box
	"""x1,y1,owidth, oheight = map(int,  box)
	scale = 300/max(fw, fh)
	width = owidth * scale
	height = oheight * scale
	x1 = int(x1 * scale)
	y1 = int(y1 * scale)"""
	x1, y1, width, height = scaleBox(box, fw, fh, 'down')
	
	cropy1 = int(max(y1-0.5*height,0))
	cropy2 = int(min(y1+1.5*height, fh))
	cropx1 = int(max(x1-0.5*width, 0))
	cropx2 = int(min(x1+1.5*width, fw))
	newBox = (x1-cropx1, y1 - cropy1, int(width), int(height))
	return img[cropy1:cropy2,cropx1:cropx2], newBox 


def isInBounds(box, fw, fh):
	(x,y,w,h) = box
	if x < 0 or y < 0:
		return False
	if x+w >= fw or y+h >= fh:
		return False
	return True

	
def findStart(img, basecolor, centerThresh, origStart):
	(w,h,c) = img.shape
	fringe = [origStart]
	seen = set([])
	while len(fringe) > 0:
		current = fringe.pop(0)
		if current in seen:
			continue
		seen.add(current)
		
		#if len(seen) % 30 == 0:
			#print(len(seen))
		(cx,cy) = current
		currentColor = img[cy,cx]
		d = (basecolor-currentColor)
		diff = (d*d).sum()
		if diff < centerThresh:
			return current, currentColor
		
		for (dx,dy) in [(0,1), (1,0), (-1,0), (0, -1)]:
			
			next = (cx + dx, cy + dy)
			(nx,ny) = next
			if ny < 0 or ny >= w or nx < 0 or nx >= h:
				continue
			if next in seen:
				continue
			
			fringe.append(next)
	
	return None, None
	

def insideBox(point, box):
	(x,y,w,h) = box
	(px, py) = point
	if px >= x and px <= x+w and py >= y and py <= y+h:
		return True
	return False

	
def maskOutBackground(img, start, bbox, basecolor, thresh):
	(w,h,c) = img.shape

	fringe = [start]
	t = 0
	seen = np.zeros((w,h), dtype = np.uint8)
	
	
	(sx,sy) = start
	#print("START", start)
	
	if thresh is not None:
		NUM_TRAIN = 0
	else:
		NUM_TRAIN = 8
		badAvgList = []
		badC = 0
		(bbx,bby,bbw,bbh) = bbox
		#around the outside
		for badx in [bbx-1, (bbx+bbw)+1]:
			badAvg = None
			for bady in range(bby, bby+bbh+1):
				if bady < 0 or bady >= w or badx < 0 or badx >= h:
					continue
				badcolor = img[bady, badx]
				d = (basecolor-badcolor)
				diff = (d*d).sum()
				if badAvg is None or diff < badAvg:
					badAvg = diff
				#badAvg += diff
				#badC += 1
			if badAvg is not None:
				badAvgList.append(badAvg)
			
		for bady in [bby-1, (bby+bbh)+1]:
			badAvg = None
			for badx in range(bbx, bbx+bbw+1):
				if bady < 0 or bady >= w or badx < 0 or badx >= h:
					continue
				badcolor = img[bady, badx]
				d = (basecolor-badcolor)
				diff = (d*d).sum()
				if badAvg is None or diff < badAvg:
					badAvg = diff
				#badAvg += diff
				#badC += 1
			if badAvg is not None:
				badAvgList.append(badAvg)
		#badAvg /= badC
		badAvg = 0
		badAvg = max(badAvgList)
		
	
			
	#badExamples = [(x-1,),(w-1,0),(0,h-1), (w-1,h-1)]
	
	#for (bady,badx) in badExamples:
		
	
	
		
	
	seen[sy,sx] = 1
	totaltraindiff = 0

	while len(fringe) > 0:
		current = fringe.pop(0)
		(cx,cy) = current
		
		for (dx,dy) in [(0,1), (1,0), (-1,0), (0, -1)]:
			
			next = (cx + dx, cy + dy)
			(nx,ny) = next
			if ny < 0 or ny >= w or nx < 0 or nx >= h:
				continue

			if seen[ny,nx] == 1:
				continue
			
			nextcolor = img[ny,nx]
			d = (basecolor-nextcolor)
			diff = (d*d).sum()
			good = False
			if t < NUM_TRAIN:
				totaltraindiff += diff
				good = True
				if t == NUM_TRAIN - 1:
					thresh = totaltraindiff/NUM_TRAIN
					if badAvg < thresh:
						pass
						#print("whoa! something went wrong! neighbor diff is", thresh, "but bad diff is", badAvg)
					else:
						thresh  = (thresh + badAvg) /2  #halfway between corners and center....
			elif diff < thresh:
				good = True
			
			if good:
				seen[ny, nx] = 1
				t += 1
				fringe.append(next)
	
	#print(seen.shape)
	newimg = np.zeros(img.shape, dtype=np.uint8)
	newimg[:,:,0] = img[:,:,0]*seen
	newimg[:,:,1] = img[:,:,1]*seen
	newimg[:,:,2] = img[:,:,2]*seen
	
	centerThresh = None
	if NUM_TRAIN > 0:
		centerThresh = totaltraindiff/NUM_TRAIN
	
	return newimg, seen, basecolor, centerThresh, thresh
			
			
			
	# mask = np.zeros(img.shape[:2],np.uint8)
    # bgdModel = np.zeros((1,65),np.float64)
    # fgdModel = np.zeros((1,65),np.float64)
    
    # (w,h,c) = img.shape
    # rect = box
    # print(img.shape)
    # print(rect)
    # res = cv2.grabCut(img,mask,rect,bgdModel,fgdModel,5,cv2.GC_INIT_WITH_RECT) 
    # print(mask)
    # print(res)
    # mask2 = np.where((mask==2)|(mask==0),0,1).astype('uint8')
    # newimg = img*mask2[:,:,np.newaxis]
    # return newimg


def getCentroid(mask):
	w,h = mask.shape
	totx = 0
	for i in range(w):
		totx += mask[i,:].sum()
	
	searchX = 0
	retx = None
	for i in range(w):
		searchX += mask[i,:].sum()
		if searchX/totx > 0.5:
			retx = i
			break
			
	toty = 0
	for j in range(h):
		toty += mask[:,j].sum()
	
	searchY = 0
	rety = None
	for j in range(h):
		searchY += mask[:,j].sum()
		if searchY/toty > 0.5:
			rety = j
			break
	return rety, retx

def adjustColorThresh(maskedImgOrig, origMask, secondImg, color, thresh, box, debug):
	change = False
	origThresh = thresh
	#diff out the color
	maskedImgO1 = np.array(maskedImgOrig, dtype=np.float64)
	maskedImgO2 = np.array(secondImg, dtype=np.float64)
	imgListO = [maskedImgO1, maskedImgO2]
	imgMaskList = []
	for maskedImgO in imgListO:
		maskedImgO[:,:,0] = (maskedImgO[:,:,0]-color[0])* (maskedImgO[:,:,0]-color[0])
		maskedImgO[:,:,1] = (maskedImgO[:,:,1]-color[1])* (maskedImgO[:,:,1]-color[1])
		maskedImgO[:,:,2] = (maskedImgO[:,:,2]-color[2])* (maskedImgO[:,:,2]-color[2])
		maskedImgO[origMask == False, :] = 1000000000 #dont want it to count
	
		imgMaskList.append(maskedImgO.sum(axis=2))
	
		
	

	
	(by1, bx1, by2, bx2) = toCornerForm(box)
	
	croppedAmts = []
	totalAmts = []
	outsideAmts = []
	for maskedImg in imgMaskList:
		croppedAmts.append((maskedImg[bx1:bx2+1, by1:by2+1] < thresh).sum())
		totalAmts.append((maskedImg < thresh).sum())
		outsideAmts.append(totalAmts[-1] - croppedAmts[-1])
	
	#if debug:
	#	plt.figure("origMask")
	#	plt.imshow(maskedImgOrig)
	#	plt.show()
	#simple binary search
	
	bestFeasible = None
	bestOutside = None
	moveAmt = thresh
	while True:
		#print("thresh", thresh, "croppedAmt0", croppedAmts[0], "totalAmt0", totalAmts[0], "outsideAmt", outsideAmts[0], "croppedAmt1", croppedAmts[1], "totalAmt1", totalAmts[1], "outsideAmt", outsideAmts[1])
		moveAmt /=2
		if moveAmt < 1:
			return bestFeasible, None, None, change
		if debug:
			plt.figure("hyp img 2")
			plt.imshow((imgMaskList[1] < thresh))
		
		tooSmall = False
		tooBig = False
		for i in range(len(totalAmts)):
			if croppedAmts[i] < 8:
				tooSmall = True
		if croppedAmts[0] < outsideAmts[0]:
			tooBig = True
		
		if not tooSmall:
			if bestFeasible is None or outsideAmts[0] < bestOutside:
				bestFeasible = thresh
				bestOutside = outsideAmts[0]
			
		if tooSmall:
			thresh += moveAmt
		elif tooBig:
			thresh -= moveAmt
		else:
			newMask = (imgMaskList[0] < thresh)
			newimg = np.zeros(maskedImgOrig.shape, dtype=np.uint8)
			newimg[:,:,0] = maskedImgOrig[:,:,0]*newMask
			newimg[:,:,1] = maskedImgOrig[:,:,1]*newMask
			newimg[:,:,2] = maskedImgOrig[:,:,2]*newMask
			#if debug:
			#	plt.figure("origMask")
			#	plt.imshow(maskedImgOrig)
			#	plt.figure("adjustMask")
			#	#drawRect(firstImage, bpx)
			#	plt.imshow(newimg)
			#	plt.show()
			#print("returning thresh", thresh, "and mask with shape", newMask.shape, "and img with shape", newimg.shape)
			if debug:
				plt.figure("hyp img 2")
				plt.imshow((imgMaskList[1] < thresh))
			return thresh, newMask, newimg, change
		
		change = True
		croppedAmts = []
		totalAmts = []
		outsideAmts = []
		for maskedImg in imgMaskList:
			croppedAmts.append((maskedImg[bx1:bx2+1, by1:by2+1] < thresh).sum())
			totalAmts.append((maskedImg < thresh).sum())
			outsideAmts.append(totalAmts[-1] - croppedAmts[-1])
		
	
	return thresh, None, None, change
	
def getColorMask(img, color, thresh):
	return img
	#temp = (img - color) * (img- color)
	#mask = np.array((temp.sum(-1) < thresh), dtype = np.float64)
	#return mask

def updateDetectors(box1,img1, totalSides, conf1):
	w,h,c = img1.shape
	_, _, ow, oh = box1
	if ow < 5 or oh <5:
		#print("box too small")
		return 0,0
	by1, bx1, by2, bx2 = toCornerForm(box1) #backwards?
	if bx1 < 0 or by1 < 0 or bx2 >= w  or by2 >= h:
		#print("box out of range")
		return
		
	hamt = int(ow/2)
	vamt = int(oh/2)
		
	#thresh*= 2
	
	#print(box1, box2)
	
	[leftDetector, rightDetector, topDetector, bottomDetector] = totalSides
	leftSlice1 = img1[bx1:bx1+hamt, by1:by2+1]
	#maskLeft = getColorMask(leftSlice1, color, thresh)
	if leftDetector is not None:
		leftDetector.addImage(leftSlice1, conf1) #+ maskLeft
	else:
		leftDetector = DifferenceWeightedSimilarity(leftSlice1, conf1)
	
	
	
	
	#print(maskLeft, maskLeft.shape)
	
	rightSlice1 = img1[bx2-hamt-1:bx2+1, by1:by2+1]
	if rightDetector is not None:
		rightDetector.addImage(rightSlice1, conf1) #+ maskLeft
	else:
		rightDetector = DifferenceWeightedSimilarity(rightSlice1, conf1)
	
	#print(bx2)
	#print(rightSlice1.shape)
	topSlice1 = img1[bx1:bx2+1, by1:by1+vamt]
	if topDetector is not None:
		topDetector.addImage(topSlice1, conf1) #+ maskLeft
	else:
		topDetector = DifferenceWeightedSimilarity(topSlice1, conf1)
	
	bottomSlice1 = img1[bx1:bx2+1, by2-vamt-1:by2+1]
	if bottomDetector is not None:
		bottomDetector.addImage(bottomSlice1, conf1) #+ maskLeft
	else:
		bottomDetector = DifferenceWeightedSimilarity(bottomSlice1, conf1)
	
	totalSides[0] =leftDetector
	totalSides[1] = rightDetector
	totalSides[2] = topDetector
	totalSides[3] = bottomDetector

def jiggerBoxPattern(box2, img2, box1, conf1, img1, color, thresh, totalSides, numSideSamp):
	
	#if box1 is not None and conf1 >= 0.5:
	#	updateDetectors(box1, img1, totalSides, conf1)
	
	[leftDetector, rightDetector, topDetector, bottomDetector] = totalSides
	
	if leftDetector is None or not leftDetector.isReady():
		#print(leftDetector.isReady())
		return 0, 0
		
	#plt.figure("left")
	#plt.imshow(leftSlice1)
	#plt.figure("maskleft")
	#plt.imshow(leftDetector.showMask(leftSlice1))
	#plt.show()
	# plt.figure("right")
	# plt.imshow(rightSlice1)
	#plt.figure("top")
	#plt.imshow(topSlice1)
	# plt.figure("bottom")
	# plt.imshow(bottomSlice1)
	#plt.show()
	
	#return box2
	
	w,h,c = img2.shape
	_, _, ow, oh = box2
	hamt = int(ow/2)
	vamt = int(oh/2)
	by1, bx1, by2, bx2  = toCornerForm(box2)
	if bx1 < 0 or by1 < 0 or bx2 >= w or by2 >= h:
		return 0,0 
	
	
	MA = 10 # max amount
	minDiff = None
	minLeft = None
	for left in range(max(0, bx1-MA), min(w-2, bx1+MA+1)):
		diff = leftDetector.computeScore(img2[left:left+hamt, by1:by2+1])
		#print("leftDiff", diff)
		if minDiff is None or diff < minDiff:
			minDiff = diff
			minLeft = left
	

		
	minDiff = None
	minRight = None
	for right in range(max(minLeft+1, bx2-MA), min(w-1,bx2+MA+1)):
		diff = rightDetector.computeScore(img2[right-hamt-1:right+1, by1:by2+1])
		if minDiff is None or diff < minDiff:
			minDiff = diff
			minRight= right

	
	minDiff = None
	minTop = None
	for top in range(max(0, by1-MA), min(h-2, by1+MA+1)):
		diff = topDetector.computeScore(img2[bx1:bx2+1, top:top+vamt])
		if minDiff is None or diff < minDiff:
			minDiff = diff
			minTop= top
			
	minDiff = None
	minBot = None
	for bot in range(max(minTop+1, by2-MA), min(h-1, by2+MA+1)):
		diff = bottomDetector.computeScore(img2[bx1:bx2+1, bot-vamt-1:bot+1])
		if minDiff is None or diff < minDiff:
			minDiff = diff
			minBot= bot
			
	
	#symmetrical
	hDiff = int(((bx1-minLeft) + (minRight-bx2))/2)
	vDiff = int(((by1-minTop) + (minBot-by2))/2)
	
	return hDiff, vDiff
	
	
	
			
		
		
def getEstimatedWAndH(mask):
	w,h = mask.shape
	totx = 0
	for i in range(w):
		totx += mask[i,:].sum()
	
	searchX = 0
	startx = None
	endx = None
	for i in range(w):
		searchX += mask[i,:].sum()
		if startx is None and searchX/totx > 0.1:
			startx = i
		elif searchX/totx > 0.9:
			endx = i
			break
			
	toty = 0
	for j in range(h):
		toty += mask[:,j].sum()
		
	
	searchY = 0
	starty = None
	endy = None
	for j in range(h):
		searchY += mask[:,j].sum()
		#print(searchY/toty)
		if starty is None and searchY/toty > 0.1:
			starty = j
		elif searchY/toty > 0.9:
			endy = j
			break
	if endy is None or endx is None:
		return None, None
	#print(startx, endx, starty, endy)
	return endx-startx, endy-starty
	
def getCenterLocRelative(mask, targetx, targety):
	w,h = mask.shape
	totx = 0
	massx = 0
	#y1,x1,y2,x2 = toCornerForm(oldBox)
	#for i in range(x1-2,x2+2+1):
	for i in range(w):
		totx += mask[i,:].sum()+1
		if i == targetx:
			massx = totx - (mask[i,:].sum()/2)
	toty = 0
	massy = 0
	for  j in range(h):
		toty += mask[:,j].sum()+1
		if j == targety:
			massy = toty - (mask[:,j].sum()/2)
	return (massx/totx, massy/toty)
	
def applyCenterLocRelative(mask, massX, massY):
	w,h = mask.shape
	totx = 0
	for i in range(w):
		totx += mask[i,:].sum()+1
	
	searchX = 0
	retx = None
	for i in range(w):
		searchX += mask[i,:].sum()+1
		if searchX/totx >= massX:
			retx = i
			break
			
	toty = 0
	for j in range(h):
		toty += mask[:,j].sum()+1
	
	searchY = 0
	rety = None
	for j in range(h):
		searchY += mask[:,j].sum()+1
		if searchY/toty >= massY:
			rety = j
			break
	return retx, rety


def calcDirTravis2(mask1, mask2):
	(x1,y1) = getCentroid(mask1)
	(x2,y2) = getCentroid(mask2)
	return [x2 - x1, y2 - y1 ]
	

def calcWandHoffset(mask1, mask2):
	(w1,h1) = getEstimatedWAndH(mask1)
	(w2,h2) = getEstimatedWAndH(mask2)
	if w1 is None or w2 is None or h1 is None or h2 is None:
		return [0,0]
	#print("w,h offset ", (h2 - h1, w2 - w1))
	return [h2 - h1, w2 - w1 ]


def calcExtraDir(mask1, oldBox):
	(by1,bx1,by2,bx2) = toCornerForm(oldBox)
	by1 += 1
	bx1 += 1
	by2 -= 1
	bx2 -= 1  #acount for border
	w,h = mask1.shape
	xdiff = 0
	ydiff = 0
	
	minY = None
	for j in range(h):
		if mask1[:,j].any():
			minY = j
			break
	maxY = None
	for j in range(h-1, -1, -1):
		if mask1[:,j].any():
			maxY = j
			break
	if minY < by1 and maxY < by2:
		ydiff = max(minY-by1, maxY-by2)
	if minY > by1 and maxY > by2:
		ydiff = min(minY-by1, maxY-by2)
		
	minX = None
	for i in range(w):
		if mask1[i,:].any():
			minX = i
			break
	maxX = None
	for i in range(w-1, -1, -1):
		if mask1[i,:].any():
			maxX = i
			break
	if minX < bx1 and maxX < bx2:
		xdiff = max(minX-bx1, maxX-bx2)
	if minY > by1 and maxY > by2:
		xdiff = min(minX-bx1, maxX-bx2)
		
	return [xdiff,ydiff]
	
			
	
	
	
def calcDirTravis(mask1, mask2, oldBox):
	(bx,by,bw,bh) = oldBox
	targety = int(bx + bw/2)
	targetx = int(by + bh/2)
	
	if mask1.sum() < 5 or mask2.sum() < 5:
		#print("warning!  insufficient info to compute box correspondence")
		
		if mask1.sum() >= 8:
			return calcExtraDir(mask1, oldBox)
		else:
			return [None, None]
			
	
	#cy, cx = getCentroid(mask1)
	#if cy < bx:
	#	cy = bx
	#if cy > bx + bw:
	#	cy = bx + bw
	#if cx < by:
	#	cx = by
	#if cx > by + bh:
	#	cx = by+bh
	#targety = cy
	#targetx = cx

	
	
	(massx, massy) = getCenterLocRelative(mask1, targetx, targety)
	retx, rety = applyCenterLocRelative(mask2, massx, massy)
	
	testx, testy = applyCenterLocRelative(mask1, massx, massy)
	if testx != targetx or testy != targety:
		#print("Masses:", massx, massy)
		#print((testx, testy))
		#print((targetx, targety))
		#print("Error, inversion test failed")  #TODO: Change to centroid method, could happen if all on one side of box
		#return [None, None]
		sys.exit(1)
	
	#(avg2x, avg2y) = getCenterLocRelative(m2)
	dir =  [retx - targetx, rety -targety ]
	#print("origDir was", dir)
	extraDir = calcExtraDir(mask1, oldBox)
	#print("extraDir returned", extraDir)
	dir[0] += extraDir[0]
	dir[1] += extraDir[1]
	return dir



	
def drawRect(img, box):
	(x,y,w,h) = box
	cv2.rectangle(img, (x,y), (x+w, y+h), (0,255,0))

def getAvgColorAndThresh(colorHist, startColor):
	if startColor is None:
		tr = 0
		tg = 0
		tb = 0
	else:
		(sr,sg,sb) = startColor
		tr = int(sr)
		tg = int(sg)
		tb = int(sb)
	avgThresh = None
	for ((r,g,b), thresh) in colorHist:
		tr += r
		tg += g
		tb += b
		if avgThresh is None:
			avgThresh = thresh
		else:
			avgThresh += thresh
	l = len(colorHist) 
	if avgThresh is not None:
		avgThresh /= l
	
	if startColor is None:
		return ((tr/l, tg/l, tb/l), avgThresh)
	else:
		return ((tr/(l+1), tg/(l+1), tb/(l+1)), avgThresh)

def normcdf(x, mu, sigma):
	t = x-mu;
	y = 0.5*math.erf(-t/(sigma*math.sqrt(2.0)));
	if y>1.0:
		y = 1.0;
	return y
	
	
def isOutlier(oldBox, newBox, dirHist):  #also adds
	fx1,fy1,_,_ = oldBox
	sx1, sy1,_,_ = newBox
	dir = [sx1-fx1, sy1-fy1]
	mag = dir[0]*dir[0] + dir[1]*dir[1]
	
	data = []
	for d in dirHist:
		magD = d[0]*d[0] + d[1]*d[1]
		data.append(magD)
	ndata = np.array(data)

	if len(dirHist) > 5:
		p = norm.cdf(mag, loc=ndata.mean(), scale=ndata.std())
		
		#print("direction",dir," has prob", p)
		#if p >= 1:
		#	return True
	
	dirHist.append(dir)
	
	return False
	

def getNewBoxOpticalFlow( oldBox, oldImage, newImage, colorHist,dirHist, totalSides,  width, height, skipFrames, debug, nextBox=None):
	if nextBox is None:
		nextBox = oldBox
	if not isInBounds(oldBox, width, height):
		#print("Line 1192: None due to orig box not in bounds")
		return None, colorHist
	firstImage, transBox1 = cropOutBoxArea(oldBox, oldImage, width, height)
	nextImage, transBox2 = cropOutBoxArea(nextBox, newImage, width, height)
	
	
	(bx, by, bw, bh) = transBox1
	#print(oldBox)
	centerFirst = (int(bx + bw/2), int(by + bh/2))
	(sx, sy) = centerFirst
	startColor = firstImage[sy,sx]
	startFirst = centerFirst
	
	if len(colorHist) == 0:
		basecolor, centerThresh = (tuple(map(float, tuple(startColor))), None)
	else:
		basecolor, centerThresh = getAvgColorAndThresh(colorHist, startColor)  #None was startColor
	#if len(colorHist) == 0:
	#	print((basecolor, centerThresh), " compared to ", (tuple(map(float, tuple(startColor))), None))
	#	sys.exit(1)
	#print("out of find color")
	if centerThresh is not None:
		startFirst, foundColor = findStart(firstImage, basecolor, centerThresh, startFirst)
		#print("out of find start")
		if startFirst is None:
			#print("Line 1217: could not find anything similar on first frame")
			return None, colorHist
			
		#basecolor = foundColor
		
	firstImageMasked, maskFirst, color, centerThresh, overallThresh = maskOutBackground(firstImage, startFirst, transBox1, basecolor, None)

	overallThresh, _, _, change = adjustColorThresh(firstImage, maskFirst, nextImage, basecolor, overallThresh, transBox1, debug)
	if overallThresh is None:
		if debug:
			#print("THRESHOLD FAILURE")
			plt.figure("failure-first")
			drawRect(firstImageMasked, transBox1)
			plt.imshow(firstImageMasked)
			plt.show()
		#print("line 1232: overall thresh is None")
		return None, colorHist
	#if maskFirst2 is not None:
		#maskFirst = maskFirst2
		#firstImage = firstImage2
	if centerThresh > overallThresh:
		centerThresh = overallThresh
		startFirst, _ = findStart(firstImage, basecolor, centerThresh, startFirst)
			
	if change:
		#print("redoing mask")
		if startFirst is None:
			#print("could not find anything similar on first frame - SHOULD NOT HAPPEN HERE")
			sys.exit(-1)
		if debug:
			plt.figure("orig mask")
			plt.imshow(firstImageMasked)
		firstImageMasked, maskFirst, color, _, _ = maskOutBackground(firstImage, startFirst,None, basecolor, overallThresh)
		if debug:
			plt.figure("adjusted mask")
			plt.imshow(firstImageMasked)
			plt.show()
		
	
	
	#NEW lines
	#centx, centy = getCentroid(maskFirst)
	#startColor =  firstImage[:,:,0].sum() / maskFirst.sum(), firstImage[:,:,1].sum() / maskFirst.sum(), firstImage[:,:,2].sum() / maskFirst.sum()#firstImage[centy,centx]
	
	
	#print("finished first mask")
	colorHist.append((startColor, centerThresh))
	
	#print("looking for ", startColor, "aka", color)
	#NEW line
	#basecolor, centerThresh = getAvgColorAndThresh(colorHist, None)  
	
	
	
	startSecond, _ = findStart(nextImage, color, centerThresh, getCentroid(maskFirst))
	#print("found at ", startSecond)
	
	if startSecond is None:
		#print("Line 1275: could not find anything similar on next frame")
		return None, colorHist
	nextImage, maskSecond, _, _, _ = maskOutBackground(nextImage, startSecond, None, color, overallThresh) #change once multiple thresholds
	#print(maskFirst.sum())
	#print(maskSecond.sum())
	#input("Press Enter to continue...")
	
	
	#print(oldBox)
	#print(firstImage.shape)
	
	
	#alg = optflow.createOptFlow_DeepFlow()  #TODO: not working?
	#flow = np.ones(firstImage.shape)
	#flow = alg.calc(firstImage, nextImage, flow)
	
	#flow = optflow.calcOpticalFlowDenseRLOF(firstImage, nextImage, flow)
	#flow = optflow.calcOpticalFlowSF(firstImage, nextImage, 3, 3, 500)
	
	dir = calcDirTravis(maskFirst, maskSecond, transBox1)
	if dir[0] is None or dir[1] is None:
		#print("Line 1296: bad dir")
		return None, colorHist
		
		
	
			
		
	#if isMax and 
	dirW, dirH = 0,0#calcWandHoffset(maskFirst, maskSecond)
	#dir = calcDirTravis2(maskFirst, maskSecond)
	#flow = optflow.calcOpticalFlowSparseToDense(firstImage, nextImage)
	#crop to just fish
	(tx, ty, tw, th) = transBox1
	#transBox2 = (tx + dir[1], ty + dir[0], tw, th)
	
	
	scale = max(width, height)/300
	dir[0] *= scale
	dir[1] *= scale
	dirW *= scale
	dirH *= scale
	
	#detect if dir is an outlier
	data = []
	mag = dir[0]*dir[0] + dir[1]*dir[1]
	
	for d in dirHist:
		magD = d[0]*d[0] + d[1]*d[1]
		data.append(magD)
	ndata = np.array(data)
	
	mag = mag/(1+skipFrames)
	#print("dir:", dir)
		
	if debug:
		#print("SHOWING DEBUG INFO")
		plt.figure("first")
		drawRect(firstImageMasked, transBox1)
		plt.imshow(firstImageMasked)
		plt.figure("next")
		drawRect(nextImage, transBox2)
		plt.imshow(nextImage)
		plt.show()
		
	if len(dirHist) > 5:
		p = norm.cdf(mag, loc=ndata.mean(), scale=ndata.std())
		#print("prob", p)
		#print("mag", mag, ndata.mean(), ndata.std())
		#print("past dirs", dirHist)
		#print("pastMags", ndata)
		#if dir[1] > 40 * (1+skipFrames):
			#print("dir (confirm):", dir)
			#
		if p >= 0.999999999:
			print("line 1350: reject, unable to track")
			return None, colorHist
	
	dirHist.append(dir)
	

		#plt.figure()
		#plt.imshow(convertFlowToImage(flow))
		#plt.show()
	
	
	
	#(tx, ty, tw, th) = transBox1
	#flow = flow[tx:tx+th,ty:ty+th]
	
	#flow = cv2.medianBlur(flow, 5)
	#median blur?
	
	
	#print(flow.shape)
	#(iw,ih, idim) = flow.shape  # middle probably most representative
	#print((iw,ih))
	#print(meanW,meanH)
	
	
	#flow *= scale
	#print("flow:", flow)

	
	#dir = flow[int(iw/2), int(ih/2)]
	#dir = []
	#dir.append((np.nanmean(flow[:,:, 0] * maskFirst)))
	#dir.append(np.nanmean((flow[:,:, 1] * maskFirst)))
	
	#if np.isnan(dir).any():
	#	print(flow)
	#	print("none due to nan")
	#	return oldBox #TODO: Change to none
	
	#sys.exit(1)
	(x,y,w,h) = oldBox
	
	newBox = (x + dir[1], y + dir[0], w , h )
	
	return (newBox, colorHist)
	

	
	
def fixBoxWandH(newBox, oldBox, oldConf, newImage, oldImage, totalSides, width, height):
	newBox1 = boxToImgCoords(newBox, width, height)
	nx1, ny1, nw1, nh1 = newBox1
	hDiff, vDiff = jiggerBoxPattern(newBox1, newImage, boxToImgCoords(oldBox, width, height), oldConf, oldImage, None, None, totalSides, None)
	scale = max(width, height)/300
	hDiff *= scale
	vDiff *= scale
	#print("alterinbg box by ", vDiff, hDiff)
	
	by1, bx1, by2, bx2 = toCornerForm(newBox) #backwards?
	
	ry = bx1 + hDiff
	rx = by1 + vDiff
	rh = (bx2-hDiff)-ry
	rw = (by2-vDiff)-rx
	
	
	(ogx,ogy,ogw,ogh) = newBox
	ocx = ogx + (ogw/2)
	ocy = ogy + (ogh/2)
	
	rcx = rx + (rw/2)
	rcy = ry + (rh/2)
	
	if int(rcx) != int(ocx) or int(rcy) != int(ocy):
		#print("Center mismatch!", (ocx,ocy), (rcx,rcy))
		#print("old box was", newBox)
		#print("new box is", (rx, ry, rw, rh))
		sys.exit(1)
	
	
	if rw < 5 or rh <5:
		#print("too small, aborting")
		return newBox
	#print("jiggered", (rx, ry, rw, rh))
	#sys.exit(1)
	return (rx, ry, rw, rh)
	
	
	#nx2, ny2, nw2, nh2 = newBox2  #want to use newBox2 directly but have rounding errors when upscale
	#newBox2T = boxFromImgCoords(newBox2, width, height)
	#print(newBox1, newBox2)
	#print(newBox, newBox2T)
	#sys.exit(-1)
	
	#(x,y,w,h) = newBox
	#newBox = (nx , y + ((ny2-ny1) * scale), w + ((nw2-nw1) * scale), h + ((nh2-nh1) * scale))
	#print("updated newbox", newBox)
	# (x,y,w,h) = newBox
	# if w + dirW <= 10:
		# dirW = 0
	# if h + dirH <= 10:
		# dirH = 0
	# x -= dirW/2
	# y -= dirH/2
	
	
	#newBox  = boxFromImgCoords(newBox, width, height)
	
totalSidesG = [None, None, None, None]
	


def generateSingleTrack(origDetections, startBox, startConf, startFrame, numFrames,frameWidth,frameHeight, frameImages):
	#startFrame(parameter) is one-indexed 
	kf = setup_kf(frameWidth,frameHeight, origDetections)
	print('startConf:', startConf)
	# copy detections
	detections = []
	for od in origDetections:
		detections.append(od.copy())
		
	
	colorHist = []
	dirHist = []
	outerDirHist = []
	
	fakeBoxes = set([])
	addedFakeFrames = set([])
	chosenBoxes = [(startFrame,startBox)]
	obsSeq = [boxToKalmanObs(startBox)]
	confSeq = [startConf] #TODO: May be unnecessary

	colorBoxes = set([])
	offScreenForward = False
	offScreenBackward = False
	trackerStartBox = scaleBox(startBox, frameWidth, frameHeight, 'down')
	medianFlowTracker = initExternalTracker(startFrame, frameImages[startFrame-1], trackerStartBox) #creates dictionary which includes 2 MedianFlowTracker objects---forward and backward
	
	while len(chosenBoxes) < numFrames:
		#try adding at end
		#if startConf == 0.65811265:
			#print('box 5', confSeq)

		curBest = {}
		curBest['maxProb'] = None
		curBest['maxBox'] = None
		curBest['maxProbDetect'] = -2
		curBest['maxAtEnd'] = True
		
		
		lastFrame, lastBox = chosenBoxes[-1]
		lastConf = confSeq[-1]

		if lastFrame+1 <= numFrames and not offScreenForward:
			# construct observation vector
			medianFlowTracker['forwardTracker'].init(frameImages[(lastFrame+1)-1], lastBox)
			curBest, offScreenForward = getBestBox( True,detections[(lastFrame+1)-1], curBest,obsSeq, confSeq, kf, frameWidth,frameHeight, detections, frameImages, colorHist, dirHist, outerDirHist, lastFrame+1, medianFlowTracker, 'forward')
		
		firstFrame, firstBox = chosenBoxes[0]
		firstConf = confSeq[0]
		if firstFrame-1 >= 1 and not offScreenBackward:
			medianFlowTracker['forwardTracker'].init(frameImages[(lastFrame-1)-1], lastBox)
			curBest, offScreenBackward = getBestBox( False, detections[(firstFrame-1)-1], curBest,obsSeq, confSeq, kf, frameWidth,frameHeight, detections, frameImages, colorHist, dirHist, outerDirHist, firstFrame-1, medianFlowTracker, 'backward')

		#if startConf == 0.77441597:
			#print(colorHist, 'colorHist of 0.77441597')
		occluded = False
		# do the add
		if curBest['maxBox'] is None:
			occluded = True
			#occluded etc.
			#print("could not find any close boxes! ", firstFrame-1, lastFrame+1)
			#if len(chosenBoxes) == 1:
			#	print("not sure what to do if this happens on the second box!")
			#	sys.exit(1)
			if lastFrame+1 > numFrames:
				curBest['maxAtEnd'] = False
			elif firstFrame-1 < 1:
				curBest['maxAtEnd'] = True
			else:#both valid, not sure which way to go
				curBest['maxAtEnd'] = random.choice([True, False]) 
		
		
		if curBest['maxAtEnd']:
			if  not occluded and curBest['maxIndex'] is None:
				#print("Chose optical flow box on frame ", (lastFrame+1))
				colorBoxes.add((lastFrame+1))
			if not occluded and curBest['maxIndex'] is not None:
				(box, score) = detections[(lastFrame+1)-1][curBest['maxIndex']]
				score /= 2
				detections[(lastFrame+1)-1][curBest['maxIndex']] = (box, score)
			

			
			
			chosenBoxes.append((lastFrame+1, curBest['maxBox']))
			obsSeq.append(boxToKalmanObs(curBest['maxBox']))
			confSeq.append(curBest['maxProbDetect'])
			#if 0.88805664 in confSeq:
				#print("fish 0 lastframe + 1: ", lastFrame+1)
				#if firstFrame+1 == 134:
					#sys.exit(1)

		else:
			if not occluded and curBest['maxIndex'] is None:
				colorBoxes.add((firstFrame-1))
			if not occluded and curBest['maxIndex'] is not None:
				(box, score) = detections[(firstFrame-1)-1][curBest['maxIndex']]
				score /= 2
				detections[(firstFrame-1)-1][curBest['maxIndex']] = (box, score)

			chosenBoxes.insert(0, (firstFrame-1, curBest['maxBox']))
			obsSeq.insert(0, boxToKalmanObs(curBest['maxBox']))
			confSeq.insert(0, curBest['maxProbDetect'])
			#if 0.88805664 in confSeq:
				#print("fish 0 firstframe - 1: ", firstFrame-1)
				#if firstFrame-1 == 134:

					#sys.exit(1)
		#adding code

	#print("chosen boxes:", chosenBoxes)

	# totalSides = [None, None, None, None]
	# for i in range(startFrame, numFrames):
		# frame, box = chosenBoxes[i]
		# if frame != i+1:
			# print("Frame number mismatch")
			# sys.exit(1)
		# if box is not None:
			# fixBox = fixBoxWandH(box, chosenBoxes[i-1][1], confSeq[i-1], frameImages[i], frameImages[i-1], totalSides, frameWidth, frameHeight)
			# #chosenBoxes[i] = (frame,fixBox)
			# obsSeq[i] = boxToKalmanObs(fixBox)
	
	# totalSides = [None, None, None, None]
	# for i in range(startFrame-2, -1, -1):
		# print("start frame", startFrame)
		# print("len cboxes", len(chosenBoxes))
		# print("len fimages", len(frameImages))
		# frame, box = chosenBoxes[i]
		# if frame != i+1:
			# print("Frame number mismatch")
			# sys.exit(1)
		# if box is not None:
			# fixBox = fixBoxWandH(box, chosenBoxes[i+1][1],  confSeq[i+1], frameImages[i], frameImages[i+1], totalSides, frameWidth, frameHeight)
			# #chosenBoxes[i] = (frame,fixBox)
			# obsSeq[i] = boxToKalmanObs(fixBox)
		
	
	
	#Smooth to eliminate missing boxes
	obsVec = np.ma.zeros((len(obsSeq), NUM_OBS))
	for t in range(len(obsSeq)):
		obsVec[t] = obsSeq[t]
	
	missing = set([])
			
	
	track = []
	(states, state_covs) = kf.smooth(obsVec)
	
	# newStates = [None] * len(states)
	# newStates[startFrame-1] = states[startFrame-1] 
	# totalSides = [None, None, None, None]
	# for i in range(startFrame, numFrames):
		# if confSeq[i] < LOW_CONFIDENCE:
			# (x,y,vx,vy,w,h) = states[i]
			# box = (x,y,w,h)
			# (px,py,pvx,pvy,pw,ph) = states[i-1]
			# prevbox = (px,py,pw,ph)
			# fixBox = fixBoxWandH(box, prevbox, confSeq[i-1], frameImages[i], frameImages[i-1], totalSidesG, frameWidth, frameHeight)
			# #chosenBoxes[i] = (frame,fixBox)
			# (x,y,w,h) = fixBox
		
			# newStates[i] = (x,y,vx,vy,w,h)
			# #newStates[i] = None
		# else:
			# newStates[i] = states[i]
	
	# #totalSides = [None, None, None, None]
	# for i in range(startFrame-2, -1, -1):
		# if confSeq[i] < LOW_CONFIDENCE:
			# (x,y,vx,vy,w,h) = states[i]
			# box = (x,y,w,h)
			# (px,py,pvx,pvy,pw,ph) = states[i+1]
			# prevbox = (px,py,pw,ph)
			# fixBox = fixBoxWandH(box, prevbox,  confSeq[i-1], frameImages[i], frameImages[i+1], totalSidesG, frameWidth, frameHeight)
			# #chosenBoxes[i] = (frame,fixBox)
			# (x,y,w,h) = fixBox
			# newStates[i] = (x,y,vx,vy,w,h)
		# else:
			# newStates[i] = states[i]
			
	# states = newStates
				
			
	for f in range(len(states)):
		if isMissingVector(obsVec[f]):
			(x,y,vx,vy,w,h) = states[f]
			box = (x,y,w,h)
			entry = (f+1, box)
			track.append(entry)
			missing.add(f+1)
		else:
			#(x,y,vx,vy,w,h) = obsVec[f] 
			(x,y,vx,vy,w,h) = states[f] 
			box = (x,y,w,h)
			entry = (f+1, box)
			track.append(entry)
	
	missing = missing.union(colorBoxes)
	highConf = []
	for f in range(len(confSeq)):
		if confSeq[f] >= MIN_START_CONFIDENCE:  #TODO: Better to sum these up?
			highConf.append(f+1)
	
	#print("confSeq len", len(confSeq))
	return track, chosenBoxes, missing, highConf, confSeq
			
				
				


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
	#Instantiate MEDIANFLOW tracker
	forwardTracker = cv2.TrackerMedianFlow_create() 
	possibleFor = forwardTracker.init(startImage, startBox)
	#if not possibleFor:
		#print('Line 1498, cv.tracker.init failed')
	backwardTracker = cv2.TrackerMedianFlow_create()
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
	
def generateSingleTrackMedianFlow(startingIndex, numFrames, bbox, images, frameWidth, frameHeight):
	#startingIndex is zero indexed
	track = []
	entry = (startingIndex+1, bbox)
	track.append(entry)
	newBox = None
	#instantiate tracker
	trackerStartBox = scaleBox(bbox, frameWidth, frameHeight, 'down')
	medianFlowTracker = initExternalTracker(startingIndex, images[startingIndex], trackerStartBox)
	backwardIndex = startingIndex
	forwardIndex = startingIndex+1
	#look forward
	while backwardIndex > 0:
		backwardIndex-=1
		newBox = getNewBoxColorTracker(images[backwardIndex], backwardIndex, medianFlowTracker, frameWidth, frameHeight, 'backward')
		entry = (backwardIndex+1, newBox)
		if newBox is not None:
			track.insert(0, entry)
	#look backward
	while forwardIndex < numFrames:
		newBox = getNewBoxColorTracker(images[forwardIndex], forwardIndex, medianFlowTracker, frameWidth, frameHeight, 'forward')
		entry = (forwardIndex+1, newBox)
		if newBox is not None:
			track.append(entry)
		forwardIndex+=1
	
	return track
	
	
def trackKPD(detections, numFrames, frameWidth, frameHeight, images):
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
			track = generateSingleTrackMedianFlow(maxFrame-1, numFrames, maxBox, images, frameWidth, frameHeight)
			for (i,b) in track:
				#print('I,B***', i,b)
				#if(b[2]>(frameWidth/3)):
					#print('HUGE BOX',len(allTracks), 'frame:', i)
				trackBoxes[i].append(b)
			if track is None:
				#print("Skipping")
				continue
			allTracks.append(track)
			#print("Final track #"+str(len(allTracks)-1), track)
			"""
			boxesUsed = boxesUsed.union(chosenBoxes)
			#also exclude overlapping boxes with final track
			overlaps = []
			totalBoxes = 0
			for (frame,boxT) in track:
				if frame not in missing:
					totalBoxes += 1
					if frame in trackBoxes:
						for box in trackBoxes[frame]:
							if boxOverlap(box, boxT):
								overlaps.append(frame)
								break
					for (box, score) in detections[frame-1]:
						#if (frame, box) in boxesUsed:
						#	continue
					
						if boxOverlap(box, boxT):
							#print("Overlap found!")
							boxesUsed.add((frame,boxT))
							boxesUsed.add((frame,box))
							
							break
			
			badFrames = set(overlaps)
			badFrames = badFrames.union(missing)
			
			selfNonOverlap = 0
			lastBox = None
			for (frame,boxT) in track:
				if lastBox is not None and not boxOverlap(lastBox, boxT):
					selfNonOverlap += 1
				lastBox = boxT
			#print("fast movements", selfNonOverlap)
			#badFrames = badFrames.union(lowConf)
			#print("On track ", len(allTracks), " comparing ",  len(badFrames),  " to ", totalBoxes)
			#if selfNonOverlap > 0:
			#	plt.imshow(images[0])
			#	plt.show()# if highconf + color_based_on_highconf - overlaps > 0.5
			#look for cases where jump a lot after overlap
			#if Nones correspond with high velocity
			
			confSum = 0
			for f in range(len(confSeq)):
				if f+1 in overlaps:
					continue
				if confSeq[f] > 0: #-1 for colorboxes etc.
					confSum += confSeq[f]
			
			
			#print("confSum", confSum)
			isolatedDetectionStartFrame = False #True:Frames before and after this have low confidence 
			#print(maxFrame)
			#print(confSeq[maxFrame-2])
			if (maxFrame-2 < 0 or confSeq[maxFrame-2] < LOW_CONFIDENCE) and (maxFrame >= len(confSeq) or confSeq[maxFrame] < LOW_CONFIDENCE):
				isolatedDetectionStartFrame = True # maxFrame start with 1 not 0
		if selfNonOverlap > 5: # TODO: relax
				print("reject selfNonOverlap:", selfNonOverlap)
				pass
			elif len(overlaps) > 0.5*totalBoxes:
				print("reject 2 len(overlaps) > 0.9*totalBoxes:")
				pass
			elif totalBoxes - len(badFrames) < -1000:
				# totalBoxes - len(badFrames) < 5
				print('confseq a',confSeq)
				print("reject 3 totalBoxes - len(badFrames) < -1000:")
				# -1 means color box and -2 means motion box
				pass
			elif confSum < 1:
				print("reject 4 (confSum < 1")
			elif isolatedDetectionStartFrame:
				print('reject 5 initial motion')
				#print("no new high!")
				#plt.imshow(images[0])
				#plt.show()
				pass
			else:
			#if True:
				#track2 = []
				#for f,t in track:
				#	if f not in missing:
				#		track2.append((f,t))
				#if len(allTracks) == 4 or len(allTracks) == 2:
					#print("finalizing track", len(allTracks))
					#plt.imshow(images[0])
					#plt.show()
				
				allTracks.append(track)
				#print("the track was accepted")
				#print('confSeq', confSeq) #0.88805664 fish zero highest confidence on travis alg
				#sys.exit()
				
				
				for (f,b) in track:
					if f not in trackBoxes:
						trackBoxes[f] = [b]
					else:
						trackBoxes[f].append(b)
			#if len(allTracks) > 3:
			#	sys.exit(-1)
	
	for i,b in allTracks[20]:
		_,b2 =  allTracks[22][i]
	#	print(b, b2)
	#	print(boxOverlap(b, b2))
	#print(confidences[20])
	#print(confidences[22])
	"""
	return allTracks

   

def load_frames(numFrames, frameWidth, frameHeight, imgPath):

	fgbg = cv2.createBackgroundSubtractorMOG2()
	
	scale = 300/max(frameWidth, frameHeight)
	
	frames = []
	for count in range(numFrames):
		imgNum = str(count+1).zfill(5)
		filename = "..\."+imgPath + "img" + str(imgNum) + ".jpg"
		
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
	images	= load_frames(numFrames, frameWidth,frameHeight, imgPath )
	tracks = trackKPD(detections, numFrames, frameWidth, frameHeight, images)
	#tracks = trackKPD(detections, numFrames, frameWidth, frameHeight)
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
