function showitl(itl,seqPath,varargin)

defTail = 0;
defSavePath = '';
defDrawRects = false;
defFixedWH = [-1 -1];

% Check user input parameters
p = inputParser;
addParamValue(p,'saveoutput',defSavePath,@ischar);
addParamValue(p,'tail',defTail,@isnumeric);
addParamValue(p,'rects',defDrawRects,@islogical);
addParamValue(p,'fixedwh',defFixedWH,@isnumeric);
parse(p,varargin{:});
 
tail = p.Results.tail;
saveFolder = p.Results.saveoutput;
drawRects = p.Results.rects;
fixedwh = p.Results.fixedwh;

if fixedwh(1)>0 fixedwh(2)>0;
    drawRects = true;
    useFixedWH = true;    
end


% fix if id field is missing
if ~isfield(itl,'id')
    for k=1:size(itl,2)
        itl(k).id = k;
    end
end
    

% initializations for visuals
hFig = figure;
iptsetpref('ImshowBorder','tight');
%hseq = seqreader(seqPath);
dataset = dir([seqPath '/*.jpg']);
colorSet = colormap('lines');
lineSet = {'--','-'};

if ~isempty(saveFolder)
    if ~exist(saveFolder)
        mkdir(saveFolder);
    end    
end
% h = hseq.Height;
% w = hseq.Width;

% sort the itl start and end times
[t_start, ind_start]= sort([itl.t_start]);
[t_end, ind_end]= sort([itl.t_end]);

idx = [];
for t = 1:length(dataset)%hseq.NumOfFrames
    % add starting tracklets
    nidx = ind_start(t_start==t);
    idx = [idx nidx];
    % delete ending tracklets
    didx = ind_end(t_end==t);
    for k=1:length(didx)
        idx(idx==didx(k))=[];
    end    
    
    img = imread([seqPath '/' dataset(t).name]);%grabFrame(hseq);
    imshow(img); hold on;
    
    
    for k=1:length(idx)    
        omega = itl(idx(k)).omega(t-itl(idx(k)).t_start+1);
        colorid = mod(idx(k),64)+1;
        
        % FIX: Our objects do not have rectangles now
        if drawRects
            
            if useFixedWH
                xy  = itl(idx(k)).xy(:,t-itl(idx(k)).t_start+1);
                rect = [xy'-fixedwh/2 fixedwh];
            else
                rect  = itl(idx(k)).rect(:,t-itl(idx(k)).t_start+1);            
            end
            
            if rect(3)>0 && rect(4)>0
            rectangle('Position',rect,'EdgeColor',colorSet(colorid,:),...
                'LineWidth',6,'LineStyle',lineSet{omega+1});
            rectangle('Position',[rect(1:2)+2 rect(3:4)-4],'EdgeColor',[0 0 0],...
                'LineWidth',3);
            rectangle('Position',[rect(1:2)+4 rect(3:4)-8],'EdgeColor',[1 1 1],...
                'LineWidth',3);

            end
            text(rect(1)+15,rect(2)+15,int2str(idx(k)),'Color',colorSet(colorid,:),'FontSize',18);            
        end
        
        
        
        if tail > 0
            xy = itl(idx(k)).data(:,...
                max(t-itl(idx(k)).t_start - tail,1)...
                :t-itl(idx(k)).t_start+1);
            plot(xy(1,:),xy(2,:),'Color',colorSet(colorid,:),'LineWidth',6);
        end
        
    end
    hold off; drawnow;
    
    % save output
    if ~isempty(saveFolder)
        frame = getframe(hFig);
        [~,imgName,imgExt] = fileparts(hseq.CurrentImageName);
        imgFullName = [saveFolder '/' imgName imgExt];
%         display(['saving ' imgFullName]);
        imwrite(frame.cdata,imgFullName);
    end
    
   
end

% for t = 1:hseq.NumOfFrames
% 
%     img = grabFrame(hseq);    
%     imshow(img); hold on;
%     
%     [idx,rects] = get_itl_rects(itl,t);
%     
%     for k=1:length(idx)
%         rect = rects(:,k);
%         colorid = mod(idx(k),256)+1;
%         rectangle('Position',rect,'EdgeColor',colorSet(colorid,:),'LineWidth',3);
%         text(rect(1)+5,rect(2)+5,int2str(idx(k)),'Color',colorSet(colorid,:),'FontSize',18);
%         
%         if tail>0
%             
%         end
%     end
%     hold off;
%     drawnow;
%         
% 
%     
%     if ~isempty(saveFolder)
%         frame = getframe(hFig);
%         [~,imgName,imgExt] = fileparts(hseq.CurrentImageName);
%         imgFullName = [saveFolder '/' imgName imgExt];
%         display(['saving ' imgFullName]);
%         imwrite(frame.cdata,imgFullName);
%     end
%     
% end

