function stateInfo=getBBoxesFromPrior(stateInfo)
% for visualization and for 2D evaluation
% we need the bounding boxes of the targets
% just take the height prior for that


global sceneInfo
% [~, N F targetsExist X Y]=getStateInfo(stateInfo);
X=stateInfo.X; Y=stateInfo.Y;

[F N]=size(X);
targetsExist=getTracksLifeSpans(X);

W=zeros(size(X));
H=zeros(size(Y));

% if we have camera calibration
% lets assume all people are 1.7m tall and push
% the heights of bboxes towards that value
if isfield(sceneInfo,'camPar')
    heightPrior=getHeightPrior(stateInfo);  
    H=heightPrior;   
else
    error('sorry dude');
end



% aspectRatio= 1/2;
% aspectRatio= 1/3;
% aspectRatio=1;

% normalize ratio to dataset mean?
% if sceneInfo.gtAvailable
%     global gtInfo
%     arithmean=mean(gtInfo.W(~~gtInfo.W)./gtInfo.H(~~gtInfo.H));    
%     aspectRatio= arithmean; 
% end

stateInfo.H=H;

% at least 30 pixels heigh
stateInfo.H(stateInfo.H<30)=30;


% if aspect ratio provided by user, take it
if isfield(sceneInfo,'targetAR')
    stateInfo.W=H*sceneInfo.targetAR;
%     stateInfo.W=H*sceneInfo.targetAR; % or take data set mean
else
    stateInfo.W=W;
end


% at least 15 pixels wide
stateInfo.W(stateInfo.W<15)=15;

% clean up mess
stateInfo.W(~X)=0; stateInfo.H(~X)=0;

% WTF?
% isnanH=find(isnan(stateInfo.H));
% isnumH=setdiff(find(stateInfo.H),isnanH);
% stateInfo.H(isnanH)=mean(stateInfo.H(isnumH));
% isnanW=find(isnan(stateInfo.W));
% isnumW=setdiff(find(stateInfo.W),isnanW);
% stateInfo.W(isnanW)=mean(stateInfo.W(isnumW));


    

end