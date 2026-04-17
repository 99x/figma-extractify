# Pre-flight check

Run all environment checks and report status. Use this before running `/extractify-setup` or `/extractify-new-component`.

> **Note:** The visual review loop (Ralph Loop) needs a working **Figma MCP** (Desktop OR Remote) and **Playwright + Chromium**. Both are checked below.

---

## Figma MCP resolution (Desktop preferred, Remote fallback)

Resolution rule used by this command and every other `/extractify-*`:

| Priority | Server | ID candidates (try in order) | URL |
|---|---|---|---|
| 1 | **Figma Desktop** | `user-figma`, `user-Figma Desktop`, `figma-desktop` | `http://127.0.0.1:3845/mcp` |
| 2 | **Figma Remote** | `plugin-figma-figma`, `figma` | `https://mcp.figma.com/mcp` |

Call `get_metadata` on the first candidate that exists at each tier. Desktop responds → use Desktop. Desktop unavailable → try Remote. Both fail → preflight fails with the block below.

**Background — server differences, Dev Mode requirements, OAuth flow, and common failures live in [`_docs/structure/figma-mcp-setup.md`](../../_docs/structure/figma-mcp-setup.md).** Do not re-explain that material in user-facing output; link to it instead.

Only two things matter operationally in this command:
- Desktop-only: reading the current selection (no URL). `/extractify-*` commands always pass URLs, so Remote is fully viable.
- Remote-only: `generate_figma_design` write-back (see Step 4).

---

## How to run

The entire pre-flight is **5 steps**:

1. **One bash script** — checks all system dependencies
2. **Check `.mcp.json`** — verify MCP config exists, auto-create if missing
3. **Resolve Figma MCP** — Desktop first, Remote fallback; fail only if both are down
4. **Check write-back** — verify `generate_figma_design` on Remote (non-blocking)
5. **Auto-install** — prompt user to install missing optional tools

---

## Step 1 — Run the system check script (single bash command)

```bash
export PATH="/opt/homebrew/bin:/usr/local/bin:$PATH"
export NVM_DIR="$HOME/.nvm"; [ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh"

# 1. Node.js
NODE_VER=$(node --version 2>/dev/null)
[ -z "$NODE_VER" ] && echo "NODE=missing" || echo "NODE=$NODE_VER"

# 2. Playwright CLI (auto-install if missing)
PW_VER=$(npx playwright --version 2>/dev/null)
if [ -z "$PW_VER" ]; then
  echo "PLAYWRIGHT=installing"
  npm install -D @playwright/test --silent 2>/dev/null
  PW_VER=$(npx playwright --version 2>/dev/null)
  [ -z "$PW_VER" ] && echo "PLAYWRIGHT=install_failed" || echo "PLAYWRIGHT=$PW_VER (just installed)"
else
  echo "PLAYWRIGHT=$PW_VER"
fi

# 3. Chromium (auto-install if missing)
CHROMIUM=$(ls "$HOME/Library/Caches/ms-playwright" 2>/dev/null | grep -i "^chromium" \
  || ls "$HOME/.cache/ms-playwright" 2>/dev/null | grep -i "^chromium" || echo "")
if [ -z "$CHROMIUM" ]; then
  echo "CHROMIUM=installing"
  npx playwright install chromium 2>/dev/null
  CHROMIUM=$(ls "$HOME/Library/Caches/ms-playwright" 2>/dev/null | grep -i "^chromium" \
    || ls "$HOME/.cache/ms-playwright" 2>/dev/null | grep -i "^chromium" || echo "")
  [ -z "$CHROMIUM" ] && echo "CHROMIUM=install_failed" || echo "CHROMIUM=installed ($CHROMIUM)"
else
  echo "CHROMIUM=ok ($CHROMIUM)"
fi

# 9. Ralph-loop stop hook
if [ -f ".claude/hooks/ralph-stop.sh" ] && [ -x ".claude/hooks/ralph-stop.sh" ]; then
  echo "RALPH_LOOP=ok"
else
  echo "RALPH_LOOP=missing (.claude/hooks/ralph-stop.sh not found or not executable)"
fi

# 10. jq
if command -v jq >/dev/null 2>&1; then echo "JQ=ok"
else echo "JQ=missing (macOS: brew install jq; Linux: apt-get install jq)"; fi

# 4. Node dependencies
[ -d "node_modules" ] && echo "DEPS=ok" || echo "DEPS=missing"

# 5. .screenshots/ directory (auto-create if missing)
if [ -d ".screenshots" ]; then echo "SCREENSHOTS=ok"
else mkdir -p .screenshots && echo "SCREENSHOTS=created"; fi

# 6. figma-paths.yaml (canonical location is _docs/, root is legacy fallback)
if [ -f "_docs/figma-paths.yaml" ]; then
  echo "YAML=ok (_docs/figma-paths.yaml)"
elif [ -f "figma-paths.yaml" ]; then
  echo "YAML=ok (figma-paths.yaml)"
else
  echo "YAML=missing"
fi

# 7. pixelmatch + pngjs (visual diff)
PIXELMATCH=$(node -e "try{require.resolve('pixelmatch');console.log('ok')}catch(e){console.log('missing')}" 2>/dev/null)
PNGJS=$(node -e "try{require.resolve('pngjs');console.log('ok')}catch(e){console.log('missing')}" 2>/dev/null)
if [ "$PIXELMATCH" = "ok" ] && [ "$PNGJS" = "ok" ]; then echo "VISUAL_DIFF=ok"
else echo "VISUAL_DIFF=missing"; fi

# 8. @axe-core/playwright (a11y audit)
AXE=$(node -e "try{require.resolve('@axe-core/playwright');console.log('ok')}catch(e){console.log('missing')}" 2>/dev/null)
[ "$AXE" = "ok" ] && echo "A11Y_AUDIT=ok" || echo "A11Y_AUDIT=missing"
```

