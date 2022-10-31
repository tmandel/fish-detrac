import csv
import sys
import os
import cv2
import shutil
from scipy.io import loadmat

PYTHON_PATH = sys.executable 
"""
MOT result keys:
0)'Thresh'
1)'Recall'
2)'Precision'
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

Additional info keys:
------------------------------
0)thresh
1)missed = FN
2)falsepositives
3)id switches
4)sumg = GT total = TP + FN
5)Nc = Number correct(total number of matches)
6)Fgt = Frames in Ground Truth
7)Ngt = MT+PT+ML(Number of ground truth trajectories)
8)MT = mostly tracked
9)PT = partially tracked
10)ML = mostly lost
11)FRA = trajectory fragmentations
12)sumDists = total distances from bounding box to ground truth
-------------------------------
"""
def save_additional_info(additionalInfo, metricsHeader, evaluateTrackerConfig):
    trackerName = evaluateTrackerConfig['tracker']
    sequenceName = evaluateTrackerConfig['sequence']
    if evaluateTrackerConfig['copyTracker']:
        trackerName = trackerName + '-' + sequenceName
    
    resultsDir = './results/' + trackerName + '/R-CNN/' 
    additionalInfoFileName = resultsDir + sequenceName + '_additional_info.txt'
   
    # overwrite old file with new results
    with open(additionalInfoFileName, 'w') as f:
        resWriter = csv.writer(f)
        resWriter.writerow(metricsHeader)

        for thresh in additionalInfo:
            resRow = []

            for metric in metricsHeader:
                resRow.append(additionalInfo[thresh][metric])

            resWriter.writerow(resRow) 

def clean_up_copied_tracker_after_concurrent_run(tracker, seq):
    os.system("./cleanup_after_concurrent_run.sh {} {}".format(tracker, seq))

def save_empty_coordinates(tracker, thresh, seq):
    resPath = './results/'  +tracker + '/R-CNN/'+ thresh + '/'
    print(resPath)
    try:
        os.mkdir(resPath)
    except FileExistsError:
        pass
    coordPath = resPath  + seq
    lx = coordPath + '_LX.txt'
    ly = coordPath + '_LY.txt'
    w = coordPath + '_w.txt'
    h = coordPath + '_H.txt'
    speedFile = coordPath + '_speed.txt'
    with open(lx, 'w') as fp:
        pass
    with open(ly, 'w') as fp:
        pass
    with open(w, 'w') as fp:
        pass
    with open(h, 'w') as fp:
        pass
    method = "echo '0' > " + speedFile
    os.system(method)

def read_empty_hota_output(hotaEvaluationDirectory):
    emptyHotaMetrics = {}
    emptyHotaMetricsFileName = os.path.join(hotaEvaluationDirectory, "pedestrian_detailed.csv")
    print(emptyHotaMetricsFileName)
    with open(emptyHotaMetricsFileName, "r") as f:
        # empty hota results is just a single header line and row of values
        hotaCSV = csv.reader(f, delimiter = ',')
        headerRow = hotaCSV.__next__()
        valuesRow = hotaCSV.__next__()
        for field, value in zip(headerRow, valuesRow):
            field = 'hota-' + field 
            emptyHotaMetrics[field] = value

    print("empty hota metrics:", emptyHotaMetrics)

    return emptyHotaMetrics

def create_empty_hota_inputs(emptyHotaInputsDir, fishDetracDirectory, trackerName, sequenceName):
    # make hota inputs dir
    try:
        os.mkdir(emptyHotaInputsDir)
    except FileExistsError:
        pass
    # Create empty tracker results file for hota to read in
    emptyTrackerResultFileName = os.path.join(emptyHotaInputsDir, "tracker.txt")
    # empty file creation
    with open(emptyTrackerResultFileName, "w") as f:
        pass
    
    # Convert existing gt file to mot format for hota to read in
    os.system("{} {}/evaluation/conversion-scripts/detrac_annotations_to_mot_format.py {} {}".format(PYTHON_PATH, fishDetracDirectory, sequenceName, trackerName))

