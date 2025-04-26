from time import time
import numpy as np
import random
import math
import sys
from pykfaster import KalmanFilter
from pykfaster.standard import _filter
from pykfaster.utils import log_multivariate_normal_density
from pykfaster.utils import get_params as kf_get_params
from util import load_mot, iou, interp_tracks
import cv2
#from cv2 import optflow
from matplotlib import pyplot as plt
from scipy.stats import norm
from scipy import linalg
import colorsys
#import pynche.ColorDB  #pulled into packages from python tools - must be a better way to do this
from collections import Counter
import copy
#profiling

import json

MIN_START_CONFIDENCE = 0.5 #If start box on a track have less than this, do not include
NUM_OBS = 6
MISSING_OBS = None#ma.masked
MISSING_VECTOR = None#np.ma.zeros(NUM_OBS)
LOW_CONFIDENCE = 0.2
NUM_COLS = 16
IGR = None
VID_ID = None#Only necessary for saving JSON, remove after testing

#These variables are used for ablation testing
ABLATE_PRE_FILTER = None  # Filter detections based on confidence?
ABLATE_NO_MEDFLOW_SWITCH = False  # Switch to MedianFlow while tracking?
ABLATE_NO_MEDFLOW_REPLACE = False  # Replace boxes with MedianFlow after track is built?
ABLATE_NO_JOIN = False  # Join Tracks?
ABLATE_TRIM_LATE = False  # Trim only when they fully leave the screen? (no acceleration)
ABLATE_TRIM_EARLY = False  # Trim Tracks near edge of screen?
ABLATE_TRIM_OFF_SCREEN = False  # Trim Tracks that are off-screen?
ABLATE_TRIM_ON_SCREEN = False  # Trim tracks if still fully on screen?
ABLATE_NO_LONG_LARGE = False  # Filter Long Large?
ABLATE_ACCEL_OFFSCREEN = False  # Accelerate offscreen?
#ABLATE_TRACKKPD_OVERLAPS = False  # Overlapping code in trackKPD
#ABLATE_TRACKKPD_BB_PEROFFS = False  # Bigger box and percent offscreen in trackKPD
ABLATE_INIT_LOOP = False # Testing the initial loop for speed performance (True = original code, False = new code implemented)
ABLATE_CHKMISS = False
DISABLE_PROFILER = True # Profiler enabled?
ABLATE_POST_TRIMMING = False # Filter_update in generateSingleTrack
SCALE_MEDFLOW = False # Scaling medflow?
BEFORE_LOADING = True # Starting speed calculation before loading frames?


if not DISABLE_PROFILER:
	import cProfile
	import pstats

def getMissingVector():
	ret = MISSING_VECTOR
	#ret[:] = MISSING_OBS
	return ret

def isMissingVector(obsVec):
	return (obsVec is None)#np.ma.is_masked(obsVec)

def toCornerForm(box):
	x,y,w,h = box
	return (x, y, x+w, y+h)

#shrink box to fit on lower res imgs
def shrinkBox(box, fw, fh):
	scale = 300/max(fw, fh)
	(x1, y1, width, height) = box
	width = int(width * scale)
	height = int(height * scale)
	x1 = int(x1 * scale)
	y1 = int(y1 * scale)

	return (x1, y1, width, height)

#if box is sized on lower res img, bump it back up
def growBox(box, fw, fh):
	scale = max(fw, fh)/300
	(x1, y1, width, height) = box
	width = int(width * scale)
	height = int(height * scale)
	x1 = int(x1 * scale)
	y1 = int(y1 * scale)

	return (x1, y1, width, height)

def boxOverlapOld(box1, box2):
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
	
def boxOverlap(box1, box2):
	if box1 is None or box2 is None:
		return False # edge case
	#get coordinates from boxes
	col1box1, row1box1, col2box1, row2box1 = toCornerForm(box1)
	col1box2, row1box2, col2box2, row2box2 = toCornerForm(box2)
	#get intersection rectangle coords
	#colA = max(col1box1, col1box2)
	if (col1box2 > col1box1):
		colA = col1box2
	else:
		colA = col1box1
	 
	#colB = min(col2box1, col2box2)
	if (col2box2 > col2box1):
		colB = col2box1
	else:
		colB = col2box2

	if colB <= colA:
		return False
	
	#rowA = max(row1box1, row1box2)
	if (row1box2 > row1box1):
		rowA = row1box2
	else:
		rowA = row1box1
	
	#rowB = min(row2box1, row2box2)
	if (row2box2 > row2box1):
		rowB = row2box1
	else:
		rowB = row2box2
	
	if rowB <= rowA:
		return False

	return True    


def uniformVariance(n):# n = b-a
	return (1.0/12.0) * n * n

def get_avg_detection_size(detections):
	totalWidth = 0
	totalHeight = 0
	count = 0
	#print("Get average detection_size")
	for f in range(len(detections)):
		#print(detections[f])
		for box, score in detections[f]:
			(x1, y1, width, height) = box
			totalWidth += width*score
			totalHeight += height*score
			count += score
	#print(totalWidth/count, totalHeight/count)
	return (totalWidth/count, totalHeight/count)

#from here: https://www.pyimagesearch.com/2016/11/07/intersection-over-union-iou-for-object-detection/
def bb_intersection_over_union(boxA, boxB):
	# determine the (x, y)-coordinates of the intersection rectangle
	xA = max(boxA[0], boxB[0])
	yA = max(boxA[1], boxB[1])
	xB = min(boxA[2], boxB[2])
	yB = min(boxA[3], boxB[3])
	# compute the area of intersection rectangle
	interArea = max(0, xB - xA + 1) * max(0, yB - yA + 1)
	# compute the area of both the prediction and ground-truth
	# rectangles
	boxAArea = (boxA[2] - boxA[0] + 1) * (boxA[3] - boxA[1] + 1)
	boxBArea = (boxB[2] - boxB[0] + 1) * (boxB[3] - boxB[1] + 1)
	# compute the intersection over union by taking the intersection
	# area and dividing it by the sum of prediction + ground-truth
	# areas - the interesection area
	iou = interArea / float(boxAArea + boxBArea - interArea)
	# return the intersection over union value
	return iou

'''
==================
Kalman Filter Functions
==================
'''


def get_initial_mean_and_cov(frameWidth, frameHeight, detections, avgDetectionSize, startBox):
	x,y,w,h = startBox
	avgWidth, avgHeight = avgDetectionSize
	initial_mean = np.array([x, y, 0, 0, w, h])
	initial_cov = np.array([[1, 0, 0, 0, 0, 0], \
							[0, 1, 0, 0, 0, 0], \
							[0, 0, 1, 0, 0, 0], \
							[0, 0, 0, 1, 0, 0], \
							[0, 0, 0, 0, 1, 0], \
							[0, 0, 0, 0, 0, 1] ])
	return (initial_mean,initial_cov)

def setup_kf(frameWidth, frameHeight, detections, avgDetectionSize, startBox):
	# The Kalman filter stores:
	#  x
	#  y
	#  v_x
	#  v_y
	#  width
	#  height

	avgWidth, avgHeight = avgDetectionSize

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
	#avgWidth, avgHeight = get_avg_detection_size(detections)
	observation_cov = np.array([[0.5, 0, 0, 0, 0, 0], \
								[0, 0.5, 0, 0, 0, 0], \
								[0, 0, 0, 0, 0, 0], \
								[0, 0, 0, 0, 0, 0], \
								[0, 0, 0, 0, 1, 0], \
								[0, 0, 0, 0, 0, 1] ]) #all pretty noisy

	(initial_mean,initial_cov) = get_initial_mean_and_cov(frameWidth, frameHeight, detections, avgDetectionSize, startBox)


	return KalmanFilter(transition_matrices=trans, observation_matrices=obs, \
			transition_covariance=transition_cov, observation_covariance=observation_cov, \
			initial_state_mean=initial_mean, initial_state_covariance=initial_cov )


#put box into correct array format for kalmanObs(cuts down on numpy overhead)
#only used in getBestBox
def formatBoxToKalmanObsArray(box, kalmanObsArr):
	if box is None:
		return getMissingVector()
	(x1, y1, width, height) = box
	kalmanObsArr[0,0] = x1
	kalmanObsArr[0,1] = y1
	kalmanObsArr[0,2] = 0.0
	kalmanObsArr[0,3] = 0.0
	kalmanObsArr[0,4] = width
	kalmanObsArr[0,5] = height
	return kalmanObsArr

#similar to above function, but this function is only used in genSingleTrack and for adding boxes to tracks(not in get best box)
def boxToKalmanObs(box):
	if box is None:
		return getMissingVector()
	(x1, y1, width, height) = box
	return np.array([x1, y1, 0, 0, width,height])

#Only needed for filterWithSingleObs
def parse_observations(obs):
	"""Safely convert observations to their expected format"""
	obs = np.atleast_2d(obs)
	#original functionality, assumes that we have more than one obs
	#if obs.shape[0] == 1 and obs.shape[1] > 1:
		#obs = obs.T
	return obs

#function to handle filtering when we only have one observation to work with(beginning of track)
def filterWithSingleObs(kf, X):
	"""
	Parameters
		----------
		X : [n_timesteps, n_dim_obs] array-like
			observations corresponding to times [0...n_timesteps-1].  If `X` is
			a masked array and any of `X[t]` is masked, then `X[t]` will be
			treated as a missing observation.
		Returns
		----------
		filtered_state_means : [n_timesteps, n_dim_state]
			mean of hidden state distributions for times [0...n_timesteps-1]
			given observations up to and including the current time step
		filtered_state_covariances : [n_timesteps, n_dim_state, n_dim_state] \
		array
			covariance matrix of hidden state distributions for times
			[0...n_timesteps-1] given observations up to and including the
			current time step
	"""
	Z = parse_observations(X)

	(transition_matrices, transition_offsets, transition_covariance,
	 observation_matrices, observation_offsets, observation_covariance,
	 initial_state_mean, initial_state_covariance) = (
		kf._initialize_parameters()
	)
	(_, _, _, filtered_state_means,
	 filtered_state_covariances) = (
		_filter(
			transition_matrices, observation_matrices,
			transition_covariance, observation_covariance,
			transition_offsets, observation_offsets,
			initial_state_mean, initial_state_covariance,
			Z
		)
	)
	return (filtered_state_means, filtered_state_covariances)


def getObsFromState(kf, pred_state, pred_state_cov):
	#print('pred_state', type(pred_state))
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

def getPredictedObsInfo(kf, pred_state, pred_state_cov, dummyKalmanObs, min_covar=1.e-7):
	#all this information is needed for log_multivariate_normal_density
	n_samples, n_dim = dummyKalmanObs.shape
	(predicted_obs, predicted_obs_cov) = getObsFromState(kf, pred_state, pred_state_cov) #convert predicted state to predicted obs
	cv = predicted_obs_cov #covariance
	cv_chol = linalg.cholesky(cv + min_covar * np.eye(n_dim), #cholesky decomp of covariance
								  lower=True)
	cv_log_det = 2 * np.sum(np.log(np.diagonal(cv_chol)))
	piLog =  np.log(2 * np.pi)

	predictedObsInfo = (np.array(predicted_obs[np.newaxis,:]), predicted_obs_cov[np.newaxis,:,:], cv_chol, cv_log_det, piLog, n_samples, n_dim)

	return predictedObsInfo


def log_multivariate_normal_density_kpd(predictedObsInfo, X):
	"""Log probability for full covariance matrices. """
	means, covars, cv_chol, cv_log_det, piLog, n_samples, n_dim = predictedObsInfo
	solve_triangular = linalg.solve_triangular

	nmix = len(means)
	log_prob = np.empty((n_samples, nmix))

	c=0
	mu = means[0]
	cv = covars[0]

	cv_sol = solve_triangular(cv_chol, (X - mu).T, lower=True).T
	log_prob[:, c] = - .5 * (np.sum(cv_sol ** 2, axis=1) + \
								 n_dim *piLog + cv_log_det)

	return log_prob

def getObsProbKF(predictedObsInfo, obs):

	#  1. Log likelihood is computed as the product of the filtered probabilites
	#  2.  Each filtered probability is based on the log_multivariate_normal_density
	#	   of the observation mean and observation cov (taken with dto product from state
	#		covariance
	#  3. in our case states take the same form as observations
	# So I think this is correct....
	if obs[0][0] == MISSING_OBS:
		print("Error! Trying to clauclate prob of missing observatioN!!!")\

	return log_multivariate_normal_density_kpd(predictedObsInfo, obs)


#check if box picked by kf and detection prob is ureasonable, and should be changed to "missing" box (box created by KF's predicted box)
def checkMissing(curBest, kf, allDetections, lastStateObsInfo, dummyKalmanObs, frameWidth,frameHeight, kalmanObsArr, avgDetectionSize, startBox, targetBox):


	missing = False
	lastProb = None
	(initial_mean,initial_cov) = get_initial_mean_and_cov(frameWidth, frameHeight, allDetections, avgDetectionSize, startBox)
	predObsInfo = getPredictedObsInfo(kf, initial_mean, initial_cov, dummyKalmanObs)
	#initProb = getObsProbKF(predObsInfo, formatBoxToKalmanObsArray(curBest['maxBox'], kalmanObsArr))

	#is centerpoint of maxBox contained in targetBox?
	#x,y,w,h = makeBiggerBox(curBest['maxBox'], fw, fh, .75)
	x,y,w,h = curBest['maxBox']
	centerPx = [(int(y + h/2), int(x + w/2))]
	numCoords, width, height = numCoordsInBox(targetBox,  frameWidth, frameHeight, centerPx)
	if numCoords == 0:
		missing = True
		#print("center check fails")

	# if initProb > curBest['maxProbKF']:
		# missing = False # missing = True
		#print('fail due to 1')
	#else:
	#Check Rule #2
	if not ABLATE_CHKMISS:
		lastProb = getObsProbKF(lastStateObsInfo, formatBoxToKalmanObsArray(curBest['maxBox'], kalmanObsArr))
		if lastProb > curBest['maxProbKF']:
			missing = True
			#print('fail due to 2')

	return missing, lastProb

'''
================================================================================================================================================
KPD Tracking
================================================================================================================================================
'''


def igrOverlap(box, igrRegion):
	if boxOverlap(box, igrRegion):
		x,y,w,h = box
		igrX = igrRegion[0]
		igrY = igrRegion[1]
		igrW = igrRegion[2]
		igrH = igrRegion[3]
		#xInt = max(x, igrX)
		if x > igrX:
			xInt = x
		else:
			xInt = igrX
		#yInt = max(y, igrY)
		if y > igrY:
			yInt = y
		else:
			yInt = igrY
		
		#wInt = min(x+w, igrX + igrW) - xInt
		if x+w < igrX + igrW:
			wInt = x+w -xInt
		else:
			wInt = igrX + igrW - xInt
		
		#hInt = min(y+h, igrY + igrH) - yInt
		if y+h < igrY + igrH:
			hInt = y+h -yInt
		else:
			hInt = igrY + igrH - yInt

		intersection =  wInt * hInt
		boxArea = w*h
		overlap = intersection / boxArea
		return overlap, wInt, hInt

	else:
		return 0,0,0


