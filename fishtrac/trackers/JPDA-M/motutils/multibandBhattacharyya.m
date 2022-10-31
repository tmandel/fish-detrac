function res=multibandBhattacharyya(h1, h2)

assert(all(size(h1)==size(h2)),'Histogram dimensions must agree');

cbands=size(h1,2);
res=zeros(1,cbands);
for c=1:cbands
    res(c)=bhattacharyya(h1(:,c),h2(:,c));
end
% res
res=mean(res);

end