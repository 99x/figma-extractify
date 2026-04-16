# Figma Extractify skill

## When to use this skill

Use this skill for any task involving:

- Extracting design tokens or specs from Figma
- Creating or editing components under `src/components/`
- Creating preview pages under `src/app/`
- Updating CSS files under `src/assets/css/`
- Any task where the user mentions "component", "page", "Figma", "token", "style", or "preview"

---

## figma-use prerequisite (mandatory before any `use_figma` call)

Before calling `use_figma` for ANY reason, you MUST first read:

```
.claude/skills/figma-use/SKILL.md
```

Then load the specific reference docs from `.claude/skills/figma-use/references/` as needed for your task (e.g. `variable-patterns.md` when creating variables, `gotchas.md` always, etc.).

Skipping this step causes silent, hard-to-debug failures in Plugin API code (wrong color ranges, broken page switching, unawaited promises, etc.). This is non-negotiable.

---

## Step 1 — Read the project docs first (always)

Before writing any code, read the following docs in order.
They are located inside the `_docs/` folder at the root of the repo.

1. `_docs/start-here.md` — entry point and golden rules
2. `_docs/structure/project-structure.md` — where things live
3. `_docs/structure/project-rules.md` — naming and file creation conventions
4. `_docs/structure/accessibility.md` — minimum accessibility requirements
5. `_docs/structure/ai-workflow.md` — Figma → repo mapping and self-update rules
6. `_docs/structure/consistency-rules.md` — aspect ratios, grid, pattern matching, typography extraction
7. `_docs/structure/visual-review.md` — visual review loop protocol (Ralph pattern)

Always read `_docs/learnings.md` — it contains fixes and patterns that must not be repeated.

For Figma extraction tasks, also read the relevant token contract:

- Colors → `_docs/front-end/01-colors.md`
- Typography → `_docs/front-end/02-typography.md`
- Grid / container → `_docs/front-end/03-grid-container.md`
- Components → `_docs/front-end/04-component-contract.md`
- Icons / SVG → `_docs/front-end/05-icons-svg.md`
- Buttons → `_docs/front-end/06-buttons.md`
- Form elements → `_docs/front-end/07-form-elements.md`

For rich-text / HTML string rendering:

- RichText components → `_docs/structure/rich-text.md`

---

## Step 2 — Understand the task scope

Before writing any code:

- Identify which files will be created or modified
- Identify which docs (if any) will need to be updated after the task
- If extracting from Figma, identify which token contract applies
- If building UI, confirm whether a Figma URL is available for the visual review loop

---

## Step 3 — Execute

Follow all the rules defined in the docs above. The docs are the source of truth — do not rely on old code patterns in the repo if they conflict with the docs.

---

## Step 4 — Visual review loop (required for UI tasks)

After building the component or page, run the Ralph Loop if a Figma URL is available:

```
1. SERVE    → npm run dev (ensure localhost:3000 is up)
2. CAPTURE  → Playwright CLI: npx playwright screenshot --browser=chromium ...
3. COMPARE  → Figma MCP (Desktop or Remote): get_design_context or get_screenshot
4. EVALUATE → Compare layout, spacing, colors, typography, alignment
5. REFINE   → Fix code → go back to CAPTURE
6. COMPLETE → Visual match satisfactory or 5 iterations reached
```

```bash
# Desktop (always)
npx playwright screenshot --browser=chromium --viewport-size=1440,900 --wait-for-timeout=2000 \
  http://localhost:3000/components/<name> .screenshots/<name>-desktop.png

# Mobile (only if design has a mobile-specific layout)
npx playwright screenshot --browser=chromium --viewport-size=375,812 --wait-for-timeout=2000 \
  http://localhost:3000/components/<name> .screenshots/<name>-mobile.png
```

Then read each file with the `Read` tool to view the screenshot.

Test at these breakpoints:

| Breakpoint | Viewport | When to test |
|---|---|---|
| Desktop | 1440 x 900 | Always |
| Mobile | 375 x 812 | If the design has a mobile-specific layout |

See `_docs/structure/visual-review.md` for the full protocol.

---

## Step 5 — Update the docs (required)

After completing the task:

1. If you introduced a new convention → update the matching doc
2. If you discovered a pattern, fix, or edge case → add an entry to `_docs/learnings.md`
3. If a convention changed → follow the rules in `_docs/structure/doc-versioning.md`

Keep doc updates small. One bullet and an example path is enough for most changes.

---

## Output checklist (before finishing any task)

- [ ] All docs were read before writing code
- [ ] Component has a `Props` interface with defaults
- [ ] No CSS modules used
- [ ] All images use `<Image>` from `next/image` — no bare `<img>` tags
- [ ] All `<Image>` components have `alt` (descriptive or `""` for decorative)
- [ ] `<figure>` used only where `<figcaption>` is present
- [ ] Icon-only interactive elements have `aria-label`
- [ ] Preview page created (if new component)
- [ ] Link added to `src/app/page.tsx` (if new preview)
- [ ] Visual review loop completed (desktop + mobile breakpoints)
- [ ] Responsive breakpoints tested via Playwright CLI
- [ ] Docs updated if a new convention was introduced
- [ ] `learnings.md` updated if something worth capturing was discovered
