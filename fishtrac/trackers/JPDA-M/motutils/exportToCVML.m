function exportToCVML(stateInfo, outfile)
% convert x,y coordinates to CVML detection file


assert(all(size(stateInfo.Xi,1)==length(stateInfo.frameNums)), ...
    'frameNums and state space are not consistent');

% figure out how many time steps
% [F, N]=size(X);
% frameNums=1:F;

% invert for image coordinates
% extar=find(X(:));
% X(extar)=7000-X(extar);
% Y(extar)=14000-Y(extar);

%% Create XML file
docNode = com.mathworks.xml.XMLUtils.createDocument('result');
docRootNode = docNode.getDocumentElement;
docRootNode.setAttribute('name',stateInfo.sceneInfo.sequence);

F=length(stateInfo.frameNums);
for t=1:F
    frameNode=docNode.createElement('frame');
    frameNode.setAttribute('number',sprintf('%i',stateInfo.frameNums(t)));
    objListNode=docNode.createElement('objectlist');
    
    exobj=find(stateInfo.W(t,:));
    for id=exobj
        objectNode=docNode.createElement('object');
%         objectNode.setAttribute('id',num2str(id));            
%         objectNode.setAttribute('confidence',num2str(1));
        objectNode.setAttribute('confidence',num2str(stateInfo.S(t,id)));
        
        boxNode=docNode.createElement('box');
        
        w=stateInfo.W(t,id); h=stateInfo.H(t,id);
        xc=stateInfo.Xi(t,id); yc=stateInfo.Yi(t,id)-h/2;
        
        
        
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
xmlwrite(outfile,docNode);
fprintf('xml written to %s\n',outfile);

end % function