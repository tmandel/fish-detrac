'''
Created on Oct 12, 2015

@author: jonas
'''
import os
import cv2
from . import label_translator
import logging

class ImageSet(object):
    """A set of Image objects.

    Attributes:
        folder_path: Path to the folder with the images.
        load_option: Defines the way how images are loaded from filepath
            by the image_gen method.
            'cbd' ClassByDirname:
                Generates an ImageSet with class label from a dir structure.
                All images of an class should be in one folder named with a
                number that represents the class.
            'all':
                Load all images from folder.
        translator: Translation table from folder names to ids
    """

    def __init__(self, folder_path, load_option='cbd'):
        self.folder_path = folder_path
        self.load_option = load_option
        self.translator = label_translator.LabelTranslator()

    def image_gen(self):
        """A generator method for loading images form file system.

        For more information on the load_option see class comment.

        Returns:
            A generator for for (ocv_img, true_label) or (ocv_img).
            Depending on load_option.
        """
        if self.load_option == 'cbd':
            for (dirpath, dirnames, filenames) in os.walk(self.folder_path):
                for f in filenames:
                    if f.endswith(".jpg") or f.endswith(".png"):
                        filepath = os.path.join(dirpath, f)
                        img = cv2.imread(filepath)
                        dirname = os.path.split(dirpath)[-1]

                        try:
                            true_label = int(dirname)
                        except ValueError:
                            true_label=self.translator.get_id(dirname)
                        yield img, true_label
                    else:
                        logging.warning("image_gen: No image file: {}".format(f))
        elif self.load_option == 'all':
            to_id= 0
            for filename in sorted(os.listdir(self.folder_path)):
                filepath = os.path.join(self.folder_path, filename)
                img = cv2.imread(filepath)
                yield img
        else:
            logging.error("Unknown load_option.")

    def get_img_label(self):
        l_img, l_label = list(), list()
        for img, label in self.image_gen():
            l_img.append(img)
            l_label.append(label)
        return l_img, l_label

#     def get_img_ocv_gt(self):
#         """Get get 3 lists: Image, OpenCV-Image, GroundTruth-Labels
#
#         Returns:
#             A tuple of lists:
#                 (Images, OpenCV-Images, GT-Labels)
#         """
#         image_array = list()
#         ocv_img_array = list()
#         gt_label_array = list()
#         for image in self.image_gen():
#             image_array.append(image)
#             ocv_img_array.append(image.data)
#             gt_label_array.append(image.true_label)
#         return image_array, ocv_img_array, gt_label_array
#
#     def next_img_ocv_gt(self, n):
#         """Get an iterator for 3 lists: Image, OpenCV-Image,
#         GT-Labels
#
#         Parameter:
#             n: Maximum number of images to return in one iteration per list.
#
#         Returns:
#             An iterator for a tuble of lists:
#                 (Images, OpenCV-Images, GT-Labels)
#         """
#         image_array = list()
#         ocv_img_array = list()
#         gt_label_array = list()
#         i = 0
#         img_gen = self.image_gen()
#         for image in img_gen:
#             i += 1
#             image_array.append(image)
#             ocv_img_array.append(image.data)
#             gt_label_array.append(image.true_label)
#             if i >= n:
#                 i = 0
#                 yield image_array, ocv_img_array, gt_label_array
#         yield image_array, ocv_img_array, gt_label_array

    def __str__(self):
        s  = "ImageSet:\n"
        s += "    folder_path: {}\n".format(self.folder_path)
        s += "    load_option: {}\n".format(self.load_option)
        s += str(self.translator)
        return s

class Video(object):
    """A class to load and work on video streams

    Attributes:
        __video: The video stream which is an OpenCV VideoCapture object.
        video_meta: Metadata of this video.
    """

    def __init__(self, file_path):
        """Init.

        Args:
            file_path: A string that indicates the path to the video file in
                file-system.
        """
        self.__cap = cv2.VideoCapture(file_path)
        self.framenumber = -1

    def get_frame_gen(self):
        self.framenumber = -1

        if self.__cap:
            while True:
                ret, frame = self.__cap.read()
                if not ret:
                    break
                self.framenumber += 1
                yield frame
        else:
            logging.warning("Need to load video first.")

    def get_frame(self, framenumber):
        self.__cap.set(1, framenumber)
        ret, frame = self.__cap.read()
        if not ret:
            frame = None
        return frame
