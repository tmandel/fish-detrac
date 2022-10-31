function displayTrackingResult(sceneInfo, stateInfo, rframes)
% Display Tracking Result
%
% Take scene information sceneInfo and
% the tracking result from stateInfo
%


% [~, ~, ~, ~, X Y]=getStateInfo(stateInfo);

[stateInfo.X, stateInfo.Y, stateInfo]= ...
    cleanState(stateInfo.Xi, stateInfo.Yi,stateInfo);
W=stateInfo.W;
H=stateInfo.H;
Xi=stateInfo.Xi;
Yi=stateInfo.Yi;

[F, N]=size(W);

options.defaultColor=[.1 .2 .9];
options.grey=.7*ones(1,3);
options.framePause=0.1/sceneInfo.frameRate; % pause between frames

options.detcol=[.1 .2 .9];


options.traceLength=0; % overlay track from past n frames
options.predTraceLength=0; % overlay track from future n frames
options.dotSize=0;
options.boxLineWidth=2;
options.traceWidth=2;
options.predTraceWidth=1;
if sceneInfo.scenario==41
    options.boxLineWidth=5;
    options.traceWidth=3;    
    options.predTraceWidth=3;
end

options.hideBG=0;

% what to display
options.displayDets=0;
options.displayDots=0;
options.displayBoxes=1;
options.displayID=1;
options.displayCropouts=0;
options.displayConnections=0;
options.displayIDSwitches=0;
options.displayFP=0;
options.displayFN=0;
options.displayMetrics=1;
options.matchColorsToGT=0;

% sceneInfo.imgFileFormat(end-2:end)='png';
% save?
% options.outFolder='tmp/wori';
global clusternr
% global outfolder
% options.outFolder=sprintf('tmp/clnr-%03d/s%d',clusternr,sceneInfo.scenario);
% options.outFolder=sprintf('tmp/IJVC/s%d',clusternr,sceneInfo.scenario);
% options.outFolder=sprintf('tmp/iccv13/single/s%d',sceneInfo.scenario);
% options.outFolder=sprintf('vis/clnr-%03d/s%d',clusternr,sceneInfo.scenario);
options.outFolder='tmp/vis';
% options.outFolder=outfolder;
% options.outFolder=sprintf('d:/acvt/projects/tracker-mot/data/tmp/s%04d',sceneInfo.scenario);
% options.outFolder='d:\acvt\projects\tracker-mot\data\tmp\tld-s0025';
% options.outFolder='d:\acvt\projects\tracker-mot\data\tmp\afl-acf-tld';
% options.outFolder='d:\acvt\projects\tracker-mot\data\tmp\afl-acf-cs-dco\final\stitched';
% options.outFolder=sprintf('tmp/KITTI_PED/s%d',sceneInfo.scenario);
if isfield(options,'outFolder') && ~exist(options.outFolder,'dir')
    mkdir(options.outFolder)
end

h=reopenFig('Tracking Results');


metr=getMetricsForEmptySolution();
if options.displayIDSwitches || options.displayFP || options.displayFN || options.displayMetrics || options.matchColorsToGT
    
    if sceneInfo.gtAvailable
        global gtInfo
        opt=stateInfo.opt;
        
        evopt.eval3d=0;
        if opt.track3d,            evopt.eval3d=1; end
%         evopt.td=.4;
        % maybe we dont have the entire sequence
