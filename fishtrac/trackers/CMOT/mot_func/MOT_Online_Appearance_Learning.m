function [ILDA] = MOT_Online_Appearance_Learning(cimg,img_path, img_List, fr, Trk, param, ILDA)
%% Copyright (C) 2014 Seung-Hwan Bae
%% All rights reserved.

if ILDA.n_update == 0
    for i=1:length(Trk)
        % Pactch cropping
        states = cell2mat(Trk(i).state);
        [bbs] = mot_impatch_crop(states');
        % Feature extraction
        for j=1:length(bbs)
            img_idx = fr - length(bbs) + j;
            filename = strcat(img_path,img_List(img_idx).name);
            rgbimg = imread(filename);
            col_hist = mot_appearance_model_generation(rgbimg,param,bbs{j}');
            col_hist = squeeze(col_hist);
            ILDA.feat_data = [ILDA.feat_data, col_hist];
            nofd = size(col_hist,2);
            ILDA.feat_label = [ILDA.feat_label, repmat(Trk(i).label, 1, nofd)];
        end
    end
else
    states = []; tlabel = [];
    for i=1:length(Trk)
        % Pactch cropping
        states = [states, Trk(i).state{fr}];
        tlabel = [tlabel, Trk(i).label];
    end
    
    if ~isempty(states)
        [bbs] = mot_impatch_crop(states');
        
        % Feature extraction
        for j=1:length(bbs)
            col_hist = mot_appearance_model_generation(cimg,param,bbs{j}');
            col_hist = squeeze(col_hist);
            ILDA.feat_data = [ILDA.feat_data, col_hist];
            nofd = size(col_hist,2);
            ILDA.feat_label = [ILDA.feat_label, repmat(tlabel(j), 1, nofd)];
        end
    end
end


% Subspace learning
if rem(fr, ILDA.duration) == 1 && ~isempty(ILDA.feat_data)
    [ILDA] = MOT_ILDA_Update(ILDA, ILDA.feat_data, ILDA.feat_label);
    ILDA.feat_data = [];
    ILDA.feat_label = [];
end
end