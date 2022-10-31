%import the csv through the import option in the toolbar as a ble in the
%workspace. You don't need the column names. 
%Make sure to set the default of  unreadable from NaN to 0
temp = [Vid2Tracks{:,1},Vid2Tracks{:,3},Vid2Tracks{:,4}, Vid2Tracks{:,5}, Vid2Tracks{:,6}-Vid2Tracks{:,4}, Vid2Tracks{:,7} - Vid2Tracks{:,5}];
out = zeros(max(temp(:,2))+1,max(temp(1)));
for i = 1:length(temp)
    outT = temp(i,:);
    out(outT(2)+1,outT(1)+1) = [outT(3)];
end 
X = out;
for i = 1:length(temp)
    outT = temp(i,:);
    out(outT(2)+1,outT(1)+1) = [outT(4)];
end 
Y = out;
for i = 1:length(temp)
    outT = temp(i,:);
    out(outT(2)+1,outT(1)+1) = [outT(5)];
end 
W = out;
for i = 1:length(temp)
    outT = temp(i,:);
    out(outT(2)+1,outT(1)+1) = [outT(6)];
end 
H = out;
%remove all columns with only zeros
H = H(:,any(H));
W = W(:,any(W));
Y = Y(:,any(Y));
X = X(:,any(X));
%right click the gtInfo struct and select save as to create a .mat file
gtInfo = struct('X', X+W/2, 'Y', Y+H,'H',H,'W',W,'frameNums', [1:(max(temp(:,2))+1)]);
csvwrite('02_Oct_18_Vid-3_LX.csv',X)
csvwrite('02_Oct_18_Vid-3_LY.csv',Y)
csvwrite('02_Oct_18_Vid-3_H.csv',H)
csvwrite('02_Oct_18_Vid-3_W.csv',W)