function [Xinit Yinit]=checkInitSolution(Xinit,Yinit,F)
% check if initial solution is correct

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