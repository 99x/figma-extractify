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

# ── 5. Copy _docs/ contracts to the app root ─────────────────────────────────
# The /extractify-setup wizard reads contract files from _docs/front-end/
# (01-colors.md, 02-typography.md, etc.) and config from _docs/figma-paths.yaml.
# Without these, the wizard cannot run any extraction step.
step "Installing documentation contracts..."
$DOCS_SRC = Join-Path $PROJECT_DIR "_docs"

if ((Test-Path $DOCS_SRC) -and $APP_ROOT) {
    $DOCS_DEST = Join-Path $APP_ROOT "_docs"
    if (Test-Path $DOCS_DEST) {
        # Merge without overwriting — don't clobber user edits
        # Copy each item only if it doesn't already exist at the destination
        Get-ChildItem -Path $DOCS_SRC -Recurse | ForEach-Object {
            $relativePath = $_.FullName.Substring($DOCS_SRC.Length)
            $destPath = Join-Path $DOCS_DEST $relativePath
            if ($_.PSIsContainer) {
                if (-not (Test-Path $destPath)) {
                    New-Item -ItemType Directory -Force -Path $destPath | Out-Null
                }
            } else {
                if (-not (Test-Path $destPath)) {
                    Copy-Item $_.FullName -Destination $destPath -Force
                }
            }
        }
        ok "Merged _docs/ → $DOCS_DEST (existing files preserved)"
    } else {
        Copy-Item $DOCS_SRC -Destination $DOCS_DEST -Recurse
        ok "Installed _docs/ → $DOCS_DEST"
    }
} elseif ((Test-Path $DOCS_SRC) -and -not $APP_ROOT) {
    warn "_docs/ found but no app root detected — copy _docs/ to your project manually"
} else {
    warn "_docs/ not found in $PROJECT_DIR — contract files may be missing"
    warn "Clone the repo with git to get the full documentation set."
}

# ── 6. Copy project config files to app root ──────────────────────────────────
# These files configure the IDE, MCP servers, and agent behaviour.
# Without them, the agent loses project context after figma-extractify/ is deleted.
step "Installing project config files..."

if ($APP_ROOT) {
    # ── 6a. CLAUDE.md (project-level agent config) ───────────────────────────
    $claudeMdSrc = Join-Path $PROJECT_DIR "CLAUDE.md"
    $claudeMdDest = Join-Path $APP_ROOT "CLAUDE.md"
    if ((Test-Path $claudeMdSrc) -and -not (Test-Path $claudeMdDest)) {
        Copy-Item $claudeMdSrc -Destination $claudeMdDest
        ok "Installed CLAUDE.md"
    } elseif (Test-Path $claudeMdSrc) {
        ok "CLAUDE.md already exists — skipped"
    }

    # ── 6b. .mcp.json (Figma MCP server definitions) ────────────────────────
    $mcpSrc = Join-Path $PROJECT_DIR ".mcp.json"
    $mcpDest = Join-Path $APP_ROOT ".mcp.json"
    if ((Test-Path $mcpSrc) -and -not (Test-Path $mcpDest)) {
        Copy-Item $mcpSrc -Destination $mcpDest
        ok "Installed .mcp.json (Figma MCP servers)"
    } elseif ((Test-Path $mcpSrc) -and (Test-Path $mcpDest)) {
        warn ".mcp.json already exists — review $mcpSrc and merge manually if needed"
    }

    # ── 6c. .claude/settings.json (permissions + hooks) ──────────────────────
    $settingsSrc = Join-Path $PROJECT_DIR ".claude" "settings.json"
    $settingsDest = Join-Path $APP_ROOT ".claude" "settings.json"
    if ((Test-Path $settingsSrc) -and -not (Test-Path $settingsDest)) {
        New-Item -ItemType Directory -Force -Path (Join-Path $APP_ROOT ".claude") | Out-Null
        Copy-Item $settingsSrc -Destination $settingsDest
        ok "Installed .claude\settings.json"
    } elseif (Test-Path $settingsSrc) {
        ok ".claude\settings.json already exists — skipped"
    }

    $settingsLocalSrc = Join-Path $PROJECT_DIR ".claude" "settings.local.json"
    $settingsLocalDest = Join-Path $APP_ROOT ".claude" "settings.local.json"
    if ((Test-Path $settingsLocalSrc) -and -not (Test-Path $settingsLocalDest)) {
        New-Item -ItemType Directory -Force -Path (Join-Path $APP_ROOT ".claude") | Out-Null
        Copy-Item $settingsLocalSrc -Destination $settingsLocalDest
        ok "Installed .claude\settings.local.json"
    }

    # ── 6d. scripts/ (visual-diff + a11y-audit) ─────────────────────────────
    $scriptsSrc = Join-Path $PROJECT_DIR "scripts"
    if (Test-Path $scriptsSrc) {
        $scriptsDest = Join-Path $APP_ROOT "scripts"
        New-Item -ItemType Directory -Force -Path $scriptsDest | Out-Null
        Get-ChildItem -Path $scriptsSrc -File | ForEach-Object {
            $destFile = Join-Path $scriptsDest $_.Name
            if (-not (Test-Path $destFile)) {
                Copy-Item $_.FullName -Destination $destFile
                ok "Installed scripts\$($_.Name)"
            } else {
                ok "scripts\$($_.Name) already exists — skipped"
            }
        }
    }

    # ── 6e. IDE rules (Cursor + Windsurf) ────────────────────────────────────
    $cursorSrc = Join-Path $PROJECT_DIR ".cursor" "rules"
    if (Test-Path $cursorSrc) {
        $cursorDest = Join-Path $APP_ROOT ".cursor" "rules"
        New-Item -ItemType Directory -Force -Path $cursorDest | Out-Null
        Get-ChildItem -Path $cursorSrc -File | ForEach-Object {
            $destFile = Join-Path $cursorDest $_.Name
            if (-not (Test-Path $destFile)) {
                Copy-Item $_.FullName -Destination $destFile
                ok "Installed .cursor\rules\$($_.Name)"
            } else {
                ok ".cursor\rules\$($_.Name) already exists — skipped"
            }
        }
    }

    $windsurfSrc = Join-Path $PROJECT_DIR ".windsurfrules"
    $windsurfDest = Join-Path $APP_ROOT ".windsurfrules"
    if ((Test-Path $windsurfSrc) -and -not (Test-Path $windsurfDest)) {
        Copy-Item $windsurfSrc -Destination $windsurfDest
        ok "Installed .windsurfrules"
    } elseif (Test-Path $windsurfSrc) {
        ok ".windsurfrules already exists — skipped"
    }
} else {
    warn "No app root detected — copy config files manually (CLAUDE.md, .mcp.json, scripts\, .cursor\rules\)"
}

