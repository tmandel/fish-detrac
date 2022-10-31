function [Xinit Yinit]=checkInitSolution(Xinit,Yinit,F)
% check if initial solution is correct
% 
% (C) Anton Andriyenko, 2012
%
% The code may be used free of charge for non-commercial and
% educational purposes, the only requirement is that this text is
% preserved within the derivative work. For any other purpose you
% must contact the authors for permission. This code may not be
% redistributed without written permission from the authors.

    assert(all(size(Xinit)==size(Yinit)), ... 
        'X and Y are of different size in initial solution');
    
    % pad with zeros if not enough frames
    Finit=size(Xinit,1);
    if Finit<F
        padframes=F-Finit;
        Xinit(end+1:end+padframes,:)=0;
        Yinit(end+1:end+padframes,:)=0;
    end
end