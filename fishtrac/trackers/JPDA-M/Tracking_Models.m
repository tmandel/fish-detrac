%% Tracking Models for Bayesian Filtering (Kalman\IMM filtering) 

model.T=1;% Temporal sampling rate
T=model.T;

%Dynamic model
% Model 1
F11=[1 T;0 1];
model.F(:,:,1)=blkdiag(F11,F11); % The transition matrix for the dynamic model 1
Q11x=q1*[T^3/3 T^2/2;T^2/2 T];
Q11y=q1*[T^3/3 T^2/2;T^2/2 T];
model.Q(:,:,1)=blkdiag(Q11x,Q11y); % The process covariance matrix for the dynamic model 1

% if you have more than one linear motion model, add same as Model 1 as 
% model.F(:,:,N) and model.Q(:,:,N).  

% Measurement model
model.H=[1 0 0 0;0 0 1 0]; % Measurement matrix
model.R=qm*eye(2); % Measurement covariance matrix


% IMM model (Constant or Sate-Dependent), Ignore this section and leave the
% parameters as it is
model.mui0=1; % The initial values for the IMM probability weights
model.TPM_Option='Constant'; % TPM_Option='State-Dependent';
model.TPM=1; % Markov Transition probability matrix in the case of constant;
% TPM{2,2}=1;TPM{2,1}=2*eye(2,2);TPM{1,2}=1;TPM{1,1}=0.5*eye(2,2);
model.H_TPM=[]; % model.H_TPM=[0 1 0 0;0 0 0 1];