#!/usr/bin/env python

"""
Copyright 2017-2018 Fizyr (https://fizyr.com)

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.

Updated 6/24/2019 by Max Panoff to use different bounds on random transforms
"""

import argparse
import os
import sys
import warnings
import math
import inspect


def import_subfolder(subfolder):
    # Use this if you want to include modules from a subfolder
    cmd_subfolder = os.path.realpath(
        os.path.abspath(os.path.join(os.path.split(inspect.getfile(inspect.currentframe()))[0], subfolder)))
    if cmd_subfolder not in sys.path:
        sys.path.insert(0, cmd_subfolder)


def import_siblingFolder(sibling_folder):
    # Use this if you want to include modules from a subfolder
    cmd_siblingFolder = os.path.realpath(os.path.abspath(
        os.path.join(os.path.split(os.path.split(inspect.getfile(inspect.currentframe()))[0])[0], sibling_folder)))
    if cmd_siblingFolder not in sys.path:
        sys.path.insert(0, cmd_siblingFolder)


import tensorflow as tf

# Allow relative imports when being executed as script.
if __name__ == "__main__" and __package__ is None:
    sys.path.insert(0, os.path.join(os.path.dirname(__file__), '..', '..'))
    import keras_retinanet.bin  # noqa: F401

    __package__ = "keras_retinanet.bin"

# Change these to absolute imports if you copy this script outside the keras_retinanet package.
from retinanet.keras_retinanet import layers  # noqa: F401
from retinanet.keras_retinanet import losses
from retinanet.keras_retinanet import models
from retinanet.keras_retinanet.callbacks import RedirectModel
from retinanet.keras_retinanet.callbacks.eval import Evaluate
from retinanet.keras_retinanet.models.retinanet import retinanet_bbox
from retinanet.keras_retinanet.preprocessing.csv_generator import CSVGenerator
from retinanet.keras_retinanet.preprocessing.dataframe_generator import DataFrameGenerator
from retinanet.keras_retinanet.preprocessing.kitti import KittiGenerator
from retinanet.keras_retinanet.preprocessing.open_images import OpenImagesGenerator
from retinanet.keras_retinanet.preprocessing.pascal_voc import PascalVocGenerator

import_siblingFolder("utils")
from anchors import make_shapes_callback
from config import read_config_file, parse_anchor_parameters
from keras_version import check_keras_version
from model import freeze as freeze_model
from model import freeze_lastN as freeze_lastN_model
from model import freeze_firstN as freeze_firstN_model
from retinanet.keras_retinanet.utils.transform import random_transform_generator

sys.path.insert(0, os.path.join(os.path.dirname(__file__), '..', '..', '..'))
import keras
import keras.preprocessing.image 


def makedirs(path):
    # Intended behavior: try to create the directory,
    # pass if the directory exists already, fails otherwise.
    # Meant for Python 2.7/3.n compatibility.
    try:
        os.makedirs(path)
    except OSError:
        if not os.path.isdir(path):
            raise


def get_session():
    """ Construct a modified tf session.
    """
    config = tf.compat.v1.ConfigProto()
    config.gpu_options.allow_growth = True
    return tf.compat.v1.Session(config=config)


def model_with_weights(model, weights, skip_mismatch):
    """ Load weights for model.

    Args
        model         : The model to load weights for.
        weights       : The weights to load.
        skip_mismatch : If True, skips layers whose shape of weights doesn't match with the model.
    """
    if weights is not None:
        model.load_weights(weights, by_name=True, skip_mismatch=skip_mismatch)
    return model


