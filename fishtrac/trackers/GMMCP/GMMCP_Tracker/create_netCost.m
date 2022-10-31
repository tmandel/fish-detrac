%% Compute the netCost Matrix
function net_cost = create_netCost(segment,param_netCost)

addpath('./MOT_toolbox/');
addpath('./toolbox/');
net_cost.motion = [];
net_cost.appearance = [];
net_cost.ind = [];
offset = 1;
cnt_global = 1;
for i=1:length(segment)
    if isempty(segment{i})
        continue;
    end
    hist1 = zeros(32*32*32,length(segment{i}.tracklet));
    curr_size = length(segment{i}.tracklet);
    for iTrack=1:length(segment{i}.tracklet)
        hist1(:,iTrack) = segment{i}.tracklet(iTrack).color_hist_median(:);
        tracklet_segment1(iTrack).frame = segment{i}.tracklet(iTrack).frame';
        tracklet_segment1(iTrack).length = length(segment{i}.tracklet(iTrack).frame);
        tracklet_segment1(iTrack).data = [(segment{i}.tracklet(iTrack).detection(:,1)+segment{i}.tracklet(iTrack).detection(:,3))/2 ...
            (segment{i}.tracklet(iTrack).detection(:,2)+segment{i}.tracklet(iTrack).detection(:,4))/2]';
        net_cost.infoBox{cnt_global} = [segment{i}.tracklet(iTrack).frame'; ...
            segment{i}.tracklet(iTrack).origDetectionInd'; segment{i}.tracklet(iTrack).detection'];
        net_cost.infoColor{cnt_global} = [segment{i}.tracklet(iTrack).color_hist_median];
        cnt_global = cnt_global+1;
    end
    
    cnt = 1;
    for ii=i:length(segment)
        if isempty(segment{ii})
            continue;
        end
        for iTrack=1:length(segment{ii}.tracklet)
            hist2(:,cnt) = segment{ii}.tracklet(iTrack).color_hist_median(:);
            tracklet_segment2(cnt).frame = segment{ii}.tracklet(iTrack).frame';
            tracklet_segment2(cnt).length = length(segment{ii}.tracklet(iTrack).frame);
            tracklet_segment2(cnt).data = [(segment{ii}.tracklet(iTrack).detection(:,1)+segment{ii}.tracklet(iTrack).detection(:,3))/2 ...
                (segment{ii}.tracklet(iTrack).detection(:,2)+segment{ii}.tracklet(iTrack).detection(:,4))/2]';
            cnt = cnt+1;
        end
    end
    
    if i==1
        net_cost.appearance=zeros(size(tracklet_segment2,2));
        net_cost.motion = zeros(size(tracklet_segment2,2));
    end
    
    %% Compute Motion Sim
    N = length(tracklet_segment2);
    M = length(tracklet_segment1);
    S = zeros(M,N);
    for iii=1:M
        for jjj=1:N
            S(iii,jjj) = compute_motion_cost_constVel(tracklet_segment1(iii),tracklet_segment2(jjj),param_netCost);
        end
    end    
    S(1:curr_size,1:curr_size)=NaN;
    
    %% Compute Appearance Sim
    hi_dist = slmetric_pw(hist1,hist2,'intersect');
    hi_dist(1:curr_size,1:curr_size)=NaN;
    net_cost.appearance(offset:offset+curr_size-1,offset:end) = 2*hi_dist;
    net_cost.motion(offset:offset+curr_size-1,offset:end) =  2*S;
    net_cost.ind = [net_cost.ind ; curr_size];
    offset = offset+curr_size;
    clear hi_dist hist2 hist1 S tracklet_segment1 tracklet_segment2;
    
end
