# Design system setup wizard

Orchestrator workflow that spawns focused subagents per step to prevent context rot across the 6 extraction steps.

Read `_docs/structure/agent-architecture.md` for the full rationale.

## Model assignments

| Phase | Model | Runs as |
|---|---|---|
| 0: Pre-flight | Sonnet | orchestrator (this agent) |
| 1–2: Load URLs + greet | Sonnet | orchestrator (this agent) |
| 3: Each extraction step | Sonnet | subagent (one per step) |
| 4: Final summary | — | orchestrator (this agent) |

Each of the 6 extraction steps runs as a **fresh subagent** so context from Step 1 (colors) doesn't bleed into Step 3 (grid), etc.

---

## Phase 0 — Pre-flight check (run before anything else)

Silently run all checks using **3 operations only**. Show the status block. Only proceed if all required checks pass.

---

### Step 0 — Verify .mcp.json exists (before any MCP calls)

Check for `.mcp.json` in the project root:

```bash
if [ -f ".mcp.json" ]; then
  echo "MCP_CONFIG=ok"
else
  echo "MCP_CONFIG=missing"
fi
```

If `MCP_CONFIG=missing`:

1. **Auto-fix:** create `.mcp.json` using the Write tool:

```json
{
  "mcpServers": {
    "figma": {
      "type": "http",
      "url": "https://mcp.figma.com/mcp"
    },
    "figma-desktop": {
      "type": "http",
      "url": "http://127.0.0.1:3845/mcp"
    }
  }
}
```

2. Stop and output:

```
⚠️  .mcp.json was missing — created with default Figma MCP config.

    You need to restart your IDE (Claude Code / Cursor) so it picks up
    the new MCP servers. Then run /extractify-setup again.
```

Do NOT continue — MCP servers are registered at IDE startup.

---

### Step 1 — Run the system check script (single bash command)

Run this entire block as one command:

```bash
export NVM_DIR="$HOME/.nvm"; [ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh"

# 1. Node.js
NODE_VER=$(node --version 2>/dev/null)
[ -z "$NODE_VER" ] && echo "NODE=missing" || echo "NODE=$NODE_VER"

# 2. Playwright CLI (auto-install if missing)
PW_VER=$(npx playwright --version 2>/dev/null)
if [ -z "$PW_VER" ]; then
  echo "PLAYWRIGHT=installing"
  npm install -D @playwright/test --silent 2>/dev/null
  PW_VER=$(npx playwright --version 2>/dev/null)
  [ -z "$PW_VER" ] && echo "PLAYWRIGHT=install_failed" || echo "PLAYWRIGHT=$PW_VER (just installed)"
else
  echo "PLAYWRIGHT=$PW_VER"
fi

# 3. Chromium (auto-install if missing)
CHROMIUM=$(ls "$HOME/Library/Caches/ms-playwright" 2>/dev/null | grep -i "^chromium" \
  || ls "$HOME/.cache/ms-playwright" 2>/dev/null | grep -i "^chromium" || echo "")
if [ -z "$CHROMIUM" ]; then
  echo "CHROMIUM=installing"
  npx playwright install chromium 2>/dev/null
  CHROMIUM=$(ls "$HOME/Library/Caches/ms-playwright" 2>/dev/null | grep -i "^chromium" \
    || ls "$HOME/.cache/ms-playwright" 2>/dev/null | grep -i "^chromium" || echo "")
  [ -z "$CHROMIUM" ] && echo "CHROMIUM=install_failed" || echo "CHROMIUM=installed ($CHROMIUM)"
else
  echo "CHROMIUM=ok ($CHROMIUM)"
fi

# 4. Node dependencies
[ -d "node_modules" ] && echo "DEPS=ok" || echo "DEPS=missing"

# 5. .screenshots/ directory (auto-create if missing)
if [ -d ".screenshots" ]; then echo "SCREENSHOTS=ok"
else mkdir -p .screenshots && echo "SCREENSHOTS=created"; fi

# 6. figma-paths.yaml (support both root and _docs)
if [ -f "figma-paths.yaml" ]; then
  echo "YAML=ok (figma-paths.yaml)"
elif [ -f "_docs/figma-paths.yaml" ]; then
  echo "YAML=ok (_docs/figma-paths.yaml)"
else
  echo "YAML=missing"
fi
```

