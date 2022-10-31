%%
for s=0:28
%     cd /home/amilan/storage/databases/KITTI/tracking/devkit_tracking/matlab
    sceneInfo=getSceneInfo(s+550); F=length(sceneInfo.frameNums);    
    tracklets=readLabels('/home/amilan/storage/databases/KITTI/tracking/testing/det_02/',s);
    if length(tracklets)<F, for t=length(tracklets)+1:F, tracklets{t}=[]; end; end
%     cd /home/amilan/research/projects/dctracking
    convertKITTIToCVML(tracklets,sprintf('/home/amilan/storage/databases/KITTI/tracking/testing/det_02/%04d.xml',s),{'Car','Pedestrian'});
end

%%
for s=0:20
%     cd /home/amilan/storage/databases/KITTI/tracking/devkit_tracking/matlab
    sceneInfo=getSceneInfo(s+500); F=length(sceneInfo.frameNums);
    tracklets=readLabels('/home/amilan/storage/databases/KITTI/tracking/training/label_02',s);
    if length(tracklets)<F, for t=length(tracklets)+1:F, tracklets{t}=[]; end; end
%     cd /home/amilan/research/projects/dctracking
    convertKITTIToCVML(tracklets,sprintf('/home/amilan/storage/databases/KITTI/tracking/training/label_02/%04d.xml',s),{'Car','Pedestrian'});
end