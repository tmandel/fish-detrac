function displayBBoxes(sceneInfo,frameNums,X,Y,W,H,options,opt,metrics)
% Draw bounding boxes on top of images


global detections
% global imgrid
% global gtAllGT
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

fpcnt=0;
fncnt=0;
idswcnt=0;

LineSmoothing='off';
LineSmoothing='on';
if nargin<8
    global opt;
end
if options.displayIDSwitches || options.displayFP || options.displayFN
    global gtInfo;
end

if options.hideBG && opt.cutToTA && isfield(sceneInfo,'bgMask')
    al=0.4;
    load(sceneInfo.bgMask);
    immask=cat(3,bgmask,bgmask,bgmask);
end
% % only for vis with labeling
% global labeling
% alldpoints=createAllDetPoints(detections);
% [axi ayi]=projectToImage(alldpoints.xp,alldpoints.yp,sceneInfo);
%         
renderframes=1:F;
if isfield(options,'renderframes')
    renderframes=options.renderframes;
end
tcnt=0;
for t=renderframes
% for t=139
    tcnt=tcnt+1;
    clf
    set(gcf,'Renderer','painters');
    if sceneInfo.imgWidth<=2800    
        im=double(imread([sceneInfo.imgFolder sprintf(sceneInfo.imgFileFormat,sceneInfo.frameNums(t))]))/255;
    else
        im=zeros(sceneInfo.imgHeight,sceneInfo.imgWidth,3);
    end
%     im=double(imread('/home/aanton/storage/databases/PNNL/ParkingLot/frames/00000139.png'))/255;
    if options.hideBG && opt.cutToTA && isfield(sceneInfo,'bgMask')
        extar=find(X(t,:));
        immaskt=immask;
        for id=extar
            bleft=X(t,id)-W(t,id)/2;        bright=X(t,id)+W(t,id)/2;
            btop=Y(t,id)-H(t,id);            bbottom=Y(t,id);
            
            brows=ceil(btop+1):floor(bbottom-1); brows=brows(brows>0 & brows<sceneInfo.imgHeight);
            bcols=ceil(bleft+1):floor(bright-1); bcols=bcols(bcols>0 & bcols<sceneInfo.imgWidth);

            immaskt(brows,bcols,:)=0;
        end
        
        imgray=rgb2gray(im); imgray=imgray+0.5;
        imgray=cat(3,imgray,imgray,imgray);
        im(immaskt)=al*im(immaskt)+(1-al)*(imgray(immaskt));
    end
    
    if (size(im,3)==1), im=repmat(im,[1 1 3]); end % greyscale
    
%     im = flipdim(im,1);
%     imshow(im,'Border','tight');
%     imshow(im,'parent',gca)
        image(im);set(gcf,'Position',[0 100 sceneInfo.imgWidth sceneInfo.imgHeight]); set(gca, 'Position', [0 0 1 1]);
        axis image; axis tight; set(gca,'XTick',[]);set(gca,'YTick',[])
%     imagesc(im); axis image; axis tight; set(gca,'XTick',[]);set(gca,'YTick',[]);

%     xlim([1 1920]);    ylim([1 1080]);
%     set(gca,'YDir','reverse');
    
    hold on
    %% grid for ILP (PETS)
