function gtInfo=parseGT(gtfile)
% read ground truth bounding boxes
% 

% first determine the type
[~, ~, fileext]=fileparts(gtfile);

% for now, we can only read CVML schema
if  strcmpi(fileext,'.xml');
else    error('Unknown type of detections file.');
end

%% now parse
xDoc=xmlread(gtfile);

allFrames=xDoc.getElementsByTagName('frame');
F=allFrames.getLength;
frameNums=zeros(1,F);
gtInfo.X=zeros(F,0);gtInfo.Y=zeros(F,0);gtInfo.W=zeros(F,0);gtInfo.H=zeros(F,0);

%%
for t=1:F
    if ~mod(t,10), fprintf('.'); end
    % what is the frame
    frame=str2double(allFrames.item(t-1).getAttribute('number'));
    frameNums(t)=frame;
    
    objects=allFrames.item(t-1).getElementsByTagName('object');
    Nt=objects.getLength;
%     nObj=size(gtInfo.X,2);
    gtInfo.X(t,:)=zeros(1,size(gtInfo.X,2));gtInfo.Y(t,:)=zeros(1,size(gtInfo.Y,2));
    gtInfo.W(t,:)=zeros(1,size(gtInfo.W,2));gtInfo.H(t,:)=zeros(1,size(gtInfo.H,2));
    for i=0:Nt-1
        id=str2double(objects.item(i).getAttribute('id'));
        if id<1, error('uh oh. IDs should be positive'); end
        box=objects.item(i).getElementsByTagName('box');
        h=str2double(box.item(0).getAttribute('h'));
        w=str2double(box.item(0).getAttribute('w'));
        xc=str2double(box.item(0).getAttribute('xc'));
        yc=str2double(box.item(0).getAttribute('yc'));
        
        % foot position
        gtInfo.X(t,id)=xc;       gtInfo.Y(t,id)=yc+h/2;
        gtInfo.H(t,id)=h;        gtInfo.W(t,id)=w;
    end
end
% gtfile
% gtInfo
gtInfo.frameNums=frameNums;
% remove zero columns
notEmpty=~~sum(gtInfo.X,1);
gtInfo.X=gtInfo.X(:,notEmpty);
gtInfo.Y=gtInfo.Y(:,notEmpty);
gtInfo.W=gtInfo.W(:,notEmpty);
gtInfo.H=gtInfo.H(:,notEmpty);


% fprintf('all read\n');
fprintf('\n');

end