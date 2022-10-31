%%
id=28; ts=244:446;
maxId=size(gtInfo.X,2); newID=maxId+1;
% newID=39;
gtInfo.X(ts,newID)=gtInfo.X(ts,id); gtInfo.X(ts,id)=0;
gtInfo.Y(ts,newID)=gtInfo.Y(ts,id); gtInfo.Y(ts,id)=0;
gtInfo.Xi(ts,newID)=gtInfo.Xi(ts,id); gtInfo.Xi(ts,id)=0;
gtInfo.Yi(ts,newID)=gtInfo.Yi(ts,id); gtInfo.Yi(ts,id)=0;
gtInfo.H(ts,newID)=gtInfo.H(ts,id); gtInfo.H(ts,id)=0;
gtInfo.W(ts,newID)=gtInfo.W(ts,id); gtInfo.W(ts,id)=0;