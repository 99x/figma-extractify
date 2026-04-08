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

# ── 4. Install Claude commands + Cowork skills ────────────────────────────────
# Claude Code and Cowork read commands/skills from ~/.claude/ in your home directory.
# This step copies everything there so /extractify-* commands appear in the UI.
#
# NOTE: Commands live in .claude/commands/ — NOT just skills. Both must be copied.
step "Installing Claude commands and Cowork skills..."
GLOBAL_COMMANDS_DIR="$HOME/.claude/commands"
GLOBAL_SKILLS_DIR="$HOME/.claude/skills"

mkdir -p "$GLOBAL_COMMANDS_DIR"
mkdir -p "$GLOBAL_SKILLS_DIR"

# ── 4a. Commands (.claude/commands/*.md) ──────────────────────────────────────
COMMANDS_SRC="$PROJECT_DIR/.claude/commands"
COMMANDS_FOUND=false

if [ -d "$COMMANDS_SRC" ]; then
  for cmd_file in "$COMMANDS_SRC"/extractify-*.md "$COMMANDS_SRC"/ralph-loop.md; do
    [ -f "$cmd_file" ] || continue
    cmd_name=$(basename "$cmd_file")
    cp "$cmd_file" "$GLOBAL_COMMANDS_DIR/"
    ok "Installed command: $cmd_name → ~/.claude/commands/$cmd_name"
    COMMANDS_FOUND=true
  done
fi

if [ "$COMMANDS_FOUND" = false ]; then
  warn "No extractify-*.md commands found in .claude/commands/"
  warn "Clone the repo with git to get the full command set."
fi

# ── 4b. Skills (.claude/skills/ or skills/) ───────────────────────────────────
SKILL_SOURCES=(
  "$PROJECT_DIR/.claude/skills"
  "$PROJECT_DIR/skills"
)

SKILLS_FOUND=false

for SRC in "${SKILL_SOURCES[@]}"; do
  if [ -d "$SRC" ]; then
    for skill_dir in "$SRC"/extractify-*/; do
      [ -d "$skill_dir" ] || continue
      skill_name=$(basename "$skill_dir")
      cp -r "$skill_dir" "$GLOBAL_SKILLS_DIR/"
      ok "Installed skill: $skill_name → ~/.claude/skills/$skill_name"
      SKILLS_FOUND=true
    done
  fi
done

if [ "$SKILLS_FOUND" = false ]; then
  warn "No extractify-* skills found — skills directory may be missing"
  warn "Clone the repo with git to get the full skill set."
fi

# ── 4c. Ralph Loop stop hook (project-local) ──────────────────────────────────
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

# ── 5. Check Figma paths file ─────────────────────────────────────────────────
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

# ── 6. Done ───────────────────────────────────────────────────────────────────
echo ""
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}${BOLD}  Setup complete. Here's what to do next:${NC}"
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
echo -e "  ${BOLD}1.${NC} Add your Figma URLs → ${YELLOW}_docs/figma-paths.yaml${NC}"
echo -e "  ${BOLD}2.${NC} Open Figma Desktop in Dev Mode (required for MCP)"
echo -e "  ${BOLD}3.${NC} ${BOLD}Restart Claude Code / Cowork${NC} so the new commands appear"
echo -e "  ${BOLD}4.${NC} Start the dev server → ${YELLOW}npm run dev${NC} (from boilerplate/ if using the monorepo)"
echo -e "  ${BOLD}5.${NC} Extract design tokens → ${YELLOW}/extractify-setup${NC}"
echo ""
echo -e "  Full command reference: see ${BLUE}README.md${NC}"
echo ""
