function stateInfo = saveEmptyStateInfo(numberOfFrames)
  
  

% save empty tracking results
stateInfo.F = [numberOfFrames];
stateInfo.frameNums = ones(1, numberOfFrames);
for i = 1:numberOfFrames
  stateInfo.frameNums(1,i) = i;
endfor
stateInfo.X = zeros(numberOfFrames, 0);
stateInfo.Y = zeros(numberOfFrames, 0);
stateInfo.Xi = zeros(numberOfFrames, 0);
stateInfo.Yi = zeros(numberOfFrames, 0);
stateInfo.W = zeros(numberOfFrames, 0);
stateInfo.H = zeros(numberOfFrames, 0);
  
endfunction