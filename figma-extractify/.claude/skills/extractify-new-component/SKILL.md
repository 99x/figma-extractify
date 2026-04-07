---
name: extractify-new-component
description: "Use this skill whenever the user wants to build, create, or implement a React component from a Figma design in the figma-extractify project. Triggers on: 'build component', 'create component', 'extract component from Figma', 'implement this design', 'make a hero section', 'build a card', 'build a footer', 'build a banner', 'new component', '/extractify-new-component', 'turn this Figma design into code', 'convert Figma to React', or any request to turn a Figma node/URL into a typed props-driven React component. Also trigger when the user says 'build [anything] from the design' or pastes a Figma URL and wants a component. This skill handles the full workflow: Figma extraction → build → compliance check → visual review → accessibility audit."
---

# Extractify New Component — Figma → React

Builds a single React component end-to-end from a Figma design. Runs as an orchestrator that spawns focused subagents per phase to prevent context rot and use the right model for each task.

## Before starting

Read these files:
1. `_docs/SKILL.md` — overall workflow
2. `_docs/structure/agent-architecture.md` — subagent assignments
3. `_docs/front-end/04-component-contract.md` — component rules
4. `_docs/learnings.md` — common mistakes (top 10 — always read before writing code)
5. `.claude/commands/extractify-new-component.md` — **full implementation: read this and follow it exactly**

## Phases

| Phase | Model | What happens |
|---|---|---|
| 1–2: Docs + resolve | Sonnet (orchestrator) | Read docs, resolve Figma URL or component name |
| 3: Build | Sonnet (subagent) | Extract from Figma, write component + preview page |
| 4: Compliance | Haiku (subagent) | Check component against project rules |
| 5: Visual review | Opus (subagent) | Screenshot, pixel diff vs Figma, axe-core audit |
| 6: Wrap up | Sonnet (orchestrator) | Summary, update learnings.md if needed |

## How to call this

The argument can be:
- A **component name**: `hero` — looks up the Figma URL from `_docs/figma-paths.yaml`
- A **Figma URL**: `https://www.figma.com/design/ABC123/...?node-id=1-2` — used directly

For enforced visual review (recommended for production components):
```
/ralph-loop /extractify-new-component hero --completion-promise "VISUAL_REVIEW_PASS" --max-iterations 8
```

## Visual review thresholds (must pass)

| Check | Threshold |
|---|---|
| Pixel similarity vs Figma | ≥ 95% |
| Spacing accuracy | ± 4px |
| Accessibility (critical/serious) | 0 violations |
| Colors | Must use design tokens — no hardcoded hex |
| Typography | Must use existing `.text-*` scale utilities |

## Non-negotiable component rules

- `Props` interface with defaults at top of every file
- `<Image>` from `next/image` — never a bare `<img>`
- No `<figure>` unless a `<figcaption>` is needed
- `<Link>` for internal routes; plain `<a>` for `mailto:`, `tel:`, external URLs
- No CSS modules — PostCSS under `src/assets/css/` or Tailwind utilities
- Every value in `rem` — never `px`
- Preview page at `src/app/components/<kebab-name>/page.tsx`
- Link added to `src/app/page.tsx`
