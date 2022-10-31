## Kalman-IOU Tracker
Python implementation of the Kalman-IOU Tracker.

This tracker is modified based on the original [IOU Tracker](https://github.com/bochinski/iou-tracker), which is a simple, high-speed tracker that works really well on the [UA-DETRAC](https://detrac-db.rit.albany.edu/) dataset. We make use of a Kalman filter to estimate object location and speed together, and obtained incremental performance improvements over the original version. 

The Kalman filter's capability of making predictions allows us to skip frames while still keeping track of the object. Skipping frames in a tracking-by-detection task means the detector will process significantly less frames. The Kalman-IOU Tracker, when used with the [EB](http://zyb.im/research/EB/) detector and configured to skip 2/3 of the frames, can run in real-time while outperforming the original IOU Tracker on the DETRAC-Train dataset.

This repo is predominantly based on the original [IOU Tracker](https://github.com/bochinski/iou-tracker). Please consider citing their work:

```
@INPROCEEDINGS{1517Bochinski2017,
	AUTHOR = {Erik Bochinski and Volker Eiselein and Thomas Sikora},
	TITLE = {High-Speed Tracking-by-Detection Without Using Image Information},
	BOOKTITLE = {International Workshop on Traffic and Street Surveillance for Safety and Security at IEEE AVSS 2017},
	YEAR = {2017},
	MONTH = aug,
	ADDRESS = {Lecce, Italy},
	URL = {http://elvera.nue.tu-berlin.de/files/1517Bochinski2017.pdf},
	}
```


## Results from DETRAC Dataset
To reproduce the reported results, download and extract the [DETRAC-toolkit](http://detrac-db.rit.albany.edu/download)
and the detections you want to evaluate. Download links for the EB detections are provided below.
Clone this repository into "DETRAC-MOT-toolkit/trackers/".
Follow the instructions to configure the toolkit for tracking evaluation and set the tracker name in "DETRAC_experiment.m":

```
tracker.trackerName = 'kiout';
```

and run the script.

Note that you still need a working python environment with numpy and [pykalman](http://pykalman.github.com) installed.
You should obtain something like the following results for the 'DETRAC-Train' set:

### DETRAC-Train Results with EB Detector
| Tracker | Frames | PR-MT | PR-PT  | PR-ML | PR-FP   | PR-FN   | PR-IDs| PR-FM | PR-MOTA | PR-MOTP | PR-MOTAL |
| -------- | ----- | ----- | ------ | ----- | ------- | ------- | ----- | ----- | ------- | ------- | -------- |
| IOU | All        |32.34  |12.88   |20.93  |7958.82  |163739.85|4129.40|4221.89|35.77    |40.81    |36.48     |
|KIOU | All        |37.4   |7.3     |21.5   |8427.5   |148393.9 |422.7  |605.4  | 39.0     |40.7     |39.1      |
|KIOU | 1/2        |34.5   |9.5     |22.1   |6803.5   |155556 |472.8  |599.6  | 38.0     |40.9     |38.1      |
|KIOU | 1/3 | 31.9 | 10.9 | 23.4 | 7611.4 | 160566.9 | 483.2 | 630.9 | 37.0 | 40.9 | 37.1 |
|KIOU | 1/4 | 20.8 | 12.6 | 32.8 | 11163.4 | 192857.4 | 628.1 | 711.1 | 30.8 | 40.9 | 30.9 |


### DETRAC-Test (Overall) Results
The reference results are taken from the [UA-DETRAC results](http://detrac-db.rit.albany.edu/TraRet) site. Only the best tracker / detector
combination is displayed for each reference method.

| Tracker       | Detector | PR-MOTA | PR-MOTP     | PR-MT     | PR-ML     | PR-IDs   | PR-FM    | PR-FP      | PR-FN      | Speed          |
| ------------- | -------- | ------- | ----------- | --------- | --------- | -------- | -------- | ---------- | ---------- | -------------- |
|CEM            | CompACT  | 5.1\%     |35.2\%     |3.0\%      |35.3\%     |**267.9** |**352.3** |**12341.2** |260390.4    |4.62 fps        |
|CMOT           | CompACT  | 12.6\%    |36.1\%     |16.1\%     |18.6\%     |285.3     |1516.8    |57885.9     | 167110.8   | 3.79 fps     |
|GOG            | CompACT  | 14.2\%    |37.0\%     |13.9\%     |19.9\%     |3334.6    |3172.4    |32092.9     |180183.8    |390 fps         |
|DCT            | R-CNN    | 11.7\%    |38.0\%     |10.1\%     |22.8\%     |758.7     |742.9     |336561.2    |210855.6    |0.71 fps        |
|H<sup>2</sup>T | CompACT  | 12.4\%    |35.7\%     |14.8\%     |19.4\%     |852.2     |1117.2    |51765.7     |173899.8    | 3.02 fps       |
|IHTLS          | CompACT  | 11.1\%    |36.8\%     |13.8\%     |19.9\%     |953.6     |3556.9    |53922.3     |180422.3    |19.79 fps       |
|IOU            | R-CNN    |16.0\%     |**38.3\%** |13.8\%     |20.7\%     |5029.4    |5795.7    |22535.1     |193041.9    |**100,840 fps** |
|IOU            | EB       |19.4\%     |28.9\%     |17.7\%     |18.4\%     |2311.3    |2445.9    |14796.5	  |171806.8    |6,902 fps       |
|**KIOU**       | EB       | **21.1\%** | 28.6\%   | **21.9\%** | **17.6\%** | 462.2  | 712.1    | 19046.8    | **159178.3** |  - |

##### EB detections
These results are evaluated on detections of [EB](http://zyb.im/research/EB/) detector. We obtained our copy of detections from the authors of the original [IOU Tracker](https://github.com/bochinski/iou-tracker).
