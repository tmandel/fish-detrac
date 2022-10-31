'''
Created on Oct 2, 2015

@author: jonas
'''
import numpy as np
from sklearn.metrics import confusion_matrix
import cv2
import os


def compute_accuracy(cm):
    """Compute accuracy for confusion matrix
    
    Args:
        cm: sklearn confusion matrix.
    
    Returns:
        (MeanAveragePrecision, Accuracy)
    """
    acc = cm.diagonal().sum(dtype=np.float32)/cm.ravel().sum()
    cm_norm = cm / cm.sum(axis=1,keepdims=True, dtype=np.float32)
    mean_ap = np.nanmean(cm_norm.diagonal())

    return (mean_ap, acc)

def normalise_cm(cm):
    """Normalise confusion matrix.
    
    Args:
        cm: sklearn confusion matrix
    
    Returns:
        Normalised confusion matrix
    """
    cm_norm = cm / cm.sum(axis=1,keepdims=True, dtype=np.float32)
    return cm_norm


def voc_average_precision(p, r):
    """Calculates the average precision in pascal voc style.
    
    Args:
        p: precision
        r: recall
    
    Returns:
        A float number indicating the average precision.
    
    """
    pre = np.hstack((p,0))
    pre_plus1 = np.hstack((0,p))
    mr = np.hstack((0,r,1))
    
    #Get max(p[i],p[i+1]) for all p[i]
    mp = np.vstack((pre,pre_plus1))
    mp = np.amax(mp, axis=0)
    mp = np.hstack((mp,0))
    
    #
    i = np.where(mr[1:] != mr [0:-1])[0] + 1
#     mr = mr[i]
    ap = np.sum((mr[i] - mr[i-1])*mp[i])
    
    return ap
    
    
# def eval_pr_curve_tptnfpfn(gt_img, p_img, check_class=True, step_size=0.01, start_confidence=0):
#     """Eval tp, tn, fp, fn for a single image to generate a precision-recall curve.
#     
#     Args:
#         gt_img: An image with ground truth bboxes.
#         p_img: An image predicted bounding boxes that should be evaluated.
#         check_class: Check if class label of groundtruth bbox is equal to
#             predicted bbox.
#     
#     Returns:
#         numpy.array of shape 4 X number of confidence levels.
#         Columns are (tp, tn, fp, fn).
#     """
#     original_list = p_img.target_objects
#     bb_list = list(p_img.target_objects)
#     res = np.empty(shape=[0, 4])
# #     if len(p_img.target_objects) > 0 and p_img.target_objects[0].detection_confidence is None:
# #         tmp = np.array(eval_detection_pascal_voc(gt_img, p_img, check_class))
# #         res = np.vstack((res, tmp))
# #     else: 
#     for conf in np.arange(start_confidence,1.0, step_size):
#         bb_list = [bb for bb in bb_list if bb.detection_confidence is None or bb.detection_confidence >= conf]
#         p_img.target_objects = bb_list
#         tmp = np.array(eval_detection_pascal_voc(gt_img, p_img, check_class))
#         res = np.vstack((res, tmp))
#     p_img.target_objects = original_list
#     return res

def eval_pr_curve_values(tptnfpfn_mat):
    tp = tptnfpfn_mat[:,0]
    fp = tptnfpfn_mat[:,2]
    fn = tptnfpfn_mat[:,3]
    
    p = tp / (tp + fp)
    r = tp / (tp + fn)
    #reverse order so that recall is running from 0...1
    p = np.flipud(p)
    r = np.flipud(r)
    return p, r  
    
