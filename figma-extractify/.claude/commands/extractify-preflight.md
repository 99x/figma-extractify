# Pre-flight check

Run all environment checks and report status. Use this before running `/extractify-setup` or `/extractify-new-component`.

> **Note:** The visual review loop (Ralph Loop) requires **Figma Desktop MCP** and **Playwright + Chromium**. Both are checked below.

---

## How to run

The entire pre-flight is **3 steps**:

1. **One bash script** — checks all system dependencies
2. **Two Figma MCP calls** — checks Desktop MCP and Remote MCP separately
3. Claude reads all output and builds the status block

---

## Step 1 — Run the system check script (single bash command)

```bash
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

# 4. Node dependencies
[ -d "node_modules" ] && echo "DEPS=ok" || echo "DEPS=missing"

# 5. .screenshots/ directory (auto-create if missing)
if [ -d ".screenshots" ]; then echo "SCREENSHOTS=ok"
else mkdir -p .screenshots && echo "SCREENSHOTS=created"; fi

# 6. figma-paths.yaml
[ -f "_docs/figma-paths.yaml" ] && echo "YAML=ok" || echo "YAML=missing"

# 7. pixelmatch + pngjs (visual diff)
PIXELMATCH=$(node -e "try{require.resolve('pixelmatch');console.log('ok')}catch(e){console.log('missing')}" 2>/dev/null)
PNGJS=$(node -e "try{require.resolve('pngjs');console.log('ok')}catch(e){console.log('missing')}" 2>/dev/null)
if [ "$PIXELMATCH" = "ok" ] && [ "$PNGJS" = "ok" ]; then
  echo "VISUAL_DIFF=ok"
else
  echo "VISUAL_DIFF=missing (run: npm install -D pixelmatch pngjs)"
fi

# 8. @axe-core/playwright (a11y audit)
AXE=$(node -e "try{require.resolve('@axe-core/playwright');console.log('ok')}catch(e){console.log('missing')}" 2>/dev/null)
if [ "$AXE" = "ok" ]; then
  echo "A11Y_AUDIT=ok"
else
  echo "A11Y_AUDIT=missing (run: npm install -D @axe-core/playwright)"
fi

# 9. Ralph-loop stop hook
if [ -f ".claude/hooks/ralph-stop.sh" ] && [ -x ".claude/hooks/ralph-stop.sh" ]; then
  echo "RALPH_LOOP=ok"
else
  echo "RALPH_LOOP=missing (.claude/hooks/ralph-stop.sh not found or not executable)"
fi
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
| `YAML=ok` | ✅ |
| `VISUAL_DIFF=missing` | ⚠️ Run `npm install -D pixelmatch pngjs` — visual diff falls back to AI-only |
| `VISUAL_DIFF=ok` | ✅ |
| `A11Y_AUDIT=missing` | ⚠️ Run `npm install -D @axe-core/playwright` — a11y audit will be skipped |
| `A11Y_AUDIT=ok` | ✅ |
| `RALPH_LOOP=missing` | ⚠️ Stop hook missing — `/ralph-loop` won't enforce iteration limits |
| `RALPH_LOOP=ok` | ✅ |

---

## Step 2 — Check Figma Desktop MCP (required for extraction)

The Desktop MCP runs locally via Figma Desktop. It gives access to Dev Mode, variables, and component inspection. **No API key required** — it uses your logged-in Figma Desktop session.

Attempt to call `get_metadata` using the `figma-desktop` server.

- Tool responds (even with an error) → ✅ Desktop MCP available
- Tool not found / connection refused → ❌ Figma Desktop not running or not configured

If ❌:

```
❌ Figma Desktop MCP not reachable.

Two things must be true for this to work:
  1. Figma Desktop is open and you are logged in
  2. Dev Mode is enabled (bottom toolbar → toggle Dev Mode, or Shift+D)

The Desktop MCP runs at http://127.0.0.1:3845/mcp automatically when
Figma Desktop is open. No API key needed.

Steps to fix:
  1. Open Figma Desktop
  2. Open any file
  3. Enable Dev Mode (Shift+D)
  4. Run /extractify-preflight again
```

---

## Step 3 — Check Figma Remote MCP (required for write-back and OAuth features)

The Remote MCP runs at https://mcp.figma.com/mcp and uses **OAuth** — Claude Code handles the authentication handshake automatically on first use. No API key or token needed in the config.

Attempt to call `get_metadata` using the `figma` (remote) server.

- Tool responds (even with an error) → ✅ Remote MCP connected
- Tool not found / 401 / auth error → ❌ Not authenticated

If ❌:

```
❌ Figma Remote MCP not authenticated.

This project uses OAuth — no API key required. Claude Code handles
the login automatically on first connection.

Steps to fix:
  1. Make sure .mcp.json is present and contains:

     {
       "mcpServers": {
         "figma": {
           "type": "http",
           "url": "https://mcp.figma.com/mcp"
         }
       }
     }

  2. Restart Claude Code — it will open a browser prompt to log in to Figma
  3. Approve the OAuth connection
  4. Run /extractify-preflight again

⚠️  Do NOT add an X-Figma-Token header — it will break the OAuth flow.
    If you need token-based auth (e.g. CI), use a Personal Access Token:
    https://help.figma.com/hc/en-us/articles/8085703771159
    and add:  "headers": { "X-Figma-Token": "YOUR_PAT_HERE" }
```

---

## Step 4 — Check Figma write-back (optional — only for /extractify-discover)

`generate_figma_design` is only available on the **remote MCP**, not the desktop one.

Attempt to call `generate_figma_design` with a minimal test payload.

- Tool exists (even if it errors) → ✅ Write-back available
- Tool not found → ⚠️ Write-back not available (non-blocking)

If ⚠️:

```
⚠️  generate_figma_design not available.

/extractify-discover will still analyze your Figma file but won't push
the design system page back to Figma.

To enable write-back, ensure the remote Figma MCP is connected (Step 3 above).
```

---

## Output format

After all steps, show the full status block:

```
Pre-flight check
────────────────────────────────────
  ✅  Node.js                  v20.x.x
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

────────────────────────────────────
All checks passed. Ready to run /extractify-setup.
```

Use ✅ for pass, ❌ for blocking failure (stop and show fix instructions), ⚠️ for non-blocking warning.
