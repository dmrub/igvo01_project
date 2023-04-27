#!/usr/bin/env bash

set -eo pipefail

THIS_DIR=$( cd "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P )

error() {
    echo >&2 "* Error: $*"
}

fatal() {
    error "$@"
    exit 1
}

message() {
    echo "* $*"
}

mkdir -p "${THIS_DIR}/tf"

IMAGE=tensorflow/tensorflow:2.8.4-gpu
set -x
docker run --rm -it  --gpus=all --net=host --entrypoint /bin/bash "$IMAGE"
