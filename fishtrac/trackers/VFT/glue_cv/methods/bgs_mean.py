import numpy as np
import cv2

class BgsMean(object):
    """Background Substraction based on mean image.
    
    Attributes:
        init_gen: A generator for frames.
        init_frames: Number of frames used for mean image calculation.
        debug: True if debug images should be shown.
        threshold: Lower threshold to generate binary mask.
        upper_threshold: Upper threshold to generate binar mask form
            grayscale image.
        method: Chose method for mean image generation.
            'mode' -> Median value of all init frames for each pixel.
            'average' -> Average value of all init frames for each pixel.
        bi_sigma: Sigma parameter of bilateral filter.
        bi_mask_size: Neighbourhood type for bilateral filtering.
    """
    def __init__(self, init_gen=None, init_frames=500, threshold=80, 
                 debug=False, method="mode", upper_threshold=200,
                 bi_sigma=100, bi_mask_size=5):
        self.init_gen = init_gen 
        self.init_frames = init_frames
        self.mean_img = None
        self.debug = debug
        self.threshold = threshold
        self.method = method
        self.upper_threshold = upper_threshold
        self.bi_sigma = bi_sigma
        self.bi_mask_size = bi_mask_size
        
    def compute_mean(self):
        """Compute mean image from init_gen
                
        Returns:
            A numpy image in opencv format. 
        """
        if self.method=="average":
            return self.__compute_mean_average()
        elif self.method=="mode":
            return self.__compute_mean_mode()
        else:
            raise Exception("method need to be either 'mode' or 'average'!")
    
    def __compute_mean_mode(self):
        count = None
        shape = None
        for f in self.init_gen:
            if self.debug:
                cv2.imshow('Current init image', f.data)
                cv2.waitKey(1)
            if f.image_id >= self.init_frames:
                break
            shape = f.data.shape
            if self.mean_img is None:
                self.mean_img = np.zeros(f.data.shape, np.uint8)
            if count is None:
                count = np.zeros((f.data.shape + (256,)))
            #count frequency of color values for each frame 
            for i in range(f.data.shape[0]):
                for j in range(f.data.shape[1]):
                    value = count.item((i,j,0,f.data.item(i,j,0))) + 1
                    count.itemset((i,j,0,f.data.item(i,j,0)), value)
                    value = count.item((i,j,1,f.data.item(i,j,1))) + 1
                    count.itemset((i,j,1,f.data.item(i,j,1)), value) 
                    value = count.item((i,j,2,f.data.item(i,j,2))) + 1
                    count.itemset((i,j,2,f.data.item(i,j,2)), value) 
        for i in range(shape[0]):
            for j in range(shape[1]):
                max_val = np.argmax(count[i,j,0])
                self.mean_img.itemset((i,j,0), max_val)
                max_val = np.argmax(count[i,j,1])
                self.mean_img.itemset((i,j,1), max_val)
                max_val = np.argmax(count[i,j,2])
                self.mean_img.itemset((i,j,2), max_val)
#         self.mean_img = cv2.GaussianBlur(self.mean_img, (5,5), 0)
        self.mean_img = cv2.bilateralFilter(self.mean_img,self.bi_mask_size,self.bi_sigma,self.bi_sigma)
        return self.mean_img
        
    def __compute_mean_average(self):
        counter = 0
        for f in self.init_gen:
            if self.mean_img is None:
                self.mean_img = np.zeros(f.data.shape, np.float64)
            self.mean_img += f.data
            counter += 1
            if counter == self.init_frames:
                break
        self.mean_img /= counter
        self.mean_img = self.mean_img.astype(np.uint8)
        if self.debug:
            cv2.imshow("Mean image", self.mean_img)
        self.mean_img = cv2.bilateralFilter(self.mean_img,self.bi_mask_size,self.bi_sigma,self.bi_sigma)
        return self.mean_img
    
    def __sum_of_squares_dist(self, diff_img):
        b = diff_img[:,:,0]
        g = diff_img[:,:,1]
        r = diff_img[:,:,2]
        res = np.zeros((diff_img.shape[0], diff_img.shape[1]))
        res = b*b + g*g + r*r
        return res.astype(np.uint8)
        
    def compute(self, frame):
        """Compute diff image (mean - current_frame).    
        
        Args:
            frame: A rproto.blob_model.Frame.
        
        Returns:
            An opencv binary image containing a diff mask.
        """
        if self.mean_img is None:
            self.compute_mean()
        in_img = frame.data
#         in_img = cv2.bilateralFilter(in_img,9,150,150)
#         in_img = cv2.GaussianBlur(in_img, (5,5), 0)
        result = np.absolute(in_img - self.mean_img)
#         result = self.__sum_of_squares_dist(result)
        result = cv2.cvtColor(result, cv2.COLOR_BGR2GRAY)
#         result = cv2.bilateralFilter(result,5,75,75)
#         result = cv2.equalizeHist(result)
        result = cv2.bilateralFilter(result,self.bi_mask_size,self.bi_sigma,self.bi_sigma)
        if self.debug:
            cv2.imshow("Grayscale: Frame - Mean", result)
#         ret,result = cv2.threshold(result, self.threshold, 255, cv2.THRESH_BINARY)
#         ret, result = cv2.threshold(result,self.threshold,255,cv2.THRESH_BINARY+cv2.THRESH_OTSU)
        result = cv2.inRange(result, self.threshold, self.upper_threshold)
#         result = cv2.adaptiveThreshold(result,255,cv2.ADAPTIVE_THRESH_GAUSSIAN_C, cv2.THRESH_BINARY,5,2)
#         result = cv2.bilateralFilter(result,9,75,75)
        result = cv2.medianBlur(result, 3)
        if self.debug:
            cv2.imshow("Binary: Frame - Mean", result)
            cv2.imshow("Image", in_img)
            cv2.waitKey(200)
        return result
    
    def __str__(self):
        s = "BgsMean:\n"
        s += "    method:             {}\n".format(self.method)
        s += "    init_frames:        {}\n".format(self.init_frames)
        s += "    threshold:          {}\n".format(self.threshold)
        s += "    upper_threshold:    {}\n".format(self.upper_threshold)
        s += "    bi_sigma:           {}\n".format(self.bi_sigma)
        s += "    bi_mask_size:       {}\n".format(self.bi_mask_size)
        s += "    debug:              {}".format(self.debug)
        
        return s
