function tracklets=convertToKITTI(stateInfo, class)

tracklets=[];
[F,N]=size(stateInfo.Xi);
if nargin<2
    class='Car';
end

for t=1:F
    extar=find(stateInfo.Xi(t,:));
    ocnt=0;
    for id=extar
        ocnt=ocnt+1;
        tracklets{t}(ocnt).frame = stateInfo.frameNums(t);
        tracklets{t}(ocnt).id = id;
        
        if isfield(stateInfo,'C')
            switch(stateInfo.C(t,id))
                case 1
                    class='Car';
                case 2
                    class='Pedestrian';
            end
        end
        tracklets{t}(ocnt).type = class;
        tracklets{t}(ocnt).x1 = stateInfo.Xi(t,id)-stateInfo.W(t,id)/2 - 1;
        tracklets{t}(ocnt).y1= stateInfo.Yi(t,id)-stateInfo.H(t,id) - 1;
        tracklets{t}(ocnt).x2 = stateInfo.Xi(t,id)+stateInfo.W(t,id)/2 - 1;
        tracklets{t}(ocnt).y2= stateInfo.Yi(t,id) - 1;
        
        % take label cost as tracklet score
        if isfield(stateInfo,'splines')
            tracklets{t}(ocnt).score= stateInfo.splines(id).labelCost;
        end
    end
end

end