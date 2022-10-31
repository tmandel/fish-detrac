function convertDollarToCVML(filein, fileout, sceneInfo, thr)
% convert KITTI format to to CVML

% sceneInfo is needed to convert the frame numbers

if nargin<4, thr=0; end

try dets=load(filein);
catch err
    error(err.identifier,'Error wile loading: %s',err.identifier);
end

ndets=size(dets,1);
fprintf('%d detections read\n',ndets);

minscore=min(dets(:,6));
maxscore=max(dets(:,6));
F=length(sceneInfo.frameNums);

%% Create XML file
docNode = com.mathworks.xml.XMLUtils.createDocument('dataset');
docRootNode = docNode.getDocumentElement;
docRootNode.setAttribute('name',sceneInfo.sequence);


for t=1:F
    if ~mod(t,10),fprintf('.'); end
    frameNode=docNode.createElement('frame');
    detsF=find(dets(:,1)==t);
    detsF=reshape(detsF,1,length(detsF));
    
    frameNode.setAttribute('number',num2str(sceneInfo.frameNums(t)));
    objListNode=docNode.createElement('objectlist');
    
    
    
    
    for d=detsF
        
        objectNode=docNode.createElement('object');

        conf=dets(d,6);
            
        if conf<thr, continue; end
        
        conf=conf/maxscore;

%         sigA=0;    sigB=1;
%         conf=1./(1+exp(-sigB*conf + sigA*sigB));
        objectNode.setAttribute('confidence',num2str(conf));
        
                
        
        boxNode=docNode.createElement('box');
        x1=dets(d,2);
        y1=dets(d,3);
        w=dets(d,4);
        h=dets(d,5);
        
        xc=x1+w/2;
        yc=y1+h/2;
        
        boxNode.setAttribute('xc',num2str(xc));
        boxNode.setAttribute('yc',num2str(yc));
        boxNode.setAttribute('w',num2str(w));
        boxNode.setAttribute('h',num2str(h));
        
        
        objectNode.appendChild(boxNode);
        objListNode.appendChild(objectNode);
        
    end
    frameNode.appendChild(objListNode);
    docRootNode.appendChild(frameNode);
    
end

xmlwrite(fileout,docNode);
fprintf('xml written to %s\n',fileout);


end
