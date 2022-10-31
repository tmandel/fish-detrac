function [RMN, Track] = rmn_initialization(Track,param,f)


for i = 1:length(Track)
    state1 = Track{i}.states;
    frame1 = Track{i}.frame;
    num1 = size(frame1,2);
    lab1 = Track{i}.lab;
    for j = 1:length(Track)
        lab2 = Track{j}.lab;
        if(lab1~=lab2)
            state2 = Track{j}.states;
            frame2 = Track{j}.frame;
            num2 = size(frame2,2);
            RMN(lab1,lab2).set = [];
            
            num_frame = min(num1,num2);
            flagk = 1;
            
            for k= 1 : num_frame
                s1 = state1(1:2,num1 - num_frame + k); s2 = state2(1:2,num2 - num_frame + k);
                f1 = frame1(num1 - num_frame + k); f2 = frame2(num2 - num_frame + k);
                if(f1==f2)
                    if(flagk==1)
                        % initialization
                        [Var] = init_relation_func_Cart(s1,s2);
                        flagk = 0;
                    else
                        % Kalman filtering
                        Dist = s1 - s2;
                        meas = [Dist(1) Dist(2)]';
                        [Var] = KF_prediction_iccv(Var,param.Fr,param.Qr,param.Gr); % Prediction
                        [Var] = KF_update_iccv(meas,Var,param.Rr,param.Hr); % Update
                    end
                end
            end
          %% modify     
            if(~isfield('Var', 'X'))
                diff_s = s1-s2;
                TransX = diff_s(1);
                TransY = diff_s(2);
                Var.X = [TransX TransY 0 0]';
            end            
            Var.P = [2 0 0 0;0 2 0 0;0 0 2 0;0 0 0 2].^2;
            Size = [state1(3,end);state2(3,end);state1(4,end);state2(4,end)];
            RMN(lab1,lab2).frames = f;
            RMN(lab1,lab2).set = [RMN(lab1,lab2).set, Var.X];
%             RMN(lab1,lab2).size = Size;
            RMN(lab1,lab2).state = Var; % Relational Function (input lab2-th state, output: lab1-th state)
            Track{i}.graph = [Track{i}.graph, j]; % Graph initialization
            Track{i}.link = [Track{i}.link, j];
        end
    end
end