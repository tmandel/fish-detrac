Robust Online Multi-Object Tracking based on Tracklet Confidence and Online Discriminative Appearance Learning
Copyright (C) 2014 Seung-Hwan Bae



IMPORTANT:

1. If you use this code, please cite the following publication.

[1] Robust Online Multi-Object Tracking based on Tracklet Confidence and Online Discriminative Appearance Learning,
Seung-Hwan Bae and Kuk-Jin Yoon, IEEE Conference on Computer Vision and Pattern Recognition (CVPR), Columbus, June, 2014.

2. For simplifying the implementation and reducing computational complexity, 
this code has been slightly modified from the one that was used to produce results of our CVPR 2014 paper. 
Therefore, the results produced by this software can be different from those provided in our paper.

3. Questions regarding the code may be directed to Seung-Hwan Bae (bshwan@gist.ac.kr; caegar07@gmail.com).

4. The code was tested on MATLAB 2012a (Windows 7).



INSTALLING & RUNNING (MATLAB 64bit)

1. Unpack cmot-v1.0.zip

2. Download the ETHMS-Bahnhof sequence (captured from the left camera, seq03-img-left.tar) from http://www.vision.ee.ethz.ch/~aess/dataset/
and put the sequence into ./Sequences/ETH_Bahnhof/

3. Download Incremental LDA code package (ILDA07.zip) from http://www.iis.ee.ic.ac.uk/icvl/code.htm and place it into ./ILDA/ 
Note that you should use the fGetDiscriminativeComponents_v2 and fGetSbModel_v2 instead of fGetDiscriminativeComponents and fGetSbModel in the ILDA package.
(This procedure can be omitted if you do not want to use online appearance learning. To this end, set param.use_ILDA = 0.) 

4. Run tracking_demo.m

5. The tracking results will be given in the folder: ./Results/




CHANGES

v1.1 Fixed MOT_Local_Association, mot_motion_similarity and km_estimation.
v1.2 Fixed MOT_Global_Association and fGetSbModel_v2.
v1.3 Fixed MOT_State_Update, fGetSbModel_v2, fGetDiscriminativeComponents_v2 and mot_appearance_model_generation.











