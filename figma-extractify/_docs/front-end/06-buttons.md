## Figma page contract: Buttons

This doc defines the **required structure** of the Figma page named **`Buttons`** and the **exact repo updates** needed to sync button styles into this boilerplate, including the `Button` component and its CSS classes.

### Figma node (project-specific)

> The Figma URL for this step is managed in `_docs/figma-paths.yaml` under `setup.buttons`.
> Edit that file directly, or run `/extractify-setup` and the wizard will ask you for it.

### Source of truth

- **Figma**: the `Buttons` page (component variants showing all button styles)
- **Repo**: `src/assets/css/base/buttons.pcss` (CSS classes) + `src/components/Button/index.tsx` (React component)

---

## Button component contract

### Props interface

```tsx
interface Props {
  variant: string             // REQUIRED — determines the CSS class applied (e.g. 'primary', 'secondary')
  href?: string               // if provided → renders as <a>; otherwise renders as <button>
  type?: 'button' | 'submit'  // only applies when rendered as <button> (default: 'button')
  target?: '_self' | '_blank' // only applies when rendered as <a>
  rel?: string                // only applies when rendered as <a>
  disabled?: boolean          // only applies when rendered as <button>
  children?: React.ReactNode
  [key: string]: any          // spreads any additional props (onClick, aria-label, data-*, etc.)
}
```

> **Note on the `variant` prop name:** The prop is named `variant` (not `style`) because `style` is a reserved React prop that accepts `React.CSSProperties`. Using `style` would break type safety and conflict with inline style overrides.

### Rendering logic

- If `href` is provided → render as `<a>`. The `type`, `disabled` props are ignored.
- If `href` is absent → render as `<button>`. The `target`, `rel` props are ignored.

```tsx
import Link from 'next/link'

interface Props {
  variant: string
  href?: string
  type?: 'button' | 'submit'
  target?: '_self' | '_blank'
  rel?: string
  disabled?: boolean
  children?: React.ReactNode
  [key: string]: any
}

export default function Button({
  variant,
  href,
  type = 'button',
  target,
  rel,
  disabled = false,
  children,
  ...props
}: Props) {
  const className = `button-${variant}`

  if (href) {
    return (
      <Link href={href} target={target} rel={rel} className={className} {...props}>
        {children}
      </Link>
    )
  }

  return (
    <button type={type} disabled={disabled} className={className} {...props}>
      {children}
    </button>
  )
}
```

### Required output files

| File | What it contains |
|---|---|
| `src/components/Button/index.tsx` | The `Button` component following the contract above |
| `src/app/components/button/page.tsx` | Preview page rendering variants in their visible states only |
| `src/assets/css/base/buttons.pcss` | CSS classes for each variant (`.button-primary`, `.button-secondary`, etc.) |

### Preview page rules

The preview page at `src/app/components/button/page.tsx` shows **static states only**:

- ✅ Default state — always shown
- ✅ Disabled state — show as a separate instance if the variant has one
- ✅ Loading state — show as a separate instance if present in the design
- ❌ Hover state — do NOT render a separate visual block; it is an interactive state
- ❌ Focus state — do NOT render a separate visual block; it is an interactive state

Hover and focus **must still be implemented in the CSS** — they just don't need a dedicated static preview block. The user can verify them by hovering/tabbing in the browser.

---

## CSS class contract

### Naming convention

Each button variant maps to a CSS class in `src/assets/css/base/buttons.pcss`:

```
.button-{variant}
```

Examples: `.button-primary`, `.button-secondary`, `.button-ghost`, `.button-danger`

> **Why this pattern?** The class can be applied to any element — `<button>`, `<a>`, `<label>`, `<div>` — making the visual style fully decoupled from the HTML element.

### Class structure (add one block per variant extracted from Figma)

All button classes must live inside `@layer utilities` in `buttons.pcss`.

#### Tailwind v4 `@apply` rules (read before writing any code)

In Tailwind v4, `@apply` inside `@layer utilities` **only accepts Tailwind's built-in utility classes**. It does not accept custom classes defined elsewhere in `@layer utilities`. Violating this causes the error:

