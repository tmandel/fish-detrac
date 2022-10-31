import scipy.io
import sys
import numpy
import csv 
from conversion_utils import read_seq_file

def convert_mat_to_csv(matFileName):

    #get sequence name
    filePrefix = matFileName[:-4]
    annotationsDir = '../../../DETRAC-Train-Annotations-MAT/'
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
    outputDir = '../DAN-input/'
    if(filePrefix[:3] == 'MVI'):
        outputDir += 'UA-DETRAC/'
    else:
        outputDir += 'fish/'
    outputDir += 'annotations/'

    outputFile = outputDir + filePrefix + '.txt'
    print("Writing converted annotations to {}".format(outputFile))
    
    with open(outputFile, 'w') as csvFile:
        
        csvWriter = csv.writer(csvFile, delimiter = ',')
        #loop through tracks
            #loop through frames
        for track in range(numTracks):
            for frame in range(numFrames):
                #Check if track exists on this frame
                if w[frame, track] != 0:
                    #DAN Format: 
                    row = [frame+1, track+1, x[frame, track],
                            y[frame, track], w[frame, track],
                            h[frame, track], 1, 3, 1] 
                    csvWriter.writerow(row)
    print("Conversion from DETRAC gt format to DAN gt input format complete.")

if __name__ == '__main__':
    if len(sys.argv) < 2:
        print('Usage:', sys.argv[0], 'seqListName(ie. trainlist-full)')

    #retrieve list of sequences
    seqFileName = sys.argv[1]
    seqList = read_seq_file(seqFileName)
    print("Sequence list: {}".format(seqList))

    #convert each sequence annotation
    for seq in seqList:
        matFileName = seq + '.mat'
        convert_mat_to_csv(matFileName)
