'''
Created on Apr 7, 2016

@author: jj
'''
import numpy as np
import logging

def bb_convert(bb_in, in_format, out_format, img_w=None, img_h=None):
    '''Convert bboxes in one format to another format.

    Possible formats for in_format and out_format are:
        "rel[xc,yc,w,h]": xc,yc define the center of a
            bounding box with width w and height h (values are relative
            to image). One row in bb_in should look like [xc,yc,w,h].
        "abs[xtl,ytl,w,h]": xtl, ytl define the top left corner of a bbox
            with height h and width w (values are absolute in pixels).
        "abs[xtl,ytl,xbr,ybr]": xtl, ytl define the top left corner of a bbox
            and xbr,ybr define the bottom right corner (values are absolute in
            pixels).
    Args:
        bb_in (ndarray): A numpy array with bboxes to transform.
            The array should contain one bbox per row: [[bbox], [bbox], ...]
        in_format (str): The format of bb_in.
        out_format (str): The desired out_format.
        img_w (int): Width of the related image. Only required if a relative format
            should be transformed to an absolute format or vice versa.
        img_h (int): Width of the related image. Only required if a relative format
            should be transformed to an absolute format or vice versa.

    Returns:
        bb_out: A numpy array with bboxes in out_format.
    '''
    if in_format == "rel[xc,yc,w,h]" and out_format == "abs[xtl,ytl,w,h]":
        if img_w is None or img_h is None:
            raise Exception(("Transformation from relative format to absolute"
                             " format requires img_w and img_h"))
        bb_out = bb_in.copy()
        # Relative to absolute
        bb_out[:,[0,2]] = bb_in[:,[0,2]] * img_w
        bb_out[:,[1,3]] = bb_in[:,[1,3]] * img_h
        w = bb_out[:,2]
        h = bb_out[:,3]
        if len(w[w <= 0]) > 0:
            logging.warning("glue_cv.bboxes.bb_convert: bbox width <= 0!")
        if len(h[h <= 0]) > 0:
            logging.warning("glue_cv.bboxes.bb_convert: bbox height <= 0!")
        #xc,yc to xtl,ytl
        #xtl = xc - w/2
        bb_out[:,0] = bb_out[:,0] - bb_out[:,2] / 2
        #xtl should not be smaler than zero.
        xtl = bb_out[:,0]
        if len(xtl[xtl < 0]) > 0:
            logging.warning(("glue_cv.bboxes.bb_convert: xtl is smaller than"
                             " zero. I set it to zero."))
            xtl[xtl < 0] = 0
        #ytl = yc - h/2
        bb_out[:,1] = bb_out[:,1] - bb_out[:,3] / 2
        #ytl should not be smaller than zero.
        ytl = bb_out[:,1]
        if len(ytl[ytl < 0]) > 0:
            logging.warning(("glue_cv.bboxes.bb_convert: ytl is smaller than"
                             " zero. I set it to zero."))
            ytl[ytl < 0] = 0
        # Absolute values should be int
        bb_out = bb_out.astype(int)
    elif in_format == "abs[xtl,ytl,xbr,ybr]" and out_format == "rel[xc,yc,w,h]":
        raise NotImplementedError()
    return bb_out

def bb_rel_to_abs(bb_in, img_w, img_h):
    bb_out = bb_in.copy()
    bb_out[:,[0,2]] = bb_in[:,[0,2]] * img_w
    bb_out[:,[1,3]] = bb_in[:,[1,3]] * img_h
    bb_out = bb_out.astype(int)
    return bb_out

def bb_abs_to_rel(bb_in, img_w, img_h):
    '''Convert bboxes in absolute format to relative format.

    Args:
        bb_in (numpy array): BBoxes in format. x,y,w,h or x1,y1,x2,y2
        img_w (int): Image width in pixels.
        img_h (int): Image heiht in pixels.

    Returns:
        BBoxes in relative format.
    '''
    bb_out = bb_in.copy()
    bb_out[:,[0,2]] = bb_in[:,[0,2]] / img_w
    bb_out[:,[1,3]] = bb_in[:,[1,3]] / img_h
    # bb_out = bb_out.astype(int)
    return bb_out

def bbox_yxyx_to_xywh(yxyx):
    """Convert bbox (y1 x1 y2 x2) to (x1 y1 width height)

    Args:
        yxyx: Tuble in format (y1, x1, y2, x2)

    Returns:
        Tuple in format (x1, y1, width, height)
    """
    return yxyx[1], yxyx[0], yxyx[3]-yxyx[1], yxyx[2]-yxyx[0]

def bbox_to_xyxy(xywh):
    return (xywh[0], xywh[1], xywh[0]+xywh[2], xywh[1]+xywh[3])

