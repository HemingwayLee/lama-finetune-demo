#!/usr/bin/env bash

# CPU counterpart to 2_predict_with_gpu.sh, for use with the CPU-only image
# built by docker/build.sh (torch==1.8.1+cpu, no CUDA runtime). Runs under
# QEMU emulation via --platform linux/amd64 on non-amd64 hosts (e.g. Apple Silicon).

if (( $# < 3 ))
then
    echo "Usage: $0 model_dir input_dir output_dir [other arguments to predict.py]"
    exit 1
fi

CURDIR="$(dirname $0)"
SRCDIR="$CURDIR/.."
SRCDIR="$(realpath $SRCDIR)"

MODEL_LOCAL_DIR="$(realpath $1)"
INPUT_LOCAL_DIR="$(realpath $2)"
mkdir -p "$3"
OUTPUT_LOCAL_DIR="$(realpath $3)"
shift 3

docker run \
    -v "$SRCDIR":/home/user/project \
    -v "$MODEL_LOCAL_DIR":/data/checkpoint \
    -v "$INPUT_LOCAL_DIR":/data/input \
    -v "$OUTPUT_LOCAL_DIR":/data/output \
    -u $(id -u):$(id -g) \
    --platform linux/amd64 \
    --name="lama-predict" \
    --rm \
    ywlee/lama \
    /home/user/project/bin/predict.py \
        model.path=/data/checkpoint \
        indir=/data/input \
        outdir=/data/output \
        dataset.img_suffix=.png \
        device=cpu \
        hydra.run.dir=/data/output/.hydra_run \
        hydra.output_subdir=null \
        $@