# def eval_detection_pascal_voc(gt_img, p_img, check_class=True, 
#                               debug=False, debug_folder=None):
#     """Evaluate detection accuracy in a PASCAL VOC like manner.
#  
#     see: Everingham 2015 - "The PASCAL Visual Object Classes Challenge:
#                             A Retrospective"
#     Args:
#         gt_img: An image with ground truth bboxes.
#         p_img: An image predicted bounding boxes that should be evaluated.
#         check_class: Check if class label of groundtruth bbox is equal to
#             predicted bbox.
#         debug: run in debug mode if True.
#         debug_folder: A folder where where debug results are stored.
#     Returns:
#         Tuple: (true positive, true negative, false positive, false negative)
#     """
#     tp, fp, fn, tn = 0, 0, 0, 0
#     gt_overlap_count = {}
#     p_overlap_count = {}
#     for bb_p in p_img.target_objects:
#         p_overlap_count[bb_p] = 0
#         
#     for bb_gt in gt_img.target_objects:
#         gt_overlap_count[bb_gt] = 0
#         for bb_p in p_img.target_objects:
#             if bboxes.iou(bb_gt, bb_p) > 0.5:
#                 if debug:
#                     print (" gt: {}\n p: {}\n overlap: {}\n"
#                            .format(bb_gt.blob_id, bb_p.blob_id, bboxes.iou(bb_gt, bb_p)))
#                 if check_class:
#                     if bb_p.pred_label == bb_gt.true_label:
#                         gt_overlap_count[bb_gt] += 1
#                         p_overlap_count[bb_p] += 1
#                 else:
#                     gt_overlap_count[bb_gt] += 1
#                     p_overlap_count[bb_p] += 1
#  
#     for gt_val in gt_overlap_count.itervalues():
#         if gt_val == 0:
#             fn += 1
#         elif gt_val == 1:
#             tp += 1
#         else:
#             fp += gt_val - 1
#             tp += 1
#     for p_val in p_overlap_count.itervalues():
#         if p_val == 0:
#             fp += 1
#     if len(gt_img.target_objects) == 0 and len(p_img.target_objects) == 0:
#         tn += 1
#      
#     if debug:
#         debug_img = visualise.draw_bbox_img(gt_img, p_img)
#         debug_gt = visualise.draw_bbox_img(gt_img=gt_img)
#         debug_p = visualise.draw_bbox_img(p_img=p_img)
#         if debug_folder is not None:
#             if isinstance(gt_img, Frame):
#                 gt_img_filename = gt_img.blob_id.split(';')[1] + ".png"
#             elif isinstance(gt_img, Image):
#                 gt_img_path = gt_img.blob_id.split(';')[1]
#                 gt_img_filename = os.path.basename(gt_img_path)
#             debug_img_path = os.path.join(debug_folder, gt_img_filename)
#             if not os.path.exists(debug_folder):
#                 os.makedirs(debug_folder)
#             cv2.imwrite(debug_img_path, debug_img)
#             with open(os.path.join(debug_img_path+".log"), 'a') as f:
#                 debug_str = "{}\n\n".format(debug_img_path)
#                 debug_str += "tp: {}\n".format(tp)
#                 debug_str += "tn: {}\n".format(tn)
#                 debug_str += "fp: {}\n".format(fp)
#                 debug_str += "fn: {}\n".format(fn)
#                 f.write(debug_str)
#         else:
#             cv2.imshow("BBoxes on one image (eval_detection_pascal_voc)", debug_img)
#             cv2.imshow("Ground Truth BBoxes (eval_detection_pascal_voc)", debug_gt)
#             cv2.imshow("Predicted BBoxes (eval_detection_pascal_voc)", debug_p)
#             cv2.waitKey(100)
#  
#     return tp, tn, fp, fn

def get_pascal_voc_pra(tp_tn_fp_fn):
    """Get precision, recall, accuracy
    
    Args:
        tp_tn_fp_fn: A Tuple of (tp, tn, fp, fn)
    
    Returns:
        (precision, recall, accuracy)
    """
    tp, tn, fp, fn = tp_tn_fp_fn
    if (tp + fp) != 0:
        precision = float(tp) / (tp + fp)
    else:
        precision = 0 
     
    if (tp + fn) != 0:
        recall = float(tp) / (tp + fn)
    else:
        recall = 0
     
    if (tp+tn+fp+fn) != 0:
        accuracy = (float(tp) + tn) / (tp + tn + fp + fn)
    else:
        accuracy = 0
    return precision, recall, accuracy