# ── 7. Check Figma paths file ─────────────────────────────────────────────────
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

# ── 8. Clean up figma-extractify\ folder ──────────────────────────────────────
# All files have been copied to the project — the source folder is no longer needed.
Write-Host ""
Write-Host "  All files have been copied to your project." -ForegroundColor Green
Write-Host "  The " -NoNewline; Write-Host "figma-extractify\" -ForegroundColor White -NoNewline; Write-Host " folder is no longer needed and can be safely deleted."
Write-Host ""
$DELETE_FOLDER = Read-Host "  Delete figma-extractify\ folder now? [y/N]"
if ($DELETE_FOLDER -match '^[Yy]$') {
    if ($PROJECT_DIR -and ($PROJECT_DIR -ne $APP_ROOT) -and (Test-Path $PROJECT_DIR)) {
        Remove-Item $PROJECT_DIR -Recurse -Force
        ok "Deleted $PROJECT_DIR"
    } else {
        warn "Could not determine a safe path to delete — remove figma-extractify\ manually"
    }
} else {
    warn "Skipped — you can delete figma-extractify\ manually whenever you're ready"
}

# ── 9. Done ───────────────────────────────────────────────────────────────────
Write-Host ""
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Green
Write-Host "  Setup complete. Here's what to do next:" -ForegroundColor Green
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Green
Write-Host ""
Write-Host "  1. Add your Figma URLs → " -NoNewline; Write-Host "_docs\figma-paths.yaml" -ForegroundColor Yellow
Write-Host "  2. Connect to Figma — either:"
Write-Host "       - Open Figma Desktop in Dev Mode (preferred - runs at 127.0.0.1:3845)"
Write-Host "       - Or approve the Remote MCP OAuth prompt in your IDE (fallback - mcp.figma.com)"
Write-Host "  3. " -NoNewline; Write-Host "Restart Claude Code / Cowork" -NoNewline -ForegroundColor White; Write-Host " so the new commands appear"
Write-Host "  4. Start the dev server → " -NoNewline; Write-Host "npm run dev" -ForegroundColor Yellow -NoNewline; Write-Host " (from boilerplate\ if using the monorepo)"
Write-Host "  5. Extract design tokens → " -NoNewline; Write-Host "/extractify-setup" -ForegroundColor Yellow
Write-Host ""
Write-Host "  Full command reference: see README.md" -ForegroundColor Cyan
Write-Host ""