def create_models(backbone_retinanet, num_classes, weights, multi_gpu=0, freeze_backbone=False, config=None,
                  freeze_lastN=0, freeze_firstN=0, lr=1e-5, nms_threshold=0.2):
    """ Creates three models (model, training_model, prediction_model).

    Args
        backbone_retinanet : A function to call to create a retinanet model with a given backbone.
        num_classes        : The number of classes to train.
        weights            : The weights to load into the model.
        multi_gpu          : The number of GPUs to use for training.
        freeze_backbone    : If True, disables learning for the backbone.
        config             : Config parameters, None indicates the default configuration.

    Returns
        model            : The base model. This is also the model that is saved in snapshots.
        training_model   : The training model. If multi_gpu=0, this is identical to model.
        prediction_model : The model wrapped with utility functions to perform object detection (applies regression values and performs NMS).
    """

    if freeze_backbone:
        modifier = freeze_model
    else:
        modifier = None

    # load anchor parameters, or pass None (so that defaults will be used)
    anchor_params = None
    num_anchors = None
    if config and 'anchor_parameters' in config:
        anchor_params = parse_anchor_parameters(config)
        num_anchors = anchor_params.num_anchors()

    # Keras recommends initialising a multi-gpu model on the CPU to ease weight sharing, and to prevent OOM errors.
    # optionally wrap in a parallel model
    if multi_gpu > 1:
        from keras.utils import multi_gpu_model
        with tf.device('/cpu:0'):
            model = model_with_weights(backbone_retinanet(num_classes, num_anchors=num_anchors, modifier=modifier),
                                       weights=weights, skip_mismatch=True)
        training_model = multi_gpu_model(model, gpus=multi_gpu)
    else:
        model = model_with_weights(backbone_retinanet(num_classes, num_anchors=num_anchors, modifier=modifier),
                                   weights=weights, skip_mismatch=True)
        if modifier is not None:
            training_model = model
            model = freeze_firstN_model(model, freeze_firstN)
            model = freeze_lastN_model(model, freeze_lastN)
        training_model = model

    # make prediction model
    prediction_model = retinanet_bbox(model=model, anchor_params=anchor_params, nms_threshold=nms_threshold)

    # compile model
    training_model.compile(
        loss={
            'regression': losses.smooth_l1(),
            'classification': losses.focal()
        },
        optimizer=keras.optimizers.adam(lr=lr, clipnorm=0.001)
    )

    return model, training_model, prediction_model


def create_callbacks(model, training_model, prediction_model, validation_generator, args):
    """ Creates the callbacks to use during training.

    Args
        model: The base model.
        training_model: The model that is used for training.
        prediction_model: The model that should be used for validation.
        validation_generator: The generator for creating validation data.
        args: parseargs args object.

    Returns:
        A list of callbacks used for training.
    """
    callbacks = []

    ##    tensorboard_callback = None
    ##    if args.tensorboard_dir:
    ##        tensorboard_callback = keras.callbacks.TensorBoard(
    ##            log_dir                = args.tensorboard_dir,
    ##            histogram_freq         = 0,
    ##            batch_size             = args.batch_size,
    ##            write_graph            = True,
    ##            write_grads            = False,
    ##            write_images           = False,
    ##            embeddings_freq        = 0,
    ##            embeddings_layer_names = None,
    ##            embeddings_metadata    = None
    ##        )
    ##        callbacks.append(tensorboard_callback)

    if args.evaluation and validation_generator:
        print("vali")
        if args.dataset_type == 'coco':
            from ..callbacks.coco import CocoEval

            # use prediction model for evaluation
            evaluation = CocoEval(validation_generator)
        else:
            evaluation = Evaluate(validation_generator, weighted_average=args.weighted_average, score_threshold=0.5)
        evaluation = RedirectModel(evaluation, prediction_model)
        callbacks.append(evaluation)

    # save the model
    if args.snapshots:
        # ensure directory created first; otherwise h5py will error after epoch.
        makedirs(args.snapshot_path)
        checkpoint = keras.callbacks.ModelCheckpoint(
            os.path.join(
                args.snapshot_path,
                '{backbone}_{dataset_type}_{{epoch:02d}}.h5'.format(backbone=args.backbone,
                                                                    dataset_type=args.dataset_type)
            ),
            verbose=1,
            # save_best_only=True,
            # monitor="mAP",
            # mode='max'
        )
        checkpoint = RedirectModel(checkpoint, model)
        callbacks.append(checkpoint)

    callbacks.append(keras.callbacks.ReduceLROnPlateau(
        monitor='loss',
        factor=0.1,
        patience=2000,
        verbose=1,
        mode='auto',
        epsilon=0.0001,
        cooldown=0,
        min_lr=0
    ))

    return callbacks