def percentOffScreen(x, y, w, h, frameWidth, frameHeight, findIGRs=False, igrList=None):
	global IGR
	xRightOnScreen = x+w
	xLeftOnScreen = frameWidth - x
	yTopOnScreen = y+h
	yBottomOnScreen = frameHeight - y
	#xOnScreen = min([xRightOnScreen, xLeftOnScreen, w]) # x value indicates part of a box on screen. 
	#														(larger min value indicates that the box may not be cut off)
	xOnScreen = xRightOnScreen
	if  xLeftOnScreen < xOnScreen:
		xOnScreen = xLeftOnScreen
	if  w < xOnScreen:
		xOnScreen = w
		
		
	#yOnScreen = min([yTopOnScreen, yBottomOnScreen, h])
	yOnScreen = yTopOnScreen
	if  yBottomOnScreen < yOnScreen:
		yOnScreen = yBottomOnScreen
	if  h < yOnScreen:
		yOnScreen = h
	percentOff = 1 - ((xOnScreen*yOnScreen) / (w*h))

	igrsTouched = []
	totalIgrPercentAreaOverlap = 0.0
	outOfScreen = False
	if igrList is None:
		igrList = IGR
	if igrList is not None:
		#print(IGR)
		for region in igrList:
			box = (x,y,w,h)
			igrPercentAreaOverlap, _, _  = igrOverlap(box,region)
			if igrPercentAreaOverlap > 0.0:
				totalIgrPercentAreaOverlap += igrPercentAreaOverlap
				if findIGRs:
					igrsTouched.append(region)
	if totalIgrPercentAreaOverlap > 0.0:
		outOfScreen = True #could be optimized
	elif xLeftOnScreen > 0 and yBottomOnScreen > 0 and xRightOnScreen < frameWidth and yTopOnScreen < frameHeight:
		outOfScreen = False
	else:
		outOfScreen = True
	
	#percentOff = max(totalIgrPercentAreaOverlap, percentOff)
	if totalIgrPercentAreaOverlap > percentOff:
		percentOff = totalIgrPercentAreaOverlap
	

	if findIGRs:
		return percentOff, outOfScreen, igrsTouched
	return percentOff, outOfScreen

def makeBiggerBox(box, fw, fh, percentBig, offScreenAllowed = False):
	x = box[0]
	y = box[1]
	w = box[2]
	h = box[3]
	wNew = percentBig*w
	hNew = percentBig*h
	xNew = x - (wNew - w)/2
	yNew = y - (hNew - h)/2


	if offScreenAllowed == False:
		#check out of bounds
		if xNew < 0:
			#wNew =wNew + (0 - xNew) ?? still want % bigger - if cant go one direction, go other?
			xNew = 0
		if xNew+wNew > fw:
			wNew = (fw - xNew)-1
		if yNew < 0:
			yNew = 0
		if yNew + hNew > fh:
			hNew = (fh - yNew) -1


	return xNew, yNew, wNew, hNew

#how many coordinate pairs in a list fall within a box?
#TODO: use shrink Box when calling if need be
def numCoordsInBox(box, fw, fh, coords,  scaleBox = False):
	if scaleBox == True:
		scale = 300/max(fw, fh)
		(x1, y1, width, height) = box
		width = int(width * scale)
		height = int(height * scale)
		x1 = int(x1 * scale)
		y1 = int(y1 * scale)
	else:
		(x1, y1, width, height) = box

	numCoords = 0

	for (ycoord, xcoord) in coords:
		if ycoord <= y1 + height and ycoord >= y1:
			if xcoord <= x1 + width and xcoord >= x1:
				numCoords += 1
	return numCoords, width, height


def detectionSkips(): #ONLY FOR PROFILER! REMOVE! #Try to comment out profiler 6.20.22
	return

def detectionCounter():#ONLY FOR PROFILER! REMOVE! #Try to comment out profiler 6.20.22
	return

def scaleBox(box, fw, fh, scaleUpOrDown):
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

#Core function.  Uses detections, kalman filter to choose box.  Determines if that box is good or not.  Conditionally decides if it should replace motion with median flow
def getBestBox(atEnd, frameDetections, origCurBest, obsSeq, confSeq, kf, frameWidth, frameHeight, allDetections, frameImages, frameIndex , firstPx, bestColor, pixelSeq, mfBoxSeq, avgDetectionSize, tracker, fullImages, indexMissing, chosenBoxes, filteredStateInfo, startBox, boxesUsed):


	curBest = origCurBest.copy() #necessary to deal with bidirectional stuff

	lastConf = None
	obsVec = np.zeros((len(obsSeq)+1, NUM_OBS))#TODO: take obsVec out since we don't really need it anymore
	if atEnd:
		for t in range(len(obsSeq)):
			obsVec[t] = obsSeq[t] #fills matrix with obsSeq
		obsVec[-1] = getMissingVector() #sets last vector in sequence to missing
		lastConf = confSeq[-1]
	else:
		for t in range(len(obsSeq)):
			obsVec[t+1] = obsSeq[t]
		obsVec[0] = getMissingVector()#sets first vector in sequence to missing
		lastConf = confSeq[0]

	#update the filter here with a missing observation, then update again in gensingle track with the actual observation
	filteredStateMean, filteredStateCovariance = filteredStateInfo
	#print('filteredStateMean before update', type(filteredStateMean))
	nextFilteredStateInfo = kf.filter_update(filteredStateMean, filteredStateCovariance, getMissingVector())
	(nextFilteredStateMean, nextFilteredStateCovariance) = nextFilteredStateInfo

	targetState = None
	targetStateCov = None
	lastIndex = None
	lastFrameIndex = None

	#target state is the box that KF thinks we should aim for
	targetState = nextFilteredStateMean
	targetStateCov = nextFilteredStateCovariance

	#update indexes depending on direction we are traveling
	if atEnd:
		#targetState = states[-1]
		#targetStateCov = state_covs[-1]
		lastIndex = len(obsVec)-2
		lastFrameIndex = frameIndex-1
	else:
		#targetState = states[0]
		#targetStateCov = state_covs[0]
		lastIndex = 1
		lastFrameIndex = frameIndex+1

	#if len(obsSeq) == 1:
	#	kfProb = getObsProbKF(states[lastIndex], state_covs[lastIndex], obsVec[lastIndex])
	#	print("Baseline KF Prob is", math.exp(kfProb))
	#No point in considering a box if it doesnt overlap with the current box
	(lx,ly,lvx,lvy,lw,lh) = targetState
	targetBox = (lx,ly,lw,lh)

	#Formatting issues with masked arrays
	#create an np array for the obs thtat is passed into getObsProbKF(reduces numpy overhead)
	kalmanObsArr = np.array([[0.0, 0.0, 0.0, 0.0, 0.0, 0.0]])#2D ARRAY

	#Setting up information needed for getObsProbKF
	dummyBox = (0,0,1,1) #need this info to format dimensionality in log_multivariate_normal_density
	dummyKalmanObs = formatBoxToKalmanObsArray(dummyBox, kalmanObsArr)
	predObsInfo = getPredictedObsInfo(kf, targetState, targetStateCov, dummyKalmanObs) #use dummyKalmanObs for dimensionality


	#(xT, yT, wT, hT) = makeBiggerBox(targetBox, frameWidth, frameHeight, 1.5)
	#find pixel coords in targetBox that are desired color
	# px, coords = getNumColorPixels((xT, yT, wT, hT), frameImages[frameIndex-1], frameWidth, frameHeight, bestColor)

	missing = True
	for i in  range(len(frameDetections)):
		(box,detectorProb) = frameDetections[i]


		if (not boxOverlap(box, targetBox)) or detectorProb<=0:
			#detectionSkips() #ONLY FOR PROFILER!
			continue



		#detectionCounter() #ONLY FOR PROFILER!
		#see how many detection boxes are actually being considered?

		#kfProb = getObsProbKF(kf, targetState, targetStateCov,  boxToKalmanObs(box))

		kfProb = getObsProbKF(predObsInfo,  formatBoxToKalmanObsArray(box, kalmanObsArr))
		overallProb = kfProb + math.log(detectorProb) #multiply

		if curBest['maxProb'] is None or curBest['maxProb'] < overallProb:

			#numPx = getNumColorPixels(box, frameImages[frameIndex-1], frameWidth, frameHeight, bestColor)

			#how many pixels in new box are also in above list?
			# numPx, width, height = numCoordsInBox(box, frameWidth, frameHeight, coords, True)
			# numPx2, width2, height2 = numCoordsInBox(makeBiggerBox(box, frameWidth, frameHeight, 1.5), frameWidth, frameHeight, coords, True)

			# inPrctPx = (width*height)*(4/100)
			# smallP = (numPx+inPrctPx)/((width*height) + inPrctPx*NUM_COLS)

			# inPrctPx2 = (width2*height2)*(4/100)
			# smallP2 = (numPx2+inPrctPx2)/((width2*height2) + inPrctPx2*NUM_COLS)

			# if smallP/smallP2 > 1.:
			curBest['maxProb'] = overallProb
			curBest['maxProbKF'] = kfProb
			curBest['maxProbDetect'] = detectorProb
			curBest['maxBox'] = box
			curBest['maxIndex'] = i
			curBest['maxAtEnd'] = atEnd
			# curBest['numPx'] = (numPx, smallP/smallP2)
			missing = False
			#curBest['maxColProbs'] = colorProbs

	#is curbest actually a good option, or is the box missing?
	# Rules:
	# 1. If had a higher chance of being initial state, reject
	# 2. If had a higher chance of being last state, reject

	lastKFProb = None
	if not missing:
		#prevents going down to lower prob boxes - this is what we want!
		#if  curBest['maxProbDetect'] < 0.5* lastConf:
		#	missing = True
		lastStateObsInfo = getPredictedObsInfo(kf, filteredStateMean, filteredStateCovariance, dummyKalmanObs)
		missing, lastKFProb = checkMissing( curBest, kf, allDetections,  lastStateObsInfo, dummyKalmanObs, frameWidth,frameHeight, kalmanObsArr, avgDetectionSize, startBox, targetBox)

		# if missing == True:
			# print(frameIndex-1, "check missing returns", missing)
		#if -.1<curBest['maxProbDetect']<.1:
		#	print("problem in checkMissing")

	debug = False

	origLastIndex = lastIndex
	#find last real box - prevents "hiccups"
	skipFrames = 0
	framesChecked = []

	if atEnd:
		delta = -1
		while lastIndex >= 0 and (isMissingVector(obsVec[lastIndex]) or -0.01 <= confSeq[lastIndex] < 0.0) : #orig .5
			lastIndex += delta
			lastFrameIndex  += delta
			skipFrames += 1
			framesChecked.append((lastFrameIndex, lastIndex, len(obsVec), atEnd))
	else:
		delta = 1
		while lastIndex < len(obsVec) and (isMissingVector(obsVec[lastIndex]) or -0.01 <= confSeq[lastIndex- delta] < 0.0) : #orig .5
			lastIndex += delta
			lastFrameIndex  += delta
			skipFrames += 1
			framesChecked.append((lastFrameIndex, lastIndex, len(obsVec), atEnd))

	'''
	if 0 <= lastIndex < len(obsVec): #here so that the fish doesn't jump frames
		#Try color-based box
		(lx,ly,lvx,lvy,lw,lh) = obsVec[lastIndex]
		lastBox = (lx,ly,lw,lh)

		lastFrame = frameImages[lastFrameIndex-1]
		curFrame = frameImages[frameIndex-1]
	'''

	if (not ABLATE_NO_MEDFLOW_SWITCH) or (not ABLATE_NO_MEDFLOW_REPLACE):
		#MEDFLOW

		#check that medflow box and possible box both contain the other's center coordinate
		# if not, and already on MF, set missing to true

		#determine if ok
		stored = False
		if tracker is not None:
			ok, bbox = tracker.update(fullImages[frameIndex-1])

			if ok:
				mfBoxSeq[frameIndex-1] = (False, bbox)
				stored = True
				if not SCALE_MEDFLOW:
					mfX, mfY, mfW, mfH = bbox
				else:
					mfX, mfY, mfW, mfH = scaleBox(bbox, frameWidth, frameHeight, 'up') # TODO: Rescale Image?
				mfCenterPx = [(int(mfY + mfH/2), int(mfX + mfW/2))]
				mfNumCoords, width, height = numCoordsInBox(targetBox,  frameWidth, frameHeight, mfCenterPx)
				if mfNumCoords == 0:
					ok = False

					#print(" earlier MF TB overlap fails", frameIndex-1)
		else:
			ok = False
			#print("no update because tracker is None")


		if not ok and not stored:
			mfBoxSeq[frameIndex-1] = (False, None)


		newStateInfo = None
		# do medflow checks and operations
		if ok:
			mfBoxSeq[frameIndex-1] = (True, bbox)

			if not missing:
				bX, bY, bW,bH = bbox
				bCenterPx = [(int(bY + bH/2), int(bX + bW/2))]
				bNumCoords, width, height = numCoordsInBox(curBest['maxBox'],  frameWidth, frameHeight, bCenterPx)

				mX, mY, mW, mH = curBest['maxBox']
				mCenterPx = [(int(mY + mH/2), int(mX + mW/2))]
				mNumCoords, width, height = numCoordsInBox(bbox,  frameWidth, frameHeight, mCenterPx)
				#print("check", frameIndex-1, centerPx, targetBox, mbNumCoords)

				if len(indexMissing[0]) > 2 and(mNumCoords == 0 or bNumCoords == 0):  #only if indexMissing is long enough (already switched to MF)
					missing = True


			if missing:
				#prevent using multiple frames in forward-backward loop
				if (frameIndex -1) not in indexMissing[0]:
					indexMissing[0].append(frameIndex-1)

					#if start of new missing list, store state information
					if indexMissing[1] is None:
						indexMissing[1] = filteredStateInfo
						indexMissing[2] = bbox
						indexMissing[3] = targetBox

			else:

				#check if box overlaps with any previous box.  If yes, set to missing, and add to MF hist
				# overlap = False
				# if (frameIndex, curBest['maxBox']) in boxesUsed: #boxes used tuple indexed at 1
					# overlap = True
					#print("used, marked missing!")
				# if overlap:
					#prevent using multiple frames in forward-backward loop
					# if (frameIndex -1) not in indexMissing[0]:
						# indexMissing[0].append(frameIndex-1)

						#if start of new missing list, store state information
						# if indexMissing[1] is None:
							# indexMissing[1] = filteredStateInfo
							# indexMissing[2] = bbox
							# indexMissing[3] = targetBox
				# else:
				#reset index missing
				indexMissing[0] = []
				indexMissing[1] = None
				indexMissing[2] = None
				indexMissing[3] = None

			#if ok and 3 missing indices in a row, replace motion with median flow
			#TODO: optimization.  this section is repetitive, should only replace those who haven't been replaced, not all in indexMissing
			#maybe if len(indexMissing[0]) > 3, just do most recent?  Remember to update the state info in index missing
			if not ABLATE_NO_MEDFLOW_SWITCH and len(indexMissing[0]) > 2: #replace obsSeq and confSeq with medflow values
				#check whether medianflow box and target box overlap
				if atEnd:
					index = -1 - (len(indexMissing[0])-2)

					step = 1
				else:
					index = 0 + (len(indexMissing[0])-2)
					step = -1

				mean, covar = indexMissing[1]
				#update previous frames
				for i in range(len(indexMissing[0])-1):
					valid, box = mfBoxSeq[indexMissing[0][0+i]]
					obsSeq[index] = boxToKalmanObs(box)
					confSeq[index] = -1
					chosenBoxes[index] = (indexMissing[0][0+i]+1, box)
					(mean, covar) = kf.filter_update(mean, covar, boxToKalmanObs(box))
					index += step
				#update current frame
				curBest['maxProbKF'] = None
				curBest['maxBox'] = bbox
				curBest['maxProbDetect'] = -1
				curBest['maxAtEnd'] = atEnd
				curBest['maxIndex'] = None
				newStateInfo = kf.filter_update(mean, covar, boxToKalmanObs(bbox))
				missing = False

		else: #not ok
			#print("tracker set to None", frameIndex-1)
			tracker = None

			#reset index missing
			indexMissing[0] = []
			indexMissing[1] = None
			indexMissing[2] = None
			indexMissing[3] = None
	else:
		newStateInfo = None


	x = filteredStateMean[0]
	y = filteredStateMean[1]
	w = filteredStateMean[4]
	h = filteredStateMean[5]
	x, y, w, h = makeBiggerBox((x, y, w, h), frameWidth, frameHeight, 1.5, offScreenAllowed=True)
	lastPercentOff, loutOfScreen, igrs = percentOffScreen(x,y,w,h, frameWidth, frameHeight, findIGRs=True)


	x = targetState[0]
	y = targetState[1]
	w = targetState[4]
	h = targetState[5]
	x, y, w, h = makeBiggerBox((x, y, w, h), frameWidth, frameHeight, 1.5, offScreenAllowed=True)
	currentPercentOff, coutOfScreen = percentOffScreen(x,y,w,h, frameWidth, frameHeight, igrList=igrs)


	offScreen = False
	if currentPercentOff > lastPercentOff:
		missing = True
		offScreen = True
		#print("offScreen", frameIndex-1)


	if missing and curBest['maxAtEnd'] == atEnd:
		curBest = origCurBest


	return curBest, offScreen, indexMissing, newStateInfo, tracker

