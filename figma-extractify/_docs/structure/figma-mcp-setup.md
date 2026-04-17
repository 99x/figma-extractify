# Figma MCP setup

**Single source of truth for connecting Figma Extractify to Figma.** All `/extractify-*` commands and other docs link here — do not re-explain this material elsewhere.

---

## Which server should I use?

Short answer: you don't have to choose — both are wired up in `.mcp.json`, and `/extractify-*` commands automatically prefer Desktop when reachable and fall back to Remote when it isn't.

In practice:

- **Paid Figma plan (Professional / Organization / Enterprise / Education)** → use **Desktop MCP**. Open Figma Desktop, press **Shift+D** to toggle Dev Mode, and you're done. No login prompts.
- **Free plan — no Dev Mode** → use **Remote MCP** with OAuth. Sign in once through the browser prompt and you're set. Every `/extractify-*` command works identically over Remote because they always pass Figma URLs.
- **Both available** → Desktop wins automatically. You don't lose anything; Remote stays as a safety net.
- **Neither available** → preflight fails. Enable one.

The only thing Remote can't do is read your *current Figma selection without a URL* — but no `/extractify-*` command does that anyway, so it's a non-issue.

The only thing Desktop can't do is `generate_figma_design` (write-back) — used exclusively by `/extractify-discover` to push a design-system summary back into Figma. If you use `/extractify-discover`, enable Remote.

---

## Two servers, one API

Every `/extractify-*` command reads from Figma through an MCP server. Two are supported, both already wired up in `.mcp.json` after `install.sh`. They expose the same read surface (`get_metadata`, `get_design_context`, `get_screenshot`, `get_variable_defs`, Code Connect).

| | **Figma Desktop MCP** | **Figma Remote MCP** |
|---|---|---|
| URL | `http://127.0.0.1:3845/mcp` | `https://mcp.figma.com/mcp` |
| Auth | None (local) | OAuth 2.0 |
| Requirement | Desktop app open + Dev Mode on | IDE logged in via browser prompt |
| Figma plan | Dev Mode needs a **paid plan** (Professional, Organization, Enterprise) or free Education | Works on any plan that can open the file |
| Read tokens / context / screenshots | ✅ | ✅ |
| Code Connect | ✅ | ✅ |
| Read current Figma selection (no URL) | ✅ | ❌ (URL required — `/extractify-*` commands always pass URLs, so not a blocker) |
| `generate_figma_design` write-back | ❌ | ✅ (used by `/extractify-discover` only) |

**Preference order**: Desktop when available → Remote as automatic fallback. Commands fail only if **both** are unreachable.

---

## Enabling Figma Desktop MCP

1. Open the Figma Desktop app and log in.
2. Open any file.
3. Press **Shift+D** (or click the `</>` toggle in the bottom toolbar) to enable Dev Mode.
4. Fully restart Claude Code / Cursor — MCP servers are registered at IDE startup.

Dev Mode requires a paid Figma plan. More info: <https://help.figma.com/hc/en-us/articles/15023124644247>.

If another process is using port 3845:

```bash
lsof -i :3845                 # macOS/Linux
netstat -ano | findstr 3845   # Windows
```

---

## Enabling Figma Remote MCP (OAuth)

Remote uses OAuth 2.0 — no Personal Access Token, no API key. The IDE opens a browser on first use; you log in to Figma and approve. The token is stored by the IDE.

**Claude Code:**

1. In the chat, run `/mcp` — lists configured MCP servers with their auth status.
2. Select `figma` → **Authenticate** (or **Reconnect** if previously failed).
3. Browser opens → log in to Figma and approve.
4. Fully restart Claude Code so live MCP sessions pick up the token.

**Cursor:**

1. `Cmd/Ctrl + Shift + P` → **Cursor: Open MCP Settings**.
2. Find `figma` → click **Authenticate**.
3. Browser opens → log in → approve.
4. Restart Cursor.

**Shortcut (both IDEs):** just trigger any Figma tool call — the first call against an unauthenticated server automatically prompts OAuth.

---

## `.mcp.json` reference

The installer drops this at the project root. Do not edit unless you know what you're doing.

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

**Do NOT add an `X-Figma-Token` header or any other `headers` block to the `figma` entry.** PATs are for the old REST API; the remote MCP rejects them and the header breaks the OAuth handshake.

---

## Troubleshooting

`/extractify-preflight` classifies Remote failures into three buckets — use the classification to pick a fix:

| Symptom | Cause | Fix |
|---|---|---|
| Tool not found in the toolkit | Server not registered in the IDE | Check `.mcp.json` has the `figma` entry → fully restart the IDE |
| `401` / "unauthorized" / "authentication required" | Registered but OAuth not completed | Run the OAuth flow above |
| OAuth succeeded but tools still 401 | IDE didn't pick up new token | Fully quit and reopen Claude Code / Cursor |
| Connection refused / timeout on Desktop | Figma Desktop not running, or Dev Mode off | Open Figma Desktop, enable Dev Mode (Shift+D) |
| Connection refused / timeout on Remote | Network / corporate proxy / firewall blocking `*.figma.com` | Restore network; check VPN rules |
| OAuth browser window didn't open | Popup blocker | Copy the auth URL from the IDE's MCP panel and paste into browser |
| OAuth uses the wrong Figma account | Browser signed in with the wrong account | Open `figma.com` in an incognito window, sign in correctly, re-run the flow |
| `generate_figma_design` not found | Remote not authenticated, or not registered | Complete Remote OAuth; see `/extractify-discover` for scope |

If stuck, run `/extractify-preflight` — it classifies the failure and prints the matching fix block.

---

## How `/extractify-*` commands resolve the server (canonical rule)

Every command follows this resolution at runtime. **This is the canonical candidate list — if IDs change, update this file first, then the command files that probe them.**

1. Try Desktop candidates in order: `user-figma`, `user-Figma Desktop`, `figma-desktop`. Call `get_metadata` on the first one that exists. Tool responds → use Desktop.
2. If Desktop unavailable, try Remote candidates: `plugin-figma-figma`, `figma`. Tool responds → use Remote.
3. Both fail → command stops with the preflight failure block.

Commands pick whichever server works for all read tools (`get_metadata`, `get_design_context`, `get_screenshot`, `get_variable_defs`, Code Connect). The `generate_figma_design` write-back is Remote-only regardless of the resolution.
