#!/usr/bin/env bash

set -eo pipefail

THIS_DIR=$( cd "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P )

error() {
    echo >&2 "* [docker-run] Error: $*"
}

fatal() {
    error "$@"
    exit 1
}

message() {
    echo "* $*"
}

read-keys() {
    local key_dir=$1
    local keys key
    if [[ -d "$key_dir" ]]; then
        for f in "$key_dir"/*.pub; do
            if [[ -r "$f" ]]; then
                key="$(< "$f")"
                if [[ -z "$keys" ]]; then
                    keys=$key
                elif [[ "$keys" == *$'\n' ]]; then
                keys="${keys}${key}"
                else
                    keys="${keys}$'\n'${key}"
                fi
            fi
        done
    fi
    echo "$keys"
}

usage() {
    echo "Run container"
    echo
    echo "$0 [options]"
    echo "options:"
    echo "      --podman               Use podman instead of docker"
    echo "  -b, --base                 Base container (default: ${BASE_IMAGE})"
    echo "  -t, --tag=TAG              Image name and optional tag"
    echo "                             (default: ${IMAGE_NAME})"
    echo "  -p, --openssh-pwd          OpenSSH password (default: empty)"
    echo "      --net=NET              Network configuration for docker"
    echo "      --help                 Display this help and exit"
}

# shellcheck source=docker-config.sh
source "$THIS_DIR/docker-config.sh" || \
    fatal "Could not load configuration from $THIS_DIR/docker-config.sh"

USE_PODMAN=
OPENSSH_PASSWORD=
ARGS=()

while [[ $# -gt 0 ]]; do
    case "$1" in
        --net=*)
            ARGS+=("$1")
            shift
            ;;
        --podman)
            USE_PODMAN=true
            shift
            ;;
        -b|--base)
            BASE_IMAGE="$2"
            shift 2
            ;;
        --base=*)
            BASE_IMAGE="${1#*=}"
            shift
            ;;
        -t|--tag)
            IMAGE="$2"
            shift 2
            ;;
        --tag=*)
            IMAGE="${1#*=}"
            shift
            ;;
        -p|--openssh-pwd)
            OPENSSH_PASSWORD="$2"
            shift 2
            ;;
        --openssh-pwd=*)
            OPENSSH_PASSWORD="${1#*=}"
            shift
            ;;
        --help)
            usage
            exit
            ;;
        --)
            shift
            break
            ;;
        -*)
            fatal "Unknown option $1"
            ;;
        *)
            break
            ;;
    esac
done

echo "Image Configuration:"
echo "USE_PODMAN:        $USE_PODMAN"
echo "IMAGE_NAME:        $IMAGE_NAME"
echo "IMAGE:             $IMAGE"

cd "$THIS_DIR"
OPENSSH_AUTHORIZED_KEYS="$(read-keys keys)"
OPENSSH_ROOT_AUTHORIZED_KEYS="$(read-keys root-keys)"

if [[ "$USE_PODMAN" = "true" ]]; then
    set -xe
    podman run -p 2222:22 "${ARGS[@]}" \
        -e OPENSSH_AUTHORIZED_KEYS="$OPENSSH_AUTHORIZED_KEYS" \
        -e OPENSSH_ROOT_AUTHORIZED_KEYS="$OPENSSH_ROOT_AUTHORIZED_KEYS" \
        -e OPENSSH_PASSWORD="$OPENSSH_PASSWORD" \
        --name="$IMAGE_NAME" \
        --rm -ti --gpus=all "${IMAGE}" "$@"
else
    set -xe
    docker run -p 2222:22 "${ARGS[@]}" \
        -e OPENSSH_AUTHORIZED_KEYS="$OPENSSH_AUTHORIZED_KEYS" \
        -e OPENSSH_ROOT_AUTHORIZED_KEYS="$OPENSSH_ROOT_AUTHORIZED_KEYS" \
        -e OPENSSH_PASSWORD="$OPENSSH_PASSWORD" \
        --name="$IMAGE_NAME" \
        --rm -ti --gpus=all "${IMAGE}" "$@"
fi
