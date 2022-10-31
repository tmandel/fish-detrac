function printSceneInfo()
% prints information about the scene
% 
% 
% 
global sceneInfo detections


%% 
% printMessage(1,'Sequence: \t%s\n',sceneInfo.seqName);
printMessage(2, 'Frames: ........  %i (%i .. %i)\n',length(sceneInfo.frameNums),sceneInfo.frameNums(1),sceneInfo.frameNums(end));
printMessage(2, 'Image size: ....  %i x %i\n',sceneInfo.imgWidth,sceneInfo.imgHeight)
printMessage(2, 'Detections file:   %s\n',sceneInfo.detfile);
printMessage(2, '# Detections: ..  %d\n',numel([detections(:).xp]));
printMessage(2, 'Det conf range:.  %f .. %f\n',min([detections(:).sc]),max([detections(:).sc]));

% sceneInfo

%%
end