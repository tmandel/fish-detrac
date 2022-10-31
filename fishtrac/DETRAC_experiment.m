% This script can be used to execute the tracking experiments or evaluate the detection results on the UA-DETRAC benchmark
% Copyright (C)2016 The UA-DETRAC Group 

% This program is free software: you can redistribute it and/or modify it under the terms of the GNU General Public License as published by
% the Free Software Foundation, either version 3 of the License, or (at your option) any later version.

% This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of
% MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for more details.

% You should have received a copy of the GNU General Public License along with this program. If not, see <http://www.gnu.org/licenses/>.

clear, clc, close all;
warning off all;
global options sequences tracker
pkg load image;

%% add the path of functionMEs
addpath(genpath('utils'));
addpath(genpath('evaluation'));
addpath(genpath('display'));

arg_list = argv();
disp(arg_list)


trackerSet = {arg_list{1}};
thresh = str2double(arg_list{2});
seq = arg_list{3};
disp('DETRAC_experiment.m called')
disp(thresh)
%'KPD', 'KCF','CMOT','KIOU', 'MEDFLOW','VIOU', 'GOG' 
%options: {'CEM','CMOT','KPD','KIOU', 'MEDFLOW', 'KCF', 'VIOU',  'DCT','FH2T','GOG','H2T','IHTLS','RMOT'};

%% input the name of the tracker
for idTracker = 1:length(trackerSet)
  tracker.trackerName = trackerSet{idTracker};%'GOG'; % ignore this line when evaluating detection results
  %% initialize the parameters for evalution
  options = initialize_environment();
  options.detectionThreshold = [thresh]
  options.seqPath = [arg_list{1} "." arg_list{2} "." arg_list{3}  ".sequences.txt"];
  fid = fopen (options.seqPath, "w");
  fputs (fid, seq);
  fclose (fid);
  %% load the dataset
  sequences = load_datasets();
  %% evaluate the tracker
  run_experiment();
  %Delete temp sequence file
  delete(options.seqPath);
end


