# shellcheck shell=bash
############### Configuration ###############

# shellcheck disable=SC2034
# BASE_IMAGE=tensorflow/tensorflow:2.2.0-gpu
# BASE_IMAGE=tensorflow/tensorflow:2.4.3-gpu
BASE_IMAGE=tensorflow/tensorflow:2.6.1-gpu

# IMAGE_PREFIX=${IMAGE_PREFIX:-}

BASE_IMAGE_TAG=${BASE_IMAGE#*:};
BASE_IMAGE_NAME=${BASE_IMAGE%%:*};
case "$BASE_IMAGE_NAME" in
  tensorflow/tensorflow) IMAGE_NAME=igvo01_project;;
  *) echo >&2 "Error: unknown base image: $BASE_IMAGE_NAME"; exit 1;;
esac;

IMAGE_TAG=${IMAGE_TAG:-${BASE_IMAGE_TAG}}

# shellcheck disable=SC2034
IMAGE=${IMAGE_PREFIX}${IMAGE_NAME}${IMAGE_TAG+:}${IMAGE_TAG}
############# End Configuration #############
