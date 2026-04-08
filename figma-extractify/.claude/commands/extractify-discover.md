# Design system discovery

Orchestrator workflow that scans all pages of a Figma file, reverse-engineers the implicit design system, and pushes a structured DS page back into Figma.

Use this when the design team has not created a formal design system page — this skill discovers the tokens from the actual designs.

Read `_docs/structure/agent-architecture.md` for the full rationale on subagent orchestration and role framing.

## Prerequisites

- **Figma desktop app** with the desktop MCP server enabled (required for write-back)
- **Figma remote MCP** for read access (link-based extraction)
- Dev or Full seat on a paid Figma plan

## Model assignments

| Phase | Model | Runs as |
|---|---|---|
| 0: Pre-flight | Sonnet | orchestrator (this agent) |
| 1: Map file structure | Sonnet | orchestrator (this agent) |
| 2: Scan pages (per page) | Sonnet | subagent (one per page) |
| 3: Analyze & normalize | Sonnet | subagent (single) |
| 4: Review with user | — | orchestrator (this agent) |
| 5: Generate DS HTML | Sonnet | subagent (single) |
| 6: Push to Figma | Sonnet | orchestrator (this agent) |

---

## Phase 0 — Pre-flight check

### Step 1 — System check (same as /extractify-preflight)

Run the same bash script from `/extractify-preflight`. Only Node.js and deps are blocking — Playwright/Chromium are not required for this skill.

### Step 2 — Check Figma Desktop MCP (read access)

First resolve the Desktop server id from the MCP servers available in the current environment.

Try these candidates in order and use the first one that exists:

- `user-figma`
- `user-Figma Desktop`
- `figma-desktop`

Then try calling `get_metadata` using that resolved Desktop server id.

- Tool responds (even with an error) → ✅ Figma Desktop MCP available
- Tool not found / connection refused → ❌ Stop with setup instructions (same as `/extractify-preflight`)

### Step 3 — Check Figma write-back (remote MCP only)

`generate_figma_design` is available **only on the remote MCP** (`https://mcp.figma.com/mcp`) and **only in Claude Code**. It does NOT exist on the desktop MCP.

First resolve the Remote server id from the MCP servers available in the current environment.

Try these candidates in order and use the first one that exists:

- `plugin-figma-figma`
- `figma`

Then try calling `generate_figma_design` with a minimal test payload.

- Tool exists (even if it errors) → ✅ Write-back available
- Tool not found → ⚠️ Write-back disabled

**How `generate_figma_design` works:**
1. Claude calls the tool → Figma returns a `captureId`
2. Claude injects a capture script into the running HTML page
3. Claude opens the browser: `http://localhost:<port>#figmacapture=<id>&figmaendpoint=<url>`
4. The script captures the rendered DOM and sends it to Figma's servers
5. Claude polls until complete → returns a Figma file URL

**Requirement:** The design system HTML must be served on localhost (not a static file) for the capture to work. Phase 5 handles this by creating a Next.js preview route.

If ⚠️, warn the user:

```
⚠️  generate_figma_design not available — write-back to Figma will be disabled.

This tool requires the remote Figma MCP (https://mcp.figma.com/mcp) and only
works in Claude Code. The desktop MCP does not support write-back.

The skill will still analyze your file and generate the design system spec.
You can manually import the generated HTML page into Figma using html.to.design
or a similar plugin.

To enable write-back:
  1. Ensure the remote Figma MCP is configured and authenticated:

     "mcpServers": {
       "figma": {
         "url": "https://mcp.figma.com/mcp"
       }
     }

  2. Restart Claude Code — it will prompt you to authenticate with Figma
  3. Run /extractify-discover again
```

Continue with analysis-only mode if the user agrees.

### Status block

```
Pre-flight check
────────────────────────────────────
  ✅  Node.js                   v20.x.x
  ✅  Figma Desktop MCP         connected
  ✅  generate_figma_design     available (write-back enabled)
  ✅  Node dependencies         installed

────────────────────────────────────
Ready to discover. Starting scan…
```

