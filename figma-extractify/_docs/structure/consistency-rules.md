## Consistency rules

These rules apply whenever building a component (`/extractify-new-component`).
The goal is to produce output that feels like it belongs to an existing, coherent system — not a fresh interpretation of each Figma frame.

**When in doubt: match existing patterns over Figma precision.**

---

## Rule 1 — Aspect ratios: always round to standards

When a component contains an image, video, or any element with a fixed aspect ratio, always round to the nearest standard ratio:

| Standard | Tailwind class | Use case |
|---|---|---|
| 16 / 9 | `aspect-video` | Video, wide hero, landscape images |
| 9 / 16 | `aspect-[9/16]` | Portrait video, mobile hero |
| 4 / 3 | `aspect-[4/3]` | Classic photo, card images |
| 3 / 4 | `aspect-[3/4]` | Portrait photo, editorial card |
| 1 / 1 | `aspect-square` | Thumbnails, avatars, icons |

**Rounding threshold:** if the Figma ratio is within ~10% of a standard, use the standard.

Examples:
- `16/8` → use `aspect-video` (16/9)
- `15/9` → use `aspect-video` (16/9)
- `4/2.75` → use `aspect-[4/3]`
- `400x395` → use `aspect-square`
- `800x610` → use `aspect-[4/3]`

Only use a custom `aspect-[x/y]` if the ratio is genuinely distinct from all standards (e.g. a wide cinematic banner at 21/9).

---

## Rule 2 — Layout: always use the grid system

Always use the existing grid infrastructure — never create ad-hoc width or layout styles.

### Outer wrapper
Every section or full-width block must use `base-container` as the outer width constraint:

```tsx
<section>
  <div className="base-container">
    {/* content */}
  </div>
</section>
```

### Column layout
When the design has a multi-column layout, use Tailwind `grid` utilities:

```tsx
<div className="base-container">
  <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
    <div>...</div>
    <div>...</div>
  </div>
</div>
```

Common patterns:

| Layout | Tailwind classes |
|---|---|
| 2 equal columns | `grid grid-cols-1 md:grid-cols-2 gap-6` |
| 3 equal columns | `grid grid-cols-1 md:grid-cols-3 gap-6` |
| Centered narrow column | `w-full mx-auto md:w-10/12 lg:w-8/12 xl:w-1/2` |
| Full 12-col grid (overlay) | `grid grid-cols-4 sm:grid-cols-6 md:grid-cols-12` |

### When Figma shows a custom layout
If the Figma layout is close to a standard grid split (e.g. 50/50, 33/66, 25/75), map it to the closest Tailwind `grid-cols-*` value. Only create custom layout CSS if the Figma layout is genuinely not achievable with built-in utilities.

---

## Rule 3 — Pattern matching: round up to existing tokens

Before creating any new token, utility class, or Tailwind arbitrary value, check whether an existing pattern is close enough.

**Threshold: if the difference is ≤ ~15%, use the existing pattern.**

### Typography
- Check `typography.pcss` for the existing size utilities (`.text-16`, `.text-18`, `.text-20`, etc. or semantic `.h1`, `.h2`, etc.)
- If Figma shows `font-size: 17px` and the codebase has `.text-16` and `.text-18`, use whichever is closer
- Do not create `.text-17` for a single component

### Spacing
- Use Tailwind's spacing scale (`gap-4`, `py-6`, `px-8`, etc.)
- If Figma shows `padding: 22px`, use `p-6` (24px) — not `p-[22px]`
- Only use arbitrary values (e.g. `px-[22px]`) if the value is a hard constraint from the design (e.g. a fixed-size element like an icon or avatar)
- Always write sizes in `rem`, never in `px` — see the full rule in `project-rules.md` (exception: single-pixel values like `border: 1px` are fine)

### Colors
- Always use `--color-*` tokens from `theme.pcss`
- If a Figma color is visually close to an existing token, use the token — don't hardcode hex values
- Only add a new token to `theme.pcss` if the color is genuinely distinct

### Border radius
- Use Tailwind's `rounded-*` scale — check what's already used in the codebase and stay consistent
- Don't mix `rounded-lg` and `rounded-[8px]` for the same visual intent

---

## Rule 4 — Typography: extract from Figma, don't guess

Never guess the heading level or text style of a Figma text node based on its visual size alone.

### Required process

1. **Use Figma Desktop MCP `get_variable_defs`** on the text node to extract:
   - `font-size`
   - `line-height`
   - `font-family`
   - `font-weight`
   - `letter-spacing` (if defined)

2. **Match to existing patterns** in `typography.pcss`:
   - If an exact or near-exact match exists (≤ 15% difference in size) → use that utility class
   - If no close match exists → only then create a new utility

3. **Use semantic HTML correctly** based on the component's content hierarchy, not Figma layer names:
   - The first heading in a component should be `<h2>` if the page `<h1>` is in the Header/Hero
   - Don't make something `<h1>` just because it looks big in Figma
   - Always think about the document outline

### Example
Figma text node: `font-size: 32px`, `font-weight: 700`, `line-height: 1.2`, `font-family: Antonio`

