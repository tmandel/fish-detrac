function [Track] = track_management(Track)

Track_temp = Track;
Track = {};
idx = 0;
for i=1:length(Track_temp)
    if(Track_temp{i}.survival ==1)
        idx = idx + 1;
        Track{idx} = Track_temp{i};
    end
end
% Graph (Link) initialization
for i=1:length(Track)
    Track{i}.graph = [];
    Track{i}.link = [];
    Track{i}.graph_x = [];
end