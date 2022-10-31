import csv
from math import log10
import sys
import os
import numpy as np
from TrackEval.trackeval.metrics.hota import HOTA

###############################################################################
#This script is for calculating aggregate evaluation metrics over all sequences for a single tracker, meaning...
#We sum up all the underlying information from MOT results and calculate MOT scores
#as an aggregate over all sequences for each threshold. If 'train' is selected, we do this for
#every threshold run by the tracker. If 'test' is selected, then we will just evaluate your results using the best threshold
#to run this tracker on based on previous training results.
#If you want to just get the max MOTA row from the mot_results file after running a tracker on
#a single sequence over multiple thresholds, run the maxMOTArow.py file included in this directory

"""
###################
FINAL EVAL HEADERS:
0)'Rcll'
1)'Prcn'
2)'F1'
3)'FAR'
4)'GT'
5)'MT'
6)'PT'
7)'ML'
8)'FP'
9)'FN'
10)'IDs'
11)'FM'
12)'MOTA'
13)'MOTP'
14)'MOTAL'
15)'Timeouts'
16)'Failures'
###################

Additional info keys:
------------------------------
0)thresh
1)missed = FN
2)falsepositives
3)id switches
4)TP+FN = GT total = TP + FN
5)TP = Number correct(total number of matches)
6)Frames = Frames in Ground Truth
7)gtTracks = MT+PT+ML(Number of ground truth trajectories)
8)MT = mostly tracked
9)PT = partially tracked
10)ML = mostly lost
11)FRA = trajectory fragmentations
12)sumDists = total distances from bounding box to ground truth
13)'Timeouts'
14)'Failures'
-------------------------------
"""
# Output best threshold and metrics to files
def write_evals_to_file(bestScores, columnNames = []):
	#write best threshold to file
	with open('./benchmark_results.csv', 'a') as csvFile:

		csvWriter = csv.writer(csvFile, delimiter=',', quotechar='"', quoting=csv.QUOTE_MINIMAL)

		for tracker in bestScores:
			# need to make header by using field names of first tracker
			if not columnNames:
				columnNames = [metricName for metricName in bestScores[tracker]]
				csvWriter.writerow(columnNames)

			trackerMetrics = [tracker]
			for column in columnNames:	
				trackerMetrics.append(bestScores[tracker][column])

			csvWriter.writerow(trackerMetrics)

# after evaluation on training set, save best thresholds for each tracker
def write_best_thresholds_to_file(bestThresholds):
	for tracker in bestThresholds:
		threshFile = '../results/best_thresholds/' + tracker + '_best_thresh.txt'
		thr = open(threshFile, 'w')
		bestThresh = bestThresholds[tracker]
		thr.write(bestThresh)
		thr.close()

#For the best performing threshold, find speed files and calculate mean speed over all sequences
def get_avg_speed(thresh, seqGroups, tracker, detector, resultsPath):
	speedFilePath = resultsPath + thresh + '/'
	avgSpeeds = []
	for seqList in seqGroups:
		totalSpeed = 0.0 #fps
		for seq in seqList:
			readFile = speedFilePath + seq +'_speed.txt'
			with open(readFile, 'r') as f:#open speedfile for sequence and threshold
				speed = f.readline() #fps
				try:
					totalSpeed += float(speed)#sum speeds over sequences
				# cannot add if no value is stored for speed
				except ValueError:
					print('speed =', speed)
		#compute mean speed
		avgSpeeds.append(totalSpeed/(len(seqList)))
		
	avgSpeed = sum(avgSpeeds)/len(avgSpeeds)
	return avgSpeed


# use when only a specific threshold is needed
def getEvalForThisThresh(thresh, aggregateMetrics):
	#aggregateMetrics: final CLEAR eval results sorted by threshold(nested dictionary)
	bestScores = aggregateMetrics[thresh]
	bestScores['Threshold'] = thresh

	return bestScores


# Used for test 
def getBestThresh(savePath):
	threshFile = savePath + '../../best_thresholds/' + tracker + '_best_thresh.txt'
	if(not os.path.exists(threshFile)):#Best threshold must have already been computed on training set
		print(threshFile + ' does not exist for this tracker! \nThis script must be run on the training set before the test set...')
		exit(1)

	thr = open(threshFile, 'r')
	bestThresh = thr.readline()
	thr.close()

	return bestThresh


