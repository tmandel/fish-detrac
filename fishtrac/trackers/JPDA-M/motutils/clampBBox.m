function [bleft bright btop bbottom]= ...
    clampBBox(bleft, bright, btop, bbottom, imgWidth, imgHeight)
% clamp bounding box to [1, imageDim]
% 


bleft=max(1,bleft); bleft=min(imgWidth,bleft);
bright=max(1,bright); bright=min(imgWidth,bright);
btop=max(1,btop); btop=min(imgHeight,btop);
bbottom=max(1,bbottom); bbottom=min(imgHeight,bbottom);

end