def cropOutBoxArea(box, img, fw, fh):  #Area centered on Box
	x1,y1,owidth, oheight = map(int,  box)
	scale = 300/max(fw, fh)
	width = owidth * scale
	height = oheight * scale
	#print(scale)
	#print(owidth, width)
	#print(oheight, height)
	x1 = int(x1 * scale)
	y1 = int(y1 * scale)

	cropy1 = int(max(y1-0.5*height,0))
	cropy2 = int(min(y1+1.5*height, fh))
	cropx1 = int(max(x1-0.5*width, 0))
	cropx2 = int(min(x1+1.5*width, fw))
	newBox = (x1-cropx1, y1 - cropy1, int(width), int(height))
	return img[cropy1:cropy2,cropx1:cropx2], newBox

def drawRect(img, box):
	(x,y,w,h) = box
	cv2.rectangle(img, (x,y), (x+w, y+h), (0,255,0))

#if tracker is moving forward in time and have decided on a box, do necessary steps to add new box
def addForwardBox(curBest, lastFrame, detections, colorBoxes, chosenBoxes,  obsSeq, confSeq, pixelSeq, mfBoxSeq, tracker, frameWidth, frameHeight, frameImages):
	occluded = False
	if curBest['maxBox'] is None:
		#print('occluded!')
		occluded = True

	if  not occluded and curBest['maxIndex'] is None:
		colorBoxes.add((lastFrame+1))

	if not occluded and curBest['maxIndex'] is not None:
		(box, score) = detections[(lastFrame+1)-1][curBest['maxIndex']]
		#del detections[(lastFrame+1)-1][curBest['maxIndex']]
		score = 0
		detections[(lastFrame+1)-1][curBest['maxIndex']] = (box, score)

	chosenBoxes.append((lastFrame+1, curBest['maxBox']))
	obsSeq.append(boxToKalmanObs(curBest['maxBox']))
	confSeq.append(curBest['maxProbDetect'])
	pixelSeq.append(curBest['numPx'])

	#MEDLFOW
	if (not ABLATE_NO_MEDFLOW_SWITCH) or (not ABLATE_NO_MEDFLOW_REPLACE):
		if tracker is None and curBest['maxBox'] is not None:
			#print("Forward at confSeq", confSeq[-1])
			#tracker.init(frameImages[lastFrame-1], shrinkBox(curBest['maxBox'], frameWidth, frameHeight))
			tracker = cv2.legacy.TrackerMedianFlow_create()
			if SCALE_MEDFLOW:
				curBest['maxBox'] = scaleBox(curBest['maxBox'], frameWidth, frameHeight, 'down')
			tracker.init(frameImages[lastFrame], curBest['maxBox'])
		elif curBest['maxProbDetect'] > 0.5:
			# print("forward reinit", lastFrame)
			tracker = cv2.legacy.TrackerMedianFlow_create()
			if SCALE_MEDFLOW:
				curBest['maxBox'] = scaleBox(curBest['maxBox'], frameWidth, frameHeight, 'down')
			tracker.init(frameImages[lastFrame], curBest['maxBox'])

	return tracker

#if tracker is moving backward in time and have decided on a box, do necessary steps to add new box
def addBackwardBox(curBest, firstFrame, detections, colorBoxes, chosenBoxes, obsSeq, confSeq, pixelSeq, mfBoxSeq, tracker, frameWidth, frameHeight, frameImages):
	occluded = False
	if curBest['maxBox'] is None:
		#print('occluded!')
		occluded = True

	if not occluded and curBest['maxIndex'] is None:
		colorBoxes.add((firstFrame-1))

	if not occluded and curBest['maxIndex'] is not None:
		(box, score) = detections[(firstFrame-1)-1][curBest['maxIndex']]
		#del detections[(firstFrame-1)-1][curBest['maxIndex']]
		score = 0
		detections[(firstFrame-1)-1][curBest['maxIndex']] = (box, score)

	chosenBoxes.insert(0, (firstFrame-1, curBest['maxBox']))
	obsSeq.insert(0, boxToKalmanObs(curBest['maxBox']))
	confSeq.insert(0, curBest['maxProbDetect'])
	pixelSeq.insert(0, curBest['numPx'])

	#MEDLFOW
	if (not ABLATE_NO_MEDFLOW_SWITCH) or (not ABLATE_NO_MEDFLOW_REPLACE):
		if tracker is None and curBest['maxBox'] is not None:
			#print("Back at confSeq", confSeq[0])
			tracker = cv2.legacy.TrackerMedianFlow_create()
			if SCALE_MEDFLOW:
				curBest['maxBox'] = scaleBox(curBest['maxBox'], frameWidth, frameHeight, 'down')
			tracker.init(frameImages[firstFrame-2], curBest['maxBox'])
		elif curBest['maxProbDetect'] > 0.5:
			#print("back reinit", firstFrame)
			tracker = cv2.legacy.TrackerMedianFlow_create()
			if SCALE_MEDFLOW:
				curBest['maxBox'] = scaleBox(curBest['maxBox'], frameWidth, frameHeight, 'down')
			tracker.init(frameImages[firstFrame-2], curBest['maxBox'])
	return tracker

def resetCurBest(curBest):
	curBest['maxProb'] = None
	curBest['maxBox'] = None
	curBest['maxProbDetect'] = -2
	curBest['maxAtEnd'] = True
	curBest['maxColProbs'] = None
	curBest['color'] = None
	curBest['numPx'] = (None, None)

#give a set of images, init a new medflow tracker and update it on these images
def createTrackerWithHistory(imageList, startBox, images, frameWidth, frameHeight):
	tracker = None
	boxes = []
	for i in range(len(imageList)):
		if (not ABLATE_NO_MEDFLOW_SWITCH) or (not ABLATE_NO_MEDFLOW_REPLACE):
			if tracker is None:
				tracker = cv2.legacy.TrackerMedianFlow_create()
				if SCALE_MEDFLOW:
					startBox = scaleBox(startBox, frameWidth, frameHeight, 'down')
				tracker.init(images[imageList[i]], startBox)
				# TODO: Rescale Image?
				boxes.append(startBox)
			else:
				(ok, bbox) = tracker.update(images[imageList[i]])
				if SCALE_MEDFLOW:
					bbox = scaleBox(bbox, frameWidth, frameHeight, 'up')
				boxes.append(bbox)
	return tracker, boxes

#given a list of kfObs and a kalman filter, reinit kf and rewrite kf history with new obs
def buildKFHistory(kf, obsList, atEnd):
	#determine which direction to iterate through
	if atEnd:
		index = len(obsList)-1
		step = -1
	else:
		index = 0
		step = 1

	#switch initial in kf
	kf.initialStateMean = obsList[index]

	#start off kf
	initMean, initCovar = filterWithSingleObs(kf, obsList[index])
	mean, covar = (initMean[0].copy(), initCovar[0].copy())
	index += step

	#for all obs in list, update kf
	for i in range(1, len(obsList)):
		mean, covar = kf.filter_update(mean, covar, obsList[index])
		index += step

	#return new current state obs
	return (mean, covar)

#given sequences for a full or partial track, go through each box and determine whether to
#keep detection, or replace with motion or medflow frame
def checkAndReplceBoxes(confSeq, obsSeq, mfBoxSeq, chosenBoxes, boxesUsed):
	newConfSeq = []
	newObsSeq = []
	newChosenBoxes = []
	prevBox = None
	for i in range(len(confSeq)):  # look through whole track
		goodBox = True

		if confSeq[i] == -2: #is it missing
			goodBox = False

		elif confSeq[i] > 0: #is it overlapping with a previous used box
			x, y, vx, vy, w, h = obsSeq[i]
			if (i+1, (x,y,w,h))in boxesUsed: #boxes used indexed at 1
				goodBox = False

		valid, mfBox  = mfBoxSeq[i]
		if not valid:
			mfBox = None
		if goodBox:  # if good, keep orig values
			newConfSeq.append(confSeq[i])
			newObsSeq.append(obsSeq[i])
			newChosenBoxes.append(chosenBoxes[i])
			ind, curBox = chosenBoxes[i]
		elif prevBox is None or not boxOverlap(prevBox, mfBox): #if mf box does not overlap with previous real box, use motion box
				newConfSeq.append(-2)
				newObsSeq.append(boxToKalmanObs(None))
				newChosenBoxes.append((i+1, None))
				curBox = None
		else:  #else, replace with medflow
			# TODO: Rescale images?
			newConfSeq.append(-1)
			newObsSeq.append(boxToKalmanObs(mfBox))
			newChosenBoxes.append((i+1, mfBox))
			curBox = mfBox
		prevBox = curBox

	return newConfSeq, newObsSeq, newChosenBoxes

#given sequences for a particular track, split into forward and backward tracks, send to checkAndReplceBoxes
#and recombine results
def replaceBadBoxesWithMF(confSeq, obsSeq, mfBoxSeq, chosenBoxes, boxesUsed, startFrame):
	fNewConfSeq = []
	fNewObsSeq = []
	fNewChosenBoxes = []
	bNewConfSeq = []
	bNewObsSeq = []
	bNewChosenBoxes = []

	#split and reverse backward track
	bCS = confSeq[0:startFrame] #start frame indexed at 1
	bCS.reverse()
	bOS = obsSeq[0:startFrame]
	bOS.reverse()
	bMF = mfBoxSeq[0:startFrame]
	bMF.reverse()
	bCB = chosenBoxes[0:startFrame]
	bCB.reverse()

	if startFrame > 0:
		bNewConfSeq , bNewObsSeq , bNewChosenBoxes = checkAndReplceBoxes(bCS, bOS, bMF, bCB, boxesUsed)
	if startFrame < len(confSeq):
		fNewConfSeq , fNewObsSeq , fNewChosenBoxes = checkAndReplceBoxes(confSeq[startFrame-1:len(confSeq)], obsSeq[startFrame-1:len(confSeq)], mfBoxSeq[startFrame-1:len(confSeq)], chosenBoxes[startFrame-1:len(confSeq)], boxesUsed)

	#unreverse backward track
	bNewConfSeq.reverse()
	bNewObsSeq.reverse()
	bNewChosenBoxes.reverse()

	#remove duplicate start state, only if it exists (neither state list is len 0)
	if len(fNewConfSeq) != 0 and len(bNewConfSeq) != 0:
		bNewConfSeq = bNewConfSeq[0:len(bNewConfSeq)-1]
		bNewObsSeq = bNewObsSeq[0:len(bNewObsSeq)-1]
		bNewChosenBoxes = bNewChosenBoxes[0:len(bNewChosenBoxes)-1]

	#concat back and forward tracks
	newConfSeq =  bNewConfSeq + fNewConfSeq
	newObsSeq = bNewObsSeq + fNewObsSeq
	newChosenBoxes = bNewChosenBoxes + fNewChosenBoxes


	return newConfSeq, newObsSeq, newChosenBoxes

def forciblyExtendStates(kf, statesList, covsList, desiredNum):
	#missingObs = getMissingVector()
	x,y,vx,vy,w,h= statesList[-1]
	for i in range(desiredNum):
		#nextMean, nextCovar = kf.filter_update(statesList[-1], covsList[-1], missingObs)
		x += vx
		y += vy
		#print("forcibly extended, old", statesList[-1], "new", nextMean)
		statesList.append((x,y,vx,vy,w,h))
		covsList.append(covsList[-1]) #Don't think this matters
	return statesList, covsList
	
	
#splits track into forwards and backwards, then smooths with Kalman filter
def smoothTrack(kf_old, startFrame, numFrames, obsSeq, confSeq, kfInfo):
	#print("start obs is ", obsSeq[startFrame-1])
	(frameWidth,frameHeight, origDetections, avgDetectionSize) = kfInfo
	#print("smooth called, staart conf is ", confSeq[startFrame-1], " startFrame", startFrame, "avg size", avgDetectionSize, "obsSeq[270]", obsSeq[270])
	x, y, vx, vy, w, h = obsSeq[startFrame-1]
	startBox = (x,y,w,h)
	kf = setup_kf(frameWidth,frameHeight, origDetections, avgDetectionSize, startBox)
	numContext = 4
	bIndex = (startFrame)
	for i in range(numContext):
		if bIndex < numFrames:
			bIndex += 1
	backObsSeq = obsSeq[0:bIndex]

	fIndex = (startFrame-1)
	for i in range(numContext):
		if fIndex > 0:
			fIndex -= 1
	forObsSeq = obsSeq[fIndex:numFrames]
	backObsSeq.reverse()

	#build obsVec (numpy verion of obsSeq)
	backObsVec = np.ma.zeros((len(backObsSeq), NUM_OBS))
	forObsVec = np.ma.zeros((len(forObsSeq), NUM_OBS))

	for t in range(len(backObsSeq)):
		if backObsSeq[t] is None:
			backObsVec[t,:] = np.ma.masked
		else:
			backObsVec[t] = backObsSeq[t]

	for t in range(len(forObsSeq)):
		if forObsSeq[t] is None:
			forObsVec[t,:] = np.ma.masked
		else:
			forObsVec[t] = forObsSeq[t]

	frameBuffer = 10  #How many extra frames to do on each side (offscreen etc.)
	backMissings = max(countTrimEdge(confSeq, 0, 1, 0)-frameBuffer,0)
	forMissings = max(countTrimEdge(confSeq, len(confSeq)-1, -1, 0)-frameBuffer, 0)
	#print("Missings:", backMissings, forMissings)
	#print(confSeq)
	#smooth both directions
	if len(backObsVec) > 0:
		toRun = backObsVec[:len(backObsVec)-backMissings]
		#print("Calling backwards smooth on", len(toRun), "frames")
		(backStates, backState_covs) = kf.smooth(toRun)
		(backStates, backState_covs) = forciblyExtendStates(kf, list(backStates),list(backState_covs), backMissings)
		backStates = np.array(backStates)
	else:
		backStates = []
	if len(forObsVec) > 0:
		#print("Calling forwards smooth on", len(toRun), "frames")
		toRun = forObsVec[:len(forObsVec)-forMissings]
		(forStates, forState_covs) = kf.smooth(toRun)
		(forStates, forState_covs) = forciblyExtendStates(kf, list(forStates),list(forState_covs), forMissings)
		forStates = np.array(forStates)
	else:
		forStates = []
	 
	#if forMissings > 0:
	#	forStates = np.concatenate((forStates, np.array(oldTrack[len(oldTrack)-forMissings:])))
	#if backMissings > 0:
		#print("index calc", len(oldTrack), "-" ,backMissings)
		#print(backStates.shape)
		#oldArray = oldTrack[len(oldTrack)-backMissings:]
		#print(len(oldArray))
		#for i in range(len(oldArray)):
		#	print(len(oldArray[i]))
	#	backStates = np.concatenate((backStates, np.array(oldTrack[len(oldTrack)-backMissings:])))


	#reverses numpy array
	backStates = backStates[::-1]

	#take out context
	for i in range(numContext):
		if bIndex > startFrame:
			backStates = backStates[0:len(backStates)-1]
			bIndex -= 1
		if fIndex < startFrame-1:
			forStates = forStates[1:numFrames]
			fIndex +=1
	
	#print("after trimming context forward len = ", len(forStates), "and back len=", len(backStates))
	#remove duplicate start state, only if it exists (neither state list is len 0)
	if len(backStates) != 0 and len(forStates) != 0:
		backStates = backStates[0:len(backStates)-1]
	#print("after remove duplicate forward len = ", len(forStates), "and back len=", len(backStates))
	#if len(forStates) != 0:
	#	print("first for state is now", forStates[0])
	#create full state list
	states = np.zeros((len(obsSeq), NUM_OBS))
	for t in range(len(obsSeq)):
		if t < len(backStates):
			# In theory the velocity should be reversed, 
			# but it's not due to the way accelerateOffscreen uses it
			states[t] = backStates[t]
		else:
			states[t] = forStates[t - (len(backStates))]
	#print("after join, start state is ", states[startFrame-1])

	track = []
	missing = set([])
	for f in range(len(states)):
		if isMissingVector(obsSeq[f]):
			(x,y,vx,vy,w,h) = states[f]
			box = (x,y,w,h)
			entry = (f+1, box)
			track.append(entry)
			if confSeq[f] != -3: #only do if not -3?
				missing.add(f+1)
		else:
			#(x,y,vx,vy,w,h) = obsSeq[f]
			(x,y,vx,vy,w,h) = states[f]
			box = (x,y,w,h)
			entry = (f+1, box)
			track.append(entry)
	return track, states, missing

