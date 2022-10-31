function saveYangXML(stInfo,xmlfile)
% save to format used by Yang Bo

% Yangs format always starts with frame 0
% hence subtract the 'correct' first frame

firstFrame=stInfo.frameNums(1);
%% Create XML file
docNode = com.mathworks.xml.XMLUtils.createDocument('Video');
docRootNode = docNode.getDocumentElement;
docRootNode.setAttribute('fname','...');
docRootNode.setAttribute('start_frame',num2str(stInfo.frameNums(1)-firstFrame));
docRootNode.setAttribute('end_frame',num2str(stInfo.frameNums(end)-firstFrame));


isgt=1;
if isfield(stInfo,'opt'), isgt=0; end

F=length(stInfo.frameNums);
[Ft N]=size(stInfo.Xi);
[F Ft]
assert(F==Ft);


for id=1:N
    if ~mod(id,10), fprintf('.'); end

    trajNode=docNode.createElement('Trajectory');
    exframes=find(stInfo.W(:,id))';
    exframenums=stInfo.frameNums(exframes);
    trajNode.setAttribute('obj_id',sprintf('%i',id));
    trajNode.setAttribute('start_frame',sprintf('%i',exframenums(1)-firstFrame));
    trajNode.setAttribute('end_frame',sprintf('%i',exframenums(end)-firstFrame));
%     [id exframes(1) exframes(end) length(exframes)]
    for t=exframes
        frNode=docNode.createElement('Frame');
        
        frno=sprintf('%d',(stInfo.frameNums(t)-firstFrame));
        x=sprintf('%d',(round(stInfo.Xi(t,id)-stInfo.W(t,id)/2)));
%         frNode.setAttribute('frame_no',num2str(stInfo.frameNums(t)-firstFrame));
%         frNode.setAttribute('x',num2str(round(stInfo.Xi(t,id)-stInfo.W(t,id)/2)));
%         frNode.setAttribute('y',num2str(round(stInfo.Yi(t,id)-stInfo.H(t,id))));
%         frNode.setAttribute('width',num2str(round(stInfo.W(t,id))));
%         frNode.setAttribute('height',num2str(round(stInfo.H(t,id))));
%         frNode.setAttribute('observation',num2str(~isgt));


        frNode.setAttribute('x',x);
        frNode.setAttribute('frame_no',frno);
        
        frNode.setAttribute('y',sprintf('%d',(round(stInfo.Yi(t,id)-stInfo.H(t,id)))));
        frNode.setAttribute('width',sprintf('%d',(round(stInfo.W(t,id)))));
        frNode.setAttribute('height',sprintf('%d',(round(stInfo.H(t,id)))));
        frNode.setAttribute('observation',sprintf('%d',(~isgt)));
        
        trajNode.appendChild(frNode);
        
    end
    
    docRootNode.appendChild(trajNode);
end

xmlwrite(xmlfile,docNode);
fprintf('\n');