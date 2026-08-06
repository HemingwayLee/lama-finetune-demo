#!/usr/bin/env node
// Headless (no-browser) equivalent of clicking "Generate" then "Save" on index.html.
// Reuses the exact same randomized table-layout algorithm as the page's <script>
// (see generateTable() in index.html) and rasterizes it straight to a PNG buffer
// instead of relying on DOM table layout + canvas/foreignObject export.

const fs = require('fs');
const path = require('path');
const { PNG } = require('pngjs');
const { generateTableRGBA } = require('./lib/table_generator');

function main() {
  const outPath = process.argv[2];
  if (!outPath) {
    console.error('Usage: node generate_table_image.js <output.png>');
    process.exit(1);
  }

  const { width, height, data } = generateTableRGBA();
  const png = new PNG({ width, height });
  data.copy(png.data);

  fs.mkdirSync(path.dirname(outPath), { recursive: true });
  png.pack().pipe(fs.createWriteStream(outPath)).on('finish', () => {
    console.log(`Saved generated table image: ${outPath} (${width}x${height})`);
  });
}

main();