def create_generators(args, preprocess_image, dataframe=None):
    """ Create generators for training and validation.

    Args
        args             : parseargs object containing configuration for generators.
        preprocess_image : Function that preprocesses an image for the network.
    """
    print("create da generatas brah")
    common_args = {
        'batch_size': args.batch_size,
        'config': args.config,
        'image_min_side': args.image_min_side,
        'image_max_side': args.image_max_side,
        'preprocess_image': preprocess_image,
    }

    # create random transform generator for augmenting training data
    if args.random_transform:
        transform_generator = random_transform_generator(
            ###############################################################################################
            min_rotation=-math.pi,
            max_rotation=math.pi,
            min_translation=(-0.0, -0.0),
            max_translation=(0.0, 0.0),
            min_shear=-0.5,
            max_shear=0.5,
            min_scaling=(0.5, 0.5),
            max_scaling=(1.5, 1.5),
            flip_x_chance=0.5,
            flip_y_chance=0.5,
            #################################################################################################
        )
    else:
        transform_generator = random_transform_generator(flip_x_chance=0.5)

    if args.dataset_type == 'coco':
        # import here to prevent unnecessary dependency on cocoapi
        from ..preprocessing.coco import CocoGenerator

        train_generator = CocoGenerator(
            args.coco_path,
            'train2017',
            transform_generator=transform_generator,
            **common_args
        )

        validation_generator = CocoGenerator(
            args.coco_path,
            'val2017',
            **common_args
        )
    elif args.dataset_type == 'pascal':
        train_generator = PascalVocGenerator(
            args.pascal_path,
            'trainval',
            transform_generator=transform_generator,
            **common_args
        )

        validation_generator = PascalVocGenerator(
            args.pascal_path,
            'test',
            **common_args
        )
    # elif args.dataset_type == 'csv':
    #     train_generator = CSVGenerator(
    #         args.annotations,
    #         args.classes,
    #         transform_generator=transform_generator,
    #         **common_args
    #     )
    #
    #     if args.val_annotations:
    #         validation_generator = CSVGenerator(
    #             args.val_annotations,
    #             args.classes,
    #             **common_args
    #         )
    #     else:
    #         validation_generator = None
    elif args.dataset_type == 'csv':
        train_generator = DataFrameGenerator(
            args.annotations,
            args.classes,
            dataframe=dataframe,
            transform_generator=transform_generator,
            **common_args
        )

        if args.val_annotations:
            validation_generator = DataFrameGenerator(
                args.val_annotations,
                args.classes,
                **common_args
            )
        else:
            validation_generator = None
    elif args.dataset_type == 'oid':
        train_generator = OpenImagesGenerator(
            args.main_dir,
            subset='train',
            version=args.version,
            labels_filter=args.labels_filter,
            annotation_cache_dir=args.annotation_cache_dir,
            parent_label=args.parent_label,
            transform_generator=transform_generator,
            **common_args
        )

        validation_generator = OpenImagesGenerator(
            args.main_dir,
            subset='validation',
            version=args.version,
            labels_filter=args.labels_filter,
            annotation_cache_dir=args.annotation_cache_dir,
            parent_label=args.parent_label,
            **common_args
        )
    elif args.dataset_type == 'kitti':
        train_generator = KittiGenerator(
            args.kitti_path,
            subset='train',
            transform_generator=transform_generator,
            **common_args
        )

        validation_generator = KittiGenerator(
            args.kitti_path,
            subset='val',
            **common_args
        )
    else:
        raise ValueError('Invalid data type received: {}'.format(args.dataset_type))

    return train_generator, validation_generator