# Find the threshold which 
# 1. Produced the least timeouts
# 2. If there is a tie on 1, pick the one which produced the highest HOTA
def get_max_hota_scores(aggregateMetrics, threshList):
	bestThreshes = [] 
	minTimeouts = None
	for thresh in threshList:
		if thresh not in aggregateMetrics:
			print("FROM GET MAX HOTA: threshold {} not in additional info".format(thresh))
			continue

		metrics = aggregateMetrics[thresh]
		timeouts = metrics['Timeouts'] + metrics['Failures']

		# if new min, reset list of best thresholds to new min
		if minTimeouts is None or timeouts < minTimeouts:
			minTimeouts = timeouts
			bestThreshes = [thresh]
		# consider this threshold as well if equal to min
		elif timeouts == minTimeouts:
			bestThreshes.append(thresh)
		print("Thresh: {} Timeouts: {} Failures: {} MOTA: {} HOTA: {}".format(thresh, metrics['Timeouts'], metrics['Failures'], metrics['MOTA'], metrics['HOTA']))

	
	bestScores = None
	maxMOTA = None
	bestSingleThresh = None
	for thresh in bestThreshes:
		metrics = aggregateMetrics[thresh]
		mota = metrics['HOTA']
		if maxMOTA is None or mota > maxMOTA:
			bestScores = metrics
			maxMOTA = mota
			bestThresh = thresh
	
	bestScores['Threshold'] = bestThresh 
	print("Best threshold: {}".format(bestThresh))

	return bestScores

def process_combined_hota_metrics(combinedHotaMetrics):

	hotaEvaluator = HOTA()

	processedMetrics = {} 

	for h in hotaEvaluator.summary_fields:
		if h in hotaEvaluator.float_array_fields:
			processedMetrics[h] = ("{0:1.5g}".format(100 * np.mean(combinedHotaMetrics[h])))
		elif h in hotaEvaluator.float_fields:
			processedMetrics[h] = ("{0:1.5g}".format(100 * float(combinedHotaMetrics[h])))
		elif h in hotaEvaluator.integer_fields:
			processedMetrics[h] = ("{0:d}".format(int(combinedHotaMetrics[h])))
		else:
			raise NotImplementedError("Summary function not implemented for this field type: " + h)
	return processedMetrics 

# format input for hota aggregate evaluation
def get_hota_input(additionalInfo, seqList):

	fieldsToIgnore = get_additional_info_header()
	hotaInput = {}
	
	ignoredMetrics = set()
	for sequence in seqList:
		for thresh in additionalInfo[sequence]:
			if thresh not in hotaInput:
				hotaInput[thresh] = {}
			hotaInput[thresh][sequence] = {}
			fieldNames = list(additionalInfo[sequence][thresh].keys())
			for metric in additionalInfo[sequence][thresh]:
				if metric in fieldsToIgnore:
					continue
				# throws exception if metric value cannot be converted to an integer
				try:
					metricName, metricIntValue = tuple(metric.split('___'))
					metricIntValue = int(metricIntValue)
					# need to remove prefix 'hota-'
					metricHotaName = metricName[5:]
					if metricHotaName not in hotaInput[thresh][sequence]:
						hotaInput[thresh][sequence][metricHotaName] = {}
	
					# build dict for this metric mapping integral values to metric values
					hotaInput[thresh][sequence][metricHotaName][metricIntValue] = (float(additionalInfo[sequence][thresh][metric]))
				except ValueError:
					ignoredMetrics.add(metric)
					

			# turn dict for each metric into a sorted array of metric values(sorted by key)
			for metricHotaName in hotaInput[thresh][sequence]:
				hotaArrayValues = hotaInput[thresh][sequence][metricHotaName]
				# sort by dict key
				hotaInput[thresh][sequence][metricHotaName] = np.array([metricValue for (similarityValue, metricValue) in sorted(hotaArrayValues.items(), key = lambda x: x[0])])
	print("Ignored metrics {} in get_hota_input, metric name must end with int".format(list(ignoredMetrics)))
	return hotaInput

