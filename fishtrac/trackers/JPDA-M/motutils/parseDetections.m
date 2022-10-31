function [detections nDets]=parseDetections(sceneInfo,frames, confthr)
% read detection file and create a struct array

global opt scenario

nDets=0;

detfile=sceneInfo.detfile;
% first determine the type
[pathstr, filename, fileext]=fileparts(detfile);
% is there a .mat file available?
matfile=fullfile(pathstr,[filename '.mat']);
if exist(matfile,'file')
    load(matfile,'detections')
    detections=setDetectionPositions(detections,opt,sceneInfo);
    
    % rescale confidense if necessary
    if scenario<190
     detections=rescaleConfidence(detections,opt);
    end

    
    % check if all info is available
    if (~isfield(detections,'xp') || ...
            ~isfield(detections,'yp') || ...
            ~isfield(detections,'sc') || ...
            ~isfield(detections,'wd') || ...
            ~isfield(detections,'ht'))
        error('detections must have fields xp,yp,sc,wd,ht');
    end
    
    if nargin>1
        detections=detections(frames);
    end
    

    
    if nargin>2, detections=removeWeakOnes(detections,confthr); end
%     [detections(:).sc]
%     pause
    % count detections
    
    if ~nDets
        for t=1:length(detections),nDets=nDets+length(detections(t).xp);end
    end
%     for t=1:length(detections),detections(t).sc(:)=1;end
    return;
end

if      strcmpi(fileext,'.idl'); detFileType=1;
elseif  strcmpi(fileext,'.xml'); detFileType=2;
else    error('Unknown type of detections file.');
end

%% now parse

if detFileType==1
    % idl type
    % format:
    % "filename": (left top right bottom):score ...
    
    
    direxist=0;
    if ~isempty(strfind(detfile,'with_direction'))
        fprintf('IDL file with directions...\n');
%         idlBoxes=readIDLwithDIR(detfile);
        direxist=1;
%         save('/home/aanton/diss/others/siyu/PETS2009/idlwithdet_S2L2.mat','idlBoxes');
        load('/home/aanton/diss/others/siyu/PETS2009/idlwithdet_S2L2.mat');
    else
        idlBoxes=readIDL(detfile);
    end
    F=size(idlBoxes,2);
    frToParse=1:F;
    if nargin==2, frToParse=frames; end
    
    for t=frToParse
        
        nboxes=size(idlBoxes(t).bb,1); % how many detections in current frame
        xis=zeros(1,nboxes);
        yis=zeros(1,nboxes);
        heights=zeros(1,nboxes);
        widths=zeros(1,nboxes);
        boxleft=zeros(1,nboxes);
        boxtop=zeros(1,nboxes);
        scores=zeros(1,nboxes);
        dirs=zeros(1,nboxes);
        for boxid=1:nboxes
            
            bbox=idlBoxes(t).bb(boxid,:);
            bbox([1 3])=bbox([1 3]);  bbox([2 4])=bbox([2 4]);
            
            % box extent
            heights(boxid)=bbox(4)-bbox(2);
            widths(boxid)=bbox(3)-bbox(1);
            
            % box left top corner
            boxleft(boxid)=bbox(1);
            boxtop(boxid)=bbox(2);
            
            % foot position
            xis(boxid) = bbox(1)+widths(boxid)/2;   % horizontal (center)
            yis(boxid) = bbox(4);                       % vertical   (bottom)
            
            
            % score
            scores(boxid)=idlBoxes(t).score(boxid);
%             scores(boxid)=scores(boxid)-1;
%             pause
            
            if direxist
            % direction
            dirs(boxid)=idlBoxes(t).dir(boxid);
            end
            
        end
        
        detections(t).bx=boxleft;
        detections(t).by=boxtop;
        detections(t).xp=xis;
        detections(t).yp=yis;
        detections(t).ht=heights;
        detections(t).wd=widths;
        detections(t).sc=scores;
        
        detections(t).xi=xis;
        detections(t).yi=yis;
        
        if direxist
            for boxid=1:nboxes
                [detections(t).dirxi(boxid) detections(t).diryi(boxid)]=getDirFromIndex(dirs(boxid));
                detections(t).dirind(boxid)=dirs(boxid);
            end
        end
        
        nDets=nDets+length(xis);
        
    end
    
    % sigmoidify