Interpret each output line:

| Output | Status |
|---|---|
| `NODE=missing` | ❌ Install Node.js 18.17+ from https://nodejs.org |
| `NODE=v16.x.x` (below v18.17) | ❌ Run `nvm install 20 && nvm use 20` |
| `NODE=v18.17+` | ✅ |
| `PLAYWRIGHT=install_failed` | ❌ Run `npm install -D @playwright/test` manually |
| `PLAYWRIGHT=*` (any version) | ✅ |
| `CHROMIUM=install_failed` | ❌ Run `npx playwright install chromium` manually |
| `CHROMIUM=ok` or `installed` | ✅ |
| `DEPS=missing` | ❌ Run `npm install` |
| `DEPS=ok` | ✅ |
| `SCREENSHOTS=ok` or `created` | ✅ |
| `YAML=missing` | ❌ Run `/extractify-setup` to create it |
| `YAML=ok (...)` | ✅ |
| `VISUAL_DIFF=missing` | ⚠️ Run `npm install -D pixelmatch pngjs` |
| `VISUAL_DIFF=ok` | ✅ |
| `A11Y_AUDIT=missing` | ⚠️ Run `npm install -D @axe-core/playwright` |
| `A11Y_AUDIT=ok` | ✅ |
| `RALPH_LOOP=missing` | ⚠️ Stop hook missing — copy from figma-extractify template |
| `RALPH_LOOP=ok` | ✅ |
| `JQ=missing` | ⚠️ Install jq (`brew install jq`) |
| `JQ=ok` | ✅ |

---

## Step 2 — Check .mcp.json exists (required for MCP connectivity)

Before checking any MCP servers, verify that `.mcp.json` exists in the project root. This file tells Claude Code / Cursor how to reach the Figma MCP servers.

```bash
if [ -f ".mcp.json" ]; then
  echo "MCP_CONFIG=ok"
  cat .mcp.json
else
  echo "MCP_CONFIG=missing"
fi
```

If `MCP_CONFIG=missing`:

1. **Try to auto-fix:** create `.mcp.json` in the project root using the Write tool:

```json
{
  "mcpServers": {
    "figma": {
      "type": "http",
      "url": "https://mcp.figma.com/mcp"
    },
    "figma-desktop": {
      "type": "http",
      "url": "http://127.0.0.1:3845/mcp"
    }
  }
}
```

2. After creating, output:

```
⚠️  .mcp.json was missing — created with default Figma MCP config.
    Restart Claude Code / Cursor so it picks up the new MCP servers,
    then run /extractify-preflight again.
```

Then **stop** — the MCP servers won't be available until the IDE restarts.

If `MCP_CONFIG=ok`, also verify the file contains both `figma` and `figma-desktop` entries. If either is missing, warn the user and show what's expected.

---

## Step 3 — Resolve Figma MCP (Desktop preferred, Remote fallback)

At least **one** Figma MCP server must be reachable. Desktop is preferred because it works offline against the file you have open; Remote is the fallback so the workflow keeps running when Desktop isn't available (headless environments, Dev Mode not enabled, Figma Desktop closed).

**Resolve each candidate and probe:**

1. **Try Desktop.** For each of `user-figma`, `user-Figma Desktop`, `figma-desktop`, call `get_metadata` using the first one that exists.
   - Tool responds (even with an error) → ✅ `FIGMA_MCP=desktop:<resolved-id>`
   - Tool not found / connection refused → Desktop unavailable, continue.
