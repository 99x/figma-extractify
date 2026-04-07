# Start here

This is the entry point for any AI working on this project.
Read this file first, then follow the links below in order.

---

## What this repo is

An open-source **Next.js + Tailwind CSS** boilerplate for building isolated, props-driven UI components and pages.

- You build isolated, reusable components
- You preview them locally via `src/app/**` routes
- You do **not** build a full Next.js app with data fetching

---

## Reading order (do this before writing any code)

1. `_docs/structure/project-structure.md` — where things live in the repo
2. `_docs/structure/project-rules.md` — naming, file creation, and styling conventions
3. `_docs/structure/ai-workflow.md` — the full Figma → repo mapping and self-update rules
4. `_docs/structure/consistency-rules.md` — aspect ratios, grid usage, pattern matching, typography extraction
5. `_docs/structure/accessibility.md` — minimum accessibility requirements
6. `_docs/structure/doc-versioning.md` — how to handle convention changes and deprecations
7. `_docs/structure/rich-text.md` — when to use RichText vs RichTextWrapper and legacy SCSS warning
8. `_docs/structure/visual-diff.md` — pixelmatch-based quantified visual comparison
9. `_docs/structure/a11y-audit.md` — automated axe-core accessibility auditing
10. `_docs/structure/code-connect.md` — Figma Code Connect integration

**Also read** (if it exists and has entries):
- `_docs/learnings.md` — common mistakes (pinned at top) + patterns and fixes discovered during development

Front-end token docs (read when working on design system extraction or building components):

- `_docs/front-end/01-colors.md`
- `_docs/front-end/02-typography.md`
- `_docs/front-end/03-grid-container.md`
- `_docs/front-end/04-component-contract.md`
- `_docs/front-end/05-icons-svg.md`
- `_docs/front-end/06-buttons.md`
- `_docs/front-end/07-form-elements.md`

---

## The golden rules

- **No bare `<img>`** — always use `<Image>` from `next/image`; it handles `<picture>`, srcset, and lazy loading internally; use `<figure>` only when a `<figcaption>` is needed
- **No CSS modules** — use Tailwind utilities or PostCSS under `src/assets/css/`
- **All components are props-driven** — no hardcoded content, no internal data fetching
- **Tailwind first** — only write PostCSS when utilities are not enough
- **Rem only** — never use `px` in generated CSS (1rem = 16px)
- **Update the docs** when you introduce a new convention (see `ai-workflow.md`)