def get_empty_hota_metrics(trackerName, sequenceName, numFrames):

    # We need to setup a folder with gt.txt and tracker.txt for HOTA
    # to evaluate on(the tracker.txt file will be empty)
    fishDetracDirectory = os.path.dirname(os.path.realpath(__file__))
    emptyHotaInputsDir = os.path.join(fishDetracDirectory, "trackers", trackerName, 'hota-evaluation', sequenceName)
    # make folder for hota to read from
    try:
        os.mkdir(emptyHotaInputsDir)
    except FileExistsError:
        pass
    # save input files for hota to read from
    create_empty_hota_inputs(emptyHotaInputsDir, fishDetracDirectory, trackerName, sequenceName)

    # this is necessary in order to call hota 
    seqInfoCommandLine = '{' + '\\"{0}\\":{1}'.format(sequenceName, numFrames) + '}'
    hotaEvaluationDirectory = os.path.join(fishDetracDirectory, "trackers", trackerName, 'hota-evaluation')

    # this is the command we will execute to get empty hota results
    hotaMethod = "{0} {1}/evaluation/TrackEval/scripts/run_mot_challenge.py --USE_PARALLEL False --METRICS HOTA --TRACKERS_TO_EVAL DETRAC --DO_PREPROC False --PLOT_CURVES False --TRACKERS_FOLDER {2} --GT_FOLDER {2} --SEQ_INFO {3}".format(PYTHON_PATH, fishDetracDirectory, hotaEvaluationDirectory, seqInfoCommandLine)
    ret = os.system(hotaMethod)
    print("\nHOTA RETURNED: " + str(ret))
   
    emptyHotaMetrics = read_empty_hota_output(hotaEvaluationDirectory)
   
    return emptyHotaMetrics

def read_clear_mot_header():
    # Read the first line(header row) of additional info csv into a list
    headersFileName = './evaluation/additional_info_headers.txt'

    header = []
    with open(headersFileName) as headerFile:
        header = csv.reader(headerFile).__next__()

    return header

def get_additional_info_header(additionalInfo):
    metricsHeader = read_clear_mot_header()
    for metric in additionalInfo:
        if metric not in metricsHeader:
            metricsHeader.append(metric)
    
    return metricsHeader

def create_empty_additional_info_result(thresh, gtNumBoxes, gtNumFrames, gtNumTracks, timeout, fail):
    emptyAdditionalInfo = {}
    emptyAdditionalInfo['thresh'] = thresh
    emptyAdditionalInfo['missed'] = gtNumBoxes
    emptyAdditionalInfo['idswitches'] = 0
    emptyAdditionalInfo['TP+FN'] = gtNumBoxes 
    emptyAdditionalInfo['TP'] = 0
    emptyAdditionalInfo['FP'] = 0
    emptyAdditionalInfo['Frames'] = gtNumFrames 
    emptyAdditionalInfo['gtTracks'] = gtNumTracks
    emptyAdditionalInfo['timeout'] = timeout
    emptyAdditionalInfo['failure'] = fail
    emptyAdditionalInfo['sumDists'] = 0 
    emptyAdditionalInfo['MT'] = 0 
    emptyAdditionalInfo['PT'] = 0 
    emptyAdditionalInfo['FRA'] = 0 
    emptyAdditionalInfo['ML'] = gtNumTracks 
    
    return emptyAdditionalInfo

def create_empty_clear_mot_row(thresh, gtNumTracks, gtNumBoxes):
    emptyResultRow = [thresh, 0, 0, 0, gtNumTracks, 0,0,gtNumTracks, 0, gtNumBoxes, 0, 0, 0,0,0]
    # 0)'Thresh' 1)'Recall' 2)'Precision' 3)'FAR' 4)'GT' 
    # 5)'MT' 6)'PT' 7)'ML' 8)'FP' 9)'FN' 
    # 10)'IDs' 11)'FM' 12)'MOTA' 13)'MOTP' 14)'MOTAL'
    
    return emptyResultRow

def parse_gt(gtInfo):
    print(gtInfo['gtInfo'][0][0][0].shape)
    gtNumFrames, gtNumTracks  = gtInfo['gtInfo'][0][0][0].shape

    gtNumBoxes = 0
    for frame in gtInfo['gtInfo'][0][0][3]:
        for box in frame:
            if box != 0.:
                gtNumBoxes += 1

    return gtNumFrames, gtNumTracks, gtNumBoxes