Read each output line and interpret:

| Output | Status |
|---|---|
| `NODE=missing` | ❌ Node not found — stop and show fix instructions |
| `NODE=v16.x.x` or lower than v18.17 | ❌ Node too old — stop and show fix instructions |
| `NODE=v18.17+` | ✅ |
| `PLAYWRIGHT=install_failed` | ❌ Playwright could not be installed — stop and show fix instructions |
| `PLAYWRIGHT=*` (any version) | ✅ |
| `CHROMIUM=install_failed` | ❌ Chromium could not be installed — stop and show fix instructions |
| `CHROMIUM=ok` or `installed` | ✅ |
| `DEPS=missing` | ❌ Stop and show fix instructions |
| `DEPS=ok` | ✅ |
| `SCREENSHOTS=ok` or `created` | ✅ |
| `YAML=missing` | create it (see below) — not a blocking failure |
| `YAML=ok (...)` | ✅ |

**If `NODE=missing`**, stop entirely and output:

```
❌ Pre-flight failed — Node.js not found.

If you use NVM, ensure it is installed at ~/.nvm.
Otherwise install Node.js 18.17+ at https://nodejs.org

Then run /extractify-setup again.
```

**If Node version is too old**, stop entirely and output:

```
❌ Pre-flight failed — Node.js version too old.

Next.js 14 requires Node.js 18.17 or higher.
Current version: <version>

Update via NVM: nvm install 20 && nvm use 20
Or install at https://nodejs.org then run /extractify-setup again.
```

**If `PLAYWRIGHT=install_failed`**, stop entirely and output:

```
❌ Pre-flight failed — could not install Playwright CLI.

Run manually:
  npm install -D @playwright/test

Then run /extractify-setup again.
```

**If `CHROMIUM=install_failed`**, stop entirely and output:

```
❌ Pre-flight failed — Chromium installation failed.

Run manually:
  npx playwright install chromium

Then run /extractify-setup again.
```

**If `DEPS=missing`**, stop entirely and output:

```
❌ Pre-flight failed — dependencies not installed.

Run the following in your project root, then run /extractify-setup again:

  npm install
```

**If `YAML=missing`**, create `figma-paths.yaml` at the project root using the Write tool (no bash needed):

```yaml
# Figma source-of-truth URLs for all setup steps and components.
# Leave a value as ~ if the URL is not yet known.

setup:
  colors: ~
  typography: ~
  grid: ~
  icons: ~
  buttons: ~
  form-elements: ~

components: {}
```

Then continue — this is not a blocking failure.
If `_docs/figma-paths.yaml` already exists (and root does not), keep using `_docs/figma-paths.yaml` to avoid splitting state.

### YAML path resolution rule (use this for all phases below)

Resolve `FIGMA_PATHS_FILE` once before Phase 1 and reuse it:

1. If `figma-paths.yaml` exists in the current project root, use it
2. Else if `_docs/figma-paths.yaml` exists, use it
3. Else create `figma-paths.yaml` in project root and use it

---

### Step 2 — Resolve Figma MCP (Desktop preferred, Remote fallback)

`/extractify-setup` reads from Figma using URLs stored in `_docs/figma-paths.yaml`, so either MCP server works. Desktop is preferred when available; if it's not, fall back to Remote. Fail only if **both** are down.

**Resolution:**

1. **Try Desktop.** For each of `user-figma`, `user-Figma Desktop`, `figma-desktop`, call `get_metadata` on the first id that exists.
   - Tool responds → ✅ Desktop available. Record `FIGMA_MCP=desktop:<id>` and proceed.
2. **If Desktop failed, try Remote.** For each of `plugin-figma-figma`, `figma`, call `get_metadata`. Classify the response:
   - Responds with data → ✅ Remote available AND authenticated. Record `FIGMA_MCP=remote:<id>` and proceed with this warning:

     ```
     ⚠️  Figma Desktop MCP unavailable — using Remote MCP as fallback.
         Setup will continue; all read tools work over Remote with URLs.
     ```
   - Returns **401 / "unauthorized" / "authentication required"** → Remote is registered but **OAuth not completed**. Stop with Block B below.
   - **Tool not found** in the toolkit → Remote is not registered. Stop with Block A below.
3. **If both failed**, stop entirely. Pick the block that matches the Remote failure mode:

