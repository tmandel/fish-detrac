function stateInfo = saveResults(itlfResult, detections, curSequence)

num_frame = length(curSequence.frameNums);
num_obj = length(itlfResult);
stateInfo = [];

stateInfo.F = num_frame;
stateInfo.X = zeros(num_frame,num_obj); 
stateInfo.Y = zeros(num_frame,num_obj);
stateInfo.frameNums = 1:num_frame;
stateInfo.Xgp = zeros(num_frame,num_obj);
stateInfo.Ygp = zeros(num_frame,num_obj);
stateInfo.Xi = zeros(num_frame,num_obj);
stateInfo.Yi = zeros(num_frame,num_obj);
stateInfo.H = zeros(num_frame,num_obj);
stateInfo.W = zeros(num_frame,num_obj);
left = zeros(num_frame,num_obj);
top = zeros(num_frame,num_obj);
right = zeros(num_frame,num_obj);
down = zeros(num_frame,num_obj);

for i = 1:num_obj
    Obj = itlfResult(i);
    cnt = 0;
    fr = [];
    newLoc = [];    
    for frame = Obj.t_start:Obj.t_end
        cnt = cnt + 1;
        loc = Obj.data(:,cnt);
        if(~isempty(detections(frame).xy))
            dist = pdist2(loc',detections(frame).xy);
            id = dist == min(dist);
            pos = detections(frame).rect(id,:);
            if(dist(id)==0)
                State(1) = pos(1) + pos(3)/2;
                State(2) = pos(2) + pos(4)/2;
                State(3) = pos(3);
                State(4) = pos(4);
            else
                State(1) = loc(1);
                State(2) = loc(2);
                State(3) = pos(3);
                State(4) = pos(4);
            end
          
            % i: Label
            % frame: frame index
            stateInfo.X(frame,i) = State(1);
            stateInfo.Y(frame,i) = State(2)+State(4)/2;
            stateInfo.Xgp(frame,i) =  State(1); % X position
            stateInfo.Ygp(frame,i) =  State(2); % Y position
            stateInfo.Xi(frame,i) =  State(1);
            stateInfo.Yi(frame,i) =  State(2)+State(4)/2;
            stateInfo.W(frame,i) =  State(3); % Width
            stateInfo.H(frame,i) =  State(4); % Height

            left(frame,i) = State(1)-State(3)/2;
            top(frame,i) = State(2)-State(4)/2;
            right(frame,i) = State(1)+State(3)/2;
            down(frame,i) = State(2)+State(4)/2;        
            if(dist(id)~=0)
                fr = cat(2, fr, frame);
                newLoc = cat(1, newLoc, loc');
            end
        end
    end
    if(~isempty(fr))
        idx = setdiff(Obj.t_start:Obj.t_end, fr);
        idxi = fr-Obj.t_start+1;       
        idy = stateInfo.W(idx,i);
        idyi = interp1(idx-Obj.t_start+1, idy, idxi,'linear');
        stateInfo.W(fr,i) = idyi;
        idy = stateInfo.H(idx,i);
        idyi = interp1(idx-Obj.t_start+1, idy, idxi,'linear');
        stateInfo.H(fr,i) = idyi;              
    end
end