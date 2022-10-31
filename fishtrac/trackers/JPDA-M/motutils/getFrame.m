function [im, filename]=getFrame(sceneInfo,t)
% load one specific frame

im=[];

filename=getFrameFile(sceneInfo,t);
if ~exist(filename,'file');
    warning('File %s does not exist!',filename);
else
    im=double(imread(filename))/255;
end

end