# for each threshold, calculate hota evaluation over all sequences
def calc_aggregate_hota(additionalInfo, seqGroups):

	hotaEvaluator = HOTA()
	aggregateHotaMetrics = {}
	for seqList in seqGroups:
		hotaInput = get_hota_input(additionalInfo, seqList)
		
		for thresh in hotaInput:
			combinedHotaMetrics = hotaEvaluator.combine_sequences(hotaInput[thresh])
			metricDict = process_combined_hota_metrics(combinedHotaMetrics)
			
			for metricName in metricDict:
				if thresh not in aggregateHotaMetrics:
					aggregateHotaMetrics[thresh] = {}
				if metricName not in aggregateHotaMetrics[thresh]:
					aggregateHotaMetrics[thresh][metricName] = []
				aggregateHotaMetrics[thresh][metricName].append(float(metricDict[metricName]))		
	acrossGroupMetrics = {}
	for thresh in aggregateHotaMetrics:
		acrossGroupMetrics[thresh] = {}
		for metricName in aggregateHotaMetrics[thresh]:
			metricList = aggregateHotaMetrics[thresh][metricName]
			acrossGroupMetrics[thresh][metricName] = sum(metricList)/len(metricList)
		
	return acrossGroupMetrics 

# sum up each metric over all sequences for each threshold
def sum_by_threshold(additionalInfo, fieldsToSum, seqList):

	aggregateInfoByThreshold = {}
	for sequence in seqList:
		for thresh in additionalInfo[sequence]:
			if thresh not in aggregateInfoByThreshold:
				aggregateInfoByThreshold[thresh] = {}
			for metric in additionalInfo[sequence][thresh]:
				if metric not in fieldsToSum:
					continue
				if metric not in aggregateInfoByThreshold[thresh]:
					aggregateInfoByThreshold[thresh][metric] = float(additionalInfo[sequence][thresh][metric])
				else:
					aggregateInfoByThreshold[thresh][metric] += float(additionalInfo[sequence][thresh][metric])

	return aggregateInfoByThreshold

# for each threshold, calculate clear mot evaluation over all sequences 
def calc_aggregate_clear_mot(additionalInfo, seqGroups):
	aggregateClearMotMetrics = {}
	
	clearMotFields = get_additional_info_header()
	for seqList in seqGroups:
		aggregateClearMotAdditionalInfoByThreshold = sum_by_threshold(additionalInfo, clearMotFields, seqList)
		#For each threshold, calculate agrregate CLEAR metrics
		for thresh, values in aggregateClearMotAdditionalInfoByThreshold.items():

			metricDict = {}
			
			metricDict['Rcll'] = (values['TP']/values['TP+FN'])*100 #recall
			if(values['FP']!=0 or values['TP']!=0):
				metricDict['Prcn'] = (values['TP']/(values['FP']+values['TP']))*100 #precision
			#No correct tracks
			else:
				metricDict['Prcn'] = float('nan')
			#needed to compute F1 (for clarity)
			recall = metricDict['Rcll'] 
			precision = metricDict['Prcn'] 

			if (recall != 0 or precision !=0):
				metricDict['F1'] = 2 * (recall * precision)/(recall + precision)
			else:#No correct tracks
				metricDict['F1'] = float('nan')

			#false alarm rate(per frame)
			metricDict['FAR'] = values['FP']/values['Frames'] 
			#number of trajectories in ground truth
			metricDict['GT'] = values['gtTracks'] 
			#Mostly Tracked as a percentage of total tracks in ground truth
			metricDict['MT'] = (values['MT']/values['gtTracks'])*100 
			#Partially Tracked as a percentage of total tracks in ground truth
			metricDict['PT'] = (values['PT']/values['gtTracks'])*100 
			#Mostly Lost as a percentage of total tracks in ground truth
			metricDict['ML'] = (values['ML']/values['gtTracks'])*100 
			metricDict['FP'] = values['FP'] #false positives
			metricDict['FN'] = values['missed'] #false negatives
			metricDict['IDs'] = values['idswitches'] #ID switches
			metricDict['FM'] = values['FRA'] #fragmented trajectories
			metricDict['MOTA'] = (1-(values['missed']+values['FP']+values['idswitches'])\
									/values['TP+FN'])*100 #MOT accuracy
			if values['TP'] != 0:
				metricDict['MOTP'] = (values['sumDists']/values['TP'])*100 #MOT Precision
			else:#No correct tracks
				metricDict['MOTP'] = float('nan')

			metricDict['MOTAL'] = (1-(values['missed']+values['FP'] + log10(values['idswitches']+1))\
									/values['TP+FN'])*100 #MOTA log10 ID switches
			metricDict['Timeouts'] = values['timeout']
			metricDict['Failures'] = values['failure']
			
			for metricName in metricDict:
				if thresh not in aggregateClearMotMetrics:
					aggregateClearMotMetrics[thresh] = {}
				if metricName not in aggregateClearMotMetrics[thresh]:
					aggregateClearMotMetrics[thresh][metricName] = []
				aggregateClearMotMetrics[thresh][metricName].append(float(metricDict[metricName]))
			
	acrossGroupMetrics = {}
	for thresh in aggregateClearMotMetrics:
		acrossGroupMetrics[thresh] = {}
		for metricName in aggregateClearMotMetrics[thresh]:
			metricList = aggregateClearMotMetrics[thresh][metricName]
			acrossGroupMetrics[thresh][metricName] = sum(metricList)/len(metricList)
		
	return acrossGroupMetrics
	
