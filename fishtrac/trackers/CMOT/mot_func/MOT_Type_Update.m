function [Trk] = MOT_Type_Update(rgbimg,Trk,type_thr,cfr)
%% Copyright (C) 2014 Seung-Hwan Bae
%% All rights reserved.

del_idx = []; lb_idx =[];
max_frame = 50;

for i=1:length(Trk)
    Conf_prob = Trk(i).Conf_prob;
    type = Trk(i).type;
    switch type
        case 'High'
            if Conf_prob < type_thr
                Trk(i).type = 'Low';
                Trk(i).efr = cfr;
            end
        case 'Low'
            if Conf_prob > type_thr
                Trk(i).type = 'High';
            end
            efr = Trk(i).efr;
            if abs(cfr - efr) >= max_frame
                del_idx = [del_idx,i];
                lb_idx= [lb_idx, Trk(i).label];
            end
    end
end

[R_pos(2), R_pos(1), ~] = size(rgbimg);
L_pos = [0,0];

margin = [0 0];
for i=1:length(Trk)
    tstates =Trk(i).state{end};

    if isnan(tstates(1))
        del_idx = [del_idx,i];
    else
         fmotion = Trk(i).state{end};
         C_pos(1) = fmotion(1,end);
         C_pos(2) = fmotion(2,end);
         L_pos = L_pos + margin;
         R_pos = R_pos - margin;
         if ~(mot_is_reg(C_pos,L_pos,R_pos))
             del_idx = [del_idx,i];
         end
    end
end
    
if ~isempty(del_idx)
    Trk(del_idx) = [];
end


end