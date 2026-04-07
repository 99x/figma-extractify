## Figma page contract: Icons / SVG

This doc defines how to extract SVG icons from Figma and apply them in this boilerplate.

### Figma node (project-specific)

> The Figma URL for this step is managed in `_docs/figma-paths.yaml` under `setup.icons`.
> Edit that file directly, or run `/extractify-setup` and the wizard will ask you for it.

### Source of truth

- **Figma**: any frame or component set containing UI icons
- **Repo**: `public/svg/ux/` — all UI icons live here as standalone `.svg` files

---

### Figma export settings (required)

When exporting SVGs from Figma:

- Format: **SVG**
- Include `id` attribute: **off**
- Outline text: **on** (if the icon contains text)
- Contents only: **on** (no surrounding artboard padding)
- `viewBox` must be present — do not strip it

Clean the exported SVG before committing:

- Remove any `fill` or `stroke` color attributes that are hardcoded (replace with `currentColor` if the icon needs to inherit color)
- Remove Figma-generated metadata (`<title>`, `data-*` attributes, comments)
- Keep the `viewBox` attribute

---

### Naming convention

- Always kebab-case: `arrow-right.svg`, `close.svg`, `chevron-down.svg`
- Prefix with a category when the library grows: `nav-close.svg`, `social-instagram.svg`
- Never use spaces, PascalCase, or underscores in SVG filenames

---

### Where icons go

All UI SVG icons belong in:

```
public/svg/ux/<icon-name>.svg
```

Do not create subfolders inside `ux/` unless the library exceeds ~50 icons, at which point use category prefixes first.

---

### Usage patterns

Use `<Image>` from `next/image` for all icon rendering. Never use a bare `<img>` tag.

> **Note on SVGs and next/image**: `next/image` does not optimize SVGs (no format conversion), but it keeps the image pattern consistent across the codebase. If you need `currentColor` inheritance or animation, use inline `<svg>` instead (see "When to use inline SVG" below).

#### Pattern A — decorative icon (next to visible text)

```tsx
import Image from 'next/image'

<Image src="/svg/ux/arrow-right.svg" alt="" width={24} height={24} className="flex-shrink-0" />
```

- `alt=""` because the surrounding element provides the label
- No `<figure>` needed — size directly on `<Image>`

#### Pattern B — standalone meaningful icon

```tsx
import Image from 'next/image'

<Image src="/svg/ux/warning.svg" alt="Warning" width={32} height={32} />
```

- Provide a descriptive `alt` — it replaces the icon for screen readers

#### Pattern C — icon-only interactive elements

When an icon is the only content inside a `<button>` or link, the interactive element must have `aria-label`. Use `<Link>` from `next/link` for internal navigation, plain `<a>` for external URLs and protocol links (`mailto:`, `tel:`).

```tsx
import Image from 'next/image'
import Link from 'next/link'

{/* Action button */}
<button aria-label="Close menu">
  <Image src="/svg/ux/close.svg" alt="" width={20} height={20} />
</button>

{/* Internal navigation link */}
<Link href={social.url} aria-label={`Visit our ${social.platform} page`}>
  <Image src="/svg/ux/social-instagram.svg" alt="" width={24} height={24} />
</Link>

{/* External link */}
<a href={social.url} target="_blank" rel="noopener noreferrer" aria-label={`Visit our ${social.platform} page`}>
  <Image src="/svg/ux/social-instagram.svg" alt="" width={24} height={24} />
</a>
```

- `alt=""` on `<Image>` because `aria-label` on the wrapper provides the label
- Never have both a descriptive `alt` and an `aria-label` — that doubles the announcement

#### When to use inline SVG instead

Inline SVG (JSX `<svg>` element) is appropriate only when:

- The icon must inherit `currentColor` for dynamic coloring
- The icon requires animated properties

In all other cases, prefer `<Image>` from `next/image` — it is simpler and more portable.

---

### Accessibility rules summary

| Situation | `alt` on `<Image>` | `aria-label` on wrapper |
|---|---|---|
| Decorative icon next to visible text | `alt=""` | not needed |
| Standalone meaningful icon | descriptive `alt` | not needed |
| Icon-only button or link | `alt=""` | required on `<button>` / `<Link>` / `<a>` |

---

### Hashed filenames from `get_design_context`

When using the Figma Desktop MCP `get_design_context` with `dirForAssetWrites`, SVGs are exported using content hashes as filenames (e.g. `0f95f2a3...svg`) — not semantic names. Before using exported icons you must:

1. List all files in `.figma-assets/`
2. Read each SVG to identify its purpose
3. Rename to kebab-case semantic names before placing in `public/svg/ux/`

Never reference hashed filenames in component code.

### `dirForAssetWrites` is required

`get_design_context` on the Figma Desktop MCP **always requires** `dirForAssetWrites` pointing to `.figma-assets/` in the project root. Omitting it causes a "Path for asset writes required" error. The directory is created automatically by the tool.

```
dirForAssetWrites: ".figma-assets/"
```

---

### Extraction checklist

From Figma, extract per icon:

- [ ] Icon name → convert to kebab-case filename
- [ ] Export as SVG with settings above
- [ ] Remove hardcoded fill/stroke colors (replace with `currentColor` if needed)
- [ ] Strip Figma metadata from the SVG file
- [ ] Rename from hashed filename to semantic kebab-case name
- [ ] Place in `public/svg/ux/`

---

### Output format (for AI runs)

When the AI finishes icon extraction, it should produce:

- A table of icons added: Figma name → filename → `public/svg/ux/<name>.svg`
- A note on any icons that required `currentColor` instead of hardcoded fill
- A note on any icons that were skipped and why
