#!/usr/bin/env bash
# Builds a full LaMa training dataset out of synthetic table images (the same
# generator used by index.html's Generate/Save buttons -- see generate_table_dataset.js).
#
# Produces, under outdir:
#   train/               raw *.jpg images (masks are generated on the fly during
#                         training by MixedMaskGenerator, per configs/training/data/*.yaml)
#   val/                 paired image + *_mask001.png files (static, for validation)
#   visual_test/         same pairing, used for periodic visual samples while training
#
# val/ and visual_test/ masks are always multiple (2-5) random rectangles --
# see lib/mask_generator.js -- rather than LaMa's own irregular-stroke/box
# generator (bin/gen_mask_dataset.py), which is probabilistic and can produce
# zero or one box.
#
# Usage:
#   fetch_data/generate_training_dataset.sh [outdir] [train_n] [val_n] [visual_test_n]
#
#   outdir        Dataset root. Defaults to training_data/ at the repo root.
#   train_n       Number of training images (default 200).
#   val_n         Number of validation image+mask pairs (default 20).
#   visual_test_n Number of visual-test image+mask pairs (default 20).

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

OUTDIR="${1:-$REPO_ROOT/training_data}"
TRAIN_N="${2:-200}"
VAL_N="${3:-20}"
VISUAL_TEST_N="${4:-20}"

if [ ! -d "$SCRIPT_DIR/node_modules" ]; then
  echo "Installing Node dependencies (pngjs, jpeg-js) in $SCRIPT_DIR ..."
  npm install --prefix "$SCRIPT_DIR"
fi

echo "Generating training dataset ..."
node "$SCRIPT_DIR/generate_table_dataset.js" "$OUTDIR" \
  --train "$TRAIN_N" --val "$VAL_N" --visual-test "$VISUAL_TEST_N"

echo
echo "Done. Training dataset written to: $OUTDIR"
echo "  $OUTDIR/train/          ($TRAIN_N raw .jpg images, no masks)"
echo "  $OUTDIR/val/            ($VAL_N paired image + multi-rectangle mask .png files)"
echo "  $OUTDIR/visual_test/    ($VISUAL_TEST_N paired image + multi-rectangle mask .png files)"
echo
echo "Point training at it by overriding location.data_root_dir, e.g.:"
echo "  python3 bin/train.py location=docker location.data_root_dir=$OUTDIR data=abl-04-256-mh-dist"
