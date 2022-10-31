# This file was created by Travis Mandel for the FISHTRAC codebase
import sys
import os
import numpy as np

import utils
import convert_DETRAC_detections as convertDet
from tao_tracking_release import generate_detection_features as genFeatures
from tao_tracking_release import track_tao
from tao_tracking_release.tao_post_processing import onekey_postprocessing as postprocess


def remove_1len_track(all_results):
	refined_results = []
	tids = np.unique(all_results[:, 1])
	for tid in tids:
		results = all_results[all_results[:, 1] == tid]
		if results.shape[0] <= 1:
			continue
		refined_results.append(results)
	refined_results = np.concatenate(refined_results, axis=0)
	return refined_results
	
def read_aoa_output(aoaOutputFile):
	video_result = np.load(aoaOutputFile)
	video_result = remove_1len_track(video_result)
	
	bboxDict = {}
	(numResults, numCols) = video_result.shape
	maxFrameNum = 1
	for r in range(numResults):
		frameNum = video_result[r,0]
		trackId = video_result[r,1]			
		boxTuple = (video_result[r,2], video_result[r,3], video_result[r,4], video_result[r,5])
		infoWeNeed = [boxTuple, 1, int(trackId)]
		key = int(frameNum)
		#What is the highest frame with a track in it
		if key > maxFrameNum:
			maxFrameNum = key
		#Seen this frame before
		if key in bboxDict:
			bboxDict[key].append(infoWeNeed)
		#Have not seen a track in this frame before
		else:
			bboxDict[key] = [infoWeNeed]
			

	bboxList = []
	for f in range(1,maxFrameNum+1):
		bboxList.append(bboxDict.get(f,[]))

	return bboxList





def track_aoa_matlab_wrapper(detectionsFile, numFrames, frameWidth, frameHeight, imgPath):
	convertDet.convert_detections(detectionsFile, imgPath, "AOA-input/aoa_detections.csv")
	genFeatures.inferDirect("AOA-input/aoa_detections.csv", "./results-AOA/det1_reid/det.npy", "tao_tracking_release/reid_pytorch/reid1.onnx")
	genFeatures.inferDirect("AOA-input/aoa_detections.csv", "./results-AOA/det2_reid/det.npy", "tao_tracking_release/reid_pytorch/reid2.onnx")
	print("Done with feature maps!")

	paramDict = { 'min_confidence': -1, \
				  'nms_max_overlap': -1, \
				  'max_cosine_distance': 0.4, \
				  'nn_budget': 70, \
				  'max_age': 12, \
				  'n_init': 1}
	track_tao.track_and_save("./results-AOA/det1_reid/det.npy", "./results-AOA/det1_reid/track.npy",
								True, paramDict)
	track_tao.track_and_save("./results-AOA/det2_reid/det.npy", "./results-AOA/det2_reid/track.npy", 
								True, paramDict)
	print("Done with initial track and saves!")
	
	postprocess.track_and_save("./results-AOA/det1_reid/track.npy", "./results-AOA/det2_reid/track.npy", \
						  "./results-AOA/combined.npy", 0.7)
	print("Done with postprocessing!")
	
	bboxScoreIdList = read_aoa_output("./results-AOA/combined.npy")
		
	AOA_LX = 'AOA_LX.txt'# generated files for input to DETRAC
	AOA_LY = 'AOA_LY.txt'
	AOA_H = 'AOA_H.txt'
	AOA_W = 'AOA_W.txt'

	#write bbox-score-id list out to a file which can be used as input to DETRAC
	print('Writing DETRAC files')
	utils.write_DETRAC_Files(bboxScoreIdList, AOA_LX, AOA_LY, AOA_H, AOA_W, numFrames)
	print("AOA complete!")
# python tao_post_processing/onekey_processing.py \
	# --onnx_results1 ./results/det1_reid/ \
	# --onnx_results2 ./results/det2_reid/ \
	# --annotations /path/to/train.json \
	# --output-dir ./results/onekey_results/ \
	# --workers 8
	
if __name__ == "__main__":
	if len(sys.argv) < 6:
		print("Usage: aoa_tracker.py detectionsFile numFrames frameWidth frameHeight imgPath igrStr")
		sys.exit(2)

	#TODO: Clear out the results from last time, if any
	inputDir = './AOA-input/'
	if os.path.exists(inputDir):
		os.system('rm -r ' + inputDir)
	os.system('mkdir ' + inputDir)

	danOutputDir='./results-AOA/'
	if os.path.exists(danOutputDir):
		os.system('rm -r ' + danOutputDir)
	
	os.system('mkdir ' + danOutputDir)
	os.system('mkdir ' + danOutputDir + "det1_reid/")
	os.system('mkdir ' + danOutputDir + "det2_reid/")
	#Clear out the results from last time, if any
	if os.path.exists('AOA_LX.txt'):
		os.system('rm AOA_LX.txt')
		os.system('rm AOA_LY.txt')
		os.system('rm AOA_W.txt')
		os.system('rm AOA_H.txt')

	detectionsFile = sys.argv[1]
	numFrames = int(sys.argv[2])
	frameWidth = int(sys.argv[3])
	frameHeight = int(sys.argv[4])
	imgPath = '../../'+sys.argv[5]
	track_aoa_matlab_wrapper(detectionsFile, numFrames, frameWidth, frameHeight, imgPath)
	
	 

