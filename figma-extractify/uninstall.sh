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

# ── Resolve project root (where commands/skills were installed) ───────────────
# Mirror the install.sh logic: detect APP_ROOT from package.json location.
PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
APP_ROOT=""
if [ -f "package.json" ]; then
  APP_ROOT="$(pwd)"
elif [ -f "../boilerplate/package.json" ]; then
  APP_ROOT="$(cd ../boilerplate && pwd)"
elif [ -f "boilerplate/package.json" ]; then
  APP_ROOT="$(cd boilerplate && pwd)"
fi

# ── 2. Remove installed Claude commands (project-local) ───────────────────────
step "Removing Claude commands..."
if [ -z "$APP_ROOT" ]; then
  warn "No project root detected — skipping command removal."
  warn "If commands live elsewhere, delete <project>/.claude/commands/extractify-*.md manually."
else
  LOCAL_COMMANDS_DIR="$APP_ROOT/.claude/commands"
  for cmd_file in "$PROJECT_DIR/.claude/commands"/extractify-*.md "$PROJECT_DIR/.claude/commands"/ralph-loop.md; do
    [ -f "$cmd_file" ] || continue
    cmd_name=$(basename "$cmd_file")
    target="$LOCAL_COMMANDS_DIR/$cmd_name"
    [ -f "$target" ] && rm "$target" && ok "Removed .claude/commands/$cmd_name" || warn "$cmd_name not in $LOCAL_COMMANDS_DIR, skipping"
  done
fi

# ── 3. Remove installed skills (project-local) ────────────────────────────────
# Only figma-use is installed by the current installer. Older versions also
# installed extractify-* skill trampolines — those are handled by the legacy
# cleanup in step 3b below.
step "Removing installed skills..."
if [ -z "$APP_ROOT" ]; then
  warn "No project root detected — skipping skill removal."
  warn "If skills live elsewhere, delete <project>/.claude/skills/figma-use/ manually."
else
  LOCAL_SKILLS_DIR="$APP_ROOT/.claude/skills"
  target="$LOCAL_SKILLS_DIR/figma-use"
  if [ -d "$target" ]; then
    rm -rf "$target"
    ok "Removed .claude/skills/figma-use"
  else
    warn "figma-use not in $LOCAL_SKILLS_DIR, skipping"
  fi
  # Also clean up any leftover extractify-* skill trampolines from older installs
  for stale_skill in "$LOCAL_SKILLS_DIR"/extractify-*/; do
    [ -d "$stale_skill" ] || continue
    rm -rf "$stale_skill"
    ok "Removed leftover .claude/skills/$(basename "$stale_skill") (from earlier installer version)"
  done
fi

# ── 3b. Remove any legacy global installs (from older installer versions) ─────
# Earlier installer versions placed commands/skills in ~/.claude/. Clean those
# up too so uninstall fully removes Figma Extractify regardless of when it was
# installed. Runs unconditionally — legacy installs don't depend on APP_ROOT.
step "Removing any legacy global installs..."
LEGACY_COMMANDS_DIR="$HOME/.claude/commands"
LEGACY_SKILLS_DIR="$HOME/.claude/skills"
LEGACY_REMOVED=false

if [ -d "$LEGACY_COMMANDS_DIR" ]; then
  for legacy_cmd in "$LEGACY_COMMANDS_DIR"/extractify-*.md "$LEGACY_COMMANDS_DIR/ralph-loop.md"; do
    [ -f "$legacy_cmd" ] || continue
    rm "$legacy_cmd"
    ok "Removed ~/.claude/commands/$(basename "$legacy_cmd")"
    LEGACY_REMOVED=true
  done
fi

if [ -d "$LEGACY_SKILLS_DIR" ]; then
  for legacy_skill in "$LEGACY_SKILLS_DIR"/extractify-*/ "$LEGACY_SKILLS_DIR/figma-use/"; do
    [ -d "$legacy_skill" ] || continue
    rm -rf "$legacy_skill"
    ok "Removed ~/.claude/skills/$(basename "$legacy_skill")"
    LEGACY_REMOVED=true
  done
fi

if [ "$LEGACY_REMOVED" = false ]; then
  ok "No legacy global installs found"
fi

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
