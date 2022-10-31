'''Run two-stage-graph-cnn tracking algorithm.

Input data format:
    Requires a detection file in format:
    framenumber,xc,yc,w,h
    framenumber,xc,yc,w,h
    ...
    xc,yc: defines the center of a bounding box (values are relative to image)
    w,h: define width and height of the bbox (values are relative to image)

Output data format:
    framenumber; track_id; xc; yc; width; height;
    ...
    The values of xc,yc,width and height are *relative to image*
    (xc,yc) define the center of a bbox. As required by CLEAR-MOT-Wrede
    as input data.
'''
import pandas as pd
import argparse
from glue_cv.methods.feat_graph_tracker import Feat2StageAlg
from glue_cv.data_access import ImageSet
from glue_cv import visualise
from glue_cv import bboxes
from glue_cv import ocv_helper
from glue_cv import stopwatch
from os.path import join
import os
import logging
import cv2
import numpy as np

__author__ = 'Jonas Jaeger'

def compute_features(video_imgs_in, df):
    img_file_list = sorted(os.listdir(video_imgs_in))
    bb_img_list = list()
    frame_n_list = list()
    for frame_id, img_file in enumerate(img_file_list):
        img_path = join(video_imgs_in, img_file)
        img = cv2.imread(img_path)
        img_w = img.shape[1]
        img_h = img.shape[0]
        df_frame = df.loc[df['frame'] == frame_id]
        frame_n_list += [frame_id] * len(df_frame)
        frame_bb_list = df_frame.iloc[:,[1,2,3,4]].values
        frame_bb_list = bboxes.bb_convert(frame_bb_list,
                                    in_format="rel[xc,yc,w,h]",
                                    out_format="abs[xtl,ytl,w,h]",
                                    img_w=img_w,
                                    img_h=img_h).tolist()
        bb_img_list += ocv_helper.crop_bbox_list(img, frame_bb_list)
    # X = cfeat.compute(bb_img_list, batch_size=100)
    first_time = True
    for bb_img in bb_img_list:
        hist0 = cv2.calcHist([bb_img],[0],None,[256],[0,256])
        hist0 = hist0.T
        hist0 = hist0 / np.sum(hist0)
        hist1 = cv2.calcHist([bb_img],[1],None,[256],[0,256])
        hist1 = hist1.T
        hist1 = hist1 / np.sum(hist1)
        hist2 = cv2.calcHist([bb_img],[2],None,[256],[0,256])
        hist2 = hist2.T
        hist2 = hist2 / np.sum(hist2)
        hist = np.concatenate((hist0, hist1, hist2), axis=1)
        if first_time:
            first_time = False
            X = hist
        else:
            X = np.vstack((X, hist))
    return X

def run(detections, out, img_in, config_file, debug=None):
    if debug is None:
        debug = False
    else:
        debug = 'true' == debug.lower()

    if debug:
        logging.basicConfig(filename=join(out,"tsgrgbhist_log.txt"),
                            level=logging.DEBUG)
    else:
        logging.basicConfig(filename=join(out,"tsgrgbhist_log.txt"),
                            level=logging.INFO)

    if not os.path.exists(out):
        os.mkdir(out)

    watch = stopwatch.Stopwatch(print_time=False)
    watch.start()

    twostage_tracker = Feat2StageAlg(config_file)

    for detection_file in os.listdir(detections):

        print(("Compute tracks for detection file: %s"%(detection_file,)))
        video_name = detection_file.split('.')[0]
        print(video_name)
        #video_imgs_in = join(img_in, video_name)
        video_imgs_in = img_in
        result_path = join(out, video_name)
        if not os.path.exists(result_path):
            os.mkdir(result_path)
        in_file = join(detections, detection_file)
        df = pd.read_csv(in_file, names=['frame', 'xc', 'yc', 'w', 'h'])
        bb_list = df[['xc','yc','w','h']].values.tolist()
        frames = df['frame'].values.tolist()

        twostage_tracker = Feat2StageAlg(config_file=config_file)
        if twostage_tracker.W_APP > 0.0:
            print("Start computing Features")
            if debug:
                X = compute_features(video_imgs_in, df)
            else:
                X = compute_features(video_imgs_in, df)
            print("Computed Features!")
        else:
            X = None

        print("Start computing tracks")
        tracks = twostage_tracker.run(bb_list, frames, X)
        print("Computed Tracks")
        df_out = pd.DataFrame(tracks)
        if debug:
            print("Start visualizing tracks")
            img_out_path = join(result_path, 'images')
            if not os.path.exists(img_out_path):
                os.mkdir(img_out_path)
            img_set = ImageSet(video_imgs_in, load_option='all')
            for frame_id, img in enumerate(img_set.image_gen()):
                # Get all bboxes for this frame
                img_w = img.shape[1]
                img_h = img.shape[0]
                df_frame = df_out.loc[df_out[0] == frame_id]
                bb_list = df_frame.ix[:,2:6].values
                bb_list = bboxes.bb_convert(bb_list,
                                            in_format="rel[xc,yc,w,h]",
                                            out_format="abs[xtl,ytl,w,h]",
                                            img_w=img_w,
                                            img_h=img_h)
                # Labels are track_id
                labels = df_frame.ix[:,1].values
                out_img = visualise.draw_bbox_color_by_index(img, bb_list,
                                                             label_list=labels)
                cv2.imwrite(join(img_out_path, "%06d.png"%(frame_id)), out_img)
            print("Finished track visualization")
        # df_out[[2,3,4,5]] = pd.DataFrame(bboxes.bb_rel_to_abs(
        #     df_out.ix[:,2:6].values, IMG_WIDTH, IMG_HEIGHT).tolist())

        # Add one to track_id since matlab cannot deal with index 0.
        df_out.loc[:,1] += 1
        # Sort tracks by framenumber
        df_out = df_out.sort_values(by=[0], ascending=[True])
        df_out.to_csv(path_or_buf=join(result_path, "tracks.csv"),
                      sep=';',
                      header=False,
                      index=False)
        print(("Wrote tracks to %s"%(join(result_path, "tracks.csv"),)))
    runtime = watch.stop()
    logging.info("Runtime: %s", runtime)
    print(("Runtime: %s"%(runtime,)))

