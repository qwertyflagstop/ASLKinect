#!/usr/bin/env sh
# Compute the mean image from the imagenet training lmdb
# N.B. this is available in data/ilsvrc12

EXAMPLE=/Users/nick/Developer/signs/
DATA=/Users/nick/Developer/signs/
TOOLS=/Users/nick/Developer/caffe/.build_release/tools

$TOOLS/compute_image_mean $EXAMPLE/ilsvrc12_val_lmdb \
  $DATA/imagenet_mean_val.binaryproto

echo "Done val."

$TOOLS/compute_image_mean $EXAMPLE/ilsvrc12_train_lmdb \
  $DATA/imagenet_mean_train.binaryproto

echo "Done train."