---

## Phase 1 — Map file structure (orchestrator)

### Step 1 — Get Figma URL

Ask the user to paste the Figma file URL. Extract `fileKey` from it.

### Step 2 — Get file structure

Call `get_design_context` with `{ nodeId: "0:0", fileKey: "<fileKey>" }` to get the top-level file structure.

Parse the response to identify all pages and their top-level frames.

### Step 3 — Show pages and confirm scope

Display the discovered pages:

```
Found N pages in your Figma file:

  [1] Home                    (12 frames)
  [2] About                   (8 frames)
  [3] Contact                 (5 frames)
  [4] Blog Post               (6 frames)
  [5] Course Detail           (9 frames)
  ...

Which pages should I analyze?
```

Use AskUserQuestion:
- `All pages` → scan everything
- `Select pages` → ask which page numbers to include
- `Only the most complex pages` → pick the 3–4 pages with the most frames (these will have the most variety)

### Step 4 — Check for existing design system page

Look through the page names for common DS page names: "Design System", "Styles", "Tokens", "Components", "UI Kit", "Foundation", etc.

If found, warn the user:

```
I found a page that might already be a design system: "{pageName}"

Should I skip analysis and use this page for /extractify-setup instead?
```

Use AskUserQuestion:
- `Use existing page` → redirect to `/extractify-setup` with this page's URL
- `Analyze anyway` → continue with discovery (useful if the DS page is incomplete)

---

## Phase 2 — Scan pages (subagents: Sonnet, one per page)

For each selected page, spawn a subagent with `model: "sonnet"`.

**Important:** Do NOT spawn all subagents at once. Run them sequentially (one page at a time) to stay within MCP rate limits. After each subagent completes, briefly summarize what was found before moving to the next page.

Pass this prompt (fill in `{placeholders}`):

```
You are a design token archaeologist. Your job is to catalog every visual property in this Figma page — colors, type styles, spacing values, border radii, shadows, and interactive patterns. Be exhaustive: a token that exists in the design but is missing from your report will be missing from the entire design system.

Do not interpret or normalize yet — extract raw values exactly as they appear. The analysis phase will handle deduplication and naming.

---

Scan a single Figma page and extract all design tokens.

**File key:** {fileKey}
**Page name:** {pageName}
**Page node ID:** {nodeId}

**Step 1 — Extract design context:**
Call `get_design_context` with the nodeId and fileKey.
If the page has many frames, you may need to call `get_design_context` on individual top-level frames to get full detail.

Also call `get_variable_defs` with the same nodeId and fileKey to get any defined variables/styles.

**Step 2 — Catalog every token found:**

For each category below, extract ALL unique values found anywhere on the page:

**Colors:**
- Every unique hex/rgba value used for: fills, strokes, backgrounds, text colors
- Note where each color is used (e.g. "heading text", "card background", "button fill")
- Note approximate frequency (used once vs used everywhere)

**Typography:**
- Every unique combination of: font-family, font-size, font-weight, line-height, letter-spacing
- Note where each style is used (e.g. "main heading", "body text", "caption")
- Note if any text styles are defined as Figma styles (not just raw values)

**Spacing:**
- Padding values on containers and sections
- Gap values between elements
- Margin patterns between sections
- Note which values appear most frequently

**Border radius:**
- Every unique border-radius value
- Note what it's applied to (cards, buttons, inputs, images)

**Shadows:**
- Every unique box-shadow definition (x, y, blur, spread, color)
- Note what it's applied to

**Buttons and interactive elements:**
- All button-like elements: background, text color, border, radius, padding, font
- Group by visual similarity (these are likely variants)
- Note any hover/pressed/disabled state variants if visible

**Container / layout:**
- Maximum content width
- Side padding/margins at different apparent breakpoints
- Column count and gutter width if a grid is visible

**Icons:**
- Count of unique icon shapes
- Approximate sizes used
- Whether they appear as components or flattened SVGs

**Step 3 — Return structured JSON:**

Return a JSON object with this exact structure:

{
  "page": "{pageName}",
  "colors": [
    { "hex": "#1A1A1A", "usage": ["heading text", "body text"], "frequency": "high" }
  ],
  "typography": [
    { "family": "Poppins", "size": "16px", "weight": 400, "lineHeight": "24px", "letterSpacing": "0", "usage": ["body text"], "isStyle": false }
  ],
  "spacing": [
    { "value": "24px", "usage": ["section padding"], "frequency": "high" }
  ],
  "borderRadius": [
    { "value": "8px", "usage": ["cards"], "frequency": "medium" }
  ],
  "shadows": [
    { "definition": "0 2px 4px rgba(0,0,0,0.1)", "usage": ["cards"] }
  ],
  "buttons": [
    { "label": "primary-like", "bg": "#2563EB", "text": "#FFF", "border": "none", "radius": "8px", "padding": "12px 24px", "font": "Poppins 600 16px" }
  ],
  "containers": [
    { "maxWidth": "1200px", "sidePadding": "24px" }
  ],
  "iconCount": 12,
  "iconSizes": ["24px", "16px"]
}

Do NOT normalize or rename — use raw values from Figma. Return ONLY the JSON, no commentary.
```

