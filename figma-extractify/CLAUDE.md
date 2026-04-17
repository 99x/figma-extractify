# Project context for Claude

## What this repo is

A **Next.js 16 + Tailwind CSS v4 + PostCSS** open-source boilerplate for building **isolated, props-driven UI components and pages**.

This is NOT a full Next.js application. You build isolated components, preview them locally via `src/app/**` routes, and all content is injected via props — making every component reusable and independently testable.

---

## Required reading (before writing any code)

**Always read [`_docs/start-here.md`](_docs/start-here.md) first.** It is the single source of truth for the reading order — follow the links it lists, in order, before writing any code.

Also always read `_docs/learnings.md` — its **Common mistakes** section (pinned at the top) captures the 10 most frequent issues to avoid, followed by a chronological log of patterns and fixes.

For Figma extraction tasks, `start-here.md` also points at the per-token contracts in `_docs/front-end/` (colors, typography, grid, components, icons, buttons, form elements). It also covers the `use_figma` prerequisite, the visual review loop, and the output checklist.

---

## Golden rules (never break these)

- **No bare `<img>`** — always use `<Image>` from `next/image` (it handles `<picture>`, srcset, and lazy loading internally); `<figure>` is optional — only add it when semantically meaningful (e.g., with `<figcaption>`)
- **Use `<Link>` for Next.js routes** — `<Link>` is a router component: it does client-side navigation, prefetching, and scroll restoration. Use it only for paths that Next.js owns (e.g. `/about`, `/contact`). For `mailto:`, `tel:`, and external `http` URLs, use a plain `<a>` — these are not routes, and `<Link>` prefetching on them is a no-op at best and a bug at worst
- **No CSS modules** — use Tailwind utilities or PostCSS under `src/assets/css/`
- **All components are props-driven** — no hardcoded content, no internal data fetching
- **Tailwind first** — only write PostCSS when utilities are not enough
- **Rem only** — never use `px` in generated CSS (1rem = 16px)
- **Update the docs** when you introduce a new convention

---

## Tech stack

| Tool | Version | Notes |
|---|---|---|
| Next.js | ^16.2.2 | App Router; Turbopack is the default bundler (`next dev` uses it automatically) |
| React | ^19.0.0 | |
| Tailwind CSS | ^4.1.18 | CSS-first config via `@theme` in PostCSS |
| PostCSS | ^8.5.6 | Via `@tailwindcss/postcss` |
| TypeScript | 5.x | Strict mode, path alias `@/*` → `./src/*` |
| GSAP | ^3.13.0 | Animation library |
| Swiper | ^11.2.4 | Slider/carousel |
| react-hook-form | ^7.60.0 | Form handling |
| Fancybox | ^6.0.14 | Lightbox / media viewer |
| clsx | ^2.1.1 | Conditional class names |

---

## Project structure

```
src/
  app/                          # Next.js App Router — preview pages only
    layout.tsx                  # Root layout (imports global CSS, Header + Footer)
    page.tsx                    # Index of all previews (add links here)
    assets/                     # Design token previews (colors, typography, buttons)
    components/<name>/page.tsx  # Component preview routes
    pages/<name>/page.tsx       # Full-page preview routes

  components/                   # Reusable components
    <ComponentName>/index.tsx   # One folder per component

  assets/css/
    global.css                  # Entry point (imports everything)
    base/
      theme.pcss                # Tailwind v4 @theme (colors, fonts, breakpoints)
      globals.pcss              # Global resets and defaults
      grid.pcss                 # .base-container utility
      typography.pcss           # Text scale utilities (.text-16, .text-18, etc.)
      buttons.pcss              # Button utilities — .button-{variant} classes + legacy BEM (.button, .button--black, etc.)
      rich-text.pcss            # Styles for rich-text HTML content
      animations.pcss           # Animation utilities
    components/                 # Component-specific PostCSS (when needed)

  utils/
    functions.ts                # Utility functions (tel, mailto, slugify, etc.)

public/
  fonts/                        # Self-hosted font files
  img/                          # Raster images (PNG/JPG)
  svg/ux/                       # UI icons (SVG)
  videos/                       # Video files
```

---

## Component constraints

These apply to everything under `src/components/**`:

