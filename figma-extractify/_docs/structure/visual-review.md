## Visual review protocol (Ralph Loop)

This doc defines the visual refinement loop that must be executed for every UI task (component creation, page creation, or visual update).

---

### Why this exists

Components are built from Figma specs. Without automated visual comparison, drift between design and implementation goes unnoticed until a designer reviews the output. The visual review loop catches these issues during development, not after.

This project uses the **Ralph Loop pattern** — an iterative self-correction cycle where each iteration sees the result of the previous one and keeps refining until the output matches the Figma source of truth.

---

### Prerequisites

| Tool | Configuration | Purpose |
|---|---|---|
| **Figma MCP** (Desktop or Remote) | Connected via Claude (preflight resolves the server — Desktop preferred, Remote fallback) | Source of truth for design specs and screenshots |
| **Playwright CLI** | `npm install -D @playwright/test` + `npx playwright install chromium` | Takes screenshots of preview pages for comparison |
| **Dev server** | `npm run dev` (port 3000) | Renders preview pages locally |

---

### The loop (step by step)

#### Step 1 — Build

Generate or update the component following all project rules (`CLAUDE.md`, `_docs/start-here.md`, component contract).

#### Step 2 — Serve

Ensure the dev server is running:

```bash
npm run dev
```

If already running, verify it is responding on `http://localhost:3000`.

#### Step 3 — Capture (Playwright CLI)

Use the Playwright CLI via bash to take a screenshot. Screenshots are saved to `.screenshots/` in the project root.

```bash
# Component
npx playwright screenshot --browser=chromium --viewport-size=1440,900 --wait-for-timeout=2000 \
  http://localhost:3000/components/<component-name> .screenshots/<component-name>-desktop.png

# Full-page component or page
npx playwright screenshot --browser=chromium --viewport-size=1440,900 --full-page --wait-for-timeout=2000 \
  http://localhost:3000/pages/<page-name> .screenshots/<page-name>-desktop.png
```

Then read the saved file to view it:

```
Read → .screenshots/<component-name>-desktop.png
```

#### Step 4 — Compare (Figma)

Use the resolved Figma MCP (Desktop if available, otherwise Remote) to get the design reference:

```
get_design_context → { nodeId, fileKey } from the Figma URL
```

This returns both a screenshot and structured design data (spacing, colors, typography).

If you only need the visual reference:

```
get_screenshot → { nodeId, fileKey }
```

#### Step 3.5 — Accessibility audit (axe-core)

Run the automated a11y scan before visual comparison. See `_docs/structure/a11y-audit.md` for full details.

```bash
node scripts/a11y-audit.js http://localhost:3000/components/<component-name> --component=<component-name>
```

**Blocking violations** (critical / serious impact) must be fixed before proceeding to Step 4. Moderate and minor violations are logged but don't block the loop.

If `@axe-core/playwright` is not installed, run: `npm install -D @axe-core/playwright`

#### Step 4.5 — Quantified pixel diff (pixelmatch)

After capturing the Figma reference screenshot, run the pixel-diff script. See `_docs/structure/visual-diff.md` for full details.

First, save the Figma screenshot as `.screenshots/<component-name>-figma.png`, then:

```bash
node scripts/visual-diff.js <component-name> --threshold=95
```

If `pixelmatch` or `pngjs` are not installed, run: `npm install -D pixelmatch pngjs`

The script outputs a similarity percentage and a diff image. Use the result to guide the evaluation in Step 5.

#### Step 5 — Evaluate

Combine the pixel-diff result with visual inspection. Check each dimension against its **quantified threshold**:

| Dimension | Threshold | How to verify |
|---|---|---|
| **Overall similarity** | ≥ 95% (from pixelmatch) | Script output — auto-pass if met |
| **Layout structure** | Pass/fail | Same grid, same visual hierarchy, same element order |
| **Spacing** | ±4px (±0.25rem) | Inspect via browser DevTools or Figma design context structured data |
| **Sizing** | ±4px for containers, exact for aspect ratios | Check widths, heights, aspect ratios against Figma spec |
| **Colors** | Exact match to design tokens | Every color must map to a `--color-*` variable — no hardcoded hex |
| **Typography** | Exact match to scale | Must use existing `.text-*` or `.h*` utility — no arbitrary font sizes |
| **Alignment** | ±2px | Horizontal and vertical alignment of elements |
| **Interactive states** | Implemented | Hover, focus, active states match design (visual check) |

**Auto-pass rule**: If pixelmatch similarity ≥ 95% AND no individual dimension fails → the iteration passes without further inspection.

**Fail rule**: If ANY dimension fails its threshold → fix is required. The diff image (`.screenshots/<name>-diff.png`) highlights exactly where differences are.

#### Step 6 — Refine

If differences are found:

1. Review the diff image to identify exact areas of mismatch
2. Cross-reference with the axe-core report for any a11y-related visual issues
3. Identify the specific CSS or markup causing the mismatch
4. Fix the code
5. **Go back to Step 3** (capture a new screenshot, re-run a11y audit, re-run pixel diff)

#### Step 7 — Complete

The loop exits when ALL of these are true:

1. Pixelmatch similarity ≥ 95%
2. No individual dimension fails its threshold
3. No critical or serious a11y violations remain
4. All breakpoints tested (if responsive)

Then proceed to the output checklist in `CLAUDE.md`.

---

### Exit conditions

The loop ends when **any** of these conditions are met:

