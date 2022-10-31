import csv
import cv2
import keras
from keras.preprocessing import image
from keras_retinanet import models
import matplotlib.pyplot as plt
from keras_retinanet.utils.image import read_image_bgr, preprocess_image, resize_image
from keras_retinanet.utils.visualization import draw_box, draw_caption
from keras_retinanet.utils.colors import label_color
import os, sys
from os.path import isfile, join
import numpy as np
import random
import scipy.io
from collections import defaultdict
import showOnVideo

FISH_MODEL_PATH = "./resnet_models/retinanet_resnet50_10epochs.h5" #FISH
CAR_MODEL_PATH = "./resnet_models/resnet50_10epochs_car_train200.h5" #CAR
PED_MODEL_PATH = "./resnet_models/resnet50_10epochs_ped_train1800.h5" #PEDESTRIAN

def get_predicted_boxes(model, image):
    # load image
    #image = read_image_bgr(filename)
    
    # preprocess image for network
    image = preprocess_image(image)
    image, scale = resize_image(image)
    
    # process image
    boxes, scores, labels = model.predict_on_batch(np.expand_dims(image, axis=0))
    
    # correct for image scale
    boxes /= scale
    return boxes, scores, labels



def extractFrames(videoFile, model_path):
    print("Reading Model")
    print(model_path)
    # load retinanet model
    model = models.load_model(model_path, backbone_name='resnet50')
    
    print("Reading video file")
    cap = cv2.VideoCapture(videoFile)
    count = 0
    #list of lists of boxes for all frames
    bboxesFrameList = []
    
    while cap.isOpened():
        print("Reading frame", count)
        
        #capture frame-by-frame
        ret, frameRGB = cap.read()
        
        if ret == True:
            #list of boxes and scores for one frame
            bboxScoreList = []
            frame = frameRGB[:, :, ::-1].copy()
            height, width, layers = frame.shape
            boxes, scores, labels = get_predicted_boxes(model, frame)
            
            for box, score, label in zip(boxes[0], scores[0], labels[0]):
                if score < 0:
                    break
                b = box.astype(int)
                bboxScoreList.append((b, score))
            count += 1
            bboxesFrameList.append(bboxScoreList)
        else:
            break
            
    cap.release()
    cv2.destroyAllWindows()
    print("Total frames:",count)
    return bboxesFrameList, width, height

def writeNewTxtFile(bigList, outputFile):
    newFile = open(outputFile, "w")
    frameNum = 0
    sep = ","
    #list of lists of boxes for all frames
    bboxesFrameList = []
    
    for frame in bigList:
    #[frame,frame,frame,...]
        frameNum += 1
        bboxNum = 0
        for box, score in frame:
        #[box,score]
            bboxNum += 1
            bList = []
            bStr = ""
            (x1,y1,x2,y2) = box
            left = round(float(x1),2)
            top = round(float(y1),2)
            right = round(float(x2),2)
            bottom = round(float(y2),2)
            height = abs(top-bottom)
            width = abs(right-left)
            
            bList = [frameNum, bboxNum, left, top, width, height, score]
            bStr = sep.join(map(str, bList))
            bStr += "\n"
            
            newFile.write(bStr)
    
    newFile.close()

