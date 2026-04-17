#!/usr/bin/env bash
# Figma Extractify — project installer
# Usage: bash install.sh
#
# Run this from inside the figma-extractify/ directory (where this file lives).
# If you cloned the monorepo, that means:
#   cd figma-extractify/figma-extractify
#   bash install.sh
set -euo pipefail

# ── Colors ────────────────────────────────────────────────────────────────────
GREEN='\033[0;32m'; YELLOW='\033[1;33m'; BLUE='\033[0;34m'; RED='\033[0;31m'; BOLD='\033[1m'; NC='\033[0m'
ok()   { echo -e "${GREEN}✓${NC} $1"; }
step() { echo -e "\n${BLUE}▶${NC} ${BOLD}$1${NC}"; }
warn() { echo -e "${YELLOW}⚠${NC} $1"; }
err()  { echo -e "${RED}✗${NC} $1"; }

# ── Resolve app root (where package.json lives) ───────────────────────────────
PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
APP_ROOT=""

if [ -f "package.json" ]; then
  APP_ROOT="$(pwd)"
elif [ -f "../boilerplate/package.json" ]; then
  APP_ROOT="$(cd ../boilerplate && pwd)"
elif [ -f "boilerplate/package.json" ]; then
  APP_ROOT="$(cd boilerplate && pwd)"
fi

# ── Header ────────────────────────────────────────────────────────────────────
echo ""
echo -e "${BOLD}╔══════════════════════════════════════════════╗${NC}"
echo -e "${BOLD}║        Figma Extractify — Installer          ║${NC}"
echo -e "${BOLD}╚══════════════════════════════════════════════╝${NC}"
echo ""

# ── 1. Check Node.js ──────────────────────────────────────────────────────────
step "Checking Node.js..."
if ! command -v node &>/dev/null; then
  err "Node.js not found. Install v18.17+ from https://nodejs.org"
  exit 1
fi
NODE_VER=$(node --version)
NODE_MAJOR=$(echo "$NODE_VER" | cut -d. -f1 | tr -d 'v')
if [ "$NODE_MAJOR" -lt 18 ]; then
  err "Node.js $NODE_VER is too old. v18.17+ required."
  exit 1
fi
ok "Node.js $NODE_VER"

# ── 2. Install dependencies ───────────────────────────────────────────────────
# The package.json lives in the boilerplate/ directory (monorepo layout).
# This script lives in figma-extractify/ — one level down from the repo root.
# We detect where package.json is and install from there.
step "Installing dependencies..."
if [ -n "$APP_ROOT" ]; then
  if [ "$APP_ROOT" = "$(pwd)" ]; then
    npm install
    ok "Dependencies installed"
  else
    warn "No package.json in this directory — monorepo layout detected."
    warn "Installing from $APP_ROOT ..."
    (cd "$APP_ROOT" && npm install)
    ok "Dependencies installed in $(basename "$APP_ROOT")/"
  fi
elif [ -f "../boilerplate/package.json" ]; then
  warn "No package.json in this directory — monorepo layout detected."
  warn "Installing from ../boilerplate/ ..."
  (cd ../boilerplate && npm install)
  ok "Dependencies installed in boilerplate/"
else
  warn "No package.json found anywhere nearby — skipping npm install."
  warn "Run 'npm install' manually from your project root (where package.json lives)."
fi

# ── 3. Optional QA tools ──────────────────────────────────────────────────────
echo ""
echo -e "  ${BOLD}Optional QA tools${NC} power the visual diff and accessibility audit:"
echo -e "  ${YELLOW}pixelmatch${NC} · ${YELLOW}pngjs${NC} · ${YELLOW}@axe-core/playwright${NC} · ${YELLOW}Playwright Chromium${NC}"
echo ""
read -r -p "  Install QA tools? [y/N] " INSTALL_QA
if [[ "$INSTALL_QA" =~ ^[Yy]$ ]]; then
  step "Installing QA tools..."
  # Install into the same location as the main dependencies
  if [ -n "$APP_ROOT" ]; then
    if [ "$APP_ROOT" = "$(pwd)" ]; then
      npm install -D pixelmatch pngjs @axe-core/playwright @playwright/test
      npx playwright install chromium
    else
      (cd "$APP_ROOT" && npm install -D pixelmatch pngjs @axe-core/playwright @playwright/test && npx playwright install chromium)
    fi
  fi
  ok "QA tools installed"
