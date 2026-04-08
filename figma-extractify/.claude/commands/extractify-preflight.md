# Pre-flight check

Run all environment checks and report status. Use this before running `/extractify-setup` or `/extractify-new-component`.

> **Note:** The visual review loop (Ralph Loop) requires **Figma Desktop MCP** and **Playwright + Chromium**. Both are checked below.

---

## How to run

The entire pre-flight is **6 steps**:

1. **One bash script** — checks all system dependencies
2. **Check `.mcp.json`** — verify MCP config exists, auto-create if missing
3. **Check Figma Desktop MCP** — verify Dev Mode connection
4. **Check Figma Remote MCP** — verify OAuth connection (non-blocking)
5. **Check write-back** — verify `generate_figma_design` is available (non-blocking)
6. **Auto-install** — prompt user to install missing optional tools

---

## Step 1 — Run the system check script (single bash command)

```bash
# Detect environment: Cowork runs in a Linux sandbox, Claude Code runs locally on macOS
IS_LOCAL=false
[ "$(uname)" = "Darwin" ] && IS_LOCAL=true

if $IS_LOCAL; then
  # Local macOS — try nvm, Homebrew, and system paths
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
  CHROMIUM=$(ls "$HOME/Library/Caches/ms-playwright" 2>/dev/null | grep -i "^chromium" || echo "")
  if [ -z "$CHROMIUM" ]; then
    echo "CHROMIUM=installing"
    npx playwright install chromium 2>/dev/null
    CHROMIUM=$(ls "$HOME/Library/Caches/ms-playwright" 2>/dev/null | grep -i "^chromium" || echo "")
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
  else echo "JQ=missing (run: brew install jq)"; fi

else
  # Cowork sandbox (Linux) — local system checks are not applicable
  echo "NODE=sandbox"
  echo "PLAYWRIGHT=sandbox"
  echo "CHROMIUM=sandbox"
  echo "RALPH_LOOP=sandbox"
  echo "JQ=sandbox"
fi

# 4. Node dependencies (meaningful in both environments — files are mounted)
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
| `NODE=sandbox` | ✅ N/A — running in Cowork sandbox; check Node locally with `node --version` |
| `PLAYWRIGHT=install_failed` | ❌ Run `npm install -D @playwright/test` manually |
| `PLAYWRIGHT=*` (any version) | ✅ |
| `PLAYWRIGHT=sandbox` | ✅ N/A — Cowork sandbox; Playwright runs locally |
| `CHROMIUM=install_failed` | ❌ Run `npx playwright install chromium` manually |
| `CHROMIUM=ok` or `installed` | ✅ |
| `CHROMIUM=sandbox` | ✅ N/A — Cowork sandbox |
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
| `RALPH_LOOP=ok` or `sandbox` | ✅ |
| `JQ=missing` | ⚠️ Install jq (`brew install jq`) |
| `JQ=ok` or `sandbox` | ✅ |

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

## Step 3 — Check Figma Desktop MCP (required for extraction)

The Desktop MCP runs locally via Figma Desktop. It gives access to Dev Mode, variables, and component inspection. **No API key required** — it uses your logged-in Figma Desktop session.

First resolve the Desktop server id from the MCP servers available in the current environment.

Try these candidates in order and use the first one that exists:

- `user-figma`
- `user-Figma Desktop`
- `figma-desktop`

Then attempt to call `get_metadata` using that resolved Desktop server id.

- Tool responds (even with an error) → ✅ Desktop MCP available
- Tool not found / connection refused → ❌ Figma Desktop not running or not configured

If ❌, stop entirely and output:

```
❌ Figma Desktop MCP not reachable.

This usually means one of three things:

  1. Figma Desktop is not running
     → Open Figma Desktop and log in to your account.

  2. Dev Mode is not enabled
     → Open any Figma file, then press Shift+D (or click the
       </> toggle in the bottom toolbar) to enable Dev Mode.

  3. Dev Mode is not available on your plan
     → Dev Mode requires a paid Figma plan (Professional, Organization,
       or Enterprise). The free Starter plan does not include Dev Mode.
     → Education plans include Dev Mode for free.
     → Check your plan: Figma → Main menu → Help → Account settings
     → More info: https://help.figma.com/hc/en-us/articles/15023124644247

The Desktop MCP runs automatically at http://127.0.0.1:3845/mcp when
Figma Desktop is open with Dev Mode active. No API key is needed.

