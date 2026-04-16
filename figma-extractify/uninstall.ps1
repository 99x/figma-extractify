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

# ── Resolve project root (where commands/skills were installed) ───────────────
# Mirror the install.ps1 logic: detect APP_ROOT from package.json location.
$APP_ROOT = $null
if (Test-Path "package.json") {
    $APP_ROOT = (Get-Location).Path
} elseif (Test-Path (Join-Path ".." "boilerplate" "package.json")) {
    $APP_ROOT = (Resolve-Path (Join-Path ".." "boilerplate")).Path
} elseif (Test-Path (Join-Path "boilerplate" "package.json")) {
    $APP_ROOT = (Resolve-Path "boilerplate").Path
}

# ── 2. Remove installed Claude commands (project-local) ───────────────────────
step "Removing Claude commands..."
$COMMANDS_SRC = Join-Path $PROJECT_DIR ".claude" "commands"

if (-not $APP_ROOT) {
    warn "No project root detected — skipping command removal."
    warn "If commands live elsewhere, delete <project>\.claude\commands\extractify-*.md manually."
} elseif (Test-Path $COMMANDS_SRC) {
    $LOCAL_COMMANDS_DIR = Join-Path $APP_ROOT ".claude" "commands"
    $patterns = @("extractify-*.md", "ralph-loop.md")
    foreach ($pattern in $patterns) {
        Get-ChildItem -Path $COMMANDS_SRC -Filter $pattern -ErrorAction SilentlyContinue | ForEach-Object {
            $target = Join-Path $LOCAL_COMMANDS_DIR $_.Name
            if (Test-Path $target) {
                Remove-Item $target -Force
                ok "Removed .claude\commands\$($_.Name)"
            } else {
                warn "$($_.Name) not in $LOCAL_COMMANDS_DIR, skipping"
            }
        }
    }
}

# ── 3. Remove installed skills (project-local) ────────────────────────────────
# Only figma-use is installed by the current installer. Older versions also
# installed extractify-* skill trampolines — those are cleaned up below as a
# leftover, and any global copies are handled by the legacy cleanup in 3b.
step "Removing installed skills..."

if (-not $APP_ROOT) {
    warn "No project root detected — skipping skill removal."
    warn "If skills live elsewhere, delete <project>\.claude\skills\figma-use\ manually."
} else {
    $LOCAL_SKILLS_DIR = Join-Path $APP_ROOT ".claude" "skills"
    $figmaUseTarget = Join-Path $LOCAL_SKILLS_DIR "figma-use"
    if (Test-Path $figmaUseTarget) {
        Remove-Item $figmaUseTarget -Recurse -Force
        ok "Removed .claude\skills\figma-use"
    } else {
        warn "figma-use not in $LOCAL_SKILLS_DIR, skipping"
    }
    # Also clean up any leftover extractify-* skill trampolines from older installs
    Get-ChildItem -Path $LOCAL_SKILLS_DIR -Directory -Filter "extractify-*" -ErrorAction SilentlyContinue | ForEach-Object {
        Remove-Item $_.FullName -Recurse -Force
        ok "Removed leftover .claude\skills\$($_.Name) (from earlier installer version)"
    }
}

# ── 3b. Remove any legacy global installs (from older installer versions) ─────
# Earlier installer versions placed commands/skills in ~\.claude\. Clean those
# up too so uninstall fully removes Figma Extractify regardless of when it was
# installed. Runs unconditionally — legacy installs don't depend on APP_ROOT.
step "Removing any legacy global installs..."
$LEGACY_COMMANDS_DIR = Join-Path $HOME ".claude" "commands"
$LEGACY_SKILLS_DIR   = Join-Path $HOME ".claude" "skills"
$LEGACY_REMOVED = $false

if (Test-Path $LEGACY_COMMANDS_DIR) {
    $legacyCmdPatterns = @("extractify-*.md", "ralph-loop.md")
    foreach ($pattern in $legacyCmdPatterns) {
        Get-ChildItem -Path $LEGACY_COMMANDS_DIR -Filter $pattern -ErrorAction SilentlyContinue | ForEach-Object {
            Remove-Item $_.FullName -Force
            ok "Removed ~\.claude\commands\$($_.Name)"
            $LEGACY_REMOVED = $true
        }
    }
}

if (Test-Path $LEGACY_SKILLS_DIR) {
    $legacySkillFilters = @("extractify-*", "figma-use")
    foreach ($filter in $legacySkillFilters) {
        Get-ChildItem -Path $LEGACY_SKILLS_DIR -Directory -Filter $filter -ErrorAction SilentlyContinue | ForEach-Object {
            Remove-Item $_.FullName -Recurse -Force
            ok "Removed ~\.claude\skills\$($_.Name)"
            $LEGACY_REMOVED = $true
        }
    }
}

if (-not $LEGACY_REMOVED) {
    ok "No legacy global installs found"
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
