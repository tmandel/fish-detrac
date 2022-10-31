function [stateInfo] = MOT_Draw_Tracking(Trk_sets, img_path, img_List, frame_end, option)
%% Copyright (C) 2014 Seung-Hwan Bae
%% All rights reserved.

% Draw Tracking Results
if ~isfield(option,'new_thr'); 
    option.isdraw = 1;
    option.iswrite = 0;
    option.new_thr = 5; 
end
new_thr = option.new_thr;
all_mot = [];
numFrames = length(Trk_sets);

X = zeros(numFrames, 1);
Y = zeros(numFrames, 1);
W = zeros(numFrames, 1);
H = zeros(numFrames, 1);
img_path = strcat('../../',strrep(img_path,'//','/'))
for q=1:numFrames
    filename = strcat(img_path,img_List(q).name);
    rgbimg = imread(filename);   
    wind_cx=[];  wind_cy =[]; windw = []; windh = [];
    Labels =[]; trk_idx = [];  trk_sts =[]; conf = [];
    
    
    if q<=new_thr
        trk_idx = Trk_sets(new_thr+1).high;
        for i=1:length(trk_idx)
            states = Trk_sets(new_thr+1).states{trk_idx(i)};
            lab = Trk_sets(new_thr+1).label;
            trk_sts = zeros(1,length(trk_idx));
            if sum(states(:,q)) ~=0
                wind_cx = [wind_cx, states(1,q)];
                wind_cy = [wind_cy, states(2,q)];
                windw = [windw,states(3,q)];
                windh = [windh,states(4,q)];
                Labels = [Labels,lab(trk_idx(i))];
                conf(i)  = 0.33 + rand *0.33;
            end
        end
    else
        high = Trk_sets(q).high;
        low = Trk_sets(q).low;
        trk_idx = [high,low];
        
        for i=1:length(trk_idx)
            states = Trk_sets(q).states{trk_idx(i)};
            wind_cx = [wind_cx, states(1,end)];
            wind_cy = [wind_cy, states(2,end)];
            windw = [windw,states(3,end)];
            windh = [windh,states(4,end)];
            conf(i) = Trk_sets(q).conf(trk_idx(i));
        end
        if ~isempty(wind_cx)
            all_lab = Trk_sets(q).label;
            Labels = [all_lab(high), all_lab(low)];
        end
    end
    
    [wind_lx, wind_ly] = CenterToLeft(wind_cx,wind_cy,windh,windw);

    X(q, Labels) = wind_lx;
    Y(q, Labels) = wind_ly;
    W(q, Labels) = windw;
    H(q, Labels) = windh;

    %% Draw results
    if option.isdraw
        figure(1);
        mot_draw_confidence_boxes(rgbimg, wind_lx, wind_ly, windw, windh, Labels, conf);
        
%         if ~isdir(out_path);mkdir(out_path);end;
%         
%         out_filename = strcat(out_path,sprintf('Tracking_Results_%04d.jpg',q));
%         
%         if option.iswrite
%             testImg= frame2im(getframe(fg1));
%             imwrite(testImg, out_filename);
%         end
    end
    
    %% Output
    if ~isempty(wind_cx)
        all_mot.cpos{q} = [wind_cx;wind_cy]; % center position
        all_mot.lpos{q} = [wind_lx;wind_ly]; % X-Y position
        all_mot.size{q} = [windw;windh];     % size
        all_mot.lab{q} = Labels;             % labels
    end    
end

% save tracking results
stateInfo = [];
xc = X + W/2;
yc = Y + H/2;
% foot position
stateInfo.X = xc;       
stateInfo.Y = yc+H/2;
stateInfo.H = W;
stateInfo.W = H;
stateInfo.F = frame_end;
stateInfo.frameNums = 1:frame_end;
stateInfo.Xgp = stateInfo.X;
stateInfo.Ygp = stateInfo.Y;
stateInfo.Xi = stateInfo.X;
stateInfo.Yi = stateInfo.Y;