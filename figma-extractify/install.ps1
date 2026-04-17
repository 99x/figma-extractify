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

# ── Install vs upgrade detection ─────────────────────────────────────────────
# If /extractify-setup already exists in the target, treat this run as an
# upgrade: shipped files (commands, skill, hook, scripts, _docs contracts, IDE
# rules) are overwritten; user-owned files (figma-paths.yaml, learnings.md,
# CLAUDE.md, .mcp.json, .claude\settings.json) are preserved.
$MODE = "install"
if ($APP_ROOT -and (Test-Path (Join-Path $APP_ROOT ".claude" "commands" "extractify-setup.md"))) {
    $MODE = "upgrade"
}
$UPGRADED_COUNT = 0
$PRESERVED_COUNT = 0

# ── Header ────────────────────────────────────────────────────────────────────
Write-Host ""
Write-Host "╔══════════════════════════════════════════════╗" -ForegroundColor White
Write-Host "║        Figma Extractify — Installer          ║" -ForegroundColor White
Write-Host "╚══════════════════════════════════════════════╝" -ForegroundColor White
if ($MODE -eq "upgrade") {
    Write-Host ""
    Write-Host "  Detected existing install - running in upgrade mode." -ForegroundColor Yellow
    Write-Host "  Shipped files will be overwritten; user-owned files preserved."
}
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
$HAS_QA = $false
if ($APP_ROOT) {
    $pkgJson = Join-Path $APP_ROOT "package.json"
    if (Test-Path $pkgJson) {
        if ((Get-Content $pkgJson -Raw) -match '"@axe-core/playwright"') {
            $HAS_QA = $true
        }
    }
}

if ($HAS_QA) {
    ok "QA tools already installed - skipping prompt"
    $INSTALL_QA = "n"
} else {
    Write-Host ""
    Write-Host "  Optional QA tools power the visual diff and accessibility audit:" -ForegroundColor White
    Write-Host "  pixelmatch · pngjs · @axe-core/playwright · Playwright Chromium" -ForegroundColor Yellow
    Write-Host ""
    $INSTALL_QA = Read-Host "  Install QA tools? [y/N]"
}
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

# ── 4. Install Claude commands + figma-use skill (project-local) ──────────────
# Claude Code reads commands/skills from <project>\.claude\{commands,skills}\.
# Installing project-local (instead of ~\.claude\) scopes them to THIS project,
# so /extractify-* commands don't appear in unrelated projects where _docs\
# doesn't exist and the commands would fail.
step "Installing Claude commands and figma-use skill..."

if (-not $APP_ROOT) {
    err "No project root detected (no package.json found nearby)."
    err "Commands and skills install into <project>\.claude\ — a project is required."
    err "Run install.ps1 from inside your project, or alongside the boilerplate\ folder."
    exit 1
}

$LOCAL_COMMANDS_DIR = Join-Path $APP_ROOT ".claude" "commands"
$LOCAL_SKILLS_DIR   = Join-Path $APP_ROOT ".claude" "skills"

New-Item -ItemType Directory -Force -Path $LOCAL_COMMANDS_DIR | Out-Null
New-Item -ItemType Directory -Force -Path $LOCAL_SKILLS_DIR   | Out-Null

# ── 4a. Commands (.claude/commands/*.md) ──────────────────────────────────────
$COMMANDS_SRC   = Join-Path $PROJECT_DIR ".claude" "commands"
$COMMANDS_FOUND = $false

if (Test-Path $COMMANDS_SRC) {
    $patterns = @("extractify-*.md", "ralph-loop.md")
    foreach ($pattern in $patterns) {
        Get-ChildItem -Path $COMMANDS_SRC -Filter $pattern -ErrorAction SilentlyContinue | ForEach-Object {
            Copy-Item $_.FullName -Destination $LOCAL_COMMANDS_DIR -Force
            ok "Installed command: $($_.Name) → .claude\commands\$($_.Name)"
            $COMMANDS_FOUND = $true
            $script:UPGRADED_COUNT++
        }
    }
}

