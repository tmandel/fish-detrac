function [indx,reliable,new] = Idx2Types(Trk,type)
%% Copyright (C) 2014 Seung-Hwan Bae
%% All rights reserved.

indx = [];
reliable = [];
new = [];
for i=1:length(Trk)
    if strcmp(Trk(i).type, type)
        indx = [indx,i];
        if Trk(i).reliable == 1
            reliable =[reliable,i];
        end
        if Trk(i).isnew == 1
            new =[new,i];
        end
    end
end

end