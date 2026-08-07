#!/usr/bin/env bash


if (( $# < 3 ))
then
    echo "Usage: $0 config_name input_images_dir image_mask_dataset_out_dir [other args to gen_mask_dataset.py]"
    exit 1
fi

CURDIR="$(dirname $0)"
SRCDIR="$CURDIR/.."
SRCDIR="$(realpath $SRCDIR)"

CONFIG_LOCAL_PATH="$(realpath $1)"

mkdir -p "$2"
INPUT_LOCAL_DIR="$(realpath $2)"
if [ -z "$(ls -A "$INPUT_LOCAL_DIR" 2>/dev/null)" ]
then
    echo "Warning: input dir $INPUT_LOCAL_DIR is empty, add images to it before running or the output will be empty too."
fi

mkdir -p "$3"
OUTPUT_LOCAL_DIR="$(realpath $3)"
shift 3

docker run \
    -v "$SRCDIR":/home/user/project \
    -v "$CONFIG_LOCAL_PATH":/data/config.yaml \
    -v "$INPUT_LOCAL_DIR":/data/input \
    -v "$OUTPUT_LOCAL_DIR":/data/output \
    -u $(id -u):$(id -g) \
    --platform linux/amd64 \
    --name="lama-mask-gen" \
    --rm \
    ywlee/lama \
    /home/user/project/bin/gen_mask_dataset.py \
        /data/config.yaml /data/input /data/output $@
