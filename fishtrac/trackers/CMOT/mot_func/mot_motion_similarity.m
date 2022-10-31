function [mot_sim] = mot_motion_similarity(Refer, Test,param,type)
%% Copyright (C) 2014 Seung-Hwan Bae
%% All rights reserved.

pos_var = param.pos_var;
switch type
    case 'Obs'
        XX = Refer.FMotion.X(:,end);
        
        refer_pos = [XX(1); XX(3)];
        test_pos = Test.pos;

        mot_sim =  motion_affinity(refer_pos,test_pos,pos_var);
        
    case 'Trk'
        
        fgap = (Test.init_time -Refer.end_time);
        
        if fgap > 0
            
            init_time = Test.init_time;
            FX = Refer.FMotion.X(:,init_time);
            
            BX = Test.BMotion.X(:,end);
            BP = Test.BMotion.P(:,:,end);
            while fgap > 0
                [BX,BP] = km_estimation(BX,[],param,BP);
                fgap = fgap - 1;
            end
            
            % Forward motion            
            refer_pos = [FX(1); FX(3)];
            test_pos = [Test.BMotion.X(1,end);Test.BMotion.X(3,end)];
            mot_sim1 =  motion_affinity(refer_pos,test_pos,pos_var); 
            
            % Backward motion
            refer_pos = [BX(1); BX(3)];
            test_pos = [Refer.FMotion.X(1,end); Refer.FMotion.X(3,end)];
            mot_sim2 =  motion_affinity(refer_pos,test_pos,pos_var);
            
            mot_sim = mot_sim1*mot_sim2;
            
        else
            mot_sim = 0;
            
        end
    otherwise
        warning('Unexpected type. Choose Obs or Trk.');
end