def check_args(parsed_args):
    """ Function to check for inherent contradictions within parsed arguments.
    For example, batch_size < num_gpus
    Intended to raise errors prior to backend initialisation.

    Args
        parsed_args: parser.parse_args()

    Returns
        parsed_args
    """

    if parsed_args.multi_gpu > 1 and parsed_args.batch_size < parsed_args.multi_gpu:
        raise ValueError(
            "Batch size ({}) must be equal to or higher than the number of GPUs ({})".format(parsed_args.batch_size,
                                                                                             parsed_args.multi_gpu))

    if parsed_args.multi_gpu > 1 and parsed_args.snapshot:
        raise ValueError(
            "Multi GPU training ({}) and resuming from snapshots ({}) is not supported.".format(parsed_args.multi_gpu,
                                                                                                parsed_args.snapshot))

    if parsed_args.multi_gpu > 1 and not parsed_args.multi_gpu_force:
        raise ValueError(
            "Multi-GPU support is experimental, use at own risk! Run with --multi-gpu-force if you wish to continue.")

    if 'resnet' not in parsed_args.backbone:
        warnings.warn(
            'Using experimental backbone {}. Only resnet50 has been properly tested.'.format(parsed_args.backbone))

    return parsed_args


def parse_args(args):
    """ Parse the arguments.
    """
    parser = argparse.ArgumentParser(description='Simple training script for training a RetinaNet network.')
    subparsers = parser.add_subparsers(help='Arguments for specific dataset types.', dest='dataset_type')
    subparsers.required = True

    coco_parser = subparsers.add_parser('coco')
    coco_parser.add_argument('coco_path', help='Path to dataset directory (ie. /tmp/COCO).')

    pascal_parser = subparsers.add_parser('pascal')
    pascal_parser.add_argument('pascal_path', help='Path to dataset directory (ie. /tmp/VOCdevkit).')

    kitti_parser = subparsers.add_parser('kitti')
    kitti_parser.add_argument('kitti_path', help='Path to dataset directory (ie. /tmp/kitti).')

    def csv_list(string):
        return string.split(',')

    oid_parser = subparsers.add_parser('oid')
    oid_parser.add_argument('main_dir', help='Path to dataset directory.')
    oid_parser.add_argument('--version', help='The current dataset version is v4.', default='v4')
    oid_parser.add_argument('--labels-filter', help='A list of labels to filter.', type=csv_list, default=None)
    oid_parser.add_argument('--annotation-cache-dir', help='Path to store annotation cache.', default='.')
    oid_parser.add_argument('--parent-label', help='Use the hierarchy children of this label.', default=None)

    csv_parser = subparsers.add_parser('csv')
    csv_parser.add_argument('annotations', help='Path to CSV file containing annotations for training.')
    csv_parser.add_argument('classes', help='Path to a CSV file containing class label mapping.')
    csv_parser.add_argument('--val-annotations',
                            help='Path to CSV file containing annotations for validation (optional).')

    group = parser.add_mutually_exclusive_group()
    ##############################################################################################################################################################################################################
    group.add_argument('--snapshot', help='Resume training from a snapshot.')
    ##############################################################################################################################################################################################################
    group.add_argument('--imagenet-weights',
                       help='Initialize the model with pretrained imagenet weights. This is the default behaviour.',
                       action='store_const', const=True, default=True)
    group.add_argument('--weights', help='Initialize the model with weights from a file.')
    group.add_argument('--no-weights', help='Don\'t initialize the model with any weights.', dest='imagenet_weights',
                       action='store_const', const=False)
    #############################################################################################################################################################################################################
    parser.add_argument('--backbone', help='Backbone model used by retinanet.', default='resnet50', type=str)
    parser.add_argument('--batch-size', help='Size of the batches.', default=1, type=int)
    parser.add_argument('--gpu', help='Id of the GPU to use (as reported by nvidia-smi).')
    parser.add_argument('--multi-gpu', help='Number of GPUs to use for parallel processing.', type=int, default=0)
    parser.add_argument('--multi-gpu-force', help='Extra flag needed to enable (experimental) multi-gpu support.',
                        action='store_true')
    parser.add_argument('--epochs', help='Number of epochs to train.', type=int, default=50)
    parser.add_argument('--steps', help='Number of steps per epoch.', type=int, default=10000)
    parser.add_argument('--snapshot-path',
                        help='Path to store snapshots of models during training (defaults to \'./snapshots\')',
                        default='./snapshots')
    # parser.add_argument('--tensorboard-dir',  help='Log directory for Tensorboard output', default='./logs')
    parser.add_argument('--no-snapshots', help='Disable saving snapshots.', dest='snapshots', action='store_false')
    parser.add_argument('--no-evaluation', help='Disable per epoch evaluation.', dest='evaluation',
                        action='store_false')
    parser.add_argument('--freeze-backbone', help='Freeze training of backbone layers.', action='store_true',
                        default=False)
    parser.add_argument('--random-transform', help='Randomly transform image and annotations.', action='store_true')
    parser.add_argument('--image-min-side', help='Rescale the image so the smallest side is min_side.', type=int,
                        default=800)
    parser.add_argument('--image-max-side', help='Rescale the image if the largest side is larger than max_side.',
                        type=int, default=1333)
    parser.add_argument('--config', help='Path to a configuration parameters .ini file.')
    parser.add_argument('--weighted-average',
                        help='Compute the mAP using the weighted average of precisions among classes.',
                        action='store_true')
    parser.add_argument('--freeze-lastN', help='Freeze last 50 layers of model', type=int, default=0)
    parser.add_argument('--freeze-firstN', help='Freeze first N layers of model', type=int, default=0)
    parser.add_argument('--compute-val-loss', help='Freeze first N layers of model', action='store_true')
    parser.add_argument('--lr', help='Learning Rate', type=float, default=1e-5)
    parser.add_argument('--nms_threshold', help='NMS Threshold', type=float, default=0.2)
    ###############################################################################################################################################################################################################
    return check_args(parser.parse_args(args))