# Calculate FINAL metrics for each threshold
def calc_aggregate_metrics(additionalInfo, seqGroups):

	aggregateClearMotMetrics = calc_aggregate_clear_mot(additionalInfo, seqGroups)
	aggregateHotaMetrics = calc_aggregate_hota(additionalInfo, seqGroups)
	aggregateMetrics = {}
	# combine dictionaries
	for thresh in aggregateClearMotMetrics:

		aggregateMetrics[thresh] = {}

		for metric in aggregateClearMotMetrics[thresh]:
			aggregateMetrics[thresh][metric] = aggregateClearMotMetrics[thresh][metric]
		for metric in aggregateHotaMetrics[thresh]:
			aggregateMetrics[thresh][metric] = aggregateHotaMetrics[thresh][metric]
	
	return aggregateMetrics

# get the fields that are used in clear mot evaluation
def get_additional_info_header():
	headersFileName = '../evaluation/additional_info_headers.txt'
	header = []

	with open(headersFileName, 'r') as f:
		header = csv.reader(f).__next__()

	return header

# read from additional info file into dictionary
def read_additional_info_for_sequence(additionalInfoFileName):

	# want to return a dictionary of thresholds and metrics
	additionalInfoForSequence = {}

	with open(additionalInfoFileName) as fAddInfo:

		additionalInfoReader = csv.DictReader(fAddInfo, delimiter = ',')

		for row in additionalInfoReader:
			# thresh needs to take the format '0.x'
			thresh = "{:.1f}".format(float(row['thresh']))
			additionalInfoForSequence[thresh] = {}
			for metric in row:
				if metric == 'thresh':
					continue
				additionalInfoForSequence[thresh][metric] = row[metric]

	return additionalInfoForSequence
	
def find_thresholds_with_no_result(additionalInfoFileName,  threshList):

	# tracker could not produce any tracks on this threshold and sequence
	threNotInSeq = set(threshList) 
	# Gather results for this sequence 
	with open(additionalInfoFileName) as fAddInfo:

		additionalInfoReader = csv.DictReader(fAddInfo, delimiter = ',')

		# find thresholds where tracker could not produce a result in tim
		for row in additionalInfoReader:
			# Sometimes, on very high thresholds, DETRAC experiment produces
			# no results and therefore doesn't even save an empty row
			# we will treat this as an empty result
			try:
				threshFloatRepresentation = float(row['thresh'])
				rmv = "{:.1f}".format(threshFloatRepresentation)
				threNotInSeq.remove(rmv)
			# When detrac does not produce a result, no line is stored and float cast fails
			except ValueError:
				print('Warning: DETRAC did not produce a result')

	return threNotInSeq

