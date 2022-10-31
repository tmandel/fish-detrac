%% Function to create tracklets using overlap threshold and extract appearance features

function segment = ll_tracklet_generator_nf(im_path,detections, param_tracklet, images, flag_visualization)

addpath('./toolbox/');

cnt_segment = 1;
num_of_segments = round(length(images)/param_tracklet.num_frames);
cnt_segment_tmp = 1;
fprintf('generating tracklets : ');


for iImg = 1:param_tracklet.num_frames:length(images)
    
    %% Find Correspondence
    fprintf(' %0.1f \n',(cnt_segment/num_of_segments)*100);
   
    if min(iImg+param_tracklet.num_frames-1,length(images))-iImg <4;break;end
    disp('run_GOG is called')
    [tracks,trackFrame] = run_GOG(detections,iImg,min(iImg+param_tracklet.num_frames-1,length(images)),param_tracklet);
    cluster_size = size(tracks,2);
    printf("generating cluster %d out of %d\n", cnt_segment, num_of_segments);
    printf("tracks in cluster: %d \n", cluster_size);
    
    
    %% Remove short tracklets 
    tracks_new = [];cntDummy=1;
    for i=1:size(tracks,2)
       if size(tracks{i},1)> param_tracklet.num_frames/2-2
           tracks_new{1,cntDummy}=tracks{i};
           cntDummy = cntDummy+1;
       end
    end
    tracks = tracks_new;
    
    
    if(flag_visualization)
        im = imread(fullfile(im_path,images(iImg).name));
        imshow(im);hold on;
        c = hsv(size(tracks,2));
        for i=1:size(tracks,2)
            xc = round((tracks{1,i}(:,3)+tracks{1,i}(:,5))/2);
            yc = round((tracks{1,i}(:,4)+tracks{1,i}(:,6))/2);
            plot(xc,yc,'-o','color',c(i,:),'MarkerFaceColor',c(i,:),'LineWidth',3);
        end
        pause(0.05);
    end
    
    %% Save the output
    cnt_tracklet = 1;
    im_preread = cell(1,param_tracklet.num_frames);
    cntDummy = 1; % Why the heck MATLAB doesn't have enumerate such as PYTHON 
    printf('imread loop ');
    for jj = iImg:min(iImg+param_tracklet.num_frames-1,length(images))
        im_preread{1,cntDummy} = imread(fullfile(im_path,images(jj).name));
        cntDummy = cntDummy+1;
    end

    [height,width,~]=size(im_preread{1,1});
    for ii=1:size(tracks,2)
        printf("Generating color hist for tracklet %d of %d\n", cnt_tracklet, cluster_size);
        tic
        segment{cnt_segment_tmp}.tracklet(cnt_tracklet).frame = tracks{ii}(:,1);
        color_hist = zeros(32,32,32,size(tracks{ii},1));
        for iii = 1:size(tracks{ii},1)
            im = im_preread{1,tracks{ii}(iii,1)-iImg+1};
            x1 = round(tracks{ii}(iii,3));
            y1 = round(tracks{ii}(iii,4));
            x2 = round(tracks{ii}(iii,5));
            y2 = round(tracks{ii}(iii,6));
            x1 = max(x1,1);
            y1 = max(y1,1);
            x2 = min(x2, width);
            y2 = min(y2, height);
            segment{cnt_segment_tmp}.tracklet(cnt_tracklet).detection(iii,1:4) = [x1 y1 x2 y2];
            segment{cnt_segment_tmp}.tracklet(cnt_tracklet).origDetectionInd(iii,1) = tracks{ii}(iii,end);
            
            hist_tmp = invhist(im(y1:y2,x1:x2,:));
            color_hist(:,:,:,iii)=hist_tmp;
        end
        segment{cnt_segment_tmp}.tracklet(cnt_tracklet).color_hist_median = median(color_hist,4);
        
        clear color_hist hist_tmp;
        cnt_tracklet = cnt_tracklet+1;
        toc
    end
    cnt_segment = cnt_segment+1;
    cnt_segment_tmp = cnt_segment_tmp+1;
    
end
param_tracklet.numOfSegments = cnt_segment_tmp-1;
if(~exist(fullfile(param_tracklet.data_directory,'Features')))
    mkdir(fullfile(param_tracklet.data_directory,'Features'));
end
save(fullfile(param_tracklet.data_directory,'Features',['tracklets_' param_tracklet.config_name '_nf.mat']),'segment');%,'-v7.3');

