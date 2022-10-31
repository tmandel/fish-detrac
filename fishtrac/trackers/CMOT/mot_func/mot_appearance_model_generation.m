function [tmpl_hist] = mot_appearance_model_generation(img, param, state)
% input :
% img: a color image
% state: [Center(X), Center(Y), Width, Height]
% output : 
% tmpl_hist: color histograms

%% Copyright (C) 2014 Seung-Hwan Bae
%% All rights reserved.

if strcmp(param.color.type,'HSV')
    hsv_img = rgb2hsv(img);
else
    hsv_img = img;
end
h_img = double(hsv_img(:,:,1))./double(max(max(img(:,:,1))));
s_img = double(hsv_img(:,:,2))./double(max(max(img(:,:,2))));
v_img = double(hsv_img(:,:,3))./double(max(max(img(:,:,3))));


initS = state;

h_tmpl = mot_generate_temp(h_img,initS,param.tmplsize); 
s_tmpl = mot_generate_temp(s_img,initS,param.tmplsize); 
v_tmpl = mot_generate_temp(v_img,initS,param.tmplsize); 

Nd = size(state,2);

h_tmpl = reshape(h_tmpl,param.subvec,param.subregion,Nd);
s_tmpl = reshape(s_tmpl,param.subvec,param.subregion,Nd);
v_tmpl = reshape(v_tmpl,param.subvec,param.subregion,Nd);

all_tmpl{1} =h_tmpl;
all_tmpl{2} =s_tmpl;
all_tmpl{3} = v_tmpl;

nbins = param.Bin;
tmpl_hist =[];
temp_hist = [];

for j=1:Nd
    temp_hist =[];
    for i=1:3
        max_val = max(max(all_tmpl{i}(:,:,j)));
        cb_tmpl = all_tmpl{i}(:,:,j);
        cb_tmpl = cb_tmpl./max_val*nbins;
        if param.subregion ==1
            cb_tmpl_hist = (hist(cb_tmpl,nbins)/param.subvec)';
        else
            cb_tmpl_hist = (hist(cb_tmpl,nbins)/param.subvec);
        end
        temp_hist = [temp_hist;cb_tmpl_hist];
    end
    tmpl_hist(:,:,j) =  temp_hist./3;
end

