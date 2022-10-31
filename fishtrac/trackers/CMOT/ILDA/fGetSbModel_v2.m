function [meanVector, noOfSample, eigenVectors, eigenValues, samplePerClass, meanPerClass] = fGetSbModel_v2(featureVectorInCol, featureLabel, eigenThreshold)
% -----------------------------------------------------------------------
% Performing principal component analysis of between-class scatter matrix
%
% written by T-K. Kim and S-F. Wong, 2007
% -----------------------------------------------------------------------

% Input:
% featureVectorInCol: MxN matrix - each column is a feature vector of the raw dataset, M - dimension size, N - the number of sample
% featureLabel: 1xN vector - each cell stores the class label of a sample
% eigenThreshold: 1x1 value - the min value of eigenvalues to be selected


% Output:
% meanVector: Mx1 vector - the mean vector of all raw data, M is the dimension
% noOfSample: 1x1 value - the number of sample in the raw data
% eigenVectors: MxR matrix - each column is an eigenvector of the between scatter matrix, R is the reduced dimension
% eigenValues: RxR matrix - diagonal matrix storing the eigenvalues of the between scatter matrix
% samplePerClass: 1xC vector - each cell stores the number of sample per class, and C is the number of class
% meanPerClass: RxC matrix - each column stores the mean vector of a certain class
% -----------------------------------------------------------------------


[noOfDimension, noOfSample]=size(featureVectorInCol);

labelSet = unique(featureLabel);
noOfClass = size(labelSet,2);

meanVector = mean(featureVectorInCol, 2); %O(MN)
samplePerClass = zeros(1,noOfClass);
meanPerClass = zeros(noOfDimension, noOfClass);

%O(MN)
for i=1:noOfClass
    classIndex = find(featureLabel==labelSet(i));
    samplePerClass(1,i) = length(classIndex);
    classMean = mean(featureVectorInCol(:,classIndex),2);
    meanPerClass(:,i)=classMean;
end

meanMatrix = repmat(meanVector, 1, noOfClass);
PhiMatrix = (meanPerClass - meanMatrix).*repmat( sqrt(samplePerClass), noOfDimension, 1); %O(MC) PhiMatrix->MxC
S_b = PhiMatrix'*PhiMatrix; %O(MC^2) S_b->CxC

[U Sigma V_T] = svd(S_b); %O(C^3)

testRow = diag(Sigma);
testIdx = find(testRow>eigenThreshold);%*noOfSample);
U = U(:,testIdx);
Sigma = diag( testRow(testIdx) );

eigenVectors = PhiMatrix*(U*inv(sqrt(Sigma))); %O(MC^2+C^3)
eigenValues = Sigma; 

meanPerClass = eigenVectors' * ( meanPerClass - repmat(meanVector, 1, size(meanPerClass,2)) );
