function [gt, occlusion, ignored_region] = struct2gt(data)
%% transfer struct to txt file
camera_state = data.sequence.sequence_attribute.Attributes.camera_state;
switch camera_state
    case 'stable'
        camera_state = 0;
    case 'unstable'
        camera_state = 1;
end
sence_weather = data.sequence.sequence_attribute.Attributes.sence_weather;
switch sence_weather
    case 'cloudy'
        sence_weather = 1;      
    case 'rainy'
        sence_weather = 2;
    case 'sunny'
        sence_weather = 3;
    case 'night'
        sence_weather = 4;
end
ignored_region = [];
gt = [];
occlusion = [];
%% check if has the ignorance region
if isfield(data.sequence.ignored_region,'box')
    % region
    % if region has more then one box
    if length(data.sequence.ignored_region.box)>1
        for i=1:length(data.sequence.ignored_region.box)
            ignored_region = cat(1, ignored_region, [str2double(data.sequence.ignored_region.box{1, i}.Attributes.left)...
                str2double(data.sequence.ignored_region.box{1, i}.Attributes.top)...
                str2double(data.sequence.ignored_region.box{1, i}.Attributes.width)...
                str2double(data.sequence.ignored_region.box{1, i}.Attributes.height)]);
        end
    else
        %if region has only one box
        ignored_region = cat(1, ignored_region, [str2double(data.sequence.ignored_region.box.Attributes.left)...
            str2double(data.sequence.ignored_region.box.Attributes.top)...
            str2double(data.sequence.ignored_region.box.Attributes.width)...
            str2double(data.sequence.ignored_region.box.Attributes.height)]);
    end
end
%% frame
for j=1:length(data.sequence.frame)
    num = str2double(data.sequence.frame{1, j}.Attributes.num);
    for jj = 1:length(data.sequence.frame{1, j}.target_list.target)
        if length(data.sequence.frame{1, j}.target_list.target)>1
            
            id = str2double(data.sequence.frame{1, j}.target_list.target{1, jj}.Attributes.id);
            orientation = str2double(data.sequence.frame{1, j}.target_list.target{1, jj}.attribute.Attributes.orientation);
            speed = str2double(data.sequence.frame{1, j}.target_list.target{1, jj}.attribute.Attributes.speed);
            trajectory = str2double(data.sequence.frame{1, j}.target_list.target{1, jj}.attribute.Attributes.trajectory_length);
            truncation_ratio = str2double(data.sequence.frame{1, j}.target_list.target{1, jj}.attribute.Attributes.truncation_ratio);
            vehicle_type = data.sequence.frame{1, j}.target_list.target{1, jj}.attribute.Attributes.vehicle_type;
            density=str2double(data.sequence.frame{1, j}.Attributes.density);
            switch(vehicle_type)
                case 'car'
                    vehicle_type = 1;
                case 'bus'
                    vehicle_type = 2;
                case 'truck'
                    vehicle_type = 3;
                case 'van'
                    vehicle_type = 4;
                case 'others'
                    vehicle_type = 5;
            end
            bheight = str2double(data.sequence.frame{1, j}.target_list.target{1, jj}.box.Attributes.height);
            bwidth = str2double(data.sequence.frame{1, j}.target_list.target{1, jj}.box.Attributes.width);
            bleft = str2double(data.sequence.frame{1, j}.target_list.target{1, jj}.box.Attributes.left);
            btop = str2double(data.sequence.frame{1, j}.target_list.target{1, jj}.box.Attributes.top);
            try
                Occ = data.sequence.frame{1, j}.target_list.target{1, jj}.occlusion;
                if(length(Occ.region_overlap)<2)
                    occlusion = cat(1, occlusion, [num id bleft btop bwidth bheight str2double( Occ.region_overlap.Attributes.occlusion_id) ...
                        str2double(Occ.region_overlap.Attributes.occlusion_status) str2double(Occ.region_overlap.Attributes.left),str2double( Occ.region_overlap.Attributes.top) ...
                        str2double(Occ.region_overlap.Attributes.width), str2double( Occ.region_overlap.Attributes.height)]);
                else
                    for k =1:length(Occ.region_overlap)
                        occlusion = cat(1, occlusion, [num id bleft btop bwidth bheight , str2double( Occ.region_overlap{k}.Attributes.occlusion_id) ...
                            str2double(Occ.region_overlap{k}.Attributes.occlusion_status) str2double(Occ.region_overlap{k}.Attributes.left),str2double( Occ.region_overlap{k}.Attributes.top) ...
                            str2double(Occ.region_overlap{k}.Attributes.width), str2double( Occ.region_overlap{k}.Attributes.height)]);
                    end
                end
            catch

            end
            gt = cat(1, gt, [bleft btop bwidth bheight  num id  sence_weather camera_state density trajectory...
                            orientation speed vehicle_type truncation_ratio]);
        else
            
            id = str2double(data.sequence.frame{1, j}.target_list.target.Attributes.id);
            
            orientation = str2double(data.sequence.frame{1, j}.target_list.target.attribute.Attributes.orientation);
            speed = str2double(data.sequence.frame{1, j}.target_list.target.attribute.Attributes.speed);
            trajectory = str2double(data.sequence.frame{1, j}.target_list.target.attribute.Attributes.trajectory_length);
            truncation_ratio = str2double(data.sequence.frame{1, j}.target_list.target.attribute.Attributes.truncation_ratio);
            vehicle_type = data.sequence.frame{1, j}.target_list.target.attribute.Attributes.vehicle_type;
            density=str2double(data.sequence.frame{1, j}.Attributes.density);
            switch(vehicle_type)
                case 'car'
                    vehicle_type = 1;
                case 'bus'
                    vehicle_type = 2;
                case 'truck'
                    vehicle_type = 3;
                case 'van'
                    vehicle_type = 4;
                case 'others'
                    vehicle_type = 5;
            end
            bheight = str2double(data.sequence.frame{1, j}.target_list.target.box.Attributes.height);
            bwidth = str2double(data.sequence.frame{1, j}.target_list.target.box.Attributes.width);
            bleft = str2double(data.sequence.frame{1, j}.target_list.target.box.Attributes.left);
            btop = str2double(data.sequence.frame{1, j}.target_list.target.box.Attributes.top);
            try
                Occ = data.sequence.frame{1, j}.target_list.target.occlusion;
                if(length(Occ.region_overlap)<2)
                    occlusion = cat(1, occlusion, [num id bleft btop bwidth bheight , str2double( Occ.region_overlap.Attributes.occlusion_id) ...
                        str2double(Occ.region_overlap.Attributes.occlusion_status) str2double(Occ.region_overlap.Attributes.left),str2double( Occ.region_overlap.Attributes.top) ...
                        str2double(Occ.region_overlap.Attributes.width), str2double( Occ.region_overlap.Attributes.height)]);
                else
                    for k =1:length(Occ.region_overlap)
                        occlusion = cat(1, occlusion, [num id bleft btop bwidth bheight str2double( Occ.region_overlap{k}.Attributes.occlusion_id) ...
                            str2double(Occ.region_overlap{k}.Attributes.occlusion_status) str2double(Occ.region_overlap{k}.Attributes.left),str2double( Occ.region_overlap{k}.Attributes.top) ...
                            str2double(Occ.region_overlap{k}.Attributes.width), str2double( Occ.region_overlap{k}.Attributes.height)]);
                    end
                end
            catch

            end
            
            gt = cat(1, gt, [bleft btop bwidth bheight num id sence_weather camera_state density trajectory...
                            orientation speed vehicle_type truncation_ratio]);
        end
    end
end