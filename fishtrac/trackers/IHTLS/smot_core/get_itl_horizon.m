function itlh = get_itl_horizon(itl,horizon)

N = size(itl,2);

hormin = horizon(1);
hormax = horizon(2);

f = ([itl.t_end]' <= hormin) | ([itl.t_start]' >= hormax);
f = ~f;
itlh = itl(f);
id = [1:N];
id = id(f);

for n=1:size(itlh,2)
    % check start
    si = max(hormin - itlh(n).t_start, 0);     
    ei = max(itlh(n).t_end - hormax, 0);
    
    itlh(n).data = itlh(n).data(:,1+si:end-ei);
    itlh(n).omega = itlh(n).omega(1+si:end-ei);
    itlh(n).t_start = max(itlh(n).t_start, hormin);
    itlh(n).t_end = min(itlh(n).t_end, hormax);
    itlh(n).length = itlh(n).t_end - itlh(n).t_start + 1;
        
end

% add id field which will be useful putting back the horizon
if ~isempty(id)
    id = num2cell(id);
    [itlh.id] = deal(id{:});
end

