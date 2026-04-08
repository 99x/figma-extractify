# Create a new component

Orchestrator workflow that spawns focused subagents per phase to prevent context rot and use the right model for each task.

Read `_docs/structure/agent-architecture.md` for the full rationale.

> **Tip — enforced iteration**: Wrap this command with ralph-loop to prevent premature exit:
> `/ralph-loop /extractify-new-component <name> --completion-promise "VISUAL_REVIEW_PASS" --max-iterations 8`
> The stop hook will force the full visual review loop to run until quantified thresholds are met.

## Model assignments

| Phase | Model | Runs as |
|---|---|---|
| 1–2: Docs + resolve | Sonnet | orchestrator (this agent) |
| 3: Build | Sonnet | subagent |
| 4: Compliance | Haiku | subagent |
| 5: Visual review | Opus | subagent |
| 6: Wrap up | — | orchestrator (this agent) |

---

## Phase 1 — Read docs (orchestrator)

Read these — they inform how you orchestrate, what context to pass to subagents, and how to resolve the component:

1. `_docs/structure/agent-architecture.md`
2. `_docs/structure/project-rules.md`
3. `_docs/front-end/04-component-contract.md`

Also read `_docs/learnings.md`.

---

## Phase 2 — Resolve the component and detect parent/child structure (orchestrator)

Resolve `FIGMA_PATHS_FILE` once before reading/saving component mappings:

1. If `figma-paths.yaml` exists in the current project root, use it
2. Else if `_docs/figma-paths.yaml` exists, use it
3. Else create `figma-paths.yaml` in project root with the standard scaffold and use it

Read `FIGMA_PATHS_FILE` fully. Then resolve the component using this priority order:

### Step 1 — Inspect the argument

- **If `$ARGUMENTS` is a Figma URL** (starts with `https://www.figma.com`):
  - Use it directly as the Figma URL
  - Derive the component name from the Figma frame name (via `get_design_context` in Phase 3)
  - Treat as a simple component — no children
  - Save the URL to `FIGMA_PATHS_FILE` under `components.<kebab-name>` after the name is known

- **If `$ARGUMENTS` is a component name** (e.g. `list-links`, `HeroBanner`):
  - Normalize to kebab-case (e.g. `HeroBanner` → `hero-banner`)
  - Look up the entry in `FIGMA_PATHS_FILE` under `components.<kebab-name>`
  - The entry can be one of two formats:
    - **Simple** (`name: url`) → use the URL, no children, proceed to Phase 3
    - **Parent/child** (`name: { figma: url, children: {...} }`) → see Step 2 below
  - If not found or empty → ask the user (see Step 3)

- **If `$ARGUMENTS` is empty**:
  - Ask the user for the component name and Figma URL together (see Step 3)

### Step 2 — Handle parent/child components

If the resolved entry has a `children` key, this is a **parent component**. Execute the following:

1. **Announce the plan** to the user:
   > "This component has child components that need to be built first: [list children]. I'll build them bottom-up, then assemble the parent."

2. **Resolve the full tree** — walk children recursively. If a child also has children, those are built first. Build order is always deepest → shallowest.

3. **Check which children already exist** in `src/components/`:
   - Already exists → skip building it, import it directly in the parent
   - Does not exist → run the full pipeline (Phases 3–5) for that child before continuing

4. **Build the parent last**, importing all child components:
   - Import children as React components: `import Accordion from '@/components/Accordion'`
   - The parent's Figma URL shows the full section (children rendered inside it) — use `get_design_context` on that URL to understand layout, spacing, and how children are composed
   - Do not rebuild child internals inside the parent — use the child component

5. **Visual review** for each component (child and parent) individually, using their respective Figma URLs

### Step 3 — Ask only what is still missing

If the Figma URL could not be resolved automatically, gather inputs using AskUserQuestion and follow-up messages:

1. **If component name is unknown** — use AskUserQuestion: "What is the component name?" (free-text follow-up — e.g. `HeroBanner`, `ListLinks`)

2. **Figma URL** — ask the user to paste the Figma frame link as a plain message. Include a note: "Type `none` to build without Figma."

3. **Child components** — use AskUserQuestion:
   - `No child components` → proceed
   - `Yes, it has children` → ask for child names and their Figma URLs as a follow-up message

4. **Specific behavior** — use AskUserQuestion:
   - `Static block`
   - `Accordion`
   - `Carousel / slider`
   - `Tabs`
   - `Form`
   - `Other (I'll describe)` → ask for description as a follow-up message

Only ask questions that are still unanswered — skip any already resolved from the argument or `FIGMA_PATHS_FILE`.

