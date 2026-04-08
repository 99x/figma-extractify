---
name: extractify-preflight
description: "Use this skill to run environment checks before starting any figma-extractify workflow. Triggers on: '/extractify-preflight', 'run preflight', 'check my environment', 'is everything ready', 'pre-flight check', 'check dependencies', 'check if Figma MCP is connected', 'check Playwright', 'check my setup', 'is Playwright installed', 'is Figma connected', 'verify my environment', 'am I ready to extract', 'check QA tools', or any request to verify that the project environment is ready before running /extractify-setup or /extractify-new-component. Use this skill proactively when the user seems to be starting fresh or getting a new error during extraction."
---

# Extractify Pre-flight Check

Runs all environment checks and reports status. Use this before `/extractify-setup` or `/extractify-new-component` to catch missing tools early.

## Before starting

Read:
1. `.claude/commands/extractify-preflight.md` — **full implementation: read this and follow it exactly**

## What it checks

| Check | Required? | What fails if missing |
|---|---|---|
| Node.js v18.17+ | ✅ Required | Nothing works |
| Figma Desktop MCP | ✅ Required | Cannot extract from Figma (Figma Desktop must be open in Dev Mode) |
| Playwright + Chromium | ⚠️ Optional | Visual review loop (Ralph pattern) won't run |
| Node dependencies (`node_modules/`) | ✅ Required | Dev server won't start |
| `.screenshots/` directory | ⚠️ Optional | Auto-created if missing |
| `_docs/figma-paths.yaml` | ✅ Required | `/extractify-setup` won't know which Figma pages to extract |
| pixelmatch + pngjs | ⚠️ Optional | Visual diff falls back to AI-only comparison |
| @axe-core/playwright | ⚠️ Optional | Accessibility audit will be skipped |
| Ralph-loop stop hook | ⚠️ Optional | `/ralph-loop` won't enforce iteration limits |
| generate_figma_design (write-back) | ⚠️ Optional | `/extractify-discover` runs in analysis-only mode |

## Output format

```
Pre-flight check
────────────────────────────────────
  ✅  Node.js                   v20.x.x
  ✅  Figma Desktop MCP         connected (Dev Mode active)
  ✅  Figma Remote MCP          authenticated  ← optional, only for write-back
  ✅  Playwright + Chromium     ready (v1.x.x)
  ✅  Node dependencies         installed
  ✅  .screenshots/             ready
  ✅  figma-paths.yaml          found
  ✅  Visual diff (pixelmatch)  ready
  ✅  A11y audit (axe-core)     ready
  ✅  Ralph-loop stop hook      ready

────────────────────────────────────
All checks passed. Ready to run /extractify-setup.
```

Stop and show fix instructions for any ❌ before proceeding. ⚠️ items are non-blocking warnings. ✅ N/A items are sandbox-only skips — the bash script detected a Cowork environment and those checks don't apply.

**Blocking in both environments:** Figma Desktop MCP, missing node_modules, missing figma-paths.yaml.
**Blocking only locally (Claude Code):** Node.js version, Playwright/Chromium install failures.
**Never blocking:** Node/Playwright/Chromium when reported as sandbox N/A.
