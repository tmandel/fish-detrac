# Date: Friday 02 June 2017 05:04:00 PM IST
# Email: nrupatunga@whodat.com
# Name: Nrupatunga
# Description: Basic regressor function implemented

from __future__ import print_function
from ..helper.image_proc import cropPadImage
from ..helper.BoundingBox import BoundingBox
from ..logger.logger import setup_logger
from ..network.regressor import regressor
from ..loader.loader_vot import loader_vot
from ..tracker.tracker import tracker
from ..tracker.tracker_manager import tracker_manager


class GOTURNTracker:
    """Simple GOTURN tracker class"""

    def __init__(self, prototxtPath, modelPath, gpuID=0):
        self.logger = setup_logger(logfile=None)

        do_train = False
        self.objRegressor = regressor(prototxtPath, modelPath, gpuID, 1, do_train, self.logger)

    def init(self, image_curr, bbox_wh):
        """ initializing the first frame in the video
        """
        (x,y,w,h) = bbox_wh
        (x1,y1,x2,y2) = (x,y,x+w,x+h)
        bbox_gt = BoundingBox(x1,y1,x2,y2)
        self.image_prev = image_curr
        self.bbox_prev_tight = bbox_gt
        self.bbox_curr_prior_tight = bbox_gt
        # objRegressor.init()

    def update(self, image_curr):
        """TODO: Docstring for tracker.
        :returns: TODO

        """
        target_pad, _, _,  _ = cropPadImage(self.bbox_prev_tight, self.image_prev)
        cur_search_region, search_location, edge_spacing_x, edge_spacing_y = cropPadImage(self.bbox_curr_prior_tight, image_curr)

        bbox_estimate = self.objRegressor.regress(cur_search_region, target_pad)
        bbox_estimate = BoundingBox(bbox_estimate[0, 0], bbox_estimate[0, 1], bbox_estimate[0, 2], bbox_estimate[0, 3])

        # Inplace correction of bounding box
        bbox_estimate.unscale(cur_search_region)
        bbox_estimate.uncenter(image_curr, search_location, edge_spacing_x, edge_spacing_y)

        self.image_prev = image_curr
        self.bbox_prev_tight = bbox_estimate
        self.bbox_curr_prior_tight = bbox_estimate
        
        reformattedBox = (int(bbox_estimate.x1), int(bbox_estimate.y1), int(bbox_estimate.x2)-int(bbox_estimate.x1), int(bbox_estimate.y2)-int(bbox_estimate.y1))

        return (True, reformattedBox) #True means we never lose track