def writeMatFile(videoFile, frameWidth, frameHeight, sequenceName, threshold, model_path):
    print("Reading model")
    print(model_path)
    model = models.load_model(model_path, backbone_name='resnet50')
    # load retinanet model
    print("Reading video file")
    cap = cv2.VideoCapture(videoFile)
    #list of lists of boxes for all frames
    
    rgbList = []
    count = 0
        ##########Mark##########
    #Create a dictionary with information from each frame in video
    frameInfo = {'boxes': [], 'scores': []}
    while cap.isOpened: #read frames from video
        print("Reading frame", count)
        ret, frameRGB = cap.read()
        if ret == True:
            frame = frameRGB[:, :, ::-1].copy()
            rgbList.append(frame)
            boxes, scores, _ = get_predicted_boxes(model,frame)
            frameInfo['boxes'].append(boxes)
            frameInfo['scores'].append(scores)
            count +=1
        else:
            break
    threshList = [] #create list of thresholds to iterate over
    if threshold.lower() == 'full': #user wants to run over all thresholds
        for i in np.arange(0.0,0.9,0.1):
            threshList.append(i)
    else: #user chose a single threshold
        if(float(threshold)>1.0 or float(threshold)<0.0): #user gave an invalid threshold
            print('Threshold must be in the range 0.0 to 0.9 Alternatively you can enter "Full" to run over all thresholds')
            exit(-1)
        threshList.append(float(threshold))
    
    outputPath = './Detections/'
    if not os.path.exists(outputPath):
        os.mkdir(outputPath)
        print('created output directory for: {}'.format(sequenceName))
    
    for thresh in threshList:
        bboxesFrameList = []
        print('Processing boxes above threshold: {}'.format(thresh))
        ########################
        
        for frameNum in range(len(rgbList)):
            boxes = frameInfo['boxes'][frameNum]
            scores = frameInfo['scores'][frameNum]
            bboxScoreList = []
            gotBox = False #Mark
            for box, score in zip(boxes[0], scores[0]):
                bList = []
                
                # if we change back to gmmcp's detections use this line
                #score = (score*6)-3
        
                if score < thresh:
                    continue
                print('Found a good detection for frame {}'.format(frameNum))
                gotBox = True#Mark
                b = box.astype(int)
                bList.extend(b)
                bList.append(score)
                bboxScoreList.append(bList)
                
            ##########Mark##########
            # if there aren't any detections on this frame that meet the confidence threshhold
            # we need a random placeholder box
            if gotBox is False:
                x = random.randint(0, frameWidth)
                y = random.randint(0, frameHeight)
                bList = []
                print('Warning: Frame {} has no good detections!'.format(frameNum))
                score = thresh #set score for dummy box to the current threshold
                b = np.array([x,y,x+1, y+1])#.astype(int)
                print(b)
                bList.extend(b)
                bList.append(score)
                bboxScoreList = [bList]#Dummy box
            
            bboxesFrameList.append(np.array(bboxScoreList, dtype=np.float64))
            ########################
        detectionDict = {}
        detectionDict["detections"] = np.array(bboxesFrameList, dtype=np.object)
        
        scipy.io.savemat(outputPath + "{}-{:.1f}.mat".format(sequenceName, thresh), detectionDict)
        
    for frameNum in range(len(rgbList)):
        print('writing frame {}'.format(frameNum))
        imgNum = frameNum + 200 #Mark
        dirName = sequenceName
        if not os.path.exists(dirName):
            os.makedirs(dirName)
        filename = dirName + "/test0" + str(imgNum) + ".jpg"
        #frame[:, :, ::-1]
        #plt.imsave(filename, frame/255.)
        plt.imsave(filename, rgbList[frameNum]/255.)
            #count += 1
            #else:
                #break
        detracImgNum = str(frameNum+1)
        while len(detracImgNum) < 5:
            detracImgNum = '0' + detracImgNum
        detracDirName = sequenceName + '-DETRAC-Images/'
        if not os.path.exists(detracDirName):
            os.mkdir(detracDirName)
        detracFileName = detracDirName + 'img' + detracImgNum + '.jpg' #Detrac wants its images to be one indexed
        plt.imsave(detracFileName, rgbList[frameNum]/255.)
    
    cap.release()
    cv2.destroyAllWindows()
    

if __name__ == "__main__":
    
    if len(sys.argv) < 4:
        print("Usage: outputDetectorPredictions.py [videoFile] [threshhold or 'Full'] [Model: 'Fish'/'Car'/'Ped']")
        sys.exit(1)
    
    modelSelection = sys.argv[3].lower()
    if modelSelection=="fish":
        model_path = FISH_MODEL_PATH
    elif modelSelection == "car":
        model_path = CAR_MODEL_PATH
    elif modelSelection == "ped":
        model_path = PED_MODEL_PATH
    else:
        print('{} is not a valid model path'.format(modelSelection))
        print("Usage: outputDetectorPredictions.py [videoFile] [threshhold or 'Full'] [Model: 'Fish'/'Car'/'Ped']")
        sys.exit(1)
    print("Model Path:", model_path)
    videoFile = sys.argv[1]
    videoName = videoFile[videoFile.rfind(os.sep)+1:]
    sequenceName = videoName[:-4]
    print("Names: ", videoName, sequenceName)
    detOutputName = sequenceName + "_Det_R-CNN.txt" 
    ##########Mark##########
    threshold = sys.argv[2]
    outputPath = './detection-files/'
    if not os.path.exists(outputPath):
        os.mkdir(outputPath)
        print('created output directory for: {}'.format(sequenceName))
    ########################
    #os.chdir(outputPath)#cd down a level into our info folder for this sequence
    #videoFile = videoFile # video file is now one level up, since we cd'd into the info directory
    bboxFrameList, frameWidth, frameHeight = extractFrames(videoFile, model_path)
    
    #takes in video file and writes out the detections in DETRAC format
    writeNewTxtFile(bboxFrameList, outputPath + os.sep + detOutputName)
    
    #writeMatFile(videoFile, frameWidth, frameHeight, sequenceName, threshold, model_path)
    
    #showOnVideo.compileVideo(videoFile, sequenceName + "_detections.mp4", bboxFrameList, frameWidth, frameHeight)
    
    #print('Copying detections into GMMCP_Tracker/Data/Detections/')
    #os.system('cp -ru ./Detections/. ../../gmmcp/GMMCP_Tracker/Data/Detections/')
    #print('Copying images into GMMCP_Tracker/Data/Images/')
    #os.system('cp -ru ./' + sequenceName + '/ ../../gmmcp/GMMCP_Tracker/Data/Images/')
    #print('moving video to used videos directory')
    #os.system('mv ' + videoFile + ' ./video_files/')
