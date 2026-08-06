#!/usr/bin/env bash
# Generates a synthetic "table" test image (equivalent to using index.html's
# Generate + Save buttons) plus a matching random-rectangle inpainting mask,
# ready to feed into bin/predict.py.
#
# Usage:
#   fetch_data/generate_test_data.sh [outdir] [rect_count]
#
#   outdir     Directory to write table.png / table_mask001.png into.
#              Defaults to test_images/ at the repo root.
#   rect_count Number of random mask rectangles (default: random 2-5).

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

OUTDIR="${1:-$REPO_ROOT/test_images}"
RECT_COUNT="${2:-}"

mkdir -p "$OUTDIR"

if [ ! -d "$SCRIPT_DIR/node_modules" ]; then
  echo "Installing Node dependencies (pngjs) in $SCRIPT_DIR ..."
  npm install --prefix "$SCRIPT_DIR"
fi

IMG_PATH="$OUTDIR/table.png"

echo "Generating table image (same random layout algorithm as index.html's Generate button) ..."
node "$SCRIPT_DIR/generate_table_image.js" "$IMG_PATH"

echo "Generating random-rectangle test mask ..."
if [ -n "$RECT_COUNT" ]; then
  node "$SCRIPT_DIR/generate_test_mask.js" "$IMG_PATH" "$RECT_COUNT"
else
  node "$SCRIPT_DIR/generate_test_mask.js" "$IMG_PATH"
fi

echo
echo "Done. Test data written to: $OUTDIR"
echo "Run inference with:"
echo "  python3 bin/predict.py model.path=$REPO_ROOT/big-lama indir=$OUTDIR outdir=$REPO_ROOT/output"