| Constraint | Reason |
|---|---|
| No CSS modules | Keeps styling consistent — use PostCSS via `src/assets/css/` |
| No internal data fetching | Components must be 100% props-driven |
| No hardcoded content | Unless documented as a default/fallback |

**Allowed in `src/components/`**: React hooks, `'use client'`, TypeScript interfaces, Tailwind utilities, PostCSS, `next/link`, `next/image`, `next/font`.

**Typical in `src/app/`** (preview pages): server components, mocked inline props, `next/navigation`, metadata.

> **Server vs Client components**: In the App Router, every component is a **Server Component by default** — it runs only on the server and has zero client-side JS. Add `'use client'` at the top of the file only when the component needs interactivity (hooks, event listeners, browser APIs). Keep `'use client'` boundaries as deep in the tree as possible to maximise server rendering.

---

## Component contract

Every component in `src/components/` must:

1. Define a `Props` interface at the top
2. Export a default function with destructured props and defaults
3. Be fully controlled by props (no internal data fetching)
4. Use `<Image>` from `next/image` for all images — no bare `<img>` tags; add `<figure>` only when a `<figcaption>` is needed
5. Add `'use client'` as first line if hooks are used
6. Have a preview page at `src/app/components/<component-name>/page.tsx`
7. Be linked from `src/app/page.tsx`

```tsx
import Link from 'next/link'
import Image from 'next/image'

interface Props {
  title?: string
  image?: { src: string; alt: string; width?: number; height?: number }
  items?: { label: string; url: string }[]
}

export default function MyComponent({
  title = 'Default title',
  image = { src: '/img/placeholder.jpg', alt: 'Placeholder', width: 800, height: 450 },
  items = [{ label: 'Link', url: '#' }]
}: Props) {
  return (
    <section className="py-8">
      <div className="base-container">
        <h2 className="text-30">{title}</h2>
        <Image src={image.src} alt={image.alt} width={image.width ?? 800} height={image.height ?? 450} className="w-full aspect-video object-cover" />
        <ul>
          {items.map((item, i) => (
            <li key={i}><Link href={item.url}>{item.label}</Link></li>
          ))}
        </ul>
      </div>
    </section>
  )
}
```

---

## `<Image>` usage guide

`next/image` renders an optimized `<picture>` element with AVIF/WebP `<source>` variants and an `<img>` fallback — you never write those yourself.

### Explicit dimensions (most common)

Use when the image has a known aspect ratio. Apply layout classes directly on `<Image>`:

```tsx
<Image
  src={image.src}
  alt={image.alt}
  width={image.width ?? 800}
  height={image.height ?? 450}
  className="w-full aspect-video object-cover"
/>
```

### Fill mode (unknown dimensions)

Use when the image must fill a container of unknown size (e.g. a card thumbnail). The parent must be `position: relative` with an explicit size:

```tsx
<div className="relative w-full aspect-video overflow-hidden">
  <Image src={image.src} alt={image.alt} fill className="object-cover" />
</div>
```

### `sizes` prop (important for non-full-width images)

Without `sizes`, the browser assumes the image is 100vw and downloads a larger file than needed. Always add `sizes` when the image is narrower than the viewport:

```tsx
{/* Half-width on desktop, full-width on mobile */}
<Image src={...} alt={...} fill sizes="(min-width: 992px) 50vw, 100vw" className="object-cover" />

{/* Fixed small image */}
<Image src={...} alt={...} width={120} height={40} sizes="120px" />
```

### `preload` prop (LCP images)

Add `preload` to the largest image visible on first load (the LCP element). This tells Next.js to preload it. The `priority` prop was deprecated in Next.js 16 — use `preload` instead:

```tsx
<Image src={hero.src} alt={hero.alt} fill preload sizes="100vw" className="object-cover" />
```

Only the first image above the fold should have `preload`. Using it on every image defeats the purpose.

---

## Accessibility baseline

- Every image must have `alt` (descriptive or `""` for decorative)
- Every image must use `<Image>` from `next/image` — never a bare `<img>`; add `<figure>` only when a `<figcaption>` is needed
- Use `<Link>` from `next/link` for internal Next.js routes; use plain `<a>` for `mailto:`, `tel:`, and external `http` URLs — `<Link>` is a router, not a generic anchor replacement
- Every `<Link>` and `<a>` must have a readable label (visible text or `aria-label`)
- Icon-only `<button>`, `<Link>`, and `<a>` must have `aria-label`
- Heading levels must be sequential (no skipping)
- Never suppress global focus styles from `globals.pcss`

