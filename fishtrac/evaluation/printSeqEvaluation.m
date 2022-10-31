function [metrics, additionalInfo, metricsInfo] = printSeqEvaluation(seqName, gtInfo, stateInfo, folder)

global options tracker

metrics = [];

if(options.printEvaluationForEachSeq)
    [metrics, metricsInfo, additionalInfo] = CLEAR_MOT(gtInfo, stateInfo); 
    hotaSaveDir = ['./trackers/' tracker.trackerName '/hota-evaluation/'  seqName ]
    if!(exist(hotaSaveDir))
        mkdir(hotaSaveDir)
    end 
    matSaveFile = [ hotaSaveDir '/tracker.mat' ]
    X = stateInfo.X;
    Y = stateInfo.Y;
    W = stateInfo.W;
    H = stateInfo.H;
    save('-6', matSaveFile, 'X', 'Y', 'W', 'H');

    num_frames = num2str(numel(gtInfo.frameNums));
    fishDir = pwd();

    seqInfoString = ['{\"' seqName '\":' num_frames '}' ];
    disp(['2D Evaluation of Sequence ' seqName ' (Detection Score Threshold=' folder '):']);

    convertGtMethod = [ options.condaPath  '/fish_env/bin/python ' fishDir '/evaluation/conversion-scripts/detrac_annotations_to_mot_format.py ' seqName ' ' tracker.trackerName  ];
    system(convertGtMethod);

    thresh = num2str(options.detectionThreshold(1));
    disp(thresh);
    convertTrackerResultsMethod = [ options.condaPath  '/fish_env/bin/python ' fishDir '/evaluation/conversion-scripts/detrac_tracker_output_to_mot_format.py ' seqName ' ' tracker.trackerName ' ' thresh] ;
    system(convertTrackerResultsMethod);

    trackersDir = [fishDir '/trackers/' tracker.trackerName '/hota-evaluation'];
    gtDir = [fishDir '/trackers/' tracker.trackerName '/hota-evaluation'];

    hotaScriptDir = [fishDir '/evaluation/TrackEval/'];
    hotaMethod = [ options.condaPath  '/fish_env/bin/python ' hotaScriptDir 'scripts/run_mot_challenge.py --USE_PARALLEL False --METRICS HOTA --TRACKERS_TO_EVAL DETRAC --DO_PREPROC False --PLOT_CURVES False --TRACKERS_FOLDER ' trackersDir ' --GT_FOLDER ' gtDir ' --SEQ_INFO ' seqInfoString ];
    disp(hotaMethod);
    system(hotaMethod);
    printMetrics(metrics, metricsInfo, 1);
end