%         isectfr=intersect(gtInfo.frameNums,stateInfo.frameNums);
%         
%         keep=false(1,length(gtInfo.frameNums));
%         cnt=0;
%         for f=isectfr
%             cnt=cnt+1;
%             if ~isempty(find(stateInfo.frameNums==f, 1))
%                 keep(cnt)=1;
%             end
%         end
%         gtInfo=cropFramesFromGT(sceneInfo,gtInfo,find(keep),opt);
%         gtInfo
%         stateInfo
        [metr,metrInfo,addInf]=CLEAR_MOT(gtInfo,stateInfo,evopt);
        printMetrics(metr,metrInfo,1,[12 13 4 5 7 8 9 10 11 1 2]);    fprintf('\n');
        %         return
        alltr=addInf.alltracked;
        
        %         if options.displayIDSwitches
        allswitches=sparse(F,size(stateInfo.X,2));
        for i=1:size(alltr,2)
            allidsind=find(alltr(:,i));
            switchframes=allidsind(find(diff(alltr(allidsind,i)))+1);
            newids=alltr(allidsind(find(diff(alltr(allidsind,i)))+1),i);
            %     switchframes
            %     newids
            %     size(alltr)
            if ~isempty(switchframes) && ~isempty(newids)
                lininds=sub2ind(size(stateInfo.X),switchframes,newids);
                allswitches(lininds)=1;
            end
        end
        %         end
        options.IDswitches=allswitches;
        options.allfp=addInf.allfalsepos;
        options.alltr=alltr;
        
        %% adjust gtColors
        if options.matchColorsToGT
            newColors=[];
            for id=1:N
                % which gt tracks are covered by id
                [u v]=find(addInf.alltracked==id);
                uniquev = unique(v');

                % which one is the dominant one?
                maxfr=0;
                domid=id;
                for id2=uniquev
                    if numel(find(v==id2)') > maxfr
                        domid=id2;
                    end
                end
                newColors(id,:)=getColorFromID(domid);

    %             pause


            end
            options.newColors=newColors;
        end
    else
        options.displayIDSwitches=0;
        options.displayFP=0;
        options.displayFN=0;
    end
    
    
    
end
% keepids=[9 12 17 19];
% keepids=53;
% Xi=Xi(:,keepids);Yi=Yi(:,keepids);W=W(:,keepids);H=H(:,keepids);
% texist=~~sum(Xi);
% Xi=Xi(:,texist); Yi=Yi(:,texist);W=W(:,texist); H=H(:,texist);
% [Xi Yi W H]=switchID(50,35,Xi,Yi,W,H);
% [Xi Yi W H]=switchID(58,43,Xi,Yi,W,H);
% [Xi Yi W H]=switchID(30,22,Xi,Yi,W,H);
% [Xi Yi W H]=switchID(21,29,Xi,Yi,W,H);
% [Xi Yi W H]=switchID(62,79,Xi,Yi,W,H);
% [Xi Yi W H]=switchID(45,9,Xi,Yi,W,H);
% [Xi Yi W H]=switchID(14,63,Xi,Yi,W,H);
% [Xi Yi W H]=switchID(34,49,Xi,Yi,W,H);
% [Xi Yi W H]=switchID(65,49,Xi,Yi,W,H);
% [Xi Yi W H]=switchID(53,70,Xi,Yi,W,H);
%
% [Xi Yi W H]=switchID(112,144,Xi,Yi,W,H);
% [Xi Yi W H]=switchID(7,69,Xi,Yi,W,H);

% [Xi Yi W H]=switchID(25,50,Xi,Yi,W,H);

% [Xi Yi W H]=switchID(9,6,Xi,Yi,W,H);
% [Xi Yi W H]=switchID(71,90,Xi,Yi,W,H);
% [Xi Yi W H]=switchID(13,64,Xi,Yi,W,H);
% [Xi Yi W H]=switchID(4,5,Xi,Yi,W,H);
% [Xi Yi W H]=switchID(95,83,Xi,Yi,W,H);
% [Xi Yi W H]=switchID(48,64,Xi,Yi,W,H);
% [Xi Yi W H]=switchID(91,116,Xi,Yi,W,H);
% [Xi Yi W H]=switchID(106,110,Xi,Yi,W,H);
% [Xi Yi W H]=switchID(81,105,Xi,Yi,W,H);
% [Xi Yi W H]=switchID(46,62,Xi,Yi,W,H);
% [Xi Yi W H]=switchID(118,83,Xi,Yi,W,H);
% [Xi Yi W H]=switchID(4,3,Xi,Yi,W,H);
% [Xi Yi W H]=switchID(15,87,Xi,Yi,W,H);
% [Xi Yi W H]=switchID(100,78,Xi,Yi,W,H);
% [Xi Yi W H]=switchID(60,77,Xi,Yi,W,H);
% [Xi Yi W H]=switchID(56,73,Xi,Yi,W,H);
% [Xi Yi W H]=switchID(44,59,Xi,Yi,W,H);
% [Xi Yi W H]=switchID(87,112,Xi,Yi,W,H);
% [Xi Yi W H]=switchID(10,7,Xi,Yi,W,H);

% [Xi Yi W H]=switchID(44,50,Xi,Yi,W,H);

if nargin==3
    options.renderframes=rframes;
end

global oinfo
oinfo=options;
displayBBoxes(sceneInfo,stateInfo.frameNums,Xi,Yi,W,H,options,stateInfo.opt,metr)



end

function [Xi Yi W H]=switchID(id1,id2,Xi,Yi,W,H)
Xi(:,[id1 id2])=Xi(:,[id2 id1]); Yi(:,[id1 id2])=Yi(:,[id2 id1]);
H(:,[id1 id2])=H(:,[id2 id1]); W(:,[id1 id2])=W(:,[id2 id1]);
end