function [meanVector, noOfSample, eigenVectors, eigenValues, samplePerClass, meanPerClass] = fMergeSb(inMean_1, inNS_1, inEVect_1, inEVal_1, samplePerClass_1, meanPerClass_1, featureLabel_1, inMean_2, inNS_2, inEVect_2, inEVal_2, samplePerClass_2, meanPerClass_2, featureLabel_2, eigenThreshold)
% -----------------------------------------------------------------------
% Merging two "between scatter matrices"
%
% written by T-K. Kim and S-F. Wong, 2007
% -----------------------------------------------------------------------

% Input:
% inMean_1: Mx1 vector - the mean vector of the old data 
% inNS_1: 1x1 value - the number of sample in the old data
% inEVect_1: MxR_1 matrix - each column is an eigenvector of the between scatter matrix of the old data, R_1 is the reduced dimension
% inEVal_1: R_1xR_1 matrix - diagonal matrix storing the eigenvalues of the between scatter matrix of the old data
% samplePerClass_1: 1xC_1 vector - each cell stores the number of sample per class in the old data, and C_1 is the number of class
% meanPerClass_1: R_1xC_1 matrix - each column stores the mean vector of a certain class in the old data
% featureLabel_1: 1xN_1 vector - each cell stores the class label of a sample in the old data

% inMean_2: Mx1 vector - the mean vector of the new data 
% inNS_2: 1x1 value - the number of sample in the new data
% inEVect_2: MxR_2 matrix - each column is an eigenvector of the total scatter matrix of the new data, R_2 is the reduced dimension
% inEVal_2: R_2xR_2 matrix - diagonal matrix storing the eigenvalues of the total scatter matrix of the new data
% samplePerClass_2: 1xC_2 vector - each cell stores the number of sample per class in the new data, and C_2 is the number of class
% meanPerClass_2: R_2xC_2 matrix - each column stores the mean vector of a certain class in the new data
% featureLabel_2: 1xN_2 vector - each cell stores the class label of a sample in the new data


% Output:
% meanVector: Mx1 vector - the updated mean vector of all raw data, M is the dimension
% noOfSample: 1x1 value - the number of sample in the raw data
% eigenVectors: MxR matrix - each column is an eigenvector of the between scatter matrix, R is the reduced dimension
% eigenValues: RxR matrix - diagonal matrix storing the eigenvalues of the between scatter matrix
% samplePerClass: 1xC vector - each cell stores the number of sample per class, and C is the number of class
% meanPerClass: RxC matrix - each column stores the mean vector of a certain class
% -----------------------------------------------------------------------

noOfDimension = size(inEVect_1, 1);
noOfSample = inNS_1 + inNS_2;
meanVector = (inMean_1 * inNS_1 + inMean_2 * inNS_2 ) / (noOfSample); 

% QR:
residueThreshold = 0.0001;