%     sigA=0;    sigB=1;
%     for t=1:length(detections)
%         detections(t).sc=1./(1+exp(sigA-sigB*detections(t).sc));
%     end
    
elseif detFileType==2
    xDoc=xmlread(detfile);
    allFrames=xDoc.getElementsByTagName('frame');
    F=allFrames.getLength;
    frameNums=zeros(1,F);
    
    
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
    
end



%% if we want to track in 3d, project onto ground plane
detections=projectToGP(detections,sceneInfo);

%% set xp and yp accordingly
detections=setDetectionPositions(detections,opt,sceneInfo);


% save detections in a .mat file
save(matfile,'detections');

end


function detections=projectToGP(detections,sceneInfo)
    global opt
    F=length(detections);
    
    % PRML
    if sceneInfo.scenario>300 && sceneInfo.scenario<400
        for t=1:length(detections)
            detections(t).xw = sceneInfo.camPar.scale*detections(t).xi;
            detections(t).yw = sceneInfo.camPar.scale*detections(t).yi;
        end
        return;
    end
    
    
    direxist=isfield(detections(1),'dirxi');
    if opt.track3d
        heightweight=zeros(F,0);
        % height prior:
        muh=1.7; sigmah=.7; factorh=1/sigmah/sqrt(2*pi);

        [mR mT]=getRotTrans(sceneInfo.camPar);

        for t=1:length(detections)
            if ~mod(t,10), fprintf('.'); end
%             figure(1)
%         clf
%         im=double(imread([sceneInfo.imgFolder sprintf(sceneInfo.imgFileFormat,1)]))/255;
%         imshow(im,'Border','tight')
%         hold on
%         
%         figure(2); clf; xlim([sceneInfo.trackingArea(1:2)]);ylim([sceneInfo.trackingArea(3) - 0000, sceneInfo.trackingArea(4)+0000]);
%         hold on
%         
%         figure(1)
            
            ndet=length(detections(t).xp);
            detections(t).xw=zeros(1,ndet);
            detections(t).yw=zeros(1,ndet);

            for det=1:ndet
%                 detections(t).dirxi(det)=0; detections(t).diryi(det)=-1; detections(t).dirind(det)=3;
                [xw yw zw]=imageToWorld(detections(t).xi(det), detections(t).yi(det), sceneInfo.camPar);
                detections(t).xw(det)=xw;
                detections(t).yw(det)=yw;

                % one meter
                xi=detections(t).xi(det);yi=detections(t).yi(det);
                [xiu yiu]=worldToImage(xw,yw,1000,mR,mT,sceneInfo.camPar.mInt,sceneInfo.camPar.mGeo);
                onemeteronimage=norm([xi yi]-[xiu yiu]);
                worldheight=detections(t).ht(det)/onemeteronimage; % in meters
                weight=normpdf(worldheight,muh,sigmah)/factorh;

                detections(t).sc(det)=detections(t).sc(det)*weight;
                
                if direxist
                    
                    % cam dir on ground plane
                    camWorldPosX=sceneInfo.camPar.mExt.mTxi;
                    camWorldPosY=sceneInfo.camPar.mExt.mTyi;
                    camdir=[xw - camWorldPosX; yw - camWorldPosY];
                    camdir=camdir/norm(camdir);
                    
%                     camdirlong=5000*camdir;
%                     [camdirXI camdirYI]=worldToImage(xw+camdirlong(1),yw+camdirlong(2),0,mR,mT,sceneInfo.camPar.mInt,sceneInfo.camPar.mGeo);
%                     [camdirXI camdirYI]=worldToImage(strangeFac*sceneInfo.camPar.mExt.mTxi,strangeFac*sceneInfo.camPar.mExt.mTyi,0,mR,mT,sceneInfo.camPar.mInt,sceneInfo.camPar.mGeo);
% %                     [camdirXI camdirYI]
% %                     [xi yi]
%                     [xwnorthvec ywnorthvec ~]=imageToWorld( ...
%                         xi,yi-1, sceneInfo.camPar);
%                     
%                     northvec=[xwnorthvec-xw ywnorthvec-yw];
%                     northvec=northvec/norm(northvec);
%                     northveclong=5000*northvec;
%                     [northdirXI northdirYI]=worldToImage(xw+northveclong(1),yw+northveclong(2),0,mR,mT,sceneInfo.camPar.mInt,sceneInfo.camPar.mGeo);
%                     camdir
%                     northvec
                    