If children are mentioned, ask for their Figma URLs and save the full parent/child structure to `FIGMA_PATHS_FILE`.

### Step 4 — Save to FIGMA_PATHS_FILE

After URLs are resolved (from argument, from `FIGMA_PATHS_FILE`, or from the user), save the full structure back to `FIGMA_PATHS_FILE`:

- Simple component → `name: url`
- Parent with children → full nested object with `figma:` and `children:`

---

## Phase 3 — Build (subagent: Sonnet)

> If this is a **parent/child** component, run Phase 3 → 5 for each child first (bottom-up), then run Phase 3 → 5 for the parent. Do not mix them.

Spawn a subagent using the **Agent tool** with `model: "sonnet"`.

Pass this prompt (fill in the `{placeholders}` with actual values):

```
You are a front-end developer building production-ready components for a CMS integration project. Your code will be reviewed by a compliance checker and a visual QA engineer after you — write clean, accessible, spec-faithful code on the first pass so fewer issues need to be caught downstream.

Your goal: translate the Figma design into a props-driven React component that follows every project convention exactly. When the design is ambiguous, prefer the conservative interpretation that matches existing components in the codebase.

---

Build a React component for the design-extractify project.

**Component:** {ComponentName}
**Figma URL:** {url}
**Behavior:** {static block / accordion / carousel / tabs / form / description}
{if parent: **Children to import:** {ChildA from @/components/ChildA, ChildB from @/components/ChildB}}

**Step 1 — Read these docs (in this order, before writing any code):**
1. _docs/start-here.md
2. _docs/structure/project-rules.md
3. _docs/structure/accessibility.md
4. _docs/front-end/04-component-contract.md
5. _docs/structure/consistency-rules.md
6. _docs/learnings.md

**Step 2 — Get Figma design context:**
Call `get_design_context` with the nodeId and fileKey extracted from the Figma URL.
{if "none": skip this step — build based on the behavior description only}

**Step 3 — Build the component:**
Create `src/components/{ComponentName}/index.tsx` following ALL rules from the docs:
- Props interface at top with all props optional + defaults
- Default export function with destructured props
- No CSS modules
- All images use next/image wrapped in <figure> (sizing on figure, Image fills it)
- 'use client' as first line if hooks are used
- All CSS values in rem (never px, except border: 1px)
- No dynamic Tailwind class construction — all class names must be static strings
{if parent: - Import child components from @/components/<ChildName> — do not inline their markup}

**Step 4 — Create preview page:**
Create `src/app/components/{component-name}/page.tsx` with mocked props.
{if parent: Pass mocked child data as props}

**Step 5 — Update index:**
Add a link to `src/app/page.tsx`.

**Step 6 — Component PostCSS (if needed):**
If Tailwind utilities are not enough, create `src/assets/css/components/{component-name}.pcss` and add the @import to `src/assets/css/global.css`.

**Return:** list all files created or modified, and a brief summary of the component structure.
```

After the subagent returns, note the files created and proceed to Phase 4.

---

## Phase 4 — Compliance check (subagent: Haiku)

Spawn a subagent using the **Agent tool** with `model: "haiku"`.

Pass this prompt (fill in the `{placeholders}` with actual values):

```
You are a front-end QA engineer specializing in component compliance and accessibility auditing. Your job is to find violations — not to confirm that things look fine. Assume the code has problems until proven otherwise. Be thorough, be strict, and flag every issue you find, no matter how minor.

Your output will be reviewed by the project lead. A missed violation that reaches production is worse than a false positive.

---

Run a compliance check on a React component in the design-extractify project.

**Component file:** src/components/{ComponentName}/index.tsx
**Preview file:** src/app/components/{component-name}/page.tsx
{if has PostCSS: **PostCSS file:** src/assets/css/components/{component-name}.pcss}

Read each file listed above, then verify every item in this checklist. If any item fails, fix it directly in the file and note the fix.

Checklist:
- [ ] Props interface defined at the top with TypeScript types
- [ ] All optional props have default values
- [ ] No bare <img> tags — all images use next/image inside <figure>
- [ ] No CSS modules imported
- [ ] No hardcoded content (unless documented as default/fallback)
- [ ] If hooks used → 'use client' is the first line
- [ ] All images have alt (descriptive or "" for decorative)
- [ ] All icon-only <button>, <a>, and <Link> have aria-label
- [ ] Heading levels are sequential (no skipping)
- [ ] Focus styles from globals.pcss are not suppressed
- [ ] All CSS values use rem (no px, except single-pixel values like border: 1px)
- [ ] No dynamic Tailwind class construction (e.g. bg-$\{var\}) — all class names must be static strings
- [ ] Preview page exists at src/app/components/{name}/page.tsx
- [ ] Link exists in src/app/page.tsx

**Return:** pass/fail for each item, and a list of any fixes applied.
```

