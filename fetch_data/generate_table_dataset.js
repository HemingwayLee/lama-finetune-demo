#!/usr/bin/env node
// Bulk-generates a synthetic table image dataset (same algorithm as index.html's
// Generate button) for a LaMa training run:
//   <outdir>/train/table_00000.jpg, ...            -- raw images, no masks. LaMa's
//                                                       default InpaintingTrainDataset
//                                                       generates masks on the fly per
//                                                       batch, and its loader hardcodes
//                                                       a *.jpg glob, so these must be
//                                                       real JPEGs (not just .jpg-named
//                                                       PNGs).
//   <outdir>/val/table_00000.png + _mask001.png     -- paired image + mask
//   <outdir>/visual_test/table_00000.png + _mask001.png
//
// val/ and visual_test/ masks are always multiple (2-5) random white rectangles
// on black, per lib/mask_generator.js -- deliberately not LaMa's own irregular-
// stroke/box generator (bin/gen_mask_dataset.py), which is probabilistic and can
// produce zero or one box.

const fs = require('fs');
const path = require('path');
const { PNG } = require('pngjs');
const jpeg = require('jpeg-js');
const { generateTableRGBA } = require('./lib/table_generator');
const { generateMaskRGBA } = require('./lib/mask_generator');

function parseArgs(argv) {
  const args = { outdir: null, train: 200, val: 20, visualTest: 20, jpegQuality: 90 };
  const positional = [];
  for (let i = 0; i < argv.length; i++) {
    const a = argv[i];
    if (a === '--train') args.train = parseInt(argv[++i], 10);
    else if (a === '--val') args.val = parseInt(argv[++i], 10);
    else if (a === '--visual-test') args.visualTest = parseInt(argv[++i], 10);
    else if (a === '--jpeg-quality') args.jpegQuality = parseInt(argv[++i], 10);
    else positional.push(a);
  }
  args.outdir = positional[0];
  return args;
}

function writeJpeg(outPath, { width, height, data }, quality) {
  const encoded = jpeg.encode({ data, width, height }, quality);
  fs.writeFileSync(outPath, encoded.data);
}

function writePng(outPath, { width, height, data }) {
  const png = new PNG({ width, height });
  data.copy(png.data);
  fs.writeFileSync(outPath, PNG.sync.write(png));
}

function generateTrainSet(dir, count, quality) {
  fs.mkdirSync(dir, { recursive: true });
  const pad = String(count).length;
  for (let i = 0; i < count; i++) {
    const name = `table_${String(i).padStart(pad, '0')}.jpg`;
    writeJpeg(path.join(dir, name), generateTableRGBA(), quality);
  }
  console.log(`Wrote ${count} images to ${dir}`);
}

// Generates paired image + always-multiple-rectangle mask files (LaMa val/visual_test convention).
function generatePairedSet(dir, count) {
  fs.mkdirSync(dir, { recursive: true });
  const pad = String(count).length;
  for (let i = 0; i < count; i++) {
    const base = `table_${String(i).padStart(pad, '0')}`;
    const image = generateTableRGBA();
    writePng(path.join(dir, `${base}.png`), image);
    const mask = generateMaskRGBA(image.width, image.height);
    writePng(path.join(dir, `${base}_mask001.png`), mask);
  }
  console.log(`Wrote ${count} image+mask pairs to ${dir}`);
}

function main() {
  const args = parseArgs(process.argv.slice(2));
  if (!args.outdir) {
    console.error('Usage: node generate_table_dataset.js <outdir> [--train N] [--val N] [--visual-test N] [--jpeg-quality Q]');
    process.exit(1);
  }

  generateTrainSet(path.join(args.outdir, 'train'), args.train, args.jpegQuality);
  generatePairedSet(path.join(args.outdir, 'val'), args.val);
  generatePairedSet(path.join(args.outdir, 'visual_test'), args.visualTest);
}

main();
