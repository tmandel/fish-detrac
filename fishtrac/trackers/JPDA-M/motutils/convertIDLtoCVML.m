function convertIDLtoCVML(filename, sequence)


%%
% filename='d:\diss\others\fayao\dataset_track\afl4\imgs\afl4_anno.idl';
bboxes=readIDL(filename);

[p, f, ex]=fileparts(filename);
outfile=[p filesep f '.xml'];

F=length(bboxes);
clear gtInfo;
frameNums=1:F;
for t=1:F
    N=size(bboxes(t).bb,1);
    for id=1:N
        x1=bboxes(t).bb(id,1);y1=bboxes(t).bb(id,2);
        x2=bboxes(t).bb(id,3);y2=bboxes(t).bb(id,4);
        w=x2-x1; h=y2-y1;
        
        gtInfo.Xi(t,id)=x1+w/2;
        gtInfo.Yi(t,id)=y2;
        gtInfo.W(t,id)=w; gtInfo.H(t,id)=h;
    end    
end

gtInfo.frameNums=frameNums;
gtInfo.sceneInfo.sequence=sequence;

exportToCVML(gtInfo,outfile);

end
