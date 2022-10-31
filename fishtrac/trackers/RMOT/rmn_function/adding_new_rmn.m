function [RMN, Track] = adding_new_rmn(Track, NewT, RMN, opt, param, f)



for i = 1:size(NewT,2)
    idx = NewT(i);
    state1 = Track{idx}.states;
    lab1 = Track{idx}.lab;
    Track{idx}.graph = []; % Link initialization
    Track{idx}.link = [];
    for j = 1:length(Track)-size(NewT,2)
        lab2 = Track{j}.lab;
        Det2 = Track{j}.detection;
        if(~isempty(Det2))
            if(lab1~=lab2)
                state2 = Track{j}.states;
                num2 = size(state2,2);
                state2 = state2(:,num2-opt.init_frames+1:num2);
                for k=1:size(state1,2)
                    s1 = state1(1:2,k); s2 = state2(1:2,k);
                    if(k==1)
                        Var = init_relation_func_Cart(s1,s2);
                    else
                        meas = s1 - s2;
                        [Var] = KF_prediction_iccv(Var,param.Fr,param.Qr,param.Gr); % Prediction
                        [Var] = KF_update_iccv(meas,Var,param.Rr,param.Hr); % Update
                    end
                end
                Var.P = [2 0 0 0;0 2 0 0;0 0 2 0;0 0 0 2].^2;
                RMN(lab1,lab2).state = Var; % Relational Function upper (input lab2-th state, output: lab1-th state)
                RMN(lab1,lab2).frames = f;
                RMN(lab1,lab2).set = [RMN(lab1,lab2).set, Var.X];
                Track{idx}.graph = [Track{idx}.graph, j]; % Graph update
                Track{idx}.link= [Track{idx}.link, j];
                
                Var.X = -1*Var.X;
                RMN(lab2,lab1).state = Var; % Relational Function upper (input lab2-th state, output: lab1-th state)
                RMN(lab2,lab1).frames = f;
                RMN(lab2,lab1).set = [RMN(lab2,lab1).set, Var.X];
                Track{j}.graph = [Track{j}.graph, idx]; % Graph update
                Track{j}.link= [Track{j}.link, idx];
            end
        end
    end
end


% New Relational function addition (associating with each other)
for i = 1:size(NewT,2)
    idx1 = NewT(i);
    state1 = Track{idx1}.states;
    lab1 = Track{idx1}.lab;
%     Track{idx1}.graph = [];
    for j = 1:size(NewT,2)
        idx2 = NewT(j);
        state2 = Track{idx2}.states;
        lab2 = Track{idx2}.lab;
        RMN(lab1,lab2).set = []; RMN(lab1,lab2).size = [];
        if(lab1~=lab2)
            for k=1:size(state2,2)
                s1 = state1(1:2,k);   s2 = state2(1:2,k);
                if(k==1)    % initialization
                    [Var] = init_relation_func_Cart(s1,s2);
                else    % Kalman filtering
                    meas = s1 - s2;
                    [Var] = KF_prediction_iccv(Var,param.Fr,param.Qr,param.Gr); % Prediction
                    [Var] = KF_update_iccv(meas,Var,param.Rr,param.Hr); % Update
                end
            end
            Var.P = [2 0 0 0;0 2 0 0;0 0 2 0;0 0 0 2].^2;
            RMN(lab1,lab2).state = Var; % Relational Function upper (input lab2-th state, output: lab1-th state)
            RMN(lab2,lab1).frames = f;
            RMN(lab2,lab1).set = [RMN(lab2,lab1).set, Var.X];
            Track{idx1}.graph = [Track{idx1}.graph, idx2]; % Graph update
            Track{idx1}.link= [Track{idx1}.link, idx2];
        end
    end
end
