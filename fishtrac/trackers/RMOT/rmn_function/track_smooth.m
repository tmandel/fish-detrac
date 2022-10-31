function [Track] = track_smooth(Track)

for i=1:length(Track)
    re_detected = Track{i}.re_detected;
    if(re_detected == 1)
        SizeN = size(Track{i}.states,2);
        State_p = Track{i}.states(:,SizeN-1);
        State_c = Track{i}.states(:,end);
        frame_p = Track{i}.frame(SizeN-1);
        frame_c = Track{i}.frame(SizeN);
        
        translation_link = (State_c - State_p)/(frame_c -  frame_p);
        frame_w = (1:(frame_c -  frame_p));
        State_link = repmat(State_p,1,frame_c -  frame_p) + repmat(frame_w,6,1).*repmat(translation_link,1,frame_c -  frame_p);
        frame_link = repmat(frame_p,1,frame_c -  frame_p) + frame_w;
        
        Track{i}.states = [Track{i}.states(:,1:SizeN-1),State_link];
        Track{i}.frame = [Track{i}.frame(:,1:SizeN-1),frame_link];
    end
end