import sys
import csv
import os
import numpy as np
import convertGMMCPRes as convert

#### Procedure
#1)Get thresholds from user
#2)Get sequences from file
#3)store combined sequence and threshold name in config file
#4)run main.m for single configuration, this produces a trackRes.mat file in ./trackingResults/
#5)convert this res.mat file into the DETRAC format(LX,LY,H,W)
#6)store this DETRAC res file and speed file in -> threshold -> sequence name
#7)Go to step 3) for next sequence and threshold configuration

#Create the files needed for DETRAC experiment
def does_res_dir_exist(thresh, seq):
    detracResFile = './conv_results/' + thresh + '/' #this is where we will put the results for DETRAC to read
    if not os.path.exists(detracResFile):
        os.mkdir(detracResFile)
    detracResFile += seq + '/'
    if not os.path.exists(detracResFile):
        os.mkdir(detracResFile)


def run_gmmcp(threshold):
    threshList = []
    if threshold.lower() == 'full': #User wants to run tracker over full threshold list  ####1)
        for i in np.arange(0.1,0.9,0.1): #Create a list of thresholds
            threshList.append('{:.1f}'.format(i))
    else: #user chose a single threshold
        if(float(threshold)>1.0 or float(threshold)<0.0): #user gave an invalid threshold
            print('Threshold must be in the range 0.0 to 1.0. Alternatively you can enter "Full" to run over all thresholds')
            exit(-1)
        threshList.append(threshold)#Create singleton list with user chosen threshold
    
    sequenceList = []
    seqFile = open('sequences.txt', 'r') 
    seqList = seqFile.readlines() #get list of sequences from file  ####2)
    seqFile.close()
    
    print('threshList', threshList)
    print('seqList', seqList)
    for seq in seqList:
        for thresh in threshList:
            
            #Write to config file
            config = seq + '-' + thresh
            with open('config.txt', 'w') as configFile:
                configFile.write(config + '\n' + seq + '\n') ####3)
            print('configFile written')
            #RUN TRACKER
            print('running tracker')
            os.system('timeout 45m flatpak run org.octave.Octave main.m')  ####4)
            print('tracking complete')
            
            detracResFile = './conv_results/' + thresh + '/' + seq + '/' 
            
            #Tracker timed Out
            if(not os.path.exists('completed.txt')):
                does_res_dir_exist(thresh,seq)
                print('gmmcp timed out')
                try:
                    os.mknod(detracResFile + 'GMMCP_LX.txt')
                    os.mknod(detracResFile + 'GMMCP_LY.txt')
                    os.mknod(detracResFile + 'GMMCP_H.txt')
                    os.mknod(detracResFile + 'GMMCP_W.txt')
                    os.mknod(detracResFile + 'speed.txt')
                except:
                    print('result files already exist')
                    pass
                continue
            
            #Convert tracker result file into a format we can evaluate with DETRAC
            resmatFile = './trackingResults/' + seq + '/trackRes.mat' #This is the file name which is produced by main.m, we need to turn it into a format that DETRAC understands
            bboxScoreIdList = convert.readMatFile(resmatFile)
            
            does_res_dir_exist(thresh,seq)
            os.system('mv speed.txt ' + detracResFile) #Move speed file into our gmmcp results directory
           
            GMMCP_LX = detracResFile + 'GMMCP_LX.txt' #generated files for input to DETRAC
            GMMCP_LY = detracResFile + 'GMMCP_LY.txt'
            GMMCP_H = detracResFile + 'GMMCP_H.txt'
            GMMCP_W = detracResFile + 'GMMCP_W.txt'
            convert.writeDETRACFiles(bboxScoreIdList, GMMCP_LX, GMMCP_LY, GMMCP_H, GMMCP_W) #Here is where the conversion actually happens ####5) and ####6)
            
            trackingResultsPath = './trackingResults/' + seq +'/'
            if os.path.exists(trackingResultsPath):
                os.system('rm -r ' + trackingResultsPath)#Remove trackingResults directory for sequence after running gmmcp
            os.system('rm completed.txt')
    return None

if __name__ == "__main__":
    if len(sys.argv) < 2:
        print("Usage: run_GMMCP.py [threshhold or 'Full']")
        print("... also, remember to change the sequences.txt file in this directory!")
        sys.exit(1)
    threshold = sys.argv[1]
    run_gmmcp(threshold)
    