If the compliance agent reports fixes, briefly review them. Then proceed to Phase 5.

---

## Phase 5 — Visual review loop (subagent: Opus)

**Skip this phase if** the user said "none" for the Figma URL.

Spawn a subagent using the **Agent tool** with `model: "opus"`.

Pass this prompt (fill in the `{placeholders}` with actual values):

```
You are a senior UI engineer conducting a pixel-level design review. You have a trained eye for spacing inconsistencies, color mismatches, and typography drift. Your standard is: if a designer would notice it in a side-by-side comparison, it needs to be fixed.

You will be evaluated on how closely the final implementation matches the Figma source of truth. Do not approve a result that "looks close enough" — identify every concrete difference, fix it, and verify the fix. When in doubt, measure don't guess.

---

Visual review for a React component in the design-extractify project.

**Component:** {ComponentName}
**Figma URL:** {url}
**Preview URL:** http://localhost:3000/components/{component-name}
**Component file:** src/components/{ComponentName}/index.tsx
{if has PostCSS: **PostCSS file:** src/assets/css/components/{component-name}.pcss}
{if has mobile layout: **Mobile testing:** yes — compare mobile Figma frame after desktop passes}

**Step 1 — Read these docs first:**
1. _docs/structure/visual-review.md
2. _docs/structure/consistency-rules.md

**Step 2 — Run the review loop (max 5 iterations):**

Each iteration:

1. Ensure dev server is running: run `npm run dev` in background if not already running.

2. Capture desktop screenshot:
   npx playwright screenshot --browser=chromium --viewport-size=1440,900 --wait-for-timeout=2000 \
     http://localhost:3000/components/{component-name} .screenshots/{component-name}-desktop.png
   Then read the screenshot file.

3. Get Figma reference: call get_design_context with the nodeId and fileKey from the Figma URL.

4. Compare both images across these dimensions:
   - Layout / grid structure
   - Spacing (margins, paddings, gaps)
   - Sizing (widths, heights, aspect ratios)
   - Colors (bg, text, borders)
   - Typography (size, weight, line-height)
   - Alignment (horizontal, vertical)
   - Interactive states (hover, focus)

5. Decision (use quantified thresholds from visual-review.md):
   - Pixelmatch ≥ 95% AND no dimension fails AND 0 critical a11y violations → exit loop
   - Any threshold fails → fix the component code → repeat from step 2
   - 5 iterations reached → exit loop, note remaining issues with measurements

6. Run a11y audit (each iteration):
   node scripts/a11y-audit.js http://localhost:3000/components/{component-name} --component={component-name}
   Fix any critical/serious violations before the next pixel comparison.

7. Run pixel diff (each iteration, after capturing Figma screenshot as .screenshots/{component-name}-figma.png):
   node scripts/visual-diff.js {component-name} --threshold=95
   Use the diff image and similarity score to guide fixes.

{if mobile testing:
**Step 8 — Mobile testing (after desktop passes):**
   npx playwright screenshot --browser=chromium --viewport-size=375,812 --wait-for-timeout=2000 \
     http://localhost:3000/components/{component-name} .screenshots/{component-name}-mobile.png
   Read the file and compare against the mobile Figma frame. Fix if needed.
}

**Return:** the quantified status block (see visual-review.md) plus list of fixes applied per iteration.

When ALL thresholds pass, output: VISUAL_REVIEW_PASS
(This string is used by the ralph-loop stop hook to allow exit when the command is wrapped in /ralph-loop.)
```

If the visual review reports remaining issues after 5 iterations, log them in `_docs/learnings.md` with exact measurements.

---

## Phase 6 — Wrap up (orchestrator)

- [ ] All subagent phases completed
- [ ] Visual review loop passed (or logged in learnings.md with measurements)
- [ ] Responsive breakpoints tested (if applicable)
- [ ] Docs updated if a new convention was introduced
- [ ] `_docs/learnings.md` updated if something worth capturing was discovered

Report the final status to the user with the quantified status block:

```
Visual review — final status
─────────────────────────────────
  Pixelmatch similarity:  XX.X%  (threshold: 95%)
  A11y critical/serious:  N      (threshold: 0)
  Layout structure:       pass/fail
  Spacing accuracy:       ±Npx
  Color token coverage:   N%
  Typography match:       N%
  Iterations used:        N/5
─────────────────────────────────
  Result: PASS / FAIL (details)
```

If this command was invoked via `/ralph-loop` and all thresholds pass, output:

VISUAL_REVIEW_PASS

The component name is: $ARGUMENTS