#core function that calls get best box until all frames have boxes for a single track
def generateSingleTrack(origDetections, avgDetectionSize, startBox, startConf, startFrame, numFrames,frameWidth,frameHeight, frameImages, fullImages, boxesUsed):
	#Start frame is one indexed!! detections is zero indexed
	kf = setup_kf(frameWidth,frameHeight, origDetections, avgDetectionSize, startBox)



	#print('startConf:', startConf)
	#print('startFrame', startFrame-1)
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
	#print("fr", numFrames)
	mfBoxSeq = [(None,None)]*numFrames
	#print("len", len(mfBoxSeq))
	#print("st", startFrame)
	mfBoxSeq[startFrame-1] = (True, startBox)
	firstCol = None
	#firstPx, bestColor = boxToBestColor(startBox, frameImages[startFrame-1], frameWidth, frameHeight, .75, 1.25)
	firstPx, bestColor = (None, None)
	pixelSeq = [(firstPx, None)]
	colProbSeq=[0]


	# normImg, newBox = cropOutBoxArea(startBox, frameImages[startFrame-2], frameWidth, frameHeight)
	# newImg = colorImg(normImg, frameWidth, frameHeight)

	# drawRect(normImg, newBox)
	# drawRect(newImg, newBox)
	# newImg = cv2.cvtColor(newImg, cv2.COLOR_BGR2RGB)
	# normImg = cv2.cvtColor(normImg, cv2.COLOR_BGR2RGB)

	# f, axarr = plt.subplots(1,2)
	# axarr[0].imshow(normImg)
	# axarr[1].imshow(newImg)
	# plt.title("startConf: "+ str(startConf))
	# plt.show()
	colorBoxes = set([])
	offScreenForward = False#Did the object leave the frame of view?
	offScreenBackward = False
	curBest = {}

	#initiate filterring
	obsVec = np.zeros((len(obsSeq), NUM_OBS))
	obsVec[0] = obsSeq[0]
	(initialStateMeans, initialStateCovariances)= filterWithSingleObs(kf, obsVec)#special function we wrote to predict from single observation

	#need to set up state info for forward and backward
	forwardStateInfo =(initialStateMeans[0].copy(), initialStateCovariances[0].copy())
	backwardStateInfo =(initialStateMeans[0].copy(), initialStateCovariances[0].copy())

	imagesForward = [(startFrame-1)]
	imagesBack = [(startFrame-1)]

	#indexmissing keeps track of a list of frames to potentially replace with medflow
	#it also stores information about the kf state and medflow box associated with the first index in the list
	indexMissingF = [[],None , None, None]
	indexMissingB = [[], None, None, None]

	#keeps track of how many missing in a row.  if >5, keep on motion for rest of the direction
	missingStreakForward = 0
	missingStreakBackward = 0

	loop = 4
	while len(chosenBoxes) < loop:
		resetCurBest(curBest)

		#MEDFLOW
		trackerForward, bx = createTrackerWithHistory(imagesForward, startBox, fullImages, frameWidth, frameHeight)
		trackerBack, bx = createTrackerWithHistory(imagesBack, startBox, fullImages, frameWidth, frameHeight)

		"""
		FORWARD DIRECTION
		"""
		lastFrame, lastBox = chosenBoxes[-1]
		lastConf = confSeq[-1]
		if lastFrame+1 <= numFrames and not offScreenForward:
			# construct observation vector
			curBest, offScreenForward, indexMissingF, newStateInfoF, trackerForward  = getBestBox(True,detections[(lastFrame+1)-1], curBest,obsSeq, confSeq, kf, frameWidth,frameHeight, detections, frameImages, lastFrame+1, firstPx, bestColor, pixelSeq, mfBoxSeq, avgDetectionSize, trackerForward, fullImages, indexMissingF, chosenBoxes, forwardStateInfo, startBox, boxesUsed)
		elif offScreenForward:
			curBest['maxProbDetect'] = -3
			curBest['maxIndex'] = None
			curBest['maxAtEnd'] = True
			filteredStateMeanF, filteredStateCovarianceF = forwardStateInfo
			forwardStateInfoMissing = kf.filter_update(filteredStateMeanF, filteredStateCovarianceF, getMissingVector())
			(nextFilteredStateMeanF, nextFilteredStateCovarianceF) = forwardStateInfoMissing
			xF, yF, vxF, vyF, wF, hF =  nextFilteredStateMeanF
			curBest['maxBox'] = (xF, yF, wF, hF)
		if not offScreenForward and missingStreakForward > 5:
			resetCurBest(curBest)

		"""
		BACKWARD DIRECTION
		"""
		#print('backward')
		firstFrame, firstBox = chosenBoxes[0]
		firstConf = confSeq[0]
		if firstFrame-1 >= 1 and not offScreenBackward:
			#print("back", firstFrame)  gets here
			curBest, offScreenBackward, indexMissingB, newStateInfoB, trackerBack = getBestBox( False, detections[(firstFrame-1)-1], curBest,obsSeq, confSeq, kf, frameWidth,frameHeight, detections, frameImages, firstFrame-1, firstPx, bestColor, pixelSeq, mfBoxSeq, avgDetectionSize, trackerBack, fullImages, indexMissingB, chosenBoxes, backwardStateInfo, startBox, boxesUsed)
		elif offScreenBackward:
			curBest['maxProbDetect'] = -3
			curBest['maxIndex'] = None
			curBest['maxAtEnd'] = False
			filteredStateMeanB, filteredStateCovarianceB = backwardStateInfo
			backwardStateInfoMissing = kf.filter_update(filteredStateMeanB, filteredStateCovarianceB, getMissingVector())
			(nextFilteredStateMeanB, nextFilteredStateCovarianceB) = backwardStateInfoMissing
			xB, yB, vxB, vyB, wB, hB =  nextFilteredStateMeanB
			curBest['maxBox'] = (xB, yB, wB, hB)
		if not offScreenBackward and missingStreakBackward > 5:
			resetCurBest(curBest)

		occluded = False

		if curBest['maxBox'] is None:
			occluded = True
			if lastFrame+1 > numFrames:
				curBest['maxAtEnd'] = False
			elif firstFrame-1 < 1:
				curBest['maxAtEnd'] = True
			else:#both valid, not sure which way to go
				curBest['maxAtEnd'] = random.choice([True, False])
		if curBest['maxAtEnd']:
			if ((lastFrame+1)-1) not in imagesForward:
				imagesForward.append((lastFrame+1)-1)
				#KF update
				forwardStateMean, forwardStateCovariance = forwardStateInfo
				#when motion is returned, update with missing vector, otherwise update with curbest
				#print("before update", type(forwardStateMean))
				if curBest['maxBox'] is None:
					forwardStateInfo = kf.filter_update(forwardStateMean, forwardStateCovariance, getMissingVector())  #TODO: Optimize (same as bestBox)...found to not make much of a difference 6.17.22
				elif newStateInfoF is not None:
					forwardStateInfo = newStateInfoF
					newStateInfoF = None
				else:
					forwardStateInfo = kf.filter_update(forwardStateMean, forwardStateCovariance, boxToKalmanObs(curBest['maxBox']))

				if curBest['maxProbDetect'] == -2 or missingStreakForward > 5:
					missingStreakForward += 1
				else:
					missingStreakForward = 0
			trackerForward = addForwardBox(curBest, lastFrame, detections, colorBoxes, chosenBoxes,  obsSeq, confSeq, pixelSeq, mfBoxSeq, trackerForward, frameWidth, frameHeight, fullImages)
			backwardStateInfo = buildKFHistory(kf, obsSeq, True)
		else:
			if ((firstFrame-1)-1) not in imagesBack:
				imagesBack.append((firstFrame-1)-1)
				#KF update
				backwardStateMean, backwardStateCovariance = backwardStateInfo
				#when motion is returned, update with missing vector, otherwise update with curbest
				#print("before update", type(backwardStateMean))
				if curBest['maxBox'] is None:
					backwardStateInfo = kf.filter_update(backwardStateMean, backwardStateCovariance, getMissingVector())  #TODO: Optimize (same as bestBox)...found to not make much of a difference 6.17.22
				elif newStateInfoB is not None:
					backwardStateInfo = newStateInfoB
					newStateInfoB = None
				else:
					backwardStateInfo = kf.filter_update(backwardStateMean, backwardStateCovariance, boxToKalmanObs(curBest['maxBox']))

				if curBest['maxProbDetect'] == -2 or missingStreakBackward > 5:
					missingStreakBackward += 1
				else:
					missingStreakBackward = 0
			trackerBack = addBackwardBox(curBest, firstFrame, detections, colorBoxes, chosenBoxes, obsSeq, confSeq, pixelSeq, mfBoxSeq, trackerBack, frameWidth, frameHeight, fullImages)
			forwardStateInfo = buildKFHistory(kf, obsSeq, False)


	#reset KF to be start box
	kf.initialStateMean = boxToKalmanObs(startBox)

	#MEDFLOW
	trackerForward, bx = createTrackerWithHistory(imagesForward, startBox, fullImages, frameWidth, frameHeight)
	trackerBack, bx = createTrackerWithHistory(imagesBack, startBox, fullImages, frameWidth, frameHeight)
	"""
	FORWARD DIRECTION
	"""
	lastFrame, lastBox = chosenBoxes[-1]
	lastConf = confSeq[-1]

	while lastFrame+1 <= numFrames:
		#print('going forward')
		#print('confSeq', confSeq)
		resetCurBest(curBest)
		#print('forwardStateInfo',forwardStateInfo)
		if not offScreenForward:
			curBest, offScreenForward, indexMissingF, newStateInfoF, trackerForward  = getBestBox(True,detections[(lastFrame+1)-1], curBest,obsSeq, confSeq, kf, frameWidth,frameHeight, detections, frameImages, lastFrame+1, firstPx, bestColor, pixelSeq, mfBoxSeq, avgDetectionSize, trackerForward, fullImages, indexMissingF, chosenBoxes, forwardStateInfo, startBox, boxesUsed)
		else:
			curBest['maxProbDetect'] = -3
			curBest['maxIndex'] = None
			curBest['maxAtEnd'] = True
			if not ABLATE_POST_TRIMMING:
				filteredStateMeanF, filteredStateCovarianceF = forwardStateInfo
				forwardStateInfoMissing = kf.filter_update(filteredStateMeanF, filteredStateCovarianceF,
														   getMissingVector())
				(nextFilteredStateMeanF, nextFilteredStateCovarianceF) = forwardStateInfoMissing
				xF, yF, vxF, vyF, wF, hF = nextFilteredStateMeanF
				curBest['maxBox'] = (xF, yF, wF, hF)
			else:
				curBest['maxBox'] = (0, 0, 0, 0)  # added 6.20.22

				# filteredStateMeanF, filteredStateCovarianceF = forwardStateInfo
				# xF, yF, vxF, vyF, wF, hF = forwardStateInfo
				# curBest['maxBox'] = (xF, yF, wF, hF)

		if not offScreenForward and missingStreakForward > 5:
			resetCurBest(curBest)

		forwardStateMean, forwardStateCovariance = forwardStateInfo
		#when motion is returned, update with missing vector, otherwise update with curbest
		if curBest['maxBox'] is None:
			#offScreenForward = True
			forwardStateInfo = kf.filter_update(forwardStateMean, forwardStateCovariance, getMissingVector())  #TODO: Optimize (same as bestBox)...found to not make much of a difference 6.17.22
		elif newStateInfoF is not None:
			forwardStateInfo = newStateInfoF
			newStateInfoF = None
		else:
			if curBest['maxBox'] != (0, 0, 0, 0): #added 6.20.22
				forwardStateInfo = kf.filter_update(forwardStateMean, forwardStateCovariance, boxToKalmanObs(curBest['maxBox']))

		if curBest['maxProbDetect'] == -2 or missingStreakForward > 5:
			missingStreakForward += 1
		else:
			missingStreakForward = 0
		trackerForward = addForwardBox(curBest, lastFrame, detections, colorBoxes, chosenBoxes,  obsSeq, confSeq, pixelSeq, mfBoxSeq, trackerForward, frameWidth, frameHeight, fullImages)
		lastFrame, lastBox = chosenBoxes[-1]
		lastConf = confSeq[-1]
	"""
	BACKWARD DIRECTION
	"""
	firstFrame, firstBox = chosenBoxes[0]
	firstConf = confSeq[0]
	while firstFrame-1 >= 1:
		#print('going backward')
		resetCurBest(curBest)
		if not offScreenBackward:

			curBest, offScreenBackward,indexMissingB, newStateInfoB, trackerBack = getBestBox(False, detections[(firstFrame-1)-1], curBest,obsSeq, confSeq, kf, frameWidth,frameHeight, detections, frameImages, firstFrame-1, firstPx, bestColor, pixelSeq, mfBoxSeq, avgDetectionSize, trackerBack, fullImages, indexMissingB, chosenBoxes, backwardStateInfo, startBox, boxesUsed)
		else:
			curBest['maxProbDetect'] = -3
			curBest['maxIndex'] = None
			curBest['maxAtEnd'] = False

			if not ABLATE_POST_TRIMMING:
				filteredStateMeanB, filteredStateCovarianceB = backwardStateInfo
				backwardStateInfoMissing = kf.filter_update(filteredStateMeanB, filteredStateCovarianceB, getMissingVector())
				(nextFilteredStateMeanB, nextFilteredStateCovarianceB) = backwardStateInfoMissing
				xB, yB, vxB, vyB, wB, hB = nextFilteredStateMeanB
				curBest['maxBox'] = (xB, yB, wB, hB)

			else:
				curBest['maxBox'] = (0, 0, 0, 0)  # added 6.20.22

				# filteredStateMeanB, filteredStateCovarianceB = backwardStateInfo
				# xB, yB, vxB, vyB, wB, hB = backwardStateInfo
				# curBest['maxBox'] = (xB, yB, wB, hB)

		if not offScreenBackward and missingStreakBackward > 5:
			resetCurBest(curBest)
		backwardStateMean, backwardStateCovariance = backwardStateInfo
		#when motion is returned, uptdate with missing vector, otherwise update with curbest
		if curBest['maxBox'] is None:
			#offScreenBackward = True
			backwardStateInfo = kf.filter_update(backwardStateMean, backwardStateCovariance, getMissingVector())  #TODO: Optimize (same as bestBox)...found to not make much of a difference 6.17.22
		elif newStateInfoB is not None:
			backwardStateInfo = newStateInfoB
			newStateInfoB = None
		else:
			if curBest['maxBox'] != (0, 0, 0, 0):#added 6.20.22
				backwardStateInfo = kf.filter_update(backwardStateMean, backwardStateCovariance, boxToKalmanObs(curBest['maxBox'])) #TODO: Optimize

		if curBest['maxProbDetect'] == -2 or missingStreakBackward > 5:
			missingStreakBackward += 1
		else:
			missingStreakBackward = 0
		trackerBack = addBackwardBox(curBest, firstFrame, detections, colorBoxes, chosenBoxes, obsSeq, confSeq, pixelSeq, mfBoxSeq, trackerBack, frameWidth, frameHeight, fullImages)
		firstFrame, firstBox = chosenBoxes[0]
		firstConf = confSeq[0]


	#check if it makes sense to replace bad boxes with medflow
	#print("before",confSeq)
	if not ABLATE_NO_MEDFLOW_REPLACE:
		confSeq, obsSeq, chosenBoxes = replaceBadBoxesWithMF(confSeq, obsSeq, mfBoxSeq, chosenBoxes, boxesUsed, startFrame)



	#Smooth once at end of track to eliminate missing boxes
	#print("original call to smooth")
	#for i in range(len(obsSeq)):
	#	print(i, obsSeq[i].astype(int))
	
	#split obsSeq into forward and backward tracks, add frames for context
	track, states, missing = smoothTrack(kf, startFrame, numFrames, obsSeq, confSeq, (frameWidth,frameHeight, origDetections, avgDetectionSize))
	#obsSeq2 = []
	#for i in range(len(obsSeq)): #len(oldTrack)
	#	f, box = oldTrack[i]
	#	obsSeq2.append(boxToKalmanObs(box))
	
	#print("second call to smooth")
	#for i in range(len(obsSeq2)):
	#	print(i, "old:", obsSeq[i].astype(int), "new: ", obsSeq2[i].astype(int))
		
	#track, missingX = smoothTrack(kf, startFrame, numFrames, obsSeq2, confSeq, (frameWidth,frameHeight, origDetections, avgDetectionSize))
	
	#obsSeq3 = []
	#for i in range(len(obsSeq)): #len(oldTrack)
	#	f, box = track[i]
	#	obsSeq3.append(boxToKalmanObs(box))
	
	#for i in range(len(obsSeq2)):
	#	print(i, "old:", obsSeq[i].astype(int), "new: ", obsSeq2[i].astype(int), "final", obsSeq3[i].astype(int))
	
	#missing = missing.union(colorBoxes)
	highConf = []
	for f in range(len(confSeq)):
		if confSeq[f] >= MIN_START_CONFIDENCE:  #TODO: Better to sum these up?
			highConf.append(f+1)

	return track, chosenBoxes, missing, highConf, confSeq, colProbSeq, pixelSeq, mfBoxSeq, states

