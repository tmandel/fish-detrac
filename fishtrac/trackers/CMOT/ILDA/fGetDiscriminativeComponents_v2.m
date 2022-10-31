function [DiscriminativeComponents S_N] = fGetDiscriminativeComponents_v2(totalEigVect, totalEigVal, betweenEigVect, betweenEigVal, outNSample,eigenThreshold,totalTermFactorZ_Limit)
% -----------------------------------------------------------------------
% Getting discriminative component
%
% written by T-K. Kim and S-F. Wong, 2007
% -----------------------------------------------------------------------

% Input:
% totalEigVect: MxR_t matrix - each column is an eigenvector of the total scatter matrix, R_t is the reduced dimension
% totalEigVal: R_txR_t matrix - diagonal matrix storing the eigenvalues of the total scatter matrix
% betweenEigVect: MxR_b matrix - each column is an eigenvector of the between scatter matrix, R_b is the reduced dimension
% betweenEigVal: R_bxR_b matrix - diagonal matrix storing the eigenvalues of the between scatter matrix


% Output:
% DiscriminativeComponents: MxR_d matrix - each column is a discriminative component, R_d is the reduced dimension
%
%
% *Caution* : 
% LDA accuracy is dependent on the dimensionality of both
% intermediate components (total scatter matrix) and the final discriminant
% components. They should be set by a priori.
%
% -----------------------------------------------------------------------

totalTermFactorZ = totalEigVect * inv(sqrt(totalEigVal)); %O(MC^2) totalTermFactorZ->MxR_t
                                    
% here, the dimension of total scatter matrix may be controlled...
% totalTermFactorZ = totalTermFactorZ(:,1:??);

num_total = floor(size(totalTermFactorZ,2));

totalTermFactorZ = totalTermFactorZ(:,1:num_total);

% totalTermFactorZ_Limit = ILDA.totalTermFactorZ_Limit;
if num_total > totalTermFactorZ_Limit
    totalTermFactorZ = totalTermFactorZ(:,1:totalTermFactorZ_Limit);
end

[spanningSetTau upperTriMat] = qr(totalTermFactorZ'*betweenEigVect, 0); % O(MR_tR_b + max(R_t,R_b)^3) spanningSetTau->R_txR
                                                                    
% removing non-significant components for further speed-up
qrThreshold = 0.0001;
upperTriSum = sum(abs(upperTriMat),2);
upperTriRowIndex = find(upperTriSum>qrThreshold)';
spanningSetTau = spanningSetTau(:,upperTriRowIndex);

halfMatrix = spanningSetTau' * (totalTermFactorZ' * betweenEigVect); % O(MR_tR_b + RR_tR_b) halfMatrix->RxR_b
compositeMatrix = halfMatrix * betweenEigVal * halfMatrix';  % O(RR_bR_b + R^2R_b) compositeMatrix->RxR: 
[U_N S_N U_NT] = svd(compositeMatrix); % O(R^3)

testRow = diag(S_N);
testIdx = find(testRow>eigenThreshold);
U_N = U_N(:,testIdx);
S_N = diag( testRow(testIdx) );

DiscriminativeComponents = totalTermFactorZ * (spanningSetTau * U_N); % O(R^2R_t + MR^2) 

% here, the dimension of the discriminant components may be controlled...
