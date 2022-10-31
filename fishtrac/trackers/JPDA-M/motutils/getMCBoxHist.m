function mchist=getMCBoxHist(bbox,channels,nbins)
% multi channel histogram
    if nargin<3
        nbins=getBinsCenters(8,0,1);
    end

    if length(nbins)==1
        nb=nbins;
    else
        nb=length(nbins);
    end
    mchist=zeros(max(channels),nb);
    mchist=zeros(length(channels),nb);
    ccnt=0;
    for c=channels
        ccnt=ccnt+1;
        pix=bbox(:,:,c); 
%         pix=pix(:);
%         chist=histc(pix,linspace(0,1,nb+1));
%         chist=chist'./numel(pix);
%         chist
        [chist, x]=imhist(pix,nb);
        chist=chist'./numel(pix);
        mchist(ccnt,:)=chist;
    end
end