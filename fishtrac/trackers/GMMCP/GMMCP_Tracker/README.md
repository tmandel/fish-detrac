# GMMCP-Tracker: Globally Optimal Generalized Maximum Multi Clique Problem for Multiple Object Tracking

[![License](https://img.shields.io/badge/license-BSD-blue.svg)](LICENSE)

By [Afshin Dehghan](http://www.afshindehghan.com/)

### Introduction

This MATLAB code implements a faster simplified version of GMMCP tracker. This code create the mid-level tracklets, explained in the paper, in overlapping segments. To form the final tracks, we conncet the mid-level tracklets that overlap. This code will provide results lower than the one reported in the paper (mostly in the number of IDS, the otehr metrics should be very close). 
One could modify the code easily to do another level of association to reduce the number of IDS. You can use the code to run it on the given test sequences or the sequence of your choice. For more details, please refer to our [CVPR paper](http://crcv.ucf.edu/papers/cvpr2015/AfshinDehghan_GMMCP_CVPR15.pdf) and our [Presentation](https://www.youtube.com/watch?v=6zlnJUyILxk).

<p align="center">
<img src="http://crcv.ucf.edu/projects/GMMCP-Tracker/Bipartite_vs_GMMCP.png" alt="SSD Framework" width="600px">
</p>


The code is consist of four main section:
- Creating low-level tracklets using overlap threshold. This part is not optimized and it is the slowest. You may replace it with a faster method.
- Creating the affinity matrix for low-level tracklets.
- Solving GMMCP with ADNs to get the mid-level tracklets in overlaping segments. This part is fast as reported in the paper. 
- Stitching the tracklets to form the final tracks 



### Citing GMMCP

Please cite GMMCP in your publications if it helps your research:

    @inproceedings{dehghanCVPR2015,
      title = {{GMMCP-Tracker}:Globally Optimal Generalized Maximum Multi Clique Problem for Multiple Object Tracking},
      author = {Afshin Dehghan and Shayan Modiri Assari and Mubarak Shah.},
      booktitle = {CVPR},
      year = {2015}
    }

### Contents
1. [Dependencies](#Dependencies)
2. [Installation](#Installation)
3. [Test](#test)

### Dependencies

  The CPLEX dependencies are included for Windows and Ubuntu. 
  For Mac you need to include the corresponding files by following the installation on IBM website. 
  (CPLEX is an optimization software with license provided FREE FOR ACADEMIC PURPOSES by IBM.
  You can download CPLEX by following this link.)

  http://www.ibm.com/developerworks/downloads/ws/ilogcplex/index.html?cmp=dwenu&cpb=dwweb&ct=dwcom&cr=dwcom&ccy=zz

  Check out the IBM Academic initiative to get a free license.

  http://www-304.ibm.com/ibm/university/academic/pub/page/ban_ilog_programming

### Installation
1. Get the code.
  ```Shell
  git clone git@github.com:afshindn/GMMCP_Tracker.git
  cd GMMCP_Tracker
  ```

2. Download sample test data using git lfs [GIT LFS Instruction:](https://git-lfs.github.com/)
  ```Shell
  git lfs pull
  ```
  
  Or alternatively download the data using this [link](https://www.dropbox.com/s/firtnxjup9ro7p9/Data.tar.gz?dl=0)

### Test
1. select the test sequence by changing main.m file. The images for three test sequences of TUD_Crossing, TUD_Stadtmitte and PL2 are included. 

2. Run main.m

*** If you plan to run it on your own sequences, check the the format of the provided data. You just need to provide the tracklets in the same format that the code requires. 
You can also modify the netCost matrix generator depending on your own sequences. 
