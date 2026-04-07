## Component contract

This doc defines how every component in `src/components/` must be written.
It exists so any AI (or developer) generates components that are consistent, reusable, and easy to maintain.

---

### The minimal contract

Every component must:

1. Define a `Props` interface (TypeScript)
2. Export a default function that receives and destructures those props
3. Provide default values for optional props
4. Render using only what it receives via props (no internal data fetching, no hardcoded content)
5. Use Tailwind utilities for styling (PostCSS only when utilities are not enough)
6. Avoid CSS modules

---

### Reference example (from the codebase)

This is the `Header` component — use it as a structural reference:

```tsx
// src/components/Header/index.tsx
import Link from 'next/link'
import Image from 'next/image'

// 1. Define the Props interface
interface Props {
  logo?: {
    src: string
    url: string
    alt: string
    width?: number
    height?: number
  }
  menu?: {
    label: string
    url: string
  }[]
}

// 2. Export a default function, destructure props with defaults
export default function Header({
  logo = {
    src: '/img/logo.png',
    url: '/',
    alt: 'Logo',
    width: 120,
    height: 40
  },
  menu = [
    { label: 'Item 01', url: '#' },
    { label: 'Item 02', url: '#' }
  ]
}: Props) {
  return (
    <section className='py-4 bg-stone-100'>
      <div className='base-container'>
        <div className='flex items-center justify-between gap-4'>

          {/* Use next/link for internal navigation */}
          <Link href={logo?.url} className='flex w-30'>
            <Image
              src={logo?.src}
              alt={logo?.alt}
              width={logo?.width ?? 120}
              height={logo?.height ?? 40}
              className='w-full h-auto'
            />
          </Link>

          <ul className='flex items-center gap-8'>
            {menu?.map((item, i) => (
              <li key={i}>
                <Link href={item?.url}>{item?.label}</Link>
              </li>
            ))}
          </ul>

        </div>
      </div>
    </section>
  )
}
```

---

### Props interface rules

- Always define an interface named `Props` at the top of the file
- Use `?` (optional) for all props that have defaults
- Nest related data into sub-objects (e.g., `logo: { src, url, alt }` not three separate props)
- Use arrays for repeatable content (e.g., `menu: { label, url }[]`)
- Avoid generic types like `any` and `object`

### Image props pattern

Image data should always include `src`, `alt`, and optionally `width`, `height`, and `caption`. Use `<Image>` from `next/image` for all images — it handles `<picture>`, srcset, lazy loading, and layout shift prevention internally.

```tsx
import Image from 'next/image'

interface Props {
  image?: {
    src: string
    alt: string
    width?: number
    height?: number
    caption?: string
  }
}
```

Render images with `<Image>`. Apply sizing classes directly on `<Image>`. Add `<figure>` only when a `<figcaption>` is needed:

```tsx
{/* Standard — no caption, no <figure> needed */}
{props.image && (
  <Image
    src={props.image.src}
    alt={props.image.alt}
    width={props.image.width ?? 800}
    height={props.image.height ?? 450}
    className="w-full aspect-video object-cover"
  />
)}

{/* With caption — <figure> is justified here */}
{props.image && (
  <figure>
    <Image
      src={props.image.src}
      alt={props.image.alt}
      width={props.image.width ?? 800}
      height={props.image.height ?? 450}
      className="w-full aspect-video object-cover"
    />
    {props.image.caption && (
      <figcaption className="caption mt-2">{props.image.caption}</figcaption>
    )}
  </figure>
)}

{/* Fill mode — when dimensions are unknown; parent must be position: relative */}
<div className="relative w-full aspect-video overflow-hidden">
  <Image src={props.image.src} alt={props.image.alt} fill className="object-cover" />
</div>
```

- Never use a bare `<img>` — always use `<Image>` from `next/image`
- Always provide `alt` (descriptive or `""` for decorative)
- Do not add `<figure>` as a boilerplate wrapper for every image — only use it when `<figcaption>` is needed

---

### When the component needs interactivity (hooks)

Add `'use client'` as the very first line:

```tsx
'use client'

import { useState } from 'react'

interface Props {
  items?: string[]
}

export default function Accordion({ items = [] }: Props) {
  const [open, setOpen] = useState<number | null>(null)
  // ...
}
```

---

### When the component needs its own CSS

Only do this if Tailwind utilities are genuinely not enough:

1. Create `src/assets/css/components/<component-name>.pcss`
2. Add `@import './components/<component-name>.pcss'` to `src/assets/css/global.css`
3. Use BEM naming inside the PostCSS file

```css
/* src/assets/css/components/accordion.pcss */
.accordion { ... }
.accordion__item { ... }
.accordion__item--open { ... }
```

---

### Demo page (required for every new component)

Every component must have a preview page:

```tsx
// src/app/components/<component-name>/page.tsx

import Header from '@/components/Header'

export default function HeaderPreview() {
  return (
    <Header
      logo={{ src: '/img/logo.png', url: '/', alt: 'Logo' }}
      menu={[
        { label: 'About', url: '/about' },
        { label: 'Contact', url: '/contact' }
      ]}
    />
  )
}
```

After creating the demo, add a link in `src/app/page.tsx`.

---

### Quick checklist

Before marking a component done:

- [ ] `Props` interface defined at the top
- [ ] All optional props have default values
- [ ] No CSS modules
- [ ] No hardcoded content (or hardcoded content is labeled as a default/fallback)
- [ ] If hooks are used, `'use client'` is the first line
- [ ] All images use `<Image>` from `next/image` — no bare `<img>` tags
- [ ] All `<Image>` components have `alt` (descriptive or `""` for decorative)
- [ ] `<figure>` used only where `<figcaption>` is present
- [ ] Preview page created at `src/app/components/<name>/page.tsx`
- [ ] Link added to `src/app/page.tsx`
