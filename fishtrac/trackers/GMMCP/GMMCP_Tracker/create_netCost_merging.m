%% Compute the netCost Matrix
function create_netCost_merging(sequence_name)

featPath = fullfile('./Data/Features/',[sequence_name '_merging_feat']);
savePath = fullfile('./Data/Features/',[sequence_name '_merging_netCost']);
if(~exist(savePath))
    mkdir(savePath);
end
feat_files = dir(fullfile(featPath,'*.mat'));
% Compute the Color Similarity
cnt_segment = 1;
offset = 1;

%
param.max_error = 250;
param.sigma = 30;
param.smooth = 1;
param.show = 0;

net_cost.appearance=[];
net_cost.motion = [];
net_cost.ind = [];
net_cost.loc_dist = [];
net_cost.motion_weight = [];
for i=1:length(feat_files)
    fprintf('processing %d out of %d\n',i,length(feat_files));
    tracklet_1 = load(fullfile(featPath,feat_files(i).name));
    hist1 = zeros(32*32*32,length(tracklet_1.tracklet.color_hist));
    curr_size = length(tracklet_1.tracklet.color_hist);
    
    for iTrack=1:length(tracklet_1.tracklet.color_hist)
        hist_tmp = zeros(32,32,32,length(tracklet_1.tracklet.color_hist{iTrack}));
        for iTmp =1:length(tracklet_1.tracklet.color_hist{iTrack})
            hist_tmp(:,:,:,iTmp)= tracklet_1.tracklet.color_hist{iTrack}{iTmp,1};
        end
        hist_tmp_median = median(hist_tmp,4);
        hist1(:,iTrack) = hist_tmp_median(:);
        x1(1,iTrack).data=[(tracklet_1.tracklet.bbox{1,iTrack}(:,1)+tracklet_1.tracklet.bbox{1,iTrack}(:,3))/2 ...
            (tracklet_1.tracklet.bbox{1,iTrack}(:,2)+tracklet_1.tracklet.bbox{1,iTrack}(:,4))/2]';
        x1(1,iTrack).length = size(tracklet_1.tracklet.bbox{1,iTrack},1);
        x1(1,iTrack).frame = tracklet_1.tracklet.frames{1,iTrack}';
        loc1(:,iTrack) = x1(1,iTrack).data(:,end);
        clear hist_tmp_median hist_tmp;
    end
    clear tracklet_1;
    cnt = 1;  
    for ii=i:length(feat_files)
        tracklet_2 = load(fullfile(featPath,feat_files(ii).name));
        for iTrack=1:length(tracklet_2.tracklet.color_hist)
            hist_tmp = zeros(32,32,32,length(tracklet_2.tracklet.color_hist{iTrack}));
            for iTmp =1:length(tracklet_2.tracklet.color_hist{iTrack})
                hist_tmp(:,:,:,iTmp)= tracklet_2.tracklet.color_hist{iTrack}{iTmp,1};
            end
            hist_tmp_median = median(hist_tmp,4);
            hist2(:,cnt) = hist_tmp_median(:);
            x2(1,cnt).data=[(tracklet_2.tracklet.bbox{1,iTrack}(:,1)+tracklet_2.tracklet.bbox{1,iTrack}(:,3))/2 ...
                (tracklet_2.tracklet.bbox{1,iTrack}(:,2)+tracklet_2.tracklet.bbox{1,iTrack}(:,4))/2]';
            x2(1,cnt).length = size(tracklet_2.tracklet.bbox{1,iTrack},1);
            x2(1,cnt).frame = tracklet_2.tracklet.frames{1,iTrack}';
            loc2(:,cnt) = x2(1,cnt).data(:,1);
            cnt = cnt+1;
            clear hist_tmp_median hist_tmp;
        end
    end
    if i==1
        net_cost.appearance=zeros(size(loc2,2));
        net_cost.motion = zeros(size(loc2,2));
        net_cost.loc_dist = zeros(size(loc2,2));
        net_cost.motion_weight = zeros(size(loc2,2));
    end
    %% LOCATION ERROR - Used for Fusion Weights
    loc_dist = slmetric_pw(loc1,loc2,'eucdist');
    motion_weight = 0.8*exp(-loc_dist/150);
    loc_dist(1:curr_size,1:curr_size)=NaN;
    net_cost.loc_dist(offset:offset+curr_size-1,offset:end) =  loc_dist;
    motion_weight(1:curr_size,1:curr_size)=NaN;
    net_cost.motion_weight(offset:offset+curr_size-1,offset:end)= motion_weight;    
    
    %% Compute Motion Sim
    N = length(x2);
    M = length(x1);
    S = zeros(M,N);
    for iii=1:M
        for jjj=1:N
            S(iii,jjj) = compute_motion_cost_constVel(x1(1,iii),x2(1,jjj),param);
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
    clear hi_dist hist2 hist1 tracklet_1 tracklet_2 loc1 loc2 x1 x2;
end
save(fullfile(savePath,['netCost_merging_' sequence_name '_submission_v2.mat']),'net_cost');