% %                     detections(t)
%                     
%                     line([detections(t).xi(det), detections(t).xi(det) + 20*detections(t).dirxi(det)], ...
%                          [detections(t).yi(det), detections(t).yi(det) + 20*detections(t).diryi(det)],'linewidth',3,'color',getColorFromID(det));
% %                     line([detections(t).xi(det), camdirXI], ...
% %                          [detections(t).yi(det), camdirYI],'linewidth',2,'color','r');
% %                      line([detections(t).xi(det), northdirXI], ...
% %                          [detections(t).yi(det), northdirYI],'linewidth',2,'color','c');
% 
%                      plot(detections(t).xi(det),detections(t).yi(det),'.','MarkerSize',20,'color',getColorFromID(det));
%                      text(xi+10,yi+10,sprintf('%d',det),'color',getColorFromID(det));
% 
% %                     devtheta=acos(devtheta);
% %                     
% %                     if detections(t).xi(det) > sceneInfo.camPar.mGeo.mImgWidth/2 %768-sceneInfo.camPar.mInt.mCx
% %                         devtheta=2*pi-devtheta;
% %                     end
% %                     degtheta=rad2deg(devtheta)
                    
                    
                    thetaoffset=0;
                    switch(detections(t).dirind(det))
                        case 1
                            thetaoffset=-pi/2;
                        case 2
                            thetaoffset=-pi/4;
                        case 3
                            thetaoffset=0;
                        case 4
                            thetaoffset=pi/4;
                        case 5
                            thetaoffset=pi/2;
                        case 6
                            thetaoffset=3*pi/4;
                        case 7
                            thetaoffset=pi;
                        case 8
                            thetaoffset=-3*pi/4;
                    end
%                     thetaoffset=0;
                    newdirworld=[cos(thetaoffset) -sin(thetaoffset); sin(thetaoffset) cos(thetaoffset)]*camdir;
                    detections(t).dirxw(det)=newdirworld(1);
                    detections(t).diryw(det)=newdirworld(2);
%                     dirworld
%                     newdirworld
                    
%                     figure(2)
%                     plot(xw,yw,'.','MarkerSize',20,'color',getColorFromID(det));
%                     line([xw xw+2000*newdirworld(1)],[yw yw+2000*newdirworld(2)],'color',getColorFromID(det),'linewidth',2)
%                     text(xw+100,yw+100,sprintf('%d',det),'color',getColorFromID(det));
%                     
%                     figure(1)

%                     pause
                end
            end

            %         detections(t).xp=detections(t).xw;
            %         detections(t).yp=detections(t).yw;
            
            % gt

%             global gtInfo
%             [Fgt Ngt]=size(gtInfo.X);
% 
%             gtEx=find(gtInfo.X(t,:));
%             for gid=gtEx
%                 c=gtInfo.Xgp(t,gid);        d=gtInfo.Ygp(t,gid);
%                 e=gtInfo.Xgp(t+1,gid);        f=gtInfo.Ygp(t+1,gid);
%                 
%                 ci=gtInfo.Xi(t,gid);        di=gtInfo.Yi(t,gid);
%                 ei=gtInfo.Xi(t+1,gid);        fi=gtInfo.Yi(t+1,gid);
% 
% 
%         %         v1=([c; d] - [a; b]);
%                 v2=([e; f] - [c; d]);
%                 v2i=([ei; fi] - [ci; di]);
% 
% 
% %                 m1=sqrt(v1(1)^2 + v1(2)^2);
%                 m2=sqrt(v2(1)^2 + v2(2)^2);
%                 m2i=sqrt(v2i(1)^2 + v2i(2)^2);
%                 gtOri.X(t,gid)=v2(1)/m2;                gtOri.Y(t,gid)=v2(2)/m2;
%                 gtOri.Xi(t,gid)=v2i(1)/m2i;                gtOri.Yi(t,gid)=v2i(2)/m2i;
%                 
%                 figure(2)
%                 plot(c,d,'o','MarkerSize',10,'color','r');
%                 line([c c+2000*gtOri.X(t,gid)],[d d+2000*gtOri.Y(t,gid)],'color','r')
%                 line([c e],[d f],'color','k')
%                 
%                 figure(1)
%                 plot(ci,di,'o','MarkerSize',10,'color','r');
%                 line([ci ci+20*gtOri.Xi(t,gid)],[di di+20*gtOri.Yi(t,gid)],'color','r')
%                 line([ci ei],[di fi],'color','k')
%                 
% 
%             end
%             pause
        end
    end
