function midLevelTracklet = extract_features_merging(NN,  NN_original, nodes, segment, seqName, param_tracklet, flag_visualize_midLevelTracklets, imPath)

saveFeat = ['./Data/Features/' seqName '_merging_feat/'];
if(~exist(saveFeat))
    mkdir(saveFeat);
end
%% Sequence Info
%data_directory = './Data/Images/';
%imPath = fullfile(data_directory,seqName,'/');
disp(imPath)
images = dir([imPath '/*.jpg']);
numOfClusters = param_tracklet.num_cluster; 
segmentLength = param_tracklet.num_frames; 
disp(length(NN))
for iFile = 1:length(NN)   
    disp("I started!")
    NN_curr = NN{iFile};
    nodes_curr = nodes{iFile};
    NN_original_curr = NN_original{iFile};
    
    segment_num = (iFile-1)*round((numOfClusters)/2);
    numClicks = size(nodes_curr,1);
    cc = hsv(numClicks);
    cumulativeSUM = cumsum(NN_curr);
    centers = cell(1,numClicks);
    im1 = imread([imPath images((segment_num)*segmentLength+1).name]);
    im2 = imread([imPath images(min((segment_num+numOfClusters)*segmentLength+1,length(images))).name]);
    im = (im2double(im1)+im2double(im2))/2;
    imshow(im);
    hold on;
    tracklet_cnt=1;
    dummy_tracklet_flag = zeros(1,numClicks);
    
    tracklet_count = 0;%Mark
    for iClick = 1:numClicks
        disp("I need less dummy nodes than total nodes to make a tracklet")
        detections = [];
        frames = [];
        tracklet_color_hist = [];
        cnt_dummy_nodes = 0;
        for ii=1:size(nodes_curr,2)
            if(ii==1)
                trackletID = nodes_curr(iClick,ii);
            else
                trackletID = nodes_curr(iClick,ii)-cumulativeSUM(ii-1);
            end
            disp("trackletID")
            disp(trackletID)
            disp("NN")
            disp(NN_original_curr(ii))
            if(trackletID>NN_original_curr(ii))
                cnt_dummy_nodes = cnt_dummy_nodes+1;
                continue;
            end
            detections = [detections ; segment{segment_num+ii}.tracklet(trackletID).detection];
            frames = [frames ; segment{segment_num+ii}.tracklet(trackletID).frame];
            aa = segment{segment_num+ii}.tracklet.color_hist_median;
            tracklet_color_hist = [tracklet_color_hist aa(:)];
        end
        if (isempty(detections))
            continue;
        end        
        % We remove nodes which have only one real node
        disp("nodes_curr")
        disp(size(nodes_curr,2))
        if(cnt_dummy_nodes< (size(nodes_curr,2)-1))
            tracklet_count = tracklet_count +1%Mark
            % Store the tracklet information
            disp("I made a tracklet!")
            tracklet.color_hist{tracklet_cnt} = tracklet_color_hist;
            tracklet.bbox{tracklet_cnt}       = detections;
            tracklet.frames{tracklet_cnt}     = frames;
            tracklet_cnt = tracklet_cnt+1;
            if (flag_visualize_midLevelTracklets)
                centers{iClick}=[(detections(:,1)+detections(:,3))/2 (detections(:,2)+detections(:,4))/2];
                plot(centers{iClick}(:,1),centers{iClick}(:,2),'-mo','color',cc(iClick,:),'LineWidth',2,'MarkerSize',6,'MarkerFaceColor',cc(iClick,:));
                pause(0.4);
                hold on;
            end
        end
    end 
    %if (size(nodes_curr,2) !=1)
    if (tracklet_count > 0)%Mark
        midLevelTracklet(iFile).color_hist = tracklet.color_hist;
        midLevelTracklet(iFile).bbox       = tracklet.bbox;
        midLevelTracklet(iFile).frames     = tracklet.frames;
    end

    %save([saveFeat sprintf('segment_%03d.mat',iFile)],'tracklet');
    clear tracklet;
end

