function stateInfo=getStateForEmptySolution(sceneInfo,opt)
% fill in stateInfo struct for trivial solution

% zero metrics
F=length(sceneInfo.frameNums);
stateInfo.F=F;
stateInfo.Xi=[];stateInfo.Yi=[];stateInfo.W=[];stateInfo.H=[];
% stateInfo.Xi=[];stateInfo.Yi=[];
% stateInfo.Xgp=[];stateInfo.Ygp=[];
stateInfo.X=[];stateInfo.Y=[];
stateInfo.sceneInfo=sceneInfo;    stateInfo.opt=opt;
stateInfo.splines=[];    stateInfo.outlierLabel=0;    stateInfo.labeling=[];

end