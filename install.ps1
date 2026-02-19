# GSD Customizations Installer (Windows PowerShell)
# Copies modified workflow files into the GSD installation directory.
# Replaces placeholder paths with the current user's home directory.
# Run after each GSD update to reapply your modifications.

$ErrorActionPreference = "Stop"

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$TemplateHome = "/Users/tilenkrivec"
$GsdDir = Join-Path $env:USERPROFILE ".claude\get-shit-done"
$CurrentHome = $env:USERPROFILE -replace '\\', '/'

Write-Host "Platform: Windows"
Write-Host "Home: $CurrentHome"

# Verify GSD is installed
if (-not (Test-Path $GsdDir)) {
    Write-Host ""
    Write-Host "Error: GSD not found at $GsdDir" -ForegroundColor Red
    Write-Host "Install GSD first, then run this script."
    exit 1
}

$Version = if (Test-Path "$GsdDir\VERSION") { Get-Content "$GsdDir\VERSION" } else { "unknown" }
Write-Host "GSD found at: $GsdDir"
Write-Host "GSD version: $Version"
Write-Host ""

# Backup originals
$BackupDir = Join-Path $ScriptDir ".originals\workflows"
if (-not (Test-Path $BackupDir)) {
    Write-Host "Backing up original files to .originals/..."
    New-Item -ItemType Directory -Path $BackupDir -Force | Out-Null
    Copy-Item "$GsdDir\workflows\discuss-phase.md" "$BackupDir\discuss-phase.md" -ErrorAction SilentlyContinue
    Copy-Item "$GsdDir\workflows\plan-phase.md" "$BackupDir\plan-phase.md" -ErrorAction SilentlyContinue
    Copy-Item "$GsdDir\workflows\progress.md" "$BackupDir\progress.md" -ErrorAction SilentlyContinue
    Write-Host "Originals backed up."
} else {
    Write-Host "Backup already exists, skipping."
}

Write-Host ""
Write-Host "Installing customizations..."

function Install-File {
    param(
        [string]$Source,
        [string]$Destination,
        [string]$Name
    )

    $content = Get-Content $Source -Raw
    if ($CurrentHome -ne $TemplateHome) {
        $content = $content -replace [regex]::Escape($TemplateHome), $CurrentHome
        Set-Content -Path $Destination -Value $content -NoNewline
        Write-Host "  [OK] $Name (paths updated: $TemplateHome -> $CurrentHome)"
    } else {
        Copy-Item $Source $Destination
        Write-Host "  [OK] $Name"
    }
}

Install-File -Source "$ScriptDir\workflows\discuss-phase.md" -Destination "$GsdDir\workflows\discuss-phase.md" -Name "workflows/discuss-phase.md"
Install-File -Source "$ScriptDir\workflows\plan-phase.md" -Destination "$GsdDir\workflows\plan-phase.md" -Name "workflows/plan-phase.md"
Install-File -Source "$ScriptDir\workflows\progress.md" -Destination "$GsdDir\workflows\progress.md" -Name "workflows/progress.md"

$CmdDir = Join-Path $env:USERPROFILE ".claude\commands\gsd"
if (-not (Test-Path $CmdDir)) { New-Item -ItemType Directory -Path $CmdDir -Force | Out-Null }
Install-File -Source "$ScriptDir\commands\gsd\discuss-phase.md" -Destination "$CmdDir\discuss-phase.md" -Name "commands/gsd/discuss-phase.md"

Write-Host ""
Write-Host "Done. Customizations installed." -ForegroundColor Green
Write-Host ""
Write-Host "Remember to add this to your project .planning/config.json:"
Write-Host "  `"workflow`": { `"discuss_mode`": `"assumptions`" }"
