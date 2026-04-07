---
name: extractify-audit
description: "Use this skill whenever the user wants to audit, check, validate, or review all components in the figma-extractify project for compliance with project rules. Triggers on: 'audit components', 'check compliance', 'run audit', 'are my components correct', 'check for violations', 'find issues with my components', 'validate components', '/extractify-audit', 'check all components', 'what components have problems', 'compliance report', or any request to scan the codebase for rule violations. Also trigger when the user says 'is everything correct' or 'what needs fixing' in the context of this project."
---

# Extractify Audit — Batch Compliance Check

Scans every component in `src/components/` against the full project compliance checklist. Produces a report at `.audit/report.md` without modifying any files. Also runs axe-core accessibility audits and pixel diff checks if the optional QA tools are installed.

## Before starting

Read:
1. `_docs/structure/project-rules.md` — naming and file conventions
2. `_docs/front-end/04-component-contract.md` — component contract
3. `.claude/commands/extractify-audit.md` — **full implementation: read this and follow it exactly**

## What it checks per component

**Structure**
- `Props` interface defined with defaults
- No CSS modules used
- No hardcoded content (no inline strings outside props)
- No internal data fetching

**Images**
- `<Image>` from `next/image` — no bare `<img>` tags
- `alt` attribute present on every `<Image>`
- No `<figure>` wrapper unless `<figcaption>` is present

**Links**
- `<Link>` used for internal Next.js routes only
- Plain `<a>` used for `mailto:`, `tel:`, external URLs

**Accessibility**
- Icon-only interactive elements have `aria-label`
- Heading levels are sequential (no skipping)
- axe-core scan (if Playwright is installed) — 0 critical/serious violations

**Preview + docs**
- Preview page exists at `src/app/components/<kebab-name>/page.tsx`
- Preview linked from `src/app/page.tsx`
- CSS file (if present) registered in `src/assets/css/global.css`

## Output

Produces `.audit/report.md` with:
- Pass/fail per component per check
- Summary table
- List of issues to fix with file paths and line references

To fix issues found: run `/extractify-new-component <name>` — it includes a compliance fix phase.
