%%
Fgt=size(gtInfo.X,1);
id1=65; id2=65; 
ts1=426; ts2=429; 
shiftts=ts2:Fgt; ipolfr=ts1+1:ts2-1; mergefr=ts1-5:ts2+5;

%
fields={'X','Y','W','H','Xi','Yi'};
ipolmeth='linear';

for f=1:length(fields)
    curfield=char(fields{f});
    
    % shift from id2 to id1
    evalstr=sprintf( ...
        'gtInfo.%s(shiftts,id1) = gtInfo.%s(shiftts,id2); gtInfo.%s(:,id2)=0;', ...
        curfield,curfield,curfield);
    eval(evalstr);

    
    % interpolate
    
    evalstr=sprintf( ...
        'inds=find(gtInfo.%s(:,id1)); gtInfo.%s(ipolfr,id1) = interp1(inds,gtInfo.%s(inds,id1),ipolfr'');', ...
        curfield,curfield,curfield);
    eval(evalstr);

end
% displayGroundTruth(sceneInfo,gtInfo);