% % %     [gridX gridY ndim]=size(imgrid);
% % %     allxi=imgrid(:,:,1); allxi=allxi(:);
% % %     allyi=imgrid(:,:,2); allyi=allyi(:);
% % %     extar=find(X(t,:));
% % %     for id=extar
% % %         bleft=X(t,id)-W(t,id)/2;        bright=X(t,id)+W(t,id)/2;
% % %         btop=Y(t,id)-H(t,id);            bbottom=Y(t,id);
% % % %         [bleft bright btop bbottom]
% % %         insidebbox=find(allxi>bleft & allxi < bright & allyi<bbottom & allyi>btop);
% % %         keepinds=setdiff(1:length(allxi),insidebbox);
% % %         allxi=allxi(keepinds);allyi=allyi(keepinds);
% % % %         insidebbox
% % % %         length(keepinds)
% % % %         pause
% % % %         numel(allxi)
% % % %         numel(allxi<bleft & allxi>bright)
% % % %         pause
% % % %         allxi=allxi(allxi<bleft | allxi>bright);
% % % %         allyi=allyi(allyi<btop | allyi>bbottom);
% % %     end
% % %     % remove inside boxes
% % %     plot(allxi,allyi,'k.','MarkerSize',2);
% % % %     maxsize=6; minsize=2; sizediff=maxsize-minsize;
% % % %     maxy=max(max(imgrid(:,:,2)));miny=min(min(imgrid(:,:,2)));
% % % %     for xi=1:gridX
% % % %         for yi=1:gridY
% % % %             interpval=(imgrid(xi,yi,2)-miny)/(maxy-miny);
% % % %             plot(imgrid(xi,yi,1),imgrid(xi,yi,2),'ko', ...
% % % %                 'MarkerSize',interpval*maxsize+(1-interpval)*minsize);
% % % % %             imgrid(xi,yi,2)
% % % % %             interpval
% % % % %             interpval*maxsize+(1-interpval)*minsize
% % % % %             pause
% % % %         end
% % % %     end
    
    %% frame number
    textcol='k';
    if sceneInfo.scenario==41, textcol='w'; end
    text(20,20,sprintf('%d',t),'FontSize',20,'color',textcol);
    
    %% tracking area
    if opt.track3d && opt.cutToTA
        if length(sceneInfo.camPar)==1
            drawTALimits(sceneInfo);
        else
            drawTALimits(sceneInfo,t);
        end
    end
    
    
    extar=find(X(t,:));
    % foot position
    if options.displayDots
        for id=extar
            dotCol=getColorFromID(id);
            if isfield(options,'newColors'), dotCol=options.newColors(id,:); end

            plot(X(t,id),Y(t,id),'.','color',dotCol,'MarkerSize',options.dotSize);
        end
    end
    
        %% show trace
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
                    
                    trCol=getColorFromID(id);
                    if isfield(options,'newColors'), trCol=options.newColors(id,:); end
                    endcol=trCol;
                    
                    line(X(tracet:tracet+1,id) ,Y(tracet:tracet+1,id), ...                        
                        'color',ipolpar*endcol + (1-ipolpar)*trCol,'linewidth',(1-ipolpar)*options.traceWidth+1, 'LineSmoothing',LineSmoothing);                
%                     'color',ipolpar*endcol + (1-ipolpar)*getColorFromID(id),'linewidth',2, 'LineSmoothing',LineSmoothing);

                end
                
            end
            
        end
    end
    
    %% show prediction
    if options.predTraceLength
        for tracet=t:min(F-1,t+options.predTraceLength)
            ipolpar=(t-tracet)/options.traceLength; % parameter [0,1] for color adjustment            
            ipolpar=1;
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
                    
                    trCol=getColorFromID(id);
                    if isfield(options,'newColors'), trCol=options.newColors(id,:); end
                    endcol=trCol;
                    
                    line(X(tracet:tracet+1,id) ,Y(tracet:tracet+1,id),'linestyle', '-',...                        
                        'color',ipolpar*endcol + (1-ipolpar)*trCol,'linewidth',(1-ipolpar)*options.predTraceWidth+1, 'LineSmoothing',LineSmoothing);                
%                     'color',ipolpar*endcol + (1-ipolpar)*getColorFromID(id),'linewidth',2, 'LineSmoothing',LineSmoothing);

                end
                
            end
            
        end
    end
    
    %% box
    if options.displayBoxes
        
        [srt srtextar]=sort(Y(t,extar),'ascend');

        for id=extar(srtextar)
            
            if options.displayFP && options.allfp(t,id)
                continue; 
            end
            
            boxCol=getColorFromID(id);
            if isfield(options,'newColors'), boxCol=options.newColors(id,:); end
            bleft=X(t,id)-W(t,id)/2;
            bright=X(t,id)+W(t,id)/2;
            btop=Y(t,id)-H(t,id);
            bbottom=Y(t,id);
            %             line([bleft bleft bright bright bleft],[btop bbottom bbottom btop btop],'color',getColorFromID(id),'linewidth',options.boxLineWidth);
            %             if id<10
            boxcurvature=[.2,.2*(W(t,id)/H(t,id))]; boxcurvature=max(0,boxcurvature);boxcurvature=min(1,boxcurvature);
            rectangle('Position',[bleft,btop,W(t,id),H(t,id)],'Curvature',boxcurvature,'EdgeColor',boxCol,'linewidth',options.boxLineWidth);
            %             else
            %                 rectangle('Position',[bleft,btop,W(t,id),H(t,id)],'Curvature',boxcurvature,'EdgeColor',getColorFromID(id),'linewidth',options.boxLineWidth,'linestyle','--');
            %             end
       end
            %% several ground truths
            
