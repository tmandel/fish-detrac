function [ILDA]= MOT_ILDA_Update(ILDA, new_data, new_label)
%ILDA pseudocode
%written by T-K. Kim, 2007
%modified by S-H. Bae, 2012
%Reference:
%[1] Incremental linear discriminant analysis using sufficient
%spanning sets and its application, Tae-Kyun Kim, Bjorn Stenger, Josef
%Kittler, IJCV, 2010.
%Incremental LDA of a raw dataset.
%featureVectorInCol: MxN matrix - each column is a feature vector of the
%raw dataset, M - dimension size, N - the number of sample

DeigenThreshold = ILDA.eigenThreshold;
up_ratio = ILDA.up_ratio;
eigenThreshold = ILDA.eigenThreshold;

if ILDA.n_update == 0
    dataset_1 = new_data; label_1 = new_label;
    % init proc
    [m_1,M_1,TeigenVect_1,TeigenVal_1] = fGetStModel(dataset_1,eigenThreshold);
    [m_1, M_1, BeigenVect_1, BeigenVal_1, samplePerClass_1, meanPerClass_1] = fGetSbModel_v2(dataset_1, label_1, eigenThreshold);
    [DiscriminativeComponents D] = fGetDiscriminativeComponents_v2(TeigenVect_1, TeigenVal_1, BeigenVect_1,...
        BeigenVal_1, M_1, DeigenThreshold,up_ratio);
    
    ILDA.m_1 = m_1;
    ILDA.M_1 = M_1;
    ILDA.TeigenVect_1 = TeigenVect_1;
    ILDA.TeigenVal_1 = TeigenVal_1;
    
    ILDA.BeigenVect_1 = BeigenVect_1;
    ILDA.BeigenVal_1 = BeigenVal_1;
    ILDA.samplePerClass_1 = samplePerClass_1;
    ILDA.meanPerClass_1 = meanPerClass_1;
    ILDA.label_1 = label_1;
else
    % for new data
    dataset_2 = new_data; label_2 = new_label;
    [m_2, M_2, TeigenVect_2,TeigenVal_2] = fGetStModel(dataset_2,eigenThreshold);
    [m_2, M_2, BeigenVect_2,BeigenVal_2, samplePerClass_2, meanPerClass_2] = fGetSbModel_v2(dataset_2,label_2,eigenThreshold);
    
    % update 
    m_1 = ILDA.m_1;
    M_1 = ILDA.M_1;
    TeigenVect_1 = ILDA.TeigenVect_1; TeigenVal_1 = ILDA.TeigenVal_1;
    BeigenVect_1 = ILDA.BeigenVect_1; BeigenVal_1 = ILDA.BeigenVal_1;
    samplePerClass_1 = ILDA.samplePerClass_1; meanPerClass_1 = ILDA.meanPerClass_1;
    label_1 = ILDA.label_1;
    
    [outMean, outNSample, outEVect_t, outEVal_t] = fMergeSt(m_1, M_1, TeigenVect_1, TeigenVal_1, m_2, M_2, TeigenVect_2, TeigenVal_2, eigenThreshold);
    [outMean, outNSample, outEVect_b, outEVal_b, outSamplePerClass, outMeanPerClass] = fMergeSb(m_1, M_1, BeigenVect_1, BeigenVal_1, samplePerClass_1, meanPerClass_1, label_1,...
        m_2, M_2, BeigenVect_2, BeigenVal_2, samplePerClass_2, meanPerClass_2, label_2, eigenThreshold);
    [DiscriminativeComponents D] = fGetDiscriminativeComponents_v2(outEVect_t, outEVal_t, outEVect_b,...
        outEVal_b, outNSample,DeigenThreshold,up_ratio);
    
    % update variables
    ILDA.m_1 = outMean;
    ILDA.M_1 = outNSample;
    ILDA.TeigenVect_1 = outEVect_t;
    ILDA.TeigenVal_1 = outEVal_t;
    
    ILDA.BeigenVect_1 = outEVect_b;
    ILDA.BeigenVal_1 = outEVal_b;
    ILDA.samplePerClass_1 = outSamplePerClass;
    ILDA.meanPerClass_1 = outMeanPerClass;
    ILDA.label_1 = horzcat(label_1,label_2);
    
end
ILDA.DiscriminativeComponents = DiscriminativeComponents;
ILDA.D = D;
ILDA.n_update = ILDA.n_update + 1;





