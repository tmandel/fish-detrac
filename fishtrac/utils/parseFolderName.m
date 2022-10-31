function folderName = parseFolderName(scoreSet)

folderName = cell(1, length(scoreSet));
fid = fopen('thresh.txt','w');
for i = 1:length(scoreSet)
    folderName{i} = sprintf('%.1f',scoreSet(i));
    fprintf(fid,'%s\n',folderName{i}); 
end
fclose(fid);