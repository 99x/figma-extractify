# Visual Diff Contract

## Purpose

Quantified pixel-level comparison between Playwright screenshots and Figma screenshots to supplement AI visual judgment in the Ralph Loop. This ensures measurable, reproducible visual validation before marking a component as complete.

---

## Tool

**pixelmatch** (`npm` package)

- Lightweight, zero-dependency pixel-comparison library
- Runs in Node.js
- Returns similarity percentage and generates visual diff images
- Integrates into the Ralph Loop at Step 5 (Evaluate)

---

## How it works

1. **Playwright captures** a screenshot of the preview page → PNG saved to `.screenshots/<component-name>-desktop.png`
2. **Figma MCP** (Desktop or Remote, whichever the preflight resolved) calls `get_screenshot` to fetch the design reference → **the response is an inline image in chat, not a file on disk**. The AI must explicitly write the raw PNG bytes to `.screenshots/<component-name>-figma.png` before proceeding.
3. **Visual diff script** (`scripts/visual-diff.js`) runs pixelmatch on both PNGs

> ⚠️ **Common failure mode**: `get_screenshot` returns the Figma screenshot inline to the chat context. It does NOT automatically write a file. If you skip the explicit file-write step, `visual-diff.js` will exit with "Missing Figma screenshot" and the gate cannot pass. Always confirm `.screenshots/<component-name>-figma.png` exists on disk before running the diff script.
4. **Output**:
   - Similarity percentage (e.g., 97.3%)
   - Number of differing pixels
   - Visual diff image saved to `.screenshots/<component-name>-diff.png` (differing pixels highlighted in pink)
   - JSON result printed to stdout

---

## Thresholds (quantified exit criteria)

| Category | Threshold | Notes |
|---|---|---|
| **Overall similarity** | ≥ 95% | Below this = must fix before passing visual review |
| **Color accuracy** | exact match to design tokens | Hex values must map to `--color-*` variables in `theme.pcss` |
| **Spacing tolerance** | ±4px (±0.25rem) | Acceptable within 1 Tailwind spacing unit; layout shifts beyond this require fixing |
| **Typography tolerance** | exact match to scale | Must use existing `.text-*` or `.h*` utility; custom font sizes must be justified |
| **Layout structure** | pass/fail | Same grid, same visual hierarchy; if grid differs from design → must fix |

---

## Integration with Ralph Loop

The visual diff script runs at **Step 5 (Evaluate)** of the Ralph Loop:

```
1. BUILD    → Generate/update the component
2. SERVE    → Ensure dev server running (npm run dev)
3. CAPTURE  → Playwright screenshot → .screenshots/<component-name>-desktop.png
4. COMPARE  → Figma MCP (Desktop or Remote) get_screenshot → .screenshots/<component-name>-figma.png
5. EVALUATE → Run visual-diff.js to quantify differences
6. REFINE   → If similarity < 95% or category fails → fix and loop back to step 3
7. COMPLETE → If similarity ≥ 95% and all categories pass → proceed to output checklist
```

### Decision logic at Step 5

- **If similarity ≥ 95%** AND **no individual category fails** → **Auto-pass visual review**
- **If similarity < 95%** OR **a category fails** → AI reviews the diff image (`.screenshots/<component-name>-diff.png`) to identify what needs fixing, then loops back to Step 3

---

## CLI usage

```bash
node scripts/visual-diff.js <component-name> [--threshold=95]
```

### Arguments

- `<component-name>` (required): Name of the component being tested (e.g., `hero-banner`, `button-primary`)
- `--threshold=<number>` (optional): Similarity threshold in percent (default: 95)

### Input files

The script expects:

- `.screenshots/<component-name>-desktop.png` — Playwright capture of the preview page
- `.screenshots/<component-name>-figma.png` — Figma reference screenshot

### Output

**stdout (JSON)**:

```json
{
  "component": "hero-banner",
  "similarity": 97.3,
  "diffPixels": 1240,
  "totalPixels": 46080,
  "threshold": 95,
  "passed": true,
  "diffImage": ".screenshots/hero-banner-diff.png"
}
```

**Files created**:

- `.screenshots/<component-name>-diff.png` — Visual diff image (differing pixels highlighted in pink)

**Exit codes**:

- `0` — Similarity ≥ threshold (visual review passed)
- `1` — Similarity < threshold or files missing (visual review failed)

---

## Error handling

The script handles these errors gracefully:

| Error | Behavior |
|---|---|
| Missing Playwright screenshot | Exit with error message; suggest running Playwright CLI |
| Missing Figma screenshot | Exit with error message; suggest calling `get_screenshot` |
| Image size mismatch | Resize the smaller image to match the larger one; note in stdout |
| PNG decode error | Exit with detailed error message |
| Threshold not a number | Default to 95; log warning to stderr |

---

## Breakpoint testing

When a component has responsive behavior, run the diff script at multiple breakpoints:

| Breakpoint | Viewport | Script call |
|---|---|---|
| Mobile | 375x812 | `node scripts/visual-diff.js <component-name>-mobile` |
| Desktop | 1440x900 | `node scripts/visual-diff.js <component-name>-desktop` |

Capture screenshots for both breakpoints:

```bash
# Mobile Playwright
npx playwright screenshot --browser=chromium --viewport-size=375,812 --wait-for-timeout=2000 \
  http://localhost:3000/components/<component-name> .screenshots/<component-name>-mobile.png

# Desktop Playwright
npx playwright screenshot --browser=chromium --viewport-size=1440,900 --wait-for-timeout=2000 \
  http://localhost:3000/components/<component-name> .screenshots/<component-name>-desktop.png
```

Then capture both breakpoints from Figma (if design includes mobile variant):

```bash
# Figma reference for mobile (if available)
get_screenshot → .screenshots/<component-name>-mobile-figma.png

# Figma reference for desktop
get_screenshot → .screenshots/<component-name>-desktop-figma.png
```

Then run diff for each:

```bash
node scripts/visual-diff.js <component-name>-mobile
node scripts/visual-diff.js <component-name>-desktop
```

---

## When NOT to use

- **Token extraction** — No preview page to screenshot; use doc review instead
- **Doc-only changes** — No UI to compare; manual review sufficient
- **Components without Figma reference** — Visual diff requires both Playwright and Figma PNGs
- **Typography/color spot checks** — Use this script only for full-page visual validation

---

## Workflow example

```bash
# 1. Build and serve (assumed running: npm run dev)

# 2. Capture Playwright screenshot
npx playwright screenshot --browser=chromium --viewport-size=1440,900 --wait-for-timeout=2000 \
  http://localhost:3000/components/hero-banner .screenshots/hero-banner-desktop.png

# 3. Get Figma reference (use the resolved Figma MCP — Desktop or Remote — get_screenshot tool)
# → Saves to .screenshots/hero-banner-figma.png

# 4. Run visual diff
node scripts/visual-diff.js hero-banner

# Output:
# {
#   "component": "hero-banner",
#   "similarity": 96.8,
#   "diffPixels": 1480,
#   "totalPixels": 46080,
#   "threshold": 95,
#   "passed": true,
#   "diffImage": ".screenshots/hero-banner-diff.png"
# }

# 5. Similarity ≥ 95% → Visual review passed ✓
```

---

## Integration notes

- The script does not modify component code — it only compares and reports
- Results are deterministic (same images → same result every time)
- Diff image serves as a visual guide for identifying specific problem areas
- If similarity < 95%, the AI reviews the diff image to decide what to fix
- No manual threshold tweaking — use the documented thresholds or update this doc