else
  warn "Skipped — visual diff and a11y audit won't be available (run /extractify-preflight to re-check later)"
fi

# ── 4. Install Claude commands + figma-use skill (project-local) ──────────────
# Claude Code reads commands/skills from <project>/.claude/{commands,skills}/.
# Installing project-local (instead of ~/.claude/) scopes them to THIS project,
# so /extractify-* commands don't appear in unrelated projects where _docs/
# doesn't exist and the commands would fail.
step "Installing Claude commands and figma-use skill..."

if [ -z "$APP_ROOT" ]; then
  err "No project root detected (no package.json found nearby)."
  err "Commands and skills install into <project>/.claude/ — a project is required."
  err "Run install.sh from inside your project, or alongside the boilerplate/ folder."
  exit 1
fi

LOCAL_COMMANDS_DIR="$APP_ROOT/.claude/commands"
LOCAL_SKILLS_DIR="$APP_ROOT/.claude/skills"

mkdir -p "$LOCAL_COMMANDS_DIR"
mkdir -p "$LOCAL_SKILLS_DIR"

# ── 4a. Commands (.claude/commands/*.md) ──────────────────────────────────────
COMMANDS_SRC="$PROJECT_DIR/.claude/commands"
COMMANDS_FOUND=false

if [ -d "$COMMANDS_SRC" ]; then
  for cmd_file in "$COMMANDS_SRC"/extractify-*.md "$COMMANDS_SRC"/ralph-loop.md; do
    [ -f "$cmd_file" ] || continue
    cmd_name=$(basename "$cmd_file")
    cp "$cmd_file" "$LOCAL_COMMANDS_DIR/"
    ok "Installed command: $cmd_name → .claude/commands/$cmd_name"
    COMMANDS_FOUND=true
  done
fi

if [ "$COMMANDS_FOUND" = false ]; then
  warn "No extractify-*.md commands found in .claude/commands/"
  warn "Clone the repo with git to get the full command set."
fi

# ── 4b. Skills (.claude/skills/) ──────────────────────────────────────────────
# Only figma-use is installed as a skill — it's the mandatory prerequisite for
# every use_figma tool call (see _docs/start-here.md). The /extractify-* workflows
# are pure slash commands; they don't need skill wrappers. The evals/ directory
# is intentionally skipped — it holds internal eval data, not a skill.
SKILL_SOURCES=(
  "$PROJECT_DIR/.claude/skills"
  "$PROJECT_DIR/skills"
)

SKILLS_FOUND=false

for SRC in "${SKILL_SOURCES[@]}"; do
  if [ -d "$SRC/figma-use" ]; then
    cp -r "$SRC/figma-use" "$LOCAL_SKILLS_DIR/"
    ok "Installed skill: figma-use → .claude/skills/figma-use"
    SKILLS_FOUND=true
    break
  fi
done

if [ "$SKILLS_FOUND" = false ]; then
  warn "figma-use skill not found — use_figma calls will fail without it"
  warn "Clone the repo with git to get the full skill set."
fi

# ── 4c. Migrate legacy global installs (one-shot cleanup) ─────────────────────
# Earlier versions of this installer copied commands/skills into ~/.claude/,
# which made /extractify-* commands appear in every project on the user's
# machine — even ones without _docs/ where the commands can't run. Detect and
# remove those orphans so users upgrading don't end up with two copies.
LEGACY_COMMANDS_DIR="$HOME/.claude/commands"
LEGACY_SKILLS_DIR="$HOME/.claude/skills"
LEGACY_FOUND=false

