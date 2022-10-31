
###################################################################
#                                                                 #
#    JPDA_m Tracker - code for multi-target tracking              #
#                using detected points only                       #
#                         Version 1.0                             #
#                                                                 #
#              The Code is also available at                      #
#   http://research.milanton.net/files/iccv2015/jpda_m.zip        #
#                                                                 #
#                     Seyed Hamid Rezatofighi                     #
#                (hamid.rezatofighi@adelaide.edu.au)              #
#                             2015                                #
#                                                                 #
###################################################################

============
Introduction
============

This code package provides a tool for tracking multiple targets using 
JPDA_m Tracker. If you use this code for research purposes, please cite 
the following paper in any resulting publication:

S. H. Rezatofighi, A. Milan, Z. Zhang, Q. Shi, A. Dick, I. Reid, "Joint 
Probabilistic Data Association Revisited", IEEE International Conference 
on Computer Vision (ICCV), 2015.

The tracker Requires:
1- The Coordinates for the detected points
2- Linear dynamic model(s), e.g. constant velocity with small acceleration  
3- An ILP solver (Gurobi is used by default)


The code is tested on Windows Seven (64bit), MATLAB (2014a) using the Gurobi ILP solver (version
5.6.3, 64bit). You can use any other ILP solver, e.g. cplex by modfying the file "gurobi_ilp.m"

The code is an extension of IMM-JPDA tracker proposed in:

S. H. Rezatofighi, S. Gould, R. Hartley, K. Mele, W. E. Hughes,“Application of 
the IMM-JPDA Filter to Multiple Target Tracking in Total Internal Reflection 
Fluorescence Microscopy Images,” The International Conference on Medical Image 
Computing and Computer Assisted Intervention (MICCAI), pp. 357–364, 2012.

Therefore, it can be used for multiple motion models as well.
#################################################################################################

============
Instructions
============

The code package contains the following files and folders:

1 - The main file is "Main_PETS.m" including a Demo for tracking pedestrains in PETS sequences. 
    you can change the sequence and camera names to try on different videos in this dataset

2-  "AddPath.m" is for adding sub-directories into the path of Matlab, e.g. Gurobi.

3- "PETS_Image_Detection_Path.m" is to extract the path to PETS sequences and their detections.
   Change this to apply the tracker for any artibitrary dataset

4- "Tracking_Models.m" generates  Kalman (or IMM) dynamic and measurement and JPDA models using 
    the given parameters.

5- "Initialization.m" initializes the state of the targets in the first frame. 

6- The folder named "JPDA files" contains all functions required to apply filtering and 
    calculate JPDA probabilites. 

7-  The rest of the folders used for either post-processing (e.g. bounding box estimation), 
    visualization or performance evaluation. Their scripts are taken from:


    A. Milan, K. Schindler, and S. Roth, "Detection and trajectory-level exclusion in multiple 
    object tracking," IEEE Conference on Computer Vision and Pattern Recognition (CVPR) 2013. 

8- The images for the PETS-S2L2 sequences are included. For all other sequences, only the
    first 10 frames are kept.
    
9- If you confront the following error after running the code (or even if the code is 
  working for few frames), it means that your Gurobi is not properly linked to your MATLAB. 
  Check your Gurobi addpath.

  "Subscripted assignment dimension mismatch.
  Error in BinIntMBest (line 19)
      x(:,m) = cx;
  ..."
    

If you have any question, please send an email to hamid.rezatofighi@adelaide.edu.au

#################################################################################################

========
Versions
========

1.1	03/02/2016
	Added bounding box estimation


1.0	19/11/2015 
	Initial Release


#################################################################################################

=====================
License & disclaimer
=====================

    Copyright (c) 2015, Seyed Hamid Rezatofighi(hamid.rezatofighi@adelaide.edu.au).

    This software can be used for research purposes only.

    THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
    "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
    LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
    A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
    OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
    SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
    LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
    DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
    THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
    (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
    OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.






