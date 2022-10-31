function stateInfo = dropTracks(stateInfo, curSequence)
%% Thank Victor Stamatescu <Victor.Stamatescu@unisa.edu.au> for his valuable comment to add this function

global options

% drop system tracks in ignored regions
ignoreRegion = curSequence.ignoreRegion;
imgHeight = curSequence.imgHeight;
imgWidth = curSequence.imgWidth;

dropBoxes = 0;
totalBoxes = 0;

if(~isempty(ignoreRegion))
    igrMap = zeros(imgHeight, imgWidth);
    numIgnore = size(ignoreRegion, 1);
    for j = 1:numIgnore
        igrMap(ignoreRegion(j,2):min(imgHeight,ignoreRegion(j,2)+ignoreRegion(j,4)),ignoreRegion(j,1):min(imgWidth,ignoreRegion(j,1)+ignoreRegion(j,3))) = 1;
    end
    intIgrMap = createIntImg(double(igrMap));
    if(options.showRemoveResults)
        figure(10); imagesc(igrMap); colormap bone; colorbar;
        title('tracks: blue-drop red-keep, ignore region: white');
    end
    for i = 1:size(stateInfo.W,2)% tracks
        for j = 1:size(stateInfo.W,1)% frames
            h = round(stateInfo.H(j,i));
            w = round(stateInfo.W(j,i));
            if(w==0 || h==0)
                continue;
            end
            totalBoxes = totalBoxes + 1;
            
            xc = stateInfo.X(j,i);
            yc = stateInfo.Y(j,i) - h/2;
            x = round(xc - w/2);
            y = round(yc - h/2);
            if(options.showRemoveResults)
                Left = x;
                Top = y;
                BoundingBox_X1 = Left;
                BoundingBox_Y1 = Top + h;
                BoundingBox_X2 = Left;
                BoundingBox_Y2 = Top;
                BoundingBox_X3 = Left + w;
                BoundingBox_Y3 = Top;
                BoundingBox_X4 = Left + w;
                BoundingBox_Y4 = Top + h;
            end
            tl = intIgrMap(max(1,min(imgHeight,y)), max(1,min(imgWidth,x)));
            tr = intIgrMap(max(1,min(imgHeight,y)), max(1,min(imgWidth,x+w)));
            bl = intIgrMap(max(1,min(imgHeight,y+h)), max(1,min(imgWidth,x)));
            br = intIgrMap(max(1,min(imgHeight,y+h)), max(1,min(imgWidth,x+w)));
            ignoreValue = tl + br - tr - bl;
            if(ignoreValue/(h*w)>=0.5)
                dropBoxes =  +1;
                stateInfo.W(j,i) = 0;
                stateInfo.H(j,i) = 0;
                stateInfo.X(j,i) = 0;
                stateInfo.Y(j,i) = 0;
                stateInfo.Xi(j,i) = 0;
                stateInfo.Yi(j,i) = 0;
                if(options.showRemoveResults)
                    rect.vertices = [BoundingBox_X1 BoundingBox_Y1; BoundingBox_X2 BoundingBox_Y2;...
                        BoundingBox_X3 BoundingBox_Y3; BoundingBox_X4 BoundingBox_Y4; BoundingBox_X1 BoundingBox_Y1];
                    rect.faces = [1 2 3 4]; 
                    hold on;  patch(rect,'Vertices',rect.vertices,'FaceColor',[0 0 1],'FaceAlpha',0.1); hold off; pause(0.1);
                end
            else
                if(options.showRemoveResults)
                    rect.vertices = [BoundingBox_X1 BoundingBox_Y1; BoundingBox_X2 BoundingBox_Y2;...
                        BoundingBox_X3 BoundingBox_Y3; BoundingBox_X4 BoundingBox_Y4; BoundingBox_X1 BoundingBox_Y1];
                    rect.faces = [1 2 3 4];
                    hold on;  patch(rect,'Vertices',rect.vertices,'FaceColor',[1 0 0],'FaceAlpha',0.1); hold off; pause(0.1);
                end
            end
        end
    end
end

if(dropBoxes)
    %disp(['Ignored Regions ---> dropped ' num2str(dropBoxes) ' out of ' num2str(totalBoxes) ' boxes']);
end