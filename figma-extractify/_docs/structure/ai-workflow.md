## AI workflow (Figma MCP → codebase)

### Goal

These docs exist so an AI can:

- Extract **colors**, **typography**, **images**, **icons**, and **component specs** from Figma using a Figma MCP server — Desktop (`127.0.0.1:3845/mcp`) is preferred, Remote (`mcp.figma.com/mcp`) is the automatic fallback
- Populate and extend the codebase using the same structure and conventions
- Create new **components** and **page previews** without introducing new patterns accidentally
- Keep these docs up to date when conventions change

### What to do before writing any code

1. Read `_docs/start-here.md`
2. Read `_docs/structure/project-structure.md` — where things live
3. Read `_docs/structure/project-rules.md` — naming and file creation conventions
4. Read `_docs/structure/consistency-rules.md` — aspect ratios, grid usage, pattern matching, typography extraction

---

### Figma → repo mapping

| What | Figma source | Repo file | Pattern |
|---|---|---|---|
| Color tokens | Color variables / styles | `src/assets/css/base/theme.pcss` | `--color-*` under `@theme` |
| Font tokens | Typography styles (families) | `src/assets/css/base/theme.pcss` | `--font-*` under `@theme` |
| Text size utilities | Typography styles (sizes, responsive) | `src/assets/css/base/typography.pcss` | `.h1`, `.body`, etc. in `@layer utilities` |
| Button utilities | Component styles (buttons, states) | `src/assets/css/base/buttons.pcss` | `.button-{variant}` inside `@layer utilities` — see `_docs/front-end/06-buttons.md` |
| Component-specific CSS | Component styles (when utilities aren't enough) | `src/assets/css/components/<name>.pcss` | Also add `@import` to `global.css` |
| Raster images | Exported PNG/JPG | `public/img/` | `<Image>` from `next/image`; `<figure>` only when `<figcaption>` is needed — see `_docs/structure/accessibility.md` |
| SVG icons | Exported SVG | `public/svg/ux/` | `<Image>` from `next/image` — see `_docs/front-end/05-icons-svg.md` |
| Rich-text / HTML string | Raw HTML prop | `src/components/RichText/` | `<RichText>{props.text}</RichText>` — see `_docs/structure/rich-text.md` |

---

### Creating new UI

→ See `_docs/structure/project-rules.md` for file paths, naming conventions, and styling rules.

---

### Design token extraction workflow

When extracting tokens from Figma:

1. **Read `_docs/figma-paths.yaml`** to get the Figma URL for each step — all URLs are stored there
2. **Read the relevant contract doc**
   - Colors → `_docs/front-end/01-colors.md`
   - Typography → `_docs/front-end/02-typography.md`
   - Grid / container → `_docs/front-end/03-grid-container.md`
3. **Extract** following the checklist in that doc
4. **Apply** following the "repo updates" section
5. **Output** a summary table (Figma name → repo token → value) and note anything that could not be mapped

---

### MCP and tooling edge cases

**Two Figma MCP servers, automatic fallback**
Both MCP servers expose the same read surface (`get_metadata`, `get_design_context`, `get_screenshot`, `get_variable_defs`, Code Connect). Skills resolve the server at run time:

1. Try Desktop candidates (`user-figma`, `user-Figma Desktop`, `figma-desktop`) — preferred when Figma Desktop is open with Dev Mode on.
2. Fall back to Remote candidates (`plugin-figma-figma`, `figma`) — uses OAuth, no local app needed.
3. Fail only if **both** are unreachable.

Differences to be aware of:
- **Selection context** (no URL, uses the node currently selected in Figma Desktop) is Desktop-only. The extractify commands always pass an explicit URL, so Remote is fully viable for every read flow here.
- **Write-back via `generate_figma_design` is Remote-only** — see below.

**`generate_figma_design` is remote MCP only**
Available only on `https://mcp.figma.com/mcp`, not the desktop MCP. It works by capturing a live localhost page via browser script injection — it does not accept raw HTML. Requirements: remote MCP must be authenticated, `npm run dev` must be running, and the page must be served on localhost.

**Figma Remote MCP authentication**
Remote uses OAuth 2.0 — no PAT, no API key. The standard `.mcp.json` entry is all that's needed; do **not** add an `X-Figma-Token` or any `headers` block (it breaks the OAuth handshake):

```json
"figma": { "type": "http", "url": "https://mcp.figma.com/mcp" }
```

To complete the flow:

- **Claude Code** — run `/mcp` in the chat → select `figma` → **Authenticate**. Browser opens, log in, approve. Fully restart Claude Code so live MCP sessions pick up the new token.
- **Cursor** — **MCP Settings** (`Cmd/Ctrl+Shift+P` → "Cursor: Open MCP Settings") → `figma` → **Authenticate** → restart Cursor.
- Or just call any Figma tool once — the IDE prompts OAuth automatically.

Failure modes to distinguish (skills and `/extractify-preflight` classify them):

- **Tool not found** → server not registered in the IDE → check `.mcp.json` and restart the IDE.
- **401 / unauthorized** → registered but OAuth not completed → run the flow above.
- **Connection error** → network/proxy/firewall blocking `*.figma.com`.

For the full guided walkthrough (including common pitfalls: popup blockers, wrong Figma account, stale token after re-auth), run `/extractify-preflight` — Step 3a has the IDE-specific instructions.

**Token discovery from a single-frame Figma file**
If the Figma file has no formal design system page and all tokens are embedded in one frame, call `get_variable_defs` + `get_design_context` on the root frame node. Variable defs return named tokens (colors, spacing, typography). Design context returns the rendered code with all inline styles, from which remaining tokens can be extracted.

**Corrupted `.next` breaks client JS**
After mixed `next build` / failed compile cycles, `.next` can be left in a broken state (missing manifests, chunk 404s). React never hydrates, so `useEffect`, hooks, and event listeners never attach. If client-side behaviour suddenly stops working: stop the dev server, run `rm -rf .next`, then restart `npm run dev`. Confirm the Network tab loads `/_next/static/chunks/main-app.js` without 404s.

---

### Self-updating the docs (required)

When you introduce a new convention, update the appropriate doc **in the same task**.

Keep updates small — add a short bullet and an example path. Do not repeat the same rule across multiple files.

| What changed | Update this doc |
|---|---|
| New folder under `src/` becomes part of the standard workflow | `project-structure.md` |
| New naming rule, file creation rule, or styling convention | `project-rules.md` |
| New accessibility baseline requirement | `accessibility.md` |
| Convention changed or old pattern deprecated | `doc-versioning.md` |
| New pattern that is useful but does not fit above | `learnings.md` (if it exists) |