2. **Try Remote.** For each of `plugin-figma-figma`, `figma`, call `get_metadata` using the first one that exists. Classify the response:
   - Tool responds with data → ✅ `FIGMA_MCP=remote:<resolved-id>` (registered AND authenticated).
   - Tool returns **401 / "unauthorized" / "authentication required" / "needs OAuth"** → ⚠️ Remote is **registered but NOT authenticated**. Walk the user through Step 3a (OAuth flow) — this is a one-time fix, do not treat it as "unavailable".
   - Tool **not found in the toolkit** at all → Remote is **not registered** in the IDE. The `.mcp.json` is either missing the `figma` entry, or the IDE wasn't restarted after editing it. Show the config fix (see failure block below).
   - **Connection error / timeout** → network issue or `mcp.figma.com` unreachable.
3. **If both failed → ❌ blocking failure.** Use the classification above to pick the right remediation block.

Downstream `/extractify-*` commands use the same resolution rule and pick whichever server this step found to work.

**If Desktop succeeds** → proceed to Step 4 with `FIGMA_MCP=desktop:…`. You may also probe Remote (Step 4 covers write-back) — it's non-blocking.

**If only Remote succeeds** → ⚠️ warn the user and proceed with `FIGMA_MCP=remote:…`:

```
⚠️  Figma Desktop MCP not reachable — falling back to Remote MCP.

Remote works for every read flow (colors, typography, components, screenshots,
Code Connect) as long as you pass a Figma URL. You lose:

  • Reading the current Figma Desktop selection (no URL needed) — not used
    by any /extractify-* command today, so this does not affect the workflow.


To switch back to Desktop later:
  1. Open Figma Desktop and log in
  2. Open any file and enable Dev Mode (Shift+D) — requires a paid plan
  3. Restart Claude Code / Cursor
  4. Run /extractify-preflight again
```

**If both failed** → ❌ stop and output a tailored fix block based on the Remote failure mode classified above:

Shared header:

```
❌ No Figma MCP server is reachable.

The figma-extractify commands need at least one of:

  • Figma Desktop MCP (http://127.0.0.1:3845/mcp)
    → Open Figma Desktop, log in, open any file, enable Dev Mode (Shift+D).
    → Dev Mode requires a paid Figma plan (Professional / Organization /
      Enterprise), or a free Education plan.
    → More info: https://help.figma.com/hc/en-us/articles/15023124644247

  • Figma Remote MCP (https://mcp.figma.com/mcp) — uses OAuth
```

Then append ONE of the three Remote-specific blocks below.

— **A. Remote not registered** (tool not found in the toolkit):

```
    → Your IDE doesn't know about the remote server yet.
    → Check that .mcp.json at the project root contains:

        "figma": {
          "type": "http",
          "url": "https://mcp.figma.com/mcp"
        }

    → Do NOT add an X-Figma-Token or any other headers — the remote
      server uses OAuth and rejects PATs.
    → After editing .mcp.json, fully quit and reopen Claude Code / Cursor
      (MCP servers are registered at IDE startup).
```

— **B. Remote registered but not authenticated** (401 / unauthorized):

```
    → The server is registered but OAuth hasn't been completed yet.
    → Walk through Step 3a below to authenticate:
        Claude Code: run `/mcp` → select `figma` → Authenticate
        Cursor:      MCP Settings → `figma` → Authenticate
      A browser window opens — log in to Figma and approve access.
    → If OAuth already succeeded once, fully restart the IDE so the new
      token is picked up by live MCP sessions.
```

— **C. Remote network error** (connection refused / timeout):

```
    → Could not reach mcp.figma.com. Check your internet connection,
      corporate proxy/VPN, or firewall rules for *.figma.com.
    → Retry after network is restored.
```

Close with:

```
Steps to fix:
  1. Pick the server that's easiest for you to enable (Desktop OR Remote)
  2. Apply the matching instructions above
  3. Fully restart Claude Code / Cursor (MCP servers connect at startup)
  4. Run /extractify-preflight again

Still not working? Check if another process is using port 3845 (Desktop):
  lsof -i :3845                 (macOS/Linux)
  netstat -ano | findstr 3845   (Windows)
```

---

## Step 3a — Remote OAuth not completed (401)

Triggered when Step 3 classifies Remote as **registered but not authenticated**. Output this block to the user (short — full troubleshooting lives in the setup doc):

