function [Net_Cost_Mat_dummy, NN_dummy, detectionInds, dummyInds] = addDummyNodes_v03(Net_Cost_Mat, NN, dummyCounts, dummyWeight)


disp('NN:');
disp(NN);
disp('length of NN');
disp(length(NN));

Net_Cost_Mat_dummy = ones(sum(NN)+sum(dummyCounts))*dummyWeight;
disp('Net_Cost_Mat_dummy before:')
disp(Net_Cost_Mat_dummy)
detectionInds = [];
dummyInds = [];



count = 0;
for i = 1:length(NN)
    detectionInds = [detectionInds; ones(NN(i),1)*i; zeros(dummyCounts(i),1)];
    dummyInds = [dummyInds; zeros(NN(i),1); ones(dummyCounts(i),1)*i];
    Net_Cost_Mat_dummy(count+1:count+NN(i)+dummyCounts(i),count+1:count+NN(i)+dummyCounts(i)) = NaN;
    count = count + NN(i) + dummyCounts(i);
end
%oldInds = logical(oldInds);
%Mark
%{
if(length(NN)==0)
    clusters = 1
    detectionInds = zeros(clusters,1);
    dummyInds = zeros(clusters,1);
    Net_Cost_Mat_dummy(1:clusters,1:clusters)=NaN;
    for i = 1:clusters
        dummyInds(i,1)=i;
        Net_Cost_Mat_dummy(i,i)=dummyWeight;
    end
    NN_dummy=ones(clusters,1);

else
%}
Net_Cost_Mat_dummy(detectionInds>0, detectionInds>0) = Net_Cost_Mat;
% Net_Cost_Mat_dummy(oldInds, ~oldInds) = dummyWeight;
% Net_Cost_Mat_dummy(~oldInds, oldInds) = dummyWeight;
Net_Cost_Mat_dummy(detectionInds==0, detectionInds==0) = Net_Cost_Mat_dummy(detectionInds==0, detectionInds==0);% -0.001;
NN_dummy = NN + dummyCounts;
%end
nodesAdded = ones(size(Net_Cost_Mat_dummy,1),1);
nodesAdded(detectionInds>0) = 0;
disp('Net_Cost_Mat_dummy:')
disp(Net_Cost_Mat_dummy)
disp('NN_dummy:')
disp(NN_dummy)
disp('detectionInds:')
disp(detectionInds)
disp('dummyInds:')
disp(dummyInds)
end

