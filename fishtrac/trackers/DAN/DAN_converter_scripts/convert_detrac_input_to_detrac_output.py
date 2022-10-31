import sys
import os
import csv


def convert_detrac_input_to_detrac_output(sequenceName, thresh, detracInputDir, detracOutputDir):
    
    inLX = "{}/{}/{}/DAN_LX.txt".format(detracInputDir,thresh, sequenceName)
    inLY = "{}/{}/{}/DAN_LY.txt".format(detracInputDir,thresh, sequenceName)
    inH = "{}/{}/{}/DAN_H.txt".format(detracInputDir,thresh, sequenceName)
    inW = "{}/{}/{}/DAN_W.txt".format(detracInputDir,thresh, sequenceName)

    inLXfile = open(inLX, "r")
    inLYfile = open(inLY, "r")
    inHfile = open(inH, "r")
    inWfile = open(inW,"r")

    xList = list(csv.reader(inLXfile,delimiter=","))
    yList = list(csv.reader(inLYfile,delimiter=","))
    hList = list(csv.reader(inHfile,delimiter=","))
    wList = list(csv.reader(inWfile,delimiter=","))

    inLXfile.close()
    inLYfile.close()
    inHfile.close()
    inWfile.close()

    comboList = list(zip(xList,yList,hList,wList))

    outputDir = detracOutputDir 
    if not os.path.exists(outputDir):
        os.mkdir(outputDir)

    outLX = "{}/{}_LX.txt".format(outputDir, sequenceName)
    outLY = "{}/{}_LY.txt".format(outputDir, sequenceName)
    outW = "{}/{}_W.txt".format(outputDir, sequenceName)
    outH = "{}/{}_H.txt".format(outputDir, sequenceName)
    
    outLXfile = open(outLX, "w")
    outLYfile = open(outLY, "w")
    outWfile = open(outW, "w")
    outHfile = open(outH, "w")

    outLXcsv = csv.writer(outLXfile)
    outLYcsv = csv.writer(outLYfile)
    outWcsv = csv.writer(outWfile)
    outHcsv = csv.writer(outHfile)

    for xInList, yInList, hInList, wInList in comboList:
        xOutRow = []
        yOutRow = []
        wOutRow = []
        hOutRow = []
        for i in range(len(xInList)):
            if round(float(hInList[i])) == 0 or round(float(wInList[i])) == 0:
                xOutRow.append(0)
                yOutRow.append(0)
                wOutRow.append(0)
                hOutRow.append(0) 
                continue
            
            w = wInList[i]
            h = hInList[i]
            x = float(xInList[i]) - round(float(w)/2)
            y = float(yInList[i]) - float(h)

            xOutRow.append(x)
            yOutRow.append(y)
            wOutRow.append(w)
            hOutRow.append(h)

        outLXcsv.writerow(xOutRow)
        outLYcsv.writerow(yOutRow)
        outWcsv.writerow(wOutRow)
        outHcsv.writerow(hOutRow)

    outLXfile.close()
    outLYfile.close()
    outHfile.close()
    outWfile.close()



if __name__ == "__main__":

    if(len(sys.argv) < 4):
        print("Usage: {} seqFilePrefix/_sequenceName thresh detracInputDir detracOutputDir".format(sys.argv[0]))
        sys.exit(2)
    seqList = []
    if sys.argv[1][0] == '_':
        sequenceList = [sys.argv[1]]
    else:
        with open("../../../evaluation/seqs/{}.txt".format(sys.argv[1])) as f:
            seqList = [line.rstrip() for line in f]
            
    thresh = sys.argv[2]
    detracInputDir = sys.argv[3]
    detracOutputDir = sys.argv[4]
    for sequenceName in seqList:
        convert_detrac_input_to_detrac_output(sequenceName, thresh, detracInputDir, detracOutputDir)
