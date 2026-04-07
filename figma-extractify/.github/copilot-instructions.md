# Figma Extractify — GitHub Copilot Instructions

This is a **Next.js 16 + Tailwind CSS v4** boilerplate for building isolated, props-driven UI components from Figma designs. It is NOT a full Next.js application. Routes under `src/app/` are local preview pages only.

## Always read before writing code

- `_docs/SKILL.md` — step-by-step workflow
- `_docs/start-here.md` — golden rules
- `_docs/learnings.md` — top 10 common mistakes + known patterns

## Non-negotiable rules

**Images**
- Always use `<Image>` from `next/image` — never a bare `<img>`
- `next/image` renders `<picture>` internally — never add a `<figure>` wrapper unless a `<figcaption>` is needed
- All `<Image>` components must have `alt` (descriptive, or `""` for decorative)

**Links**
- `<Link>` from `next/link` is a router component — use it only for internal Next.js routes
- Use plain `<a>` for `mailto:`, `tel:`, and external `http` URLs

**Styling**
- No CSS modules — use Tailwind utilities or PostCSS files under `src/assets/css/`
- All values in rem — never px in generated CSS

**Components**
- Every component is 100% props-driven — no internal data fetching, no hardcoded content
- Define a `Props` interface with defaults at the top of every component file
- Add `'use client'` only when the component uses hooks or browser APIs

**Naming**
- Component folder: `src/components/<PascalCase>/index.tsx`
- Preview route: `src/app/components/<kebab-case>/page.tsx`
- CSS file: `src/assets/css/components/<kebab-case>.pcss`

## Tech stack

- Next.js 16 (App Router, Turbopack default)
- React 19
- Tailwind CSS v4 — CSS-first config via `@theme` in `src/assets/css/base/theme.pcss`
- TypeScript 5 strict mode
- Path alias: `@/*` → `./src/*`
