import fs from 'fs'
import path from 'path'
import { fileURLToPath } from 'url'
import { PNG } from 'pngjs'
import pixelmatch from 'pixelmatch'

const __filename = fileURLToPath(import.meta.url)
const __dirname = path.dirname(__filename)

const projectRoot = path.resolve(__dirname, '..')

function parseArgs() {
  const args = process.argv.slice(2)
  let componentName = null
  let threshold = 95

  for (const arg of args) {
    if (arg.startsWith('--threshold=')) {
      const val = parseInt(arg.split('=')[1], 10)
      if (!isNaN(val)) {
        threshold = val
      } else {
        console.warn(`Warning: Invalid threshold "${arg.split('=')[1]}", using default 95`)
      }
    } else if (!arg.startsWith('--')) {
      componentName = arg
    }
  }

  if (!componentName) {
    console.error('Usage: node scripts/visual-diff.js <component-name> [--threshold=95]')
    console.error('Example: node scripts/visual-diff.js hero-banner --threshold=95')
    process.exit(1)
  }

  return { componentName, threshold }
}

function getFilePaths(componentName) {
  const screenshotsDir = path.join(projectRoot, '.screenshots')
  return {
    playwrightPng: path.join(screenshotsDir, `${componentName}-desktop.png`),
    figmaPng: path.join(screenshotsDir, `${componentName}-figma.png`),
    diffPng: path.join(screenshotsDir, `${componentName}-diff.png`),
    screenshotsDir
  }
}

function ensureScreenshotsDir(dir) {
  if (!fs.existsSync(dir)) {
    fs.mkdirSync(dir, { recursive: true })
  }
}

function readPng(filePath) {
  if (!fs.existsSync(filePath)) {
    throw new Error(`File not found: ${filePath}`)
  }

  try {
    return PNG.sync.read(fs.readFileSync(filePath))
  } catch (err) {
    throw new Error(`Failed to parse PNG ${filePath}: ${err.message}`)
  }
}

function resizeImage(png, targetWidth, targetHeight) {
  if (png.width === targetWidth && png.height === targetHeight) {
    return png
  }

  const resized = new PNG({ width: targetWidth, height: targetHeight })

  // Simple nearest-neighbor scaling
  for (let y = 0; y < targetHeight; y++) {
    for (let x = 0; x < targetWidth; x++) {
      const srcX = Math.floor((x / targetWidth) * png.width)
      const srcY = Math.floor((y / targetHeight) * png.height)
      const srcIdx = (srcY * png.width + srcX) << 2
      const dstIdx = (y * targetWidth + x) << 2

      resized.data[dstIdx] = png.data[srcIdx]
      resized.data[dstIdx + 1] = png.data[srcIdx + 1]
      resized.data[dstIdx + 2] = png.data[srcIdx + 2]
      resized.data[dstIdx + 3] = png.data[srcIdx + 3]
    }
  }

  return resized
}

function writePng(png, filePath) {
  fs.writeFileSync(filePath, PNG.sync.write(png))
}

async function main() {
  const { componentName, threshold } = parseArgs()
  const { playwrightPng, figmaPng, diffPng, screenshotsDir } = getFilePaths(componentName)

  ensureScreenshotsDir(screenshotsDir)

  try {
    // Read both PNG files (pngjs v7+ requires buffer/sync read, not ReadStream)
    const playWrightData = readPng(playwrightPng)
    const figmaData = readPng(figmaPng)

    // Ensure same dimensions
    let pw = playWrightData
    let fm = figmaData

    const maxWidth = Math.max(pw.width, fm.width)
    const maxHeight = Math.max(pw.height, fm.height)

    if (pw.width !== maxWidth || pw.height !== maxHeight) {
      console.warn(
        `Note: Playwright screenshot (${pw.width}x${pw.height}) resized to match Figma (${maxWidth}x${maxHeight})`
      )
      pw = resizeImage(pw, maxWidth, maxHeight)
    }

    if (fm.width !== maxWidth || fm.height !== maxHeight) {
      console.warn(
        `Note: Figma screenshot (${fm.width}x${fm.height}) resized to match Playwright (${maxWidth}x${maxHeight})`
      )
      fm = resizeImage(fm, maxWidth, maxHeight)
    }

    // Create diff image
    const diff = new PNG({ width: maxWidth, height: maxHeight })

    // Run pixelmatch
    const numDiffPixels = pixelmatch(pw.data, fm.data, diff.data, maxWidth, maxHeight, {
      threshold: 0.1
    })

    const totalPixels = maxWidth * maxHeight
    const similarity = ((totalPixels - numDiffPixels) / totalPixels) * 100
    const similarityRounded = Math.round(similarity * 10) / 10

    // Write diff image
    writePng(diff, diffPng)

    // Output result
    const result = {
      component: componentName,
      similarity: similarityRounded,
      diffPixels: numDiffPixels,
      totalPixels: totalPixels,
      threshold: threshold,
      passed: similarity >= threshold,
      diffImage: `.screenshots/${componentName}-diff.png`
    }

    console.log(JSON.stringify(result, null, 2))

    // Exit with appropriate code
    process.exit(similarity >= threshold ? 0 : 1)
  } catch (error) {
    console.error(`Error: ${error.message}`)
    process.exit(1)
  }
}

main()