**Block A — Remote not registered OR Desktop-only setup:**

```
❌ Pre-flight failed — no Figma MCP server is reachable.

Setup needs at least one of:

  • Figma Desktop MCP (http://127.0.0.1:3845/mcp)
    → Open Figma Desktop, log in, open any file, enable Dev Mode (Shift+D).
    → Dev Mode requires a paid Figma plan. More info:
      https://help.figma.com/hc/en-us/articles/15023124644247

  • Figma Remote MCP (https://mcp.figma.com/mcp) — uses OAuth
    → Verify .mcp.json at the project root contains:

        "figma": {
          "type": "http",
          "url": "https://mcp.figma.com/mcp"
        }

    → Do NOT add an X-Figma-Token header — it breaks OAuth.
    → Fully restart Claude Code / Cursor after editing .mcp.json.

Steps to fix:
  1. Enable at least one of the servers above
  2. Restart the IDE — MCP connections are established at startup
  3. Run /extractify-setup again

For a full guided check, run /extractify-preflight.
```

**Block B — Remote registered but not authenticated (401):**

```
❌ Pre-flight failed — Figma Remote MCP needs OAuth.

Quick fix:
  Claude Code → /mcp → `figma` → Authenticate → restart IDE.
  Cursor      → MCP Settings → `figma` → Authenticate → restart Cursor.

Or enable Figma Desktop MCP (open Dev Mode) to skip OAuth entirely.

Full walkthrough and troubleshooting:
  → _docs/structure/figma-mcp-setup.md
  → or run /extractify-preflight for the guided check

Then run /extractify-setup again.
```

All subsequent `get_metadata` / `get_design_context` / `get_screenshot` / `get_variable_defs` calls in this workflow should be made against the resolved `FIGMA_MCP` server.

---

### Status block

Show this before the wizard greeting. Adjust each line to reflect actual results. Stop if any ❌ is present.

```
Pre-flight check
────────────────────────────────────
  ✅  Node.js                   v20.x.x
  ✅  .mcp.json                 found (figma + figma-desktop)
  ✅  Figma MCP                 Desktop (primary)   ← or "Remote (fallback)"
  ✅  Playwright + Chromium     ready (v1.x.x)
  ✅  Node dependencies         installed
  ✅  .screenshots/             ready
  ✅  figma-paths.yaml          found

────────────────────────────────────
Ready to run setup. Starting wizard…
```

---

## Phase 1 — Load saved URLs (orchestrator)

Read `FIGMA_PATHS_FILE` and load all URLs:

- `setup.colors` → Step 1
- `setup.typography` → Step 2
- `setup.grid` → Step 3
- `setup.icons` → Step 4
- `setup.buttons` → Step 5
- `setup.form-elements` → Step 6

A field is empty if its value is `~`, blank, or missing.

---

## Phase 2 — Greet and show pipeline (orchestrator)

Greet the user and display the pipeline. Mark steps that already have a saved URL with `(URL saved)`.

```
Design System Setup — 6 steps

  [1/6] Colors         → theme.pcss (--color-* tokens)
  [2/6] Typography     → theme.pcss (--font-*) + typography.pcss
  [3/6] Grid           → theme.pcss (breakpoints) + grid.pcss (container)
  [4/6] Icons / SVG    → public/svg/ux/ (SVG files)
  [5/6] Buttons        → buttons.pcss (.button-* classes) + Button component
  [6/6] Form Elements  → forms.pcss + form components

You can skip any step by typing "skip".
```

Then move directly to Step 1.

---

## Phase 3 — Run each step

### Step prompt format (orchestrator handles all user interaction)

**URL already saved** — before showing any choices:

1. Extract `nodeId` and `fileKey` from the saved URL
2. Call `get_screenshot → { nodeId, fileKey }` and display the image inline
3. Then use AskUserQuestion with these choices:
   - `Use saved URL` → proceed with the saved URL as-is
   - `Enter a different URL` → ask the user to paste the new URL as a follow-up message, then save and proceed
   - `Skip this step` → skip step

This lets the user visually confirm the correct Figma frame before committing.

