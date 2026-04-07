## Figma page contract: Typography

This doc defines the **required structure** of the Figma page named **`Typography`** and the **exact repo updates** needed to sync fonts and a type scale into this boilerplate.

### Figma node (project-specific)

> The Figma URL for this step is managed in `_docs/figma-paths.yaml` under `setup.typography`.
> Edit that file directly, or run `/extractify-setup` and the wizard will ask you for it.

### Units policy (required)

- **Base font size is always 16px**
- **Always use rem in generated code**
	- \(1rem = 16px\)
	- Convert any Figma px values using \(rem = px / 16\)
- **Never generate `px`-based arbitrary values**
	- Bad: `text-[16px]`
	- Good: `text-base` or `text-[1rem]`
- **Prefer Tailwind named sizes when they match**
	- Example: `text-base` instead of `text-[1rem]`
	- When there is no exact match, use **rem-based** arbitrary values (eg `text-[4.375rem]`)

### Source of truth

- **Figma**: the `Typography` page (text styles and/or typography variables)
- **Repo**:
	- Font tokens: `src/assets/css/base/theme.pcss` under `@theme` → `/* fonts */`
	- Type scale utilities: `src/assets/css/base/typography.pcss` under `@layer utilities`
	- Optional preview: `src/app/assets/typography/page.tsx`

### Figma page requirements (must exist)

On the Figma page **`Typography`**, maintain these sections:

- **Font families**
	- Body font
	- Heading font
	- Optional: mono/UI font
- **Text styles (the scale)**
	- Headings (H1–H6 or the subset you use)
	- Body (default)
	- Lead/ingress (optional)
	- Small / caption
	- Quotation (optional)
- **Responsive rules**
	- Desktop size + line-height
	- Mobile size + line-height
	- Breakpoint used to switch (eg `md`, `lg`)
- **Weights**
	- Only list weights you actually use

### Figma naming rules (recommended)

Use consistent style names that encode purpose:

- `heading/h1`
- `heading/h2`
- `body/default`
- `body/small`
- `body/caption`
- `special/quote`

Avoid naming styles by raw numbers only (eg `Text 18`) unless the whole system is numeric-first.

### Extraction checklist (what to extract from Figma)

From the `Typography` page, extract:

- **Font families**
	- Family name (eg `Inter`)
	- Source:
		- Google Fonts (preferred to label explicitly)
		- Custom / licensed font file
	- Fallback stack (if specified)
- **Weights used per family**
	- Eg `400`, `500`, `600`, `700`
- **Per text style**
	- Style name
	- Font family (body vs heading)
	- Font weight
	- Font size (px)
	- Line height (px or %)
	- Letter spacing (if any)
	- Text transform (uppercase etc) if part of the style
	- Responsive mapping (desktop vs mobile)

### Repo updates (the “apply” step)

#### 1) Define font tokens in Tailwind v4 theme

Edit `src/assets/css/base/theme.pcss` under `/* fonts */`.

Preferred token names:

- `--font-body`
- `--font-heading`
- Optional: `--font-mono`

#### Google Fonts — use `next/font/google` (recommended)

Use `next/font/google` for Google Fonts. It eliminates layout shift, self-hosts the font automatically, and is the Next.js best practice.

```tsx
// src/app/layout.tsx
import { Inter, Playfair_Display } from 'next/font/google'

const bodyFont = Inter({ subsets: ['latin'], variable: '--font-body' })
const headingFont = Playfair_Display({ subsets: ['latin'], variable: '--font-heading' })

export default function RootLayout({ children }: { children: React.ReactNode }) {
  return (
    <html lang='en' className={`${bodyFont.variable} ${headingFont.variable}`}>
      <body>{children}</body>
    </html>
  )
}
```

Then reference those CSS variables in `src/assets/css/base/theme.pcss`:

```css
@theme {
  /* fonts */
  --font-body: var(--font-body);
  --font-heading: var(--font-heading);
}
```

Replace `Inter` and `Playfair_Display` with the families extracted from Figma. The `variable` option maps the font to the CSS custom property consumed by Tailwind.

#### 2) Replace typography utility classes

**Replace the entire contents** of `src/assets/css/base/typography.pcss` — do not preserve or merge existing utilities. The file should only contain the classes extracted from Figma, wrapped in `@layer utilities`. Starting fresh ensures no stale or mismatched classes remain from a previous run.

Two supported patterns (pick one and stay consistent):

- **Numeric scale utilities** (already used in this repo): `.text-16`, `.text-18`, etc
- **Semantic utilities**: `.h1`, `.h2`, `.body`, `.caption`, etc

Recommended approach:

- Provide semantic classes for headings and body styles
- Optionally keep numeric helpers if designers think in numbers

Important:

- **All sizes must be expressed in rem** in generated code
- If you must use arbitrary values, they must be **rem-based** (never px-based)
	- Bad: `text-[40px]`
	- Good: `text-[2.5rem]`

Example (structure only):

```css
@layer utilities {
	.h1 {
		@apply font-heading font-semibold text-4xl md:text-5xl leading-[1.1]
	}

	.body {
		@apply font-body text-base md:text-lg leading-relaxed
	}

	.caption {
		@apply font-body text-sm leading-snug
	}
}
```

Example (rem-based arbitrary values when needed):

```css
@layer utilities {
	.h1 {
		/* 70px = 4.375rem, 40px = 2.5rem */
		@apply font-heading font-normal text-[2.5rem] md:text-[4.375rem] leading-[1.2]
	}

	.body {
		/* 20px = 1.25rem, 16px = 1rem */
		@apply font-body font-normal text-base md:text-[1.25rem] leading-relaxed
	}
}
```

#### 3) Keep the typography preview page in sync (required)

Update `src/app/assets/typography/page.tsx` so it renders the actual utilities you provide.

Rules:

- Each preview block should show:
	- Utility class name
	- Desktop spec and mobile spec (size/line-height)
	- A sample sentence

### External (self-hosted) fonts

If the font is not from Google Fonts (licensed/external font), it must be self-hosted:

- Put the font files in `public/fonts/`
	- The user must manually add the `.woff2` and `.woff` files there
	- Prefer `.woff2` as the primary source

Then create a font-face stylesheet and load it globally:

- Add a new file: `src/assets/css/base/fonts.pcss`
- Import it from `src/assets/css/global.css` near the top (before using the fonts anywhere)

In the font-face stylesheet:

- Define `@font-face` for each family + weight + style you extracted from Figma
- Ensure `font-family` names match what you put into `--font-body` and `--font-heading`
- Use `font-display: swap` for better UX

For self-hosted fonts, `@font-face` in PostCSS is the right approach since `next/font/local` requires a static file path known at build time — both work fine in this boilerplate.

### Output format (for AI runs)

When the AI finishes extraction and application, it should produce:

- Fonts loaded:
	- Source (Google vs custom)
	- Weights included
	- Where it was configured (`layout.tsx` and/or CSS)
- A table of text styles:
	- Figma style → CSS utility → desktop spec → mobile spec

