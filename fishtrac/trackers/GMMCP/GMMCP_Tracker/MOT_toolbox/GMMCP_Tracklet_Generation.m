function [NN,NN_original, nodes] = GMMCP_Tracklet_Generation(net_cost, firstSeg, lastSeg, Kcliques,seqName,mergingFlag)

appearanceWeight = 0.7;
motionWeight = 1 - appearanceWeight;
dummyWeight = 0.4;
forceExtraCliques = 1;

net_cost.motion = (net_cost.motion + net_cost.motion')/2;
net_cost.appearance = (net_cost.appearance + net_cost.appearance')/2;
Net_Cost_Mat = appearanceWeight*net_cost.appearance + motionWeight*net_cost.motion;

NN = net_cost.ind;

disp('SIZE OF NN')
disp(size(NN))
disp('NN')
disp(NN)
% sometimes there is no tracklet at the end of the video and sizes don't
% match up so we need to do a check here
if lastSeg>size(NN,1)
    lastSeg=size(NN,1);
end

disp('firstSeg')
disp(firstSeg)
disp('lastSeg')
disp(lastSeg)
disp('sum(NN(1:(firstSeg-1)))+1')
disp(sum(NN(1:(firstSeg-1)))+1)

Net_Cost_Mat = Net_Cost_Mat(sum(NN(1:(firstSeg-1)))+1:sum(NN(1:lastSeg)),sum(NN(1:(firstSeg-1)))+1:sum(NN(1:lastSeg)));
motionCost = net_cost.motion(sum(NN(1:(firstSeg-1)))+1:sum(NN(1:lastSeg)),sum(NN(1:(firstSeg-1)))+1:sum(NN(1:lastSeg)));

NN = NN(firstSeg:lastSeg);
disp('SIZE OF NN')
disp(size(NN))
NC = length(NN);
%Mark
%{
if(length(NN)==0)
    NC=1;
    Kcliques=1;
else
%}
Kcliques = max(NN) + forceExtraCliques;
%end

NN_original = NN;
Net_Cost_Mat_Original = Net_Cost_Mat;
dummy_counts = ones(size(NN));

[Net_Cost_Mat, NN, detectionInds, dummyInds] = addDummyNodes_v03(Net_Cost_Mat, NN, dummy_counts, dummyWeight);
Net_Cost_Mat = motionWeightTimeAdapt(Net_Cost_Mat, motionCost, detectionInds, dummyInds, dummyWeight, motionWeight,mergingFlag);

isFindMax = 1;
method = 2;
showDebugInfo = 1;

[nodes, cost, timeSpent] = GMMCP_Solver_ADN(Net_Cost_Mat, NN, NC, isFindMax, method, 100000, 10000000,showDebugInfo, Kcliques,dummyWeight);

% % save(fullfile(savePath,sprintf('segment_%03d_to_%03d.mat',firstSeg, lastSeg)),'Net_Cost_Mat','Net_Cost_Mat_Original','NN_original','dummy_counts','dummyWeight','NN','NC','nodes','cost','Kcliques','timeSpent');
% fprintf('cost: %d, time: %d\n', cost, timeSpent);
end
