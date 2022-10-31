function [detections, nDets]=parseDetCVML(detfile)

xDoc=xmlread(detfile);
allFrames=xDoc.getElementsByTagName('frame');
F=allFrames.getLength;
frameNums=zeros(1,F);

nDets=0;

%%
frToParse=1:F;
if nargin==2, frToParse=frames; end

for t=frToParse
    if ~mod(t,10), fprintf('.'); end
    % what is the frame
    frame=str2double(allFrames.item(t-1).getAttribute('number'));
    frameNums(t)=frame;
    
    objects=allFrames.item(t-1).getElementsByTagName('object');
    Nt=objects.getLength;
    nboxes=Nt; % how many detections in current frame
    xis=zeros(1,nboxes);
    yis=zeros(1,nboxes);
    heights=zeros(1,nboxes);
    widths=zeros(1,nboxes);
    boxleft=zeros(1,nboxes);
    boxtop=zeros(1,nboxes);
    scores=zeros(1,nboxes);
    
    
    for i=0:Nt-1
	% score
	boxid=i+1;
	scores(boxid)=str2double(objects.item(i).getAttribute('confidence'));
	box=objects.item(i).getElementsByTagName('box');
	
	% box extent
	heights(boxid) = str2double(box.item(0).getAttribute('h'));
	widths(boxid) = str2double(box.item(0).getAttribute('w'));
	
	% foot position
	xis(boxid) = str2double(box.item(0).getAttribute('xc'));
	yis(boxid) = str2double(box.item(0).getAttribute('yc'))+heights(boxid)/2;
	
    end
    
    
    % box left top corner
    boxleft=xis-widths/2;
    boxtop=yis-heights;
    
    detections(t).bx=boxleft;
    detections(t).by=boxtop;
    detections(t).xp=xis;
    detections(t).yp=yis;
    detections(t).ht=heights;
    detections(t).wd=widths;
    detections(t).sc=scores;
    
    detections(t).xi=xis;
    detections(t).yi=yis;
    
    nDets=nDets+length(xis);
end
fprintf('\n');