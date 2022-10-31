%% COMMON PARAMETERS
param.similarity_method = method;
param.min_s = 1e-2;     % minimum similarity for tracklets
param.mota_th = 0.5;    % we want the detections to stay in width/2.
param.debug = false;

%% DATASET

seqPath = [datasetPath '/' seqName '/img'];
itlName = [datasetPath '/' seqName '/' seqName '.itl'];
savePath = [datasetPath '/' seqName '/' method ];
if ~exist(savePath,'dir') && saveOutput
    mkdir(savePath)
end

% SMOT dataset
if ~isempty(strfind(['dribbling,slalom,juggling,crowd,acrobats,firebirds,seagulls,balls,tud-crossing,tud-campus'],seqName))
    % get the information about the sequence
    itl0 = loaditl(itlName);
end

% PSU dataset
if ~isempty(strfind(['psu-sparse,psu-dense'],seqName))
    switch(seqName(5:end))
        case 'sparse', segi = 1;
        case 'dense',  segi = 3;
    end    
    [X,Y,targetIDs] = read_traj_block(segi,keyId,0,10,datasetPath);    
    itl0 = psu2itl(X,Y,targetIDs);    
end

% convert itls to idl
idl0 = itl2idl(itl0);


%% PARAMETERS

switch seqName
%%%% SMOT dataset (Labelled with pdollars tool)

    case 'dribbling',
        param.hor = 40; param.eta_max = 3;
    case 'slalom',
        param.hor = 80; param.eta_max = 3;
    case 'juggling',
        param.hor = 40; param.eta_max = 3;
    case 'crowd',
        param.hor = 60; param.eta_max = 3/2;
    case 'acrobats'
        param.hor = 40; param.eta_max = 3/2;
    case 'firebirds'
        param.hor = 40; param.eta_max = 3;
    case 'seagulls'
        param.hor = 40; param.eta_max = 3;
    case 'balls'
        param.hor = 40; param.eta_max = 3/2;
    case 'tud-crossing'
        param.hor = 60; param.eta_max = 3/8;
    case 'tud-campus'
        param.hor = 60; param.eta_max = 3/4;
%%%% SMOT dataset (Labelled with pdollars tool)        


%%%% PSU HUB dataset
    case 'psu-sparse',
        param.hor = 60; param.eta_max = 3/2; param.conflict_ratio = 3/2; param.mu = 25; 
    case 'psu-dense',
        param.hor = 60; param.eta_max = 3/2; param.conflict_ratio = 3/2; param.mu = 25;
%%%% PSU HUB dataset
    otherwise
        error('Unknown sequence!');
end

if isequal(method,'ksp') 
    
    error('KSP method is not supported in shared version. Sorry!');
    % executable for ksp
    kspRun = '/home/caglayan/research/code/c/work/epfl_ksp/ksp1_1/ksp';
    param.ksp_run = kspRun;
    
    % get the image width height
    hseq = seqreader(seqPath);    
    param.img.width  = hseq.Width;
    param.img.height = hseq.Height;
    clear hseq;
    
    % temporary ksp setup file folder
    kspConfPath  = [ datasetPath '/' seqName '/ksp_conf' ];
    if ~exist(kspConfPath,'dir') && saveOutput
        mkdir(kspConfPath);
    end
    INPUT_FORMAT = [ kspConfPath '/prob_f%05d.dat'];
    param.input_format = INPUT_FORMAT;
    param.ksp_conf_path = kspConfPath;
    
    % parameters to play    
    N_GRID_X = 64;   % Grid size
    N_GRID_Y = 64;    
    param.grid.nx = N_GRID_X;
    param.grid.ny = N_GRID_Y;
    
    DEPTH = 3;
    param.depth = DEPTH;
    
end