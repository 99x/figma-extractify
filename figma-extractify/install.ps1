# Figma Extractify — project installer (Windows)
# Usage: powershell -ExecutionPolicy Bypass -File install.ps1
#
# Run this from inside the figma-extractify/ directory (where this file lives).
# If you cloned the monorepo, that means:
#   cd figma-extractify\figma-extractify
#   powershell -ExecutionPolicy Bypass -File install.ps1

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

# ── Colors ────────────────────────────────────────────────────────────────────
function ok($msg)   { Write-Host "✓ $msg" -ForegroundColor Green }
function step($msg) { Write-Host "`n▶ $msg" -ForegroundColor Cyan }
function warn($msg) { Write-Host "⚠ $msg" -ForegroundColor Yellow }
function err($msg)  { Write-Host "✗ $msg" -ForegroundColor Red }

# ── Resolve app root (where package.json lives) ───────────────────────────────
$PROJECT_DIR = $PSScriptRoot
$APP_ROOT = $null

if (Test-Path "package.json") {
    $APP_ROOT = (Get-Location).Path
} elseif (Test-Path (Join-Path ".." "boilerplate" "package.json")) {
    $APP_ROOT = (Resolve-Path (Join-Path ".." "boilerplate")).Path
} elseif (Test-Path (Join-Path "boilerplate" "package.json")) {
    $APP_ROOT = (Resolve-Path "boilerplate").Path
}

# ── Header ────────────────────────────────────────────────────────────────────
Write-Host ""
Write-Host "╔══════════════════════════════════════════════╗" -ForegroundColor White
Write-Host "║        Figma Extractify — Installer          ║" -ForegroundColor White
Write-Host "╚══════════════════════════════════════════════╝" -ForegroundColor White
Write-Host ""

# ── 1. Check Node.js ──────────────────────────────────────────────────────────
step "Checking Node.js..."
if (-not (Get-Command node -ErrorAction SilentlyContinue)) {
    err "Node.js not found. Install v18.17+ from https://nodejs.org"
    exit 1
}
$NODE_VER = (node --version).Trim()
$NODE_MAJOR = [int]($NODE_VER -replace '^v(\d+)\..*', '$1')
if ($NODE_MAJOR -lt 18) {
    err "Node.js $NODE_VER is too old. v18.17+ required."
    exit 1
}
ok "Node.js $NODE_VER"

# ── 2. Install dependencies ───────────────────────────────────────────────────
step "Installing dependencies..."
if ($APP_ROOT) {
    if ($APP_ROOT -eq (Get-Location).Path) {
        npm install
        ok "Dependencies installed"
    } else {
        warn "No package.json in this directory — monorepo layout detected."
        warn "Installing from $APP_ROOT ..."
        Push-Location $APP_ROOT
        npm install
        Pop-Location
        ok "Dependencies installed in $(Split-Path $APP_ROOT -Leaf)/"
    }
} elseif (Test-Path (Join-Path ".." "boilerplate" "package.json")) {
    warn "No package.json in this directory — monorepo layout detected."
    warn "Installing from ..\boilerplate\ ..."
    Push-Location (Join-Path ".." "boilerplate")
    npm install
    Pop-Location
    ok "Dependencies installed in boilerplate/"
} else {
    warn "No package.json found anywhere nearby — skipping npm install."
    warn "Run 'npm install' manually from your project root (where package.json lives)."
}

# ── 3. Optional QA tools ──────────────────────────────────────────────────────
Write-Host ""
Write-Host "  Optional QA tools power the visual diff and accessibility audit:" -ForegroundColor White
Write-Host "  pixelmatch · pngjs · @axe-core/playwright · Playwright Chromium" -ForegroundColor Yellow
Write-Host ""
$INSTALL_QA = Read-Host "  Install QA tools? [y/N]"
if ($INSTALL_QA -match '^[Yy]$') {
    step "Installing QA tools..."
    if ($APP_ROOT) {
        if ($APP_ROOT -eq (Get-Location).Path) {
            npm install -D pixelmatch pngjs @axe-core/playwright @playwright/test
            npx playwright install chromium
        } else {
            Push-Location $APP_ROOT
            npm install -D pixelmatch pngjs @axe-core/playwright @playwright/test
            npx playwright install chromium
            Pop-Location
        }
    }
    ok "QA tools installed"
} else {
    warn "Skipped — visual diff and a11y audit won't be available (run /extractify-preflight to re-check later)"
}

# ── 4. Install Claude commands + Cowork skills ────────────────────────────────
step "Installing Claude commands and Cowork skills..."
$GLOBAL_COMMANDS_DIR = Join-Path $HOME ".claude" "commands"
$GLOBAL_SKILLS_DIR   = Join-Path $HOME ".claude" "skills"

New-Item -ItemType Directory -Force -Path $GLOBAL_COMMANDS_DIR | Out-Null
New-Item -ItemType Directory -Force -Path $GLOBAL_SKILLS_DIR   | Out-Null

# ── 4a. Commands (.claude/commands/*.md) ──────────────────────────────────────
$COMMANDS_SRC   = Join-Path $PROJECT_DIR ".claude" "commands"
$COMMANDS_FOUND = $false