def getTotalIOU(track, boxesInFrameDict, confSeq, allConfSeqs, trackIdx = None):
	#Inputs: track - Compare this track to another track
	totalIOU = 0
	totalBoxes = 0.0
	for (frame,boxT) in track:
		if confSeq[frame-1] == -3: #Don't count offscreen
			continue
		if confSeq[frame-1] != -2:
			totalBoxes += 1
			if frame in boxesInFrameDict:
				maxIOU = 0
				for i in range(len(boxesInFrameDict[frame])):
					if i != trackIdx:
						otherConfSeq = allConfSeqs[i]
						if otherConfSeq[frame-1] != 2 and otherConfSeq[frame-1] != 3:
							box = boxesInFrameDict[frame][i]
							tempIOU = bb_intersection_over_union(toCornerForm(box), toCornerForm(boxT))
							if tempIOU > maxIOU:
								maxIOU = tempIOU
				totalIOU += maxIOU
						#TODO Only count frames where neither confseq is -2 or -3
						#TODO only take max IOU for each frame
						#if boxOverlap(box, boxT):
						# if bb_intersection_over_union(toCornerForm(box), toCornerForm(boxT)) > .1:
						# overlaps.append(frame)

	return totalIOU, totalBoxes

# core function that determines start box, calls generateSingleTrack, then accepts or rejects returned track
def trackKPD(detections, numFrames, frameWidth, frameHeight, images, fullImages):
	allTracks = []
	allStates = []
	allConfSeqs = []
	allMFTracks = []
	boxesUsed = set([])
	boxesInFrameDict = {}
	avgDetectionSize = get_avg_detection_size(detections)
	trackNum = 0
	confAreaDict = {}

	if not ABLATE_INIT_LOOP:
		detectionsToChooseStartFrom = filterDetectionsSimple(detections, MIN_START_CONFIDENCE)
	else:
		detectionsToChooseStartFrom = 0

	frameArea = frameWidth * frameHeight
	confAreaDict['frameArea'] = frameArea
	maxConfidence = 1.0
	while maxConfidence > MIN_START_CONFIDENCE:
		maxConfidence = 0.0
		maxBox = None
		maxFrame = None

		if not ABLATE_INIT_LOOP:
			for f in range(len(detectionsToChooseStartFrom)):
				for (box, score) in detectionsToChooseStartFrom[f]:
					frame = f + 1  # FRAME IS ONE INDEXED
					if (frame, box) in boxesUsed:
						# print("previously seen box! ", f)
						continue
					# print("Box lookup", (frame,box), boxesUsed)

					percentBig = 1.5
					x, y, w, h = makeBiggerBox(box, frameWidth, frameHeight, percentBig, offScreenAllowed=True)
					percentOff, offScreen = percentOffScreen(x, y, w, h, frameWidth, frameHeight)
					if score > maxConfidence and percentOff <= 0:  # not offScreen: #percentOff> 0:
						# print('maxConfidence', maxConfidence)
						# print('score', score)
						# print('percentOff', percentOff)
						# print('offScreen', offScreen)
						maxConfidence = score
						maxBox = box
						maxFrame = frame
		else:
			for f in range(len(detections)):
				for (box, score) in detections[f]:
					frame = f + 1  # FRAME IS ONE INDEXED
					if (frame, box) in boxesUsed:
						# print("previously seen box! ", f)
						continue
					# print("Box lookup", (frame,box), boxesUsed)

					percentBig = 1.5
					x, y, w, h = makeBiggerBox(box, frameWidth, frameHeight, percentBig, offScreenAllowed=True)
					percentOff, offScreen = percentOffScreen(x, y, w, h, frameWidth, frameHeight)
					if score > maxConfidence and percentOff <= 0:  # not offScreen: #percentOff> 0:
						# print('maxConfidence', maxConfidence)
						# print('score', score)
						# print('percentOff', percentOff)
						# print('offScreen', offScreen)
						maxConfidence = score
						maxBox = box
						maxFrame = frame


		if maxConfidence > MIN_START_CONFIDENCE:
			# print("choosing box with confidence", maxConfidence)
			print("Starting generateSingleTrack function")
			(track, chosenBoxes, missing, highConf, confSeq, colProbSeq, pixelSeq, mfBoxSeq,
			 states) = generateSingleTrack(detections, avgDetectionSize, maxBox, maxConfidence, maxFrame, numFrames,
										   frameWidth, frameHeight, images, fullImages, boxesUsed)

			if track is None:
				# print("Skipping")
				boxesUsed = boxesUsed.union(chosenBoxes)
				continue
			# print("Final track #"+str(len(allTracks)+1), track)
			boxesUsed = boxesUsed.union(chosenBoxes)
			# also exclude overlapping boxes with final track
			overlaps = []

			if not ABLATE_INIT_LOOP:
				# break
				for (frame, boxT) in track:
					for (box, score) in detectionsToChooseStartFrom[frame - 1]:
						# if (frame, box) in boxesUsed:
						#	continue
						if boxOverlap(box, boxT):
							# if bb_intersection_over_union(toCornerForm(box), toCornerForm(boxT)) > .2:
							boxesUsed.add((frame, boxT))
							boxesUsed.add((frame, box))
			else:
				# break
				for (frame, boxT) in track:
					for (box, score) in detections[frame - 1]:
						# if (frame, box) in boxesUsed:
						#	continue
						if boxOverlap(box, boxT):
							# if bb_intersection_over_union(toCornerForm(box), toCornerForm(boxT)) > .2:
							boxesUsed.add((frame, boxT))
							boxesUsed.add((frame, box))




			#totalIOU, totalBoxes = getTotalIOU(track, boxesInFrameDict, confSeq, allConfSeqs) # 6.17.22 no uses in code

			badFrames = set(overlaps)
			badFrames = badFrames.union(missing)

			selfNonOverlap = 0
			"""
			lastBox = None
			for (frame,boxT) in track:
				if lastBox is not None and not boxOverlap(lastBox, boxT):
					selfNonOverlap += 1
				lastBox = boxT
			"""
			confSum = 0
			for f in range(len(confSeq)):
				if f + 1 in overlaps:
					continue
				if confSeq[f] > 0:  # -1 for colorboxes etc.
					confSum += confSeq[f]

			# print("confSum", confSum)
			# percentOffScreen(x, y, w, h, frameWidth, frameHeight)
			##TODO Compute average box area
			# print("frame" , maxFrame-1)
			x, y, w, h = maxBox
			startBoxArea = w * h
			startBoxAreaAsPercentOfFrame = startBoxArea / frameArea
			sumOfArea = 0
			boxCount = 1

			if not ABLATE_POST_TRIMMING:
				trimmedTrack = trim_track(track, confSeq, maxFrame, numFrames, frameWidth, frameHeight, trackNum)  # 6.20.22
			else:
				trimmedTrack = reformatTracks(track, maxFrame, numFrames, trackNum)  # added 6.20.22

			for boxAfterTrim in trimmedTrack:
				w = boxAfterTrim[3]
				h = boxAfterTrim[4]
				if w > 0:
					sumOfArea += w * h
					boxCount += 1

			avgArea = sumOfArea / boxCount
			avgAreaAsPercentOfFrame = avgArea / frameArea

			if ABLATE_NO_LONG_LARGE:
				startBoxAreaAsPercentOfFrame = 0
				avgAreaAsPercentOfFrame = 0
				sumOfArea = frameArea
				confSum = 0
				boxCount = 1


			if True:  # Who needs to filter?
				allTracks.append(track)
				allConfSeqs.append(confSeq)
				allMFTracks.append(mfBoxSeq)
				allStates.append(states)
				print('trackNum', trackNum, 'maxBox', maxBox, 'maxFrame', maxFrame)
				if 'avgArea' not in confAreaDict:
					confAreaDict['startBoxArea'] = [startBoxAreaAsPercentOfFrame]
					confAreaDict['conf'] = [maxConfidence]
					confAreaDict['index'] = [trackNum]
					confAreaDict['avgArea'] = [avgAreaAsPercentOfFrame]
					confAreaDict['totalArea'] = [sumOfArea / frameArea]
					confAreaDict['startFrame'] = [maxFrame]
					confAreaDict['confSum'] = [confSum]
					confAreaDict['boxCount'] = [boxCount]
					confAreaDict['confSeqs'] = [confSeq]
					confAreaDict['tracks'] = [track]
				else:
					confAreaDict['startBoxArea'].append(startBoxAreaAsPercentOfFrame)
					confAreaDict['conf'].append(maxConfidence)
					confAreaDict['index'].append(trackNum)
					confAreaDict['avgArea'].append(avgAreaAsPercentOfFrame)
					confAreaDict['totalArea'].append(sumOfArea / frameArea)
					confAreaDict['startFrame'].append(maxFrame)
					confAreaDict['confSum'].append(confSum)
					confAreaDict['boxCount'].append(boxCount)
					confAreaDict['confSeqs'].append(confSeq)
					confAreaDict['tracks'].append(track)
				# print("the track was accepted")
				# print(trackNum, 'confSeq', confSeq)
				# print(mfBoxSeq)
				# print('pixelSeq', pixelSeq)
				trackLength = len(track)
				for (f, b) in track:
					if f not in boxesInFrameDict:
						boxesInFrameDict[f] = [b]
					else:
						boxesInFrameDict[f].append(b)

				trackNum += 1
				"""
			if 'rejection' not in confAreaDict:
				confAreaDict['rejection'] = [rejected]
			else:
				confAreaDict['rejection'].append(rejected)
				"""
	# if len(allTracks) > 3:
	#	sys.exit(-1)
	# printProgressBar(progressCount, trackLength, 'Processing Track {}'.format(trackNum), 'Box {}/{}'.format(progressCount, len(track)))
	# jsonFileName = './jsons/confToAreaData(' + VID_ID + ').json'
	# with open(jsonFileName, 'w') as f:
	#	json.dump(confAreaDict, f)

	#print("Starting the function for startFrames list")
	startFrames = []
	for confSeq in allConfSeqs:
		maxConf = 0
		maxFrame = 0
		for f in range(len(confSeq)):
			if confSeq[f] > maxConf:
				maxFrame = f
		startFrames.append(maxFrame)


	if not ABLATE_NO_LONG_LARGE:
		sampleConfThresh = 0.8

		listOfTotalAreas = np.array(confAreaDict['totalArea'])
		startConfList = confAreaDict['conf']
		globalTotalAreaMean = np.mean(listOfTotalAreas)
		sampleAreas = []
		for i in range(len(listOfTotalAreas)):
			if listOfTotalAreas[i] > globalTotalAreaMean and startConfList[i] > sampleConfThresh:
				sampleAreas.append(listOfTotalAreas[i])

		sampleAreas = np.array(sampleAreas)
		sampleMean = np.mean(sampleAreas)
		#print('GLOBAL MEAN:', globalTotalAreaMean)
		#print('ALL AREAS:', listOfTotalAreas)
		#print('SAMPLE AREAS:', sampleAreas)
		#print('SAMPLE MEAN:', sampleMean)

		trackGoodnessFlags = []
		if len(sampleAreas) > 1:
			sampleStd = np.std(sampleAreas)
			summedAreaThresh = norm.ppf(0.975, sampleMean, sampleStd)
			#print('ppf(0.975):', summedAreaThresh)
			for i in range(len(allTracks)):
				goodTrack = True
				summedBoxArea = listOfTotalAreas[i]
				startConf = startConfList[i]
				#print(startConf, summedBoxArea)
				if summedBoxArea > summedAreaThresh and startConf < sampleConfThresh:
					goodTrack = False
					#print("BAD TRACK:", i)
				trackGoodnessFlags.append(goodTrack)
		else:
			for i in range(len(listOfTotalAreas)):
				if listOfTotalAreas[i] > sampleMean:
					trackGoodnessFlags.append(False)
				else:
					trackGoodnessFlags.append(True)

		#print(trackGoodnessFlags)
	else:
		trackGoodnessFlags = []
		for i in range(len(allTracks)):
			trackGoodnessFlags.append(True)

	#print(confAreaDict['conf'])
	#print(confAreaDict['index'])

	print("Reached the end of trackKPD function")

	return allTracks, allStates, allConfSeqs, allMFTracks, boxesInFrameDict, startFrames, trackGoodnessFlags


