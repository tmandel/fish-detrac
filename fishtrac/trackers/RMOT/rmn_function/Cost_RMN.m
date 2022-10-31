function [Cost2ndMat] = Cost_RMN(Track, RMN, new_set, new_set_hist, opt, param)


% Histogram
new_set_hist_temp = new_set_hist;
new_set_hist = [];
for i=1:size(new_set_hist_temp,2)
    new_set_hist = [new_set_hist new_set_hist_temp{i}(:,1)];
end

% Second Layer
% Not associated detection with
% Not detected object at previous frames
% Collecting not associated object index
not_used_track_idx = [];
for i=1:length(Track)
    not_used_track_idx = [not_used_track_idx, i];
end



Cost2ndMat = opt.cost_threshold*ones(length(Track),size(new_set,2));
%
for i = 1:length(Track)
    Label_i = Track{i}.lab;
    WidhtHeight = Track{i}.X(5:6);
    % Predict other object states with RMN
    Pred_Set = [];
    Label_G = [];
    Track_idx = [];
    Link_Weight = [];
    HSV_Set = [];
    Graph = [];
    Graph = Track{i}.graph; % representing the j to i edge
    Graph = [i, Graph];
    for k=1:size(Graph,2)
        idx_k = Graph(k);
        Label_k = Track{idx_k}.lab;
        Track_Pos = param.F*Track{idx_k}.X;
        temp_state_i = [Track_Pos(1:2);0;0;Track_Pos(5:6)];
        if(Label_i~=Label_k)
            Relative_Trans = param.Fr*RMN(Label_i,Label_k).state.X;            
            pred_rmn = [temp_state_i(1:2);0;0;0;0] + [Relative_Trans(1:2); Relative_Trans(3:4); WidhtHeight]; % The i-th object is associated with the j-th detection
        else
            pred_rmn = temp_state_i;
        end
        
        Pred_Set = [Pred_Set, pred_rmn(:)];
        Label_G = [Label_G, Label_k];
        Track_idx = [Track_idx, idx_k];
        hsv_link_app = Track{idx_k}.Appearance;
        HSV_Set = [HSV_Set, hsv_link_app];
    end
    
    
    
    
    
    % Linked Event
    for k=1:size(new_set,2)
        det_state = [new_set(1:2,k)+new_set(3:4,k)/2;new_set(3:4,k)]; % center u,v,w,h
        
        if(~isempty(Pred_Set))
            Cost = 0;
            Cost_S = [];
            MotionW = [];
            for kk=1:size(Pred_Set,2)
                pred_state = [Pred_Set(1:2,kk);Pred_Set(5:6,kk)]; % center u,v,w,h
                
                MotionConst = 0.3; SizeConst = 0.8;
                [size_prob, motion_prob] = MotionAffinityModel(pred_state,det_state,1,1, MotionConst, SizeConst); % Model1(Overlap) Model2(Dist), Constraint1 (ON)
                
                app_prob = sum(sqrt(HSV_Set(:,kk).*new_set_hist(:,k)));
                
                if(opt.app_off ==0)
                    App_Const = 0.7;
                    if(app_prob<App_Const)
                        app_prob = eps;
                    end
                else
                    app_prob = 1;
                end
                Cost_S(kk) = min((-log(app_prob*motion_prob*size_prob)),opt.cost_threshold);
                MotionW(kk) = motion_prob;
            end
            [maxval maxidx] = max(MotionW);
            %
            %                  Max
            Cost = Cost_S(maxidx);
            Cost2ndMat(i,k) =   Cost;
        end
    end
    
    
    
    
end


