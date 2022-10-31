function [Size_Affinity, Motion_Affinity] = MotionAffinityModel(pred_state,det_state,Model,Constraint, MotionConst, SizeConst)


size_prob = 1 - abs(det_state(4)-pred_state(4))/(det_state(4)+pred_state(4)); %% Size
if(size_prob<SizeConst && Constraint==1)
    size_prob = eps;
end
Size_Affinity = size_prob;

if(Model==1)    
    overlap_ratio = p_computePascalScoreRect(pred_state, det_state);
    if(overlap_ratio < MotionConst&& Constraint==1)
        overlap_ratio = eps;
    end
    Motion_Affinity = overlap_ratio;
else
    dist_prob = exp(-1*norm((det_state(1:2)./(det_state(3:4))-pred_state(1:2)./(pred_state(3:4))))^2);
    
    cov_dist = diag(det_state(3:4)/2 + pred_state(3:4)/2).^2;
    dist_thresh = exp(-(det_state(3:4)/2 + pred_state(3:4)/2)'*inv(cov_dist)*(det_state(3:4)/2 + pred_state(3:4)/2));
    
    dist_prob = exp(-(det_state(1:2)-pred_state(1:2))'*inv(cov_dist)*(det_state(1:2)-pred_state(1:2))); %% Distance
    if(dist_prob<dist_thresh && Constraint==1)
        dist_prob = eps;
    end
    Motion_Affinity = dist_prob;
end

