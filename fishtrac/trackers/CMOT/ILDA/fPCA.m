function [principalComponents, eigenValues, meanVector, projectedData] = fPCA(featureVectorInCol, eigenThreshold)
% -----------------------------------------------------------------------
% Low-dimensional batch eigen-computation when M>>N
%
% written by T-K, Kim and S-F. Wong, 2007
% -----------------------------------------------------------------------

% Input:
% featureVectorInCol: MxN matrix - input data, M=dimension, N=noOfSample
% eigenThreshold: 1x1 value - the min value of eigenvalues to be selected

% Output:
% principalComponents: MxR matrix - each column is a PC, R is the reduced dimension
% eigenValues: RxR - diagonal matrix storing the eigenvalues which are > eigenThreshold
% meanVector: Mx1 vector - the mean vector of the input data
% projectedData: RxN matrix - the projected data organised in column
% -----------------------------------------------------------------------


[noOfDimension, noOfSample] = size(featureVectorInCol);
meanVector = mean(featureVectorInCol, 2); % O(MN)

featureVectorInCol=double(featureVectorInCol); 
data = featureVectorInCol - repmat(meanVector, 1, noOfSample);

normCovMatrix = data'*data; % O(N^2M) normCovMatrix->NxN
[V_NN, S_NN,V_NNT] = svd(normCovMatrix); %O(N^3) V_NN->NxR

% Component selection 
testRow = diag(S_NN);
testIdx = find(testRow>eigenThreshold);
V_NN = V_NN(:,testIdx);
S_NN = diag( testRow(testIdx) );


invSigma_NN = inv(diag(sqrt(diag(S_NN))));
principalComponents = data*(V_NN*invSigma_NN); % O(NR^2+MNR)
eigenValues = S_NN;
projectedData = principalComponents'*data; 