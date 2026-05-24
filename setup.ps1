<#
.SYNOPSIS
    Editor Configuration Sync Script for Windows
.DESCRIPTION
    Safely symlinks editor configurations from this repository to your local Windows system.
#>

$ErrorActionPreference = 'Stop'

# Determine paths
$RepoDir = $PSScriptRoot
$Timestamp = Get-Date -Format "yyyyMMdd_HHmmss"

Write-Host "Initializing configuration sync for Windows..." -ForegroundColor Cyan

# ---------------------------------------------------------
# Helper Function: Safely link files or directories
# ---------------------------------------------------------
function Install-Symlink {
    param (
        [string]$SourcePath,
        [string]$TargetPath
    )

    $TargetDir = Split-Path $TargetPath -Parent
    if (-not (Test-Path $TargetDir)) {
        New-Item -ItemType Directory -Force -Path $TargetDir | Out-Null
    }

    # Check if target exists
    if (Test-Path $TargetPath) {
        $Item = Get-Item $TargetPath
        # If it's not a link/reparse point, back it up
        if (-not $Item.Attributes.HasFlag([System.IO.FileAttributes]::ReparsePoint)) {
            $BackupPath = "$TargetPath.backup_$Timestamp"
            Write-Host "  [BACKUP] Moving existing config to $BackupPath" -ForegroundColor Yellow
            Move-Item -Path $TargetPath -Destination $BackupPath -Force
        } else {
            # It's an existing link, remove it so we can cleanly overwrite
            Remove-Item -Path $TargetPath -Force -Recurse
        }
    }

    # Determine link type. Junctions don't require Admin rights for directories.
    $ItemType = if (Test-Path $SourcePath -PathType Container) { "Junction" } else { "SymbolicLink" }

    try {
        New-Item -ItemType $ItemType -Path $TargetPath -Target $SourcePath -Force | Out-Null
        Write-Host "  [LINKED] $TargetPath -> $SourcePath" -ForegroundColor Green
    } catch {
        Write-Host "  [ERROR] Failed to link $TargetPath." -ForegroundColor Red
        Write-Host "          If this is a file symlink, ensure Windows Developer Mode is enabled or run as Administrator." -ForegroundColor DarkGray
    }
}

# ---------------------------------------------------------
# 1. VS Code
# ---------------------------------------------------------
Write-Host "`nConfiguring VS Code..."
$VsCodeTarget = Join-Path $env:APPDATA "Code\User"
Install-Symlink -SourcePath (Join-Path $RepoDir "vscode\settings.json") -TargetPath (Join-Path $VsCodeTarget "settings.json")
# Install-Symlink -SourcePath (Join-Path $RepoDir "vscode\keybindings.json") -TargetPath (Join-Path $VsCodeTarget "keybindings.json")

# ---------------------------------------------------------
# 2. Neovim
# ---------------------------------------------------------
Write-Host "`nConfiguring Neovim..."
$NvimTarget = Join-Path $env:LOCALAPPDATA "nvim"
Install-Symlink -SourcePath (Join-Path $RepoDir "nvim") -TargetPath $NvimTarget

# ---------------------------------------------------------
# 3. Zed
# ---------------------------------------------------------
Write-Host "`nConfiguring Zed..."
$ZedTarget = Join-Path $env:LOCALAPPDATA "Zed"
Install-Symlink -SourcePath (Join-Path $RepoDir "zed\settings.json") -TargetPath (Join-Path $ZedTarget "settings.json")
Install-Symlink -SourcePath (Join-Path $RepoDir "zed\keymap.json") -TargetPath (Join-Path $ZedTarget "keymap.json")

# ---------------------------------------------------------
# 4. Antigravity
# ---------------------------------------------------------
Write-Host "`nConfiguring Antigravity..."
$AntigravityTarget = Join-Path $env:LOCALAPPDATA "antigravity"
Install-Symlink -SourcePath (Join-Path $RepoDir "antigravity") -TargetPath $AntigravityTarget

# ---------------------------------------------------------
# 5. WebStorm (JetBrains)
# ---------------------------------------------------------
Write-Host "`nConfiguring WebStorm..."
$JetBrainsDir = Join-Path $env:APPDATA "JetBrains"
if (Test-Path $JetBrainsDir) {
    $WebStormDirs = Get-ChildItem -Path $JetBrainsDir -Filter "WebStorm*" -Directory
    foreach ($Dir in $WebStormDirs) {
        # Note: .ideavimrc usually lives in the Windows user profile root
        Install-Symlink -SourcePath (Join-Path $RepoDir "webstorm\.ideavimrc") -TargetPath (Join-Path $env:USERPROFILE ".ideavimrc")
        Write-Host "  Applied WebStorm baseline to $($Dir.Name)" -ForegroundColor Green
    }
} else {
    Write-Host "  No JetBrains directory found. Skipping." -ForegroundColor DarkGray
}

# ---------------------------------------------------------
# 6. Android Studio
# ---------------------------------------------------------
Write-Host "`nConfiguring Android Studio..."
$GoogleDir = Join-Path $env:LOCALAPPDATA "Google"
if (Test-Path $GoogleDir) {
    $StudioDirs = Get-ChildItem -Path $GoogleDir -Filter "AndroidStudio*" -Directory
    foreach ($Dir in $StudioDirs) {
        Install-Symlink -SourcePath (Join-Path $RepoDir "android-studio\keymaps") -TargetPath (Join-Path $Dir.FullName "keymaps")
        Install-Symlink -SourcePath (Join-Path $RepoDir "android-studio\codestyles") -TargetPath (Join-Path $Dir.FullName "codestyles")
        Write-Host "  Applied Android Studio baseline to $($Dir.Name)" -ForegroundColor Green
    }
} else {
    Write-Host "  No Android Studio directory found. Skipping." -ForegroundColor DarkGray
}

Write-Host "`nSync complete! Your monolithic editor environment is ready." -ForegroundColor Cyan