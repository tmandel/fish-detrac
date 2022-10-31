function gtInfo=convertAtaToCVML(annoroot, outfile, frshift)
% Generate Ground Truth from Annotated Bounding Boxes

nUnique = 0;
uuidLUT=cell(nUnique,2);

if nargin<3, frshift=0; end

% images=sprintf('../%s-c%i_%%04d.%s',sequence,cam,fileformat);

% images=images(strfind(images,sequence):end);
%%% !!! IMAGE FORMAT FIXED
images = 'img%05d.png';
dirlisting=dir([annoroot '*.ata']);
% dirlisting=zeros(
% dirlisting=dirlisting.name;

F=numel(dirlisting);
fprintf('%d frames annotated\n',F);

Xi=zeros(0);
Yi=zeros(0);
W=zeros(0);
H=zeros(0);

for t=1:F
    if (mod(t,100) == 0)
        fprintf('%.2f%% read\n',t/F*100);
    end
    xDoc=xmlread(fullfile(annoroot,dirlisting(t).name));
    imagefile=xDoc.getElementsByTagName('file');
    imagefile=imagefile.item(0).getFirstChild.getNodeValue;
    imagefile=char(imagefile);
    frame=sscanf(imagefile,images);
    allAnnos=xDoc.getElementsByTagName('annotation');
    
    
    %disp(sprintf('frame %i has %i annotations',frame,allAnnos.getLength))
    for i=0:allAnnos.getLength-1
        uuid=allAnnos.item(i).getAttribute('uuid');
        uuid=char(uuid);
        idx=regexpi(uuid,'[^-]');
        uuidt=uuid(idx);
        uuidt=hex2dec(uuidt);
        
        matches = find(strcmpi(uuidLUT(:,1),uuid));
        if(size(matches,1) == 0)
            nUnique=nUnique+1;
            uuidLUT(nUnique,1)=cellstr(uuid);
            uuidLUT(nUnique,2)=num2cell(nUnique);
            id = nUnique;
            fprintf('uid %i in frame %i, uuid %s, file %s\n',id,frame,uuid,dirlisting(t).name);
        elseif (size(matches,1) == 1)
            id=cell2mat(uuidLUT(matches(1),2));
        else
            error('something wrong with the lookup table');
        end
        %             [frame id]
        %             pause
        W(frame,id)=str2double(allAnnos.item(i).getElementsByTagName('size').item(0).getAttribute('w'));
        H(frame,id)=str2double(allAnnos.item(i).getElementsByTagName('size').item(0).getAttribute('h'));
        x1=str2double(allAnnos.item(i).getElementsByTagName('point').item(0).getAttribute('x'));
        y1=str2double(allAnnos.item(i).getElementsByTagName('point').item(0).getAttribute('y'));
        
        Xi(frame,id)=x1+W(frame,id)/2;
        Yi(frame,id)=y1+H(frame,id);
        
        
    end
end
[F, N] = size(Xi);

fprintf('all read\n');

gtInfo.Xi=Xi;
gtInfo.Yi=Yi;
gtInfo.H=H;
gtInfo.W=W;

end