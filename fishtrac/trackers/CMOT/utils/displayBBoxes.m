function displayBBoxes(sceneInfo,frameNums,X,Y,W,H,options)
% Draw bounding boxes on top of images
% 
% (C) Anton Andriyenko, 2012
%
% The code may be used free of charge for non-commercial and
% educational purposes, the only requirement is that this text is
% preserved within the derivative work. For any other purpose you
% must contact the authors for permission. This code may not be
% redistributed without written permission from the authors.
%
[F,~]=size(X);

ind=find(W);
aspectRatio=mean(H(ind)./W(ind));

%% if we want to display  traces, lets compute average image
% or let's not... Doesn't look good, anyway

% im=imread([sceneInfo.imgFolder sprintf(sceneInfo.imgFileFormat,frameNums(1))]);    
% avim=zeros(size(im));
% avgF=1:5:min(500,F);
% avgnF=length(avgF);
% for t=avgF
%     im=imread([sceneInfo.imgFolder sprintf(sceneInfo.imgFileFormat,frameNums(t))]);
%     avim=avim+double(im)/avgnF;
% end
% avim=avim/255;

global opt;

    if options.hideBG && opt.cutToTA && isfield(sceneInfo,'bgMask')
        al=0.5;
        load(sceneInfo.bgMask);
        immask=cat(3,bgmask,bgmask,bgmask);
        
    end
    
for t=1:F
    clf
    im=double(imread([sceneInfo.imgFolder sprintf(sceneInfo.imgFileFormat,frameNums(t))]))/255;
    
    if options.hideBG && opt.cutToTA && isfield(sceneInfo,'bgMask')
        imgray=rgb2gray(im); imgray=imgray+0.5;
        imgray=cat(3,imgray,imgray,imgray);
        im(immask)=al*im(immask)+(1-al)*(imgray(immask));
    end
    
    if (size(im,3)==1), im=repmat(im,[1 1 3]); end % greyscale
    imshow(im,'Border','tight')
    hold on
    
    % frame number
    text(20,50,sprintf('%d',t),'FontSize',20);
    
    % tracking area
    if opt.track3d && opt.cutToTA
        drawTALimits;
    end
    
    
    extar=find(X(t,:));
    % foot position
    if options.displayDots
        for id=extar
            plot(X(t,id),Y(t,id),'.','color',getColorFromID(id),'MarkerSize',options.dotSize);
        end
    end
    
    % box
    if options.displayBoxes
        for id=extar
            bleft=X(t,id)-W(t,id)/2;
            bright=X(t,id)+W(t,id)/2;
            btop=Y(t,id)-H(t,id);
            bbottom=Y(t,id);
%             line([bleft bleft bright bright bleft],[btop bbottom bbottom btop btop],'color',getColorFromID(id),'linewidth',options.boxLineWidth);
            rectangle('Position',[bleft,btop,W(t,id),H(t,id)],'Curvature',[.3,.3*(W(t,id)/H(t,id))],'EdgeColor',getColorFromID(id),'linewidth',options.boxLineWidth);
        end
    end
    
    % ID
    if options.displayID
        for id=extar
            tx=X(t,id); 
            ty=Y(t,id)-H(t,id)*2/3; % inside
%             ty=Y(t,id)-H(t,id)-10; % on top
            text(tx,ty,sprintf('%i',id),'color',getColorFromID(id), ...
                'HorizontalAlignment','center', ...
                'FontSize',W(t,id)/2, 'FontUnits','pixels','FontWeight','bold');
        end
    end
    
    % cropouts
    if options.displayCropouts
        bw=2; %border cropouts
        
        %% crop outs var sized
        maxTar=30;
        extarRed=extar(extar<=maxTar); % reducde
%         crpImg=zeros(round(max(max(H))+5),round(sum(max(W))+5*bw),3);
%         offset=1;
%         offsets=round([1 cumsum(max(W))]);
%         for id=extarRed
% %             offsets(id)=offset;
%             offset=offsets(id);
%             bleft=round(X(t,id)-W(t,id)/2);
%             bright=round(X(t,id)+W(t,id)/2);
%             btop=round(Y(t,id)-H(t,id));
%             bbottom=round(Y(t,id));
%             
%             ht=(bbottom-btop)+1;wt=(bright-bleft)+1;
%             crpImg(1:ht,offset:offset+wt-1,:)=im(btop:bbottom,bleft:bright,:);
% %             offset=offset+wt+bw;
%         end

        %% crop outs fixed sized
        uniH=min(60,round(sceneInfo.imgHeight/10)); uniW=round(uniH/aspectRatio);