Process:
1. `get_variable_defs` confirms these values
2. Check `typography.pcss` — `.text-30` exists at `30px` with the same weight and family
3. `32px` is within 15% of `30px` → use `.text-30`
4. Only create `.text-32` if the design strictly requires it and the difference matters visually

---

## Rule 5 — Prefer named Tailwind classes over arbitrary values

Before writing an arbitrary value like `px-[3rem]` or `max-w-[84rem]`, check if it maps to a Tailwind named class.

**Conversion:** Tailwind's spacing scale is `1 unit = 0.25rem = 4px`. To convert a rem value: `units = rem × 4`.

| Arbitrary value | Named class | How |
|---|---|---|
| `px-[3rem]` | `px-12` | 3 × 4 = 12 |
| `py-[1.5rem]` | `py-6` | 1.5 × 4 = 6 |
| `gap-[2rem]` | `gap-8` | 2 × 4 = 8 |
| `max-w-[84rem]` | `max-w-336` | 84 × 4 = 336 |
| `text-[1rem]` | `text-base` | Tailwind named size |
| `text-[0.875rem]` | `text-sm` | Tailwind named size |

**Rule — two steps, always apply both:**

1. **Exact:** if `value_in_rem × 4` is a whole number → use the named class directly.
2. **Round:** if the result is NOT a whole number but is within ~15% of the nearest whole number → round to that class. Only use an arbitrary value if no named class is close enough.

Examples of rounding:
- `size-[1.5625rem]` → `1.5625 × 4 = 6.25` → rounds to `6` → use `size-6` ✅
- `px-[1.375rem]` → `1.375 × 4 = 5.5` → rounds to `6` → use `px-6` ✅
- `gap-[0.9rem]` → `0.9 × 4 = 3.6` → rounds to `4` → use `gap-4` ✅
- `w-[4.8rem]` → `4.8 × 4 = 19.2` → rounds to `20` → use `w-20` ✅
- `max-w-[73.5rem]` → `73.5 × 4 = 294` → whole number → use `max-w-294` ✅

This also applies to `w-`, `h-`, `size-`, `min-h-`, `m-`, `p-`, `inset-`, `translate-`, `space-` and other spacing utilities.

---

## Rule 6 — Never add visual properties not present in Figma

Only render what Figma shows. Never apply `border-radius`, `box-shadow`, `text-shadow`, `opacity`, or other decorative properties as stylistic assumptions — even when they "look nice" or feel like safe defaults.

**Why this matters:** The visual diff step will catch these additions as failures, requiring a fix pass. It is always faster to omit a property and check the diff than to add it and explain the deviation.

If you want to suggest an enhancement, flag it as a comment after completing the task — do not silently include it in the output.

---

## Rule 7 — Watch for text underline bleeding from `<Link>` into children

Browser default `text-decoration: underline` on `<Link>` and `<a>` cascades to all inline child elements (`<span>`, `<strong>`, `<p>` used as inline, etc.). If the Figma design does not show underlines on those child text elements, the diff image will show mismatches that are easy to miss in code review.

**Fix:** Add `no-underline` on the `<Link>` itself, or use `[&_*]:no-underline` to target children individually.

```tsx
// Underline bleeding — add no-underline to prevent cascade
<Link href={item.url} className="no-underline">
  <span className="font-semibold">{item.title}</span>
</Link>

// Or target children specifically
<Link href={item.url} className="[&_*]:no-underline">
  <h3>{item.title}</h3>
  <p>{item.description}</p>
</Link>
```

Always check for underline bleed-through during the visual comparison step — it shows clearly in the diff image.

---

## Rule 8 — Always use Tailwind v4 syntax and methods

This project uses Tailwind v4. Use its native patterns — never fall back to v3 workarounds.

### CSS variable colors

Use the CSS variable shorthand syntax, not `var()`:

```css
/* ✅ Tailwind v4 */
@apply bg-(--color-brand-primary) text-(--color-text-default);

/* ❌ Old / verbose */
@apply bg-[var(--color-brand-primary)];
```

### Defining custom utilities

Use `@utility` for new single utilities, `@layer utilities` for groups:

```css
/* ✅ Single utility */
@utility base-container {
  @apply mx-auto w-full max-w-7xl px-4 sm:px-6 lg:px-8;
}

/* ✅ Group of related utilities */
@layer utilities {
  .button-primary { @apply ...; }
  .button-secondary { @apply ...; }
}
```

### Theme tokens

All design tokens live in `theme.pcss` under `@theme` — never use `tailwind.config.js` or `tailwind.config.ts`:

```css
@theme {
  --color-brand-primary: #000000;
  --font-body: 'Inter', sans-serif;
  --breakpoint-md: 48rem;
}
```

### Responsive variants

Use the breakpoint tokens defined in `theme.pcss` — they map directly to `sm:`, `md:`, `lg:`, etc.:

```tsx
<div className="text-base md:text-lg lg:text-xl">...</div>
```

### Gradients

Use the new gradient syntax, not the v3 `bg-gradient-to-*` + `from-*` + `to-*` pattern:

```css
/* ✅ v4 */
@apply bg-linear-to-r from-blue-500 to-purple-500;
```
