## Project rules

This document defines conventions for creating and updating files in this repo.
It is written so an AI can consistently generate new components, demos, and styling without drifting from existing patterns.

---

### Component and demo creation

#### New component

- File: `src/components/<ComponentName>/index.tsx`
- Name: PascalCase (e.g., `Accordion`, `HeroBanner`, `CourseCard`)
- Must be fully props-driven — see `_docs/front-end/04-component-contract.md`

#### Component preview (demo page)

- File: `src/app/components/<component-name>/page.tsx`
- Name: kebab-case (e.g., `accordion`, `hero-banner`, `course-card`)
- Must import the component and render it with mocked props only
- **Always add a link to `src/app/page.tsx`** after creating a new demo

#### Full-page component

- Component file: `src/components/Pages/<PageName>/index.tsx`
- Demo file: `src/app/pages/<page-name>/page.tsx`
- **Always add a link to `src/app/page.tsx`** after creating a new demo

---

### Styling conventions

#### Default approach

- **Prefer Tailwind utilities in JSX** — this is the default
- Only create PostCSS files when utility classes are not enough

#### Colors

- If you add a new color variable, add it to `src/assets/css/base/theme.pcss` under `@theme` → `/* colors */`
- Use the pattern: `--color-<token-name>` in kebab-case

#### Fonts

- If you add a new font variable, add it to `src/assets/css/base/theme.pcss` under `@theme` → `/* fonts */`
- Only `--font-body` and `--font-heading` are standard (add `--font-mono` if needed)

#### Typography utilities

- Add new text size utilities to `src/assets/css/base/typography.pcss`
- The boilerplate ships with **numeric utilities** (`.text-16`, `.text-18`, `.text-20`, etc.)
- For **new projects**, prefer **semantic names** (`.h1`, `.h2`, `.body`, `.caption`) — see `_docs/front-end/02-typography.md`
- When **extending an existing project**, stay consistent with whatever naming is already in use — never mix both patterns in the same file
- Define desktop size first, then add mobile/breakpoint variations in the same class
- **Always use rem** (1rem = 16px) — never use `px` in generated CSS, except for single-pixel values like `border: 1px` or `outline: 1px` where `px` is intentional and does not scale with font size

#### Button utilities

- Button utilities live in `src/assets/css/base/buttons.pcss`
- Use the `.button-{variant}` pattern (e.g. `.button-primary`, `.button-secondary`) via the `Button` component — see `_docs/front-end/06-buttons.md`
- All classes must be inside `@layer utilities` and use `@apply` with Tailwind utilities
- Preserved non-button utilities: `.hover-underline`, `.hover-underline-white` — do not remove

#### Dynamic class names — never construct Tailwind classes at runtime

Tailwind scans source files **at build time** for complete class name strings. Any class built via string interpolation or concatenation will not be included in the generated CSS.

```tsx
// ❌ WRONG — Tailwind never sees the full class name
<div className={`bg-${color}`} />
<div className={`text-${size}`} />
<div className={`gap-${spacing}`} />

// ✅ CORRECT — full class name is a static string in the source
const colors = [
  { name: 'brand-primary', bg: 'bg-brand-primary', text: 'text-brand-primary' },
]
<div className={item.bg} />
```

This applies to **every** Tailwind utility — colors, spacing, typography, borders, etc. Always store the complete class name as a literal string and reference it directly.

#### Component-specific PostCSS

Only use when Tailwind utilities are genuinely not enough:

1. Create `src/assets/css/components/<component-name>.pcss`
2. Add `@import './components/<component-name>.pcss'` to `src/assets/css/global.css`

---

### Component constraints

**Quick reference:**

- No CSS modules — use the PostCSS setup under `src/assets/css/`
- No internal data fetching in components under `src/components/`
- All content must be passed via props — no hardcoded text or data

---

### Doc maintenance

When you introduce something new, update the matching doc **in the same task**:

- New standard folder or preview section → `project-structure.md`
- New naming, file placement, or styling convention → this file
- New pattern that does not fit the above → `learnings.md` (if it exists)