%         crpImg=zeros(round(uniH+bw),round(uniW*size(W,2)+bw*size(W,2)),3);     % black
        mxfac=.5;
        crpImg=im(1:uniH,1:min(sceneInfo.imgWidth,round(uniW*size(W,2)+bw*size(W,2))),:)*mxfac; 
        crpImg=crpImg + (1-mxfac)*ones(size(crpImg));   % bleeched
        for id=extarRed
            offset=(id-1)*uniW + (id-1)*bw+1;
            bleft=round(X(t,id)-W(t,id)/2);
            bright=round(X(t,id)+W(t,id)/2);
            btop=round(Y(t,id)-H(t,id));
            bbottom=round(Y(t,id));
            
            [bleft bright btop bbottom]= ...
                clampBBox(bleft, bright, btop, bbottom, sceneInfo.imgWidth, sceneInfo.imgHeight);
            ht=uniH;
            imres=imresize(im(btop:bbottom,bleft:bright,:),[uniH uniW]);
            crpImg(1:ht,offset:offset+uniW-1,:)=imres;
            
        end        
        imshow(crpImg);

        for id=extarRed
%             tx=offsets(id)+W(t,id)/2;
            tx=id*uniW-uniW/2 + id*bw;
            ty=30; % top
            ty=size(crpImg,1)-10; % below
            text(tx,ty,sprintf('%i',id),'color',getColorFromID(id), ...
                'HorizontalAlignment','center', ...
                'FontSize',uniW/2, 'FontUnits','pixels','FontWeight','bold'); % fixed size
%                 'FontSize',mean(W(t,extarRed))/2, 'FontUnits','pixels','FontWeight','bold'); % var size
            
        end
        if options.displayConnections
            for id=extarRed
                if t-find(X(:,id),1,'first')<5
                btop=round(Y(t,id)-H(t,id));
                offset=(id-1)*uniW + (id-1)*bw+1 + uniW/2;
                line([X(t,id) offset],[btop uniH],'color',getColorFromID(id),'linestyle','-');
                end
            end
        end
    end
    
    % show trace
    if options.traceLength
        for tracet=max(1,t-options.traceLength):max(1,t-1)
            ipolpar=(t-tracet)/options.traceLength; % parameter [0,1] for color adjustment
            
            % pick color from tail
%             if tracet==max(1,t-options.traceLength)
%                 im=imread([sceneInfo.imgFolder sprintf(sceneInfo.imgFileFormat,frameNums(tracet))]);
%             end

            extarpast=find(X(tracet,:));
            % foot position
            for id=extarpast
    %             plot(X(tracet,id),Y(tracet,id), ...
    %                 '.','color',ipolpar*options.grey + (1-ipolpar)*getColorFromID(id),'MarkerSize',max(1,options.dotSize*(1-ipolpar)));
                
                
                if W(tracet+1,id)
                    posx=round(max(1,X(t,id))); posx=min(sceneInfo.imgWidth,posx);
                    posy=round(max(1,Y(t,id))); posy=min(sceneInfo.imgHeight,posy);
%                     endcol=double(reshape(avim(posy,posx,:),1,3));  
%                     endcol=min(1,endcol); endcol=max(1,endcol);
                    endcol=options.grey;
                    line(X(tracet:tracet+1,id) ,Y(tracet:tracet+1,id), ...
                        'color',ipolpar*endcol + (1-ipolpar)*getColorFromID(id),'linewidth',(1-ipolpar)*options.traceWidth+1);
                end

            end

        end
    end
    

    pause(options.framePause)
    
    % save
    if isfield(options,'outFolder');
        im2save=getframe(gcf);
        im2save=im2save.cdata;
        imwrite(im2save, fullfile(options.outFolder,sprintf('frame_%04d.jpg',frameNums(t))));
    end
    
end

end