%             gtcols=[1 1 1; 0 1 0; 0 0 1];
%         for g=1:3
%             
%                 X=gtAllGT{g}.Xi;Y=gtAllGT{g}.Yi;
%                 H=gtAllGT{g}.H;W=gtAllGT{g}.W;
%                 boxCol=gtcols(g,:);
%                 extar=find(X(t,:));    
%                 for id=extar
%             
%                 bleft=X(t,id)-W(t,id)/2;                bright=X(t,id)+W(t,id)/2;
%                 btop=Y(t,id)-H(t,id);               bbottom=Y(t,id);
%                 boxcurvature=[.3,.3*(W(t,id)/H(t,id))]; boxcurvature=max(0,boxcurvature);boxcurvature=min(1,boxcurvature);
%                 rectangle('Position',[bleft,btop,W(t,id),H(t,id)],'Curvature',boxcurvature,'EdgeColor',boxCol,'linewidth',options.boxLineWidth);
%                 end
%           
%             
%         end
    end
    
    %% ID number
    if options.displayID
        for id=extar
            tx=X(t,id);
            if isequal(sceneInfo.dataset,'PETS2009') 
                ty=Y(t,id)-H(t,id)*2/3; % inside
%             elseif isequal(sceneInfo.dataset,'PNNL')
%                 ty=Y(t,id)-H(t,id)*1/2; % inside
            else
                        ty=Y(t,id)-H(t,id)-10; % on top
            end
            idCol=getColorFromID(id);
            if isfield(options,'newColors'), idCol=options.newColors(id,:); end
            fontwidth=W(t,id)/2;
            if isequal(sceneInfo.dataset,'PNNL')
                fontwidth=W(t,id)/3;
            end

            text(tx,ty,sprintf('%i',id),'color',idCol, ...
                'HorizontalAlignment','center', ...
                'VerticalAlignment','bottom', ...
                'FontSize',fontwidth, 'FontUnits','pixels','FontWeight','bold');
        end
    end
    
    %% cropouts
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
    
    
    %% indicate id switches
    if options.displayIDSwitches
        incurframe=find(options.IDswitches(t,:));
        inprevframe=[]; inppframe=[];
        
        scfac=1.1;        scfac2=1.2;
        for id=incurframe
            idswcnt=idswcnt+1;
            bleft=X(t,id)-scfac*W(t,id)/2;
            btop=Y(t,id)-scfac*H(t,id);
            boxCol=getColorFromID(id);
            if isfield(options,'newColors'), boxCol=options.newColors(id,:); end

            rectangle('Position',[bleft,btop,scfac2*W(t,id),scfac2*H(t,id)],'Curvature',[.3,.3*(W(t,id)/H(t,id))],'EdgeColor',boxCol,'linewidth',options.boxLineWidth);
            tx=X(t,id);   ty=Y(t,id)-H(t,id)-10; % on top
            
            text(tx,ty,'new ID','color',getColorFromID(id), ...
                'HorizontalAlignment','center', ...
                'FontSize',W(t,id)/2, 'FontUnits','pixels','FontWeight','bold');
            
        end
        
        if t>1,inprevframe=find(options.IDswitches(t-1,:)); end
        
        scfac=1.2;        scfac2=1.4;
        for id=inprevframe
            bleft=X(t,id)-scfac*W(t-1,id)/2;
            btop=Y(t,id)-scfac*H(t-1,id);
            boxCol=getColorFromID(id);
            if isfield(options,'newColors'), boxCol=options.newColors(id,:); end

%             rectangle('Position',[bleft,btop,scfac2*W(t-1,id),scfac2*H(t-1,id)],'Curvature',[.3,.3*(W(t,id)/H(t,id))],'EdgeColor',getColorFromID(id),'linewidth',options.boxLineWidth/2);
            tx=X(t,id);   ty=Y(t,id)-H(t,id)-10; % on top
            text(tx,ty,'new ID','color',boxCol, ...
                'HorizontalAlignment','center', ...
                'FontSize',W(t-1,id)/2, 'FontUnits','pixels','FontWeight','bold');
            
        end
        
        
        if t>2,inppframe=find(options.IDswitches(t-2,:)); end
        
        scfac=1.4;        scfac2=1.6;
        for id=inppframe
            bleft=X(t,id)-scfac*W(t-2,id)/2;
            btop=Y(t,id)-scfac*H(t-2,id);
