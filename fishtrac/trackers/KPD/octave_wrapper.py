
import sys
import os
import scipy.io
import kpd_tracker as kpd

print(sys.argv)


def convertMatToBBList(arr):
	bigList = []
	(numRows, numCols) = arr.shape
	#print('numRows: ', numRows)
	#print('numCols: ', numCols)
	for r in range(numRows):
		f = int(arr[r,0])
		#arr[r,1] is redundant
		bbox = (float(arr[r,2]), float(arr[r,3]), float(arr[r,4]), float(arr[r,5]))
		score = float(arr[r,6])
		while len(bigList) < f:
			bigList.append([])
		bigList[f-1].append((bbox, score))
	return bigList



if len(sys.argv) < 7:
	print("Usage: octave_wrapper.py detectionsFile numFrames frameWidth frameHeight imgPath trackDuringOcclusion ignoreRegions")
	sys.exit(2)



d = scipy.io.loadmat(sys.argv[1])
detections = convertMatToBBList(d['detects'])
print("Converted to bbList with",len(detections), "elements")

numFrames = int(sys.argv[2])
frameWidth = int(sys.argv[3])
frameHeight = int(sys.argv[4])
imgPath = sys.argv[5]
trackDuringOcclusion = sys.argv[6]
print("trackDuringOcclusion =", trackDuringOcclusion)
if trackDuringOcclusion == 1:
	trackDuringOcclusion = True
else:
	trackDuringOcclusion = False
if len(sys.argv) == 8:
	ignoreRegions = sys.argv[7].split(',')
	#print('ignoreRegions:', ignoreRegions)
	igr = []
	for i in range(0,len(ignoreRegions),4):
		row = []
		for j in range(4):
			row.append(float(ignoreRegions[i+j]))
		igr.append(row)
	#print("igr:", igr)
else:
	igr = None

speed,trackList = kpd.track_kpd_matlab_wrapper(detections,numFrames, frameWidth, frameHeight, imgPath, igr)

scipy.io.savemat("results.mat", {"speed":speed, 'trackList':trackList})