def read_seq_list(seqFileName):
	
	# get sequence names
	print('getting seq list')
	seqGroups = []
	if seqFileName[0] == "_": # User wants to evaluate a single sequence
		print("User wants to evaluate single sequence: {}".format(seqFileName))
		# trin off undetscore and .txt from sequence file name
		seqGroups = [[seqFileName[1:-4]]]
	else: # user wants to evaluate a list of sequences
		seqFileName = '../evaluation/seqs/' + seqFileName
		seqList = []

		with open(seqFileName) as fSeq:
			csv_reader = csv.reader(fSeq, delimiter='\n')
			for row in csv_reader:
				if row[0] == '#':  #delimits groups
					seqGroups.append(seqList)
					seqList = []
					continue
				seqList.append(row[0]) # seq file is a list of sequence names, get first(and only) item in each row 
		seqGroups.append(seqList)
	return seqGroups

def read_tracker_results(seqFileName, threshList, resultsPath):
	"""
	Args:
		seqFile(string) = name of sequence file(.txt)
		threshFile(string) = file name of thresholds evaluated over(.txt)
		resultsPath(string) = path leading to info needed to calculate CLEAR eval
	Returns:
		additionalInfo
		threshList(list(str)) = list of thresholds
		seqList(list(string)) = list of sequence names
		seqsNotRun(list)      = list of sequences without any results for this tracker
	"""
	# List of sequence names
	seqGroups = read_seq_list(seqFileName)
	print("seqGroups", seqGroups)

	# Create a set of thresholds to ignore(ignore threshold if tracker does not produce any tracks for one of the sequences)
	ignore = set([]) 
	seqsNotRun = []

	# Gather additionalinfo for each sequence and threshold
	additionalInfo = {}
	for seqList in seqGroups: 
		for sequence in seqList: 

		    print("Getting additional info results for {}".format(sequence))
		    additionalInfoFileName = resultsPath + sequence + '_additional_info.txt' 

		    # Need to keep track of which sequences have not actually been evaluated over for this tracker
		    if not os.path.isfile(additionalInfoFileName):
			    print("Tracker has no results for this sequence: {}".format(additionalInfoFileName))
			    seqsNotRun.append(sequence)
			    continue #Don't try to open a result file if the tracker has no results for that seq

		    # build additional info dict for this sequence, store results for every threshold
		    additionalInfo[sequence] = read_additional_info_for_sequence(additionalInfoFileName); firstThresh = list(additionalInfo[sequence].keys())[0]; print("Sequence", sequence, "First thresh", firstThresh, "Timeouts for first thresh", additionalInfo[sequence][firstThresh]['timeout'], "Failures", additionalInfo[sequence][firstThresh]['failure'])

		    threNotInSeq = find_thresholds_with_no_result(additionalInfoFileName, threshList)
		    ignore = ignore.union(threNotInSeq)#build set of thresholds to ignore

	# Remove all data for thresholds which the tracker could not return a track for one of the sequences
	print('ignore due to no results produced', ignore)
	for key in additionalInfo:
		if key in ignore:
			additionalInfo[key] = None

	return additionalInfo, threshList, seqGroups, seqsNotRun

