function [imgFormat, imgExt, frameNums]=getImgFormat(folder,ext)
% try to determine the image format for a sequence
% folder - image file folder
% ext - (optional) provide file extension
% if no extension is provided, it is determined as the
% dominating file type within folder
%
% The format is determined by all static characters (slow)

imgFormat='';
imgExt='';

assert(exist(folder,'dir')~=0,'Image folder %s does not exist',folder);

% first determine extension
if nargin<2 || isempty(ext)
    ext='';
    domext=0;
    exts={'jpg','jpeg','png'};
    for e=1:length(exts)
        dirlisting=dir([folder,filesep,'*.' char(exts{e})]);
        if length(dirlisting)>domext
            ext=char(exts{e});
            domext=length(dirlisting);
        end
    end
    % if no images found, throw error
    if domext==0, error('No images found in folder %s\n',folder); end    
end

if isequal(ext(1),'.')
  ext=ext(2:end);
end

% now guess format    
dirlisting=dir([folder,filesep,'*.' ext]);
F=length(dirlisting);
if isempty(dirlisting)
    error('No .%s files found in %s',ext,folder);
end

% grab first file name without extension
fname=strsplit(dirlisting(1).name,'.');
fname=char(fname{1});


staticchar=true(1,length(fname));
for f=2:length(dirlisting)
    fname2=strsplit(dirlisting(f).name,'.');
    fname2=char(fname2{1});
    
    if length(fname)~=length(fname)
        error('image files do not have equal lengths');
    end
    
    for c=1:length(fname)
        % if 
        if ~isequal(fname(c),fname2(c))
            % if characters different but not numeric, error
            if isempty(regexp(fname(c),'\d', 'once'));
                error('non-numeric values differ in file names');
            else
                staticchar(c)=0;
            end
        end
    end
    fname=fname2;
end
% staticchar
fc=find(~staticchar,1,'first');
lc=find(~staticchar,1,'last');
ln=lc-fc+1;

% static prefix
prefix='';
if fc>1
    prefix=fname(1:fc-1);
    imgFormat(1:fc-1)=prefix;
end

% dynamic numeric counter
counterstring=sprintf('%%0%dd',ln);
lencs=length(counterstring);
imgFormat(fc:fc+lencs-1)=counterstring;

% static suffix
suffix='';
if lc<length(fname)
    suffixlength=length(fname)-lc;
    suffix=fname(lc+1:end);
    imgFormat(end+1:end+suffixlength)=suffix;
end
fprintf('Recovered image format: %s.%s\n',imgFormat,ext);


% image extension
imgExt=['.' ext];

% determine frame numbers
% first
fname=strsplit(dirlisting(1).name,'.'); fname=char(fname{1});
ff=sscanf(fname,[prefix counterstring suffix]);
% last
fname=strsplit(dirlisting(end).name,'.'); fname=char(fname{1});
lf=sscanf(fname,[prefix counterstring suffix]);
frameNums=ff:lf;
fprintf('sequence runs from frame %d to frame %d (%d frames)\n',ff,lf,length(frameNums));

% finally, test for correctness
for t=1:F
    filestr=[sprintf(imgFormat,frameNums(t)) imgExt];
    if ~isequal(dirlisting(t).name, filestr)
        error('Expected %s, but found %s',filestr,dirlisting(t).name)
    end
end


% find numeric values
% numval=false(1,length(fname));
% for l=1:length(fname)
%     numval(l)=~isempty(regexp(fname(l),'\d', 'once'));
% end
% numval
% 
% residfname=fname;
% while ~isempty(residfname)
%     
% end

end