if [ -d "$LEGACY_COMMANDS_DIR" ]; then
  for legacy_cmd in "$LEGACY_COMMANDS_DIR"/extractify-*.md "$LEGACY_COMMANDS_DIR/ralph-loop.md"; do
    [ -f "$legacy_cmd" ] || continue
    if [ "$LEGACY_FOUND" = false ]; then
      step "Removing legacy global install (now project-local)..."
      LEGACY_FOUND=true
    fi
    rm "$legacy_cmd"
    ok "Removed ~/.claude/commands/$(basename "$legacy_cmd")"
  done
fi

if [ -d "$LEGACY_SKILLS_DIR" ]; then
  for legacy_skill in "$LEGACY_SKILLS_DIR"/extractify-*/ "$LEGACY_SKILLS_DIR/figma-use/"; do
    [ -d "$legacy_skill" ] || continue
    if [ "$LEGACY_FOUND" = false ]; then
      step "Removing legacy global install (now project-local)..."
      LEGACY_FOUND=true
    fi
    rm -rf "$legacy_skill"
    ok "Removed ~/.claude/skills/$(basename "$legacy_skill")"
  done
fi

# ── 4d. Ralph Loop stop hook (project-local) ──────────────────────────────────
step "Installing Ralph Loop stop hook..."
HOOK_SRC="$PROJECT_DIR/.claude/hooks/ralph-stop.sh"

if [ ! -f "$HOOK_SRC" ]; then
  warn "Hook source not found at .claude/hooks/ralph-stop.sh — skipping."
elif [ -z "$APP_ROOT" ]; then
  warn "Could not detect app root (package.json not found)."
  warn "Copy hook manually to your project: .claude/hooks/ralph-stop.sh"
else
  HOOK_DEST_DIR="$APP_ROOT/.claude/hooks"
  mkdir -p "$HOOK_DEST_DIR"
  cp "$HOOK_SRC" "$HOOK_DEST_DIR/ralph-stop.sh"
  chmod +x "$HOOK_DEST_DIR/ralph-stop.sh"
  ok "Installed Ralph stop hook: $HOOK_DEST_DIR/ralph-stop.sh"
fi

if command -v jq &>/dev/null; then
  ok "jq found (required by ralph-stop.sh)"
else
  warn "jq not found — /ralph-loop stop hook requires jq"
  warn "Install with: brew install jq"
fi

# ── 5. Copy _docs/ contracts to the app root ─────────────────────────────────
# The /extractify-setup wizard reads contract files from _docs/front-end/
# (01-colors.md, 02-typography.md, etc.) and config from _docs/figma-paths.yaml.
# Without these, the wizard cannot run any extraction step.
step "Installing documentation contracts..."
DOCS_SRC="$PROJECT_DIR/_docs"

