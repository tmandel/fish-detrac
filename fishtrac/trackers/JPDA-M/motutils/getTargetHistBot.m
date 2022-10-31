function th=getTargetHistBot(im,stateInfo,t,id)

[imgHeight imgWidth imC]=size(im);

bleft=round(stateInfo.Xi(t,id)-stateInfo.W(t,id)/2);
bright=round(stateInfo.Xi(t,id)+stateInfo.W(t,id)/2);
btop=round(stateInfo.Yi(t,id)-stateInfo.H(t,id));
bbottom=round(stateInfo.Yi(t,id));

[bleft bright btop bbottom]= ...
    clampBBox(bleft, bright, btop, bbottom, imgWidth, imgHeight);

crpBox=im(btop:bbottom,bleft:bright,:);
% imshow(crpBox);
% pause
% now get the center of the upper body

[boxHeight boxWidth, ~]=size(crpBox);
bleft=round(1/6*boxWidth);
bright=round(1/6*boxWidth + 2/3*boxWidth);
btop=1;
bbottom=round(1/2*boxHeight);

% complete upper body
bleft=1;
bright=boxWidth;
btop=1;
bbottom=round(1/2*boxHeight);

% complete body
% bleft=1;bright=boxWidth;
% btop=1;bbottom=boxHeight;


[bleft bright btop bbottom]= ...
    clampBBox(bleft, bright, btop, bbottom, boxWidth, boxHeight);


ubBox=crpBox(btop:bbottom, bleft:bright,:);

% complete lower body
bleft=1;
bright=boxWidth;
btop=round(1/2*boxHeight);
bbottom=boxHeight;
[bleft bright btop bbottom]= ...
    clampBBox(bleft, bright, btop, bbottom, boxWidth, boxHeight);


lbBox=crpBox(btop:bbottom, bleft:bright,:);

% imshow(ubBox);


th1=getMCBoxHist(ubBox,1:imC);
th2=getMCBoxHist(lbBox,1:imC);

th=th2;
end