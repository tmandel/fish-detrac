import csv

def read_seq_file(seqListName):
    
    seqDir = '../../../evaluation/seqs/'
    seqListFileName = seqDir + seqListName + '.txt'
    seqList = []
    with open(seqListFileName, 'r') as f:
        csvReader = csv.reader(f)
        for row in csvReader:
            seqList.append(row[0])

    return seqList

def reformatOutput(LX, LY, H, W):

    outLX = open(LX, "r")
    outLY = open(LY, "r")
    outH = open(H, "r")
    outW = open(W,"r")

    xList = list(csv.reader(outLX,delimiter=","))
    yList = list(csv.reader(outLY,delimiter=","))
    hList = list(csv.reader(outH,delimiter=","))
    wList = list(csv.reader(outW,delimiter=","))

    comboList = list(zip(xList,yList,hList,wList))

    bigList = []

    for x1List, y1List, h1List, w1List in comboList:
        frameList=[]
        for i in range(len(x1List)):
            if round(float(h1List[i])) == 0 or round(float(w1List[i])) == 0:
                continue

            x1 = round(float(x1List[i]))
            y1 = round(float(y1List[i]))
            x2 = x1 + round(float(w1List[i]))
            y2 = y1 + round(float(h1List[i]))
            bbox = (x1, y1, x2, y2)

            score = None

            fishID = i

            miniList = [bbox, score, fishID]

            frameList.append(miniList)

        bigList.append(frameList)

    outLX.close()
    outLY.close()
    outH.close()
    outW.close()

    return bigList