def bbox_to_rel(img_size, box):
    """Convert a bbox in absolute format to relative format.

    Args:
        img_size: Image size in pixels(width, height)
        box: Absolute bbox in pixels (x, y, w, h)

    Returns:
        (x,y,w,h) bbox in relative format.
    """
    dw = 1./img_size[0]
    dh = 1./img_size[1]
    x = box[0] + box[2] / 2.0
    y = box[1] + box[3] / 2.0
    w = float(box[2])
    h = float(box[3])
    x = x*dw
    w = w*dw
    y = y*dh
    h = h*dh
    return (x,y,w,h)

def xywh_to_xcycwh(bbox):
    '''Convert bbox (xtl,ytl,w,h) to (xc,yc,w,h)

    Args:
        bbox (numpy array): [[xtl,ytl,w,h],[xtl,ytl,w,h],...]

    Returns:
        [[xc,yc,w,h],[xc,yc,w,h],...]
    '''
    bbout = bbox.copy()
    bbout[:,0] = bbox[:,0] + bbox[:,2]/2
    bbout[:,1] = bbox[:,1] + bbox[:,3]/2
    return bbout

def bbox_to_cbbox(bbox):
    '''Convert bbox (x,y,w,h) to (xc,yc,w,h)

    Args:
        bbox: (x,y,w,h) format absolute in pixels.

    Returns:
        (xc,yc,w,h) absolute in pixels.
    '''
    x_out = bbox[0] + bbox[2]/2
    y_out = bbox[1] + bbox[3]/2
    return (x_out, y_out, bbox[2], bbox[3])

def bb_intersec_area(bb_0, bb_1):
    w_ia = max(0, min(bb_0[0] + bb_0[2], bb_1[0] + bb_1[2]) - max(bb_0[0], bb_1[0]))
    h_ia = max(0, min(bb_0[1] + bb_0[3], bb_1[1] + bb_1[3]) - max(bb_0[1], bb_1[1]))
    return w_ia * h_ia

def bb_union_area(bb_0, bb_1):
    a_u = float(bb_0[2]) * bb_0[3] + bb_1[2] * bb_1[3]
    a_u = a_u - bb_intersec_area(bb_0, bb_1)
    return a_u

def iou(bb_0, bb_1):
    """ Intersection over Union.
    iou = bb_p and bb_gt / bb_p or bb_gt
    """
    return bb_intersec_area(bb_0, bb_1) / bb_union_area(bb_0, bb_1)

def contains(bb_0, bb_1, threshold=1.0):
    """Check if bb_0 contains bb_1

    If 'threshold != 1.0', this method checks whether bb_1 is at least
    contained in bb_0 for a certain percentage controled by 'threshold'
    argument.
    For example, if 'threshold = 0.9':
    The method will check if at least 90% of the area of bb_1 are contained
    in bb_0.

    Args:
        bb_0: (x1, y1, width, height)
        bb_1: (x1, y1, width, height)
        threshold: A float number in range 0...1

    Returns:
        True if bb_0 contains bb_1
    """
    intersec = bb_intersec_area(bb_0, bb_1)
    bb_1_area = bb_1[2] * bb_1[3]

    return intersec >= (bb_1_area * threshold)

def non_max_supression(bb_list, conf_list, thresh=0.7):
    """Non max supression by bbox detechtion confidence.

    Args:
        bb_list: List of bboxes in format (x,y,w,h)
        conf_list: A float list of detection confidences for each bbox.
        thresh: Threshold for overlap. E.g. if iou of bb1 and bb2
            is greater than or equal to thres, then it is
            considered that bb1 and bb2 have detected the same
            object.

    Returns:
        A numpy array with idxs of max bboxes.

        To get list of bboxes from returned idxs you can do the
        following:
            bboxes = np.array(bb_list)
            max_bbs = bboxes[unique_max].tolist()
    """
    if bb_list is not None and len(bb_list) > 0:
        #1. find all overlaps for each box and save detection confidence
        # in a matrix.
        o_arr = np.zeros((len(bb_list), len(bb_list)))
        for idx1, bb1 in enumerate(bb_list):
            for idx2, bb2 in enumerate(bb_list):
                if iou(bb1, bb2) >= thresh:
                    o_arr[idx1,idx2] = conf_list[idx2]

        #2. for each bbox get the index of an overlapping bbox with max confidence
        max_overlap = np.argmax(o_arr, axis=1)

        #3. filter multiple entries of same max bbox
        unique_max = np.unique(max_overlap)

#         #4. get max bboxes
#         bboxes = np.array(bb_list)
#         max_bbs = bboxes[unique_max].tolist()
#         conf_arr = np.array(conf_list)
#         max_confs = conf_arr(unique_max).tolist()
    else:
        return None

    return unique_max
