function homedir=getHomeFolder()
% 
% (C) Anton Andriyenko, 2012
%
% The code may be used free of charge for non-commercial and
% educational purposes, the only requirement is that this text is
% preserved within the derivative work. For any other purpose you
% must contact the authors for permission. This code may not be
% redistributed without written permission from the authors.

    homedir='/home/aanton';
    if ispc
        homedir='D:';
    end
    if exist('/gris/gris-f/home/aandriye','dir')
        homedir='/gris/gris-f/home/aandriye';
    end
end