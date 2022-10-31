%%
detfile='/home/aanton/storage/databases/TUD/tud-stadtmitte/cvpr10_tud_stadtmitte.al';
xDoc=xmlread(detfile);
allFrames=xDoc.getElementsByTagName('annotation');
F=allFrames.getLength;
frameNums=zeros(1,F);
    
outfile='/home/aanton/storage/databases/TUD/tud-stadtmitte/cvpr10_tud_stadtmitte.idl';
fid=fopen(outfile,'a');

%%
%
frToParse=1:F;
    
for t=frToParse
    if ~mod(t,10), fprintf('.'); end
    
    str2write='';
    
    % frame
%     imagenode=allFrames.item(t-1).getElementsByTagName('image');
    imfilenode=allFrames.item(t-1).getElementsByTagName('name');
    imfile=imfilenode.item(0).getFirstChild.getData;
    imfile=char(imfile);
%     
    str2write=sprintf('%s"%s":',str2write,imfile);
    objects=allFrames.item(t-1).getElementsByTagName('annorect');    
    Nt=objects.getLength;
    nboxes=Nt; % how many detections in current frame
    boxleft=zeros(1,nboxes);
    boxtop=zeros(1,nboxes);
    boxright=zeros(1,nboxes);
    boxbottom=zeros(1,nboxes);
    
    
    
    
        
    sepstr=',';
    for i=0:Nt-1
        if i==Nt-1, sepstr=';'; end
        % score
        boxid=i+1;
        boxl=objects.item(i).getElementsByTagName('x1');
        boxt=objects.item(i).getElementsByTagName('y1');
        boxr=objects.item(i).getElementsByTagName('x2');
        boxb=objects.item(i).getElementsByTagName('y2');

        boxleft=str2double(boxl.item(0).getFirstChild.getData);
        boxtop=str2double(boxt.item(0).getFirstChild.getData);
        boxright=str2double(boxr.item(0).getFirstChild.getData);
        boxbottom=str2double(boxb.item(0).getFirstChild.getData);
        str2write=sprintf('%s (%g,%g,%g,%g):-1%s',str2write,boxleft,boxtop,boxright,boxbottom,sepstr);
    end
    
    str2write=sprintf('%s\n',str2write);
    fprintf(fid,str2write);
    
%     str2write
%     pause
    
    
end

fclose(fid);