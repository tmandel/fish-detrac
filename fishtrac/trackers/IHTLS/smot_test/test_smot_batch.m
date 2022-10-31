% This is the batch testing script for smot code.
clear,clc,close all;
% add path
addpath(genpath('../'));

% set random generator
rng(1233245);
saveOutput = false;
% Datasets to be tested
dataSets = {'slalom'};%,'juggling','crowd','acrobats','seagulls',...
%     'balls','tud-crossing','tud-campus'};
datasetPath = '../smot_data';

% Method to be tested
% NOTE: IP method requires CVX to run, and a lot of patience! 
methods = {'ihtls','admm','ip'};
method  = methods{1};

% Noise type to be tested
noiseType = {'fn','fp'};
noise_tag = noiseType{1};

% Noise levels
fn = [0:0];     % I put this here for demo purposes. To obtain results with 
                % noise uncomment the next line.
% fn = [0.0:0.06:0.3];
fp = [0.0:0.1:0.5];
N = length(fn);

% Number of trials per noise level.
TRIALS = 1;

%%
% noise base
noisebase.fn = 0.0;
noisebase.fp = 0.0;
noisebase.gn = 0;
% mota base
motbase.fn = 0;
motbase.fp = 0;
motbase.mme = 0;
motbase.g = 0;
motbase.mota = 0;
motbase.mmerat = 0;
for i = 1:size(dataSets,2)    
    seqName = dataSets{i};    
    % the following script will load a lot of variables. See the file for
    % more details. 
    initialize_smot();
    for n=1:N      
        for t = 1:TRIALS
            fprintf('Processing Dataset:%s  Method:%s  Noise:%0.2f|%0.2f  Trial:%d\n', seqName,method,fp(n),fn(n),t);
            fprintf('---------------------------------------\n');
            if  n==1 && t>1
                % noiseless case is same for all trials. copy.
                itlf{t,n} = itlf{1,n};
                etime(t,n) = etime(1,n);
                mot(t,n) = mot(1,n);
            else                
                noise(n).fp = fp(n);
                noise(n).fn = fn(n);
                noise(n).gn = 0;              
                [idlp, fp_idl{t,n}, fn_idl{t,n}] = idladdnoise(idl0,noise(n));
                % do the stitching
                [itlf{t,n}, etime(t,n)] = smot_associate(idlp,param);
                fprintf('Process time: %g \n\n',etime(t,n));
                % compute mota
                fprintf('Computing MOT metrics \n');
                mot(t,n) = smot_clear_mot_fp(itl0,itlf{t,n},fp_idl{t,n},param.mota_th);
                fprintf('\n');
            end
            % save output for noiseless case
            if (n==1) && (t==1)
                showitl(itlf{t,n},seqPath,'tail',5);
                % the below line is useful if you want to save the output
%                 showitl(itlf{t,n},seqPath,'tail',5,'saveoutput',savePath);
            end
        end      
    end
    % save variables     
    if(saveOutput)
        saveResultName = sprintf('%s/%s_%s_%s.mat',savePath,seqName,method,noise_tag);    
        save(saveResultName,'param','seqName','method','noise','mot','itlf','etime','fp_idl','fn_idl');
    end
end