if (-not $COMMANDS_FOUND) {
    warn "No extractify-*.md commands found in .claude\commands\"
    warn "Clone the repo with git to get the full command set."
}

# ── 4b. Skills (.claude/skills/) ──────────────────────────────────────────────
# Only figma-use is installed as a skill — it's the mandatory prerequisite for
# every use_figma tool call (see _docs\start-here.md). The /extractify-* workflows
# are pure slash commands; they don't need skill wrappers. The evals\ directory
# is intentionally skipped — it holds internal eval data, not a skill.
$SKILL_SOURCES = @(
    (Join-Path $PROJECT_DIR ".claude" "skills"),
    (Join-Path $PROJECT_DIR "skills")
)
$SKILLS_FOUND = $false

foreach ($SRC in $SKILL_SOURCES) {
    $figmaUseSrc = Join-Path $SRC "figma-use"
    if (Test-Path $figmaUseSrc) {
        # Clean-replace so removed-upstream files don't linger in the user's copy.
        # figma-use\ is fully owned by figma-extractify - no user files to preserve.
        $figmaUseDest = Join-Path $LOCAL_SKILLS_DIR "figma-use"
        if (Test-Path $figmaUseDest) {
            Remove-Item $figmaUseDest -Recurse -Force
        }
        Copy-Item $figmaUseSrc -Destination $LOCAL_SKILLS_DIR -Recurse -Force
        ok "Installed skill: figma-use → .claude\skills\figma-use"
        $SKILLS_FOUND = $true
        $UPGRADED_COUNT++
        break
    }
}

if (-not $SKILLS_FOUND) {
    warn "figma-use skill not found — use_figma calls will fail without it"
    warn "Clone the repo with git to get the full skill set."
}

# ── 4c. Migrate legacy global installs (one-shot cleanup) ─────────────────────
# Earlier versions of this installer copied commands/skills into ~\.claude\,
# which made /extractify-* commands appear in every project on the user's
# machine — even ones without _docs\ where the commands can't run. Detect and
# remove those orphans so users upgrading don't end up with two copies.
$LEGACY_COMMANDS_DIR = Join-Path $HOME ".claude" "commands"
$LEGACY_SKILLS_DIR   = Join-Path $HOME ".claude" "skills"
$LEGACY_FOUND = $false

if (Test-Path $LEGACY_COMMANDS_DIR) {
    $legacyPatterns = @("extractify-*.md", "ralph-loop.md")
    foreach ($pattern in $legacyPatterns) {
        Get-ChildItem -Path $LEGACY_COMMANDS_DIR -Filter $pattern -ErrorAction SilentlyContinue | ForEach-Object {
            if (-not $LEGACY_FOUND) {
                step "Removing legacy global install (now project-local)..."
                $LEGACY_FOUND = $true
            }
            Remove-Item $_.FullName -Force
            ok "Removed ~\.claude\commands\$($_.Name)"
        }
    }
}

if (Test-Path $LEGACY_SKILLS_DIR) {
    $legacySkillFilters = @("extractify-*", "figma-use")
    foreach ($filter in $legacySkillFilters) {
        Get-ChildItem -Path $LEGACY_SKILLS_DIR -Directory -Filter $filter -ErrorAction SilentlyContinue | ForEach-Object {
            if (-not $LEGACY_FOUND) {
                step "Removing legacy global install (now project-local)..."
                $LEGACY_FOUND = $true
            }
            Remove-Item $_.FullName -Recurse -Force
            ok "Removed ~\.claude\skills\$($_.Name)"
        }
    }
}

# ── 4d. Ralph Loop stop hook (project-local) ──────────────────────────────────
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
    $UPGRADED_COUNT++
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

# Files under _docs\ that are user-owned and must never be overwritten on
# upgrade. Everything else in _docs\ is shipped by figma-extractify and gets
# force-updated so contract changes propagate to existing installs.
$DOCS_PRESERVE = @("figma-paths.yaml", "learnings.md")

