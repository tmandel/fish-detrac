function dres = bboxes2dres(bboxes,minFrame,maxFrame)


dres.x = [];
dres.y = [];
dres.w = [];
dres.h = [];
dres.r = [];
dres.fr = [];
dres.origInd = [];
    
for i=minFrame:maxFrame
  
  if  i>length(bboxes) || isempty(bboxes{i})
    continue
  end
  bbox = [bboxes{i}(:,1:4) bboxes{i}(:,5)];
  dres.x = [dres.x; bbox(:,1)];
  dres.y = [dres.y; bbox(:,2)];
  dres.w = [dres.w; bbox(:,3) - bbox(:,1)+1];
  dres.h = [dres.h; bbox(:,4) - bbox(:,2)+1];
  dres.r = [dres.r; bbox(:,5)];
  dres.origInd = [dres.origInd; (1:size(bboxes{i},1))'];
  dres.fr = [dres.fr; repmat(i, [size(bbox,1) 1])];
end


