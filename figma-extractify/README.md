# Figma Extractify

A boilerplate for [Claude Code](https://docs.anthropic.com/en/docs/claude-code). Point it at your Figma file and get fully typed, props-driven React components with your own design tokens, visual review, and accessibility auditing — automatically.

**Built for teams who want pixel-perfect components out of Figma without the manual handoff.**

**Watch the walkthrough** to see everything in action: [figma-extractify.mp4](https://99xtech-my.sharepoint.com/:v:/g/personal/flavio_troszczanczuk_99x_io/IQDtzlCuetHxSq2-cZL4HodGAd2sc5C3l4alqb0NUOn8gns?nav=eyJyZWZlcnJhbEluZm8iOnsicmVmZXJyYWxBcHAiOiJPbmVEcml2ZUZvckJ1c2luZXNzIiwicmVmZXJyYWxBcHBQbGF0Zm9ybSI6IldlYiIsInJlZmVycmFsTW9kZSI6InZpZXciLCJyZWZlcnJhbFZpZXciOiJNeUZpbGVzTGlua0NvcHkifX0&e=dJqq3a)

---

## What This Does

Paste your Figma URL, run a command, and Claude extracts your design system into code:

```
> /extractify-setup

Reading _docs/figma-paths.yaml...

✓ Colors        — your palette → --color-* variables in theme.pcss
✓ Typography    — your type styles → font families + text scale utilities
✓ Grid          — your breakpoints + container → CSS layout tokens
✓ Icons         — your icon set → public/svg/ux/
✓ Buttons       — your button variants → .button-* classes + Button component
✓ Form elements — your inputs, selects, checkboxes → form components

Your design system is now in code. Run /extractify-new-component to start building.
```

Then build any component from your Figma:

```
> /extractify-new-component hero

Building HeroBanner from your Figma...

✓ Component created    → src/components/HeroBanner/index.tsx
✓ Preview page created → src/app/components/hero-banner/page.tsx
✓ Screenshot captured  — Playwright (1440px)
✓ Pixel diff vs Figma  — 97.3% similarity ✅
✓ a11y audit           — 0 critical violations ✅
✓ Code Connect         → linked back to your Figma node

Done. Open http://localhost:3000/components/hero-banner to preview.
```

---

## Installation

### Recommended setup

Open the `boilerplate/` folder in your IDE (Claude Code, Cursor, etc.), copy the `figma-extractify/` folder into it, and run the installer:

```bash
# From inside the boilerplate/ folder:
bash figma-extractify/install.sh
```

The installer will:
- Check Node.js v18.17+
- Run `npm install` for your project dependencies
- Optionally install the visual QA toolchain (Playwright, pixelmatch, axe-core)
- Copy `/extractify-*` commands to `<project>/.claude/commands/` (project-scoped — won't leak into other projects)
- Copy the `figma-use` skill to `<project>/.claude/skills/` (required prerequisite for any `use_figma` tool call)
- Copy `_docs/` (contracts + figma-paths.yaml) to your project root
- Copy `scripts/` (visual-diff + a11y-audit) to your project root
- Copy project config files (`CLAUDE.md`, `.mcp.json`, `.claude/settings.json`, `.cursor/rules/`, `.windsurfrules`)
- Ask if you want to delete the `figma-extractify/` folder (safe — all files have been copied)

After the installer finishes, **restart Claude Code / Cursor** so the new `/extractify-*` commands appear.

### Standalone setup (existing project)

If you're installing Figma Extractify into an existing project (not the monorepo):

```bash
# Copy the figma-extractify/ folder into your project root, then:
bash figma-extractify/install.sh
```

The installer detects `package.json` in the current directory and installs from there.

### Windows

Double-click `install.bat` or run from PowerShell:

```powershell
powershell -ExecutionPolicy Bypass -File figma-extractify\install.ps1
```

### Uninstall

```bash
# macOS / Linux
bash uninstall.sh

# Windows — double-click uninstall.bat, or:
powershell -ExecutionPolicy Bypass -File uninstall.ps1
```

---

## Commands

Run these in **Claude Code** or **your preferred A.I.**:

| Command | What it does |
|---|---|
| `/extractify-preflight` | Checks Node, Figma MCP, Playwright, pixelmatch, axe-core |
| `/extractify-setup` | Reads your Figma and writes your design tokens into the codebase |
| `/extractify-new-component <name>` | Builds a component from your Figma, end-to-end with visual review |
| `/extractify-discover` | Scans an entire Figma file and reverse-engineers your design system |
| `/extractify-audit` | Runs a compliance + accessibility audit across all built components |
| `/extractify-code-connect <name>` | Links a component back to its Figma node so specs show in Dev Mode |
| `/extractify-security-audit` | Runs a full 4-phase security audit (16 domains, 95 checks) via ESAA-Security |

### First-time workflow

```
1. Connect to Figma — EITHER of these works:
     • Open Figma Desktop in Dev Mode (Shift+D)     ← preferred, runs at 127.0.0.1:3845
     • Let the IDE open the Remote MCP OAuth prompt ← fallback, https://mcp.figma.com/mcp
2. Add your Figma URLs to _docs/figma-paths.yaml
   (or import example-file/example.fig to try with a sample file)
3. npm run dev

/extractify-preflight              ← verify your environment
/extractify-setup                  ← pull your tokens from Figma into code
/extractify-new-component hero     ← build your first component
/extractify-audit                  ← check compliance across all components
/extractify-code-connect hero      ← link it back to Figma Dev Mode
```

---

## Configuring your Figma URLs

Before running `/extractify-setup`, edit `_docs/figma-paths.yaml` with the URLs from your Figma file:

```yaml
setup:
  colors:       https://www.figma.com/design/ABC123/YourProject?node-id=1-2
  typography:   https://www.figma.com/design/ABC123/YourProject?node-id=3-4
  grid:         https://www.figma.com/design/ABC123/YourProject?node-id=5-6
  icons:        https://www.figma.com/design/ABC123/YourProject?node-id=7-8
  buttons:      https://www.figma.com/design/ABC123/YourProject?node-id=9-10
  form-elements: ~

components:
  hero:         https://www.figma.com/design/ABC123/YourProject?node-id=11-12
  nav:          https://www.figma.com/design/ABC123/YourProject?node-id=13-14
```

Each URL maps to a page or frame in your file. Leave a field as `~` to skip it or have Claude ask you when the time comes.

---

## How It Works

1. **You paste your Figma URLs** into `_docs/figma-paths.yaml`
2. **`/extractify-setup` reads your Figma** and writes your colors, fonts, breakpoints, icons, and button variants into the CSS and component files
3. **`/extractify-new-component`** reads your Figma component spec and builds a typed, props-driven React component
4. **Visual review loop** — Playwright screenshots the component and pixel-diffs it against your Figma design (≥ 95% similarity to pass)
5. **a11y audit** — axe-core scans for accessibility violations (zero critical/serious allowed)
6. **`/extractify-code-connect`** links the finished component back to its Figma node so your team sees real code in Dev Mode

---

## IDE support

| Tool | What it does |
|---|---|
| **Claude Code** | Full slash commands, hooks, MCP server config, the Ralph Loop |
| **Cursor** | Project rules injected on every file edit via `.cursor/rules/` |
| **Windsurf** | Project rules injected on every session via `.windsurfrules` |
| **GitHub Copilot** | Project context via `.github/copilot-instructions.md` |

---

## Prerequisites

- **Node.js** 18.17+
- **At least one Figma MCP server reachable** — you need **either**:
  - **Figma Desktop** open in Dev Mode (preferred, runs locally at `http://127.0.0.1:3845/mcp`), **or**
  - **Figma Remote MCP** authenticated via OAuth in your IDE (`https://mcp.figma.com/mcp`) — used automatically as a fallback when Desktop isn't available.
- **Claude Code**, **Cursor**, or another AI IDE that supports MCP

### About the two Figma MCP servers

Figma Extractify works against either server. Both expose the same read tools (`get_metadata`, `get_design_context`, `get_screenshot`, `get_variable_defs`, Code Connect). Every command resolves the server at run time — Desktop first, Remote as fallback — and fails preflight only if **both** are down.

**Figma Desktop MCP** (preferred)
- Runs locally at `http://127.0.0.1:3845/mcp` whenever Figma Desktop is open with Dev Mode on.
- Dev Mode requires a **paid Figma plan** (Professional, Organization, Enterprise) or a free Education plan.
- To enable: open any file in Figma Desktop and press **Shift+D** (or click the `</>` toggle in the bottom toolbar).
- More info: [Figma Dev Mode plans](https://help.figma.com/hc/en-us/articles/15023124644247)

**Figma Remote MCP** (fallback)
- Served at `https://mcp.figma.com/mcp`, authenticated via **OAuth** — your IDE opens a browser prompt on first use.
- Works without the desktop app, which makes it the right option for headless setups or when Dev Mode is unavailable.
- Also required for write-back flows like `/extractify-discover` — `generate_figma_design` is Remote-only.
- Do **not** add an `X-Figma-Token` header to `.mcp.json`; it breaks the OAuth flow.

Both are already wired up in `.mcp.json` after install. Run `/extractify-preflight` to verify which one is active before your first `/extractify-setup`.

---

## License

MIT License — see [LICENSE](LICENSE) for details.
