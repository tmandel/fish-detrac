%% This script is to visualize the tracking results
%% Smooth them if necessary and plot the tail
%% Afshin Dehghan
%% 10/08/2014

function plotTracking(trackResults, imPath, images, saveFlag, outDir)

tail_length = 50;
if(~exist(outDir,'dir'))
    mkdir(outDir);
end
save([outDir '/trackRes.mat'],'trackResults');


return % No need to show results in DETRAC
%csvwrite([outDir '/trackRes.mat'])
%% Smooth BBOX size
IDs = unique(trackResults(:,2))';
trk_tmp=zeros(size(trackResults,1),size(trackResults,2));
for iID=IDs
    ind = find(trackResults(:,2)==iID) ;
    for i=1:50:length(ind)
        bbox_width_avg = mean(trackResults(ind(i:min(i+49,length(ind))),5)-trackResults(ind(i:min(i+49,length(ind))),3));
        bbox_height_avg = mean(trackResults(ind(i:min(i+49,length(ind))),6)-trackResults(ind(i:min(i+49,length(ind))),4));
        center_x = (trackResults(ind(i:min(i+49,length(ind))),5)+trackResults(ind(i:min(i+49,length(ind))),3))/2;
        center_y = (trackResults(ind(i:min(i+49,length(ind))),6)+trackResults(ind(i:min(i+49,length(ind))),4))/2;
        trk_tmp(ind(i:min(i+49,length(ind))),1:2)=trackResults(ind(i:min(i+49,length(ind))),1:2);
        trk_tmp(ind(i:min(i+49,length(ind))),3)  =center_x-bbox_width_avg/2;
        trk_tmp(ind(i:min(i+49,length(ind))),5)  =center_x+bbox_width_avg/2;
        trk_tmp(ind(i:min(i+49,length(ind))),4)  =center_y-bbox_height_avg/2;
        trk_tmp(ind(i:min(i+49,length(ind))),6)  =center_y+bbox_height_avg/2;
    end
end
trackResults = trk_tmp;

%% Show the results
time1 = tic;
numClicks = max(unique(trackResults(:,2)))+2;
minFrame = min(trackResults(:,1));
maxFrame = max(trackResults(:,1));
cc = hsv(numClicks+2);


for iFrame = [minFrame:1:maxFrame]
    im = imread(fullfile(imPath,images(iFrame).name));
    %im = imresize(im,0.5);
    ind = find(trackResults(:,1)==iFrame);
    
    for iTrk=1:length(ind)
        ID = trackResults(ind(iTrk),2);
        boxTMP = trackResults(ind(iTrk),3:end);%/2;
        % Show ID of each person
        heightBox = boxTMP(4)-boxTMP(2)+1;
        widthBox  = boxTMP(3)-boxTMP(1)+1;
        im(max(1,round(boxTMP(2)-0.2*heightBox)):round(boxTMP(2)),max(1,round(boxTMP(1))):round(boxTMP(3)),1)=uint8(255*cc(ID,1));
        im(max(1,round(boxTMP(2)-0.2*heightBox)):round(boxTMP(2)),max(1,round(boxTMP(1))):round(boxTMP(3)),2)=uint8(255*cc(ID,2));
        im(max(1,round(boxTMP(2)-0.2*heightBox)):round(boxTMP(2)),max(1,round(boxTMP(1))):round(boxTMP(3)),3)=uint8(255*cc(ID,3));
    end
    
    imshow(im);hold on;
%     text(round(size(im,2))-150,60,sprintf('#%03d',iFrame),'FontSize',30,'FontWeight','bold','BackgroundColor','yellow');
    text(round(size(im,2))-250,round(size(im,1))-120,sprintf('#%03d',iFrame),'FontSize',30,'FontWeight','bold','BackgroundColor','yellow');
    
    for iTrk=1:length(ind)
        ID = trackResults(ind(iTrk),2);
        boxTMP = trackResults(ind(iTrk),3:end);%/2;
        line([boxTMP(1) boxTMP(3) boxTMP(3) boxTMP(1) boxTMP(1)],[boxTMP(2) boxTMP(2) boxTMP(4) boxTMP(4) boxTMP(2)],'color',cc(ID,:),'LineWidth',1.5);
        text(round((boxTMP(1)+boxTMP(3))/2)-20,round((boxTMP(2)))-15,num2str(ID),'FontName','Times New Roman','FontSize',12,'FontWeight','bold');
        % Tail
        indID = find(trackResults(:,2)==ID);
        framesID = trackResults(indID,1);
        centerX=0.5*(trackResults(indID,3)+trackResults(indID,5));
        centerY=0.5*(trackResults(indID,4)+trackResults(indID,6));
        centerY=(trackResults(indID,6));%+trackResults(indID,6));
        if ((iFrame-framesID(1))>2)
            if(length(1:(iFrame-framesID(1)))<(tail_length+1))
                %centerX = 0.5*centerX(1:(iFrame-framesID(1)));
                %centerY = 0.5*centerY(1:(iFrame-framesID(1)));
                
                centerX = 1*centerX(1:(iFrame-framesID(1)));
                centerY = 1*centerY(1:(iFrame-framesID(1)));
            else
                %centerX = 0.5*centerX(((iFrame-framesID(1))-tail_length):(iFrame-framesID(1)));
                %centerY = 0.5*centerY(((iFrame-framesID(1))-tail_length):(iFrame-framesID(1)));
                centerX = 1*centerX(((iFrame-framesID(1))-tail_length):(iFrame-framesID(1)));
                centerY = 1*centerY(((iFrame-framesID(1))-tail_length):(iFrame-framesID(1)));
            end
            plot(centerX,centerY,'-mo','color',cc(ID,:),'LineWidth',1.5,'MarkerSize',1.5,'MarkerFaceColor',cc(ID,:));
        end
    end
    hold off;
    pause(0.01);
    if(saveFlag)
        disp(gcf),disp('-dpng'),disp('-r100'),disp([outDir sprintf('%03d.jpg',iFrame)]);%original print
    end
end










