## RichText components

This doc explains when and how to use `RichText` and `RichTextWrapper` in this project.

---

### Why these components exist

Some components need to render raw HTML strings (body text, articles, descriptions from a CMS or API). These strings cannot be rendered safely as JSX — they must go through `dangerouslySetInnerHTML`. The `RichText` component is the approved wrapper for this.

---

### RichText

**File:** `src/components/RichText/index.tsx`

Use `RichText` whenever you need to render a raw HTML string inside a component.

```tsx
interface Props {
	className?: string
	children?: string
}
```

- `children` — the raw HTML string to render
- `className` — optional extra classes to apply alongside `.rich-text`

**Usage:**

```tsx
<RichText>{props.bodyText}</RichText>
```

The component applies the `.rich-text` CSS class automatically. All typography, spacing, and element styles for CMS-injected HTML are defined in `src/assets/css/base/rich-text.pcss`.

---

### RichTextWrapper

**File:** `src/components/RichTextWrapper/index.tsx`

A layout wrapper that renders `RichText` inside a centered `base-container` with a narrow column offset (10/12 desktop, 6/12 wide desktop).

Use `RichTextWrapper` for standalone article or body-text sections that need the standard centered column layout.

```tsx
interface Props {
	text: string
}
```

**Usage:**

```tsx
<RichTextWrapper text={props.bodyText} />
```

---

### Which one to use

| Situation | Component |
|---|---|
| Rendering an HTML string inside a larger component | `RichText` |
| Full-width standalone body text section with container | `RichTextWrapper` |

If `RichTextWrapper`'s column layout does not match your design, use `RichText` directly inside your own layout markup.

---

### Styling CMS-injected HTML

All styles for elements inside `.rich-text` (headings, paragraphs, lists, links, tables) belong in:

```
src/assets/css/base/rich-text.pcss
```

Do not add inline styles or Tailwind utilities to the `<RichText>` component itself to style its inner content — that HTML is injected externally and not under your control.

---

### Security requirement

All HTML strings passed to `RichText` or any `dangerouslySetInnerHTML` prop **must** be sanitized before rendering. Use the `sanitizeHtml()` utility from `@/utils/functions`:

```tsx
import { sanitizeHtml } from '@/utils/functions'

<div dangerouslySetInnerHTML={{ __html: sanitizeHtml(htmlString) }} />
```

Passing unsanitized strings from external sources (CMS, APIs, user input, AI-generated content) is an XSS vulnerability. The `RichText` component itself applies `sanitizeHtml` internally — but if you ever use `dangerouslySetInnerHTML` directly outside of `RichText`, you are responsible for sanitizing first.

---

### No `.scss` in components

Do not create new `.scss` files in components and do not import `.scss` or `.module.css` in any component under `src/components/`. If you need to extend `RichTextWrapper` styles, add them to `rich-text.pcss` or a new `components/rich-text-wrapper.pcss` file and import it from `global.css`.