def load_frames(numFrames, frameWidth, frameHeight, imgPath):
	#fgbg = cv2.createBackgroundSubtractorMOG2()

	if SCALE_MEDFLOW:
		scale = 300/max(frameWidth, frameHeight)

	frames = []
	fullSizeFrames = []
	for count in range(numFrames):
		imgNum = str(count+1).zfill(5)
		filename = "../."+imgPath + "img" + str(imgNum) + ".jpg"

		#print(filename)
		#!!!****cv2 reads as BGR****!!!
		img = cv2.imread(filename)

		if SCALE_MEDFLOW:
			img = cv2.resize(img, (0, 0), fx=scale, fy=scale)
		#fgmask = fgbg.apply(img)
		#plt.imshow(fgmask)
		#plt.show()
		fullSizeFrames.append(img)


		frames.append(img)


	return frames, fullSizeFrames

#find where the list of motion frames ends when starting from front and back of track
# also return center coordinates of the box at that point
def getIndexAndCenterPx(track, confSeq):
	missingIndexForward = 0
	index = 0

	#increment from beginning of track while on motion
	while confSeq[index] <= -2 and missingIndexForward < len(confSeq)-1:
		missingIndexForward  = index
		index +=1

	missingIndexForward += 1 # get index of non missing box
	#get center coordinates of box at index
	(frame, box) = track[missingIndexForward]
	x, y, w, h = box
	boxCenterForward = (int(y+ h/2), int(x + w/2))

	#increment from back of track while on motion
	missingIndexBackward = len(track) -1
	index = len(confSeq)-1

	while confSeq[index] <= -2 and missingIndexBackward > 0:
		missingIndexBackward = index
		index -=1

	missingIndexBackward -= 1 # get index of non missing box
	#get center coordinates of box at index
	(frame, box) = track[missingIndexBackward]
	x, y, w, h = box
	boxCenterBackward = (int(y+ h/2), int(x + w/2))

	return missingIndexForward, boxCenterForward, missingIndexBackward, boxCenterBackward

#detrmine how many boxes overlap in the non-missing frames shared by both tracks
def overlappingDetections(track1, t1IndexBackward, track2, t2IndexForward, confSeq1, confSeq2, fw, fh):
	index = t2IndexForward
	countOverlap = 0
	offscreen = False
	while index <= t1IndexBackward:
		if confSeq1[index] == -3 or confSeq2[index] == -3: #if offscreen is being considered, do not use combination
			offscreen = True
			break
		f, box1 = track1[index]
		f, box2 = track2[index]

		#IOU used here instead of overlap due to cars overlapping for majority of their tracks
		if bb_intersection_over_union(toCornerForm(box1), toCornerForm(box2)) > .3:
			countOverlap += 1
		index += 1


	return countOverlap, offscreen

#helper function for debugging
#counts how many tracks before an index are none
def countNones(tracks, trackIndex):
	index = 0
	numNone = 0
	while index < trackIndex:
		if tracks[index] == None:
			numNone += 1
		index += 1
	return numNone

#if the space in between two tracks is motion, try replacing with first track's medflow values (if available)
def replaceMotionWithMF(track, indexBack, indexFor, confSeq, mfBoxSeq):
	index = indexBack + 1
	while index < indexFor-1:
		valid, box = mfBoxSeq[index]
		if confSeq[index] != -2:
			break
		if box is not None:
			track[index] = (index+1, box)
			confSeq[index] = -4  #will want to change this to -1, right now -4 to check if it's happening
		index += 1
	return track, confSeq

'''
def createTrackerWithHistory2(imageList, startBox, images):
	tracker = None
	boxes = []
	for i in range(len(imageList)):
		if (not ABLATE_NO_MEDFLOW_SWITCH) or (not ABLATE_NO_MEDFLOW_REPLACE):
			if tracker is None:
				tracker = cv2.TrackerMedianFlow_create()
				tracker.init(images[imageList[i]], startBox)
				boxes.append(startBox)
			else:
				(ok, bbox) = tracker.update(images[imageList[i]])
				if ok:
					# if not boxOverlap(bbox, boxes[-1]):
						# tracker = None
						# startBox = boxes[-1]
						# boxes.append(None)
					# else:
					boxes.append(bbox)
				else:
					tracker = None
					startBox = boxes[-1]
					boxes.append(None)
	return tracker, boxes
'''

def findStartFrame(confSeq):
	maxConf = None
	maxIndex = None
	for i in range(len(confSeq)):
		if maxConf is None or confSeq[i] > maxConf:
			maxConf = confSeq[i]
			maxIndex = i
	return maxIndex+1 #Off by one!

'''
#generates a median flow tracker with the first box starting just below the provided box
#TODO: generate two boxes to use
def generateMFBoxForVelocity(fw, fh, startBox, imageIndex, images): #, vertical):
	mfBoxes = []

	sX, sY, sW, sH = startBox
	boxWidth = sW
	boxHeight = sH

	# if vertical:
		#need to account for out of frame
	if sY+sH+boxHeight > fh:
		mfY = sY - boxHeight
	else:
		mfY = sY + sH
	# else:
		# if sX+sW+boxWidth > fw:
			# mfX = sX - boxWidth
		# else:
			# mfX = sX + sX

	mfX = sX
	mfH = boxHeight
	mfW = boxWidth
	#generate box just outside startbox
	mfBox = (mfX, mfY, mfW, mfH)

	#get mf boxes
	tracker, boxes = createTrackerWithHistory2(imageIndex, mfBox, images)
	# tracker = cv2.TrackerMedianFlow_create()
	# tracker.init(images[imageIndex], mfBox)


	#return list
	return tracker, boxes
'''

#use boxes to determine velocity
def velocityCalc(newBoxes, curMFBox, prevMFBox, x, y, w, h, prevMFVX, prevMFVY, index, atEnd, forcedZero):
	ok = True
	if atEnd:
		prev = index -1
	else:
		prev = index + 1
	#ox, oy, ow, oh = newBoxes[prev]
	#cx = int(ox+ ow/2)
	#cy = int(oy + oh/2)

	if prevMFBox is not None:
		mfX, mfY, mfW, mfH =  prevMFBox
		cmfX = int(mfX+ mfW/2)
		cmfY = int(mfY + mfH/2)
	else:
		ok = False

	#curBox center px
	#nx, ny, nw, nh = newBoxes[index]
	#ncx = int(nx+ nw/2)
	#ncy = int(ny + nh/2)

	if curMFBox is not None:
		nmfX, nmfY, nmfW, nmfH = curMFBox
		ncmfX = int(nmfX+ nmfW/2)
		ncmfY = int(nmfY + nmfH/2)
	else:
		ok = False

	oVX, oVY = getVelocityComponents(newBoxes[prev],newBoxes[index])
	#velocities
	#oVX = ncx - cx
	#oVY = ncy - cy
	#print("new smoothed velocity at", index, oVX, oVY)

	if ok:
		mfVX = ncmfX - cmfX
		mfVY = ncmfY - cmfY
		if forcedZero:
			mfVX = prevMFVX
			mfVY = prevMFVY
	else:
		mfVX = prevMFVX
		mfVY = prevMFVY


	#print("mf velocity at", index, mfVX, mfVY)

	#compute new box
	x = x + oVX + mfVX
	y = y + oVY + mfVY
	#TODO incorporate helper function to compute velocity
	#TODO Soon: why are the velocities be addeds

	return x, y, w, h, mfVX, mfVY

#boxA is earlier box
#boxB is later box
def getVelocityComponents(boxA, boxB):
	Ax, Ay, Aw, Ah = boxA
	Bx, By, Bw, Bh = boxB

	Axc = (Ax + (Aw/2))
	Ayc = (Ay + (Ah/2))
	Bxc = (Bx + (Bw/2))
	Byc = (By + (Bh/2))

	Vx = Bxc - Axc
	Vy = Byc - Ayc

	return Vx, Vy

#resmoothes track
def resmoothTrack(oldTrack, oldStates, confSeq, forwardIndex, backwardIndex, images, numFrames, detections, avgDetectionSize,fw, fh, numJoins):
	obsSeq = []
	startFrame = None
	startBox = None
	maxConf = None
	for i in range(len(oldTrack)):
		if confSeq[i] == -2:
			obsSeq.append(boxToKalmanObs(None))
			continue # no need to update max
		else:
			f, box = oldTrack[i]
			obsSeq.append(boxToKalmanObs(box))

		if maxConf is None or confSeq[i] > maxConf:
			maxConf = confSeq[i]
			x, y, vx, vy, w, h = obsSeq[i]
			startBox = (x,y,w,h)
			startFrame = i+1

	#smooth
	if numJoins > 1:
		#print("calling smooth on a track with numJoins=", numJoins)
		kf = setup_kf(fw,fh, detections, avgDetectionSize, startBox)
		track, states, missing = smoothTrack(kf, startFrame, numFrames, obsSeq, confSeq, (fw,fh, detections, avgDetectionSize))
	else:
		track, states = oldTrack, oldStates
	return track, confSeq, startFrame, states



#Uses kalman filter to determine if tracks should be combined
def evaluatePartialTracksWithKF(track1, track2, index, index2, detections, avgDetectionSize, kalmanObsArr, fw, fh, frameDiff, distDiff, dummyKalmanObs):
	missing = False
	#starting at beginning of before track and use kalman filter to generate velocity between boxes, looking for max velocity
	f1, initBox = track1[0]
	kf = setup_kf(fw,fh, detections, avgDetectionSize, initBox)
	initList = np.zeros((1, NUM_OBS))
	initList[0] = boxToKalmanObs(initBox)

	(initialStateMeans, initialStateCovariances)= filterWithSingleObs(kf, initList)
	stateMean, stateCovariance =(initialStateMeans[0].copy(), initialStateCovariances[0].copy())

	#update on boxes till index
	maxVel1 = None
	while f1-1 <= index:
		f1, box = track1[f1]
		stateMean, stateCovariance = kf.filter_update(stateMean, stateCovariance, boxToKalmanObs(box))
		sx, sy, svx, svy, sw, sh = stateMean
		velocity = math.sqrt(svx**2 + svy**2)
		if maxVel1 is None or velocity > maxVel1:
			maxVel1 = velocity

	# do missing boxes until next track starts detections
	f1 += 1
	nextFilteredStateMean, nextFilteredStateCovariance = kf.filter_update(stateMean, stateCovariance, getMissingVector())
	while f1-1 <= index2:
		nextFilteredStateMean, nextFilteredStateCovariance = kf.filter_update(nextFilteredStateMean, nextFilteredStateCovariance, getMissingVector())
		f1 += 1

	#starting at end of after track and use kalman filter to generate velocity between boxes, looking for max velocity
	backTrack = track2[index2: len(track2)]
	backTrack.reverse()
	f2, initBox2 = backTrack[0]
	kf2 = setup_kf(fw,fh, detections, avgDetectionSize, initBox2)
	initList2 = np.zeros((1, NUM_OBS))
	initList2[0] = boxToKalmanObs(initBox2)

	(initialStateMeans2, initialStateCovariances2)= filterWithSingleObs(kf2, initList2)#special function we wrote to predict from single observation
	stateMean2, stateCovariance2 =(initialStateMeans2[0].copy(), initialStateCovariances2[0].copy())

	#update on boxes till index
	maxVel2 = None
	i = 0
	while i < len(backTrack):
		f2, box2 = backTrack[i]
		stateMean2, stateCovariance2 = kf.filter_update(stateMean2, stateCovariance2, boxToKalmanObs(box2))
		sx2, sy2, svx2, svy2, sw2, sh2 = stateMean2
		velocity2 = math.sqrt(svx2**2 + svy2**2)
		if maxVel2 is None or velocity2 > maxVel2:
			maxVel2 = velocity2
		i += 1

	# find max of two velocities
	velocity = max(maxVel1, maxVel2)
	#print("vel 1", maxVel1, "vel2", maxVel2, "dist", distDiff*0.8, distDiff*1.2, "vel*time", velocity*frameDiff)


	if frameDiff == 0:  # if the frames end at same point, check overlap
		f, box1 = track1[index]
		f, box2 = track2[index2]
		if not boxOverlap(makeBiggerBox(box1, fw, fh, 1.5), makeBiggerBox(box2, fw, fh, 1.5)):
			missing = True
			#print("frameDiff is 0, boxes do not overlap")
	elif velocity*frameDiff < distDiff: # else, check that distance possible is greater than distance required
		missing = True
		#print("fails velocity check", velocity, frameDiff, distDiff)


	#Setting up information needed for getObsProbKF
	predObsInfo = getPredictedObsInfo(kf, nextFilteredStateMean, nextFilteredStateCovariance, dummyKalmanObs)
	f, nextBox = track2[index2]
	kfProb = getObsProbKF(predObsInfo, formatBoxToKalmanObsArray(nextBox, kalmanObsArr))

	lastStateObsInfo = getPredictedObsInfo(kf, stateMean, stateCovariance, dummyKalmanObs)

	#Do second check missing check
	lastProb = getObsProbKF(lastStateObsInfo, formatBoxToKalmanObsArray(nextBox, kalmanObsArr))
	if lastProb > kfProb:
		missing = True
		#print("last", lastProb,"new", kfProb)

	return missing

