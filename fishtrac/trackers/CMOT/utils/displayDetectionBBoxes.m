function displayDetectionBBoxes(sceneInfo, detections)
% Display Detection Bounding Boxes
%
% Take scene information sceneInfo and
% an array of detections and display
% them on 
% 
% (C) Anton Andriyenko, 2012
%
% The code may be used free of charge for non-commercial and
% educational purposes, the only requirement is that this text is
% preserved within the derivative work. For any other purpose you
% must contact the authors for permission. This code may not be
% redistributed without written permission from the authors.

reopenFig('Detections')

F=size(detections,2);
assert(F==length(sceneInfo.frameNums), 'length of detections must be equal to the number of frames');

detcol=[.1 .2 .9];
grey=.6*ones(1,3);
framePause=0.01; % pause between frames
% framePause=1;

traceLength=10; % overlay data from past 10 frames
dotSize=20;
boxLineWidth=3;

for t=1:F
    clf    
    im=imread([sceneInfo.imgFolder sprintf(sceneInfo.imgFileFormat,sceneInfo.frameNums(t))]);
    if (size(im,3)==1), im=repmat(im,[1 1 3]); end % greyscale
    imshow(im,'Border','tight')
    hold on
    
    % frame number
    text(20,50,sprintf('%d',t),'FontSize',20);
    
    % foot position
    for k=1:length(detections(t).xp)
        plot(detections(t).xp(k),detections(t).yp(k),'.','color',detcol,'MarkerSize',dotSize*detections(t).sc(k));
    end
    
    % box
    nboxes=length(detections(t).xp);
    for id=1:nboxes
        bleft=detections(t).bx(id);
        bright=detections(t).bx(id)+detections(t).wd(id);
        btop=detections(t).by(id);    
        bbottom=detections(t).by(id)+detections(t).ht(id);
        line([bleft bleft bright bright bleft],[btop bbottom bbottom btop btop],'color',detcol,'linewidth',boxLineWidth*detections(t).sc(id));
    end
    
    % show trace
    for tracet=max(1,t-traceLength):max(1,t-1)
        ipolpar=(t-tracet)/traceLength; % parameter [0,1] for color adjustment
        
        % foot position
        for k=1:length(detections(tracet).xp)
            plot(detections(tracet).xi(k),detections(tracet).yi(k), ...
                '.','color',ipolpar*grey + (1-ipolpar)*detcol,'MarkerSize',dotSize*detections(tracet).sc(k));
        end
        
        % box
%         nboxes=length(detections(tracet).xp);
%         for id=1:nboxes
%             bleft=detections(tracet).xp(id)-detections(tracet).wd(id)/2;    
%             bright=detections(tracet).xp(id)+detections(tracet).wd(id)/2;
%             btop=detections(tracet).yp(id)-detections(tracet).ht(id);    
%             bbottom=detections(tracet).yp(id);
%             line([bleft bleft bright bright bleft],[btop bbottom bbottom btop btop],'color',ipolpar*grey + (1-ipolpar)*detcol);
%         end

    end
    
    pause(framePause)
    
end

end