def load_gt_info_from_file(seq):
    gtFileName = './DETRAC-Train-Annotations-MAT/' + seq + '.mat'
    print('Loading mat file: ', gtFileName+'...')
    gtInfo = loadmat(gtFileName)
    
    return gtInfo

def get_gt_info(seq):
    gtInfo = load_gt_info_from_file(seq)
    gtNumFrames, gtNumTracks, gtNumBoxes = parse_gt(gtInfo)

    return gtNumFrames, gtNumTracks, gtNumBoxes

# TODO: ugly long function need to further modularize

def get_result_failure(evaluateTrackerConfig, timeout, fail):

    # unpack config
    thresh = evaluateTrackerConfig['thresh']
    seq = evaluateTrackerConfig['sequence']
    resultsPath = evaluateTrackerConfig['resultsPath']
    tracker = evaluateTrackerConfig['tracker']
    # get gt info needed to generate empty hota row
    gtNumFrames, gtNumTracks, gtNumBoxes = get_gt_info(seq)

    # Whereas clear mot metrics calculate MOTA, MOTAL, etc, additional info is the information used to 
    # compute these metrics
    emptyAdditionalInfo = create_empty_additional_info_result(thresh, gtNumBoxes, gtNumFrames, gtNumTracks, timeout, fail)

    # get empty hota metrics
    emptyHotaMetrics = {} 
    emptyHotaMetrics = get_empty_hota_metrics(tracker, seq, gtNumFrames)

    # merge two dictionaries
    emptyAllAdditionalInfo = {}
    for metric in emptyAdditionalInfo:
        emptyAllAdditionalInfo[metric] = emptyAdditionalInfo[metric] 
    for metric in emptyHotaMetrics:
        emptyAllAdditionalInfo[metric] = emptyHotaMetrics[metric] 
    
    save_empty_coordinates(tracker, thresh, seq)

    return emptyAllAdditionalInfo 

def get_result_success(evaluateTrackerConfig):

    trackerName = evaluateTrackerConfig['tracker']
    sequenceName = evaluateTrackerConfig['sequence']

    # concurrent run changes name of tracker directory
    if evaluateTrackerConfig['copyTracker']:
        trackerName = trackerName + '-' + sequenceName 

    # Location where DETRAC saves its evaluation
    trackerDir = './trackers/' + trackerName + '/'
    hotaEvaluationFile = trackerDir + 'hota-evaluation/pedestrian_detailed.csv'
    clearMotAdditionalInfoFile = trackerDir + 'clear-mot/additional_info.txt' 
    additionalInfoSingleRun = {}

    with open(hotaEvaluationFile) as f:
        dictReader = csv.DictReader(f)
        for row in dictReader:
            for metric in row:
                additionalInfoSingleRun['hota-' + metric] = row[metric]

    with open(clearMotAdditionalInfoFile) as f: 
        dictReader = csv.DictReader(f)
        for row in dictReader:
            for metric in row:
                additionalInfoSingleRun[metric] = row[metric]

    return additionalInfoSingleRun

def evaluate_tracker(evaluateTrackerCommand, evaluateTrackerConfig, timed):
    # Here is where we hand control off to OCTAVE!
    if timed:
        print('./timedEval {}'.format(evaluateTrackerCommand))
        ret = os.system('./timedEval {}'.format(evaluateTrackerCommand))
    else:
        ret = os.system(evaluateTrackerCommand)

    print(evaluateTrackerCommand)
    print('run tracker command returned: {}'.format(ret)) 

    additionalInfoSingleRun = {}

    # Success
    if(ret == 0):
        additionalInfoSingleRun = get_result_success(evaluateTrackerConfig)
    # Child exited with error while processing detections (often from no detections on frame)
    elif(ret == 256): 
        additionalInfoSingleRun = get_result_failure(evaluateTrackerConfig, timeout=0, fail=1)
    # exit code 5 
    elif(ret == 1280): 
        additionalInfoSingleRun = get_result_failure(evaluateTrackerConfig, timeout=1, fail=0)
    else:
        print("Unknown exit code: ", ret)

    return additionalInfoSingleRun