> _"@apply only accepts built-in utilities; .foo is a custom class."_

Rules:
- ✅ `@apply px-6 py-3 bg-black text-white rounded-full` — built-in utilities, always valid
- ❌ `@apply button-base` — custom class, will throw an error
- ❌ `@apply hover-underline` — custom class, throws an error even though it lives in the same file
- If multiple variants share base styles, **repeat** the Tailwind utilities in each class — do not create a shared custom base class and `@apply` it
- All values must use Tailwind utilities or CSS variables — no raw px values; use rem-based arbitrary values if needed: `px-[1.5rem]`
- Use Tailwind variant prefixes inline for states: `hover:bg-gray-800 focus-visible:outline-2 disabled:opacity-50`

Correct pattern:

```css
@layer utilities {
    .button-primary {
        @apply inline-flex items-center justify-center gap-2
               px-6 py-3 rounded-full
               bg-(--color-brand-primary) text-white font-semibold text-sm
               transition-colors duration-200
               hover:bg-(--color-brand-dark)
               focus-visible:outline focus-visible:outline-2 focus-visible:outline-offset-2
               disabled:opacity-50 disabled:pointer-events-none;
    }

    .button-secondary {
        @apply inline-flex items-center justify-center gap-2
               px-6 py-3 rounded-full border border-current
               bg-transparent text-(--color-brand-primary) font-semibold text-sm
               transition-colors duration-200
               hover:bg-(--color-brand-primary) hover:text-white
               focus-visible:outline focus-visible:outline-2 focus-visible:outline-offset-2
               disabled:opacity-50 disabled:pointer-events-none;
    }
}
```

### Typography inside button classes

Before writing font-size or line-height values in a button class, check `typography.pcss` for existing utilities (created in Step 2 of `/extractify-setup`).

- If the button's font-size matches an existing utility's Tailwind classes (e.g. `.text-14` uses `text-sm`) → use those same Tailwind classes directly in the button `@apply`
- If no match exists → use the appropriate Tailwind scale utility directly (e.g. `text-sm`, `text-base`)
- Never create a new custom text utility just for a button size

Since `@apply` cannot reference custom classes, this is always about using the same **Tailwind utility classes** (e.g. `text-sm`), not `@apply`-ing the custom class itself.

---

### What to extract from Figma

For each button variant found in the Figma page:

| Figma variant name | CSS class | Styles to extract |
|---|---|---|
| `primary` | `.button-primary` | bg, text color, border, border-radius, padding, font-weight |
| `secondary` | `.button-secondary` | same |
| _(others)_ | `.button-{name}` | same |

Also extract:
- Default size (padding, min-height) → repeat inline in each variant class (do not create a shared `.button-base` — see `@apply` rules above)
- Hover / focus / disabled states per variant
- Any size modifiers (e.g. `small`, `large`) → add as `.button-primary--sm` if present

### Preserved utility classes (do not remove)

The following classes exist in `buttons.pcss` and must be kept alongside the new `.button-{variant}` classes:

- `.hover-underline` — animated underline on hover (used across components)
- `.hover-underline-white` — animated underline with white overlay

---

## Figma page requirements (must exist)

The Figma **`Buttons`** page should contain:

- All button variants as named component variants (e.g. `variant=primary`, `variant=secondary`)
- Each variant shown in default, hover, focus, and disabled states
- Size variants if applicable (default, small, large)
- Both filled/outlined/ghost variants if the design system has them

---

## Extraction checklist

- [ ] List all variant names from Figma (normalize to kebab-case)
- [ ] Extract base styles (bg, text, border, padding, radius, font) for each variant
- [ ] Extract hover state per variant
- [ ] Extract focus-visible state per variant
- [ ] Extract disabled state per variant
- [ ] Create `.button-{variant}` class in `buttons.pcss` for each
- [ ] Create `src/components/Button/index.tsx` following the component contract above
- [ ] Create preview page at `src/app/components/button/page.tsx`
- [ ] Add link to `src/app/page.tsx`
- [ ] Verify the `Button` component renders correctly at all variants in the preview
