<#
.SYNOPSIS
    Editor Configuration Fetch & Backup Script
.DESCRIPTION
    Copies the latest editor configurations from Windows system paths into this Git repository,
    then automatically commits and pushes the changes.
#>

$ErrorActionPreference = 'Stop'
$RepoDir = $PSScriptRoot

# Navigate to the repository root
Set-Location -Path $RepoDir

Write-Host "Starting configuration fetch from system locations..." -ForegroundColor Cyan

# ---------------------------------------------------------
# Helper Function: Safely copy files or directories
# ---------------------------------------------------------
function Fetch-Config {
    param (
        [string]$Source,
        [string]$Destination
    )

    if (-not (Test-Path $Source)) {
        Write-Host "  [SKIP] Not found on system: $Source" -ForegroundColor DarkGray
        return
    }

    $IsFile = (Get-Item $Source) -is [System.IO.FileInfo]

    if ($IsFile) {
        $DestDir = Split-Path $Destination -Parent
        if (-not (Test-Path $DestDir)) { New-Item -ItemType Directory -Force -Path $DestDir | Out-Null }
        
        Copy-Item -Path $Source -Destination $Destination -Force
        Write-Host "  [FETCHED] $(Split-Path $Source -Leaf)" -ForegroundColor Green
    } else {
        if (-not (Test-Path $Destination)) { New-Item -ItemType Directory -Force -Path $Destination | Out-Null }
        
        # Copy folder contents
        Copy-Item -Path "$Source\*" -Destination $Destination -Recurse -Force
        Write-Host "  [FETCHED] $(Split-Path $Source -Leaf)\ (Directory)" -ForegroundColor Green
    }
}

# ---------------------------------------------------------
# 1. Fetch VS Code
# ---------------------------------------------------------
Write-Host "`nFetching VS Code..."
$VsCodeSource = Join-Path $env:APPDATA "Code\User"
Fetch-Config -Source (Join-Path $VsCodeSource "settings.json") -Destination (Join-Path $RepoDir "vscode\settings.json")
Fetch-Config -Source (Join-Path $VsCodeSource "keybindings.json") -Destination (Join-Path $RepoDir "vscode\keybindings.json")

# ---------------------------------------------------------
# 2. Fetch Neovim
# ---------------------------------------------------------
Write-Host "`nFetching Neovim..."
Fetch-Config -Source (Join-Path $env:LOCALAPPDATA "nvim") -Destination (Join-Path $RepoDir "nvim")

# ---------------------------------------------------------
# 3. Fetch Zed
# ---------------------------------------------------------
Write-Host "`nFetching Zed..."
$ZedSource = Join-Path $env:LOCALAPPDATA "Zed"
Fetch-Config -Source (Join-Path $ZedSource "settings.json") -Destination (Join-Path $RepoDir "zed\settings.json")
Fetch-Config -Source (Join-Path $ZedSource "keymap.json") -Destination (Join-Path $RepoDir "zed\keymap.json")

# ---------------------------------------------------------
# 4. Fetch Antigravity
# ---------------------------------------------------------
Write-Host "`nFetching Antigravity..."
Fetch-Config -Source (Join-Path $env:LOCALAPPDATA "antigravity") -Destination (Join-Path $RepoDir "antigravity")

# ---------------------------------------------------------
# 5. Fetch WebStorm / JetBrains
# ---------------------------------------------------------
Write-Host "`nFetching WebStorm..."
# Capturing the global .ideavimrc used by JetBrains IDEs
Fetch-Config -Source (Join-Path $env:USERPROFILE ".ideavimrc") -Destination (Join-Path $RepoDir "webstorm\.ideavimrc")

# ---------------------------------------------------------
# 6. Fetch Android Studio
# ---------------------------------------------------------
Write-Host "`nFetching Android Studio..."
$GoogleDir = Join-Path $env:LOCALAPPDATA "Google"
if (Test-Path $GoogleDir) {
    # Find the most recently modified Android Studio folder to ensure we get the active version
    $LatestStudio = Get-ChildItem -Path $GoogleDir -Filter "AndroidStudio*" -Directory | Sort-Object LastWriteTime -Descending | Select-Object -First 1
    
    if ($LatestStudio) {
        Write-Host "  Using version: $($LatestStudio.Name)" -ForegroundColor DarkGray
        Fetch-Config -Source (Join-Path $LatestStudio.FullName "keymaps") -Destination (Join-Path $RepoDir "android-studio\keymaps")
        Fetch-Config -Source (Join-Path $LatestStudio.FullName "codestyles") -Destination (Join-Path $RepoDir "android-studio\codestyles")
    }
}

# ---------------------------------------------------------
# Git Sync Logic
# ---------------------------------------------------------
Write-Host "`nAnalyzing changes for Git..." -ForegroundColor Cyan

# Check if there are any untracked, modified, or deleted files
$GitStatus = git status --porcelain

if ([string]::IsNullOrWhiteSpace($GitStatus)) {
    Write-Host "Everything is up to date. No changes to commit." -ForegroundColor Green
    exit
}

Write-Host "Changes detected. Staging files..." -ForegroundColor Yellow
git add .

# Generate timestamped commit message
$Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
$CommitMessage = "chore(config): auto-fetch and backup settings [$Timestamp]"

Write-Host "Committing: '$CommitMessage'" -ForegroundColor Yellow
git commit -m $CommitMessage | Out-Null

Write-Host "Pushing to remote repository..." -ForegroundColor Yellow
try {
    git push origin main
    Write-Host "`nBackup complete! Your configs are safely stored in the repository." -ForegroundColor Green
} catch {
    Write-Host "`n[ERROR] Failed to push to remote. Check your network or Git credentials." -ForegroundColor Red
}