import os
import sys
import csv

    
def convert_and_save_detections(detrac_detections, outDir):
    arr = detrac_detections
    numRows = len(arr)  #Rows = frame_num, detection_idx, x, y, w, h, prob
    numCols = len(arr[0]) #Colums = number of detections
    
    
    #list of detections in DAN input format
    detections = []
    
    print('numRows: ', numRows)
    print('numCols: ', numCols)
    for colNum in range(numCols):
        frameNum = int(arr[0][colNum])
        #print("frameNum is", frameNum)
        detection_idx = int(arr[1][colNum])
        x1 = float(arr[2][colNum])
        y1 = float(arr[3][colNum])
        width = float(arr[4][colNum])
        height = float(arr[5][colNum])
        prob = float(arr[6][colNum])
        
        newRecord = [frameNum, detection_idx, x1, y1, width, height, prob]
        while(len(newRecord) < 10):
            newRecord.append(-1)
        #Set track number to -1(dummy value)
        newRecord[1] = -1
        detections.append(newRecord)
    

    
    outFileName = outDir + 'MVI_9999.txt'
    print("Writing converted detections for DAN input to: {}".format( outFileName ))

    #Write out to dan formatted detection file
    with open(outFileName, 'w') as outF:
        csvWriter = csv.writer(outF)
        for row in detections:
            csvWriter.writerow(row)
        
    print("Conversion from DETRAC detection format to DAN detection input format complete.")
    return outFileName

