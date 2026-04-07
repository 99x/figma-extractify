## Accessibility contract

This doc defines the **minimum accessibility requirements** for every component in this repo.
It is not exhaustive — it covers the rules that prevent the most common failures.

---

### Why this exists

Components built here are consumed by real users, including assistive technology users. Inaccessible markup in a component becomes inaccessible in production with no easy fix.

---

### Rules (always enforced)

#### Images

Always use `<Image>` from `next/image`. Never use a bare `<img>` tag. `next/image` handles `<picture>`, srcset, lazy loading, and layout shift prevention internally — you don't add those yourself.

- Every `<Image>` must have `alt` passed via props — never omit it
- If the image is decorative (no meaning), pass `alt=""` explicitly
- The `alt` must describe what the image shows, not its filename or "image of..."
- Use `<figure>` only when you need a `<figcaption>` — it is not required otherwise
- Apply sizing and layout classes directly on `<Image>` (or on a wrapping `<div>` if needed for layout)

```tsx
import Image from 'next/image'

// Correct — Image with explicit dimensions
<Image src={image.src} alt={image.alt} width={image.width ?? 800} height={image.height ?? 450} className="w-full aspect-video object-cover" />

// Correct — decorative image, explicit alt=""
<Image src={divider.src} alt="" width={1440} height={2} className="w-full" />

// Correct — with caption, <figure> is justified here
<figure>
	<Image src={image.src} alt={image.alt} width={image.width ?? 800} height={image.height ?? 450} className="w-full object-cover" />
	{image.caption && <figcaption className="caption mt-2">{image.caption}</figcaption>}
</figure>

// Correct — fill mode for unknown dimensions (parent must be position: relative)
<div className="relative w-full aspect-video overflow-hidden">
  <Image src={image.src} alt={image.alt} fill className="object-cover" />
</div>

// Wrong — bare <img> tag
<img src={image.src} alt={image.alt} />

// Wrong — <Image> without alt
<Image src={image.src} width={800} height={450} />
```

#### Links

- Use `<Link>` from `next/link` for all internal navigation links
- Use a plain `<a>` only for external URLs, `mailto:` addresses, and `tel:` numbers — these are external protocols, not Next.js routes
- Every link must have a readable label
- If the link contains only an icon or image, add `aria-label` describing the destination
- Never use "click here", "read more", or "link" as the visible or accessible label
- **Never nest block-level elements (`<div>`, `<p>`, `<h1>`–`<h6>`, `<section>`, etc.) inside `<Link>` or `<a>`** — this is invalid HTML. Use only inline elements (`<span>`, `<strong>`, `<em>`, `<Image>`, `<svg>`) inside an anchor. If a clickable card or block area is needed, use `position: relative` on the container and a `<Link className="absolute inset-0">` to stretch it.

```tsx
import Link from 'next/link'

// Correct — internal navigation with <Link>
<Link href={item.url}>
  <span className="font-semibold">{item.title}</span>
</Link>

// Correct — external protocol links use plain <a>
<a href={mailto(email)} className="hover-underline">{email}</a>
<a href={tel(phone)}>{phone}</a>
<a href="https://external-site.com" target="_blank" rel="noopener noreferrer">External</a>

// Correct — full-card link via stretched link pattern
<article className="relative">
  <h3>{item.title}</h3>
  <p>{item.description}</p>
  <Link href={item.url} className="absolute inset-0" aria-label={item.title} />
</article>

// Wrong — block element inside <Link>
<Link href={item.url}>
  <div className="flex flex-col gap-4">
    <h3>{item.title}</h3>
  </div>
</Link>
```

#### Buttons

- Every `<button>` must have a readable label (text content or `aria-label`)
- Icon-only buttons must have `aria-label`
- Use `<button>` for actions, `<Link>` for internal navigation, `<a>` for external links — never swap them

```tsx
// Correct — visible label
<button className="button button--black">{props.label}</button>

// Correct — icon-only with aria-label
<button aria-label="Close menu">
  <Image src="/svg/ux/close.svg" alt="" width={20} height={20} />
</button>
```

#### Heading hierarchy

- Use heading levels semantically: `<h1>` once per page, then `<h2>`, `<h3>`, etc.
- Do not skip levels (e.g., `<h1>` → `<h3>`)
- Do not use heading elements just for visual size — use typography utility classes instead

```tsx
// Correct — semantic heading with visual class
<h2 className="h1">{props.title}</h2>

// Wrong — heading used for visual size, skips level
<h4 className="h1">{props.title}</h4>
```

#### Interactive elements

Focus styles are already defined globally in `globals.pcss`:

```css
a, button, input {
  @apply outline-offset-2 focus-visible:outline-1 focus-visible:outline-black;
}
```

- Do not suppress or override these focus styles
- If a component uses custom focus styles, ensure they are at least as visible as the default

#### Landmark regions

- Wrap navigation in `<nav>` with `aria-label` if there are multiple navs on the page
- Use `<main>`, `<header>`, `<footer>` semantically in layout components
- Use `<section>` with `aria-label` or `aria-labelledby` when the section has a distinct topic

---

### What the AI must check before finishing a component

- [ ] No bare `<img>` tags — always use `<Image>` from `next/image`
- [ ] All `<Image>` components have `alt` (descriptive or empty `""` for decorative)
- [ ] `<figure>` used only where a `<figcaption>` is present or semantics genuinely require it
- [ ] Internal links use `<Link>` from `next/link`; external/protocol links use `<a>`
- [ ] All `<Link>` and `<a>` tags have readable labels (visible text or `aria-label`)
- [ ] All icon-only `<button>` tags have `aria-label`
- [ ] Heading levels are sequential and not skipped
- [ ] Focus styles are not removed or overridden without an accessible replacement

---

### Automated accessibility auditing

In addition to the manual checklist above, the project includes an **automated axe-core audit** that runs as part of the Ralph Loop (visual review). See `_docs/structure/a11y-audit.md` for full details.

The automated audit catches issues that manual review often misses: color contrast violations, ARIA attribute validity, keyboard trap risks, and landmark structure problems.

Run it manually for any preview page:

```bash
node scripts/a11y-audit.js http://localhost:3000/components/<name> --component=<name>
```

---

### What is out of scope here

The following are important but beyond this baseline contract:

- ARIA live regions (for dynamic content updates)
- Full keyboard navigation patterns (for complex widgets like modals, dropdowns)
- Color contrast ratios — **partially covered** by `axe-core` automated checks (see `a11y-audit.md`), but design token choices are still the responsibility of `01-colors.md`
- Screen reader testing

If a component requires any of the above, add a note in `learnings.md`.
