%%
id1=40; id2=42;
ts=474;
tmp=gtInfo.X(ts,id1); gtInfo.X(ts,id1)=gtInfo.X(ts,id2); gtInfo.X(ts,id2)=tmp;
tmp=gtInfo.Xi(ts,id1); gtInfo.Xi(ts,id1)=gtInfo.Xi(ts,id2); gtInfo.Xi(ts,id2)=tmp;
tmp=gtInfo.Y(ts,id1); gtInfo.Y(ts,id1)=gtInfo.Y(ts,id2); gtInfo.Y(ts,id2)=tmp;
tmp=gtInfo.Yi(ts,id1); gtInfo.Yi(ts,id1)=gtInfo.Yi(ts,id2); gtInfo.Yi(ts,id2)=tmp;
tmp=gtInfo.W(ts,id1); gtInfo.W(ts,id1)=gtInfo.W(ts,id2); gtInfo.W(ts,id2)=tmp;
tmp=gtInfo.H(ts,id1); gtInfo.H(ts,id1)=gtInfo.H(ts,id2); gtInfo.H(ts,id2)=tmp;