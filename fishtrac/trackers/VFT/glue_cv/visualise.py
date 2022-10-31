'''
Created on Jan 4, 2016

@author: jonas
'''
import cv2

rgb_look_up = list()
rgb_look_up.append((255,0,0))
rgb_look_up.append((0,255,0))
rgb_look_up.append((0,0,255))
rgb_look_up.append((255,255,0))
rgb_look_up.append((255,0,255))
rgb_look_up.append((0,255,255))
rgb_look_up.append((255,255,255))
rgb_look_up.append((128,0,0))
rgb_look_up.append((0,128,0))
rgb_look_up.append((0,0,128))
rgb_look_up.append((128,255,0))
rgb_look_up.append((128,0,255))
rgb_look_up.append((0,128,255))
rgb_look_up.append((255,128,0))
rgb_look_up.append((255,0,128))
rgb_look_up.append((0,255,128))
rgb_look_up.append((128,128,0))
rgb_look_up.append((128,0,128))
rgb_look_up.append((0,128,128))



def draw_bbox_img(ocv_img, bb_list_gt=None, bb_list_p=None, gt_color=(255,0,0), p_color=(0,0,255), line_width=1):
    """Draws an image with bboxes.

    If p_img is None, only bboxes of gt_img will be drawn.

    Args:
        gt_img: The image with ground truth bboxes (ocv_imgae).
        p_img: The image with predicted bboxes.
        gt_color: Color for ground truth bboxes.
        p_colot: Color for predicted bboxes.
        line_width: The line width for the bboxes.

    Returns:
        Returns an opencv bgr image with drawn bboxes.
    """
    img = ocv_img.copy()

    if bb_list_gt is not None:
        for bb in bb_list_gt:
            cv2.rectangle(img,
                          (bb[0], bb[1]),
                          (bb[0]+bb[2], bb[1]+bb[3]),
                          gt_color,
                          line_width
                          )
    if bb_list_p is not None:
        for bb in bb_list_p:
            cv2.rectangle(img,
                          (bb[0], bb[1]),
                          (bb[0]+bb[2], bb[1]+bb[3]),
                          gt_color,
                          line_width
                          )
    return img

def draw_bbox_color_by_index(ocv_img, bb_list, line_width=1, label_list=None,
                             font=cv2.FONT_HERSHEY_SIMPLEX, font_scale=2,
                             text_thickness=2):
    """Draws an image with bboxes and colors bbox based on label or list index.

    Args:
        ocv_image: Image in opencv format.
        bb_list: list of tuples (xtl,ytl,width,height). All values are assumed
            to be absolute in pixels.
        line_width: [1] The line width for the bboxes.
        write_bb_idx: [True] Writes index of bbox in bb_list into image.
        label_list: List of corresponding bbox labels.
    Returns:
        Returns an opencv bgr image with drawn bboxes.
    """
    img = ocv_img.copy()

    for idx, bb in enumerate(bb_list):
        if bb is not None:
            if label_list is not None:
                # If label is a number, map label to constant color in look_up
                try:
                    label = int(label_list[idx])
                    color_idx = label % len(rgb_look_up)
                    color = rgb_look_up[color_idx]
                # If label is no number, map bbox list index to color.
                except ValueError:
                    color = rgb_look_up[idx]
                    label = label_list[idx]
            else:
                # If no label_list, map bbox list index to color.
                color = rgb_look_up[idx]
                label = idx
            cv2.rectangle(img,
                          (bb[0], bb[1]),
                          (bb[0]+bb[2], bb[1]+bb[3]),
                          color,
                          line_width)
            cv2.putText(img, str(label), (bb[0],bb[1]+bb[3]), font,
                        font_scale, color, text_thickness, cv2.LINE_AA)
    return img
