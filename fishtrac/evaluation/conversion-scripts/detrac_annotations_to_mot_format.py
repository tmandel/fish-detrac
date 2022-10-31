import scipy.io
import sys
import numpy
import csv 
import os

def detrac_annotations_to_mot_format(matFileName, outputFileName, fishDirPath):

    #get sequence name
    filePrefix = matFileName[:-4]
    annotationsDir = os.path.join(fishDirPath, 'DETRAC-Train-Annotations-MAT/')
    print("Reading {} from {}".format(matFileName, annotationsDir))

    #Read in MAT file
    matContents = scipy.io.loadmat(annotationsDir + matFileName)
    gtInfo = matContents['gtInfo']
    x = gtInfo['X'][0][0]
    x=x.astype('int')
    y = gtInfo['Y'][0][0]
    y=y.astype('int')
    w  = gtInfo['W'][0][0]
    w=w.astype('int')
    h = gtInfo['H'][0][0]
    h=h.astype('int')
    (numFrames, numTracks)=y.shape
    print('Converting {} gt tracks and {} frames to DAN input format'.format(numTracks, numFrames))

    #create csv formatted for input to DAN
    print("Writing converted annotations to {}".format(outputFileName))
    with open(outputFileName, 'w') as csvFile:
        
        csvWriter = csv.writer(csvFile, delimiter = ',')
        #loop through tracks
            #loop through frames
        for track in range(numTracks):
            for frame in range(numFrames):
                #Check if track exists on this frame
                if w[frame, track] != 0:
                    row = [frame+1, track+1, x[frame, track],
                            y[frame, track], w[frame, track],
                            h[frame, track], 1, 3, 1] 
                    csvWriter.writerow(row)
    print("Conversion from DETRAC gt format to DAN gt input format complete.")

if __name__ == '__main__':
    if len(sys.argv) < 3:
        print('Usage:', sys.argv[0], ' seqName tracker')
        exit(2)
    
    # path to fish detrac directory
    fishDirPath = os.path.join(os.path.abspath(os.path.dirname(__file__)), "../..")

    # retrieve list of sequences
    seqName = sys.argv[1]
    print("Sequence name: {}".format(seqName))
    trackerName = sys.argv[2]

    # Information needed to convert gt file
    matFileName = seqName + '.mat'
    outputFile = os.path.join(fishDirPath, 'trackers/{}/hota-evaluation/{}/gt.txt'.format(trackerName, seqName))
    print("output path:", os.path.abspath(os.path.dirname(outputFile)))

    # need to create output dir if there isnt one
    if not (os.path.exists(os.path.dirname(outputFile))):
        os.mkdir(os.path.dirname(outputFile))
    
    detrac_annotations_to_mot_format(matFileName, outputFile, fishDirPath)