if ((Test-Path $DOCS_SRC) -and $APP_ROOT) {
    $DOCS_DEST = Join-Path $APP_ROOT "_docs"
    New-Item -ItemType Directory -Force -Path $DOCS_DEST | Out-Null
    Get-ChildItem -Path $DOCS_SRC -Recurse -File | ForEach-Object {
        $rel = $_.FullName.Substring($DOCS_SRC.Length).TrimStart('\', '/')
        $destFile = Join-Path $DOCS_DEST $rel
        $destDir  = Split-Path $destFile -Parent
        New-Item -ItemType Directory -Force -Path $destDir | Out-Null
        $relNormalized = $rel -replace '\\', '/'
        $preserved = $false
        foreach ($p in $DOCS_PRESERVE) {
            if ($relNormalized -eq $p -and (Test-Path $destFile)) {
                $preserved = $true
                break
            }
        }
        if ($preserved) {
            $script:PRESERVED_COUNT++
        } else {
            Copy-Item $_.FullName -Destination $destFile -Force
            $script:UPGRADED_COUNT++
        }
    }
    ok "Installed _docs/ → $DOCS_DEST (figma-paths.yaml and learnings.md preserved if present)"
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
    # ── 6a. CLAUDE.md (project-level agent config - user-customized) ─────────
    # Preserve on upgrade; teams edit CLAUDE.md heavily for project specifics.
    $claudeMdSrc = Join-Path $PROJECT_DIR "CLAUDE.md"
    $claudeMdDest = Join-Path $APP_ROOT "CLAUDE.md"
    if ((Test-Path $claudeMdSrc) -and -not (Test-Path $claudeMdDest)) {
        Copy-Item $claudeMdSrc -Destination $claudeMdDest
        ok "Installed CLAUDE.md"
    } elseif (Test-Path $claudeMdSrc) {
        ok "CLAUDE.md already exists - preserved"
        $PRESERVED_COUNT++
    }

    # ── 6b. .mcp.json (Figma MCP server definitions - may contain others) ───
    $mcpSrc = Join-Path $PROJECT_DIR ".mcp.json"
    $mcpDest = Join-Path $APP_ROOT ".mcp.json"
    if ((Test-Path $mcpSrc) -and -not (Test-Path $mcpDest)) {
        Copy-Item $mcpSrc -Destination $mcpDest
        ok "Installed .mcp.json (Figma MCP servers)"
    } elseif ((Test-Path $mcpSrc) -and (Test-Path $mcpDest)) {
        warn ".mcp.json already exists - preserved (review $mcpSrc and merge manually if needed)"
        $PRESERVED_COUNT++
    }

    # ── 6c. .claude\settings.json (permissions - may contain other tools) ───
    $settingsSrc = Join-Path $PROJECT_DIR ".claude" "settings.json"
    $settingsDest = Join-Path $APP_ROOT ".claude" "settings.json"
    if ((Test-Path $settingsSrc) -and -not (Test-Path $settingsDest)) {
        New-Item -ItemType Directory -Force -Path (Join-Path $APP_ROOT ".claude") | Out-Null
        Copy-Item $settingsSrc -Destination $settingsDest
        ok "Installed .claude\settings.json"
    } elseif (Test-Path $settingsSrc) {
        ok ".claude\settings.json already exists - preserved"
        $PRESERVED_COUNT++
    }

    # Note: settings.local.json is intentionally NOT copied. It's a per-machine
    # file that accumulates permission grants with absolute paths from the user
    # who created it. Each installation must generate its own - Claude Code does
    # this automatically as the user approves tools. A reference copy of useful
    # MCP permissions lives at figma-extractify\.claude\settings.local.json.example
    # if you want to seed one manually.

    # ── 6d. scripts\ (visual-diff + a11y-audit - shipped, overwritten) ──────
    $scriptsSrc = Join-Path $PROJECT_DIR "scripts"
    if (Test-Path $scriptsSrc) {
        $scriptsDest = Join-Path $APP_ROOT "scripts"
        New-Item -ItemType Directory -Force -Path $scriptsDest | Out-Null
        Get-ChildItem -Path $scriptsSrc -File | ForEach-Object {
            $destFile = Join-Path $scriptsDest $_.Name
            Copy-Item $_.FullName -Destination $destFile -Force
            ok "Installed scripts\$($_.Name)"
            $script:UPGRADED_COUNT++
        }
    }

    # ── 6e. IDE rules (Cursor + Windsurf + Copilot - shipped, overwritten) ──
    $cursorSrc = Join-Path $PROJECT_DIR ".cursor" "rules"
    if (Test-Path $cursorSrc) {
        $cursorDest = Join-Path $APP_ROOT ".cursor" "rules"
        New-Item -ItemType Directory -Force -Path $cursorDest | Out-Null
        Get-ChildItem -Path $cursorSrc -File | ForEach-Object {
            $destFile = Join-Path $cursorDest $_.Name
            Copy-Item $_.FullName -Destination $destFile -Force
            ok "Installed .cursor\rules\$($_.Name)"
            $script:UPGRADED_COUNT++
        }
    }

    $windsurfSrc = Join-Path $PROJECT_DIR ".windsurfrules"
    $windsurfDest = Join-Path $APP_ROOT ".windsurfrules"
    if (Test-Path $windsurfSrc) {
        Copy-Item $windsurfSrc -Destination $windsurfDest -Force
        ok "Installed .windsurfrules"
        $UPGRADED_COUNT++
    }

    # ── 6f. GitHub Copilot instructions (shipped, overwritten) ──────────────
    $copilotSrc = Join-Path $PROJECT_DIR ".github" "copilot-instructions.md"
    if (Test-Path $copilotSrc) {
        $copilotDestDir = Join-Path $APP_ROOT ".github"
        New-Item -ItemType Directory -Force -Path $copilotDestDir | Out-Null
        Copy-Item $copilotSrc -Destination (Join-Path $copilotDestDir "copilot-instructions.md") -Force
        ok "Installed .github\copilot-instructions.md"
        $UPGRADED_COUNT++
    }
} else {
    warn "No app root detected - copy config files manually (CLAUDE.md, .mcp.json, scripts\, .cursor\rules\, .github\copilot-instructions.md)"
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
if ($MODE -eq "upgrade") {
    ok "Upgrade summary: $UPGRADED_COUNT shipped files updated, $PRESERVED_COUNT user-owned files preserved"
    Write-Host ""
}
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Green
if ($MODE -eq "upgrade") {
    Write-Host "  Upgrade complete. Here's what to do next:" -ForegroundColor Green
} else {
    Write-Host "  Setup complete. Here's what to do next:" -ForegroundColor Green
}
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Green
Write-Host ""
Write-Host "  1. Add your Figma URLs → " -NoNewline; Write-Host "_docs\figma-paths.yaml" -ForegroundColor Yellow
Write-Host "  2. Connect to Figma — either:"
Write-Host "       - Open Figma Desktop in Dev Mode (preferred - runs at 127.0.0.1:3845)"
Write-Host "       - Or approve the Remote MCP OAuth prompt in your IDE (fallback - mcp.figma.com)"
Write-Host "  3. " -NoNewline; Write-Host "Restart Claude Code" -NoNewline -ForegroundColor White; Write-Host " so the new commands appear"
Write-Host "  4. Start the dev server → " -NoNewline; Write-Host "npm run dev" -ForegroundColor Yellow -NoNewline; Write-Host " (from boilerplate\ if using the monorepo)"
Write-Host "  5. Extract design tokens → " -NoNewline; Write-Host "/extractify-setup" -ForegroundColor Yellow
Write-Host ""
Write-Host "  Full command reference: see README.md" -ForegroundColor Cyan
Write-Host ""
