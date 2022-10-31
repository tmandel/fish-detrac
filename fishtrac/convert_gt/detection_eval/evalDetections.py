import showGT
import showDetections
import showOnVideo
from statistics import mean
import matplotlib.pyplot as plt
import numpy as np
import sys
import json
from scipy.sparse import csr_matrix
from scipy.sparse.csgraph import maximum_bipartite_matching

def bb_intersection_over_union(boxA, boxB):
    # determine the (x, y)-coordinates of the intersection rectangle
    xA = max(boxA[0], boxB[0])
    yA = max(boxA[1], boxB[1])
    xB = min(boxA[2], boxB[2])
    yB = min(boxA[3], boxB[3])
    # compute the area of intersection rectangle
    interArea = max(0, xB - xA + 1) * max(0, yB - yA + 1)
    # compute the area of both the prediction and ground-truth
    # rectangles
    boxAArea = (boxA[2] - boxA[0] + 1) * (boxA[3] - boxA[1] + 1)
    boxBArea = (boxB[2] - boxB[0] + 1) * (boxB[3] - boxB[1] + 1)
    # compute the intersection over union by taking the intersection
    # area and dividing it by the sum of prediction + ground-truth
    # areas - the interesection area
    iou = interArea / float(boxAArea + boxBArea - interArea)
    # return the intersection over union value
    return iou
    
def getDetectorEvalOnVideo(gtLists, predLists, confThresh=0.5,verbose=False):
    tp = 0
    fp = 0
    fn = 0
    count=0
    for f in range(len(gtLists)):
        gtScoreIdList = gtLists[f]
        predScoreList = predLists[f]
        
        count+=1
        # for (pBox, pScore) in predScoreList:
            # if pScore < confThresh:
                # continue
            # foundTup = None
            # for gTup in gtScoreIdList:
                # (gBox, gScore,id) = gTup
                # iou = bb_intersection_over_union(gBox, pBox)
                # if iou >= 0.2:
                    # foundTup = gTup
                    # tp1 += 1
                    # break
            # if foundTup is None:
                # fp1 += 1
            # else:
                # gtScoreIdList.remove(foundTup)
        # fn1 += len(gtScoreIdList)
        
        filteredPreds = []
        for (pBox, pScore) in predScoreList:
           if pScore < confThresh:
                continue
           filteredPreds.append(pBox)
        
        matrix = np.zeros((len(filteredPreds), len(gtScoreIdList)))
        for pBoxInd in range(len(filteredPreds)):
            pBox = filteredPreds[pBoxInd]
            foundTup=False
            for gTupInd in range(len(gtScoreIdList)):
                (gBox, gScore,id) = gtScoreIdList[gTupInd]
                
                iou = bb_intersection_over_union(gBox, pBox)
                if iou >= 0.2:
                    matrix[pBoxInd][gTupInd] = 1
                    foundTup=True
            
        #This returns the matches one per column (despite what the argument says)
        # in other words, the element at index i tells us whether the ground truth at index i was matched
        #print("Matrix shape", matrix.shape)
        #print(" CSR Matrix shape", csr_matrix(matrix).shape)
        matches = (maximum_bipartite_matching(csr_matrix(matrix), perm_type='row')).tolist()
        #print("matches", len(matches), "compared to", len(filteredPreds))
        tp1 = 0
        fp1 = 0
        fn1 = 0
        for match in matches:
            if match is not -1:
                tp1 += 1
                
        fn1 = len(gtScoreIdList) - tp1
        fp1 = len(filteredPreds) - tp1
        
        if verbose == True:
            if(tp1 + fp1) == 0:
                precision = 0
            else:
                precision = tp1 / (tp1 + fp1)
            print('Frame', count-1,'Precision:',tp1,'/ (',tp1,'+',fp1,') = ',precision)
            
            recall = tp1 / (tp1 + fn1)
            print('Frame',count-1,'recall:',tp1,'/ (',tp1,'+',fn1,') = ',recall)
        tp+=tp1
        fp+=fp1
        fn+=fn1
    return (tp, fp, fn)
            
            

def get_precision_and_recall(confThresh, vidList, detName,verbose=False):
    summedTP = 0
    summedFP = 0
    summedFN = 0
    print('Analyzing at Confidence Threshold:',confThresh)
    detectionDir = "../../DETRAC-Train-Detections/R-CNN/"
    annotationDir= "../../DETRAC-Train-Annotations-MAT/"

    for vidPrefix in vidList:
        (h, w, x, y) = showGT.convertFile(annotationDir + vidPrefix)
        bigGTList = showOnVideo.reformatOutput(x,y,h,w)
        predList = showDetections.loadDetections(detectionDir + vidPrefix + detName)
        (tp,fp,fn) = getDetectorEvalOnVideo(bigGTList, predList,confThresh,verbose)
        summedTP += tp
        summedFP += fp
        summedFN += fn
    print('Precision:',summedTP,'/ (',summedTP,'+',summedFP,')')
    if(summedTP + summedFP) == 0:
        precision = 1
    else:
        precision = summedTP / (summedTP + summedFP)
    print('recall:',summedTP,'/ (',summedTP,'+',summedFN,')')
    recall = summedTP / (summedTP + summedFN)
    return precision, recall

    
