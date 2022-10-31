% function smoothTraj=smooth_trajectory(centers)   
% wts = [1/12;repmat(1/6,5,1);1/12];
% % wts = [1/24;repmat(1/12,11,1);1/24];
% smoothTrajTmp = conv(centers(:,1),wts,'valid');
% smoothTrajTmp(:,2) = conv(centers(:,2),wts,'valid');
% diffLength = size(centers,1)-size(smoothTrajTmp,1);
% smoothTraj(:,1)=interp1(diffLength/2+1:diffLength/2+size(smoothTrajTmp,1),smoothTrajTmp(:,1),1:size(centers,1),'linear','extrap')';
% smoothTraj(:,2)=interp1(diffLength/2+1:diffLength/2+size(smoothTrajTmp,1),smoothTrajTmp(:,2),1:size(centers,1),'linear','extrap')';
% smoothTraj = round(smoothTraj);
% 

function smoothTraj=smooth_trajectory(centers)
if(size(centers,1)>50)
    wts = [1/36;repmat(1/18,17,1);1/36];
elseif(size(centers,1)>30)
    wts = [1/24;repmat(1/12,11,1);1/24];
elseif(size(centers,1)>24)
    wts = [1/12;repmat(1/6,5,1);1/12];
else
    wts = [1/6;repmat(1/3,2,1);1/6];
end
% wts = [1/24;repmat(1/12,11,1);1/24];
if(size(centers,1)>8)
smoothTrajTmp = conv(centers(:,1),wts,'valid');
smoothTrajTmp(:,2) = conv(centers(:,2),wts,'valid');
diffLength = size(centers,1)-size(smoothTrajTmp,1);
smoothTraj(:,1)=interp1(diffLength/2+1:diffLength/2+size(smoothTrajTmp,1),smoothTrajTmp(:,1),1:size(centers,1),'linear','extrap')';
smoothTraj(:,2)=interp1(diffLength/2+1:diffLength/2+size(smoothTrajTmp,1),smoothTrajTmp(:,2),1:size(centers,1),'linear','extrap')';
smoothTraj = round(smoothTraj);
else
    smoothTraj = centers;
end