def get_evaluate_tracker_command(experimentInfo, evaluateTrackerConfig):

    command = experimentInfo['octaveCommand'] + ' DETRAC_experiment.m '

    # If the tracker has been copied, then we need to point DETRAC to evaluate the copied tracker
    if experimentInfo['copyTrackerConcurrentRun']:
        command += '{0}-{2} {1} {2} '.format( evaluateTrackerConfig['tracker'],\
                                              evaluateTrackerConfig['thresh'],\
                                              evaluateTrackerConfig['sequence'] )
    else:
        command += '{0} {1} {2} '.format( evaluateTrackerConfig['tracker'],\
                                          evaluateTrackerConfig['thresh'],\
                                          evaluateTrackerConfig['sequence'] )
    # finally
    command += '> ./output/{0}/{1}/{2}.txt'.format( evaluateTrackerConfig['tracker'],\
                                                    evaluateTrackerConfig['thresh'],\
                                                    evaluateTrackerConfig['sequence'] )

    return command

def create_empty_sequence_result_files(resultsPath, seq):
    with open(resultsPath + seq + '_mot_result.txt', 'w'):
        pass

def copy_tracker_for_concurrent_run(tracker, seq):
    os.system("./copy_tracker_concurrent_run.sh {} {}".format(tracker, seq))

def set_up_copied_tracker_for_concurrent_run(tracker, seq, experimentInfo):
    copiedTrackerName = tracker + '-' + seq
    copiedTrackerResultsPath = './results/' + copiedTrackerName + '/R-CNN/'
    copiedTrackerOutputPath = './output/' + copiedTrackerName + '/'
    copy_tracker_for_concurrent_run(tracker, seq)
    set_up_dirs_for_tracker(copiedTrackerName, copiedTrackerResultsPath, copiedTrackerOutputPath, experimentInfo['threshList'])

def remove_previous_sequence_results(resultsPath, outputPath, seq):
    print("results path", resultsPath)
    print("output path", outputPath)
    print("seq", seq)
    os.system("rm -f {0}*_{1}.txt".format(outputPath, seq))
    # remove additional info and mot results
    os.system("rm -f {0}{1}*".format(resultsPath, seq))
    for f in os.scandir(resultsPath):
        if f.is_dir():
            os.system("rm -rf {0}/{1}*".format(f.path, seq))

def set_up_dirs_for_tracker(tracker, resultsPath, outputPath, threshList):
    # evaluation text logs 
    try:
        os.mkdir('./output/')
    except FileExistsError:
        pass
    try:
        os.mkdir(outputPath)
    except FileExistsError:
        pass
    # output tracks 
    try:
        os.mkdir('./results/')
    except FileExistsError:
        pass
    try:
        os.mkdir('./results/' + tracker)
    except FileExistsError:
        pass
    try:
        os.mkdir(resultsPath)
    except FileExistsError:
        pass
    # clear mot info
    additionalInfoPath = './trackers/' + tracker + '/clear-mot/'
    try:
        os.mkdir(additionalInfoPath)
    except FileExistsError:
        pass
    # hota evaluation files
    try:
       os.mkdir('./trackers/' + tracker + '/hota-evaluation/')
    except FileExistsError:
        pass
    for thresh in threshList:
        try:
            os.mkdir(outputPath + thresh) 
        except FileExistsError:
            pass

