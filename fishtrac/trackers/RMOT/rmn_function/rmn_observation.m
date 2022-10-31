function [RMN] = rmn_observation(Track, RMN)

% initialization
for i=1:length(Track)
    lab1 = Track{i}.lab;
    for j=1:length(Track)
        lab2 = Track{j}.lab;
        RMN(lab1,lab2).MeasSet = [];
    end
end
for i=1:length(Track)
    lab1 = Track{i}.lab;
    det1 = Track{i}.detection;
    if(~isempty(det1))
%         det1 = det1(1:2) + det1(3:4)/2;
        for j=1:length(Track)
            lab2 = Track{j}.lab;
            if(lab1~=lab2)
                det2 = Track{j}.detection;
                if(~isempty(det2)) % 1st case
%                     det2 = det2(1:2) + det2(3:4)/2;
                    MeasSet = det1(1:2) - det2(1:2);
                    for k=1:length(Track)
                        lab3 = Track{k}.lab;
                        if(lab2~=lab3)
                            est3 = Track{k}.X;
                            det3 = Track{k}.detection;
                            if( ~isempty(det3)) % 1st case
%                                 det3 = det3(1:2) + det3(3:4)/2;
                                Meas_Ele = det1(1:2) - (det2(1:2) - det3(1:2) + est3(1:2));
                                MeasSet = [MeasSet, Meas_Ele];
                            end
                        end
                    end
                    RMN(lab1,lab2).MeasSet = MeasSet;
                end
            end
        end
    end
end