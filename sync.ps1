<#
.SYNOPSIS
    Editor Configuration Auto-Sync
.DESCRIPTION
    Checks for changes in the configuration repository, stages them, 
    creates a timestamped commit, and pushes to the remote origin.
#>

$ErrorActionPreference = 'Stop'
$RepoDir = $PSScriptRoot

# Navigate to the repository root just in case the script is called from elsewhere
Set-Location -Path $RepoDir

Write-Host "Checking for configuration changes..." -ForegroundColor Cyan

# Check if there are any changes (untracked, modified, or deleted)
$GitStatus = git status --porcelain

if ([string]::IsNullOrWhiteSpace($GitStatus)) {
    Write-Host "Everything is up to date. No changes to commit." -ForegroundColor Green
    exit
}

# Changes exist; proceed with sync
Write-Host "Changes detected. Staging files..." -ForegroundColor Yellow
git add .

# Generate a clean timestamp for the commit message
$Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
$CommitMessage = "chore(config): auto-sync environment settings [$Timestamp]"

Write-Host "Committing changes: '$CommitMessage'" -ForegroundColor Yellow
git commit -m $CommitMessage | Out-Null

Write-Host "Pushing to remote repository..." -ForegroundColor Yellow
try {
    git push origin main # Change 'main' to 'master' if you are using an older repo structure
    Write-Host "`nSync complete! Your configurations are safely backed up." -ForegroundColor Green
} catch {
    Write-Host "`n[ERROR] Failed to push to remote. Check your network or Git credentials." -ForegroundColor Red
}