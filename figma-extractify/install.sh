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
if [ -f "package.json" ]; then
  npm install
  ok "Dependencies installed"
elif [ -f "../boilerplate/package.json" ]; then
  warn "No package.json in this directory — monorepo layout detected."
  warn "Installing from ../boilerplate/ ..."
  (cd ../boilerplate && npm install)
  ok "Dependencies installed in boilerplate/"
elif [ -f "boilerplate/package.json" ]; then
  warn "No package.json in this directory — installing from boilerplate/ ..."
  (cd boilerplate && npm install)
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
  if [ -f "package.json" ]; then
    npm install -D pixelmatch pngjs @axe-core/playwright @playwright/test
    npx playwright install chromium
  elif [ -f "../boilerplate/package.json" ]; then
    (cd ../boilerplate && npm install -D pixelmatch pngjs @axe-core/playwright @playwright/test && npx playwright install chromium)
  elif [ -f "boilerplate/package.json" ]; then
    (cd boilerplate && npm install -D pixelmatch pngjs @axe-core/playwright @playwright/test && npx playwright install chromium)
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
PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
GLOBAL_COMMANDS_DIR="$HOME/.claude/commands"
GLOBAL_SKILLS_DIR="$HOME/.claude/skills"

mkdir -p "$GLOBAL_COMMANDS_DIR"
mkdir -p "$GLOBAL_SKILLS_DIR"

# ── 4a. Commands (.claude/commands/*.md) ──────────────────────────────────────
COMMANDS_SRC="$PROJECT_DIR/.claude/commands"
COMMANDS_FOUND=false

if [ -d "$COMMANDS_SRC" ]; then
  for cmd_file in "$COMMANDS_SRC"/extractify-*.md; do
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

# ── 5. Check Figma paths file ─────────────────────────────────────────────────
echo ""
if [ -f "_docs/figma-paths.yaml" ]; then
  COLORS_URL=$(grep -A1 "colors:" _docs/figma-paths.yaml | tail -1 | tr -d ' ' | sed 's/colors://')
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