After each subagent returns, parse the JSON and store it. Show a brief summary:

```
✅ Page "Home" scanned — 24 colors, 8 type styles, 5 button variants found
```

---

## Phase 3 — Analyze & normalize (subagent: Sonnet)

After all pages are scanned, merge the results and spawn a single subagent with `model: "sonnet"`.

Pass this prompt:

```
You are a design systems architect. You've been given raw, messy, duplicated token data extracted from multiple Figma pages. Your job is to build a clean, normalized, deduplicated design system from this raw data.

Your output will be used to generate a design system reference page and applied to a codebase. Errors here cascade everywhere — be precise, be opinionated about naming, and explain your decisions.

---

Analyze and normalize extracted design tokens into a coherent design system.

**Raw token data from {N} pages:**

{paste merged JSON array from Phase 2}

**Step 1 — Color analysis:**
- Cluster similar colors (within ΔE < 3 perceptual difference) — these are likely the same token used inconsistently
- For each cluster: pick the most-used hex as the canonical value
- Name tokens using semantic names where usage is clear (e.g. "brand-primary", "text-body", "bg-surface")
- Name tokens using descriptive names where usage is ambiguous (e.g. "blue-600", "gray-100")
- Identify a grayscale ramp if one exists (white → light grays → dark grays → black)
- Flag any one-off colors used only once (these may be mistakes or one-offs)
- Always include pure-white (#FFFFFF), pure-black (#000000), and a red for errors

**Step 2 — Typography analysis:**
- Identify all font families used — flag if more than 2 (unusual, may indicate inconsistency)
- Build a type scale from the extracted sizes — map to roles: h1, h2, h3, h4, h5, h6, body, small, caption
- For each role: document size, weight, line-height, letter-spacing
- If the same role appears at different sizes across pages, note the conflict and pick the most-used value
- Identify which font is the heading font and which is the body font

**Step 3 — Spacing analysis:**
- Identify the spacing scale (e.g. 4, 8, 12, 16, 24, 32, 48, 64, 80, 96, 120)
- Map common spacing values to named tokens: xs, sm, md, lg, xl, 2xl, 3xl
- Flag any spacing values that don't fit the scale (may be mistakes)

**Step 4 — Border radius analysis:**
- Identify the radius scale (e.g. 4, 8, 12, 16, full)
- Map to named tokens: sm, md, lg, xl, full

**Step 5 — Shadow analysis:**
- Deduplicate shadows
- Name by intensity: sm, md, lg, xl

**Step 6 — Button analysis:**
- Group by visual similarity into named variants (primary, secondary, ghost, outline, etc.)
- For each variant: canonical bg, text, border, radius, padding, font, hover state (if found)
- Note if any variant is missing states (hover, disabled)

**Step 7 — Container / grid analysis:**
- Identify the primary container max-width
- Identify the spacing/padding pattern at different widths
- Suggest breakpoints based on observed layout changes

**Step 8 — Return structured design system:**

Return a JSON object with this structure:

{
  "colors": {
    "brand-primary": { "hex": "#2563EB", "usage": "Primary actions, links" },
    "brand-secondary": { "hex": "#10B981", "usage": "Secondary actions" },
    ...
  },
  "typography": {
    "headingFont": "Antonio",
    "bodyFont": "Poppins",
    "scale": {
      "h1": { "size": "60px", "weight": 700, "lineHeight": "1.1", "letterSpacing": "-0.02em", "font": "heading" },
      "body": { "size": "16px", "weight": 400, "lineHeight": "1.5", "letterSpacing": "0", "font": "body" },
      ...
    }
  },
  "spacing": {
    "scale": [4, 8, 12, 16, 24, 32, 48, 64, 80, 96, 120],
    "tokens": { "xs": "4px", "sm": "8px", "md": "16px", "lg": "24px", "xl": "32px", "2xl": "48px", "3xl": "64px" }
  },
  "borderRadius": {
    "sm": "4px", "md": "8px", "lg": "12px", "xl": "16px", "full": "9999px"
  },
  "shadows": {
    "sm": "0 1px 2px rgba(0,0,0,0.05)",
    "md": "0 4px 6px rgba(0,0,0,0.1)",
    ...
  },
  "buttons": {
    "primary": { "bg": "#2563EB", "text": "#FFF", "border": "none", "radius": "8px", "padding": "12px 24px", "font": "Poppins 600 16px", "hoverBg": "#1D4ED8" },
    ...
  },
  "containers": {
    "maxWidth": "1200px",
    "sidePadding": { "mobile": "16px", "desktop": "24px" },
    "breakpoints": { "sm": "576px", "md": "768px", "lg": "992px", "xl": "1200px", "2xl": "1400px" }
  },
  "decisions": [
    "Merged #2563EB and #2564EA into brand-primary (ΔE < 1)",
    "Heading font is Antonio (used in all h1-h3), body is Poppins",
    "Spacing scale follows 4px base unit",
    ...
  ],
  "warnings": [
    "3 one-off colors found that don't match any pattern — may be design mistakes",
    "Button 'ghost' variant has no hover state in any page",
    ...
  ]
}

Return ONLY the JSON, no commentary.
```

