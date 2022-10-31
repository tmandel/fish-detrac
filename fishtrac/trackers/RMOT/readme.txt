IMPORTANT:

1. If you use this code, please cite the following publication.

[1] Bayesian Multi-Object Tracking Using Motion Context from Multiple Objects,
Ju Hong Yoon, Ming-Hsuan Yang, Jongwoo Lim and Kuk-Jin Yoon, 
IEEE Winter Conference on Applications of Computer Vision (WACV), HI, 2015.

project page: https://cvl.gist.ac.kr/project/rmot.html

2. Questions regarding the code may be directed to Ju Hong Yoon or Kuk-Jin Yoon (jh.yoon82@gmail.com, kjyoon@gist.ac.kr).

3. The code was tested on MATLAB 2014a (Windows 7).



INSTALLING & RUNNING (MATLAB 32/64bit)

1. Unpack rmot-v1.0.zip

2. Carefully check the detection format
   
    - You can use the code 'detection_xml_2_mat.m' (in 'detection generation folder') to convert detections from a txt file to a mat file.
    - You need xml_toolbox to convert a xml to a mat data. (Tool Box: XML Toolbox for Matlab V.3.1.2)
    - observation{f}.bbox: 'f' is frame index
    - detection format is [left upper X, left upper Y, width, height]
    - a set of detections are represented by N by M matrix where N is # of detections and M is the detection dimension (It is 4).

3. Run demo_rmot.m

4. The tracking results will be given in the folder: ./Results/

5. Result format

* mat file
       
        stateInfo.tiToInd(frame,i) =  idx; % frame: frame index, i: track index
        stateInfo.stateVec = [stateInfo.stateVec;State(1)];
        stateInfo.X(frame,i) = State(1);   
        stateInfo.Y(frame,i) = State(2);
        stateInfo.Xgp(frame,i) =  State(1); % X position
        stateInfo.Ygp(frame,i) =  State(2); % Y position
        stateInfo.Xi(frame,i) =  State(1);
        stateInfo.Yi(frame,i) =  State(2);
        stateInfo.H(frame,i) =  State(4); % Width
        stateInfo.W(frame,i) =  State(3); % Height


* txt file


 for each frame
	- [Frame, ID ,Type , Trunc, Occ, Alpha, X1, Y1, X2, Y2, H, W, L, t1, t2, t3, Ry, Score]
	- Frame, ID, X1, Y1, X2, Y2, are important for evaluation.
	- X1: left upper X
	- Y1: left upper Y
	- X2: right bottom X
	- Y2L right bottom Y 







