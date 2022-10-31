function createNewPath(filePath)
% create new folder for saving results
if(~isdir(filePath))
    mkdir(filePath);
elseif(isdir(filePath))
    Dirs = dir(filePath);
    for i = 1:length(Dirs)
        % remove directory and all contents
        if(Dirs(i).isdir && ~strcmp(Dirs(i).name,'.') && ~strcmp(Dirs(i).name,'..'))
            rmdir([filePath Dirs(i).name],'s');
        % delete the files in corresponding directory
        elseif(~strcmp(Dirs(i).name,'.') && ~strcmp(Dirs(i).name,'..'))
            delete([filePath Dirs(i).name]);            
        end
    end
end