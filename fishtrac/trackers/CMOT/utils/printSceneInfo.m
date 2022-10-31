function printSceneInfo()
% 
% (C) Anton Andriyenko, 2012
%
% The code may be used free of charge for non-commercial and
% educational purposes, the only requirement is that this text is
% preserved within the derivative work. For any other purpose you
% must contact the authors for permission. This code may not be
% redistributed without written permission from the authors.
% prints information about the scene

% sceneInfo.targetSize=10;                % target 'radius'
% 
% 
% % sceneInfo.imgFolder=fullfile(dbfolder,dataset,'Crowd_PETS09','S2','L1','Time_12-34','View_001',filesep); % 23
% sceneInfo.imgFolder=fullfile(dbfolder,dataset,'Crowd_PETS09','S3','Multiple_Flow','Time_12-43','View_001',filesep); % 80
% 
% sceneInfo.imgFileFormat='frame_%04d.jpg';
% sceneInfo.frameNums=1:107;
% % sceneInfo.frameNums=0:794;
% [sceneInfo.imgHeight, sceneInfo.imgWidth, ~]= ...
%     size(imread([sceneInfo.imgFolder sprintf(sceneInfo.imgFileFormat,sceneInfo.frameNums(1))]));
% sceneInfo.trackingArea=[1 sceneInfo.imgWidth 1 sceneInfo.imgHeight];   % tracking area
% 
% %% load detections
% detections=parseDetections(detfile); fr=1:length(detections);
% % fr=1:50; detections=detections(fr);  % !!!!!!! REMOVE
% F=size(detections,2);
% stateInfo.F=F;                          % number of frames
% 
% 
global sceneInfo


%% 
% printMessage(1,'Sequence: \t%s\n',sceneInfo.seqName);
printMessage(2, 'Frames: ......  %i\n',length(sceneInfo.frameNums));
printMessage(2, 'Image size: ..  %i x %i\n',sceneInfo.imgWidth,sceneInfo.imgHeight)

% sceneInfo

%%
end