| Condition | Action |
|---|---|
| **All thresholds pass** — pixelmatch ≥ 95%, no dimension fails, no blocking a11y violations, all breakpoints tested | Mark task as complete |
| **Maximum 5 iterations** reached | Stop — log remaining differences in `learnings.md` with specific measurements (e.g., "spacing is 32px vs expected 24px, pixelmatch at 91%") |
| **Figma URL or node is not available** | Skip visual review, note it in task output |
| **Dev server cannot start** | Skip visual review, note the error |
| **Pixel diff tools not installed** | Fall back to AI-only visual comparison (original behavior), note in task output |

### Quantified exit criteria (detailed)

When the loop ends (pass or max iterations), the final status must include these measurements:

```
Visual review — final status
─────────────────────────────────
  Pixelmatch similarity:  97.3%  (threshold: 95%)  ✅
  A11y critical/serious:  0      (threshold: 0)    ✅
  A11y moderate/minor:    2      (logged)
  Layout structure:       pass                      ✅
  Spacing accuracy:       ±2px                      ✅
  Color token coverage:   100%                      ✅
  Typography match:       100%                      ✅
  Iterations used:        2/5
─────────────────────────────────
  Result: PASS
```

If max iterations reached, the same block must show which dimensions still fail, with exact measurements.

---

### Responsive testing

When the component has responsive behavior, the loop must run at multiple breakpoints:

| Breakpoint | Viewport | When to test |
|---|---|---|
| Desktop | 1440 x 900 | Always |
| Mobile | 375 x 812 | If the design has a mobile-specific layout |

Use Playwright CLI with the appropriate `--viewport-size` for each breakpoint:

```bash
# Mobile
npx playwright screenshot --browser=chromium --viewport-size=375,812 --wait-for-timeout=2000 \
  http://localhost:3000/components/<name> .screenshots/<name>-mobile.png

# Desktop
npx playwright screenshot --browser=chromium --viewport-size=1440,900 --wait-for-timeout=2000 \
  http://localhost:3000/components/<name> .screenshots/<name>-desktop.png
```

Then read each file with the `Read` tool to compare against Figma.

Compare each viewport against the corresponding Figma frame.

---

### What to check at each breakpoint

| Check | What to look for |
|---|---|
| Container width | Does `.base-container` match the Figma container at this breakpoint? |
| Column layout | Do columns stack correctly on mobile? |
| Font sizes | Do typography utilities switch to mobile sizes? |
| Spacing | Do paddings and gaps adjust for the breakpoint? |
| Hidden elements | Are elements that should hide on mobile actually hidden? |
| Image aspect ratios | Do images maintain correct proportions? |

---

### Comparison strategies

#### Standard comparison (default — recommended)

Combines automated tooling with AI judgment:

1. **Pixelmatch** — quantified similarity score + diff image (`scripts/visual-diff.js`)
2. **axe-core** — automated a11y violations (`scripts/a11y-audit.js`)
3. **AI visual review** — review diff image for context (what specifically is different and why)

This is the default for all components. The automated tools catch measurable issues; the AI catches semantic issues (wrong visual hierarchy, incorrect responsive behavior).

#### Quick comparison (fallback)

Side-by-side visual inspection only. Use when pixelmatch/axe-core are not installed or when comparing against a Figma frame that has significantly different dimensions.

#### Deep comparison (for pixel-critical UI)

All of standard comparison, plus:

1. Get Figma design context (returns structured data: spacing values, colors, font specs)
2. Use the structured data to validate specific CSS properties against the design spec
3. Focus on measurable properties: exact padding values, color hex codes, font sizes in rem
4. Compare at both desktop and mobile breakpoints regardless of whether mobile design exists

---

### Logging

After the loop completes, if any issues were found and fixed during iterations, add an entry to `_docs/learnings.md` with:

- What was wrong (e.g., "padding-top was 2rem instead of 1.5rem")
- What Figma said vs what was generated
- The fix applied

This helps prevent the same mistakes in future components.

---

### Enforced iteration with ralph-loop (recommended)

The visual review loop can be wrapped in the **ralph-loop** stop hook, which prevents Claude from exiting until the quantified exit criteria are objectively met. This eliminates the risk of Claude approving "close enough" results.

#### How to use it

Instead of running `/extractify-new-component hero` directly, wrap it:

```
/ralph-loop /extractify-new-component hero --completion-promise "VISUAL_REVIEW_PASS" --max-iterations 8
```

Claude will:

1. Build the component, run compliance, start visual review
2. Try to exit when it thinks it's done
3. The stop hook checks if `VISUAL_REVIEW_PASS` appears in the output
4. If not → blocks exit, re-injects the prompt, Claude sees all previous changes and continues
5. Repeat until `VISUAL_REVIEW_PASS` is genuinely output or 8 iterations hit

#### When to output the completion promise

The Opus visual review subagent (or the orchestrator) should output `VISUAL_REVIEW_PASS` **only** when ALL of these are true:

- Pixelmatch similarity ≥ 95%
- Zero critical/serious a11y violations
- No individual dimension fails its threshold
- All required breakpoints tested

This maps directly to the quantified exit criteria defined above.

#### When NOT to use ralph-loop

- Quick exploration or prototyping (where "good enough" is fine)
- Token extraction tasks (`/extractify-setup`) — no visual review involved
- When you want manual control over iteration decisions

---

### When the visual review loop does NOT apply

- Design token extraction tasks (colors, typography, grid) — no visual rendering needed
- Documentation-only changes
- Utility function changes
- Tasks where no Figma URL or node is provided

In these cases, skip the loop and proceed directly to the output checklist.
