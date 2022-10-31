resultdir="results_tsgrgb/test_tsgrgb"
## Run
python two_stage_graph_rgbhist.py --detections data/gluecv_in_gt_320x240/ --img_in data/seaclef16imgs_val_320x240 --debug false --config_file $resultdir/tsgrgb.cfg --out $resultdir
