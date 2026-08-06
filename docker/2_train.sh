#!/usr/bin/env bash
# Finetunes/trains LaMa via bin/train.py, using the CPU-only image built by
# docker/build.sh (torch==1.8.1+cpu, no CUDA runtime). Runs under QEMU emulation
# via --platform linux/amd64 on non-amd64 hosts (e.g. Apple Silicon) -- expect
# this to be slow (minutes per training step on a large model).
#
# data_dir must already be laid out as LaMa expects (see
# fetch_data/generate_training_dataset.sh for one way to build this):
#   data_dir/train/*.jpg               raw images, masks generated on the fly
#   data_dir/val/*.png + *_mask*.png    paired validation images/masks
#   data_dir/visual_test/... likewise
#
# Usage:
#   docker/2_train.sh pretrained_model_dir data_dir out_dir [other args to bin/train.py]
#
#   pretrained_model_dir  e.g. $(pwd)/big-lama -- mounted read-only-ish at
#                         /data/checkpoint; pass finetune_from=/data/checkpoint/models/best.ckpt
#                         as one of the extra args to actually initialize from it
#                         (see bin/train.py's finetune_from option -- loads
#                         weights non-strictly, unlike Trainer's own
#                         resume_from_checkpoint which requires an identical config).
#   data_dir              dataset root as laid out above.
#   out_dir               where experiments/, tb_logs/, and a torch_home/ cache
#                         (downloaded VGG16 weights for the LPIPS validation
#                         metric) get written; created if missing.
#
# Example (finetune from big-lama on CPU):
#   docker/2_train.sh $(pwd)/big-lama $(pwd)/training_data $(pwd)/experiments \
#     --config-name big-lama.yaml \
#     finetune_from=/data/checkpoint/models/best.ckpt \
#     trainer.kwargs.gpus=0 trainer.kwargs.accelerator=null \
#     losses.resnet_pl.weight=0 \
#     data.val_batch_size=1 +data.val.pad_out_to_modulo=32

if (( $# < 3 ))
then
    echo "Usage: $0 pretrained_model_dir data_dir out_dir [other args to bin/train.py]"
    exit 1
fi

CURDIR="$(dirname $0)"
SRCDIR="$CURDIR/.."
SRCDIR="$(realpath $SRCDIR)"

MODEL_LOCAL_DIR="$(realpath $1)"
DATA_LOCAL_DIR="$(realpath $2)"
mkdir -p "$3/experiments" "$3/tb_logs" "$3/torch_home"
OUT_LOCAL_DIR="$(realpath $3)"
shift 3

docker run \
    -v "$SRCDIR":/home/user/project \
    -v "$MODEL_LOCAL_DIR":/data/checkpoint \
    -v "$DATA_LOCAL_DIR":/data/data \
    -v "$OUT_LOCAL_DIR/experiments":/data/experiments \
    -v "$OUT_LOCAL_DIR/tb_logs":/data/tb_logs \
    -v "$OUT_LOCAL_DIR/torch_home":/data/torch_home \
    -e TORCH_HOME=/data/torch_home \
    -u $(id -u):$(id -g) \
    --platform linux/amd64 \
    --shm-size=2g \
    --name="lama-train" \
    --rm \
    ywlee/lama \
    /home/user/project/bin/train.py \
        location.data_root_dir=/data/data \
        location.out_root_dir=/data/experiments \
        location.tb_dir=/data/tb_logs \
        location.pretrained_models=/data/checkpoint \
        hydra.run.dir=/data/experiments/.hydra_run \
        hydra.output_subdir=null \
        $@