def main(args=None):
    # parse arguments
    if args is None:
        args = sys.argv[1:]
    args = parse_args(args)

    # create object that stores backbone information
    backbone = models.backbone(args.backbone)

    # make sure keras is the minimum required version
    check_keras_version()

    # optionally choose specific GPU
    if args.gpu:
        os.environ['CUDA_VISIBLE_DEVICES'] = args.gpu
    keras.backend.tensorflow_backend.set_session(get_session())

    # optionally load config parameters
    if args.config:
        args.config = read_config_file(args.config)

    # create the generators
    train_generator, validation_generator = create_generators(args, backbone.preprocess_image)

    # create the model
    if args.snapshot is not None:
        print('Loading model, this may take a second...')
        model = models.load_model(args.snapshot, backbone_name=args.backbone)
        training_model = model
        anchor_params = None
        if args.config and 'anchor_parameters' in args.config:
            anchor_params = parse_anchor_parameters(args.config)
        prediction_model = retinanet_bbox(model=model, anchor_params=anchor_params, nms_threshold=args.nms_threshold)
    else:
        weights = args.weights
        # default to imagenet if nothing else is specified
        if weights is None and args.imagenet_weights:
            weights = backbone.download_imagenet()

        print('Creating model, this may take a second...')
        model, training_model, prediction_model = create_models(
            backbone_retinanet=backbone.retinanet,
            num_classes=train_generator.num_classes(),
            weights=weights,
            multi_gpu=args.multi_gpu,
            freeze_backbone=args.freeze_backbone,
            freeze_lastN=args.freeze_lastN,
            freeze_firstN=args.freeze_firstN,
            config=args.config,
            nms_threshold=args.nms_threshold
        )

    # print model summary
    print(model.summary())

    # this lets the generator compute backbone layer shapes using the actual backbone model
    if 'vgg' in args.backbone or 'densenet' in args.backbone:
        train_generator.compute_shapes = make_shapes_callback(model)
        if validation_generator:
            validation_generator.compute_shapes = train_generator.compute_shapes

    # create the callbacks
    callbacks = create_callbacks(
        model,
        training_model,
        prediction_model,
        validation_generator,
        args,
    )

    # start training
    training_model.fit_generator(
        generator=train_generator,
        steps_per_epoch=args.steps,
        epochs=args.epochs,
        verbose=1,
        callbacks=callbacks,
    )

   


