function itl = process_itl_associations(itl,assign,param)

% take a copy of A. We will manipulate it. 
assign_0 = assign;
for i=1:length(assign)
    
    j = i;    
    while assign(j)~=0
        % merge two itls considering the gap in between
        itl(i) = mergeitl(itl(i),itl(assign(j)),param);
        % book keep the id of merges
        itl(i).id = [itl(i).id itl(assign(j)).id];
        % next
        jnext = assign(j);        
        assign(j) = 0;
        j = jnext;
    end
end
assign = assign_0;
itl(assign(assign>0)) = [];