**No URL saved** — ask the user to paste the Figma URL as a plain message (no AskUserQuestion needed — it's free text). Include a note: "Type `skip` to skip this step."

- Response starts with `https://` → extract `nodeId` + `fileKey`, call `get_screenshot`, display the image, then save and proceed
- Response is `skip` → skip step

After each step: save the URL back to `FIGMA_PATHS_FILE`, confirm completion, then move to the next step.

### Preview and confirmation (orchestrator — required before spawning extraction subagent)

After confirming the Figma URL, the orchestrator:

1. Reads the current state of files that will be modified (e.g. `theme.pcss` content for colors step)
2. Spawns the extraction subagent (see step-specific prompts below)
3. When the subagent returns its summary, display it to the user
4. Use AskUserQuestion with these choices:
   - `Apply to codebase` → the subagent already applied the changes; confirm and move on
   - `Adjust first` → ask what to change as a follow-up, spawn a new subagent with the adjustment instructions
   - `Skip this step` → revert the subagent's changes (re-write original file contents) and move on

---

### Step 1 — Colors (subagent: Sonnet)

1. Orchestrator prompts the user using the step prompt format above
2. On URL received, read `src/assets/css/base/theme.pcss` (current content), then spawn a subagent with `model: "sonnet"`:

```
You are a design systems engineer extracting tokens from Figma into a codebase. Precision matters — a wrong hex value, a misnamed token, or a missed variant will cascade into every component built on top of these tokens. Extract exactly what exists in the design, normalize names to project conventions, and never invent tokens that aren't in the source.

---

Extract and apply color tokens for the design-extractify project.

**Figma URL:** {url}

**Step 1 — Read the contract doc:**
Read `_docs/front-end/01-colors.md` completely.

**Step 2 — Extract from Figma:**
Call `get_design_context` with nodeId and fileKey from the Figma URL.
Extract all color variables/styles following the checklist in 01-colors.md.
Normalize names to --color-* tokens (kebab-case, / → -).

**Step 3 — Merge with defaults:**
These three defaults must ALWAYS be present:
- --color-pure-white: #ffffff
- --color-pure-black: #000000
- --color-red: #E74C3C

Merge logic for pure-white and pure-black — match by exact hex only:
- white: #f5f5f5 is NOT pure-white → both coexist
- Exact hex match found → rename to default name
- No match → add default alongside Figma tokens

Merge logic for red — match by name OR hex:
- If Figma has a color with "red", "danger", or "error" in the name (case-insensitive), OR hex hue ~340°–10° → use it as --color-red, remove #E74C3C
- If no red found → keep --color-red: #E74C3C

**Step 4 — Apply to codebase:**
- Replace the /* colors */ section in src/assets/css/base/theme.pcss
- Update src/app/assets/colors/page.tsx to reflect the new tokens
  CRITICAL: always include the full Tailwind class as a static string in the data array (e.g. bg: 'bg-brand-primary'), never use template literals like bg-$\{token\}

**Return:** a table of Figma name → repo token → hex (mark defaults with [default]), count of tokens applied, and list of files modified.
```

3. On skip: "⏭️ Step 1 skipped — colors unchanged." then move to Step 2
   - ⚠️ Even when skipped: if `theme.pcss` doesn't already contain the three default tokens, add them without touching anything else

---

### Step 2 — Typography (subagent: Sonnet)

1. Orchestrator prompts the user using the step prompt format above
2. On URL received, read `src/assets/css/base/theme.pcss` and `src/assets/css/base/typography.pcss` (current content), then spawn a subagent with `model: "sonnet"`:

```
You are a design systems engineer extracting typography tokens from Figma. Typography is the most visible part of any design system — wrong font sizes, missing responsive rules, or incorrect line-heights will be immediately noticeable. Cross-reference every value against the Figma source and the contract doc. When Figma values conflict with the contract, follow the contract and note the discrepancy.

---

Extract and apply typography tokens for the design-extractify project.

**Figma URL:** {url}

**Step 1 — Read the contract doc:**
Read `_docs/front-end/02-typography.md` completely.

**Step 2 — Extract from Figma:**
Call `get_design_context` with nodeId and fileKey from the Figma URL.
Also call `get_variable_defs` with the same nodeId and fileKey for accurate type values.
Extract font families, weights, and all text styles (size, line-height, responsive rules).

**Step 3 — Apply to codebase:**
- Update the /* fonts */ section in src/assets/css/base/theme.pcss
- Replace src/assets/css/base/typography.pcss — follow the file replacement rules in 02-typography.md
- If Google Fonts: update src/app/layout.tsx to use next/font/google (see _docs/front-end/02-typography.md)
- If self-hosted: create src/assets/css/base/fonts.pcss with @font-face rules and import in global.css
- Update src/app/assets/typography/page.tsx to render the new utilities

**Return:** a table of Figma style → CSS utility → desktop spec → mobile spec, count of styles applied, and list of files modified.
```

3. On skip: "⏭️ Step 2 skipped — typography unchanged." then move to Step 3

---

### Step 3 — Grid / Container (subagent: Sonnet)

1. Orchestrator prompts the user using the step prompt format above
2. On URL received, read `src/assets/css/base/theme.pcss`, `src/assets/css/base/grid.pcss`, and `src/components/Guidelines/index.tsx` (current content), then spawn a subagent with `model: "sonnet"`:

```
You are a design systems engineer extracting layout and grid tokens from Figma. The grid system is the structural foundation — breakpoints, container widths, and padding values must be exact because every component relies on them. Convert all pixel values to rem precisely (1rem = 16px). When the Figma grid doesn't map cleanly to the existing system, choose the closest match and document the decision.

---

Extract and apply grid/container tokens for the design-extractify project.

**Figma URL:** {url}

**Step 1 — Read the contract doc:**
Read `_docs/front-end/03-grid-container.md` completely.

**Step 2 — Extract from Figma:**
Call `get_design_context` with nodeId and fileKey from the Figma URL.
Extract breakpoints (name + px), container max-width, side padding per breakpoint, gutter.

**Step 3 — Apply to codebase:**
- Apply breakpoints to src/assets/css/base/theme.pcss under /* breakpoints */ (convert px → rem)
- Update @utility base-container in src/assets/css/base/grid.pcss to match container specs
- This project uses Tailwind grid utilities only — do NOT add .row/.col-* helpers
- If src/components/Guidelines/index.tsx exists: update the `gap-{n}` class on the grid div to match the extracted gutter (e.g. gutter 24px → gap-6, 16px → gap-4, 32px → gap-8). If the file does not exist, skip silently.

**Return:** breakpoints table + container summary, and list of files modified.
```

3. On skip: "⏭️ Step 3 skipped — grid unchanged." then move to Step 4

---

### Step 4 — Icons / SVG (subagent: Sonnet)

1. Orchestrator prompts the user using the step prompt format above
   - Add this note to the prompt: "SVG files cannot be exported automatically via MCP. I will read the icon metadata from Figma and give you exact export instructions. You will add the SVG files manually to `public/svg/ux/`."
2. On URL received, spawn a subagent with `model: "sonnet"`:

```
You are an icon systems specialist cataloging a Figma icon library for developer handoff. Your checklist will be used by the user to manually export SVGs — if you miss an icon, misspell a filename, or give wrong cleanup instructions, the developer will waste time fixing it. Be exhaustive: list every icon, double-check naming against kebab-case conventions, and provide clear, actionable export instructions.

---

Extract icon metadata for the design-extractify project.

**Figma URL:** {url}

**Step 1 — Read the contract doc:**
Read `_docs/front-end/05-icons-svg.md` completely.

**Step 2 — Extract from Figma:**
Call `get_design_context` with nodeId and fileKey from the Figma URL.
List all icon names and structure.

**Step 3 — Generate export checklist:**
- Table: Figma name → kebab-case filename → public/svg/ux/<name>.svg
- Export settings reminder (SVG, no id, contents only, viewBox preserved)
- Cleanup instructions (remove hardcoded fill/stroke, strip metadata, add currentColor if needed)

**Return:** the export checklist table, count of icons found, and cleanup instructions.
```

3. After the subagent returns, display the checklist and ask: "Have you exported and added the SVG files to `public/svg/ux/`? Type 'done' when ready, or 'skip' to come back later."
4. On done: "✅ Step 4 complete — N icons documented."
5. On skip: "⏭️ Step 4 skipped — icons not extracted." then move to Step 5

---

### Step 5 — Buttons (subagent: Sonnet)

1. Orchestrator prompts the user using the step prompt format above
2. On URL received, read `src/assets/css/base/buttons.pcss` (current content), then spawn a subagent with `model: "sonnet"`:

```
You are a design systems engineer extracting interactive component tokens from Figma. Buttons are the most frequently reused interactive element — every variant needs complete state coverage (default, hover, focus-visible, disabled). Missing a hover state or getting a border-radius wrong will be visible across the entire application. Extract all states for every variant, and verify that the generated CSS matches the Figma spec exactly.

---

Extract and apply button variants for the design-extractify project.

**Figma URL:** {url}

**Step 1 — Read the contract doc:**
Read `_docs/front-end/06-buttons.md` completely.
Also read `_docs/structure/consistency-rules.md` (for Rule 5 and 6).

**Step 2 — Extract from Figma:**
Call `get_design_context` with nodeId and fileKey from the Figma URL.
List all button variants found (e.g. primary, secondary, ghost) — normalize to kebab-case.
For each variant, extract: background, text color, border, border-radius, padding, font-weight, hover/focus-visible/disabled states.

**Step 3 — Apply to codebase:**
- Add a .button-{variant} class to src/assets/css/base/buttons.pcss for each variant — follow the @apply rules in 06-buttons.md
- Preserve existing non-button utilities: .hover-underline, .hover-underline-white — do not remove
- Create src/components/Button/index.tsx following the contract in 06-buttons.md
- Create preview page at src/app/components/button/page.tsx rendering all variants
- Add link to src/app/page.tsx

**Return:** a table of variant name → CSS class → key styles, count of variants, and list of files modified.
```

3. On skip: "⏭️ Step 5 skipped — buttons unchanged." then move to Step 6

---

### Step 6 — Form Elements (subagent: Sonnet)

1. Orchestrator prompts the user using the step prompt format above
   - Add this note: "The form elements contract (`_docs/front-end/07-form-elements.md`) may still be a placeholder. If it has not been filled in yet, skip this step."
2. On URL received, spawn a subagent with `model: "sonnet"`:

```
You are a design systems engineer extracting form element patterns from Figma. Forms are where users interact most — input styles, validation states, label positioning, and spacing must all be precise. Pay special attention to focus states and error states, which are often the most inconsistently implemented. If the contract doc is incomplete, stop immediately rather than guessing.

---

Extract and apply form element styles for the design-extractify project.

**Figma URL:** {url}

**Step 1 — Read the contract doc:**
Read `_docs/front-end/07-form-elements.md` completely.

If the doc is still a placeholder or nearly empty, STOP and return:
"PLACEHOLDER — the form elements contract is not yet defined."

**Step 2 — Extract from Figma:**
Call `get_design_context` with nodeId and fileKey from the Figma URL.
Extract form element styles following the contract doc.

**Step 3 — Apply to codebase:**
Follow the instructions in 07-form-elements.md for file creation and styling.

**Return:** summary of form elements applied, or "PLACEHOLDER" if the doc is not ready.
```

3. If subagent returns "PLACEHOLDER" → inform the user: "The form elements contract is not yet defined. Please fill in `07-form-elements.md` before running this step." and recommend skipping.
4. On skip: "⏭️ Step 6 skipped — form elements unchanged." then move to final summary

---

## Phase 4 — Final summary (orchestrator)

After all 6 steps are resolved, output:

```
Design system setup complete.

  ✅ [1/6] Colors         — N tokens applied to theme.pcss
  ✅ [2/6] Typography     — N styles applied to typography.pcss
  ⏭️ [3/6] Grid           — skipped
  ✅ [4/6] Icons / SVG    — N icons documented
  ✅ [5/6] Buttons        — N variants applied to buttons.pcss
  ⏭️ [6/6] Form Elements  — skipped

Files updated:
  src/assets/css/base/theme.pcss
  src/assets/css/base/typography.pcss
  src/assets/css/base/buttons.pcss
  src/components/Button/index.tsx
  src/app/assets/colors/page.tsx
  src/app/assets/typography/page.tsx
  src/app/components/button/page.tsx
  public/svg/ux/ (manual export required)

Next steps:
  → Run `npm run dev` and review http://localhost:3000/assets/colors
  → Review http://localhost:3000/assets/typography
  → Review http://localhost:3000/components/button
  → Start building components with /extractify-new-component <name>
```

Update `_docs/learnings.md` if any edge cases or Figma naming quirks were discovered.
