function [Track] = prediction_rmn(Track, RMN, param)

% Node motion
for i=1:length(Track)
    State = Track{i}.X;
    P = Track{i}.P;
    [State,P] = KF_prediction_iccv2(State, P, param.F, param.Q, param.G); % Prediction
    Track{i}.Xp = State;
    Track{i}.Pp = P;
end

% relative motion from neighbor objects
for i=1:length(Track)
    GP = Track{i}.graph; % node index to i-th Track
    s_node = Track{i}.Xp; % predicted state of the node
    graph_x_prev = Track{i}.graph_x;
    
    %     Track{i}.graph = [];
    Track{i}.graph_x = [];
    Track{i}.graph_x = s_node(1:6); TN = s_node(3:4); WH = s_node(5:6);
    lab1 = Track{i}.lab; % the node target label
    graph_weight_idx = i;
    for j=1:size(GP,2) % Insert states from relationa function
        idx = GP(j); % the neighbor node index
        state_o = Track{idx}.Xp; % the neighbor node state
        lab2 = Track{idx}.lab; % the neighbor node target label
        Rtrans = param.Fr*RMN(lab1,lab2).state.X; % relational translation
        trans_state = state_o(1:4)+ Rtrans(1:4);
        T_state = [trans_state; WH]; % Transfered state
        % is it within the image ?
        Track{i}.graph_x = [Track{i}.graph_x, T_state];
        graph_weight_idx = [graph_weight_idx, idx];
    end
    
    % Check link
    graph_weight_idx_prev = Track{i}.graph_weight;
    not_equal = 0;
    
    if(size(graph_weight_idx_prev,2) ~= size(graph_weight_idx,2) || isempty(graph_weight_idx_prev))
        not_equal = 1;
    else
        for j=1:size(graph_weight_idx_prev,2)
            if(graph_weight_idx_prev(2,j)~=graph_weight_idx(j))
                not_equal = 1;
            end
        end
    end
    
    
    graph_weight_val = Track{i}.graph_weight;
    if(isempty(graph_weight_val) || not_equal==1)
        % Graph weight
        Track{i}.graph_weight = [1/size(graph_weight_idx,2)*ones(1,size(graph_weight_idx,2));graph_weight_idx];
    else
        Track{i}.graph_weight =  [graph_weight_val(1,:);graph_weight_idx];
    end
    
    
end



% Partintion of Tracks in terms of positions
% Position threshold comute by two objects width and height from its centers
for i=1:length(Track)
    idx = 0;
    state = Track{i}.graph_x; % [X, Y, tX, tY, W, H]
    s_i = [state(1:2,:); state(5:6,:)]; %[left upper X, Y, W, H]
    Track{i}.partition = [];
    for j=1:length(Track)
        state = Track{j}.graph_x; % [X, Y, tX, tY, W, H]
        s_j = [state(1:2,:); state(5:6,:)]; %[left upper X, Y, W, H]
        if(i==j)
            Track{i}.partition = [Track{i}.partition, j];
        else
            idx = idx + 1;
            Over_Mat = zeros(size(s_i,2),size(s_j,2));
            for i2 = 1:size(s_i,2)
                for j2 = 1:size(s_j,2)
                    XY_i = s_i(1:2,i2); WH_i = s_i(3:4,i2)/2;
                    XY_j = s_j(1:2,j2); WH_j = s_j(3:4,j2)/2;
                    
                    Wid = (WH_i(1)+WH_j(1)); Hei = (WH_i(2)+WH_j(2));
                    Thresh = 2*sqrt(Wid^2 + Wid^2);
                    
                    Dist = norm(XY_i-XY_j)/Thresh;
                    Over_Mat(i2,j2) = Dist;
                end
            end
            MinVal = min(min(Over_Mat));
            if MinVal < 1
                Track{i}.partition = [Track{i}.partition, j]; % Track numbers in the i-th track partition
            end
        end
    end
   
end