# Learnings

This file captures patterns, fixes, and discoveries that emerged during development.
It is the place for anything that does not fit neatly into the core docs.

---

## How this file works

**When to add an entry:**
- A bug was fixed in a way that should not be repeated
- A workaround was found for a Next.js or tooling limitation
- A Figma → repo mapping had an edge case not covered by the contract docs
- A component pattern emerged that is useful but too specific for `project-rules.md`

**When NOT to add an entry:**
- If the learning changes a core rule → update `project-rules.md` instead
- If it is a new convention that will be used everywhere → it belongs in a contract doc, not here

**Format (always follow this):**

```
### [Short title of the learning]

**Date**: YYYY-MM-DD  
**Context**: Which component, page, or task triggered this  
**Problem**: What went wrong or what was unclear  
**Solution**: What was done and why it works  
**Example** (optional): a short code snippet
```

**Size rule:** keep each entry focused. If an entry exceeds ~15 lines, it probably belongs in a dedicated doc instead.

---

## Self-update rule (for AI)

When you finish a task and discover something that fits the criteria above, add an entry to this file **before closing the task**.

Do not ask the user — just append it. The entry should be small, factual, and reproducible.

---

## Common mistakes (pinned — read these first)

Scan this before writing any code. Full rules are in the linked docs — this is the fast pre-task check.

- **Bare `<img>`** — always use `<Image>` from `next/image` → `_docs/structure/accessibility.md`
- **Block element inside `<Link>` or `<a>`** — use the stretched link pattern instead → `_docs/structure/accessibility.md`
- **Dynamic Tailwind class construction** — always use full static strings, never template literals → `_docs/structure/project-rules.md`
- **`px` instead of `rem`** — convert all values; only exception is `border: 1px` → `_docs/structure/project-rules.md`
- **Missing `'use client'`** — must be the very first line when using any React hook → `_docs/front-end/04-component-contract.md`
- **Phantom visual properties** — never add `border-radius`, `box-shadow`, etc. that aren't in Figma → `_docs/structure/consistency-rules.md` Rule 6
- **Underline bleeding from `<Link>`** — add `no-underline` or `[&_*]:no-underline` → `_docs/structure/consistency-rules.md` Rule 7
- **Hashed SVG filenames** — rename from content hash to kebab-case semantic name before use → `_docs/front-end/05-icons-svg.md`
- **PostCSS file not imported** — always add `@import` to `global.css` → `_docs/front-end/04-component-contract.md`
- **Hardcoded hex colors** — always use `--color-*` tokens from `theme.pcss` → `_docs/structure/consistency-rules.md` Rule 3
- **`dirForAssetWrites` missing** — always pass it to `get_design_context` → `_docs/front-end/05-icons-svg.md`
- **Unsanitized HTML** — always wrap with `sanitizeHtml()` before `dangerouslySetInnerHTML` → `_docs/structure/rich-text.md`

---

## Entries

<!-- New entries go below this line, most recent first -->

