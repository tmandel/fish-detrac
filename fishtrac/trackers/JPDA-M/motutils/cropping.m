%%
gtOld=hamid.gtInfo;
stOld=hamid.stateInfo2;


gtOld.X=gtOld.Xgp;gtOld.Y=gtOld.Ygp;
stOld.X=stOld.Xgp;stOld.Y=stOld.Ygp;

sceneInfo.trackingArea=[-14069.6, 4981.3, -14274.0, 1733.5];

gtNew=cutGTToTrackingArea(gtOld,sceneInfo);

% displayGroundTruth(sceneInfo,gtNew);

opt.track3d=1;
stNew=cutStateToTrackingArea(stOld,sceneInfo,opt);

%%
% texist=~~sum(stNew.X);		% which columns actually contain targets?
% stNew.X=stNew.X(:,texist); stNew.Y=stNew.Y(:,texist);	% keep only these
% if isfield(stNew,'Xgp')
%     stNew.Xgp=stNew.Xgp(:,texist);stNew.Ygp=stNew.Ygp(:,texist);
% end
% if isfield(stNew,'Xi')
%     stNew.Xi=stNew.Xi(:,texist);stNew.Yi=stNew.Yi(:,texist);
% end
% if isfield(stNew,'W')
%     stNew.W=stNew.W(:,texist);stNew.H=stNew.H(:,texist);
% end

%%
% also split fragmented trajectories

% [F N]=size(stNew.X);
% for i=1:N
%     frags=~~stNew.X(:,i);
%     starts=find(frags(1:end-1)==frags(2:end)-1)+1;
%     ends=find(frags(1:end-1)==frags(2:end)+1);
%     if frags(1), starts=[1; starts]; end
%     if frags(end), ends=[ends; numel(frags)]; end
%     for s=2:numel(starts)
%         stNew.X(starts(s):ends(s),end+1)=stNew.X(starts(s):ends(s),i);stNew.X(starts(s):ends(s),i)=0;
%         stNew.Y(starts(s):ends(s),end+1)=stNew.Y(starts(s):ends(s),i);stNew.Y(starts(s):ends(s),i)=0;
%         if isfield(stNew,'Xi')
%             stNew.Xi(starts(s):ends(s),end+1)=stNew.Xi(starts(s):ends(s),i);stNew.Xi(starts(s):ends(s),i)=0;
%             stNew.Yi(starts(s):ends(s),end+1)=stNew.Yi(starts(s):ends(s),i);stNew.Yi(starts(s):ends(s),i)=0;
%         end
%         if isfield(stNew,'Xgp')
%             stNew.Xgp(starts(s):ends(s),end+1)=stNew.Xgp(starts(s):ends(s),i);stNew.Xgp(starts(s):ends(s),i)=0;
%             stNew.Ygp(starts(s):ends(s),end+1)=stNew.Ygp(starts(s):ends(s),i);stNew.Ygp(starts(s):ends(s),i)=0;
%         end
%         if isfield(stNew,'W')
%             stNew.W(starts(s):ends(s),end+1)=stNew.W(starts(s):ends(s),i);stNew.W(starts(s):ends(s),i)=0;
%             stNew.H(starts(s):ends(s),end+1)=stNew.H(starts(s):ends(s),i);stNew.H(starts(s):ends(s),i)=0;
%         end
%     end
% end



% displayTrackingResult(sceneInfo,stNew);
[metrics3d, metricsInfo3d, addInfo3d]=CLEAR_MOT(gtNew,stNew,struct('eval3d',1)); printMetrics(metrics3d,metricsInfo3d,1);
stNew.opt.track3d=0;

stNew.X=stNew.Xi;stNew.X=stNew.Yi;
gtNew.X=gtNew.Xi;gtNew.Y=gtNew.Yi;

[metrics3d, metricsInfo3d, addInfo3d]=CLEAR_MOT(gtNew,stNew,struct('eval3d',0)); printMetrics(metrics3d,metricsInfo3d,1);