#go through all tracks and determine if they are partial tracks that can be combined into longer tracks
#conditions: close in time (20 frames, unless overlapping detections, distance (is it reasonable according to KF?), does KF say better probability
def postProcessCombinePartialTracks(allTracks, allStates, allConfSeqs, allMFTracks, detections, numFrames, images, fw, fh, trackGoodnessFlags):
	newTracks = []
	newConfSeqs = []
	maxTime = 20
	combined = True
	trackCombos = {}
	avgDetectionSize = get_avg_detection_size(detections)
	minDist = 30 #TODO: scale to image size? to avg detection size?

	kalmanObsArr = np.array([[0.0, 0.0, 0.0, 0.0, 0.0, 0.0]])#2D ARRAY
	dummyBox = (0,0,1,1)
	dummyKalmanObs = formatBoxToKalmanObsArray(dummyBox, kalmanObsArr)

	for track in range(len(allTracks)):
		trackCombos[track] = [track] # track combos is lists of the combined tracks

	#Save dict track num -> startConf, box area, rejection
	while combined == True: #until no more combinations
		combined = False
		#for each track
		for base in range(len(allTracks)):
			if allTracks[base] is None:
				continue
			#get index and center points of boxes from end of missing streaks in both directions
			baseIndexForward, baseCenterForward, baseIndexBackward, baseCenterBackward = getIndexAndCenterPx(allTracks[base], allConfSeqs[base])
			
			#compare track to each other track
			for compare in range(base, len(allTracks)): # should make it quicker
				if base == compare or allTracks[compare] is None: #don't compare same tracks or missing tracks
					continue
				compareIndexForward, compareCenterForward, compareIndexBackward, compareCenterBackward = getIndexAndCenterPx(allTracks[compare], allConfSeqs[compare])

				#TODO: move calculations for time and dist to new func?
				#compBase
				#Time eval

				#if indices extend pass one another, compute difference in frames
				if compareIndexBackward <= baseIndexForward:
					compBaseOverlap = 0
					compBaseTimeDiff = baseIndexForward - compareIndexBackward
					compBaseDistAllowed = minDist*(abs(compBaseTimeDiff)+1)
					compBaseOverlap, offscreen = overlappingDetections(allTracks[base], baseIndexForward, allTracks[compare], compareIndexBackward, allConfSeqs[base], allConfSeqs[compare], fw, fh)
				# otherwise, check that there are less than 2 frames that do not overlap on the tracks, then compute
				else:
					compBaseOverlap, offscreen = overlappingDetections(allTracks[compare], compareIndexBackward, allTracks[base], baseIndexForward, allConfSeqs[compare], allConfSeqs[base], fw, fh)
					compBaseTimeDiff = (compareIndexBackward - baseIndexForward) - compBaseOverlap
					compBaseDistAllowed = minDist*(abs(compBaseTimeDiff)+1)
					if compBaseTimeDiff > 2: #are there more than two non overlapping?
						compBaseTimeDiff = None
					else:
						compBaseTimeDiff = 0 #don't care about how many frames if overlapping

				# if the region between contains offscreen frames, do not consider
				if offscreen:
					compBaseTimeDiff = None

				#dist eval
				#if there are overlapping frames, then the distance between the fish is 0
				if compBaseOverlap > 0:
					compBaseAtBaseForDistDiff = 0
				else:
					baseForY, baseForX = baseCenterForward
					f, mfBoxCompAtBaseFor = allTracks[compare][baseIndexForward] #use detection if possible, if not, use medflow
					if mfBoxCompAtBaseFor is None: # allConfSeqs[compare][baseIndexForward] == -2: #!!!Change to if confSeq is -2
						valid, mfBoxCompAtBaseFor = allMFTracks[compare][baseIndexForward] # try medflow
					if mfBoxCompAtBaseFor is not None:
						x, y, w, h = mfBoxCompAtBaseFor
						compForY = int(y+ h/2)
						compForX = int(x + w/2)
						compBaseAtBaseForDistDiff = math.sqrt((baseForY - compForY)**2 + (baseForX - compForX)**2)
					else: # if no available boxes to compare, do not consider
						compBaseAtBaseForDistDiff = None

				#baseComp
				#Time eval
				#if indices extend pass one another, compute difference in frames
				if baseIndexBackward <= compareIndexForward:
					baseCompOverlap = 0
					baseCompTimeDiff = compareIndexForward - baseIndexBackward
					baseCompDistAllowed = minDist*(abs(baseCompTimeDiff)+1)
					baseCompOverlap, offscreen = overlappingDetections( allTracks[compare], compareIndexForward, allTracks[base], baseIndexBackward, allConfSeqs[compare], allConfSeqs[base], fw, fh)
				# otherwise, check that there are less than 2 frames that do not overlap on the tracks, then compute
				else:
					baseCompOverlap, offscreen = overlappingDetections(allTracks[base], baseIndexBackward, allTracks[compare], compareIndexForward, allConfSeqs[base], allConfSeqs[compare], fw, fh)
					baseCompTimeDiff = (baseIndexBackward - compareIndexForward) - baseCompOverlap
					baseCompDistAllowed = minDist*(abs(baseCompTimeDiff)+1)
					if  baseCompTimeDiff >2: #are there more than two non overlapping?
						baseCompTimeDiff = None
					else:
						baseCompTimeDiff = 0
				# if the region between contains offscreen frames, do not consider
				if offscreen:
					baseCompTimeDiff = None

				#dist eval
				#if there are overlapping frames, then the distance between the fish is 0
				if baseCompOverlap > 0:
					baseCompAtCompForDistDiff = 0
				else:
					compForY, compForX = compareCenterForward
					f, mfBoxBaseAtCompFor = allTracks[base][compareIndexForward]  #use detection if possible, if not, use medflow
					if mfBoxBaseAtCompFor is None: #allConfSeqs[base][compareIndexForward] == -2: #!!!Change to if confSeq is -2
						valid, mfBoxBaseAtCompFor = allMFTracks[base][compareIndexForward] # try medflow
					if mfBoxBaseAtCompFor is not None:
						x, y, w, h = mfBoxBaseAtCompFor
						baseForY = int(y+ h/2)
						baseForX = int(x + w/2)
						baseCompAtCompForDistDiff = math.sqrt((compForY - baseForY)**2 + (compForX - baseForX)**2)
					else: # if no available boxes to compare, do not consider
						baseCompAtCompForDistDiff = None

				#print("\nbase", base-countNones(allTracks, base), trackCombos[base], "compare", compare-countNones(allTracks, compare), trackCombos[compare])
				#print("compBaseTime ", compBaseTimeDiff , compBaseOverlap," indexFor", baseIndexForward," indexBack ", compareIndexBackward," compBaseDist", compBaseAtBaseForDistDiff)
				#print("baseCompTime", baseCompTimeDiff, baseCompOverlap, " indexFor", compareIndexForward," indexBack", baseIndexBackward, " baseCompDist",  baseCompAtCompForDistDiff)


				#print("compBase")
				if compBaseOverlap == 0 and compBaseAtBaseForDistDiff> 0 and compBaseTimeDiff is not None:
					compBaseMissing = evaluatePartialTracksWithKF(allTracks[compare], allTracks[base], compareIndexBackward, baseIndexForward, detections, avgDetectionSize, kalmanObsArr, fw, fh, compBaseTimeDiff, compBaseAtBaseForDistDiff, dummyKalmanObs)
				else:
					compBaseMissing = False



				if baseCompOverlap == 0 and baseCompAtCompForDistDiff > 0 and baseCompTimeDiff is not None:
					baseCompMissing = evaluatePartialTracksWithKF(allTracks[base], allTracks[compare], baseIndexBackward, compareIndexForward, detections, avgDetectionSize, kalmanObsArr, fw, fh, baseCompTimeDiff, baseCompAtCompForDistDiff, dummyKalmanObs)
				else:
					baseCompMissing = False

				#print("compBaseMissing", compBaseMissing, "baseCompMissing", baseCompMissing)

				#evaluate
				#if (compBaseTimeDiff is not None) and (compBaseAtBaseForDistDiff is not None) and (compBaseTimeDiff <= maxTime) and compBaseAtBaseForDistDiff < compBaseDistAllowed:
					#print("c", compare, allConfSeqs[compare])
					#print("b", base, allConfSeqs[base])
				oneGoodTrack = trackGoodnessFlags[base] or trackGoodnessFlags[compare] #TRY: AND
				if not compBaseMissing and compBaseTimeDiff is not None and compBaseTimeDiff <= maxTime: #(compBaseTimeDiff is not None) and (compBaseAtBaseForDistDiff is not None) and (compBaseTimeDiff <= maxTime) and compBaseAtBaseForDistDiff < compBaseDistAllowed:
					#print("c", compare, allConfSeqs[compare])
					#print("b", base, allConfSeqs[base])
					#combine tracks
					print("combining tracks:", base,"and",compare)
					newTrack = allTracks[compare][0:compareIndexBackward+1] + allTracks[base][compareIndexBackward+1:len(allTracks[base])]
					newConfSeq = allConfSeqs[compare][0:compareIndexBackward+1] + allConfSeqs[base][compareIndexBackward+1:len(allTracks[base])]
					newMFBoxSeq = allMFTracks[compare][0:compareIndexBackward+1] + allMFTracks[base][compareIndexBackward+1:len(allTracks[base])]

					#newTrack, newConfSeq = determineVelocityWithKFAndMF(newTrack, newConfSeq, compareIndexForward, baseIndexBackward, images, numFrames, detections, avgDetectionSize, fw, fh)

					#print("a", base, newConfSeq)
					#adjust lists
					allTracks[base] = newTrack
					allTracks[compare] = None
					allConfSeqs[base] = newConfSeq
					allMFTracks[base] = newMFBoxSeq
					allMFTracks[compare] = None
					
					#States no longer valid after combine
					allStates[base] = None 
					allStates[compare] = None

					trackCombos[base] = trackCombos[compare] + trackCombos[base]
					trackCombos[compare] = []
					trackGoodnessFlags[base] = oneGoodTrack
					trackGoodnessFlags[compare] = None

					#have to recompute base values
					baseIndexForward, baseCenterForward, baseIndexBackward, baseCenterBackward = getIndexAndCenterPx(allTracks[base], allConfSeqs[base])
					combined = True

				#elif (baseCompTimeDiff is not None) and (baseCompAtCompForDistDiff is not None) and (baseCompTimeDiff <= maxTime) and baseCompAtCompForDistDiff < baseCompDistAllowed:
					#print("b", base, allConfSeqs[base])
					#print("c", compare, allConfSeqs[compare])


				elif not baseCompMissing and baseCompTimeDiff is not None and baseCompTimeDiff <= maxTime: #(baseCompTimeDiff is not None) and (baseCompAtCompForDistDiff is not None) and (baseCompTimeDiff <= maxTime) and baseCompAtCompForDistDiff < baseCompDistAllowed:
					#print("b", base, allConfSeqs[base])
					#print("c", compare, allConfSeqs[compare])
					#combine tracks

					print("combining tracks:", base,"and",compare)
					newTrack = allTracks[base][0:baseIndexBackward+1] + allTracks[compare][baseIndexBackward+1:len(allTracks[compare])]
					newConfSeq = allConfSeqs[base][0:baseIndexBackward+1] + allConfSeqs[compare][baseIndexBackward+1:len(allConfSeqs[compare])]
					newMFBoxSeq = allMFTracks[base][0:baseIndexBackward+1] + allMFTracks[compare][baseIndexBackward+1:len(allConfSeqs[compare])]

					#newTrack, newConfSeq = determineVelocityWithKFAndMF(newTrack, newConfSeq, baseIndexForward, compareIndexBackward, images, numFrames, detections, avgDetectionSize, fw, fh)

					#print("a", base, newConfSeq)
					#adjust lists
					allTracks[base] = newTrack
					allTracks[compare] = None
					allConfSeqs[base] = newConfSeq
					allMFTracks[base] = newMFBoxSeq
					allMFTracks[compare] = None

					trackCombos[base] = trackCombos[base] + trackCombos[compare]
					trackCombos[compare] = []
					trackGoodnessFlags[base] = oneGoodTrack
					trackGoodnessFlags[compare] = None
					#have to recompute values
					baseIndexForward, baseCenterForward, baseIndexBackward, baseCenterBackward = getIndexAndCenterPx(allTracks[base], allConfSeqs[base])
					combined = True
	#smooth new tracks
	avgDetectionSize = get_avg_detection_size(detections)
	startFrames = []
	newFlags = []
	for i in range(len(allTracks)):
		if allTracks[i] is not None:
			indexForward, centerForward, indexBackward, centerBackward = getIndexAndCenterPx(allTracks[i], allConfSeqs[i])
			if True:#len(trackCombos[i]) > 1:
				newTrack, newConfSeq, startFrame, newStates = resmoothTrack(allTracks[i], allStates[i],allConfSeqs[i], indexForward, indexBackward, images, numFrames, detections, avgDetectionSize, fw, fh, len(trackCombos[i]))
				#print("after kf and mf, start box:", track[startFrame-1])
			#else:
			#	newTrack, newConfSeq, startFrame = allTracks[i], allConfSeqs[i], findStartFrame(allConfSeqs[i])

			###transform newTrack here
			if not ABLATE_TRIM_LATE and not ABLATE_ACCEL_OFFSCREEN:
				newTrack = accelerateOffscreen(newTrack, newConfSeq, newStates)
			newFlags.append(trackGoodnessFlags[i])
			newTracks.append(newTrack)
			newConfSeqs.append(newConfSeq)
			startFrames.append(startFrame)
			#print(len(newTracks)-1,"final confSeq", newConfSeq)


	return newTracks, newConfSeqs, startFrames, newFlags

def applyVelocity(box, velocity):
	#this will not work if we don't assume the box dimensions stay the same
	Vx, Vy = velocity
	x,y,w,h = box
	x = x + Vx
	y = y + Vy
	newBox = x,y,w,h
	return newBox

def getSignOfComponent(velocityComponent):
	if velocityComponent < 0:
		return -1
	else:
		return 1

def accelerateOffscreen(track, confSeq, states):
	#NOTE: 'track' is a list of tuples (frameNum[1-indexed], box)

	index = 0
	#find first frame before non -3
	while confSeq[index] == -3:
		index+=1
	firstGoodFrame = index

	#find first frame after non -3
	while confSeq[index] !=-3:#we may reach end of video(clip ends before track exits screen)
		index+=1
		if index == len(confSeq):
			break
	lastGoodFrame = index-1

	#accelerate offscreen forward
	#velocityBackward = getVelocityComponents(track[firstGoodFrame+1][1],track[firstGoodFrame][1])
	x, y, vBackX, vBackY, w, h = states[firstGoodFrame]
	accelerationX = 0.05*(vBackX) #constant acceleration
	accelerationY = 0.05*(vBackY)
	velocityBackward = (1.1*vBackX, 1.1*vBackY)
	backIndex = firstGoodFrame
	while backIndex > 0:
		#print(backIndex, track[backIndex])
		track[backIndex-1] = backIndex, applyVelocity(track[backIndex][1], velocityBackward)
		Vx, Vy = velocityBackward
		velocityBackward = (Vx + accelerationX), (Vy + accelerationY) #compute new velocity given acceleration
		backIndex -= 1

	x, y, vForX, vForY, w, h = states[lastGoodFrame]
	#velocityForward = getVelocityComponents(track[lastGoodFrame-1][1], track[lastGoodFrame][1])
	accelerationX = 0.05*vForX#(velocityForward[0]) #constant acceleration
	accelerationY = 0.05*vForY#(velocityForward[1]) #constant acceleration
	velocityForward = (1.1*vForX, 1.1*vForY)
	forwardIndex = lastGoodFrame
	while forwardIndex < len(track)-1:
		#print(forwardIndex, track[forwardIndex])
		track[forwardIndex+1] =  forwardIndex+2, applyVelocity(track[forwardIndex][1], velocityForward)
		Vx, Vy = velocityForward
		velocityForward = (Vx + accelerationX), (Vy + accelerationY) #compute new velocity given acceleration
		forwardIndex += 1

	return track

def taishiCheck(box, frameWidth, frameHeight, frameNum):

	"""
	Inputs:	Bounding box, frame dimensions, frame number, track label number
	Returns: box on screen x, box on screen y, one percent of frame in x and y
	"""
	global IGR
	(x1, y1, w,h) = box
	xRightOnScreen = x1+w
	xLeftOnScreen = frameWidth - x1
	yTopOnScreen = y1+h
	yBottomOnScreen = frameHeight - y1
	xOnScreen = min([xRightOnScreen, xLeftOnScreen, w]) # x value indicates part of a box on screen. (larger min value indicates that the box may not be cut off)
	yOnScreen = min([yTopOnScreen, yBottomOnScreen, h])
	xOnePercent = frameWidth * 0.01 # 1% of x-axis screen
	yOnePercent = frameHeight * 0.01

	if IGR is not None:
		for region in IGR:
			igrPercentAreaOverlap, igrXOverlap, igrYOverlap  = igrOverlap(box,region)
			if w - igrXOverlap < xOnScreen:
				xOnScreen = w - igrXOverlap
				#print('frame {}, track {}'.format(frameNum, trackNum))
				#print("igrPercentAreaOverlap: {}, igrXOverlap: {}, igrYOverlap: {}".format(igrPercentAreaOverlap, igrXOverlap, igrYOverlap))
				#print('xOnScreen', xOnScreen, 'xOnePercent', xOnePercent)
			if h - igrYOverlap < yOnScreen:
				yOnScreen = h - igrYOverlap
				#print('frame {}, track {}'.format(frameNum, trackNum))
				#print("igrPercentAreaOverlap: {}, igrXOverlap: {}, igrYOverlap: {}".format(igrPercentAreaOverlap, igrXOverlap, igrYOverlap))
				#print('yOnScreen', xOnScreen, 'yOnePercent', yOnePercent)
			#smRegion = makeBiggerBox(region, frameWidth, frameHeight, 0.7)
			#if boxOverlap(box, smRegion):
				#boxTouchingIGR = True
				#break

	return xOnScreen, xOnePercent, yOnScreen, yOnePercent#, boxTouchingIGR