if __name__ == "__main__":
    if len(sys.argv) < 2:
        #Verbose should print precision and recall for a single frame
        print("Usage: evalDetections.py fish/car/ped/_video [detectorname/all] [verbose/normal] [threshold]")
        sys.exit(2)
    fishVids= ["V1_Leleiwi_26June19_22","V1_Leleiwi_26June19_17", "02_Oct_18_Vid-3"]
    carVids = ["MVI_40141","MVI_40732","MVI_41073"]
    pedVids = ["MOT17-02-DPM",  "MOT17-04-DPM",  "MOT17-05-DPM",  "MOT17-09-DPM",  "MOT17-10-DPM",  "MOT17-11-DPM",  "MOT17-13-DPM"]
    vidList = None
    vidDetList = ["_Det_R-CNN.txt","_Inf_Mobile_Det_R-CNN.txt","_Inf_ssdResNet_Det_R-CNN.txt","_DK_Det_R-CNN.txt","_DK_TINY_Det_R-CNN.txt","_DK_TINY_608_Det_R-CNN.txt","_DK_1024_Det_R-CNN.txt", "_UNITY_NewMnet50model_Det_R-CNN.txt","_UNITY_Yolov4TFLITE_608_Det_R-CNN.txt","_UNITY_NewResnet50model_Det_R-CNN.txt","_DK_320_Det_R-CNN.txt", "_UNITY_Yolov4TFLITE_320_Det_R-CNN.txt","_DK_Y3Tiny608_Det_R-CNN.txt","_UNITY_Yolov4Tiny320-New_Det_R-CNN.txt","_CONSOLE_MobileNet50_Det_R-CNN.txt","_UNITY_Mnet50model100Det_Det_R-CNN.txt","_DK_TEMP320_Det_R-CNN.txt"]
    labelList = ["Retinanet","Mobilenetv2","ssdResnet","YOLOV4-608x608","TinyYOLOV4-416x416","TinyYOLOV4-608x608", "Yolo-1024x1024", "Unity-MobileNet50" ,"Unity-Tiny-Yolov4-608x608","Unity-Resnet50","Yolov4Tiny-320x320","Unity-Tiny-Yolov4-320x320","Yolov3Tiny608", "Unity-Tiny-Yolov4-320x320-New","ConsoleMobileNet","Unity-MobileNet100","Yolov4320"]
    className = sys.argv[1]
    verbose=False
    thres=None
    jsonBool = False
    
    try:
        thres=float(sys.argv[4])
    except:
        thres=None
    
    try:
        if sys.argv[3].strip().lower()[0] == 'v':
            verbose=True
    except:
        verbose=False
        debug=False
    if sys.argv[2].strip().lower()[0] == 'm':
        vidDetList=["_Inf_Mobile_Det_R-CNN.txt"]
        labelList = ["Mobilenetv2"]
    elif 'res' in sys.argv[2].strip().lower():
        vidDetList=["_Inf_ssdResNet_Det_R-CNN.txt"]
        labelList = ["ssdResnet"]
    elif 'python' in sys.argv[2].strip().lower():
        vidDetList=["_PythonTflite_Mnet50model100Det_Det_R-CNN.txt"]
        labelList = ["PythonTflie"]
    elif 'unity' in sys.argv[2].strip().lower():
        if "mobile" in sys.argv[2].strip().lower():
            if "100" in sys.argv[2].strip().lower():
              vidDetList=["_UNITY_Mnet50model100Det_Det_R-CNN.txt"]
              labelList = ["Unity-MobileNet100"]
            else:
              vidDetList=["_UNITY_NewMnet50model_Det_R-CNN.txt"]
              labelList = ["Unity-MobileNet50"]
        elif "yolo" in sys.argv[2].strip().lower():
            if "608" in sys.argv[2].strip().lower():
                vidDetList=["_UNITY_Yolov4TFLITE_608_Det_R-CNN.txt"]
                labelList = ["Unity-Tiny-Yolov4-608x608"]
            elif "new" in sys.argv[2].strip().lower():
                vidDetList=["_UNITY_Yolov4Tiny320-New_Det_R-CNN.txt"]
                labelList = ["Unity-Tiny-Yolov4-320x320-New"]
            elif "320" in sys.argv[2].strip().lower():
                vidDetList=["_UNITY_Yolov4TFLITE_320_Det_R-CNN.txt"]
                labelList = ["Unity-Tiny-Yolov4-320x320"]
    elif "dark" in sys.argv[2].strip().lower():
        if "tiny" in sys.argv[2].strip().lower():
            if "608" in sys.argv[2].strip().lower():
                vidDetList=["_DK_TINY_608_Det_R-CNN.txt"]
                labelList = ["TinyYOLOV4-608x608"]
            elif "320" in sys.argv[2].strip().lower():
                vidDetList=["_DK_320_Det_R-CNN.txt"]
                labelList = ["Yolov4Tiny-320x320"]
            else:
                vidDetList=["_DK_TINY_Det_R-CNN.txt"]
                labelList = ["TinyYOLOV4-416x416"]
        elif "1024" in sys.argv[2].strip().lower():
            vidDetList=["_DK_1024_Det_R-CNN.txt"]
            labelList=["Yolo-1024x1024"]
        elif "v3" in sys.argv[2].strip().lower():
            vidDetList=["_DK_Y3Tiny608_Det_R-CNN.txt"]
            labelList=["Yolov3Tiny608"]
        elif "new320" in sys.argv[2].strip().lower():
            vidDetList=["_DK_320NEW_Det_R-CNN.txt"]
            labelList=["Yolov4-320"]
        elif "320" in sys.argv[2].strip().lower():
            vidDetList=["_DK_TEMP320_Det_R-CNN.txt"]
            labelList=["Yolov4320"]
        else:
            vidDetList=["_DK_Det_R-CNN.txt"]
            labelList = ["YOLOV4-608x608"]
    elif "console" in sys.argv[2].strip().lower():
        vidDetList=["_CONSOLE_MobileNet50_Det_R-CNN.txt"]
        labelList = ["ConsoleMobileNet"]
    elif 'all' in sys.argv[2].strip().lower():
        vidDetList=vidDetList;
    elif 'retina' in sys.argv[2].strip().lower():
        vidDetList=["_Det_R-CNN.txt"]
        labelList = ["Retinanet"]
    if className.strip().lower() == "fish":
        vidList = fishVids
    elif className.strip().lower()  == "car":
        vidList = carVids
    elif className.strip().lower()  == "ped":
        vidList = pedVids
    elif className[0] == '_':
        vidList = [className[1:]]

    #print(vidDetList)
    #sys.exit(1)
    labelIndex = 0
    for vidDet in vidDetList:
        method = {}
        method['method']=[]
        precisions = []
        recalls = []
        mAP=0
        mAP_Index=0
        if thres is not None:
            precision, recall = get_precision_and_recall(thres, vidList,vidDet,verbose)
            if thres == 0.5:
                precision50 = precision
                recall50 = recall
            precisions.append(precision)
            recalls.append(recall)
        else:
          for i in np.linspace(0,1,101):
            precision, recall = get_precision_and_recall(i, vidList,vidDet,verbose)
            if i == 0.5:
                precision50 = precision
                recall50 = recall
            precisions.append(precision)
            recalls.append(recall)
            if mAP_Index == 0:
                mAP_Index = mAP_Index + 1
                previousPrecision=precision
                previousRecall=recall
            else:
                if (previousRecall - recall) < 0:
                    print("THIS IS NEGATIVE!",(previousRecall - recall))
                    sys.exit(1)
                mAP = mAP + ((previousRecall - recall) * previousPrecision)
                
                previousPrecision=precision
                previousRecall=recall
        print("///////////",labelList[labelIndex],"///////////////")
        print("Average Precision:",mean(precisions),"Average Recall:", mean(recalls))
        try:
            print("Mean Average Precision:",mAP)
            print("Precision at 50% Threshold:",precision50,"Recall at 50% Threshold:",recall50)
        except:
            print("Precision at",thres*100,"% Threshold:",precision,"Recall at",thres*100,"Threshold:",recall)
        plt.plot(recalls,precisions, label=labelList[labelIndex])
        method['method'].append({
            'name': labelList[labelIndex],
            'AP': mean(precisions),
            'AR': mean(recalls),
            'AP50': precision50,
            'AR50': recall50,
            'mAP': mAP,
            'precisions': precisions,
            'recalls': recalls
        })
        path=labelList[labelIndex] + ".json"
        labelIndex += 1
        with open(path,'w') as outfile:
            json.dump(method, outfile)
    plt.xlabel('Recall')
    plt.ylabel('Precision')
    plt.title('PR Curve')
    plt.grid(True)
    plt.legend()
    plt.savefig("detectionPR.png")
    #plt.show()
