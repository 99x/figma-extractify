## Figma page contract: Grid / container

This doc defines the **required structure** of the Figma page named **`Grid / container`** and the **exact repo updates** needed to sync breakpoints, container sizing, and grid rules into this boilerplate.

### Figma node (project-specific)

> The Figma URL for this step is managed in `_docs/figma-paths.yaml` under `setup.grid`.
> Edit that file directly, or run `/extractify-setup` and the wizard will ask you for it.

### Units policy (required)

- **Base font size is always 16px**
- **Always use rem in generated code**
	- \(1rem = 16px\)
	- Convert any Figma px values using \(rem = px / 16\)
- **Allowed exception (docs only)**: you may keep a `px` comment in docs for clarity
	- Example: `--breakpoint-md: 48rem; /* 768px */`

### Source of truth

- **Figma**: the `Grid / container` page (desktop + mobile specs)
- **Repo**:
	- Breakpoints: `src/assets/css/base/theme.pcss` under `@theme` → `/* breakpoints */`
	- Container utility: `src/assets/css/base/grid.pcss` (`@utility base-container`)

### Figma page requirements (must exist)

On the Figma page **`Grid / container`**, maintain these sections:

- **Breakpoints**
	- Names and widths (px)
	- The breakpoint used to switch typography + layout (if different)
- **Container**
	- Max width (desktop)
	- Side padding (mobile/tablet/desktop)
	- Alignment (centered)
- **Grid**
	- Column count (usually 12)
	- Gutter width
	- Optional: baseline spacing unit (eg 4px or 8px)
- **Examples**
	- A frame showing the container at key breakpoints
	- A frame showing the grid overlay and gutters

### Extraction checklist (what to extract from Figma)

From the `Grid / container` page, extract:

- **Breakpoints**
	- Name (eg `sm`, `md`, `lg`)
	- Width in px
- **Container**
	- Max width in px (or `none`) → convert to rem for code
	- Side padding in px per breakpoint → convert to rem for code
	- Whether container is fixed-width or fluid until max
- **Grid**
	- Columns count
	- Gutter width (px) → convert to rem for code
	- Outer margin (if defined separately from padding) → convert to rem for code

### Repo updates (the “apply” step)

#### 1) Update breakpoints in Tailwind v4 theme

Edit `src/assets/css/base/theme.pcss` under `/* breakpoints */`.

Rules:

- Keep names consistent across codebase (avoid renaming once published)
- Use `rem` values in the file, but preserve the px comment for clarity
- Ensure ordering is smallest → largest

Example (structure only):

```css
@theme {
	/* breakpoints */
	--breakpoint-sm: 36rem; /* 576px */
	--breakpoint-md: 48rem; /* 768px */
	--breakpoint-lg: 62rem; /* 992px */
}
```

#### 2) Update the container utility

Edit `src/assets/css/base/grid.pcss`, specifically `@utility base-container`.

Goal:

- Match Figma container max width
- Match side padding per breakpoint

Recommended pattern:

- Use `mx-auto` for centering
- Use `max-w-[...]` for max width (rem-based if arbitrary)
- Use responsive `px-[...]` to enforce padding (Tailwind spacing scale is already rem-based)

Example (structure only):

```css
@utility base-container {
	/* 1200px = 75rem */
	@apply mx-auto w-full max-w-[75rem] px-4 sm:px-6 lg:px-8
}
```

#### 3) Grid layout approach

This repo uses **Tailwind layout utilities** exclusively. There are no bootstrap-style `.row` / `.col-*` helpers.

`grid.pcss` contains only the `@utility base-container` definition. All column layouts use Tailwind `grid` or `flex` utilities directly in components:

```tsx
{/* 2-column */}
<div className="grid grid-cols-1 md:grid-cols-2 gap-6">...</div>

{/* 3-column */}
<div className="grid grid-cols-1 md:grid-cols-3 gap-6">...</div>

{/* Centered narrow text column */}
<div className="w-full mx-auto md:w-10/12 lg:w-8/12 xl:w-1/2">...</div>
```

### Output format (for AI runs)

When the AI finishes extraction and application, it should produce:

- Breakpoints table:
	- Figma name → repo breakpoint token → px
- Container table:
	- Max width
	- Padding per breakpoint
- Grid summary:
	- Columns
	- Gutter
	- Which strategy was used (Option A vs B)

