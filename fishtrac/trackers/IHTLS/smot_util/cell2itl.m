function itl = cell2itl(cell_tracks)

N = size(cell_tracks,1);

% TODO: pre allocate for itl

for n=1:N
    itl(n).t_start = min(cell_tracks{n}(:,1));
    itl(n).t_end   = max(cell_tracks{n}(:,1));
    itl(n).length  = itl(n).t_end - itl(n).t_start +1;
    itl(n).omega   = ones(1,itl(n).length);
    itl(n).data    = cell_tracks{n}(:,2:end)';
end