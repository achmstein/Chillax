/**
 * Script to invert images for admin_app
 * Creates white versions of cup icons and logo for dark background
 *
 * Run: npm install sharp && node scripts/invert_images.mjs
 */

import sharp from 'sharp';
import { readFile, writeFile, mkdir } from 'fs/promises';
import { existsSync } from 'fs';
import { join, dirname } from 'path';
import { fileURLToPath } from 'url';

const __dirname = dirname(fileURLToPath(import.meta.url));
const rootDir = join(__dirname, '..');

const mobileAssetsDir = join(rootDir, 'src', 'mobile_app', 'assets', 'images');
const adminAssetsDir = join(rootDir, 'src', 'admin_app', 'assets', 'images');

/**
 * Invert an image's colors while preserving transparency
 * Black becomes white, white becomes black
 */
async function invertImage(inputPath, outputPath) {
  console.log(`Inverting: ${inputPath}`);
  console.log(`Output: ${outputPath}`);

  try {
    // Read the image
    const image = sharp(inputPath);
    const metadata = await image.metadata();

    // Get raw pixel data
    const { data, info } = await image
      .raw()
      .toBuffer({ resolveWithObject: true });

    const channels = info.channels;
    const hasAlpha = channels === 4;

    // Invert RGB channels, preserve alpha
    for (let i = 0; i < data.length; i += channels) {
      // Invert R, G, B
      data[i] = 255 - data[i];       // R
      data[i + 1] = 255 - data[i + 1]; // G
      data[i + 2] = 255 - data[i + 2]; // B
      // Alpha (if present) stays the same
    }

    // Create output image
    await sharp(data, {
      raw: {
        width: info.width,
        height: info.height,
        channels: channels,
      },
    })
      .png()
      .toFile(outputPath);

    console.log(`  Created: ${outputPath}\n`);
  } catch (error) {
    console.error(`  Error processing ${inputPath}:`, error.message);
    throw error;
  }
}

/**
 * Copy the mobile_app's cup_splash_white.png which already has the correct white cup style
 * and ensure it has proper padding for adaptive icons
 */
async function createPaddedWhiteIcon(inputPath, outputPath) {
  console.log(`Creating padded white icon from: ${inputPath}`);
  console.log(`Output: ${outputPath}`);

  try {
    const image = sharp(inputPath);
    const metadata = await image.metadata();

    // The cup_splash_white.png is already styled correctly (white cup, black buttons)
    // We need to ensure proper sizing/padding for adaptive icons
    // Adaptive icons typically need the foreground to be 432x432 with content in center 288x288

    await image
      .resize(1024, 1024, {
        fit: 'contain',
        background: { r: 0, g: 0, b: 0, alpha: 0 }
      })
      .png()
      .toFile(outputPath);

    console.log(`  Created: ${outputPath}\n`);
  } catch (error) {
    console.error(`  Error processing ${inputPath}:`, error.message);
    throw error;
  }
}

async function main() {
  console.log('='.repeat(60));
  console.log('Generating inverted images for admin_app');
  console.log('='.repeat(60));
  console.log();

  // Ensure output directory exists
  if (!existsSync(adminAssetsDir)) {
    await mkdir(adminAssetsDir, { recursive: true });
  }

  const tasks = [
    // 1. Create cup_padded_white.png by inverting cup_padded.png
    {
      input: join(mobileAssetsDir, 'cup_padded.png'),
      output: join(adminAssetsDir, 'cup_padded_white.png'),
      action: invertImage,
    },
    // 2. Create cup_ios_inverted.png by inverting cup_ios.png
    {
      input: join(mobileAssetsDir, 'cup_ios.png'),
      output: join(adminAssetsDir, 'cup_ios_inverted.png'),
      action: invertImage,
    },
    // 3. Create logo_white.png by inverting logo.png
    {
      input: join(mobileAssetsDir, 'logo.png'),
      output: join(adminAssetsDir, 'logo_white.png'),
      action: invertImage,
    },
    // 4. Create cup_splash_white.png by inverting cup_splash.png for splash screen
    {
      input: join(mobileAssetsDir, 'cup_splash.png'),
      output: join(adminAssetsDir, 'cup_splash_white.png'),
      action: invertImage,
    },
  ];

  for (const task of tasks) {
    if (!existsSync(task.input)) {
      console.error(`Source file not found: ${task.input}`);
      continue;
    }
    await task.action(task.input, task.output);
  }

  console.log('='.repeat(60));
  console.log('Done! Generated files:');
  console.log('  - cup_padded_white.png (for Android adaptive icon foreground)');
  console.log('  - cup_ios_inverted.png (for iOS app icon)');
  console.log('  - logo_white.png (for splash screen on dark background)');
  console.log();
  console.log('Next steps:');
  console.log('  1. Update admin_app/pubspec.yaml splash to use logo_white.png');
  console.log('  2. Run: cd src/admin_app && flutter pub get');
  console.log('  3. Run: flutter pub run flutter_launcher_icons:main');
  console.log('  4. Run: flutter pub run flutter_native_splash:create');
  console.log('='.repeat(60));
}

main().catch(console.error);