def genTrainingModel(args=None):
    '''
        genereate a training model with setup according to the args
    '''
    # parse arguments
    if args is None:
        args = sys.argv[1:]
    args = parse_args(args)

    # create object that stores backbone information
    backbone = models.backbone(args.backbone)

    # make sure keras is the minimum required version

    # optionally choose specific GPU
    if args.gpu:
        os.environ['CUDA_VISIBLE_DEVICES'] = args.gpu

    # optionally load config parameters
    if args.config:
        args.config = read_config_file(args.config)

    # create the generators
    train_generator, validation_generator = create_generators(args, backbone.preprocess_image)

    # create the model
    if args.snapshot is not None:
        print('Loading model, this may take a second...')
        model = models.load_model(args.snapshot, backbone_name=args.backbone)
        training_model = model
        anchor_params = None
        if args.config and 'anchor_parameters' in args.config:
            anchor_params = parse_anchor_parameters(args.config)
        print("nms retinanet_bbox param:", args.nms_threshold)
        prediction_model = retinanet_bbox(prediction_model=None, model=model, anchor_params=anchor_params, nms_threshold=args.nms_threshold)
    else:
        weights = args.weights
        # default to imagenet if nothing else is specified
        if weights is None and args.imagenet_weights:
            weights = backbone.download_imagenet()

        print('Creating model, this may take a second...')
        model, training_model, prediction_model = create_models(
            backbone_retinanet=backbone.retinanet,
            num_classes=train_generator.num_classes(),
            weights=weights,
            multi_gpu=args.multi_gpu,
            freeze_backbone=args.freeze_backbone,
            freeze_lastN=args.freeze_lastN,
            freeze_firstN=args.freeze_firstN,
            lr=args.lr,
            config=args.config,
            nms_threshold=args.nms_threshold
        )
    # print(model.summary())
    # create the callbacks
    callbacks = create_callbacks(
        model,
        training_model,
        prediction_model,
        validation_generator,
        args
    )
    print("made callbacks")

    return training_model, train_generator, callbacks


def Train(training_model, callbacks, args=None, First=True, callback_model=None, dataframe=None):
    '''
        Train the model on a single epoch
    '''
    print("start da train brah")
    import traceback
    args = parse_args(args)
    backbone = models.backbone(args.backbone)
    train_generator, validation_generator = create_generators(args, backbone.preprocess_image, dataframe=dataframe)
    try:
        history = training_model.fit_generator(
            generator=train_generator,
            steps_per_epoch=args.steps,
            epochs=args.epochs,
            verbose=1,
            callbacks=callbacks,
            #First = First,
            validation_data=validation_generator,
        )
        # score = training_model.evaluate_generator(generator=train_generator, steps=1)
        # print("score: ", score)
        # callback_model = callbacks[0]
    except AttributeError:
        traceback.print_exc()
        print("Nothing to train on!")
        print("Unexpected error:", sys.exc_info()[0])
        # import time
        # time.sleep(4)
    #if First:
        #training_model.save("savedModelTestH.h5")
        #training_model.save("savedModelTest2", save_format='tf')
        
        #These two are the same:
        #tf.keras.models.save_model(training_model, "savedModelTest3")
        #tf.saved_model.save(training_model, "savedModelTest")
    First = False
    return First, callbacks, callback_model, training_model


if __name__ == '__main__':
    main()
