function [Detect, Detection_App, NofDet, det_bbox] = detection_conversion(observation, f, opt, framergb)

 

%% Input conversion
det_bbox = observation{f}.bbox;
% det_bbox = [left upper X, left upper Y, Width, Height];
% det_bbox: N (# of detections) by M (detection dimension)
det_hist = {};
for i=1:size(det_bbox,1)
    d_bbox_rgb = img_crop(det_bbox(i,:),framergb, 128, 64);
    d_bbox_hsv = double(rgb2hsv(d_bbox_rgb));
    h_crop = d_bbox_hsv(:,:,1);  s_crop = d_bbox_hsv(:,:,2); v_crop = d_bbox_hsv(:,:,3);
    
    d_h_feat = hist(h_crop(:),64)/(128*64);
    d_s_feat = hist(s_crop(:),64)/(128*64);
    d_v_feat = hist(v_crop(:),64)/(128*64);
    d_all_feat = [d_h_feat(:); d_s_feat(:); d_v_feat(:)]/3;
    det_hist{i} = d_all_feat(:);
end


%% Detection Conversion
Detect=[]; Idx = 0;
Detection_App = {}; % Input Detection Appearance (HSV histogram)
NofDet = size(det_bbox,1);
for i=1:NofDet
    if(det_bbox(i,1)>-1*opt.img_margin_u && det_bbox(i,2)>-opt.img_margin_u && fix(det_bbox(i,1) + det_bbox(i,3))<opt.imgsz(2)+opt.img_margin_u && fix(det_bbox(i,2) + det_bbox(i,4))<opt.imgsz(1)+opt.img_margin_u)
        Size_H = det_bbox(i,4)*opt.d_ratio(2);
        if(Size_H >= opt.s_size(1) && Size_H <= opt.s_size(3))
            Idx = Idx + 1;
            Detect = [Detect; det_bbox(i,:)]; % Detection Input
            Detection_App{Idx} = det_hist{i};
        end
    end
end
NofDet = Idx; % Number of detections