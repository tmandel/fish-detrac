function sequence=getSequenceFromScenario(scenario)
% 
% (C) Anton Andriyenko, 2012
%
% The code may be used free of charge for non-commercial and
% educational purposes, the only requirement is that this text is
% preserved within the derivative work. For any other purpose you
% must contact the authors for permission. This code may not be
% redistributed without written permission from the authors.

switch (scenario)
    case 18
        sequence='campus4';
    case 19
       sequence= 'campus7';
    case 20
        sequence='terrace1';
    case 21
        sequence='terrace2';
    case 22
        sequence='PETS-S2L1';
    case 23
        sequence='PETS-S2L1';
    case 24
        sequence='PETSMONO_short';
    case 25
        sequence='PETS-S2L2';
    case 27
        sequence='PETS-S2L3';
    case 30
        sequence='ped1';
    case 31
        sequence='ped1-c1';
    case 32
        sequence='ped1-c2';
    case {35,36,37}
        sequence='TUD10-ped2';
    case 40
        sequence='TUD-Campus';
    case 41
        sequence='TUD-Crossing';
    case 42
        sequence='TUD-Stadtmitte';
    case {45,46,47}
        sequence=sprintf('pedxing-seq%i',scenario-44);
    case 60
        sequence='AVSS-AB_Easy';
    case 61
        sequence='AVSS-AB_Medium';
    case 62
        sequence='AVSS-AB_Hard';
    case 70
        sequence='PETS-S1L1-1';
    case 71
        sequence='PETS-S1L1-2';
    case 72
        sequence='PETS-S1L2-1';
    case 73
        sequence='PETS-S1L2-2';
    case 74
        sequence='PETS-S1L3-1';
    case 75
        sequence='PETS-S1L3-2';
    case 80
        sequence='PETS-S3-MF1';
    case 81
        sequence='PETS-S3-MF2';
    case 82
        sequence='PETS-S3-MF3';
    case 83
        sequence='PETS-S3-MF4';
    case 84
        sequence='PETS-S3-MF5';
    case 85
        sequence='PETS-S3-HL1';
    case 86
        sequence='PETS-S3-HL2';
    case 101
        sequence='EnterExitCrossingPaths1cor';
    case 131
        sequence='EnterExitCrossingPaths1front';
    case 160
        sequence='AA_Easy_01';
    case 161
        sequence='AA_Crossing_01';
        
end
end