### EXPERIMENT WRAPPER
def experiment_wrapper(experimentInfo):
    
    # first time an evaluation is run, metric header needs to be constructed
    fullyLoadedMetrics = False
    metricsHeader = []

    for tracker in experimentInfo['trackerList']:

        # set paths to write out results
        outputPath = './output/' + tracker + '/'
        resultsPath = './results/' + tracker + '/R-CNN/'
        set_up_dirs_for_tracker(tracker, resultsPath, outputPath, experimentInfo['threshList'])

        for seq in experimentInfo['seqList']:

            # set up copy tracker
            if experimentInfo['copyTrackerConcurrentRun']:
                resultsPath = './results/' + tracker + '-' + seq + '/R-CNN/'
                set_up_copied_tracker_for_concurrent_run(tracker, seq, experimentInfo)

            # clear out old results
            remove_previous_sequence_results(resultsPath, outputPath, seq)
            create_empty_sequence_result_files(resultsPath, seq)

            additionalInfo = {}

            for thresh in experimentInfo['threshList']:
                  
                # make dir for results on this thresh
                if not os.path.exists("{}/{}/".format(resultsPath, thresh)):
                    os.mkdir("{}/{}/".format(resultsPath, thresh))

                # Info about running on this sequence,tracker,thresh combination
                evaluateTrackerConfig = {'tracker': tracker,\
                                         'thresh': thresh,\
                                         'sequence': seq,\
                                         'resultsPath': resultsPath,\
                                         'copyTracker': experimentInfo['copyTrackerConcurrentRun']}

                # EVALUATE
                evaluateTrackerCommand = get_evaluate_tracker_command(experimentInfo, evaluateTrackerConfig)
                additionalInfoSingleRun = evaluate_tracker(evaluateTrackerCommand, evaluateTrackerConfig, experimentInfo['timed']) 
                additionalInfo[thresh] = additionalInfoSingleRun
              
                # need to build metric orderring for output on first evaluation run
                if not fullyLoadedMetrics:
                    metricsHeader = get_additional_info_header(additionalInfoSingleRun)

                # SAVE ADDITIONAL INFO
                save_additional_info(additionalInfo, metricsHeader, evaluateTrackerConfig)

            if copyTrackerConcurrentRun:
                clean_up_copied_tracker_after_concurrent_run(tracker, seq)

def parse_seq_file(seqFileName):
    seqList = []
    with open(seqFileName) as fSeq:
        csv_reader = csv.reader(fSeq, delimiter='\n')
        for row in csv_reader:
            seqList.append(row[0])

    return seqList

def get_seq_list(seqPrefix):
    seqList = []
    if seqPrefix[0] == '_':
        seqList = [seqPrefix[1:]]
    else:
        seqFileName = './evaluation/seqs/' + sys.argv[3] + '.txt'
        seqList = parse_seq_file(seqFileName)
    
    return seqList

def get_thresh_list(threshSelection):
    threshList = ['0.0', '0.1', '0.2', '0.3','0.4', '0.5', '0.6', '0.7', '0.8', '0.9']
    if threshSelection == 'SOME':
        threshList = ['0.6', '0.7', '0.8', '0.9']
    elif threshSelection != 'ALL':
        thresh = '{:.1f}'.format(float(threshSelection))
        threshList = [thresh]

    return threshList

def get_tracker_list(trackerSelection):
    trackerList = os.listdir("./trackers/")
    if trackerSelection in set(trackerList): #make sure selected tracker is available
        trackerList = [sys.argv[1].upper()]
    elif trackerSelection != 'ALL': #invalid input
        print('Quitting, tracker "{}" is not recognized'.format(trackerSelection))
        sys.exit(2)

    return trackerList

if __name__ == "__main__":
    if len(sys.argv) < 4:
        print('usage: experiment_wrapper.py tracker/"all" thresh/"all" seqFilePrefix/_seqFile [octave_command] [untimed/timed] [copyTracker/dontcopyTracker]')
        sys.exit(2)

    # What is the command line octave being used?
    octaveCommand="octave-cli"
    if len(sys.argv) > 4:
        octaveCommand = sys.argv[4]

    # will this test be timed?
    timed = True
    if len(sys.argv) > 5:
        if sys.argv[5].lower() == "untimed":
            timed = False

    # Are we copying the tracker to run concurrently over different sequences
    copyTrackerConcurrentRun = False
    if len(sys.argv) > 6:
        if sys.argv[6].lower() == "copytracker":
            copyTrackerConcurrentRun = True

    trackerList = get_tracker_list(sys.argv[1].upper())
    threshList = get_thresh_list(sys.argv[2].upper())
    seqList = get_seq_list(sys.argv[3])

    experimentInfo = { 'trackerList': trackerList,\
                       'threshList': threshList, \
                       'seqList': seqList,\
                       'timed':timed,\
                       'copyTrackerConcurrentRun':copyTrackerConcurrentRun, \
                       'octaveCommand':octaveCommand }
    experiment_wrapper(experimentInfo)