---

## Phase 4 — Review with user (orchestrator)

Parse the analysis JSON and present it to the user in a readable format:

```
Design System Discovery — Results
═══════════════════════════════════

🎨 Colors — N tokens discovered
  brand-primary     #2563EB    Primary actions, links
  brand-secondary   #10B981    Secondary actions
  text-body         #1A1A1A    Body text
  ...

📝 Typography — 2 fonts, N styles
  Heading font: Antonio
  Body font: Poppins
  h1: 60px / 700 / 1.1
  h2: 36px / 700 / 1.2
  body: 16px / 400 / 1.5
  ...

📐 Spacing scale — base unit: 4px
  xs=4  sm=8  md=16  lg=24  xl=32  2xl=48  3xl=64

🔘 Buttons — N variants
  primary: #2563EB bg, #FFF text, 8px radius
  secondary: ...
  ...

📦 Container
  Max width: 1200px
  Breakpoints: sm=576 md=768 lg=992 xl=1200 2xl=1400

⚠️  Warnings
  - 3 one-off colors found that don't match any pattern
  - Button 'ghost' variant has no hover state

💡 Decisions made
  - Merged #2563EB and #2564EA into brand-primary (ΔE < 1)
  - ...
```

Then use AskUserQuestion:

- `Looks good — generate DS page` → proceed to Phase 5
- `I need to adjust some tokens` → ask what to change, update the JSON, re-display
- `Export as YAML only` → save the token map to `_docs/discovered-tokens.yaml` and stop

