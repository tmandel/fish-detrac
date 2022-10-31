
import sys
import os
import scipy.io
import kcf_tracker as kcf

print(sys.argv)

def formatBBList(arr):
	bigList = []
	numRows = len(arr)  #Rows = frame_num, detection_idx, x, y, w, h, prob
	numCols = len(arr[0]) #Colums = number of detections
	print('numRows: ', numRows)
	print('numCols: ', numCols)
	for c in range(numCols):
		f = int(arr[0][c])
		#arr[r,1] is redundant
		bbox = (float(arr[2][c]), float(arr[3][c]), float(arr[4][c]), float(arr[5][c]))
		score = float(arr[6][c])
		while len(bigList) < f:
			bigList.append([])
		try:
			bigList[f-1].append((bbox, score))
		except Exception as err:
			print(err)
			print('Likely cant find a detection for frame ', f)
			print(len(bigList))
			print(arr)
			exit(-1)
	return bigList


def convertMatToBBList(arr):
	bigList = []
	numDetections = 0
	for i in range(len(arr[0])):
		if arr[0][i] > arr[0][i+1]:
			numDetections = i+1
			break
	
	idx = 0
	for i in range(7):
		littleList = []
		while idx < (numDetections*(i+1)):
			littleList.append(float(arr[0][idx]))
			idx+=1
		bigList.append(littleList)
	return bigList
"""
def convertMatToBBList(arr):
	bigList = []
	(numRows, numCols) = arr.shape
	for r in range(numRows):
		f = int(arr[r,0])
		#arr[r,1] is redundant
		bbox = (float(arr[r,2]), float(arr[r,3]), float(arr[r,4]), float(arr[r,5]))
		score = float(arr[r,6])
		if len(bigList) < f:
			bigList.append([])
		bigList[f-1].append((bbox, score))
	return bigList
	
"""

if len(sys.argv) < 5:
	print("Usage: octave_wrapper.py detectionsFile numFrames frameWidth frameHeight imgPath")
	sys.exit(2)



d = scipy.io.loadmat(sys.argv[1])
detections = convertMatToBBList(d['detects'])
detections = formatBBList(detections)
print("Converted to bbList with",len(detections), "elements")



numFrames = int(sys.argv[2])
frameWidth = int(sys.argv[3])
frameHeight = int(sys.argv[4])
imgPath = sys.argv[5]


speed,trackList = kcf.track_kpd_matlab_wrapper(detections,numFrames, frameWidth, frameHeight, imgPath)

scipy.io.savemat("results.mat", {"speed":speed, 'trackList':trackList})