---

## Design system tokens

**Colors** — defined in `src/assets/css/base/theme.pcss` as `--color-*` variables under `@theme`.

**Fonts** — `--font-body` (Poppins) in `theme.pcss`.

**Breakpoints**:

| Token | Value |
|---|---|
| `xs` | 26.25rem (420px) |
| `sm` | 36rem (576px) |
| `md` | 48rem (768px) |
| `lg` | 62rem (992px) |
| `xl` | 75rem (1200px) |
| `2xl` | 87.5rem (1400px) |

**Typography** — numeric scale utilities in `typography.pcss`: `.text-16`, `.text-18`, `.text-20`, `.text-24`, `.text-30`, `.text-36`, `.text-60`, `.text-100` (all responsive).

**Buttons** — two coexisting patterns in `buttons.pcss`:
- **New pattern** (use this for all new components): `.button-{variant}` → e.g. `.button-primary`, `.button-secondary`. Applied via the `Button` component (`src/components/Button/index.tsx`). Variants are extracted from Figma during `/extractify-setup`.
- **Preserved utilities** (do not remove, do not replicate): `.hover-underline`, `.hover-underline-white`.

**Grid** — `.base-container` for centered max-width container; use Tailwind `grid grid-cols-*` and `flex` utilities for column layouts.

---

## Styling rules

1. **Tailwind utilities first** — only write PostCSS when utilities are not enough
2. **All values in rem** — never `px` in generated CSS (1rem = 16px)
3. **No CSS modules** — use PostCSS files under `src/assets/css/`
4. When adding component-specific PostCSS:
   - Create `src/assets/css/components/<component-name>.pcss`
   - Add `@import` to `global.css`
   - Use BEM naming inside the file
5. Tailwind v4 uses CSS-first config — all theme tokens live in `theme.pcss` under `@theme`

---

## Naming conventions

| What | Convention | Example |
|---|---|---|
| Component folder | PascalCase | `src/components/HeroBanner/index.tsx` |
| Preview route | kebab-case | `src/app/components/hero-banner/page.tsx` |
| CSS file | kebab-case | `src/assets/css/components/hero-banner.pcss` |
| Color token | `--color-<name>` kebab-case | `--color-brand-primary` |
| Font token | `--font-<role>` | `--font-body`, `--font-heading` |
| SVG icon | kebab-case | `public/svg/ux/arrow-right.svg` |
| Button variant class | `button-{variant}` | `.button-primary`, `.button-secondary` |
| Utility class | lowercase with hyphens | `.text-16`, `.button--black` |

---

## RichText components

- **`RichText`** — wrapper for raw HTML strings (uses `dangerouslySetInnerHTML`). Use when rendering an HTML string inside a larger component.
- **`RichTextWrapper`** — layout wrapper that renders `RichText` inside a centered container column. Use for standalone body text sections.
- All HTML passed to `RichText` or `dangerouslySetInnerHTML` **must** be sanitized with `sanitizeHtml()` from `@/utils/functions` — never pass raw CMS, API, or AI-generated strings directly.
- All styling for rich-text content goes in `rich-text.pcss` — never add inline styles to `<RichText>`.
- Do not use `.scss` or CSS modules in components — use PostCSS files under `src/assets/css/`.

---

## Utility functions (`src/utils/functions.ts`)

- `tel(str)` — convert to `tel:` link
- `mailto(str)` — convert to `mailto:` link
- `limitCharacters(text, limit)` — truncate with "..."
- `slugify(str)` — URL-safe slug
- `firstChar(str)` — first character
- `getFocusableElements(container)` — all focusable elements inside
- `getFocusableElementsOutside(container)` — all focusable elements outside
- `formatNumber(value)` — thousand separators
- `capitalizeFirstLetter(str)` — capitalize first char
- `sanitizeHtml(html)` — sanitize an HTML string before `dangerouslySetInnerHTML`; required for all CMS, API, or AI-generated content

---

## Self-updating docs (required after every task)

When you introduce a new convention or discover a pattern:

| What changed | Update this doc |
|---|---|
| New folder or route | `_docs/structure/project-structure.md` |
| New naming/styling convention | `_docs/structure/project-rules.md` |
| New a11y requirement | `_docs/structure/accessibility.md` |
| Convention deprecated | `_docs/structure/doc-versioning.md` |
| Pattern/fix/edge case | `_docs/learnings.md` |