end

function detections=setDetectionPositions(detections,opt,sceneInfo)
% set xp,yp to xi,yi if tracking is in image (2d)
% set xp,yp to xw,yi if tracking is in world (3d)
F=length(detections);
if opt.track3d
    assert(isfield(detections,'xw') && isfield(detections,'yw'), ...
        'for 3D tracking detections must have fields ''xw'' and ''yw''');
    
    for t=1:F,  detections(t).xp=detections(t).xw;detections(t).yp=detections(t).yw;        end
else
    for t=1:F,  
        detections(t).xp=detections(t).xi;
        detections(t).yp=detections(t).yi;  
        % YSHIFT
        if sceneInfo.yshift
            detections(t).yp=detections(t).yi-detections(t).ht/2;        
        end
    end
end

% do we have direction?
if isfield(detections(1),'dirxi')
    if opt.track3d
        assert(isfield(detections,'dirxw') && isfield(detections,'diryw'), ...
            'for 3D tracking detections must have fields ''dirxw'' and ''diryw''');

        for t=1:F,  detections(t).dirx=detections(t).dirxw;detections(t).diry=detections(t).diryw;        end
    else
        for t=1:F,  detections(t).dirx=detections(t).dirxi;detections(t).diry=detections(t).diryi;        end
    end    
end

end

function detections=removeWeakOnes(detections,confthr)
    % remove weak ones
    
    fnames=fieldnames(detections(1));
    for t=1:length(detections)
        tokeep=detections(t).sc>confthr;
        for fn=1:length(fnames)
            fnstr=fnames{fn};
            replstr=sprintf('detections(t).%s=detections(t).%s(tokeep);',fnstr,fnstr);
            eval(replstr);
            
        end
    end

end

function [dirxi diryi]=getDirFromIndex(dirind)
dirxi=1; diryi=0;

one_div_sqrt2=1/sqrt(2);
switch(dirind)
    case 1
        dirxi=1; diryi=0;
    case 2
        dirxi=one_div_sqrt2; diryi=-one_div_sqrt2;
    case 3
        dirxi=0; diryi=-1;
    case 4
        dirxi=-one_div_sqrt2; diryi=-one_div_sqrt2;
    case 5
        dirxi=-1; diryi=0;
    case 6
        dirxi=-one_div_sqrt2; diryi=one_div_sqrt2;
    case 7
        dirxi=0; diryi=1;
    case 8
        dirxi=one_div_sqrt2; diryi=one_div_sqrt2;
end

end

function res = comp_gauss(x, mu, sigma)

  res = exp(-0.5 * (x - mu).^2 / sigma^2) / (sqrt(2*pi) * sigma);
end

function detections=sigmoidify(detections,opt)
if isfield(opt,'detScale')
    sigA=opt.detScale.sigA;    sigB=opt.detScale.sigB;
    for t=1:length(detections)
        detections(t).sc=1./(1+exp(-sigB*detections(t).sc+sigA*sigB));
    end 
end
end

function detections=rescaleConfidence(detections,opt)

if isfield(opt,'detScale')
    
%     if ~isempty(intersect(scenario,[24 26]))
%     % desigmoidify
%     
    sigA=0;    sigB=1;
    for t=1:length(detections)
        detections(t).sc= (sigA - log(1./detections(t).sc - 1)/sigB);
    end    
%     
%         SIG.mean_tp= 2.5170;    SIG.std_tp= 6.7671;
%     SIG.mean_fp= -11.4631;    SIG.std_fp= 6.5885;
%     for t=1:length(detections)
%         g1 = comp_gauss(detections(t).sc, SIG.mean_tp, SIG.std_tp);
%         g2 = comp_gauss(detections(t).sc, SIG.mean_fp, SIG.std_fp);
%         detections(t).sc= g1 ./ (g1+g2);
%     end    
% 
%     % resigmoidify
    sigA=opt.detScale.sigA;    sigB=opt.detScale.sigB;
    for t=1:length(detections)
        detections(t).sc=1./(1+exp(-sigB*detections(t).sc+sigA*sigB));
    end
end
%     end

end