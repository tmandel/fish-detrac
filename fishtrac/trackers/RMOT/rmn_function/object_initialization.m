function [Track, NewT, param] = object_initialization(InitObj, InitObj_Hist, Track, NewT, param)


% Object Initialization
% Initialization of Track
if(isempty(Track) && ~isempty(InitObj))
    idx = 0;
    for i = 1:size(InitObj,2)
        idx = idx + 1;
        param.MAX_LAB = param.MAX_LAB + 1;
        
        NewT = [NewT idx];
        % state
        SSS = InitObj{i}(1:4,:); % States (Left upper X, Left upper Y, Width, Height)
        % left upper and right bottom
        S = SSS(1:2,:) + SSS(3:4,:)/2;
        [Trans] = compute_translation(S);
        Track{idx}.states = [SSS(1:2,:)+SSS(3:4,:)/2; SSS(3:4,:); repmat(Trans,1,size(S,2))]; % (Cen X, Cen Y, Width, Height)
        %             Track{idx}.states_result = Track{idx}.states;
        State = [S(1:2,end);Trans;SSS(3:4,end)]; % State (X,Y,tX,tY,W,H)
        Track{idx}.X = State; % State (X,Y,tX,tY,W,H)
        Track{idx}.Xp = State; % Predicted State (X,Y,tX,tY,W,H)
        Track{idx}.P = param.P; % Covariance (X,Y,tX,tY,W,H)
        Track{idx}.Pp = param.P; % Predicted Covariance (X,Y,tX,tY,W,H)
        % frame information
        Track{idx}.frame = InitObj{i}(5,:); % history of frame
        Track{idx}.sframe = InitObj{i}(5,1); % starting frame
        
        % Appearance (HSV)
        Track{idx}.HSV = InitObj_Hist{i};
        Track{idx}.Appearance = InitObj_Hist{i}(:,1);
        % RMN
        % track link information GRAPH
        Track{idx}.graph = [];
        Track{idx}.link = [];
        
        % Graph weight
        Track{idx}.graph_weight = [];
        
        % state from other nodes
        Track{idx}.graph_x = State; % node state
        
        % an associated detection
        Track{idx}.detection = [State(1),State(2),State(5),State(6)]';
        
        % a probability associated with detection
        Track{idx}.asso_spatial = [];
        Track{idx}.asso_hist = [];
        
        % Track survival
        Track{idx}.survival = 1;
        
        % label
        Track{idx}.lab = param.MAX_LAB;
        
        %Track unreliable
        Track{idx}.unreliable = 0;
        
        % Track confidence in 3 levels
        Track{idx}.confidence = 2;
        
        Track{idx}.not_detected = 0;
        
        Track{idx}.re_detected = 0;
    end
elseif(~isempty(Track) && ~isempty(InitObj))
    for i = 1:size(InitObj,2)
        idx = length(Track) + 1;
        NewT = [NewT idx];
        param.MAX_LAB = param.MAX_LAB + 1;
        
        % state
        SSS = InitObj{i}(1:4,:); % States (Left upper X, Left upper Y, Width, Height)
        % left upper and right bottom
        S = SSS(1:2,:) + SSS(3:4,:)/2;
        [Trans] = compute_translation(S);
        Track{idx}.states = [SSS(1:2,:)+SSS(3:4,:)/2; SSS(3:4,:); repmat(Trans,1,size(S,2))]; % (Cen X, Cen Y, Width, Height)
        %             Track{idx}.states_result = Track{idx}.states;
        State = [S(1:2,end);Trans;SSS(3:4,end)]; % State (X,Y,tX,tY,W,H)
        Track{idx}.X = State; % State (X,Y,tX,tY,W,H)
        Track{idx}.Xp = State; % Predicted State (X,Y,tX,tY,W,H)
        Track{idx}.P = param.P; % Covariance (X,Y,tX,tY,W,H)
        Track{idx}.Pp = param.P; % Predicted Covariance (X,Y,tX,tY,W,H)
        % frame information
        Track{idx}.frame = InitObj{i}(5,:); % history of frame
        Track{idx}.sframe = InitObj{i}(5,1); % starting frame
        
        % Appearance (HSV)
        Track{idx}.HSV = InitObj_Hist{i};
        Track{idx}.Appearance = InitObj_Hist{i}(:,1);
        
        % RMN
        % track link information GRAPH
        Track{idx}.graph = [];
        Track{idx}.link = [];
        
        % Graph weight
        Track{idx}.graph_weight = [];
        
        % state from other nodes
        Track{idx}.graph_x = State; % node state
        
        % an associated detection
        Track{idx}.detection = [State(1),State(2),State(5),State(6)]';
        
        % a probability associated with detection
        Track{idx}.asso_spatial = [];
        Track{idx}.asso_hist = [];
        
        % Track survival
        Track{idx}.survival = 1;
        
        % label
        Track{idx}.lab = param.MAX_LAB;
        
        %Track unreliable
        Track{idx}.unreliable = 0;
        
        % Track confidence in 3 levels
        Track{idx}.confidence = 2;
        
        Track{idx}.not_detected = 0;
        
        Track{idx}.re_detected = 0;
    end
end