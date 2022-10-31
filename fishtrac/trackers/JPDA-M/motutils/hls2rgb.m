function rgb=hls2rgb(hue_light_sat)

rgb=zeros(size(hue_light_sat));

h = hue_light_sat(:,:,1);
l =  hue_light_sat(:,:,2)/10;
s =  hue_light_sat(:,:,3)/1;

m2 = l + s - (l .* s);

inds=find(l<0.5);
m2(inds) = l(inds) .* (1 +s(inds));


m1 = (2.0 * l) - m2;

inds1=find(~s);
if ~isempty(inds1)
    inds2=intersect(find(h<0), inds1);
    rgb(inds2)=l(inds2);
else
    rgb(:,:,1)=hue_value(m1,m2,h-120);
    rgb(:,:,2)=hue_value(m1,m2,h);
    rgb(:,:,3)=hue_value(m1,m2,h+120);    

end

valrange=max(rgb(:))-min(rgb(:));
rgb=rgb-min(rgb(:));
rgb=rgb/valrange;

end

function hue=hue_value( n1, n2, hue )


toolarge=find(hue>360);
hue(toolarge)=hue(toolarge)-360;

toosmall=find(hue<0);
hue(toosmall)=hue(toosmall)+360;



small=find(hue<60);
hue(small)=n1(small)+(n2(small)-n1(small)).*hue(small)./60;

med=find(hue<180 & hue>=60);
hue(med)=n2(med);

lar=find(hue<240 & hue>=180);
hue(lar)=n1(lar)+(n2(lar)-n1(lar)).*(240-hue(lar))./60;

oth=find(hue>=240);
hue(oth)=n1(oth);
end