if [ -d "$DOCS_SRC" ] && [ -n "$APP_ROOT" ]; then
  if [ -d "$APP_ROOT/_docs" ]; then
    # Merge without overwriting — don't clobber user edits
    # cp -n (no-clobber) works on macOS and GNU coreutils; fallback to plain cp
    if cp -rn "$DOCS_SRC"/* "$APP_ROOT/_docs/" 2>/dev/null; then
      ok "Merged _docs/ → $APP_ROOT/_docs/ (existing files preserved)"
    else
      # Fallback: copy everything (may overwrite)
      cp -r "$DOCS_SRC"/* "$APP_ROOT/_docs/"
      ok "Merged _docs/ → $APP_ROOT/_docs/"
    fi
  else
    cp -r "$DOCS_SRC" "$APP_ROOT/_docs"
    ok "Installed _docs/ → $APP_ROOT/_docs/"
  fi
elif [ -d "$DOCS_SRC" ] && [ -z "$APP_ROOT" ]; then
  warn "_docs/ found but no app root detected — copy _docs/ to your project manually"
else
  warn "_docs/ not found in $PROJECT_DIR — contract files may be missing"
  warn "Clone the repo with git to get the full documentation set."
fi

# ── 6. Copy project config files to app root ──────────────────────────────────
# These files configure the IDE, MCP servers, and agent behaviour.
# Without them, the agent loses project context after figma-extractify/ is deleted.
step "Installing project config files..."

if [ -n "$APP_ROOT" ]; then
  # ── 6a. CLAUDE.md (project-level agent config) ─────────────────────────────
  if [ -f "$PROJECT_DIR/CLAUDE.md" ] && [ ! -f "$APP_ROOT/CLAUDE.md" ]; then
    cp "$PROJECT_DIR/CLAUDE.md" "$APP_ROOT/CLAUDE.md"
    ok "Installed CLAUDE.md"
  elif [ -f "$PROJECT_DIR/CLAUDE.md" ]; then
    ok "CLAUDE.md already exists — skipped"
  fi

  # ── 6b. .mcp.json (Figma MCP server definitions) ──────────────────────────
  if [ -f "$PROJECT_DIR/.mcp.json" ] && [ ! -f "$APP_ROOT/.mcp.json" ]; then
    cp "$PROJECT_DIR/.mcp.json" "$APP_ROOT/.mcp.json"
    ok "Installed .mcp.json (Figma MCP servers)"
  elif [ -f "$PROJECT_DIR/.mcp.json" ] && [ -f "$APP_ROOT/.mcp.json" ]; then
    warn ".mcp.json already exists — review $PROJECT_DIR/.mcp.json and merge manually if needed"
  fi

  # ── 6c. .claude/settings.json (permissions + hooks) ────────────────────────
  if [ -f "$PROJECT_DIR/.claude/settings.json" ] && [ ! -f "$APP_ROOT/.claude/settings.json" ]; then
    mkdir -p "$APP_ROOT/.claude"
    cp "$PROJECT_DIR/.claude/settings.json" "$APP_ROOT/.claude/settings.json"
    ok "Installed .claude/settings.json"
  elif [ -f "$PROJECT_DIR/.claude/settings.json" ]; then
    ok ".claude/settings.json already exists — skipped"
  fi

  # Note: settings.local.json is intentionally NOT copied. It's a per-machine
  # file that accumulates permission grants with absolute paths from the user
  # who created it. Each installation must generate its own — Claude Code does
  # this automatically as the user approves tools. A reference copy of useful
  # MCP permissions lives at figma-extractify/.claude/settings.local.json.example
  # if you want to seed one manually.

  # ── 6d. scripts/ (visual-diff + a11y-audit) ────────────────────────────────
  if [ -d "$PROJECT_DIR/scripts" ]; then
    mkdir -p "$APP_ROOT/scripts"
    for script_file in "$PROJECT_DIR/scripts"/*; do
      [ -f "$script_file" ] || continue
      script_name=$(basename "$script_file")
      if [ ! -f "$APP_ROOT/scripts/$script_name" ]; then
        cp "$script_file" "$APP_ROOT/scripts/$script_name"
        ok "Installed scripts/$script_name"
      else
        ok "scripts/$script_name already exists — skipped"
      fi
    done
  fi

  # ── 6e. IDE rules (Cursor + Windsurf) ──────────────────────────────────────
  if [ -d "$PROJECT_DIR/.cursor/rules" ]; then
    mkdir -p "$APP_ROOT/.cursor/rules"
    for rule_file in "$PROJECT_DIR/.cursor/rules"/*; do
      [ -f "$rule_file" ] || continue
      rule_name=$(basename "$rule_file")
      if [ ! -f "$APP_ROOT/.cursor/rules/$rule_name" ]; then
        cp "$rule_file" "$APP_ROOT/.cursor/rules/$rule_name"
        ok "Installed .cursor/rules/$rule_name"
      else
        ok ".cursor/rules/$rule_name already exists — skipped"
      fi
    done
  fi

  if [ -f "$PROJECT_DIR/.windsurfrules" ] && [ ! -f "$APP_ROOT/.windsurfrules" ]; then
    cp "$PROJECT_DIR/.windsurfrules" "$APP_ROOT/.windsurfrules"
    ok "Installed .windsurfrules"
  elif [ -f "$PROJECT_DIR/.windsurfrules" ]; then
    ok ".windsurfrules already exists — skipped"
  fi
else
  warn "No app root detected — copy config files manually (CLAUDE.md, .mcp.json, scripts/, .cursor/rules/)"
fi

# ── 7. Check Figma paths file ─────────────────────────────────────────────────
# Look for figma-paths.yaml in APP_ROOT/_docs/ first (canonical location),
# then fall back to the root of APP_ROOT (legacy placement).
echo ""
YAML_PATH=""
if [ -n "$APP_ROOT" ] && [ -f "$APP_ROOT/_docs/figma-paths.yaml" ]; then
  YAML_PATH="$APP_ROOT/_docs/figma-paths.yaml"
elif [ -n "$APP_ROOT" ] && [ -f "$APP_ROOT/figma-paths.yaml" ]; then
  YAML_PATH="$APP_ROOT/figma-paths.yaml"
elif [ -f "_docs/figma-paths.yaml" ]; then
  YAML_PATH="_docs/figma-paths.yaml"
fi

if [ -n "$YAML_PATH" ]; then
  COLORS_URL=$(grep -A1 "colors:" "$YAML_PATH" | tail -1 | tr -d ' ' | sed 's/colors://')
  if [[ -z "$COLORS_URL" || "$COLORS_URL" == "~" ]]; then
    warn "Figma URLs not set yet — edit _docs/figma-paths.yaml before running /extractify-setup"
  else
    ok "figma-paths.yaml already has URLs"
  fi
fi

# ── 8. Clean up figma-extractify/ folder ──────────────────────────────────────
# All files have been copied to the project — the source folder is no longer needed.
echo ""
echo -e "  ${GREEN}All files have been copied to your project.${NC}"
echo -e "  The ${BOLD}figma-extractify/${NC} folder is no longer needed and can be safely deleted."
echo ""
read -r -p "  Delete figma-extractify/ folder now? [y/N] " DELETE_FOLDER
if [[ "$DELETE_FOLDER" =~ ^[Yy]$ ]]; then
  if [ -d "$PROJECT_DIR" ] && [ "$PROJECT_DIR" != "$APP_ROOT" ]; then
    rm -rf "$PROJECT_DIR"
    ok "Deleted $PROJECT_DIR"
  else
    warn "Could not determine a safe path to delete — remove figma-extractify/ manually"
  fi
else
  warn "Skipped — you can delete figma-extractify/ manually whenever you're ready"
fi

# ── 9. Done ───────────────────────────────────────────────────────────────────
echo ""
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}${BOLD}  Setup complete. Here's what to do next:${NC}"
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
echo -e "  ${BOLD}1.${NC} Add your Figma URLs → ${YELLOW}_docs/figma-paths.yaml${NC}"
echo -e "  ${BOLD}2.${NC} Connect to Figma — either:"
echo -e "       • Open Figma Desktop in Dev Mode (preferred — runs at 127.0.0.1:3845)"
echo -e "       • Or approve the Remote MCP OAuth prompt in your IDE (fallback — mcp.figma.com)"
echo -e "  ${BOLD}3.${NC} ${BOLD}Restart Claude Code${NC} so the new commands appear"
echo -e "  ${BOLD}4.${NC} Start the dev server → ${YELLOW}npm run dev${NC} (from boilerplate/ if using the monorepo)"
echo -e "  ${BOLD}5.${NC} Extract design tokens → ${YELLOW}/extractify-setup${NC}"
echo ""
echo -e "  Full command reference: see ${BLUE}README.md${NC}"
echo ""
