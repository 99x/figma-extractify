# Troubleshooting

Common failure modes, mapped to the doc that fixes them. If you hit an error here, jump to the linked section — this page is an index, not a duplicate of the fix steps.

---

## Figma MCP won't connect

Classify the failure by what the IDE is reporting, then follow the matching fix in [`figma-mcp-setup.md`](figma-mcp-setup.md).

| Symptom | Classification | Fix |
|---|---|---|
| Tool not found in the IDE toolkit | Server not registered | [figma-mcp-setup.md → `.mcp.json` reference](figma-mcp-setup.md#mcpjson-reference) |
| `401` / "unauthorized" / "needs OAuth" | Remote not authenticated | [figma-mcp-setup.md → Enabling Remote MCP (OAuth)](figma-mcp-setup.md#enabling-figma-remote-mcp-oauth) |
| OAuth completed but tools still 401 | Token not picked up | Fully restart Claude Code / Cursor |
| Desktop at `127.0.0.1:3845` refuses connections | Desktop app closed, or Dev Mode off, or port in use | [figma-mcp-setup.md → Enabling Desktop MCP](figma-mcp-setup.md#enabling-figma-desktop-mcp) |
| OAuth uses the wrong Figma account | Browser signed in with wrong account | Open `figma.com` in incognito, sign in correctly, re-run OAuth |

Shortcut: run `/extractify-preflight` — it classifies the failure and prints the right fix block.

---

## `generate_figma_design` not available

Only exists on Remote MCP (not Desktop). Used by `/extractify-discover` write-back. Requirements:

1. Remote MCP authenticated ([OAuth](figma-mcp-setup.md#enabling-figma-remote-mcp-oauth))
2. `npm run dev` running
3. Preview page served on localhost

If all three are true and it still fails, see [`ai-workflow.md` → MCP and tooling edge cases](ai-workflow.md#mcp-and-tooling-edge-cases).

---

## Visual review

**"Missing Figma screenshot" from `scripts/visual-diff.js`**
`get_screenshot` returns the image inline to chat — it does NOT write a file. Write the raw PNG bytes to `.screenshots/<component-name>-figma.png` before running the diff script. Full detail: [`visual-diff.md`](visual-diff.md).

**Similarity stuck below 95%**
AI should open `.screenshots/<component-name>-diff.png`, identify the divergence, fix the code, capture again. After 5 iterations without passing, log remaining issues in `learnings.md` and stop. See [`visual-review.md`](visual-review.md) for the full loop.

**Image size mismatch**
The script auto-resizes the smaller image to match. Warning only — not an error.

---

## a11y audit

**"axe-core not installed"**
Run `npm install -D @axe-core/playwright` or re-run the installer and accept the optional QA tools prompt.

**Zero violations locally but stakeholders still report a11y issues**
axe-core covers automated checks only — it does NOT replace manual keyboard-nav + screen-reader testing. See [`a11y-audit.md`](a11y-audit.md) and [`accessibility.md`](accessibility.md) for manual test protocols.

---

## Playwright / Chromium

**`npx playwright screenshot` fails with "browser not installed"**
Run `npx playwright install chromium`. The installer does this automatically — if it failed, re-run manually.

**Screenshot is blank / captures loading spinner**
Increase `--wait-for-timeout=2000` to `3000` or higher for heavy pages. Confirm `npm run dev` is up and the preview page renders at the URL you're capturing.

---

## Ralph Loop

**Loop never stops / doesn't exit on completion**
The stop hook at `.claude/hooks/ralph-stop.sh` is missing or not executable. Fix: copy from the figma-extractify template and `chmod +x`. Run `/extractify-preflight` — it checks the hook and can auto-install it.

**Loop runs forever without progressing**
Max iterations is 5. If the component still fails at iteration 5, the loop terminates and logs the remaining issues — that's expected.

---

## `.next` corruption

Client-side behavior (hooks, `useEffect`, event listeners) suddenly stops working after mixed `next build` / failed compile cycles.

Fix: stop dev server → `rm -rf .next` → `npm run dev`. Confirm the Network tab loads `/_next/static/chunks/main-app.js` without 404s. Source: [`ai-workflow.md`](ai-workflow.md#mcp-and-tooling-edge-cases).

---

## Icons / SVG

**SVGs have hashed filenames like `0f95f2a3...svg`**
`get_design_context` with `dirForAssetWrites` exports using content hashes, not semantic names. Rename to kebab-case before use. Full checklist: [`front-end/05-icons-svg.md`](../front-end/05-icons-svg.md).

**`dirForAssetWrites` missing from `get_design_context` call**
Always pass it when extracting icons — otherwise SVGs are inline in the response, not written to disk. See [`05-icons-svg.md`](../front-end/05-icons-svg.md).

---

## Code Connect

Mapping not appearing in Dev Mode, props interface drift, node-not-found, and duplicate mappings → see [`code-connect.md` → Troubleshooting](code-connect.md#troubleshooting).

---

## `figma-paths.yaml` resolution

Skills accept the file at either `figma-paths.yaml` (project root) or `_docs/figma-paths.yaml`. If both exist they can drift out of sync — keep only one. `/extractify-setup` documents the resolution rule.

---

## Installer / uninstaller

**Installer says "No app root detected"**
Run `install.sh` from a directory that contains `package.json`, or from `figma-extractify/` with `boilerplate/package.json` one level up.

**`install.bat` exists but instructions only show `install.ps1`**
Double-click `install.bat` OR run `install.ps1` — both work. `.bat` is a thin wrapper around `.ps1` for Windows users who prefer double-clicking.

**After uninstall, `_docs/` and `.mcp.json` are still in my project**
By design — the uninstaller removes `.claude/commands/`, `.claude/skills/figma-use/`, the optional QA dev-deps, and runtime state (`.screenshots/`, `.audit/`, `.ralph-loop-state.json`). It does NOT touch your source, `_docs/`, `.mcp.json`, or `CLAUDE.md` — delete those manually if you want a full removal.

---

## Something else

Before opening an issue, check:

1. `_docs/learnings.md` — "Common mistakes" pinned at the top covers the 12 most frequent pitfalls.
2. `/extractify-preflight` — diagnoses most environment issues automatically.
3. The per-contract docs in `_docs/front-end/` — most "my extraction looks wrong" issues are covered there.