def countTrimEdge(confSeq, start, incr, minimumTailMotionFrames=5):
	"""
	Inputs: Confidence sequence of track, startframe, forward or backward increment
	Returns: number of boxes at end of track which relied on color tracking
	"""

	idx = start
	conf = confSeq[idx]
	motionCount = 0 #count -2s
	trimCount = 0 #count total frames to trim
	#-2 means motion
	#-3 means off screen
	while conf == -2 or conf == -3:
		idx += incr
		if conf == -2:
			motionCount += 1
		conf = confSeq[idx]
		trimCount += 1

	#motionCount -= minimumTailMotionFrames
	if motionCount < minimumTailMotionFrames:
		trimCount = 0

	return trimCount

def trimEdge(oldTrack, confSeq, start, incr=1):
	trimLength = countTrimEdge(confSeq, start, incr)
	if trimLength == 0:
		return oldTrack
	if incr < 0: #Slice end off
		newTrack = oldTrack[:-trimLength]
		#print("Trimmed end:", trimLength)
	else: #Slice beginning off
		newTrack = oldTrack[trimLength:]
		#print("Trimmed beginning:", trimLength)
	f = start
	trackIdx = oldTrack[0][-1]
	while len(newTrack) < len(oldTrack):
		if incr < 0: #Build forward
			newTrack.append([float(0), float(0), float(0), float(0), float(f+1), float(trackIdx)])
		else: #Build backward
			newTrack.insert(0,[float(0), float(0), float(0), float(0), float(f+1), float(trackIdx)])
		f += incr

	return newTrack

def postProcessRemoveRedundantTracks(tracks, confSeqs, startFrames, boxesInFrameDict):
	#boxesInFrameDict is one-indexed
	newTracks = []
	newConfSeqs = []
	deletedIndices = []

	for i in range(len(tracks)-2,-1,-1): #iterate backwards
		#print("Post processing Track", i)
		track = tracks[i]
		totalIOU, totalBoxes = getTotalIOU(track, boxesInFrameDict, confSeqs[i], confSeqs, i)
		#print("totalIOU", totalIOU)
		#print("totalBoxes", totalBoxes)
		if totalIOU/totalBoxes > .2:
			print('found redundant track:', i)
			del tracks[i]
			del confSeqs[i]
			del startFrames[i]
			for f in range(1,len(boxesInFrameDict)+1):
				del boxesInFrameDict[f][i]

	return tracks, confSeqs, startFrames

	"""
		trackIdx = 0 #This is the index of the track we are IOU checking (checking to delete)
		for oldTrack in tracks[:]:
			totalIOU, totalBoxes = getTotalIOU(oldTrack, boxesInFrameDict, allConfSeqs[trackNum], trackIdx)
			if totalIOU/totalBoxes > .2:
				print("Found an old track that overlaps the newly added track")
				del allTracks[trackIdx]
				del allConfSeqs[trackIdx]
				del allMFTracks[trackIdx]
				for f in range(len(boxesInFrameDict)):
					frame = f+1
					del boxesInFrameDict[frame][trackIdx]
				trackNum -=1 #Total number of tracks
			else:
				trackIdx += 1 #This is the index of the track we are IOU checking (checking to delete)
	"""

def track_list_to_dict(tracks):
	boxesInFrameDict = {}
	for track in tracks:
		for frame, box in track: #iterate backwards
			if frame not in boxesInFrameDict:
				boxesInFrameDict[frame] = [box]
			else:
				boxesInFrameDict[frame].append(box)
	return boxesInFrameDict

def post_process_drop_long_large_tracks(tracks, confSeqs, startFrames, trackGoodnessFlags, fw, fh):

	newTracks = []
	newConfSeqs = []
	newStartFrames = []
	for i in range(len(tracks)):
		if trackGoodnessFlags[i]:
			newTracks.append(tracks[i])
			newConfSeqs.append(confSeqs[i])
			newStartFrames.append(startFrames[i])
		else:
			print('removing long large track', i, '-- start frame:', startFrames[i])
			#biggerTrack = make_bigger_track(tracks[i], fw, fh, 3)
			#newTracks.append(biggerTrack)
			#newConfSeqs.append(confSeqs[i])
			#newStartFrames.append(startFrames[i])

	return newTracks, newConfSeqs, newStartFrames

def make_bigger_track(track, fw, fh, scale = 2):
	biggerTrack = []
	#for box in track:
		#biggerBox = makeBiggerBox(box, fw, fh, scale, False)
		#biggerTrack.append(biggerBox)

	return biggerTrack

#Added 6.20.22 to test filter_update ablations
def reformatTracks(track, startFrame, numFrames, idx):
	trimmedTrack = []
	f = startFrame - 1
	while f < numFrames:
		frame, box = track[f]
		(x1, y1, w, h) = box

		trimmedTrack.append([float(x1), float(y1), float(w), float(h), float(f+1), float(idx)])
		f += 1
	return trimmedTrack

def trim_track(track, confSeq, startFrame, numFrames, frameWidth, frameHeight, idx):
	trimmedTrack = []
	f = startFrame - 1
	offScreenForward = False
	#Build track forward
	while f < numFrames:
		if not offScreenForward:
			frame, box = track[f]
			if not ABLATE_TRIM_OFF_SCREEN:
				xOnScreen, xOnePercent, yOnScreen, yOnePercent = taishiCheck(box, frameWidth, frameHeight, f)
			else:
				xOnScreen = 0
				xOnePercent = 0
				yOnScreen = 0
				yOnePercent = 0
			(x1, y1, w, h) = box
			if ABLATE_TRIM_LATE or ABLATE_TRIM_EARLY:
				percentOff, outOfScreen = percentOffScreen(x1, y1, w, h, frameWidth, frameHeight)
				if ABLATE_TRIM_EARLY:
					if percentOff > 0:
						offScreenForward = True
						trimmedTrack.append([float(0), float(0), float(0), float(0), float(f+1), float(idx)])
				if ABLATE_TRIM_LATE:
					if percentOff == 1:
						offScreenForward = True
						trimmedTrack.append([float(0), float(0), float(0), float(0), float(f+1), float(idx)])
			if ABLATE_TRIM_OFF_SCREEN:
				trimmedTrack.append([float(x1), float(y1), float(w), float(h), float(f+1), float(idx)])
			elif xOnScreen > xOnePercent and yOnScreen > yOnePercent:
				trimmedTrack.append([float(x1), float(y1), float(w), float(h), float(f+1), float(idx)])
			else:
				offScreenForward = True
				if not ABLATE_TRIM_ON_SCREEN:
					trimmedTrack = trimEdge(trimmedTrack, confSeq, f, -1)
				else:
					trimmedTrack.append([float(0), float(0), float(0), float(0), float(f+1), float(idx)])
		else:
			trimmedTrack.append([float(0), float(0), float(0), float(0), float(f+1), float(idx)])
		f += 1
	if not offScreenForward and not ABLATE_TRIM_ON_SCREEN:
		trimmedTrack = trimEdge(trimmedTrack, confSeq, numFrames - 1, -1)

	f = startFrame -1
	offScreenBackward = False
	#build track backwards
	while f >= 0:
		#print("frame", f)
		if not offScreenBackward:
			frame, box = track[f]
			if not ABLATE_TRIM_OFF_SCREEN:
				xOnScreen, xOnePercent, yOnScreen, yOnePercent = taishiCheck(box, frameWidth, frameHeight, f)
			else:
				xOnScreen = 0
				xOnePercent = 0
				yOnScreen = 0
				yOnePercent = 0
			(x1, y1, w, h) = box
			if ABLATE_TRIM_LATE or ABLATE_TRIM_EARLY:
				percentOff, outOfScreen = percentOffScreen(x1, y1, w, h, frameWidth, frameHeight)
				if ABLATE_TRIM_EARLY:
					if percentOff > 0:
						offScreenBackward= True
						trimmedTrack.insert(0,[float(0), float(0), float(0), float(0), float(f+1), float(idx)])
				if ABLATE_TRIM_LATE:
					if percentOff == 1:
						offScreenBackward = True
						trimmedTrack.insert(0,[float(0), float(0), float(0), float(0), float(f+1), float(idx)])
			if ABLATE_TRIM_OFF_SCREEN:
				trimmedTrack.insert(0,[float(x1), float(y1), float(w), float(h), float(f+1), float(idx)])
			elif xOnScreen > xOnePercent and yOnScreen > yOnePercent:
				trimmedTrack.insert(0,[float(x1), float(y1), float(w), float(h), float(f+1), float(idx)])
			else:
				offScreenBackward = True
				if not ABLATE_TRIM_ON_SCREEN:
					trimmedTrack = trimEdge(trimmedTrack, confSeq, f, 1)
				else:
					trimmedTrack.insert(0,[float(0), float(0), float(0), float(0), float(f+1), float(idx)])
		else:
			trimmedTrack.insert(0,[float(0), float(0), float(0), float(0), float(f+1), float(idx)])
		f -= 1
	if not offScreenBackward and not ABLATE_TRIM_ON_SCREEN:
		trimmedTrack = trimEdge(trimmedTrack, confSeq, 0, 1)

	return trimmedTrack

def filterDetectionsPreFilter(detections, threshold):
	newDetections = []
	for f in range(len(detections)):
		frameList = []
		for (box, score) in detections[f]:
			if score > threshold:
				fakeScore = threshold + 0.1
				frameList.append((box,fakeScore))
		newDetections.append(frameList)
	return newDetections


def filterDetectionsSimple(detections, threshold):
	newDetections = []
	for f in range(len(detections)):
		frameList = []
		for (box, score) in detections[f]:
			if score > threshold:
				frameList.append((box,score))
		newDetections.append(frameList)
	return newDetections
			
def track_kpd_matlab_wrapper(detections, numFrames, frameWidth, frameHeight, imgPath, igr):
	##
	random.seed(0) # same every time
	global IGR#Ignore regions for DETRAC
	IGR = igr
	global VID_ID
	VID_ID = imgPath[-6:-1]
	#print(frameWidth,frameHeight)
	#print(frameWidth*frameHeight)
	##
	if not DISABLE_PROFILER:
		cp=cProfile.Profile()
		cp.enable()
	#with open("../../../output.txt", 'w') as fh:
		#sys.stdout = fhmakeBiggerBox

	if BEFORE_LOADING:
		start = time()
	
	if ABLATE_PRE_FILTER is not None:
		detections = filterDetectionsPreFilter(detections, ABLATE_PRE_FILTER)

	if (not ABLATE_NO_MEDFLOW_SWITCH) or (not ABLATE_NO_MEDFLOW_REPLACE):
		images, fullImage = load_frames(numFrames, frameWidth,frameHeight, imgPath )
	else:
		images = []
		fullImage = []

	print('frame width:',frameWidth)
	print('frame height:',frameHeight)

	if not BEFORE_LOADING:
		start = time()
	
	

	#here we run our algorithm
	tracks, states, confSeqs, mfTracks, boxesInFrameDict, startFrames, trackGoodnessFlags = trackKPD(detections, numFrames, frameWidth, frameHeight, images, fullImage)

	#here we do some post processing
	if not ABLATE_NO_JOIN:
		tracks, confSeqs, startFrames, trackGoodnessFlags = postProcessCombinePartialTracks(tracks, states, confSeqs, mfTracks, detections, numFrames, fullImage, frameWidth, frameHeight, trackGoodnessFlags)

	if not ABLATE_NO_LONG_LARGE:
		#print("beginning postProcessDropLongLargeTracks")
		tracks, confSeqs, startFrames = post_process_drop_long_large_tracks(tracks, confSeqs, startFrames, trackGoodnessFlags, frameWidth, frameHeight)
		#print("beginning postProcessRemoveRedundantTracks")
		boxesInFrameDict = track_list_to_dict(tracks)
		tracks, confSeqs, startFrames = postProcessRemoveRedundantTracks(tracks, confSeqs, startFrames, boxesInFrameDict)
   
	end = time()

	#here we format our output for DETRAC
	idx = 1 #track index
	out = [] #list of all final tracks
	if len(tracks) != len(startFrames):
		print("Track and startframes mismatched length")
		sys.exit(-1)
	for track, startFrame in zip(tracks, startFrames):
		#print('track:', idx-1)
		#print(confSeqs[idx-1])makeBiggerBox
		#print("analyzing track:", idx-1)
		#print('startFrame', startFrame)
		tempOut = trim_track(track, confSeqs[idx-1], startFrame, numFrames, frameWidth, frameHeight, idx)
		for bb in tempOut:
			out.append(bb)
		idx += 1

		"""
		tempOut = []  #represents final version of single track

		f = startFrame - 1
		offScreenForward = False
		#Build track forward

		while f < numFrames:
			if not offScreenForward:
				frame, box = track[f]
				xOnScreen, xOnePercent, yOnScreen, yOnePercent = taishiCheck(box, frameWidth, frameHeight, f, idx-1 )
				(x1, y1, w,h) = box
				if xOnScreen > xOnePercent and yOnScreen > yOnePercent:
					tempOut.append([float(x1), float(y1), float(w), float(h), float(f+1), float(idx)])
				else:
					offScreenForward = True
					tempOut = trimEdge(tempOut, confSeqs[idx-1], f, -1)
			else:
				tempOut.append([float(0), float(0), float(0), float(0), float(f+1), float(idx)])
			f += 1
		if not offScreenForward:
			tempOut = trimEdge(tempOut, confSeqs[idx-1], numFrames - 1, -1)

		f = startFrame -1
		offScreenBackward = False;
		#build track backwards
		while f >= 0:
			#print("frame", f)
			if not offScreenBackward:
				frame, box = track[f]
				xOnScreen, xOnePercent, yOnScreen, yOnePercent = taishiCheck(box, frameWidth, frameHeight, f , idx-1)
				(x1, y1, w,h) = box
				if xOnScreen > xOnePercent and yOnScreen > yOnePercent:
					tempOut.insert(0,[float(x1), float(y1), float(w), float(h), float(f+1), float(idx)])
				else:
					offScreenBackward = True
					tempOut = trimEdge(tempOut, confSeqs[idx-1], f, 1)
			else:
				tempOut.insert(0,[float(0), float(0), float(0), float(0), float(f+1), float(idx)])
			f -= 1
		if not offScreenBackward:
			tempOut = trimEdge(tempOut, confSeqs[idx-1], 0, 1)
		"""





	num_frames = len(detections)
	# this part occasionally throws ZeroDimakeBiggerBoxvisionError when evaluated in the DETRAC toolkit without the except clause
	try:
		speed = num_frames / (end - start)
	except:
		speed = num_frames / 0.1


	#print("done!")

	if not DISABLE_PROFILER:
		cp.disable()
		stats = pstats.Stats(cp)
		stats.sort_stats('tottime')
		stats.print_stats()

	return speed, out

#json.dump(dict, f)
#dict = json.load(f)
