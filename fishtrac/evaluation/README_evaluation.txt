==============================================
 trainlist (60 sequences) Detection evaluation to calculate AP score
 reference: M. Everingham, S. M. A. Eslami, L. J. V. Gool, C. K. I. Williams, J. M. Winn, and A. Zisserman. The pascal visual object classes challenge: A retrospective. IJCV, 111(1):98¨C136, 2015.
==============================================

Command parameters:

Input_1: Detector name

Input_2: Detection result folder Path
	Detection file is named as "SequenceName_Det_DetectorName.txt"
	
Input_3: path of a txt file contains which sequences will be evaluated.
	For example:
	*******************
	MVI_39501
	MVI_39511
	*******************
	
Input_4: Output Path


For example:
	- Command line: AP_DET_EVAL.exe name C:/Detections/ C:/sqList.txt C:/PRCurve/ 
	
	The output file is named as "name_detection_PR.txt"
	The format of this file is as following:
	
	***************************************
	// left is recall, right is precision
	0.000001581602796 1.000000000000000
	0.000003163205593 1.000000000000000
	0.000004744808389 1.000000000000000
	0.000006326411185 1.000000000000000
	0.000007908013981 1.000000000000000
	0.000009489616778 1.000000000000000
	0.000011071219574 1.000000000000000
	0.000012652822370 1.000000000000000
	0.000014234425166 1.000000000000000
	0.000015816027963 1.000000000000000
	0.000017397630759 1.000000000000000
	0.000018979233555 1.000000000000000
	0.000020560836352 1.000000000000000
	0.000022142439148 1.000000000000000
	0.000023724041944 1.000000000000000
	0.000025305644740 1.000000000000000
	0.000026887247537 1.000000000000000
	0.000026887247537 0.944444444444444
	0.000026887247537 0.894736842105263
	0.000028468850333 0.900000000000000
	......
	*****************************************
	
==============================================
 trainlist (60 sequences) CLEAR MOT evaluation
==============================================

threshold = 0:0.1:1

Command parameters:

Input_1: tracker name

Input_2: detector name

Input_3: Tracking result folder Path
	There are N <= 11 folders under Input_1 path, which takes threshold value as name
	*****
	0.0
	0.1
	0.2
	...
	1.0
	*****
	Tracking file under each threshold folder is named as 
		"SequenceName_LX.txt"
		"SequenceName_LY.txt"
		"SequenceName_H.txt"
		"SequenceName_W.txt"

Input_4: path of a txt file contains which threshold will be evaluated
	For example:
	*******************
	0.0
	0.3
	0.6
	1.0
	*******************
	
Input_5: path of a txt file contains which sequences will be evaluated.
	For example:
	*******************
	MVI_39501
	MVI_39511
	*******************
	
Input_6: Output Path
	tracking indicators of each threshold in one file named as "DETRAC_MOT_Result.txt"
	********
	metrics contains the following
    [1]   recall	- recall = percentage of detected targets
    [2]   precision	- precision = percentage of correctly detected targets
    [3]   FAR		- number of false alarms per frame
    [4]   GT        - number of ground truth trajectories
    [5-7] MT, PT, ML	- number of mostly tracked, partially tracked and mostly lost trajectories (*100)
    [8]   falsepositives- number of false positives (FP)
    [9]   missed        - number of missed targets (FN)
    [10]  idswitches	- number of id switches     (IDs)
    [11]  FRA       - number of fragmentations
    [12]  MOTA	- Multi-object tracking accuracy in [0,100]
    [13]  MOTP	- Multi-object tracking precision in [0,100] (3D) / [td,100] (2D)
    [14]  MOTAL	- Multi-object tracking accuracy in [0,100] with log10(idswitches)
	********
	
For example:
	- Command line: exeName.exe CEM ACF C:/TrackerResult/ C:/thresh.txt C:/sequences.txt C:/output/


==============================================
 trainlist (60 sequences) Detection evaluation
==============================================

threshold = 0:step:1

Command parameters:

Input_1: Detector name

Input_2: Detection result folder Path
	Detection file is named as "SequenceName_Det_DetectorName.txt"
	
Input_3: path of a txt file contains which sequences will be evaluated.
	For example:
	*******************
	MVI_39501
	MVI_39511
	*******************
Input_4: score step
	For example: 0.1
	
Input_5: Output Path


For example:
	- Command line: DETRAC_DET_EVAL.exe name C:/Detections/ C:/sqList.txt 0.1 C:/PRCurve/ 
	
	The output file is named as "name_detection_PR.txt"
	The format of this file is as following:
	
	***************************************
	// left is recall, right is precision
	0.5672 0.2926
	0.5672 0.2926
	0.5672 0.2927
	0.5672 0.2944
	0.5672 0.3094
	0.5666 0.3752
	0.5573 0.5571
	0.4644 0.7976
	0.1008 0.9430
	*****************************************
	
	The other output file is named as "name_thres.txt"
	Since the maximal score value may be less than 1, we create this file to record what the actual scores are used. The next TRACK SYSTEM evaluation phase will reply on this file.
	For example:
	************
	0.0
	0.1
	0.2
	0.3
	0.4
	0.5
	0.6
	0.7
	0.8
	************

==============================================
 trainlist (60 sequences) DETRAC MOT evaluation
==============================================

Command parameters:

Input_1: tracker name

Input_2: detector name

Input_3: "detectorname_thres.txt" file which is generated by detection evaluation phase.

Input_4: detectorName_detection_PR.txt path

Input_5: path of a txt file contains which sequences will be evaluated.
	For example:
	*******************
	MVI_39501
	MVI_39511
	*******************

Input_6: Tracking result folder Path
	There are N folders under Input_1 path, which takes threshold value as name.
	These names should be consistent with "detectorname_thres.txt" file
	*****
	0.0
	0.2
	0.4
	...
	1.0
	*****
	Tracking file under each threshold folder is named as 
		"SequenceName_LX.txt"
		"SequenceName_LY.txt"
		"SequenceName_H.txt"
		"SequenceName_W.txt"
		
Input_7: Output Path
		
	final average score (13 indicators) in one file named as "trackerName_detectorName_averageScore.txt"
	********
	scoreRECALL
	scorePRECISION
	scoreFAR
	scoreMT
	scorePT
	scoreML
	scoreFP
	scoreFN	
	scoreIDS	
	scoreFM	
	scoreMOTA	
	scoreMOTP	
	scoreMOTAL	
	*********	
	
For example:
	- Command line: exeName.exe TrackerName detectorName C:/detectorname_thres.txt C:/detectorname_detection_PR.txt C:/seqList.txt C:/TrackerName/ C:/output/
	

 