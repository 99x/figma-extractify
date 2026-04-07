# Automated Accessibility Audit Integration

## Purpose

Automated WCAG 2.1 AA verification that runs as part of the Ralph Loop (between CAPTURE and COMPARE steps). Catches issues that visual comparison misses: missing ARIA attributes, color contrast failures, heading hierarchy violations, missing alt text, keyboard trap risks.

---

## Tool

**`@axe-core/playwright`** — integrates axe-core accessibility engine with Playwright. Runs in-browser against the rendered preview page.

---

## What it checks

axe-core default ruleset, WCAG 2.1 AA compliance:

- Color contrast (text vs background)
- Missing alt text on images
- Empty links / buttons
- Heading hierarchy violations
- Missing form labels
- ARIA attribute validity
- Keyboard accessibility issues
- Landmark structure
- Button and link semantics
- Form control labels and associations

---

## Integration with Ralph Loop

The audit runs as **Step 3.5** (after CAPTURE, before COMPARE):

```
Step 3   — CAPTURE (Playwright screenshot)
Step 3.5 — A11Y AUDIT (axe-core scan)
Step 4   — COMPARE (Figma visual comparison)
Step 5   — EVALUATE (layout, spacing, colors, typography)
Step 6   — REFINE (if needed, go back to step 3)
```

**Violation handling:**

- If the audit finds violations with **critical** or **serious** impact → they **must be fixed** before visual comparison proceeds.
- **Moderate** and **minor** violations are logged but don't block the loop; address them if quick, otherwise note in `learnings.md`.

---

## Script usage

```bash
node scripts/a11y-audit.js <url> [--component=<name>]
```

### Examples

```bash
# Scan a component preview
node scripts/a11y-audit.js http://localhost:3000/components/hero-banner --component=hero-banner

# Scan a page preview
node scripts/a11y-audit.js http://localhost:3000/pages/landing --component=landing

# Scan without saving detailed report
node scripts/a11y-audit.js http://localhost:3000/components/button
```

---

## Output

The script outputs:

1. **JSON to stdout** — structured results with violations grouped by impact level
2. **Detailed HTML report** (if `--component` flag provided) — saved to `.screenshots/<component-name>-a11y.json`

### JSON structure

```json
{
  "url": "http://localhost:3000/components/hero-banner",
  "component": "hero-banner",
  "timestamp": "2026-03-23T14:30:00Z",
  "summary": {
    "total_violations": 3,
    "critical": 1,
    "serious": 0,
    "moderate": 1,
    "minor": 1
  },
  "violations": {
    "critical": [
      {
        "id": "color-contrast",
        "impact": "critical",
        "description": "Ensures the contrast between foreground and background colors meets WCAG 2 AA standards for accessibility.",
        "nodes": [
          {
            "html": "<h1 style=\"color: #666;\">Hero Title</h1>",
            "target": ["h1"],
            "message": "Element has insufficient color contrast of 4.5:1 (foreground color: #666666, background color: #ffffff, font size: 16pt, font weight: normal). Expected contrast: 4.5:1"
          }
        ]
      }
    ],
    "serious": [],
    "moderate": [...],
    "minor": [...]
  },
  "passed": 15
}
```

### Console output example

```
✓ Accessibility audit for http://localhost:3000/components/hero-banner

Violations: 3 total
  🔴 critical: 1
  🟠 serious: 0
  🟡 moderate: 1
  🔵 minor: 1

✓ Passed: 15 rules

Action required: Fix 1 critical violation before proceeding.
```

---

## Severity handling

| Impact | Action |
|---|---|
| **critical** | ⛔ Block — must fix before continuing the Ralph Loop |
| **serious** | ⛔ Block — must fix before continuing the Ralph Loop |
| **moderate** | ⚠️ Log — fix if quick, otherwise note in `learnings.md` for later iteration |
| **minor** | ℹ️ Log only — address in future iteration if relevant |

---

## Known exclusions

Color contrast checks may flag false positives on:
- Gradient overlays
- Transparent backgrounds
- Decorative text over images

**Exclude per-component** by adding `data-axe-exclude="color-contrast"` to the parent element:

```tsx
<section data-axe-exclude="color-contrast" className="relative">
  {/* Content over gradient or transparent bg */}
</section>
```

---

## When to use

- **UI component creation or updates** — run as part of the Ralph Loop (Step 3.5)
- **Visual refinement iterations** — re-run after code changes
- **Accessibility-focused tasks** — verify compliance before merging

## When NOT to use

- Token extraction or design system documentation
- Doc-only changes (markdown, non-code)
- Non-visual tasks (utility functions, configuration)
- Figma-to-component mapping (Code Connect)

---

## Setup

The script requires `@axe-core/playwright` as a devDependency. If not already installed:

```bash
npm install --save-dev @axe-core/playwright
```

Playwright (`@playwright/test`) must already be installed (it is).

---

## Exit codes

| Code | Meaning |
|---|---|
| `0` | ✓ Scan completed; no critical or serious violations |
| `1` | ✗ Scan completed; 1 or more critical/serious violations found |
| `2` | ✗ Error (page not found, timeout, script error) |

---

## Integration with CI/CD

The script can be added to a pre-commit or pre-push hook to catch accessibility regressions:

```json
{
  "scripts": {
    "a11y-audit": "node scripts/a11y-audit.js"
  }
}
```

Or run selectively on changed components before code review.
