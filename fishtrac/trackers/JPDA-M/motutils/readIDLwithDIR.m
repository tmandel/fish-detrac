% Return IDL structure for given filename
%
% INPUT
% filename filename of IDL file
%
% OUTPUT
% idl IDL structure, consisting of
%      idl.img - array of images
%      idl.bb - array of array of bounding box coordinates
%      idl.score - array of array of scores for boxes
%      idl.dir - array of orientations (1=east, ... 8=southeast)

function idl=readIDLwithDIR(filename)

fid=fopen(filename);
idl.bb=[];
idl.img=[];
idl.score=[];
idl.dir=[];

i=1;
bbnum=0;
while 1
    tline = fgetl(fid);
    if ~ischar(tline),   break,   end
    tline = strrep(tline, ',', ' '); %replace commas with spaces
    colon=strfind(tline,':'); %all colons
    
    if isempty(colon)
        point = strfind(tline,'";');
        if length(point) > 0
            idl(i).img=tline(2:point(1)-1); %filename
            i = i + 1;
            continue
        else
            break
        end
    end
    
    bb_idx=[(strfind(tline,'(')+1)' (strfind(tline,')')-1)'];%positions of bb start and stop
    
    idl(i).img=tline(2:colon(1)-2); %filename
    for k=1:size(bb_idx,1)
        idl(i).bb(end+1,:)=str2num(tline(bb_idx(k,1):bb_idx(k,2))); % next bb
    end
    
    if length(colon)>1 %there are scores in the file ...
        for k=1:size(bb_idx,1)-1
            col1pos=colon(2*k);
            col2pos=colon(2*k+1);
            nextbox=bb_idx(k+1,1);
            idl(i).score(end+1) = str2num(tline(col1pos+1:col2pos-1)); %next score
            idl(i).dir(end+1) = str2num(tline(col2pos+1:nextbox-2)); %next dir
        end
        idl(i).score(end+1) = str2num(tline(colon(length(colon)-1)+1:colon(length(colon))-1));
        idl(i).dir(end+1) = str2num(tline(colon(length(colon))+1:length(tline)-1));
    else
        idl(i).score = 1*ones(1,size(bb_idx,1));
    end
    
    i=i+1;
    bbnum = bbnum + size(bb_idx,1);
end
fclose(fid);

%   fprintf('%d bounding boxes loaded.', bbnum);
end