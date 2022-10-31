function prepFigure()
% prepare figure for showing state
% 
% (C) Anton Andriyenko, 2012
%
% The code may be used free of charge for non-commercial and
% educational purposes, the only requirement is that this text is
% preserved within the derivative work. For any other purpose you
% must contact the authors for permission. This code may not be
% redistributed without written permission from the authors.

global sceneInfo opt;

% figh=findobj('type','figure','name','optimization');

% if isempty(figh), figh=figure('name','optimization'); end
% set(figh);

clf;
hold on;
box on

if ~opt.track3d
    set(gca,'Ydir','reverse');
end
xlim(sceneInfo.trackingArea(1:2))
ylim(sceneInfo.trackingArea(3:4))
if ~opt.track3d
    ylim([sceneInfo.imTopLimit sceneInfo.trackingArea(4)]);
end

zlim([0 length(sceneInfo.frameNums)])

view(-78,4)
if ~opt.track3d
    view(-40,10);
end

end