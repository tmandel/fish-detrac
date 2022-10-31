function [ Net_Cost_Mat ] = motionWeightTimeAdapt(Net_Cost_Mat, motionCost, detectionInds, dummyInds, dummyWeight, motionWeight,mergingFlag)
%MOTIONWEIGHTTIMEADAPT Summary of this function goes here
%   Detailed explanation goes here
NC = max(max(dummyInds),max(detectionInds));

% It is expected to load "dampingMatrix"
if(~mergingFlag)
    load('motionWeight_midLevelTracklet');
else
    load('motionWeight_6');
end
     
for i = 1:NC
    for j = 1:NC
        if i == j
            continue;
        end
        detectI = (detectionInds == i);
        detectJ = (detectionInds == j);
        dummyI = (dummyInds == i);
        dummyJ = (dummyInds == j);
        clusterNum = nonzeros(detectionInds);
        Net_Cost_Mat(detectI , detectJ) = Net_Cost_Mat(detectI, detectJ) - (1-dampingMatrix(i,j)) * motionWeight * motionCost(clusterNum==i, clusterNum==j);
        Net_Cost_Mat(dummyI, dummyJ) = Net_Cost_Mat(dummyI, dummyJ) - (1-dampingMatrix(i,j)) * motionWeight * dummyWeight;
        Net_Cost_Mat(detectI, dummyJ) = Net_Cost_Mat(detectI, dummyJ) - (1-dampingMatrix(i,j)) * motionWeight * dummyWeight;
        Net_Cost_Mat(dummyI, detectJ) = Net_Cost_Mat(dummyI, detectJ) - (1-dampingMatrix(i,j)) * motionWeight * dummyWeight;
    end
end

end
