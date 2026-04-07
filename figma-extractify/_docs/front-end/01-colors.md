## Figma page contract: Colors

This doc defines the **required structure** of the Figma page named **`Colors`** and the **exact repo updates** needed to sync a new project’s color system into this boilerplate.

### Figma node (project-specific)

> The Figma URL for this step is managed in `_docs/figma-paths.yaml` under `setup.colors`.
> Edit that file directly, or run `/extractify-setup` and the wizard will ask you for it.

### Source of truth

- **Figma**: the `Colors` page (variables or styles)
- **Repo**: `src/assets/css/base/theme.pcss` under `@theme` → `/* colors */`

### Figma page requirements (must exist)

On the Figma page **`Colors`**, maintain these sections:

- **Palette (brand + neutral)**  
	Solid colors you actually use in UI.
- **Semantic tokens**  
	Tokens like `text/default`, `bg/surface`, `border/default`, `success`, `warning`, `danger`.
- **States (optional but recommended)**  
	Hover/active/focus/disabled variants if they are unique tokens (not derived).
- **Modes (optional)**  
	If you support Light/Dark (or other themes), use **Figma variable modes**.

### Figma variable naming rules (recommended)

Use either **semantic-first** or **palette-first**, but be consistent:

- **Semantic-first**: `text/default`, `text/muted`, `bg/surface`, `border/subtle`, `brand/primary`
- **Palette-first**: `brand/blue/500`, `neutral/100`, `neutral/900`

Avoid naming that encodes usage in a component (eg `button/primary/bg`) unless you have a design system that mandates it.

### Extraction checklist (what to extract from Figma)

From the `Colors` page:

- **All color variables** used by the design system
- **Per token**:
	- Variable name (including group path)
	- Hex value (preferred), and RGBA if alpha is used
	- Which mode(s) it applies to (if multiple modes exist)
	- Notes about usage (eg “main text color”, “surface background”, “accent”)

If Figma uses styles instead of variables:

- Extract color styles and treat them as tokens
- Migrate to variables when possible (preferred long-term)

### Normalization rules (Figma → repo token names)

Repo tokens are CSS variables under `@theme` and **must** follow this pattern:

- `--color-<token-name>`

Convert Figma names to kebab-case:

- `/` becomes `-`
- spaces become `-`
- remove characters that aren’t letters/numbers/hyphens
- collapse repeated hyphens

Examples:

- `brand/Primary` → `--color-brand-primary`
- `text/default` → `--color-text-default`
- `neutral/100` → `--color-neutral-100`

### Repo updates (the “apply” step)

#### 1) Update Tailwind v4 theme tokens

Edit `src/assets/css/base/theme.pcss`:

- Replace the existing `/* colors */` section with the new project tokens
	- Do **not** keep old/demo colors from the boilerplate
	- Follow the same grouping and ordering pattern (brand → semantic → neutral)
- Keep the `--color-*` variables grouped and sorted (brand, semantic, neutral)

#### Default color override rules

Three default tokens must always be present: `--color-pure-white`, `--color-pure-black`, and `--color-red`. Apply the following logic for each:

**`--color-pure-white` and `--color-pure-black`:** matched by exact hex only — see the merge logic in `/extractify-setup`.

**`--color-red` — special rule (name + hex):**
- If Figma contains a color identified as "red" (name contains "red", "danger", or "error" — case-insensitive; or hex hue is in the red spectrum ~340°–10°) → use that Figma color as `--color-red`. Do **not** also add `#E74C3C`.
- If Figma has no red → keep `--color-red: #E74C3C` as the default.
- **Never have two red tokens.** If the Figma red has a different name (e.g. `--color-danger`), rename it to `--color-red` rather than keeping both.

Example (structure only):

```css
@theme {
	/* colors */
	--color-brand-primary: #000000
	--color-brand-secondary: #ffffff
	--color-text-default: #111111
	--color-bg-surface: #ffffff
	--color-border-default: #e5e7eb
}
```

#### 2) Verify generated utilities exist

Because this repo uses Tailwind v4 CSS-first config (`@theme`), these utilities should be available after adding tokens:

- `bg-<token>`
- `text-<token>`
- `border-<token>`

Example usage:

```tsx
export function Example() {
	return (
		<div className='bg-bg-surface text-text-default border border-border-default'>
			Hello
		</div>
	)
}
```

#### 3) Keep the colors preview page in sync (required)

Update `src/app/assets/colors/page.tsx` so it reflects the **current** token set.

Rules:

- The preview must show **all** design tokens that are meant to be used
- Do not show random “unused” colors unless you label them clearly as legacy
- Prefer listing **token names + swatch + hex value**

Recommended approach:

- Maintain a single array of tokens in the page (or import it from a small token list file if you create one later)
- Render swatches using `bg-<token>` classes

> ⚠️ **Tailwind static class rule (critical):** Tailwind scans source files for complete class name strings at build time. **Never construct class names via template literals** (e.g. `` `bg-${item.token}` ``). Tailwind cannot detect dynamically constructed strings and will not include them in the CSS. Always store the full class name as a literal string in your data array:
>
> ```tsx
> // ✅ CORRECT — full class name as a static string
> const colors = [
>   { token: 'brand-primary', hex: '#FF6B35', bg: 'bg-brand-primary' },
> ]
> // use: <div className={item.bg} />
>
> // ❌ WRONG — dynamic construction, Tailwind will ignore it
> // <div className={`bg-${item.token}`} />
> ```

### Output format (for AI runs)

When the AI finishes extraction and application, it should produce:

- A table of tokens applied (Figma name → repo token → value)
- A list of any tokens it could not map (and why)
- A note on whether modes were present (Light/Dark) and how they were handled
