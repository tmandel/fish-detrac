function metricsKITTI=evalKITTI(resfile)
    % evaluate KITTI Training Set
    % requires a file with a allInfo 520x1 struct
    % FIX ALL THIS
    
    
    thiswd=pwd;
    load(resfile);
    
    pathToKittiDevkit='/home/amilan/storage/databases/KITTI/tracking/devkit_tracking/python';
    
    
    allscen=800:820;
    for scenario=allscen
        stateInfo=allInfo(scenario,6).stateInfo;
        cd(thiswd)
        tracklets=convertToKITTI(stateInfo,'Pedestrian');
        cd(pathToKittiDevkit)

        writeLabels(tracklets,'results/a/data',scenario-700);
    end
    
    
    !python evaluate_tracking.py a
    metricsKITTI=dlmread('results/a/stats_pedestrian.txt');
    
    cd(thiswd);
end