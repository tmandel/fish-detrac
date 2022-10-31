
% ILDA pseudocode

% written by T-K. Kim, 2007

dataset_1 = init_data; label_1 = init_label;


for nupdate=0:numOfupdate
    
    if(nupdate==0)

        % init proc
        [m_1, M_1, TeigenVect_1, TeigenVal_1] = fGetStModel(dataset_1, eigenThreshold);
        [m_1, M_1, BeigenVect_1, BeigenVal_1, samplePerClass_1, meanPerClass_1] = fGetSbModel(dataset_1, label_1, eigenThreshold);
        [DiscriminativeComponents D] = fGetDiscriminativeComponents(TeigenVect_1, TeigenVal_1, BeigenVect_1, BeigenVal_1, M_1, DeigenThreshold);
        
    else

        % for new data
        dataset_2 = New_data; label_2 = New_label; 
        [m_2, M_2, TeigenVect_2, TeigenVal_2] = fGetStModel(dataset_2, eigenThreshold);
        [m_2, M_2, BeigenVect_2, BeigenVal_2, samplePerClass_2, meanPerClass_2] = fGetSbModel(dataset_2, label_2, eigenThreshold);

        % update
        [outMean, outNSample, outEVect_t, outEVal_t] = fMergeSt(m_1, M_1, TeigenVect_1, TeigenVal_1, m_2, M_2, TeigenVect_2, TeigenVal_2, eigenThreshold);
        [outMean, outNSample, outEVect_b, outEVal_b, outSamplePerClass, outMeanPerClass] = fMergeSb(m_1, M_1, BeigenVect_1, BeigenVal_1, samplePerClass_1, meanPerClass_1, label_1, m_2, M_2, BeigenVect_2, BeigenVal_2, samplePerClass_2, meanPerClass_2, label_2, eigenThreshold);
        [DiscriminativeComponents D] = fGetDiscriminativeComponents(outEVect_t, outEVal_t, outEVect_b, outEVal_b, outNSample,DeigenThreshold);

        % update variables
        m_1 = outMean; M_1 = outNSample; TeigenVect_1=outEVect_t; TeigenVal_1=outEVal_t;
        BeigenVect_1=outEVect_b; BeigenVal_1=outEVal_b; 
        samplePerClass_1=outSamplePerClass; meanPerClass_1=outMeanPerClass;
        label_1 = horzcat(label_1,label_2);
        
    end
    
end