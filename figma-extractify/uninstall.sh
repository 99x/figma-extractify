#!/usr/bin/env bash
# Figma Extractify — uninstaller
# Removes QA dev dependencies and cleans up runtime files.
set -euo pipefail

GREEN='\033[0;32m'; YELLOW='\033[1;33m'; BLUE='\033[0;34m'; BOLD='\033[1m'; NC='\033[0m'
ok()   { echo -e "${GREEN}✓${NC} $1"; }
step() { echo -e "\n${BLUE}▶${NC} ${BOLD}$1${NC}"; }
warn() { echo -e "${YELLOW}⚠${NC} $1"; }

echo ""
echo -e "${BOLD}╔══════════════════════════════════════════════╗${NC}"
echo -e "${BOLD}║        Figma Extractify — Uninstaller        ║${NC}"
echo -e "${BOLD}╚══════════════════════════════════════════════╝${NC}"
echo ""

# ── 1. Remove QA dev dependencies ─────────────────────────────────────────────
step "Removing optional QA tools..."
QA_PKGS="pixelmatch pngjs @axe-core/playwright @playwright/test"
for pkg in $QA_PKGS; do
  if npm ls "$pkg" &>/dev/null 2>&1; then
    npm uninstall -D "$pkg" 2>/dev/null && ok "Removed $pkg" || warn "$pkg not installed, skipping"
  else
    warn "$pkg not installed, skipping"
  fi
done

# ── 2. Remove installed Claude commands ───────────────────────────────────────
step "Removing Claude commands..."
PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
GLOBAL_COMMANDS_DIR="$HOME/.claude/commands"
for cmd_file in "$PROJECT_DIR/.claude/commands"/extractify-*.md "$PROJECT_DIR/.claude/commands"/ralph-loop.md; do
  [ -f "$cmd_file" ] || continue
  cmd_name=$(basename "$cmd_file")
  target="$GLOBAL_COMMANDS_DIR/$cmd_name"
  [ -f "$target" ] && rm "$target" && ok "Removed ~/.claude/commands/$cmd_name" || warn "$cmd_name not in ~/.claude/commands/, skipping"
done

# ── 3. Remove installed Cowork skills ────────────────────────────────────────
step "Removing Cowork skills..."
GLOBAL_SKILLS_DIR="$HOME/.claude/skills"
for skill_dir in "$PROJECT_DIR/.claude/skills"/extractify-*/; do
  [ -d "$skill_dir" ] || continue
  skill_name=$(basename "$skill_dir")
  target="$GLOBAL_SKILLS_DIR/$skill_name"
  [ -d "$target" ] && rm -rf "$target" && ok "Removed ~/.claude/skills/$skill_name" || warn "$skill_name not in ~/.claude/skills/, skipping"
done

# ── 4. Remove runtime state files ─────────────────────────────────────────────
step "Cleaning up runtime files..."
[ -f ".ralph-loop-state.json" ] && rm ".ralph-loop-state.json" && ok "Removed .ralph-loop-state.json" || true
[ -d ".screenshots" ]           && rm -rf ".screenshots"        && ok "Removed .screenshots/"         || true
[ -d ".audit" ]                 && rm -rf ".audit"              && ok "Removed .audit/"               || true

# ── 5. Done ───────────────────────────────────────────────────────────────────
echo ""
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}${BOLD}  Done.${NC} The boilerplate source files are untouched."
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
echo -e "  To fully remove the project:  ${YELLOW}rm -rf <project-folder>${NC}"
echo ""
