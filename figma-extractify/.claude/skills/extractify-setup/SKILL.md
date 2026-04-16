---
name: extractify-setup
description: "Use this skill to extract design tokens from Figma into the figma-extractify codebase. Triggers on: 'extract design tokens', 'set up design system', 'extract colors from Figma', 'extract typography', 'extract fonts', 'extract icons', 'extract buttons', 'sync Figma tokens', 'extractify setup', '/extractify-setup', 'run the setup wizard', 'set up my project', 'I have a Figma file where do I start', 'pull design values from Figma into code', or any request to get Figma colors/fonts/grid/breakpoints/icons/buttons into the CSS files. This is the FIRST thing to run on a new figma-extractify project. Always use this skill when the user wants to initialize the design system from Figma."
---

# Extractify Setup — Design System Wizard

Extracts design tokens from Figma into the codebase across 6 steps: colors, typography, grid/breakpoints, icons, buttons, and form elements. Runs as an orchestrator that spawns a fresh subagent per step to prevent context rot.

## Before starting

Read these files (they govern the full workflow):
1. `_docs/SKILL.md` — step-by-step process
2. `_docs/structure/agent-architecture.md` — subagent model assignments
3. `.claude/commands/extractify-setup.md` — **full implementation: read this and follow it exactly**

## What it produces

| Step | Figma source | Output |
|---|---|---|
| 1. Colors | Colors page | `theme.pcss` → `--color-*` variables |
| 2. Typography | Typography page | `theme.pcss` + `typography.pcss` → font families + text scale |
| 3. Grid | Grid/Layout page | `theme.pcss` + `grid.pcss` → breakpoints + `.base-container` |
| 4. Icons | Icons page | `public/svg/ux/` → named SVG files |
| 5. Buttons | Buttons page | `buttons.pcss` + `src/components/Button/index.tsx` |
| 6. Form Elements | Form Elements page | form components (contract TBD) |

## Requirements

- Figma URLs must be set in `_docs/figma-paths.yaml` before running
- **At least one Figma MCP server reachable** — Desktop (`127.0.0.1:3845/mcp`, via Figma Desktop + Dev Mode) is preferred; Remote (`mcp.figma.com/mcp`, via OAuth) is the automatic fallback. Setup fails only if both are down.
- `npm run dev` running in a separate terminal

## Key rules (enforced during extraction)

- All color tokens → `--color-*` kebab-case CSS variables in `@theme`
- Typography utilities → `.text-{size}` numeric scale (`.text-16`, `.text-18`, etc.)
- Button classes → `.button-{variant}` inside `@layer utilities` using `@apply`
- Never use `px` — always `rem` (1rem = 16px)
- Never use bare `<img>` — always `<Image>` from `next/image`
