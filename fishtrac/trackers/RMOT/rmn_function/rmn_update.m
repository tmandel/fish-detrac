function [RMN,Track] = rmn_update(Track,RMN,NewT, opt, param,f)


Q = param.Qr;

for i = 1:(length(Track)-size(NewT,2))
    state1 = Track{i}.X;
    lab1 = Track{i}.lab; % relational function index
    Det1 = Track{i}.detection;
    Track{i}.link = [];
    for j=1:(length(Track) - size(NewT,2))
        state2 = Track{j}.X;
        lab2 = Track{j}.lab; % relational function index
        Det2 = Track{j}.detection;
        
        if(lab1~=lab2)
            if(~isempty(RMN(lab1,lab2).state)) % if relation_func is empty
                % update in 3 cases
                % 1) both tracks (nodes) are associated with one of current detections -> link
                % 2) a root track is associated with one of current detections -> link
                % 3) a root track is not associated with any of current detections -> link failure
                Var = RMN(lab1,lab2).state;
                if(~isempty(RMN(lab1,lab2).MeasSet)) % 1st case
                    
                    MeasSet = RMN(lab1,lab2).MeasSet;
                    
%                     [Q] = instant_Q(RMN(lab1,lab2).set,param.Qr);
                    
                    [Var] = KF_prediction_iccv(Var,param.Fr,Q,param.Gr); % Prediction
                    Xp = Var.X;
                    Pp = Var.P;
                    
                    Yp = inv(Pp);
                    yp = Yp*Xp;
                    
                    
                    sumI = zeros(4,4);
                    sumi = zeros(4,1);
%                     for kk=1:size(MeasSet,2)
%                         if(kk==1)
%                             R = param.Rr;
%                         else
%                             R = 2^2*param.Rr;
%                         end
%                         
%                         sumI = sumI + param.Hr'*inv(R)*param.Hr;
%                         sumi = sumi + param.Hr'*inv(R)*MeasSet(:,kk);
%                     end
                    
                     for kk=1:1
                        if(kk==1)
                            R = param.Rr;
                        else
                            R = 2^2*param.Rr;
                        end
                        
                        sumI = sumI + param.Hr'*inv(R)*param.Hr;
                        sumi = sumi + param.Hr'*inv(R)*MeasSet(:,kk);
                     end
                    
                     
                    Y = Yp + sumI;
                    y = yp + sumi;
                    
                    Var.P = inv(Y);
                    Var.X = Var.P*y;
                    

                    
                    if(Track{i}.not_detected ==1 || Track{j}.not_detected ==1)
                        Var.X = [Var.X(1), Var.X(2), 0, 0]';
                        Var.P = diag([Var.P(1,1),Var.P(1,1),2*Var.P(3,3),2*Var.P(4,4)]');
                    end
                    
                    
                    
                    RMN(lab1,lab2).state = Var; % Relational Function upper (input lab2-th state, output: lab1-th state)
                    RMN(lab1,lab2).frames = [RMN(lab1,lab2).frames, f];
                    RMN(lab1,lab2).set = [RMN(lab1,lab2).set, Var.X];
                    Track{i}.graph = [Track{i}.graph, j];
                    Track{i}.link = [Track{i}.link, j];
                    
                elseif(isempty(Det1) && ~isempty(Det2)) % 2nd case
                    %                     [Q] = instant_Q(RMN(lab1,lab2).set,param.Qr);
                    [Var] = KF_prediction_iccv(Var,param.Fr,Q,param.Gr); % Prediction
                    % Store new updated data
                    RMN(lab1,lab2).state = Var; % Relational Function upper (input lab2-th state, output: lab1-th state)
                    RMN(lab1,lab2).frames = [RMN(lab1,lab2).frames, f];
                    RMN(lab1,lab2).set = [RMN(lab1,lab2).set, Var.X];
                    Track{i}.graph = [Track{i}.graph, j];
                    
                elseif(~isempty(Det1) && isempty(Det2)) % 3rd case
%                     [Q] = instant_Q(RMN(lab1,lab2).set,param.Qr);
                    [Var] = KF_prediction_iccv(Var,param.Fr,Q,param.Gr); % Prediction
                    % Store new updated data
                    RMN(lab1,lab2).state = Var; % Relational Function upper (input lab2-th state, output: lab1-th state)
                    RMN(lab1,lab2).frames = [RMN(lab1,lab2).frames, f];
                    RMN(lab1,lab2).set = [RMN(lab1,lab2).set, Var.X];
                    Track{i}.link = [Track{i}.link, j];
                    
                elseif(~isempty(Det1) && ~isempty(Det2))
%                     [Q] = instant_Q(RMN(lab1,lab2).set,param.Qr);
                    [Var] = KF_prediction_iccv(Var,param.Fr,Q,param.Gr); % Prediction
                    % Store new updated data
                    RMN(lab1,lab2).state = Var; % Relational Function upper (input lab2-th state, output: lab1-th state)
                    RMN(lab1,lab2).frames = [RMN(lab1,lab2).frames, f];
                    RMN(lab1,lab2).set = [RMN(lab1,lab2).set, Var.X];
                end
            else % if relation_func is empty ?
                if(~isempty(Det1) && ~isempty(Det2))
                    state1 = Track{i}.states; N1 = size(state1,2);
                    state2 = Track{j}.states; N2 = size(state2,2);
                    
                    RMN(lab1,lab2).set = [];
                    if(opt.init_frames==5)
                        IDX = [5 4 3 2 1 0];
                    elseif(opt.init_frames==4)
                        IDX = [4 3 2 1 0];
                    elseif(opt.init_frames==3)
                        IDX = [3 2 1 0];
                    elseif(opt.init_frames==2)
                        IDX = [2 1 0];
                    end
                    
                    for k=1:opt.init_frames+1
                        idx1 = N1 - IDX(k); idx2 = N2 - IDX(k);
                        s1 = state1(1:2,idx1); s2 = state2(1:2,idx2);
                        if(k==1)
                            % initialization
                            [Var] = init_relation_func_Cart(s1,s2);
                        else
                            % Kalman filtering
                            Dist = s1 - s2;
                            meas = [Dist(1) Dist(2)]';
                            [Var] = KF_prediction_iccv(Var,param.Fr,param.Qr,param.Gr); % Prediction
                            [Var] = KF_update_iccv(meas,Var,param.Rr,param.Hr); % Update
                        end
                    end
                    Var.P = [2 0 0 0;0 2 0 0;0 0 2 0;0 0 0 2].^2;
                    RMN(lab1,lab2).state = Var; % Relational Function (input lab2-th state, output: lab1-th state)
                    RMN(lab1,lab2).frames = [RMN(lab1,lab2).frames, f];
                    RMN(lab1,lab2).set = [RMN(lab1,lab2).set, Var.X];
                    Track{i}.graph = [Track{i}.graph, j]; % Graph initialization
                    Track{i}.link = [Track{i}.link, j];
                end
            end
        end
    end
end