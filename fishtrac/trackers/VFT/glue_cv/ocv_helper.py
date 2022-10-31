'''
Created on Dec 9, 2015

@author: jonas
'''
import cv2


def crop_bbox_list(img, bb_list):
    bb_img_list = list()
    for bb in bb_list:
        bb_img_list.append(crop_box(img, bb))
    return bb_img_list

def crop_box(img, rect):
    """Get a copy of the image part described by a bounding rectangle.

    Args:
        img: OpenCV bgr image.
        rect: Tuple (xtl, ytl, width, height) that describes the bounding
            rectangle. A values are considered as absolute in pixels.

    Returns:
        An OpenCV bgr image
    """
    img_out = img[rect[1]:rect[1]+rect[3], rect[0]:rect[0]+rect[2]].copy()
    h,w,foo = img_out.shape
    if h <= 0:
        raise Exception(("glue_cv.ocv_helper.crop_box: Image height can not be"
                         " smaller or equal to zero"))
    if w <= 0:
        raise Exception(("glue_cv.ocv_helper.crop_box: Image width can not be"
                         " smaller or equal to zero"))
    return img_out

def get_img_size(img):
    """Get width and height of an imageself.

    Args:
        img: The image to get size from.

    Returns:
        A Tuple: (height, width)

    Raises:
        IOError: An error occurred accessing the bigtable.Table object.
    """
    height, width = img.shape[:2]
    return height, width