#Sum over corresponding thresholds between sequences
def benchmark_evaluation(sequenceFile='trainlist-full.txt', threshList=[0.5], testOrTrain='train', tracker = 'KPD', resultsDir = "results", detector = 'R-CNN', ):
	"""
	Args:
		sequenceFile(string): Sequences to be evaluated
		threshFile(string): File containing list of thresholds over which tracker was tested
		testOrTrain: Evaluation for training set or testing set
		tracker(string): Multiple Object Tracker used on sequences
		detector(string): Detector used on sequences

	Returns:
		bestThresh(float): threshold which performed best on training set
		bestScores(dictionary): dictionary where keys are CLEAR metrics and values are scores
		avgSpeed(double): average speed over all sequences of tracker on best performing threshold(fps)
	"""
	testOrTrain = testOrTrain.lower() #lower case
	resultsPath = '../{}/{}/{}/'.format(resultsDir, tracker, detector)
	print("Getting results from: {}".format(resultsPath))

	# for use on the training set
	if testOrTrain == 'train':
		# get raw results from each sequence and threshold(all underlying info)
		additionalInfo, threshList, seqGroups, seqsNotRun = read_tracker_results(sequenceFile, threshList, resultsPath)
		# Tracker has no results for a sequence in this list, cant evaluate this tracker until experiment is run
		if seqsNotRun: 
			print('No results for ', tracker, ' on:')
			for seq in seqsNotRun:
				print(seq)
			print('please run experiment')
			return -1
		# Tracker has results for every sequence in this training set
		else:
			aggregateMetrics = calc_aggregate_metrics(additionalInfo, seqGroups)
			bestScores = get_max_hota_scores(aggregateMetrics, threshList) 
			bestThresh = bestScores['Threshold']
			print("best Thresh in scores", bestThresh)
			avgSpeed = get_avg_speed(bestThresh, seqGroups, tracker, detector, resultsPath) 

			bestScores['Speed(fps)'] = avgSpeed

	# validate that the best thresh calculated for the training set is also a good choice for the test data
	# just want to get best thresh, then reevaluate test results(read_tracker_results, parse_additional_info, calcAggregate) 
	# but only looking at best thresh
	elif testOrTrain == 'test':
		bestThresh = getBestThresh(resultsPath) 
		additionalInfo, threshList, seqGroups, seqsNotRun = read_tracker_results(sequenceFile, threshList, resultsPath) 
		if seqsNotRun: 
			print('error: No results for ', tracker, ' on following sequences:')
			for seq in seqsNotRun:
				print(seq)
			print('please run experiment')
			return -1
		else: 
			aggregateMetrics = calc_aggregate_metrics(additionalInfo, seqGroups) 
			bestScores = getEvalForThisThresh(bestThresh, aggregateMetrics) 
			avgSpeed = get_avg_speed(bestThresh, seqGroups, tracker, detector, resultsPath)
			bestScores['Speed(fps)'] = avgSpeed

	# incorrect command line argument
	else:
		print('Please try again, choose either test or train')
		print("Usage:", sys.argv[0], "sequenceFilePrefix thresh/'full'  tracker/'full' test/train")
		exit(2)
	print("best scores",bestScores)

	return bestScores 

def parse_user_tracker_selection(userSelection):
	
	trackerList = os.listdir('../trackers/')

	if sys.argv[2].lower() == 'all':
		pass
	elif sys.argv[2].upper() in trackerList:	
		trackerList = [sys.argv[2]]
	else:
		tempTrackerList = userSelection.split(',')
		for tracker in tempTrackerList:
			if tracker not in trackerList:
				print("INVALID TRACKER NAME...")
				sys.exit(2)
		trackerList = tempTrackerList

	return trackerList

if __name__ == "__main__":
	if len(sys.argv) < 4:
		print("Usage: {} sequenceFilePrefix/_seqName 'trackerOne,trackerTwo_...'/'all' test/train [resultsDir]".format(sys.argv[0]))
		sys.exit(2)

	# unpack commandline argements
	seqFileName = sys.argv[1] + '.txt'
	trackerList = []
	trackerList = parse_user_tracker_selection(sys.argv[2])
	threshList = ['0.0','0.1', '0.2', '0.3', '0.4', '0.5', '0.6', '0.7', '0.8', '0.9' ]
	resultsDir = "results"
	if len(sys.argv) == 5:
		resultsDir = sys.argv[5]

	testOrTrain = sys.argv[3]
	
	with open('./benchmark_results.csv', 'w') as csvFile:
		pass

	evaluations = {}
	bestThresholds = {}
	# evaluate each tracker
	for tracker in trackerList:
		print('tracker:',tracker)
		print('threshList:', threshList)
		
		evaluations[tracker] = benchmark_evaluation(seqFileName, threshList, testOrTrain, tracker, resultsDir)
		print('best thresh in eval:', evaluations[tracker]['Threshold'])
		bestThresholds[tracker] = evaluations[tracker]['Threshold']
			
	if testOrTrain.lower() == 'train':
		print("bext trhesholds dict", bestThresholds)
		write_best_thresholds_to_file(bestThresholds)
	write_evals_to_file(evaluations)

"""
---------------------
command line template:
python benchmark_evaluation.py trainlist-full GOG train
---------------------
"""
