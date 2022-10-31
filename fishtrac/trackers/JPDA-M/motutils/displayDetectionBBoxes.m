function displayDetectionBBoxes(sceneInfo, detections, labeling)
% Display Detection Bounding Boxes
%
% Take scene information sceneInfo and
% an array of detections and display
% them on 


reopenFig('Detections')
%     scrsz = get(0,'ScreenSize');
%     set(gcf,'Position',[1 scrsz(4)/2 scrsz(3)/2 scrsz(4)/2])

F=size(detections,2);
assert(F==length(sceneInfo.frameNums), 'length of detections must be equal to the number of frames');

detcol=[.1 .2 .9];
grey=.6*ones(1,3);
framePause=0.1; % pause between frames
% framePause=1;

traceLength=0; % overlay data from past n frames
dotSize=10;
boxLineWidth=3;


if nargin<3
    labeling=1*ones(1,length([detections(:).xp]));
else
    assert(length(labeling)==length([detections(:).xp]),...
        'length of labeling must equal length of detection');
end

detections=setDetectionsIDs(detections,labeling);

        
for t=1:F
    clf       

    im=imread([sceneInfo.imgFolder sprintf(sceneInfo.imgFileFormat,sceneInfo.frameNums(t))]);
    if (size(im,3)==1), im=repmat(im,[1 1 3]); end % greyscale
%     im=ones(sceneInfo.imgHeight, sceneInfo.imgWidth); %
    imagesc(im)
    hold on
    
    % frame number
%     text(20,50,sprintf('%d',t),'FontSize',20);
%     text(20,100,sceneInfo.sequence,'FontSize',16);
    
    % foot position
    for k=1:length(detections(t).xp)
        detcol=getColorFromID(detections(t).id(k));     
        detcol=[.9,.9,.9];
        plot(detections(t).xp(k),detections(t).yp(k),'o','color',detcol,'MarkerSize',dotSize*max(0.1,detections(t).sc(k)));        
    end
    
    % box
    nboxes=length(detections(t).xp);
    for id=1:nboxes
        bleft=detections(t).bx(id);
        bright=detections(t).bx(id)+detections(t).wd(id);
        btop=detections(t).by(id);    
        bbottom=detections(t).by(id)+detections(t).ht(id);
        detcol=getColorFromID(detections(t).id(id));
        if detections(t).id(id)==-1
            detcol(:)=1;
        end
        detcol(:)=1;
        line([bleft bleft bright bright bleft],[btop bbottom bbottom btop btop],'color',detcol,'linewidth',boxLineWidth*max(0.1,detections(t).sc(id)));
    end
    
    % show trace
    for tracet=max(1,t-traceLength):max(1,t-1)
%     for tracet=1:F
        ipolpar=(t-tracet)/traceLength; % parameter [0,1] for color adjustment

        nboxes=length(detections(tracet).xp);        
        % foot position
        for k=1:nboxes
            if detections(tracet).id(k) == -1
%                 pause
                detcol(:)=1;
                plot(detections(tracet).xi(k),detections(tracet).yi(k), ...
                    'd','color',detcol,'MarkerSize',dotSize*max(1.1,detections(tracet).sc(k)));
%                 pause
            else                
                detcol=getColorFromID(detections(tracet).id(k));
                detcol(:)=1;
                plot(detections(tracet).xi(k),detections(tracet).yi(k), ...
                    'o','color',detcol,'MarkerSize',dotSize*max(0.1,detections(tracet).sc(k)));
    %                 '.','color',ipolpar*grey + (1-ipolpar)*detcol,'MarkerSize',dotSize*max(0.1,detections(tracet).sc(k)));
            end
        end
        
        % box

%         for id=1:nboxes
%             bleft=detections(tracet).bx(id);
%             bright=detections(tracet).bx(id)+detections(tracet).wd(id);
%             btop=detections(tracet).by(id);    
%             bbottom=detections(tracet).by(id)+detections(tracet).ht(id);
%             
%             detcol=getColorFromID(detections(tracet).id(id));
% %             detcol(:)=1;
% % ipolpar
%             line([bleft bleft bright bright bleft],[btop bbottom bbottom btop btop],'color',ipolpar*grey + (1-ipolpar)*detcol);
% %             pause
%         end

    end
%     saveas(gcf,sprintf('../../data/tmp/dets-%s-final-%04d.jpg',sceneInfo.sequence,t));
    gd=getframe(gcf);
    imwrite(gd.cdata,sprintf('tmp/dets/dets-%s-%04d.jpg',sceneInfo.sequence,t));
    pause(framePause)
end


end