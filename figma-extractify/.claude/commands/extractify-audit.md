# Batch compliance audit

Scans all components in `src/components/` against the full project compliance checklist. Produces a report without modifying any files.

Use this to detect drift — components that were built before a rule was added, or that were manually edited and broke a convention.

---

## Phase 1 — Discovery

1. List all directories in `src/components/` — each is a component
2. For each component, identify:
   - Main file: `src/components/<Name>/index.tsx`
   - Preview page: `src/app/components/<kebab-name>/page.tsx`
   - PostCSS file (if any): `src/assets/css/components/<kebab-name>.pcss`
3. Read `src/app/page.tsx` to get the list of linked previews
4. Read `src/assets/css/global.css` to get the list of imported PostCSS files
5. Resolve `FIGMA_PATHS_FILE` once:
   - `figma-paths.yaml` in project root if present
   - else `_docs/figma-paths.yaml` if present
   - else no mapping file (treat as unmapped warning set)
6. If resolved, read `FIGMA_PATHS_FILE` to get the component-to-Figma mapping

---

## Phase 2 — Per-component audit (subagent: Haiku per component)

For each component found in Phase 1, spawn a Haiku subagent with this prompt:

```
You are a strict front-end QA engineer. Read the component file and check every item below. Report pass/fail for each. Do NOT modify any files.

**Component file:** {path}
**Preview file:** {preview_path}
{if PostCSS: **PostCSS file:** {pcss_path}}

Checklist:
- [ ] Props interface defined at top with TypeScript types
- [ ] All optional props have default values in the function signature
- [ ] No bare <img> — every image uses next/image inside a <figure> element
- [ ] No CSS modules imported (no .module.css or .module.scss)
- [ ] 'use client' is the first line IF any React hooks are used (useState, useEffect, useRef, etc.)
- [ ] Every image (next/image or img) has an alt attribute
- [ ] Every icon-only <button> has aria-label
- [ ] Every icon-only <a> or <Link> has aria-label
- [ ] No px values in className strings or inline styles (except border-related 1px values)
- [ ] No dynamic Tailwind class construction (template literals with variables inside class names)
- [ ] No hardcoded hex color values in className or style attributes

Return a JSON object: { "component": "Name", "results": { "check_name": true/false, ... }, "notes": ["any additional observations"] }
```

---

## Phase 3 — Project-wide audit (orchestrator)

After all per-component audits complete, the orchestrator checks:

1. **Preview pages exist**: For each component in `src/components/`, verify `src/app/components/<kebab-name>/page.tsx` exists
2. **Index links**: For each preview page, verify it is linked from `src/app/page.tsx`
3. **PostCSS imports**: For each `.pcss` file in `src/assets/css/components/`, verify it is `@import`ed in `global.css`
4. **Figma mapping**: For each component, check if `FIGMA_PATHS_FILE` has an entry (warning, not error)

---

## Phase 4 — Report

Generate a markdown report with this structure:

### Summary
- Components scanned: X
- Fully compliant: Y
- With issues: Z

### Per-component results

| Component | Props | figure wrap | alt text | aria-label | use client | rem only | No CSS modules | Status |
|---|---|---|---|---|---|---|---|---|
| Header | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | PASS |
| Footer | ✅ | ✅ | ❌ | ✅ | ✅ | ✅ | ✅ | FAIL |

### Project-wide results

| Check | Status | Details |
|---|---|---|
| All previews exist | ✅ / ❌ | Missing: [list] |
| All previews linked | ✅ / ❌ | Not linked: [list] |
| PostCSS imports complete | ✅ / ❌ | Missing imports: [list] |
| Figma paths mapped | ⚠️ | Unmapped: [list] |

### Top issues (by frequency)

1. Issue description — found in X components
2. Issue description — found in Y components

---

## Notes

- This audit is read-only — it does NOT fix anything
- To fix issues, run `/extractify-new-component <name>` which includes a compliance fix phase
- Run this audit periodically (e.g., after building 5+ components) to catch drift

The arguments are: $ARGUMENTS
