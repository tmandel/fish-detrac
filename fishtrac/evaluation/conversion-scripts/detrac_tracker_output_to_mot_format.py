import csv
import sys
import os
import numpy as np
import scipy.io

def set_up_output_dir(experimentConfig):
    
    if not os.path.exists(experimentConfig['outputDir']):
        os.mkdir(outputDir)
    
    return outputDir
    

def save_mot_result(motResult, experimentConfig):
    set_up_output_dir(experimentConfig)
    outputFileName = experimentConfig['outputDir']\
                     + 'tracker.txt'
    
    with open(outputFileName, 'w') as outFile:
        csvWriter = csv.writer(outFile)
        for row in motResult:
            csvWriter.writerow(row)
           

def convert_detrac_row_to_mot_row(detracRow):
    motRow = detracRow 
    while(len(motRow) < 10):
        motRow.append(-1)
    
    return motRow

def extract_detrac_result_bbox_coordinates(detracResult, i):
    x = detracResult['X'][i]
    y = detracResult['Y'][i]
    w = detracResult['W'][i]
    h = detracResult['H'][i]
    
    return (x,y,w,h) 
    
def get_detrac_row(detracResult, i):
    detracRow = []
    (x,y,w,h) = extract_detrac_result_bbox_coordinates(detracResult, i)
    detracRow.append(detracResult['frame'][i])
    detracRow.append(detracResult['track_id'][i])
    detracRow.append(x - (w/2.0))
    detracRow.append(y - (h/2.0))
    detracRow.append(w)
    detracRow.append(h)

    return detracRow

def convert_detrac_result_to_mot_result(detracResult):
    motResult = []
    numBoxes = len(detracResult['X'])
    for i in range(numBoxes):
        detracRow = get_detrac_row(detracResult, i)
        motRow = convert_detrac_row_to_mot_row(detracRow)
        motResult.append(motRow)

    return motResult

def extract_state_info_bbox_coordinates(stateInfo, frameNum, trackNum):
    x = stateInfo['X'][frameNum, trackNum]
    y = stateInfo['Y'][frameNum, trackNum]
    w = stateInfo['W'][frameNum, trackNum]
    h = stateInfo['H'][frameNum, trackNum]

    return (x,y,w,h)

def add_non_empty_detrac_row(detracResult, bboxCoordinates, frameNum, trackNum):
    x,y,w,h = bboxCoordinates
    if w > 1.0:
        detracResult['frame'].append(frameNum + 1) # frames are 1 indexed for easier conversion to mot format and consistency
        detracResult['track_id'].append(trackNum)
        detracResult['X'].append(x)
        detracResult['Y'].append(y)
        detracResult['W'].append(w)
        detracResult['H'].append(h)

    return detracResult

def convert_state_info_to_detrac_result(stateInfo):
    detracResult = {'frame':[], 'track_id':[], 'X':[], 'Y':[], 'W':[], 'H':[]}
    frames, tracks = stateInfo['X'].shape
    for frameNum in range(frames):
        for trackNum in range(tracks):
            bboxCoordinates = extract_state_info_bbox_coordinates(stateInfo, frameNum, trackNum)
            detracResult = add_non_empty_detrac_row(detracResult, bboxCoordinates, frameNum, trackNum)

    return detracResult
    
def read_detrac_result_state_info(experimentConfig):
    pathToThisDir = os.path.abspath(os.path.dirname(__file__))
    stateInfoFileName = pathToThisDir + '/../../trackers/' + experimentConfig['tracker'] + '/hota-evaluation/' + experimentConfig['sequence'] + '/tracker.mat'
    print("state info path:", os.path.abspath(stateInfoFileName))
    stateInfo = scipy.io.loadmat(stateInfoFileName)

    return stateInfo

def get_detrac_result(experimentConfig):
    stateInfo = read_detrac_result_state_info(experimentConfig)
    detracResult = convert_state_info_to_detrac_result(stateInfo)
     
    return detracResult
             
## THIS IS THE IMPORTANT FUNCTION
def detrac_tracker_output_to_mot_format(experimentConfig):
    detracResult = get_detrac_result(experimentConfig)
    motResult = convert_detrac_result_to_mot_result(detracResult)
    save_mot_result(motResult, experimentConfig)

if __name__ == "__main__":
    if(len(sys.argv) < 4):
        print("usage: {} sequenceName tracker thresh".format(sys.argv[0]))
        sys.exit(2)

    sequenceName = sys.argv[1]
    tracker = sys.argv[2]
    thresh = sys.argv[3]
    pathToThisDir = os.path.abspath(os.path.dirname(__file__))
    outputDir = "{}/../../trackers/{}/hota-evaluation/{}/".format(pathToThisDir,tracker, sequenceName)
    print("outputDir:", outputDir) 

    experimentConfig = {"sequence":sequenceName, "tracker":tracker, "thresh":thresh, "outputDir":outputDir}
    
    detrac_tracker_output_to_mot_format(experimentConfig)
