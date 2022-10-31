function [x, y, w, h]=getBBox(stateInfo,t,id)
% return [x, y, w, h] from stateInfo at t, id

    w=stateInfo.W(t,id);
    h=stateInfo.H(t,id);
    x=stateInfo.Xi(t,id)-w/2;
    y=stateInfo.Yi(t,id)-h;
    
end