---

## Phase 5 — Generate design system page (subagent: Sonnet)

### Step 1 — Map extracted assets

Before spawning the builder subagent, the orchestrator must:

1. List all files in `.figma-assets/`
2. Read the SVG files to identify what each one is (icon, logo, decorative element)
3. Build an asset mapping table: `{ "hash-filename.svg": "icon-name or description", ... }`
4. Separate PNGs (raster images — likely photos or complex illustrations) from SVGs (icons/logos)

This asset mapping is passed to the builder subagent so it can reference actual icons instead of placeholders.

### Step 2 — Spawn builder subagent

Spawn a subagent with `model: "sonnet"`.

Pass this prompt:

```
You are a design system documentation specialist. Build a clean, professional Next.js page that showcases a complete design system. This page will be served on localhost and then captured by Figma's generate_figma_design tool, so visual clarity and clean structure matter.

CRITICAL: Never use placeholder elements (colored circles, empty divs) for icons or images. Every icon must render the actual SVG from the extracted assets. If an icon's SVG file is available, inline it or reference it via <img src>. If not available, show the icon name as text — never a fake circle.

---

Generate a Next.js page component for the design system reference.

**Design system tokens:**

{paste the analysis JSON from Phase 3}

**Extracted assets (from .figma-assets/):**

{paste the asset mapping table from Step 1}

SVG icons are in the `.figma-assets/` directory at the project root. Reference them as:
- For Next.js page: `/.figma-assets/{filename}` (served as static files)
- The orchestrator will copy them to `public/.figma-assets/` so Next.js can serve them

PNG images are also in `.figma-assets/` — use the same pattern.

**Output format:** Create a Next.js page at `src/app/design-system/page.tsx` (NOT a static HTML file).

This is a preview-only route (same pattern as other preview pages in `src/app/`), so:
- It can use Next.js features (metadata export, etc.)
- It should import global CSS (already available via the root layout)
- It should be self-contained — no external component imports needed

**Layout rules:**
- Page width: 1440px centered (use .base-container or max-width)
- Background: white
- Use a clear visual hierarchy with section headers
- Left-align everything, use consistent spacing

**Required sections (in this order):**

1. **Header** — "Design System" title + project name + date generated

2. **Colors** — Grid of color swatches
   - Each swatch: 80×80px square with the color fill + label below (token name + hex)
   - Group by category if possible (brand, text, background, gray scale, status)
   - 6–8 swatches per row

3. **Typography** — Type specimens
   - For each style in the scale: render a sample line at the actual size/weight
   - Show the specs next to each: "h1 — IBM Plex Serif 60px/1.1 Regular"
   - Use the actual fonts (include Google Fonts links if needed)

4. **Spacing** — Visual spacing scale
   - Horizontal bars showing each spacing value, labeled
   - Bar width = the spacing value, height = 24px, colored with a neutral accent

5. **Border Radius** — Radius samples
   - Squares (80×80px) with each radius applied, labeled

6. **Shadows** — Shadow samples (skip if none discovered)
   - Squares (120×120px) with each shadow applied on a light background, labeled

7. **Interactive elements** — All discovered patterns
   - Render actual elements styled with the extracted properties
   - Use the real SVG icons from .figma-assets/ — never placeholders
   - One row per variant: default state + hover state (side by side)
   - Label each variant

8. **Icons** — Grid of all extracted SVG icons
   - Display each SVG at its actual size + a label with the filename
   - 8–10 icons per row
   - This section ensures all icons are visible for verification

9. **Container** — Layout reference
   - Show the container max-width, side padding, and breakpoints as a simple diagram

**Output:** The complete page.tsx file. Return ONLY the code, no commentary.
```

### Step 3 — Set up assets for serving

After the subagent creates the page, the orchestrator must:

1. Copy `.figma-assets/` contents to `public/.figma-assets/` so Next.js can serve them
2. Add a link to `src/app/page.tsx` for the design system preview
3. Also save a static HTML copy to `design-system-preview.html` at the project root (for quick browser access without the dev server)

