## Project structure

### Overview

This repo is an open-source **Next.js + Tailwind CSS** boilerplate used as a **development and preview harness** to build **isolated, reusable UI components and blocks**.

Key implications:

- The goal is **not** to build a full Next.js website with route-driven data fetching
- You build **isolated components** (banners, blocks, full pages like 404, etc.)
- Components must be **fully controlled by props** — no internal data fetching, no hardcoded content
- The `Header` and `Footer` are **components**, not hardcoded layout wrappers
- Routes under `src/app/**` are **preview pages** for local development only

### Related docs

- **Entry point**: `_docs/start-here.md`
- **AI workflow (Figma MCP → codebase)**: `_docs/structure/ai-workflow.md`
- **Rules and conventions**: `_docs/structure/project-rules.md`

### File tree (accurate as of boilerplate)

```
.
  CLAUDE.md                       (per-project instructions for Claude Code / Cursor)
  next.config.mjs
  postcss.config.mjs
  tsconfig.json
  package.json
  package-lock.json

  .mcp.json                       (Figma Desktop + Remote MCP server config — read at IDE startup)

  .claude/
    commands/                     (project-scoped /extractify-* slash commands)
      extractify-preflight.md
      extractify-setup.md
      extractify-new-component.md
      extractify-audit.md
      extractify-discover.md
      extractify-code-connect.md
      extractify-security-audit.md
      ralph-loop.md
    skills/
      figma-use/                  (mandatory prerequisite for any use_figma tool call)
        SKILL.md
        references/               (per-topic Plugin API references loaded on demand)
    hooks/
      ralph-stop.sh               (stop-hook that terminates the Ralph Loop on completion)
    settings.json                 (shared project settings — committed)
    settings.local.json.example   (template for per-machine MCP permissions — copy to settings.local.json, git-ignored)

  .cursor/rules/figma-to-code.mdc (Cursor-only project rules, same content family as CLAUDE.md)
  .windsurfrules                  (Windsurf-only project rules)
  .github/copilot-instructions.md (GitHub Copilot project rules)

  _docs/
    start-here.md                 (entry point — reading order, golden rules, use_figma prerequisite, output checklist)
    figma-paths.yaml              (Figma URLs for each /extractify-setup step — edit before running the wizard)
    learnings.md                  (self-updating patterns log)
    structure/
      ai-workflow.md              (Figma → repo mapping and self-update rules)
      accessibility.md            (minimum a11y requirements)
      consistency-rules.md        (aspect ratios, grid, pattern matching, typography extraction)
      doc-versioning.md           (how to handle convention changes)
      figma-mcp-setup.md          (connecting to Figma via Desktop or Remote MCP — single source of truth)
      project-rules.md            (naming, file creation, styling conventions)
      project-structure.md        ← this file
      rich-text.md                (RichText vs RichTextWrapper usage)
      troubleshooting.md          (index of common failures with jumps to the fix)
      visual-review.md            (visual review loop — Ralph pattern)
    front-end/
      01-colors.md                (color token extraction contract)
      02-typography.md            (typography extraction contract)
      03-grid-container.md        (grid and breakpoint extraction contract)
      04-component-contract.md    (how to write a component)
      05-icons-svg.md             (SVG icon extraction contract)
      06-buttons.md               (button component contract + .button-{variant} classes)
      07-form-elements.md         (form elements contract — placeholder)

  public/
    fonts/                        (add font files here if self-hosting)
    img/                          (jpg/png raster images)
    svg/
      ux/                         (UI icons as SVG)
    videos/

  src/
    app/                          (Next.js App Router)
      layout.tsx                  (imports global.css, defines shell with Header + Footer)
      page.tsx                    (index of all previews — add links here when creating new demos)
      assets/
        buttons/page.tsx
        colors/page.tsx
        typography/page.tsx
      components/                 (component preview routes)
        <component-name>/
          page.tsx

    components/                   (reusable components)
      Header/index.tsx
      Footer/index.tsx
      Fancybox/index.tsx
      RichText/index.tsx
      RichTextWrapper/index.tsx
      Guidelines/index.tsx
      <ComponentName>/index.tsx   (new components go here)

    assets/
      css/
        global.css                (entry point — imports everything below)
        base/
          theme.pcss              (Tailwind v4 @theme: colors, fonts, breakpoints)
          globals.pcss            (global element resets and defaults)
          grid.pcss               (base-container utility)
          typography.pcss         (text scale utilities: .h1, .h2, .body, etc.)
          buttons.pcss            (.button-{variant} classes + .hover-underline utilities)
          rich-text.pcss          (typography inside rich-text / HTML string content)
          animations.pcss         (reusable animation utilities)
        components/               (create here when component needs its own PostCSS)
          <component-name>.pcss

    utils/
      functions.ts
      useTableWrapper.ts
```

### Routing structure

#### `src/app/` (App Router — preview only)

- `layout.tsx` — imports `global.css`, renders `Header` and `Footer` around `{children}`
- `page.tsx` — index of all previews; **always add a link here** when you create a new demo
- `src/app/assets/**` — previews for design tokens (colors, typography, buttons)
- `src/app/components/**` — previews for individual components

Treat everything in `src/app/` as demo/preview code. Keep it thin: compose and render components with mocked props.

### Components (`src/components/`)

Each component lives in its own folder:

```
src/components/<ComponentName>/index.tsx
```

Optional namespaces you may introduce as the library grows:

- `src/components/Form/` — form primitives and helpers
- `src/components/Macros/` — higher-level composed content blocks
- `src/components/Icons/` — SVG icon wrappers

See `_docs/front-end/04-component-contract.md` for how to write a component correctly.

### Styling system

Tailwind v4 (CSS-first config via `@theme`) is the default approach.

- **Global entry**: `src/assets/css/global.css` — imported by `layout.tsx`
- **Theme tokens**: `src/assets/css/base/theme.pcss` — colors, fonts, breakpoints
- **Base styles**: `src/assets/css/base/*.pcss` — elements, typography, buttons, grid
- **Component styles**: `src/assets/css/components/*.pcss` — only when utilities are not enough

When you add a new component PostCSS file, also add the `@import` line to `global.css`.

### TypeScript path aliases

`tsconfig.json` defines:

- `@/*` → `./src/*`

Use this throughout imports (e.g., `@/components/Header`, `@/assets/css/global.css`).
