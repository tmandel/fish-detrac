#  Welcome to the FISHTRAC codebase (and dataset)

<img src="./intro_gif.gif" width=533 height=300>

Welcome to the FISHTRAC codebase! This includes a harness for comparing 17 Multi-Object Tracking (MOT) algorithms on three datasets, links to our new real-world fish tracking dataset, and the ability to easily run trackers on  new datasets or detections.   It also includes code for our new MOT algorithm (RCT aka KPD) that works well in domains like fish tracking where detection is imperfect, and the ability to easily run trackers on  new datasets or detections.  

If you use this codebase (or any part of it, such as the RCT tracker), please cite the following associated publication:

[Detection Confidence Driven Multi-Object Tracking to Recover Reliable Tracks From Unreliable Detections](https://www.sciencedirect.com/science/article/pii/S0031320322005878)

```
@article{mandel2022detection,
title = {Detection Confidence Driven Multi-Object Tracking to Recover Reliable Tracks From Unreliable Detections},
author = {Travis Mandel and Mark Jimenez and Emily Risley and Taishi Nammoto and Rebekka Williams and Max Panoff and Meynard Ballesteros and Bobbie Suarez},
journal = {Pattern Recognition},
year = {2022},
pages = {109107},
issn = {0031-3203},
doi = {https://doi.org/10.1016/j.patcog.2022.109107},
url = {https://www.sciencedirect.com/science/article/pii/S0031320322005878}
}
```



Our test harness is a heavily modified and extended version of the [UA-DETRAC](https://detrac-db.rit.albany.edu/download) toolkit.

**There are a lot of MOT codebases out there.  Why consider using ours?**
* Completely built off of free and open-source technologies  - no need to purchase MATLAB or run on Windows (it's meant for Linux!)
* Easily **run** trackers on your own instead of relaying on leaderboards or saved-off results. Perfect for trying new datasets or seeing how trackers would perform given different inputs.
* Integrates 17 open-source trackers into the test harness - this includes classic trackers like GMMCP and JPDA-M, recent deep trackers like AOA and TransCenter, and single object trackers like D3S and GOTURN.  
* Three very different datasets provided to easily test your tracker in different environments
* Brand-new **FISHTRAC underwater fish tracking dataset** to test trackers in a difficult real-world setting (complex backgrounds, complex camera movement, complex object movement and appearance changes).
* Features a brand-new tracking algorithm, RCT, which works very well in the face of imperfect detections (that occur in understudied settings such as fish tracking)
* Scripts and instructions including to help you run these trackers on your own dataset.
* Includes both HOTA and MOTA metrics
* One of the only datasets to release deep object detections that are completely unfiltered by detection confidence - allowing for approaches like RCT that make use of this value.
* Tools provided to visualize results




## Initial setup
This is designed to work only on Linux OS. The steps you should follow are:
1. Clone the repo
2. Install Anaconda
3. Install GNU Octave (version 4.4.1+) `sudo apt-get install octave &&  sudo apt-get install liboctave-dev` (this will install version 5.2.0 on ubuntu 20, if you are ubuntu 18  or earlier we recommend installing version 5.2.0 or 6.2.0 from source )
4. Install CMake
5. (Only needed for **TransCenter** tracker) Install Singularity (we used version 3.7.2) [https://docs.sylabs.io/guides/3.5/admin-guide/installation.html] 
6. (Only needed for **JPDA-M** tracker) Install flatpak,  and Octave 6.2.0 inside flatpak, which needs the io and statistics packages 
```
sudo apt install flatpak
flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
 flatpak install flathub org.octave.Octave
 sudo flatpak update --commit=51d145ea9ae2bd4bfb6d5518fd8d6c1833753d98d102ec9deae589dfea25d9b9 org.octave.Octave
 sudo flatpak install flathub org.kde.Platform//5.15
 sudo flatpak install flathub org.kde.Sdk//5.15
 flatpak run org.octave.Octave
 pkg install io-2.6.3.tar.gz
 pkg install statistics-1.4.3.tar.gz
 quit()
 ```
5. Download [fishtrac-extras.zip](https://web.datadrivengame.science/fishtrac/fishtrac-extras.zip) and place it in the outer fish-detrac directory (this contains large files that are too big to place in the repo).
6. cd into the fish-detrac directory and run `./setupFiles.sh` to create the necessary directories and conda environments, as well as download and setup the D3S tracker
7. Follow the instructions printed at the end of `setupFiles.sh` to install the necessary Octave packages.

# Running trackers on datasets

1. Download your dataset(s) of choice and unzip it **into the fishtrac folder**.  Our tutorial below will use FISHTRAC train, but the process is similar for the other choices.

**Note: By downloading and using FISHTRAC data, you hereby agree not to use  not use FISHTRAC data for harmful/unethical purposes, for instance better killing, harvesting, harming, or exploiting fish populations.  FISHTRAC is meant to aid conservation of fish and non-invasive studies of fish behavior.**

* [FISHTRAC Train Data](https://web.datadrivengame.science/fishtrac/fishtrac-train.zip). FISHTRAC conatins real-world video of fish behavior off the coast of the Big Island of Hawai'i.  Most of our data was collected by divers near coral reefs, increasing the complexity of the problem.
* FishTrac Test Data [Link coming soon!] (Please follow good test set discipline, do not examine results on the test set until the end of your project)
* [MOT17-reformatted](https://web.datadrivengame.science/fishtrac/MOT17-reformatted.zip) This is the [MOT17](https://motchallenge.net/data/MOT17/) train set converted to DETRAC format with included detections from our custom low-performance detector. MOT17 is one of the most popular sources of pedestrian video.  In the paper we used this as a "generalization test" since we did not examine this while developing our algorithm, and unfortunately the M0T17 test set annotations are not pubically available.  
<sub><sup>This data is licensed CC BY-NC-SA 3.0 by the authors of the following paper:  	Milan, A., Leal-Taixé, L., Reid, I., Roth, S. & Schindler, K. MOT16: A Benchmark for Multi-Object Tracking. arXiv:1603.00831 [cs], 2016., (arXiv: 1603.00831).  Our modifications are licensed the same way.</sup></sub>
* [UA-DETRAC](https://detrac-db.rit.albany.edu/download) - You will want to download the *images and MAT annotations only*, and place them in their respective folders (`DETRAC-images` and `DETRAC-Train-Annotations-MAT`).  The detections we created using the imperfect detector found in the paper can be found [here](https://web.datadrivengame.science/fishtrac/DETRAC-Detections.zip) and can be placed in the `DETRAC-Train-Detections/R-CNN` folder.
* Or your own custom dataset (see instructions below)


2. Choose the sequence file that matches your dataset our interest:

We provide several sequence files in `fishtrac/evaluation/seqs`:
* `fishtrac-train` : This contains the full 3-video trainset for our FISHTRAC dataset. As explained in the paper, the trainset is intentionally kept small to determine how to build effective MOT systems when data is scarce.
* `fishtrac-test`: this contains the 11-video test set for our FISHTRAC dataset.  Do not run on these until the end of your project.
* `car-train`: This contains the three videos from the UA-DETRAC train set we used as a reducted "train" set in the paper.
* `car-validate`: This contains the 4 -video set from UA_DETRAC train that we used to check that our scripts were working before running on the test data.
* `car-test`: This contains all 40  videos from the UA-DETRAC test set.
* `MOT17-vids`: this contains the MOT17 train set, which we used in the paper to evaluate the algorithms on a different domains. THe DPM annotation on each one is meaningless because we use our own set of detections (download provided above).
* `testlist-combined` - this combines fishtrac-test and car-test (useful for running all test videos at once)
* `trainlist-split` - this has both car-train and fishtrac-train, and instructions the comparison script to do a 50/50 average between the datasets - this is how we tune parameters such as the confidence threshold cutoff for the non-RCT Trackers, etc.
* If you just want to run one a single video, you can simply do `_videoName` to run on that one videom for instance `_02_Oct_18_Vid-3` will run on just the one 02_Oct_18_Vid-3 video.
* With your own dataset, you will need to create your own sequence file in `fishtrac/evaluation/seqs` with the names of the videos you want to run on.


3. To run trackers, we can use experiment wrapper.  Experiment wrapper lets you specify the tracker, the detection confidence threshold, and the sequence file name (see step 9).  It will automatically record MOTA and HOTA metrics and time out the trackers if they have not completed in 30 minutes.  As an example, we will run GOG and RCT (called KPD in the code).  We run GOG with a 0.3 threshold on detection confidence because that is what we found to perform best on our train data; the threshold for RCT is arbitrary: it does not use the threshold as it consumes unfiltered detections.
```
    cd fishtrac
    conda activate fish_env
	python experiment_wrapper.py GOG 0.3 fishtrac-train octave-cli
	python experiment_wrapper.py KPD 0.5 fishtrac-train octave-cli
```

	Note that you might need to replace `octave-cli` part if you have a different way of running octave (e.g. a custom compiled version, etc.)  If it succeeded, you should see a relatively short output and a message like: 

	`run tracker command returned: 0`

	otherwise, there may have been some error in the installation process.

11. Next, we will take a look at some of the scores:
```
	cd compare-trackers/
	python benchmark_evaluation.py fishtrac-train GOG,KPD train
	cat benchmark_results.csv
```
    *Note : the train argument means we will run over all detection confidence thresholds that have been run to determine the best and store it off in a file in `fishtrac/results/best_thresholds/`. If we were to specify test instead of train, it would read and used the stored threshold rather than searching for the best.*
    
	Pasting the displayed info into a spreadsheet program will show that RCT (KPD) has a much better HOTA and MOTA than GOG on the FISHTRAC train videos.  In fact, they should be essentially the same results as we provided for "Fish Vids" in the provided `full_paper_results/Train_results.xlsx` spreadsheet that we based our paper results on (along with `full_paper_results/Test_results.xlsx`).

4. However, it is also useful to see qualitative performance (that is, what the trackers actually look like in action!).  Thankfully, we also provide scripts for that. Here is an example of visualizing the methods on one of the three videos:

```
	cd ../convert_gt
    python mergeFrame.py ../DETRAC-images/02_Oct_18_Vid-3
	python showOnVideo.py ../DETRAC-images/02_Oct_18_Vid-3.mp4 GOG_Test.mp4 ../results/GOG/R-CNN/0.3/02_Oct_18_Vid-3_LX.txt GOG
	python showOnVideo.py ../DETRAC-images/02_Oct_18_Vid-3.mp4 RCT_Test.mp4 ../results/KPD/R-CNN/0.5/02_Oct_18_Vid-3_LX.txt RCT
```

Then view the GOG_Test.mp4 and RCT_Test.mp4 videos in your favorite video player!  You are now done with the basic tutorial!

## Tracker-specific notes

* The deep learning trackers require specialized hardware and software to run effectively.  AOA, TransCenter, and GOTURN-GPU have all been tested on a server running Ubuntu 18 and with an RTX 2080 Ti.  DAN and D3S were tested on a CentOS 7 system with two Nvidia Tesla V100 32GB cards due to differing hardware requirements. As these are not our trackers, we cannot guarantee they will work on other systems.
* If using your own dataset (see below), to maximize performance, DAN  and TransCenter require training a model on annotated video data. Scripts for that can be found in the associated repos.

# Using your own dataset:

The FISHTRAC codebase is intended to provide a  general-purpose way to evaluate tracking-by-detection methods on a variety of datasets, including new ones that other researchers have collected.  Tracking-by-detection methods typically have three sources of input: Raw videos (mp4 or folder of frames), detections, and annotations (so that the results can be rigorously evaluated). 

## Getting detections

The first step to getting detections would be to train a detector on your domain. For this, you will need some annotated image data.

But what if I  have little to no annotated images data?  You can follow the approach we took in the paper and download images from Google Open Images - see https://github.com/aferriss/openImageDownloader

In the paper we did a query like the following to grab all human-annotated bounding box data of fish (you will need to change the label name depending on your label of interest):
```
#standardsql
SELECT
  i.image_id AS image_id,
  original_url,thumbnail_300k_url,
  confidence
FROM
  `bigquery-public-data.open_images.annotations_bbox` l
INNER JOIN
  `bigquery-public-data.open_images.images` i
ON
  l.image_id = i.image_id
WHERE
  label_name='/m/0ch_cf'
  AND source='human'
  AND Subset='train'
```
Next, you will need to covert those annotations to covert these annotations to a format that you can train on. We have provided a script to convert to keras-retinanet format in `fishtrac/convert_gt/detection_train/annotations.py`

Next, you will need to train the detector over your annotations.  We used https://github.com/fizyr/keras-retinanet (version 0.5.0) to train a retinanet model on the CSV file and then convert the training h5 file to an inference h5 file. Although this method is a bit old, it outperformed more recent approaches such as YOLOv4 on our dataset, as we explain in the paper. 

Finally, you will need to run the detector over the video file(s) and create the resulting detection file.  This is the purpose of `fishtrac/convert_gt/outputDetectorPredictions.py`. It should generate a Detection MAT file which can be placed in the `DETRAC-Train-Detections/R-CNN` folder.


## From mp4 video and vatic.js style annotations
	
In order to evaluate trackers, we need video annotations.  As an example of how we did this, in the `raw_data` folder (provided by `fishtrac-extras`) I have provided the raw mp4s and raw xml annotation files produced by the tool [vatic.js](https://dbolkensteyn.github.io/vatic.js/) for Fishtrac Train.

1. Copy the files into convertGT:
```
cp raw_data/*.mp4 fishtrac/convert_gt
cp raw_data/*.xml fishtrac/convert_gt
```


2. Run convertLocal.py over the video to convert the annotation to DETRAC format.
```
cd fishtrac/convert_gt
python convertLocal.py
```
(When prompted, select the 02_Oct_18_Vid-3.mp4, then run again for the other two mp4 files)

	This creates numerous items:
	* A folder of images in DETRAC format for the video
	* The annotations in mat format
	* The annotations in a similar format to how DETRAC specifies tracks
	* A video to help you review the annotations and make sure they look correct




3. Now, we need to move the files in the right place for the FISHTRAC experiment. 
```
	cp *.mat ../DETRAC-Train-Annotations-MAT/
	cp -r 02_Oct_18_Vid-3 ../DETRAC-images/
    cp -r V1_Leleiwi_26June19_17 ../DETRAC-images/
    cp -r V1_Leleiwi_26June19_22 ../DETRAC-images/
```
    
Once you have placed the detections from the `fishtrac-train.zip` file in the `DETRAC-Train-Detections/R-CNN`, you should be able to run as normal and get the same results as we did when we just used the processed annotations and images from `fishtrac-train.zip`.

## From MOT-17 frame images and MOT17 annotations
Some may have their images and annotations already in MOT17 format so as to participate in the MOTChallenges, etc.

We provide scripts for this in the `fishtrac/convert_gt/MOT17convert` folder.  If you make a trainSet folder and put the MOT17 videos that end in DPM there, running `convertMOTImages.sh` will convert the images to DETRAC format.  Running `convertAllGT.sh` will convert the MOT17 ground truth files to DETRAC format.  Then you can place the converted images in the `fishtrac/DETRAC-images/` folder and the ground truth mat files in the `fishtrac/DETRAC-Train-Annotations-MAT/` folder.



# License info

The FISHTRAC evalulation harness is a (heavily modifed) derivative work of the [UA-DETRAC evaluation codebase](https://detrac-db.rit.albany.edu/download). UA-DETRAC is also licensed [CC BY-NC-SA 3.0](https://creativecommons.org/licenses/by-nc-sa/3.0/).  UA-DETRAC was developed by Longyin Wen, Dawei Du, Zhaowei Cai, Zhen Lei and Ming-Ching Chang, Honggang Qi, Jongwoo Lim, Ming-Hsuan Yang, Siwei Lyu, Yi Wei, Yuezun Li,Tao Hu, and Siwei Lyu.

Therefore, the FISHTRAC evaluation harness code (excluding the HOTA code and the code for the individual trackers) is also licensed [CC BY-NC-SA 3.0](https://creativecommons.org/licenses/by-nc-sa/3.0/). The FISHTRAC evaluation code was developed by Travis Mandel, Mark Jimenez, Emily Risley, Taishi Nammoto, Rebekka Williams, Max Panoff, Meynard Ballesteros, Timothy Kudryn, and Sebastian Carter.  

FISHTRAC code incorporates HOTA evaluation scores from Jonathon Luiten, Aljosa Osep, Patrick Dendorfer, Philip Torr, Andreas Geiger, Laura Leal-Taixe and Bastian Leibe, and their paper "HOTA: A Higher Order Metric for Evaluating Multi-Object Tracking". That code from their [repo](https://github.com/JonathonLuiten/TrackEval/) is provided under the [MIT License](https://mit-license.org/). We included a modified version of their code under the `fishtrac/evaluation/TrackEval` folder - any modifications we have made (to base it on DIOU, etc) are released under the same license.

## Trackers:

All trackers are included under the `fishtrac/trackers/<trackerName>` folder unless otherwise specified.

* **RCT** (named in the code as **KPD**) is our innovative tracker and was developed by Travis Mandel, Mark Jimenez, Emily Risley, Taishi Nammoto, Rebekka Williams, Max Panoff, Meynard Ballesteros, Jennifer Nakano, and Timothy Kudryn in our paper, "Detection Confidence Driven Multi-Object Tracking to Recover Reliable Tracks From Unreliable Detections". Excluding the `fishtrac/trackers/KPD/pykfaster` folder,  RCT is released under the [CC BY 3.0](https://creativecommons.org/licenses/by/3.0/) license.
    * RCT relies upon the [pykalman](https://github.com/pykalman/pykalman) Kalman Filter library by Daniel Duckworth.  We modified the library to improve speed etc.  The original  library was released under a BSD license, our modifications in `fishtrac/trackers/KPD/pykfaster` are licensed in the same way.

* **GOG** is from the paper by Hamed Pirsiavash, Deva Ramanan, Charless C. Fowlkes, "Globally-Optimal Greedy Algorithms for Tracking a Variable Number of Objects". It was included in the original UA-DETRAC codebase and is therefore licensed [CC BY-NC-SA 3.0](https://creativecommons.org/licenses/by-nc-sa/3.0/). Our modifications to that tracker to make it open-source-compatible are licensed in the same way.

* **CMOT** is from Seung-Hwan Bae and Kuk-Jin Yoon, "Robust Online Multi-Object Tracking based on Tracklet Confidence and Online Discriminative Appearance Learning". It was included in the original UA-DETRAC codebase and is therefore licensed [CC BY-NC-SA 3.0](https://creativecommons.org/licenses/by-nc-sa/3.0/). Our modifications to that tracker to make it open-source-compatible are licensed in the same way.

* **RMOT** is from Ju Hong Yoon, Ming-Hsuan Yang, Jongwoo Lim and Kuk-Jin Yoon, "Bayesian Multi-Object Tracking Using Motion Context from Multiple Objects". It was included in the original UA-DETRAC codebase and is therefore licensed [CC BY-NC-SA 3.0](https://creativecommons.org/licenses/by-nc-sa/3.0/). Our modifications to that tracker to make it open-source-compatible are licensed in the same way.

* **IHTLS** is from  Caglayan Dicle, and Octavia I Camps,  and Mario Sznaier and their paper, "The Way They Move: Tracking Targets with Similar Appearance".  It was included in the original UA-DETRAC codebase and is therefore licensed [CC BY-NC-SA 3.0](https://creativecommons.org/licenses/by-nc-sa/3.0/). Our modifications to that tracker to make it open-source-compatible are licensed in the same way.

* **GMMCP** is from Afshin Dehghan, Shayan Modiri Assari, Mubarak Shah and their paper "GMMCP-Tracker: Globally Optimal Generalized Maximum Multi Clique Problem for Multiple Object Tracking". Their [code](https://github.com/afshindn/GMMCP_Tracker) is licensed under a [BSD License](https://choosealicense.com/licenses/0bsd/). Our modifications to that tracker to make it open-source-compatible are licensed in the same way.

* **KIOU** is from Siyuan Chen, Chenhui Shao, Erik Bochinski, Volker Eiselein and Thomas Sikora, and their paper "Efficient Online Tracking-by-Detection With Kalman Filter".  Their [code](https://github.com/siyuanc2/kiout) is licensed under an [MIT license](https://mit-license.org/). Our modifications to that tracker to make it open-source-compatible are licensed in the same way.

* **VIOU** is from Erik Bochinski, Tobias Senst, Thomas Sikora, and their paper Extending IOU Based Multi-Object Tracking by Visual Information. Their [code](https://github.com/bochinski/iou-tracker) is licensed under an [MIT license](https://mit-license.org/). Our modifications to that tracker to make it open-source-compatible are licensed in the same way. 

* **VFT** is from Jonas J&auml;ger, Viviane Wolff, Klaus Fricke-Neuderth, Oliver Mothes, and Joachim Denzler and their paper "Visual fish tracking: combining a two-stage graph approach with CNN-features".  We recieved the source code from the first author, who provided written permission to include it in our public  codebase. Therfore the presumed license for the tracker (and our minor modifications) is [CC BY-NC-SA 3.0](https://creativecommons.org/licenses/by-nc-sa/3.0/).

* **DAN** is from ShiJie Sun,  Naveed Akhtar, HuanSheng Song,  Ajmal Mian,  and  Mubarak Shah, and their paper "Deep affinity network for multiple object tracking". Their [code](https://github.com/shijieS/SST) is based on a  [CC BY-NC-SA 3.0](https://creativecommons.org/licenses/by-nc-sa/3.0/) license,  and our modifications to their code to integrate into FISHTRAC are released under the same license.

* **AOA** is from Fei Du, Bo Xu, Jiasheng Tang, Yuqi Zhang, Fan Wang and
Hao Li, from their paper "1st Place Solution to ECCV-TAO-2020: Detect and Represent Any Object for Tracking". Their [code](https://github.com/feiaxyt/Winner_ECCV20_TAO) is licensed under an [Apache 2.0](https://choosealicense.com/licenses/apache-2.0/) License , and our modifications to their code to integrate into FISHTRAC is released under the same license.  To comply with the conditions of the license, each file we changed or added in the AOA folder is marked with a notice at the top.

* **JPDA-M** is from Seyed Hamid Rezatofighi, Anton Milan, Zhen Zhang,  Qinfeng Shi,  Anthony Dick,  and Ian Reid,  and their paper "Joint probabilistic data association revisited". Their [code](http://research.milanton.net/files/iccv2015/jpda_m.zip) has a custom licence which says it can only be used for research purposes and limits liability - our modifications to adapt it to open-source and integrate it into the FISHTRAC codebase are released under the same license.

* **TransCenter** (**TRANSCTR**) is From Yihong Xu, Yutong Ban, Guillaume Delorme,  Chuang Gan and Daniela Rus and Xavier Alameda-Pineda, and their paper "TransCenter: Transformers with Dense Representations for Multiple-Object Tracking". Their [code](https://gitlab.inria.fr/robotlearn/TransCenter_official) located wholly in the `fishtrac/trackers/TRANSCTR/TransCenter_official` is released under the [GPLv3 License](https://www.gnu.org/licenses/gpl-3.0.en.html), and our modifications are released under the same license.  Since our experiment wrapper code uses the shell to start this code as a separate process in a completely different working environment (specifically, using the Singularity environment file) we feel that this meets GNU's definition of ["arm's length"](https://www.gnu.org/licenses/gpl-faq.html#GPLInProprietarySystem) and the entire FISHTRAC codebase does not need to be licensed under GPL.  The wrapper scripts in the outer folder (`fishtrac/trackers/TRANSCTR/`) are wholly created by our team and licensed  [CC BY 3.0](https://creativecommons.org/licenses/by/3.0/).

* **KCF** is from Jo&atilde;o F Henriques, Rui Caseiro, Pedro Martins,  and Jorge Batista, and their paper, "High-speed tracking with kernelized correlation filters". We use the built-in OpenCV implementation rather than relying on code from the authors, so our implementation would not be considered a derivative work. Our code to wrap the single-object tracker as a multi-object tracker and integrate it into the DETRAC codebase is provided under a [CC BY 3.0](https://creativecommons.org/licenses/by/3.0/) license.

* **MedianFlow** (**MEDFLOW**) is from  Zdenek Kalal,  Krystian Mikolajczyk, and  Jiri Matas, and their paper, "Forward-backward error: Automatic detection of tracking failures". We use the built-in OpenCV implementation rather than relying on code from the authors, so our implementation would not be considered a derivative work. Our code to wrap the single-object tracker as a multi-object tracker and integrate it into the DETRAC codebase is provided under a [CC BY 3.0](https://creativecommons.org/licenses/by/3.0/) license.

* **GOTURN** (**GOTURN-GPU**) is from David Held,  and Sebastian Thrun,  and Silvio Savarese, from their paper "Learning to track at 100 {FPS} with deep regression networks". We used the official [PY-GOTURN Caffe implementation](https://github.com/nrupatunga/PY-GOTURN) by Nrupatunga, which supports GPU computation.  It is provided under an [MIT license](https://mit-license.org/), and our modifications to their code to integrate into FISHTRAC are released under the same license.

* **D3S** is from Alan Lukezic,  Jiri Matas, and Matej Kristan and their paper, "D3S - A Discriminative Single Shot Segmentation Tracker".  The [code](https://github.com/alanlukezic/d3s) is released publically, but under an unclear license - therefore, rather than directly include this code directly in our repo, we include scripts to download it from GitHub and integrate it with the codebase. 

# Contact

 * Travis Mandel, email: 
`tmandel <at> hawaii <dot> edu`



