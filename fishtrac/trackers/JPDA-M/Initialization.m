function X0=Initialization(Detection_address,param,model)
% By assuming all detections from the first frame belongs to real targets,
% this function calculates the initial position and velocity for all targets

% Output:
% X0: Initial position and velocity for x-y dimension, e.g.
% X0=(x_0 Vx_0 y_0 Vy_0)

% Input:
% Detection_address: The path to load the detections
% param: The method's parameters
% model: Tracking models

narginchk(3, 3)
load(Detection_address) % load the detections
DSE=2;% DSE = 1 means position only, = 2 means position and velocity,
% = 3 means position, velocity and acceralation and so on

XYZ=cell(1,DSE);

for k=1:DSE
    XYZ{1,k}=[detections(k).xi(detections(k).sc>param.Prun_Thre);...
        detections(k).yi(detections(k).sc>param.Prun_Thre)]';% detections
    % for the first and the second frames
end

T=model.T;
Vmax=param.Vmax; % maximum velocity the a target in the first frame can has
DMV=size(model.H,1);
X0=zeros(size(XYZ{1,1},1),size(model.F,1));
for i=1:DSE
    if ~isempty(XYZ{1,i})
        if i==1
            for j=1:DMV
                X0(:,(j-1)*DSE+i)=XYZ{1,i}(:,j);
            end
        else
            [~, indx]= min(pdist2(XYZ{1,i},XYZ{1,1}));
            XYZ2M=XYZ{1,i}(indx,:);
            for j=1:DMV
                XYZ2N=X0(:,(j-1)*DSE+1);
                for k=2:i-1
                    XYZ2N=XYZ2N+(X0(:,(j-1)*DSE+k)*T^(k-1))/factorial(k-1);
                end
                X0(:,(j-1)*DSE+i)=(DSE-1)*(XYZ2M(:,j)-XYZ2N)/T^(DSE-1);
                X0(:,(j-1)*DSE+i)=(abs(X0(:,(j-1)*DSE+i))<2^(i-2)*Vmax/T^(i-2)).*X0(:,(j-1)*DSE+i);
            end
        end
    else
        if i==1
            X0=[];
            warning('No detection exists in the first frame')
        end
        break
    end
end

end







