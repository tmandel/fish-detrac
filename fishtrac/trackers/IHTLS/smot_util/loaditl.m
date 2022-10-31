function itl = loaditl(fileName)
fid = fopen(fileName,'r');
N = fscanf(fid,'%d',1);

for n=1:N
    itl(n).id = fscanf(fid,'%d',1);
    itl(n).t_start = fscanf(fid,'%d',1);
    itl(n).t_end = fscanf(fid,'%d',1);
    itl(n).length = itl(n).t_end - itl(n).t_start +1;
    
    rect = fscanf(fid,'%f',[itl(n).length 4])';
%     rect = reshape(rect,[4 itl(n).length]);
    omega = fscanf(fid,'%d',itl(n).length);
    itl(n).rect = rect;
    itl(n).xy = rect(1:2,:) + rect(3:4,:)/2;
    itl(n).omega = omega';

end


fclose(fid);