%             rectangle('Position',[bleft,btop,scfac2*W(t-2,id),scfac2*H(t-2,id)],'Curvature',[.3,.3*(W(t-2,id)/H(t-2,id))],'EdgeColor',getColorFromID(id),'linewidth',options.boxLineWidth/3);
            boxCol=getColorFromID(id);
            if isfield(options,'newColors'), boxCol=options.newColors(id,:); end

            tx=X(t,id);   ty=Y(t,id)-H(t,id)-10; % on top
            text(tx,ty,'new ID','color',boxCol, ...
                'HorizontalAlignment','center', ...
                'FontSize',W(t-2,id)/2, 'FontUnits','pixels','FontWeight','bold');
            
        end
        
    end
    
    %% indicate false positives
    if options.displayFP
        fpinframe=find(options.allfp(t,:));
        for id=fpinframe
            bleft=X(t,id)-W(t,id)/2;
            bright=X(t,id)+W(t,id)/2;
            btop=Y(t,id)-H(t,id);
            bbottom=Y(t,id);
            boxcurvature=[.3,.3*(W(t,id)/H(t,id))]; boxcurvature=max(0,boxcurvature);boxcurvature=min(1,boxcurvature);
            boxCol=getColorFromID(id);
            if isfield(options,'newColors'), boxCol=options.newColors(id,:); end

%             rectangle('Position',[bleft,btop,W(t,id),H(t,id)],'Curvature',boxcurvature,'EdgeColor',boxCol,'linewidth',options.boxLineWidth,'linestyle','-');
            rectangle('Position',[bleft,btop,W(t,id),H(t,id)],'Curvature',boxcurvature,'EdgeColor',boxCol,'linewidth',2*options.boxLineWidth,'linestyle',':');
            fpcnt=fpcnt+1;
        end
    end
    
    %% indicate false negatives
    if options.displayFN
        fninframe=find(~options.alltr(t,:)  & gtInfo.Xi(t,:));
        for id=fninframe
            bleft=gtInfo.Xi(t,id)-gtInfo.W(t,id)/2;
            bright=gtInfo.Xi(t,id)+gtInfo.W(t,id)/2;
            btop=gtInfo.Yi(t,id)-gtInfo.H(t,id);
            bbottom=gtInfo.Yi(t,id);
            boxCol=getColorFromID(id);
%             if isfield(options,'newColors'), boxCol=options.newColors(id,:); end

            boxcurvature=[.3,.3*(gtInfo.W(t,id)/gtInfo.H(t,id))]; boxcurvature=max(0,boxcurvature);boxcurvature=min(1,boxcurvature);
            rectangle('Position',[bleft,btop,gtInfo.W(t,id),gtInfo.H(t,id)],'Curvature',boxcurvature,'EdgeColor',boxCol,'linewidth',2*options.boxLineWidth,'linestyle','--');
            fncnt=fncnt+1;
        end
    end
    
    %%
    if options.displayIDSwitches
        text(20,390,sprintf('ID: %i',idswcnt),'FontSize',24, 'FontUnits','pixels','FontWeight','bold');
    end
    if options.displayFP
        text(20,420,sprintf('FP: %i',fpcnt),'FontSize',24, 'FontUnits','pixels','FontWeight','bold');
    end
    if options.displayFN
        text(20,450,sprintf('FN: %i',fncnt),'FontSize',24, 'FontUnits','pixels','FontWeight','bold');
    end
    
    if options.displayMetrics
        
        yt=sceneInfo.imgHeight-50; ytoffset=30;        
        xt=150;  xtoffset=0;
        col=[.1 0 .1];
        text(xt+xtoffset,yt,sprintf('MOTA'),'FontSize',20, 'FontUnits','pixels','FontWeight','bold','color',col);
        text(xt+xtoffset,yt+ytoffset,sprintf('%.1f %%',metrics(12)),'FontSize',20, 'FontUnits','pixels','FontWeight','bold','color',col);
        xtoffset=100;
        text(xt+xtoffset,yt,sprintf('MOTP'),'FontSize',20, 'FontUnits','pixels','FontWeight','bold','color',col);
        text(xt+xtoffset,yt+ytoffset,sprintf('%.1f %%',metrics(13)),'FontSize',20, 'FontUnits','pixels','FontWeight','bold','color',col);
        xtoffset=260;
        text(xt+xtoffset,yt,sprintf('FP'),'FontSize',20, 'FontUnits','pixels','FontWeight','bold','color',col);
        text(xt+xtoffset,yt+ytoffset,sprintf('%d',metrics(8)),'FontSize',20, 'FontUnits','pixels','FontWeight','bold','color',col);
        xtoffset=340;
        text(xt+xtoffset,yt,sprintf('FN'),'FontSize',20, 'FontUnits','pixels','FontWeight','bold','color',col);
        text(xt+xtoffset,yt+ytoffset,sprintf('%d',metrics(9)),'FontSize',20, 'FontUnits','pixels','FontWeight','bold','color',col);
        xtoffset=420;
        text(xt+xtoffset,yt,sprintf('IDs'),'FontSize',20, 'FontUnits','pixels','FontWeight','bold','color',col);
        text(xt+xtoffset,yt+ytoffset,sprintf('%d',metrics(10)),'FontSize',20, 'FontUnits','pixels','FontWeight','bold','color',col);

    end
    
    if options.displayDets
        
        
        for k=1:length(detections(t).xp)
