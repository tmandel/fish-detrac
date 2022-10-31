function homedir=getHomeFolder()
% home directory

    homedir='/home/amilan';
    if ispc
        homedir='C:';
    end
    if exist('/gris/gris-f/home/aandriye','dir')
        homedir='/gris/gris-f/home/aandriye';
    end
end