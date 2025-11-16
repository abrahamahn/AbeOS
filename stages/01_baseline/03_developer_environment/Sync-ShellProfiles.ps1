#Requires -RunAsAdministrator
<#
.SYNOPSIS
    Syncs shell profile entrypoints so they dot-source the AbeOS-managed configs.
.DESCRIPTION
    Copies the PowerShell stub in configs/core/terminal into the current $PROFILE path,
    and updates the WSL ~/.bashrc to source the AbeOS bash profile stub.
.PARAMETER SkipWSL
    Skip updating the WSL bash profile.
.PARAMETER WSLBashPath
    Custom bashrc path inside WSL (default: ~/.bashrc).
.EXAMPLE
    .\Sync-ShellProfiles.ps1
.EXAMPLE
    .\Sync-ShellProfiles.ps1 -SkipWSL
.NOTES
    Run this whenever the AbeOS repo moves or after wiping user profiles.
#>

param(
    [switch]$SkipWSL,
    [string]$WSLBashPath = "~/.bashrc"
)

$ErrorActionPreference = "Stop"
$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot "..\..\..")).ProviderPath

$powProfileSource = Join-Path $repoRoot "configs\core\terminal\Microsoft.PowerShell_profile.ps1"
if (-not (Test-Path $powProfileSource)) {
    throw "PowerShell profile stub not found at $powProfileSource"
}

$targetProfile = $PROFILE
Write-Host "Syncing PowerShell profile..." -ForegroundColor Cyan
Write-Host "  Source: $powProfileSource" -ForegroundColor DarkGray
Write-Host "  Target: $targetProfile" -ForegroundColor DarkGray

$targetDir = Split-Path $targetProfile
if (-not (Test-Path $targetDir)) {
    New-Item -ItemType Directory -Path $targetDir -Force | Out-Null
}
Copy-Item -Path $powProfileSource -Destination $targetProfile -Force
Write-Host "  ✓ PowerShell profile updated" -ForegroundColor Green

if (-not $SkipWSL) {
    $bashStub = "/mnt/c/AbeOS/configs/core/terminal/bashrc"
    Write-Host "`nSyncing WSL bash profile..." -ForegroundColor Cyan
    Write-Host "  Source: $bashStub" -ForegroundColor DarkGray
    Write-Host "  Target: $WSLBashPath" -ForegroundColor DarkGray

    $bashCommand = "cp $bashStub $WSLBashPath"
    $result = & wsl.exe bash -lc $bashCommand 2>&1
    if ($LASTEXITCODE -ne 0) {
        Write-Warning "WSL copy failed: $result"
    } else {
        Write-Host "  ✓ Bash profile updated. Run 'source $WSLBashPath' inside WSL to reload." -ForegroundColor Green
    }
}

Write-Host "`nDone. Restart shells or run 'powerShell -File $PROFILE' / 'source ~/.bashrc' to reload." -ForegroundColor Cyan