if (Test-Path $COMMANDS_SRC) {
    $patterns = @("extractify-*.md", "ralph-loop.md")
    foreach ($pattern in $patterns) {
        Get-ChildItem -Path $COMMANDS_SRC -Filter $pattern -ErrorAction SilentlyContinue | ForEach-Object {
            Copy-Item $_.FullName -Destination $GLOBAL_COMMANDS_DIR -Force
            ok "Installed command: $($_.Name) → ~/.claude/commands/$($_.Name)"
            $COMMANDS_FOUND = $true
        }
    }
}

if (-not $COMMANDS_FOUND) {
    warn "No extractify-*.md commands found in .claude\commands\"
    warn "Clone the repo with git to get the full command set."
}

# ── 4b. Skills (.claude/skills/ or skills/) ───────────────────────────────────
$SKILL_SOURCES = @(
    (Join-Path $PROJECT_DIR ".claude" "skills"),
    (Join-Path $PROJECT_DIR "skills")
)
$SKILLS_FOUND = $false

foreach ($SRC in $SKILL_SOURCES) {
    if (Test-Path $SRC) {
        Get-ChildItem -Path $SRC -Directory -Filter "extractify-*" -ErrorAction SilentlyContinue | ForEach-Object {
            Copy-Item $_.FullName -Destination $GLOBAL_SKILLS_DIR -Recurse -Force
            ok "Installed skill: $($_.Name) → ~/.claude/skills/$($_.Name)"
            $SKILLS_FOUND = $true
        }
    }
}

if (-not $SKILLS_FOUND) {
    warn "No extractify-* skills found — skills directory may be missing"
    warn "Clone the repo with git to get the full skill set."
}

# ── 4c. Ralph Loop stop hook (project-local) ──────────────────────────────────
step "Installing Ralph Loop stop hook..."
$HOOK_SRC = Join-Path $PROJECT_DIR ".claude" "hooks" "ralph-stop.sh"

if (-not (Test-Path $HOOK_SRC)) {
    warn "Hook source not found at .claude\hooks\ralph-stop.sh — skipping."
} elseif (-not $APP_ROOT) {
    warn "Could not detect app root (package.json not found)."
    warn "Copy hook manually to your project: .claude\hooks\ralph-stop.sh"
} else {
    $HOOK_DEST_DIR = Join-Path $APP_ROOT ".claude" "hooks"
    New-Item -ItemType Directory -Force -Path $HOOK_DEST_DIR | Out-Null
    Copy-Item $HOOK_SRC -Destination (Join-Path $HOOK_DEST_DIR "ralph-stop.sh") -Force
    ok "Installed Ralph stop hook: $HOOK_DEST_DIR\ralph-stop.sh"
}

if (Get-Command jq -ErrorAction SilentlyContinue) {
    ok "jq found (required by ralph-stop.sh)"
} else {
    warn "jq not found — /ralph-loop stop hook requires jq"
    warn "Install with: winget install jqlang.jq  (or via https://jqlang.github.io/jq/download/)"
}

# ── 5. Check Figma paths file ─────────────────────────────────────────────────
Write-Host ""
$YAML_PATH = $null

if ($APP_ROOT) {
    $candidate1 = Join-Path $APP_ROOT "_docs" "figma-paths.yaml"
    $candidate2 = Join-Path $APP_ROOT "figma-paths.yaml"
    if (Test-Path $candidate1) { $YAML_PATH = $candidate1 }
    elseif (Test-Path $candidate2) { $YAML_PATH = $candidate2 }
}
if (-not $YAML_PATH -and (Test-Path (Join-Path "_docs" "figma-paths.yaml"))) {
    $YAML_PATH = Join-Path "_docs" "figma-paths.yaml"
}

if ($YAML_PATH) {
    $yaml = Get-Content $YAML_PATH -Raw
    if ($yaml -match 'colors:\s*\n\s*url:\s*(.+)') {
        $colorsUrl = $Matches[1].Trim()
        if (-not $colorsUrl -or $colorsUrl -eq '~') {
            warn "Figma URLs not set yet — edit _docs\figma-paths.yaml before running /extractify-setup"
        } else {
            ok "figma-paths.yaml already has URLs"
        }
    } else {
        warn "Figma URLs not set yet — edit _docs\figma-paths.yaml before running /extractify-setup"
    }
}

# ── 6. Done ───────────────────────────────────────────────────────────────────
Write-Host ""
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Green
Write-Host "  Setup complete. Here's what to do next:" -ForegroundColor Green
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Green
Write-Host ""
Write-Host "  1. Add your Figma URLs → " -NoNewline; Write-Host "_docs\figma-paths.yaml" -ForegroundColor Yellow
Write-Host "  2. Open Figma Desktop in Dev Mode (required for MCP)"
Write-Host "  3. " -NoNewline; Write-Host "Restart Claude Code / Cowork" -NoNewline -ForegroundColor White; Write-Host " so the new commands appear"
Write-Host "  4. Start the dev server → " -NoNewline; Write-Host "npm run dev" -ForegroundColor Yellow -NoNewline; Write-Host " (from boilerplate\ if using the monorepo)"
Write-Host "  5. Extract design tokens → " -NoNewline; Write-Host "/extractify-setup" -ForegroundColor Yellow
Write-Host ""
Write-Host "  Full command reference: see README.md" -ForegroundColor Cyan
Write-Host ""
