function convertKITTIToCVML(dets, fileout, classes, thr)
% convert KITTI format to to CVML

if nargin<3
    classes={'Car'};
end
if isstr(classes)
    classes=cellstr(classes);
end

if nargin<4, thr=0; end

% result / dets
detfound=0;
t=0;
while ~detfound
    t=t+1;
    if isempty(dets{t})
        continue;
    else
        detfound=1;
        if isfield(dets{t}(1),'score')
            gt=0;
        else
            gt=1;
        end
    end
end
if ~detfound, warning('No dets/labels found. Assuming det'); gt=0; end
    
    
F=length(dets);
    
    %% Create XML file
    docNode = com.mathworks.xml.XMLUtils.createDocument('dataset');
    docRootNode = docNode.getDocumentElement;
    docRootNode.setAttribute('name','KITTI');
    
    
    for t=1:F
        if ~mod(t,10),fprintf('.'); end
        frameNode=docNode.createElement('frame');
        ndet=length(dets{t});
%         if ~ndet, continue; end
      
        % KITTI sequences start at 0
        frameNode.setAttribute('number',num2str(t-1));
        objListNode=docNode.createElement('objectlist');
        
        
        exobj=1:ndet;
        
        for i=exobj
            % is object of relevant class?
            rel=0;
            for cl=1:length(classes)
                if isequal(char(classes{cl}),dets{t}(i).type)
                    rel=1;
                end
            end
            if ~rel, continue; end
            
            
            objectNode=docNode.createElement('object');
            
            if gt                
                id=dets{t}(i).id+1;
                objectNode.setAttribute('id',num2str(id));
                
            else
                conf=dets{t}(i).score;

                if conf<thr, continue; end
                
                sigA=0;    sigB=1;
                conf=1./(1+exp(-sigB*conf + sigA*sigB));
                objectNode.setAttribute('confidence',num2str(conf));
            end
            
            objectNode.setAttribute('class',dets{t}(i).type);
%             objectNode.setAttribute('id',num2str(i));
            
            
            boxNode=docNode.createElement('box');
            x1=dets{t}(i).x1;
            y1=dets{t}(i).y1;
            x2=dets{t}(i).x2;
            y2=dets{t}(i).y2;
            w=x2-x1;
            h=y2-y1;
            
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
