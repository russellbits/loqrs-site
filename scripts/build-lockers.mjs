#!/usr/bin/env node
// Builds the locker-row composites used by src/components/LockersRow.astro.
// Run after changing lockers-row.png or lockers-floor.png:
//   node scripts/build-lockers.mjs
import sharp from 'sharp';

const SRC_ROW = 'public/images/lockers-row.png';
const SRC_FLOOR = 'public/images/lockers-floor.png';
const OUT_DESKTOP = 'public/images/lockers-row-composite.png';
const OUT_MOBILE = 'public/images/lockers-row-mobile.png';

// The row is 1443 wide. The floor is 1431 wide and is stretched to the row
// width, matching the old two-image composition.
const WIDTH = 1443;
const ROW_HEIGHT = 557;
const FLOOR_HEIGHT = 262;
const OVERLAP = 10;

// Locker seams in the row, measured from the source: 17, 430, 1048, 1422.
// A crop from 430 to 1048 lands on two seams, so the mobile image shows three
// complete doors with no half-panel at either edge.
const MOBILE_LEFT = 430;
const MOBILE_WIDTH = 618;

const composite = await sharp(SRC_ROW)
  .resize({ width: WIDTH, height: ROW_HEIGHT, fit: 'fill' })
  .extend({ bottom: FLOOR_HEIGHT - OVERLAP, background: '#215' })
  .composite([
    {
      input: await sharp(SRC_FLOOR)
        .resize({ width: WIDTH, height: FLOOR_HEIGHT, fit: 'fill' })
        .toBuffer(),
      top: ROW_HEIGHT - OVERLAP,
      left: 0,
    },
  ])
  .png()
  .toFile(OUT_DESKTOP);

await sharp(OUT_DESKTOP)
  .extract({
    left: MOBILE_LEFT,
    top: 0,
    width: MOBILE_WIDTH,
    height: composite.height,
  })
  .png()
  .toFile(OUT_MOBILE);

console.log(`${OUT_DESKTOP} ${composite.width}x${composite.height}`);
console.log(`${OUT_MOBILE} ${MOBILE_WIDTH}x${composite.height}`);