Steps to fix:
  1. Make sure Figma Desktop is open and you are logged in
  2. Open any Figma file
  3. Enable Dev Mode (Shift+D)
  4. Restart Claude Code / Cursor (MCP connections are established at startup)
  5. Run /extractify-preflight again

Still not working? Check if another process is using port 3845:
  lsof -i :3845       (macOS/Linux)
  netstat -ano | findstr 3845   (Windows)
```

---

## Step 4 — Check Figma Remote MCP (required for discover and write-back)

The Remote MCP runs at https://mcp.figma.com/mcp and uses **OAuth** — Claude Code handles the authentication handshake automatically on first use. No API key or token needed in the config.

First resolve the Remote server id from the MCP servers available in the current environment.

Try these candidates in order and use the first one that exists:

- `plugin-figma-figma`
- `figma`

Then attempt to call `get_metadata` using that resolved Remote server id.

- Tool responds (even with an error) → ✅ Remote MCP connected
- Tool not found / 401 / auth error → ⚠️ Not authenticated (non-blocking for `/extractify-setup`)

If ⚠️:

```
⚠️ Figma Remote MCP not authenticated.

This is non-blocking — /extractify-setup only needs the Desktop MCP.
Remote MCP is required for /extractify-discover write-back flows.

Authentication uses OAuth (no API key needed). Claude Code opens a
browser window to log in to Figma on first connection.

Steps to fix:
  1. Make sure .mcp.json contains a remote Figma entry:

     "figma": {
       "type": "http",
       "url": "https://mcp.figma.com/mcp"
     }

  2. Restart Claude Code / Cursor — it will open a browser prompt
  3. Log in to Figma and approve the OAuth connection
  4. Run /extractify-preflight again

⚠️  Do NOT add an X-Figma-Token header — it will break the OAuth flow.
    Token-based auth (for CI) uses a Personal Access Token instead:
    https://help.figma.com/hc/en-us/articles/8085703771159
```

---

## Step 5 — Check Figma write-back (optional — only for /extractify-discover)

`generate_figma_design` is only available on the **remote MCP**, not the desktop one.

Use the same resolved Remote server id from Step 4, then attempt to call `generate_figma_design` with a minimal test payload.

- Tool exists (even if it errors) → ✅ Write-back available
- Tool not found → ⚠️ Write-back not available (non-blocking)

If ⚠️:

```
⚠️  generate_figma_design not available.

/extractify-discover will still analyze your Figma file but won't push
the design system page back to Figma.

To enable write-back, ensure the remote Figma MCP is connected (Step 4 above).
```

---

## Step 6 — Auto-install missing optional tools

After collecting all results from Steps 1–5, check whether any optional tools are missing. Optional tools are anything marked ⚠️ — they do not block setup but improve the workflow significantly.

**What can be auto-installed:**

| Missing item | Install command |
|---|---|
| pixelmatch + pngjs | `npm install -D pixelmatch pngjs` |
| @axe-core/playwright | `npm install -D @axe-core/playwright` |
| jq | `brew install jq` (macOS only) |
| Playwright + Chromium | `npm install -D @playwright/test && npx playwright install chromium` |
| ralph-stop hook | Copy + chmod (see below) |

**If one or more optional tools are missing AND the environment is local (not sandbox):**

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

1. `~/.claude/skills/extractify-setup/` (installed globally)
2. A sibling `figma-extractify/` directory relative to the current project
3. Not found → inform the user and skip (do not fail)

If found:
```bash
mkdir -p .claude/hooks
cp <source>/figma-extractify/.claude/hooks/ralph-stop.sh .claude/hooks/ralph-stop.sh
chmod +x .claude/hooks/ralph-stop.sh
```

**In sandbox (Cowork) environment:** skip this entire step — installs must be done locally by the user.

---

## Output format

After all steps, show the full status block:

```
Pre-flight check
────────────────────────────────────
  ✅  Node.js                  v20.x.x
  ✅  .mcp.json                found (figma + figma-desktop)
  ✅  Figma Desktop MCP        connected (Dev Mode active)
  ✅  Figma Remote MCP         authenticated
  ✅  generate_figma_design    available       ← only shown for /extractify-discover
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
- Figma Desktop MCP
- Playwright/Chromium install failures
- Missing dependencies

Non-blocking warnings:
- Figma Remote MCP not authenticated
- generate_figma_design not available
- Ralph-loop stop hook missing
