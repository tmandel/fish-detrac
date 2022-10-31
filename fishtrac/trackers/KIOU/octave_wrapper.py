
import sys
import os
import iou_tracker as iou
import scipy.io

print(sys.argv)

if len(sys.argv) < 8:
	print("Usage: octave_wrapper.py detectionsFile sigma_l sigma_iou sigma_p sigma_len skip_frames n_skip")
	sys.exit(2)

d = scipy.io.loadmat(sys.argv[1])
detections = d['detects']
sigma_l = float(sys.argv[2])
sigma_iou = float(sys.argv[3])
sigma_p = int(sys.argv[4])
sigma_len = int(sys.argv[5])
sf = int(sys.argv[6])
skip_frames = True
if sf == 0:
	skip_frames = False
n_skip = int(sys.argv[7])
speed,trackList = iou.track_iou_matlab_wrapper(detections, sigma_l, sigma_iou, sigma_p, sigma_len, skip_frames, n_skip)

scipy.io.savemat("results.mat", {"speed":speed, 'trackList':trackList})