def main():
    parser = argparse.ArgumentParser(description='Run Two-Stage-Graph algorithm.')
    parser.add_argument('--detections', nargs='?', default=detections, action='store',
                        help='Path to detection folder.')
    parser.add_argument('--out', nargs='?',default=out, action='store',
                        help='Path to output folder.')
    parser.add_argument('--debug', nargs='?', default=debug, action='store',
                        help='Start script in debung mode. Can be "true" or "false". [false]')
    parser.add_argument('--img_in', nargs='?',default=img_in, action='store',
                        help='Path to folder with folders of images for each video.')
    parser.add_argument('--config_file', nargs='?', default=config_file, action='store',
                        help='Path to a config_file')
    args = parser.parse_args()
    run(args.detections, args.out, args.img_in, args.config_file, args.debug)
    """
    if args.debug is None:
        debug = False
    else:
        debug = 'true' == args.debug.lower()

    if debug:
        logging.basicConfig(filename=join(args.out,"tsgrgbhist_log.txt"),
                            level=logging.DEBUG)
    else:
        logging.basicConfig(filename=join(args.out,"tsgrgbhist_log.txt"),
                            level=logging.INFO)

    if not os.path.exists(args.out):
        os.mkdir(args.out)

    watch = stopwatch.Stopwatch(print_time=False)
    watch.start()

    twostage_tracker = Feat2StageAlg(config_file=args.config_file)

    for detection_file in os.listdir(args.detections):
        print(("Compute tracks for detection file: %s"%(detection_file,)))
        video_name = detection_file.split('.')[0]
        video_imgs_in = join(args.img_in, video_name)
        result_path = join(args.out, video_name)
        if not os.path.exists(result_path):
            os.mkdir(result_path)
        in_file = join(args.detections, detection_file)
        df = pd.read_csv(in_file, names=['frame', 'xc', 'yc', 'w', 'h'])
        bb_list = df[['xc','yc','w','h']].values.tolist()
        frames = df['frame'].values.tolist()

        twostage_tracker = Feat2StageAlg(config_file=args.config_file)
        if twostage_tracker.W_APP > 0.0:
            print("Start computing Features")
            if debug:
                X = compute_features(video_imgs_in, df)
            else:
                X = compute_features(video_imgs_in, df)
            print("Computed Features!")
        else:
            X = None

        print("Start computing tracks")
        tracks = twostage_tracker.run(bb_list, frames, X)
        print("Computed Tracks")
        df_out = pd.DataFrame(tracks)
        if debug:
            print("Start visualizing tracks")
            img_out_path = join(result_path, 'images')
            if not os.path.exists(img_out_path):
                os.mkdir(img_out_path)
            img_set = ImageSet(video_imgs_in, load_option='all')
            for frame_id, img in enumerate(img_set.image_gen()):
                # Get all bboxes for this frame
                img_w = img.shape[1]
                img_h = img.shape[0]
                df_frame = df_out.loc[df_out[0] == frame_id]
                bb_list = df_frame.ix[:,2:6].values
                bb_list = bboxes.bb_convert(bb_list,
                                            in_format="rel[xc,yc,w,h]",
                                            out_format="abs[xtl,ytl,w,h]",
                                            img_w=img_w,
                                            img_h=img_h)
                # Labels are track_id
                labels = df_frame.ix[:,1].values
                out_img = visualise.draw_bbox_color_by_index(img, bb_list,
                                                             label_list=labels)
                cv2.imwrite(join(img_out_path, "%06d.png"%(frame_id)), out_img)
            print("Finished track visualization")
        # df_out[[2,3,4,5]] = pd.DataFrame(bboxes.bb_rel_to_abs(
        #     df_out.ix[:,2:6].values, IMG_WIDTH, IMG_HEIGHT).tolist())

        # Add one to track_id since matlab cannot deal with index 0.
        df_out.loc[:,1] += 1
        # Sort tracks by framenumber
        df_out = df_out.sort_values(by=[0], ascending=[True])
        df_out.to_csv(path_or_buf=join(result_path, "tracks.csv"),
                      sep=';',
                      header=False,
                      index=False)
        print(("Wrote tracks to %s"%(join(result_path, "tracks.csv"),)))
    runtime = watch.stop()
    logging.info("Runtime: %s", runtime)
    print(("Runtime: %s"%(runtime,)))

   """

if __name__ == "__main__":
    main()
