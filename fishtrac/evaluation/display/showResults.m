function showResults(stateInfo, curSequence, resultSavePath)

global options

if(options.showVisualResults)
    sceneInfo.imgFolder = curSequence.imgFolder;
    sceneInfo.imgFileFormat = 'img%05d.jpg';
    if(options.saveVisualResults)
        sceneInfo.outFolder = ['visual' resultSavePath '/' curSequence.seqName]; % tracking results saving path
        createPath(['visual' resultSavePath '/']);
    else
        sceneInfo.outFolder = [];
    end
    sceneInfo.frameNums = stateInfo.frameNums;
    sceneInfo.imgHeight = curSequence.imgHeight;
    sceneInfo.imgWidth = curSequence.imgWidth;

    %% Display parameters
    sceneInfo.defaultColor = [.1 .2 .9];
    sceneInfo.grey = 0.7*ones(1,3);
    sceneInfo.framePause = 0.001; % pause between frames

    sceneInfo.traceLength = 20; % overlay track from past n frames
    sceneInfo.dotSize = 20;
    sceneInfo.boxLineWidth = 3;
    sceneInfo.traceWidth = 2;

    % what to display
    sceneInfo.displayDots = options.displayDots;
    sceneInfo.displayBoxes = options.displayBoxes;
    sceneInfo.displayID = options.displayID;
    sceneInfo.displayCropouts = options.displayCropouts;
    sceneInfo.displayConnections = options.displayConnections;    

    displayTrackingResult(sceneInfo, stateInfo, curSequence.seqName);
end