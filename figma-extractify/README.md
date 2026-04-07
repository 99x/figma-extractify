# Figma Extractify

A boilerplate for [Claude Code](https://docs.anthropic.com/en/docs/claude-code). Point it at your Figma file and get fully typed, props-driven React components with your own design tokens, visual review, and accessibility auditing — automatically.

**Built for teams who want pixel-perfect components out of Figma without the manual handoff.**

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

### Repo structure

When you clone this repo you get a **monorepo** with two sibling folders:

```
figma-extractify/          ← repo root
├── figma-extractify/      ← the AI skill system (this project)
│   ├── install.sh
│   ├── _docs/
│   └── .claude/
└── boilerplate/           ← Next.js starter (package.json lives here)
```

**Important:** `install.sh` must be run from inside `figma-extractify/figma-extractify/`, not from the repo root.

### One-command setup (monorepo)

```bash
git clone https://github.com/your-org/figma-extractify.git
cd figma-extractify/figma-extractify   # ← go one level deeper
bash install.sh
```

The installer will:
- Check Node.js v18.17+
- Detect the monorepo layout and run `npm install` inside `boilerplate/` automatically
- Optionally install the visual QA toolchain (Playwright, pixelmatch, axe-core)
- Copy `/extractify-*` commands to `~/.claude/commands/`
- Copy `extractify-*` skills to `~/.claude/skills/`

> **After installation, restart Claude Code or Cowork** so the new `/extractify-*` commands appear in the UI.

### One-command setup (standalone)

If you're installing Figma Extractify into an existing project (not the monorepo):

```bash
# Copy the figma-extractify/ folder into your project root, then:
cd your-project/figma-extractify
bash install.sh
```

The installer detects `package.json` in the current directory and runs `npm install` there.

### Manual setup

```bash
# From the boilerplate/ directory (or your project root):
npm install

# Optional — needed for visual diff + a11y audit:
npm install -D pixelmatch pngjs @axe-core/playwright @playwright/test
npx playwright install chromium

# Copy commands and skills globally so Claude can find them:
cp .claude/commands/extractify-*.md ~/.claude/commands/
cp -r .claude/skills/extractify-* ~/.claude/skills/
```

### Uninstall

```bash
bash uninstall.sh
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
1. Add your Figma URLs to _docs/figma-paths.yaml
2. Open Figma Desktop in Dev Mode
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
- **Figma Desktop** open in Dev Mode (required for the MCP connection) (pro plan not required but recommended)
- **Claude Code**

Run `/extractify-preflight` before your first `/extractify-setup` to verify everything is ready.

---

## License

MIT License — see [LICENSE](LICENSE) for details.
