function convertDetTopToCVML(filein, fileout)
% convert comma-seperated variable (CSV) format
% as used by Benfold et al. to CVML

[pa na ex]=fileparts(filein);

if nargin<2
    fileout=fullfile(pa,[na '.xml']);
end

% load file
TCDATA=load(filein);

datalines=size(TCDATA,1);
% frameNums=0:250;
frameNums=1:748;
% sceneInfo=getSceneInfo(95);
% frameNums=sceneInfo.frameNums;
F=length(frameNums);
ix=[9 19 11 12]; % body
ix=[5 6 7 8]; % head

% parse
% for ds=1:datalines
%     t=TCGT(ds,2)+1;
%     if numel(find(frameNums==t))
%         id=TCGT(ds,1)+1;
%         x1=TCGT(ds,ix(1));y1=TCGT(ds,ix(2));x2=TCGT(ds,ix(3));y2=TCGT(ds,ix(4));
%         Axd(t,id)=x1; Ayd(t,id)=y1;
%         Awd(t,id)=x2-x1; Ahd(t,id)=y2-y1;
%     end
% end

for doheads=0%0:1
    Awd=[]; Axd=[]; Ayd=[]; Ahd=[];
    ix=9;
    if doheads, ix=5; end
    ix=3;
    
    for t=1:F
        if ~mod(t,100), fprintf('.'); end
        ds=find(TCDATA(:,2)==frameNums(t))';
        for obj=1:length(ds)
            x1=TCDATA(ds(obj),ix);y1=TCDATA(ds(obj),ix+1);x2=TCDATA(ds(obj),ix+2);y2=TCDATA(ds(obj),ix+3);
            Awd(t,obj)=x2-x1; Ahd(t,obj)=y2-y1;
            Axd(t,obj)=x1;
            Ayd(t,obj)=y1;
        end
    end
    fprintf('\n');
    % write xml
    
    %% Create XML file
    docNode = com.mathworks.xml.XMLUtils.createDocument('dataset');
    docRootNode = docNode.getDocumentElement;
    docRootNode.setAttribute('name','PNNL');
    for t=1:F
        frameNode=docNode.createElement('frame');
        frameNode.setAttribute('number',sprintf('%i',frameNums(t)));
        objListNode=docNode.createElement('objectlist');
        
        exobj=find(Awd(t,:));
        
        for i=exobj
            objectNode=docNode.createElement('object');
%             objectNode.setAttribute('confidence',num2str(1));
            objectNode.setAttribute('id',num2str(i));
            
            
            boxNode=docNode.createElement('box');
            
            xc=Axd(t,i)+Awd(t,i)/2;
            yc=Ayd(t,i)+Ahd(t,i)/2;
            w=Awd(t,i);
            h=Ahd(t,i);
			[i t]	
			[xc-w/2 yc-h/2 xc+w/2 yc+h/2]
			pause
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
    
    if doheads
        [pa na ex]=fileparts(fileout);
        fileout=fullfile(pa,[na '-heads' ex]);
    end
    
    xmlwrite(fileout,docNode);
    fprintf('xml written to %s\n',fileout);
    
end

end