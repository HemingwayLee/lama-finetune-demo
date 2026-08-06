#!/usr/bin/env node
// Generates a random-rectangle inpainting mask for a given image, following the
// LaMa CLI convention: for an image `foo.png`, the mask must be named
// `foo_mask001.png` and live in the same folder (see saicinpainting/evaluation/data.py,
// which globs `*mask*.png` and derives the image name via `fname.rsplit('_mask', 1)[0]`).

const fs = require('fs');
const path = require('path');
const { PNG } = require('pngjs');
const { generateMaskRGBA } = require('./lib/mask_generator');

function parsePngSize(imgPath) {
  const png = PNG.sync.read(fs.readFileSync(imgPath));
  return { width: png.width, height: png.height };
}

function buildMaskPath(imgPath) {
  const dir = path.dirname(imgPath);
  const ext = path.extname(imgPath);
  const base = path.basename(imgPath, ext);
  return path.join(dir, `${base}_mask001${ext}`);
}

function main() {
  const imgPath = process.argv[2];
  const rectCount = process.argv[3] ? parseInt(process.argv[3], 10) : undefined;

  if (!imgPath) {
    console.error('Usage: node generate_test_mask.js <image.png> [rectCount]');
    process.exit(1);
  }

  const { width, height } = parsePngSize(imgPath);
  const maskPath = buildMaskPath(imgPath);
  const rgba = generateMaskRGBA(width, height, rectCount);

  const png = new PNG({ width, height });
  rgba.data.copy(png.data);

  png.pack().pipe(fs.createWriteStream(maskPath)).on('finish', () => {
    console.log(`Saved mask: ${maskPath} (${width}x${height}, ${rgba.rectCount} rectangles)`);
  });
}

main();
