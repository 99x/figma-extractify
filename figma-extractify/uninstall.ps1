# Figma Extractify — uninstaller (Windows)
# Removes QA dev dependencies, Claude commands/skills, and runtime files.
# Usage: powershell -ExecutionPolicy Bypass -File uninstall.ps1

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

# ── Colors ────────────────────────────────────────────────────────────────────
function ok($msg)   { Write-Host "✓ $msg" -ForegroundColor Green }
function step($msg) { Write-Host "`n▶ $msg" -ForegroundColor Cyan }
function warn($msg) { Write-Host "⚠ $msg" -ForegroundColor Yellow }

$PROJECT_DIR = $PSScriptRoot

Write-Host ""
Write-Host "╔══════════════════════════════════════════════╗" -ForegroundColor White
Write-Host "║        Figma Extractify — Uninstaller        ║" -ForegroundColor White
Write-Host "╚══════════════════════════════════════════════╝" -ForegroundColor White
Write-Host ""

# ── 1. Remove QA dev dependencies ─────────────────────────────────────────────
step "Removing optional QA tools..."
$QA_PKGS = @("pixelmatch", "pngjs", "@axe-core/playwright", "@playwright/test")
foreach ($pkg in $QA_PKGS) {
    try {
        $listed = npm ls $pkg 2>&1
        if ($LASTEXITCODE -eq 0) {
            npm uninstall -D $pkg 2>$null
            ok "Removed $pkg"
        } else {
            warn "$pkg not installed, skipping"
        }
    } catch {
        warn "$pkg not installed, skipping"
    }
}

# ── 2. Remove installed Claude commands ───────────────────────────────────────
step "Removing Claude commands..."
$GLOBAL_COMMANDS_DIR = Join-Path $HOME ".claude" "commands"
$COMMANDS_SRC = Join-Path $PROJECT_DIR ".claude" "commands"

if (Test-Path $COMMANDS_SRC) {
    $patterns = @("extractify-*.md", "ralph-loop.md")
    foreach ($pattern in $patterns) {
        Get-ChildItem -Path $COMMANDS_SRC -Filter $pattern -ErrorAction SilentlyContinue | ForEach-Object {
            $target = Join-Path $GLOBAL_COMMANDS_DIR $_.Name
            if (Test-Path $target) {
                Remove-Item $target -Force
                ok "Removed ~/.claude/commands/$($_.Name)"
            } else {
                warn "$($_.Name) not in ~/.claude/commands/, skipping"
            }
        }
    }
}

# ── 3. Remove installed Cowork skills ────────────────────────────────────────
step "Removing Cowork skills..."
$GLOBAL_SKILLS_DIR = Join-Path $HOME ".claude" "skills"

$SKILL_SOURCES = @(
    (Join-Path $PROJECT_DIR ".claude" "skills"),
    (Join-Path $PROJECT_DIR "skills")
)

foreach ($SRC in $SKILL_SOURCES) {
    if (Test-Path $SRC) {
        Get-ChildItem -Path $SRC -Directory -Filter "extractify-*" -ErrorAction SilentlyContinue | ForEach-Object {
            $target = Join-Path $GLOBAL_SKILLS_DIR $_.Name
            if (Test-Path $target) {
                Remove-Item $target -Recurse -Force
                ok "Removed ~/.claude/skills/$($_.Name)"
            } else {
                warn "$($_.Name) not in ~/.claude/skills/, skipping"
            }
        }
    }
}

# ── 4. Remove runtime state files ─────────────────────────────────────────────
step "Cleaning up runtime files..."
$runtimeFiles = @(".ralph-loop-state.json")
$runtimeDirs  = @(".screenshots", ".audit")

foreach ($f in $runtimeFiles) {
    if (Test-Path $f) {
        Remove-Item $f -Force
        ok "Removed $f"
    }
}
foreach ($d in $runtimeDirs) {
    if (Test-Path $d) {
        Remove-Item $d -Recurse -Force
        ok "Removed $d/"
    }
}

# ── 5. Done ───────────────────────────────────────────────────────────────────
Write-Host ""
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Green
Write-Host "  Done. The boilerplate source files are untouched." -ForegroundColor Green
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Green
Write-Host ""
Write-Host "  To fully remove the project: " -NoNewline; Write-Host "Remove-Item -Recurse -Force <project-folder>" -ForegroundColor Yellow
Write-Host ""
