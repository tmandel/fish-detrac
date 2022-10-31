#This file was crreated by Travis Mandel for the FISHTRAC codebase
import scipy.io
import csv
import pandas as pd


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
		"""
		while idx < (numDetections*(i+1)):    cap.release()
	cv2.destroyAllWindows()


	cap.release()
	cv2.destroyAllWindows()
		"""

		while idx < (numDetections*(i+1)):
			littleList.append(float(arr[0][idx]))
			idx+=1
		bigList.append(littleList)
	return bigList
	
	
def convert_detections(detectionsFile, imgPath, outputPath):
	d = scipy.io.loadmat(detectionsFile)
	detections = convertMatToBBList(d['detects'])
	items = {'image_path': [], 'bb_left': [], 'bb_top': [], 'bb_width': [], 'bb_height': [], 'conf': [], 'category': []}
	
	numRows = len(detections)  #Rows = frame_num, detection_idx, x, y, w, h, prob
	numCols = len(detections[0]) #Colums = number of detections
	
	
	print('numRows: ', numRows)
	print('numCols: ', numCols)
	for colNum in range(numCols):
		frameNum = int(detections[0][colNum])
		detection_idx = int(detections[1][colNum])
		x = float(detections[2][colNum])
		y = float(detections[3][colNum])
		w = float(detections[4][colNum])
		h = float(detections[5][colNum])
		score = float(detections[6][colNum])
		
		imgNum = str(frameNum).zfill(5)
		filename = imgPath + "img" + str(imgNum) + ".jpg"
		items['image_path'].append(filename)
		items['bb_left'].append(x)
		items['bb_top'].append(y)
		items['bb_width'].append(w)
		items['bb_height'].append(h)
		items['conf'].append(score)
		items['category'].append(0)
		
			
			
	det_dfs = pd.DataFrame(items)
	
	columns = ['image_path','bb_left','bb_top', 'bb_width', 'bb_height', 'conf', 'category']
	det_dfs.to_csv(outputPath, header=False, index=False, columns=columns)
			
			
			
			