```
⚠️  Figma Remote MCP is registered but not authenticated (OAuth needed).

Quick fix:
  Claude Code → run `/mcp` → select `figma` → Authenticate → restart the IDE.
  Cursor      → MCP Settings → `figma` → Authenticate → restart Cursor.
  (Or call any Figma tool — the first call triggers the OAuth prompt.)

Full walkthrough + troubleshooting (popup blockers, wrong account,
stale token, X-Figma-Token gotcha, account/plan issues):
  → _docs/structure/figma-mcp-setup.md

Then run /extractify-preflight again.
```

If the user asks for more detail, open [`_docs/structure/figma-mcp-setup.md`](../../_docs/structure/figma-mcp-setup.md) and walk through the Troubleshooting table.

---

## Step 4 — Check Figma write-back (optional — only for /extractify-discover)

`generate_figma_design` is only available on the **remote MCP**, not the desktop one.

Resolve the Remote server id (candidates: `plugin-figma-figma`, `figma`) and attempt to call `generate_figma_design` with a minimal test payload.

- Tool exists (even if it errors) → ✅ Write-back available
- Tool not found → ⚠️ Write-back not available (non-blocking)

If ⚠️:

```
⚠️  generate_figma_design not available.

/extractify-discover will still analyze your Figma file but won't push
the design system page back to Figma.

To enable write-back, the Remote MCP must be registered AND authenticated:
  1. Confirm .mcp.json contains the `figma` entry (see Step 2)
  2. Complete the OAuth flow (see Step 3a above — `/mcp` → Authenticate)
  3. Fully restart the IDE, then re-run this preflight
```

---

## Step 5 — Auto-install missing optional tools

After collecting all results from Steps 1–4, check whether any optional tools are missing. Optional tools are anything marked ⚠️ — they do not block setup but improve the workflow significantly.

**What can be auto-installed:**

| Missing item | Install command |
|---|---|
| pixelmatch + pngjs | `npm install -D pixelmatch pngjs` |
| @axe-core/playwright | `npm install -D @axe-core/playwright` |
| jq | `brew install jq` (macOS only) |
| Playwright + Chromium | `npm install -D @playwright/test && npx playwright install chromium` |
| ralph-stop hook | Copy + chmod (see below) |

**If one or more optional tools are missing:**

Use the **AskUserQuestion tool** with the following structure:

- **question:** List exactly what's missing, for example:
  ```
  The following optional tools are not installed:
    • pixelmatch + pngjs  — visual diff
    • jq                  — ralph-loop hook

  Install them now?
  ```
- **options:**
  - `"Yes — install everything"` 
  - `"No — I'll install manually"`
  - `"Skip — continue without them"`

- If the user picks **Yes** → run all applicable install commands (see table above), then re-run the affected checks and show an updated status block
- If the user picks **No** or **Skip** → show the original status block with the ⚠️ warnings and the manual install commands shown beneath each item

**ralph-stop hook special case:**

The hook file is not an npm package — it must be copied from the figma-extractify template. Look for the source in these locations in order:

1. A sibling `figma-extractify/` directory relative to the current project
2. Not found → inform the user and skip (do not fail)

If found:
```bash
mkdir -p .claude/hooks
cp <source>/figma-extractify/.claude/hooks/ralph-stop.sh .claude/hooks/ralph-stop.sh
chmod +x .claude/hooks/ralph-stop.sh
```

---

## Output format

After all steps, show the full status block:

```
Pre-flight check
────────────────────────────────────
  ✅  Node.js                  v20.x.x
  ✅  .mcp.json                found (figma + figma-desktop)
  ✅  Figma MCP                Desktop (primary)   ← or "Remote (fallback — Desktop unavailable)"
  ⚠️   Figma Desktop MCP        unavailable         ← only shown when fallback is active
  ✅  Figma Remote MCP         authenticated       ← shown when Remote is up (primary or secondary)
  ✅  generate_figma_design    available           ← only shown for /extractify-discover
  ✅  Playwright + Chromium    ready (v1.x.x)
  ✅  Node dependencies        installed
  ✅  .screenshots/            ready
  ✅  figma-paths.yaml         found
  ✅  Visual diff (pixelmatch)  ready
  ✅  A11y audit (axe-core)    ready
  ✅  Ralph-loop stop hook     ready
  ✅  jq                       installed

────────────────────────────────────
All checks passed. Ready to run /extractify-setup.
```

Use ✅ for pass, ❌ for blocking failure (stop and show fix instructions), ⚠️ for non-blocking warning.

Blocking failures:
- Node.js
- **Figma MCP — both Desktop and Remote unavailable** (either one alone is enough to pass)
- Playwright/Chromium install failures
- Missing dependencies

Non-blocking warnings:
- Figma Desktop MCP unavailable while Remote works (fallback active)
- Figma Remote MCP not authenticated while Desktop works
- generate_figma_design not available
- Ralph-loop stop hook missing
