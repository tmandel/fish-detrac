function col=getColorFromID(id, numObjs)
% get rgb [0,1] values from id
global options
    if(~isfield(options,'colors'))
        options.colors = rand(max(1,numObjs-13), 3);
        colors=[
                128 255 255;    % 
                255 0 0;        % red           1
                0 255 0;        % green         2
                0 0 255;        % blue          3
                0 255 255;      % cyan          4
                255 0 255;      % magenta       5
                212 212 0;      % yellow        6
                25 25 25;       % black         7
                34,139,34;      % forestgreen   8
                0,191,255;      % deepskyblue   9
                139,0,0 ;       % darkred       10
                218,112,214;    % orchid        11
                244,164,96 ;]/255;  % sandybrown    12
        colors = colors / 255;
        options.colors = cat(1,colors,options.colors);
    end
    col = options.colors(id,:);
end