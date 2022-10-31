function stateInfo=parsePETS(resfile)

xDoc=xmlread(resfile);
allFrames=xDoc.getElementsByTagName('Frame');
F=allFrames.getLength;
frameNums=zeros(1,F);
stateInfo.Xi=zeros(F,0);stateInfo.Yi=zeros(F,0);
stateInfo.W=zeros(F,0);stateInfo.H=zeros(F,0);
frToParse=1:F;




for t=frToParse
    if ~mod(t,10), fprintf('.'); end
    framestr=char(allFrames.item(t-1).getAttribute('id'));
    frame=sscanf(framestr,'frame_%04d');
    frameNums(t)=frame;
    
    objects=allFrames.item(t-1).getElementsByTagName('Person');
    Nt=objects.getLength;
    stateInfo.Xi(t,:)=zeros(1,size(stateInfo.Xi,2));stateInfo.Yi(t,:)=zeros(1,size(stateInfo.Yi,2));
    stateInfo.W(t,:)=zeros(1,size(stateInfo.W,2));stateInfo.H(t,:)=zeros(1,size(stateInfo.H,2));
    for i=0:Nt-1
        id=str2double(objects.item(i).getAttribute('id'));
        if id<1, error('uh oh. IDs should be positive');
        end
        box=objects.item(i).getElementsByTagName('BoundingBox');
        bottom=str2double(box.item(0).getAttribute('bottom'));
        left=str2double(box.item(0).getAttribute('left'));
        right=str2double(box.item(0).getAttribute('right'));
        top=str2double(box.item(0).getAttribute('top'));
        
        h=bottom-top;
        w=right-left;
        xc=left + w/2;
%         yc=top + h/2;
        
        % foot position
        stateInfo.Xi(t,id)=xc;       stateInfo.Yi(t,id)=bottom;
        stateInfo.H(t,id)=h;        stateInfo.W(t,id)=w;
    end
    
    
end

stateInfo.frameNums=frameNums;
% remove zero columns
notEmpty=~~sum(stateInfo.Xi,1);
stateInfo.Xi=stateInfo.Xi(:,notEmpty);
stateInfo.Yi=stateInfo.Yi(:,notEmpty);
stateInfo.W=stateInfo.W(:,notEmpty);
stateInfo.H=stateInfo.H(:,notEmpty);

fprintf('\n');
end