When encountering old patterns in the codebase: follow the docs (not old code), do not refactor unprompted, and log widespread divergences in `learnings.md`.

---

## Visual review loop (Ralph pattern — required for UI tasks)

Every component or page task that involves UI must go through a **visual refinement loop** before being marked as complete. This project uses the **Ralph Loop pattern** — an iterative self-correction cycle where the AI compares its output against the Figma source of truth and keeps refining until the result is satisfactory.

Read `_docs/structure/visual-review.md` for the full protocol.

### Available tools

| Tool | Purpose |
|---|---|
| **Figma MCP** (Desktop or Remote) | Source of truth — extract design context, screenshots, and specs. Desktop is preferred (runs at `127.0.0.1:3845` when Figma Desktop is open in Dev Mode); Remote (`mcp.figma.com/mcp`, OAuth) is the automatic fallback when Desktop is unavailable. |
| **Playwright CLI** | Render preview pages and capture screenshots for comparison |

### The loop (execute for every UI task)

```
1. BUILD    → Generate/update the component following all project rules
2. SERVE    → Ensure dev server is running (npm run dev)
3. CAPTURE  → Use Playwright CLI to screenshot the preview page
4. COMPARE  → Use the resolved Figma MCP (Desktop or Remote) to get the design screenshot/context for the same component
5. EVALUATE → Compare both images — check spacing, colors, typography, alignment, sizing
6. REFINE   → If differences found → fix the code → go back to step 3
7. COMPLETE → If visual match is satisfactory → proceed to output checklist
```

### Exit conditions (when to stop the loop)

- Layout structure matches (same grid, same visual hierarchy)
- Spacing and sizing are consistent (margins, paddings, gaps)
- Colors match the design tokens
- Typography (size, weight, line-height) matches
- Interactive states are implemented (hover, focus, active)
- Maximum **5 iterations** reached (log remaining issues in `learnings.md`)

### Playwright CLI usage in this project

```bash
# Screenshot a component preview page (desktop)
npx playwright screenshot --browser=chromium --viewport-size=1440,900 --wait-for-timeout=2000 \
  http://localhost:3000/components/<component-name> .screenshots/<component-name>-desktop.png

# Then read the saved file
Read → .screenshots/<component-name>-desktop.png
```

### Figma usage for comparison

```bash
# Get design context (code + screenshot + metadata)
get_design_context → nodeId + fileKey from the Figma URL

# Get just a screenshot for visual comparison
get_screenshot → nodeId + fileKey from the Figma URL
```

### Breakpoint testing (required for responsive components)

When the component has responsive behavior, capture and compare at these breakpoints:

| Breakpoint | Viewport width |
|---|---|
| Mobile | 375px |
| Desktop | 1440px |

Use Playwright CLI with the `--viewport-size` flag for each breakpoint:

```bash
# Mobile
npx playwright screenshot --browser=chromium --viewport-size=375,812 --wait-for-timeout=2000 \
  http://localhost:3000/components/<component-name> .screenshots/<component-name>-mobile.png

# Desktop
npx playwright screenshot --browser=chromium --viewport-size=1440,900 --wait-for-timeout=2000 \
  http://localhost:3000/components/<component-name> .screenshots/<component-name>-desktop.png
```

---

## Output checklist (before finishing any task)

- [ ] All relevant docs were read before writing code
- [ ] Component has a `Props` interface with defaults
- [ ] No CSS modules used
- [ ] All images use `<Image>` from `next/image` — no bare `<img>` tags
- [ ] All `<Image>` components have `alt` (descriptive or `""` for decorative)
- [ ] `<figure>` used only where `<figcaption>` is present
- [ ] Internal links use `<Link>`; `mailto:` / `tel:` / external URLs use `<a>`
- [ ] Icon-only interactive elements have `aria-label`
- [ ] Preview page created (if new component)
- [ ] Link added to `src/app/page.tsx` (if new preview)
- [ ] Visual review loop completed (if UI task — see visual review section above)
- [ ] Desktop screenshot captured via Playwright CLI; mobile captured if design has mobile layout
- [ ] Docs updated if a new convention was introduced
- [ ] `learnings.md` updated if something worth capturing was discovered
