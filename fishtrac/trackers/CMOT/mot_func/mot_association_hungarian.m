function [matching, score] = mot_association_hungarian(score_mat, thr)
%% Copyright (C) 2014 Seung-Hwan Bae
%% All rights reserved
% Association using the hungarian algorithm

if size(score_mat,1) ==1
    [assignment,cost] = munkres(-(score_mat')); 
    assignment = assignment';
    [ass_row,ass_col] = find(assignment == 1);
else
    [assignment,cost] = munkres(-(score_mat)); 
    [ass_row,ass_col] = find(assignment == 1);
end

match_cost = score_mat(assignment);
midx = find(match_cost > thr);


matching = [ass_row(midx),ass_col(midx)];
score= match_cost(midx);

end