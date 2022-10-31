function sceneInfo=computeImBordersOnGroundPlane(opt,sceneInfo,detections)
    % compute image borders on ground plane

    % determine detection that is highest in image as top border
    imtoplimit=min([detections(:).xi]);

    % for 2D tracking, image border = 'ground plane'
    if ~opt.track3d
        sceneInfo.imOnGP= [...
            1 sceneInfo.imgHeight ...
            1 imtoplimit ...
            sceneInfo.imgWidth,imtoplimit ...
            sceneInfo.imgWidth,sceneInfo.imgHeight];

    else
        % if (static) camera calibration available, project image
        if isfield(sceneInfo,'camPar')
            
            [x1, y1]=imageToWorld(1,sceneInfo.imgHeight,sceneInfo.camPar); % left bottom
            [x2, y2]=imageToWorld(1,imtoplimit,sceneInfo.camPar);   % left top
            [x3, y3]=imageToWorld(sceneInfo.imgWidth,imtoplimit,sceneInfo.camPar);  % right top
            [x4, y4]=imageToWorld(sceneInfo.imgWidth,sceneInfo.imgHeight,sceneInfo.camPar); % tight bottom

            sceneInfo.imOnGP=[x1 y1 x2 y2 x3 y3 x4 y4];
        else
            % otherwise just take tracking area
            x1=sceneInfo.trackingArea(1); x2=sceneInfo.trackingArea(2);
            y1=sceneInfo.trackingArea(3); y2=sceneInfo.trackingArea(4);
            
            sceneInfo.imOnGP=[x1 y1 x1 y2 x2 y2 x2 y1];
        end
        
    end
end