%             plot(detections(t).xi(k),detections(t).yi(k),'.','color',options.detcol,'MarkerSize',options.dotSize*detections(t).sc(k));
        end
        
        % show trace
        for tracet=max(1,t-options.traceLength):max(1,t-1)
            ipolpar=(t-tracet)/options.traceLength; % parameter [0,1] for color adjustment
        
%             curTpts=find(alldpoints.tp==tracet);              
%             for ct=curTpts
%                 if labeling(ct)==53 || labeling(ct)==53
%                 plot3(axi(ct),ayi(ct),1, '.', 'color',getColorFromID(labeling(ct)), ...
%                     'MarkerSize',options.dotSize*alldpoints.sp(ct), 'LineSmoothing',LineSmoothing);
%                 end
%             end
           
            
%             foot position
            for k=1:length(detections(tracet).xp)
                plot(detections(tracet).xi(k),detections(tracet).yi(k), ...
                      '.','color',ipolpar*options.grey + (1-ipolpar)*options.detcol,'MarkerSize',options.dotSize*detections(tracet).sc(k));
                
            end
        end
        
%         % show trace
%         for tracet=min(F,t+1):min(F,t+options.traceLength)
%             ipolpar=(t-tracet)/options.traceLength; % parameter [0,1] for color adjustment
%         
%             curTpts=find(alldpoints.tp==tracet);              
%             for ct=curTpts
%                 if labeling(ct)==53 || labeling(ct)==53
%                 plot3(axi(ct),ayi(ct),1, '.', 'color',getColorFromID(labeling(ct)), ...
%                     'MarkerSize',options.dotSize*alldpoints.sp(ct), 'LineSmoothing',LineSmoothing);
%                 end
%             end
%            
%         end
    end
    
    
    % gt comparison
    %     text(20,450,'ours','FontSize',24, 'FontUnits','pixels','FontWeight','bold');
    %     text(200,450,'theirs','FontSize',24, 'FontUnits','pixels','FontWeight','bold');
    %     rectangle('Position',[100 400 30 60],'Curvature',[.3,.3*(W(t,id)/H(t,id))],'EdgeColor',getColorFromID(id),'linewidth',options.boxLineWidth);
    %     rectangle('Position',[300 400 30 60],'Curvature',[.3,.3*(W(t,id)/H(t,id))],'EdgeColor',getColorFromID(id),'linewidth',options.boxLineWidth,'linestyle','--');
    
    pause(options.framePause)
    
        if t==1
            pause(.1);
        end    
    %% save
    if isfield(options,'outFolder');
        im2save=getframe(gcf);
        im2save=im2save.cdata;
        ext='jpg';
%         ext='png';
        [imrows, imcols, imcolors]=size(im2save);
%         if imrows ~= 480
%             im2save=imresize(im2save,[480 640]);
%         end
        if t==1
            pause(.1);
        end
        outfile=sprintf('s%d-f%04d.%s',sceneInfo.scenario,frameNums(t),ext);
%         if isfield(options,'renderframes')
%             outfile=sprintf('s%d-%d.%s',sceneInfo.scenario,tcnt,ext);
%         end
        imwrite(im2save, fullfile(options.outFolder,outfile));
    end
end

end