### Step 4 — Verify the page renders

1. Ensure `npm run dev` is running
2. Use Playwright to screenshot `http://localhost:3000/design-system`
3. Read the screenshot to verify icons render correctly (no black circles or missing images)
4. If icons are broken → fix the asset paths and re-check

---

## Phase 6 — Push to Figma (orchestrator)

**How `generate_figma_design` works (important — read this first):**

The tool does NOT take HTML as input. It captures a **live web page** running on localhost:

1. Orchestrator calls `generate_figma_design` with the localhost URL → Figma returns a `captureId`
2. The tool injects a capture script into the page
3. It opens the browser at `http://localhost:<port>/design-system#figmacapture=<id>&figmaendpoint=<url>`
4. The script captures the rendered DOM (text, layout, structure) and sends it to Figma's servers
5. Claude polls until capture completes → receives a Figma file URL with editable layers

**Requirement:** The dev server MUST be running (`npm run dev`) so the page is accessible at `http://localhost:3000/design-system`.

---

**If `generate_figma_design` is available (remote MCP authenticated):**

1. Ensure `npm run dev` is running on port 3000
2. Call `generate_figma_design` with `{ url: "http://localhost:3000/design-system" }` (check actual parameter names — they may differ)
3. Wait for the capture to complete — the tool will poll automatically
4. On success: display the returned Figma file URL to the user

If the tool fails:

```
⚠️  Figma write-back failed.

I've created the design system as a local preview page:
  → http://localhost:3000/design-system (requires dev server)
  → design-system-preview.html (static copy, open in browser)

To manually import into Figma:
  1. Open http://localhost:3000/design-system in Chrome
  2. Install the "html.to.design" Figma plugin
  3. Use it to capture the page into your Figma file
  4. Or: screenshot sections and paste into a new Figma page
```

**If `generate_figma_design` is NOT available (analysis-only mode):**

Save the design system spec to `_docs/discovered-tokens.yaml`. The preview page at `/design-system` and the static HTML copy still work.

```
Design system discovery complete (analysis-only mode).

Files created:
  src/app/design-system/page.tsx   — Next.js preview page
  _docs/discovered-tokens.yaml     — structured token spec
  design-system-preview.html       — static HTML copy

Preview:
  → Run `npm run dev` and open http://localhost:3000/design-system

To import into Figma manually:
  → Use the "html.to.design" Figma plugin on the preview page
  → Or run /extractify-discover again with the remote Figma MCP authenticated

To apply tokens to the codebase directly:
  → Run /extractify-setup (it can use discovered-tokens.yaml as reference)
```

---

## Phase 7 — Final summary (orchestrator)

```
Design system discovery complete.

  ✅ Scanned N pages
  ✅ Discovered: N colors, N type styles, N button variants
  ✅ Design system page pushed to Figma

Files created:
  _docs/discovered-tokens.yaml     — token spec (YAML)
  design-system-preview.html       — HTML preview

Next steps:
  → Review the new DS page in Figma — adjust colors/names as needed
  → Run /extractify-setup to apply tokens to the codebase
  → Or manually point /extractify-setup steps to the new DS page in Figma
```

Resolve `FIGMA_PATHS_FILE` once before saving discovery output:

1. If `figma-paths.yaml` exists in the current project root, use it
2. Else if `_docs/figma-paths.yaml` exists, use it
3. Else create `figma-paths.yaml` in project root with the standard scaffold and use it

Save the URL of the newly created Figma page to `FIGMA_PATHS_FILE` under a new `design-system` key:

```yaml
design-system: <figma-url>
```

Update `_docs/learnings.md` if any edge cases or patterns were discovered during analysis.

---

## Argument

Optional: Figma file URL. If not provided, the orchestrator will ask for it.

Example usage:
```
/extractify-discover
/extractify-discover https://www.figma.com/design/abc123/MyProject
```
