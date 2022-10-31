function flowFile=getFlowFile(sceneInfo,t)

root = sceneInfo.imgFolder;
imgFile=getFrameFile(sceneInfo,t);
[~,imgFile,~]=fileparts(imgFile);
root_flows = fullfile(root,'TSP_flows/');
flowFile = fullfile(root_flows,[imgFile '_flow.mat']);