GMatrix = inEVect_1' *inEVect_2; % O(R_1MR_2) GMatrix->R_1xR_2
meanDiff = inMean_1-inMean_2;
residue = inEVect_2 - inEVect_1 * (GMatrix); % O(MR_1R_2)
residueSumRow = sum(abs(residue),1);
pureResidue = residue(:,find(residueSumRow>residueThreshold));
meanResidue = meanDiff - inEVect_1 * (inEVect_1' * meanDiff); % O(MR_1)
meanResidueSumRow = sum(abs(meanResidue),1);
meanResidue = meanResidue(:,find(meanResidueSumRow>residueThreshold));

[OrthSubMatrix upperTri] = qr([pureResidue meanResidue], 0); % O(MR_2^2) OrthSubMatrix->MxR

qrThreshold = 0.0001;
upperTriSum = sum(abs(upperTri),2);
upperTriRowIndex = find(upperTriSum>qrThreshold)';
OrthSubMatrix = OrthSubMatrix(:,upperTriRowIndex);

% %%% Removing zero-columns in OrthMatrix:::
nonZeroThreshold = 0.0001;
OrthMatrixSum = sum(abs(OrthSubMatrix),1);
nonZeroIndex = find(OrthMatrixSum>nonZeroThreshold);
OrthSubMatrix = OrthSubMatrix(:,nonZeroIndex);

%SVD
TMatrix = OrthSubMatrix' * inEVect_2; % O(MRR_2) TMatrix->RxR_2
mGMatrix = inEVect_1'*meanDiff; % O(MR_1) mGMatrix->R_1x1
mTMatrix = OrthSubMatrix'*meanDiff; % O(MR) mTMatrix->Rx1

reducedDim = size(inEVect_1, 2) + size(OrthSubMatrix,2);

term1 = zeros(reducedDim, reducedDim);
term1(1:size(inEVect_1,2),1:size(inEVect_1,2)) = inEVal_1;
term2 = [GMatrix*inEVal_2*GMatrix' GMatrix*inEVal_2*TMatrix'; TMatrix*inEVal_2*GMatrix' TMatrix*inEVal_2*TMatrix']; % O( max(R_1, R_2, R)^3) 
term4 = [mGMatrix*mGMatrix' mGMatrix*mTMatrix'; mTMatrix*mGMatrix' mTMatrix*mTMatrix']  *((inNS_1*inNS_2)/(noOfSample)); % O( max(R_1, R)^2)

% for common classes
term3 = zeros(reducedDim, reducedDim);
% O(C^2 M R_i)
labelSet1 = union([],featureLabel_1);
labelSet2 = union([],featureLabel_2);
labelSet_com = intersect(labelSet1, labelSet2);
if(length(labelSet_com))
    for i=1:length(labelSet_com)
        idx1 = find(labelSet_com(i)==labelSet1);
        idx2 = find(labelSet_com(i)==labelSet2);
                
        coeff = (-samplePerClass_1(1,idx1)*samplePerClass_2(1,idx2)) / (samplePerClass_1(1,idx1)+samplePerClass_2(1,idx2)) ;
        classmeanDiff = (inEVect_1 * meanPerClass_1(:,idx1) + inMean_1 - inEVect_2 * meanPerClass_2(:,idx2) - inMean_2); % O(MR_iC)
        cGMatrix = inEVect_1'*classmeanDiff; % O(R_1M)
        cTMatrix = OrthSubMatrix'*classmeanDiff; % O(RM)
        term3 = term3 + [cGMatrix*cGMatrix' cGMatrix*cTMatrix';cTMatrix*cGMatrix' cTMatrix*cTMatrix']*coeff; % O(max(R_1, R)^2)
    end
end
    
CompositeMatrix = term1+term2+term3+term4; % CompositeMatrix->RxR

[U Sigma V_T] = svd(CompositeMatrix); % O(R^3)

testRow = diag(Sigma);


testIdx = find(testRow>eigenThreshold);%*noOfSample);
U = U(:,testIdx);
Sigma = diag( testRow(testIdx) );


eigenVectors = [inEVect_1 OrthSubMatrix] * U; % O(M (R_1+R) R)
eigenValues = Sigma;


% updates other params.
featureLabel = horzcat(featureLabel_1, featureLabel_2);
labelSet = union([],featureLabel);
noOfClass = size(labelSet,2);
samplePerClass = zeros(1,noOfClass);
meanPerClass = zeros( size(eigenVectors, 2), noOfClass);

for i=1:length(labelSet)
    idx1 = find(labelSet(i)==labelSet1);
    idx2 = find(labelSet(i)==labelSet2);
    subMean_3 = zeros(noOfDimension,1);

    if(length(idx1))
        samplePerClass(1,i) = samplePerClass(1,i) + samplePerClass_1(1,idx1);
        subMean_3 = subMean_3 + samplePerClass_1(1,idx1)*(inEVect_1 * meanPerClass_1(:,idx1) + inMean_1);
    end
    if(length(idx2))
        samplePerClass(1,i) = samplePerClass(1,i) + samplePerClass_2(1,idx2);
        subMean_3 = subMean_3 + samplePerClass_2(1,idx2)*(inEVect_2 * meanPerClass_2(:,idx2) + inMean_2);
    end
    
    subMean_3 = subMean_3/samplePerClass(1,i);
    meanPerClass(:,i) = eigenVectors'*(subMean_3-meanVector);
end

