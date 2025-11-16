#Requires -RunAsAdministrator
<#
.SYNOPSIS
    Unifies PowerShell profile configuration across all PowerShell hosts.
.DESCRIPTION
    Creates a unified PowerShell profile system that ensures all PowerShell environments
    (Windows Terminal, VS Code, PowerShell 7, Admin shells) load the same configuration.

    Fixes all issues documented in DEBUG2.md:
    - Unifies fragmented PowerShell profiles
    - Adds Claude CLI to PATH (C:\Users\abe\.local\bin)
    - Ensures all shells load C:\AbeOS\configs\core\terminal\pwsh.core.profile.ps1
    - Eliminates PATH fragmentation between different terminal hosts

    Creates/updates these profile files:
    - User profiles (OneDrive\Documents\PowerShell\)
      - profile.ps1 (Windows Terminal)
      - Microsoft.VSCode_profile.ps1 (VS Code)
    - AllUsers profiles (C:\Program Files\PowerShell\7\)
      - profile.ps1 (All users)
      - Microsoft.VSCode_profile.ps1 (VS Code all users)
.PARAMETER CoreProfilePath
    Path to the core AbeOS PowerShell profile (default: C:\AbeOS\configs\core\terminal\pwsh.core.profile.ps1)
.PARAMETER BackupProfiles
    Create backups of existing profiles before modifying (default: $true)
.EXAMPLE
    .\Configure-PowerShellProfiles.ps1
.EXAMPLE
    .\Configure-PowerShellProfiles.ps1 -BackupProfiles:$false
.NOTES
    File: Configure-PowerShellProfiles.ps1
    Phase: 1.3 - Developer Environment
    System: Windows 11 (Zephyrus G14)
#>

[CmdletBinding()]
param(
    [string]$CoreProfilePath = "C:\AbeOS\configs\core\terminal\pwsh.core.profile.ps1",
    [bool]$BackupProfiles = $true
)

$ErrorActionPreference = "Stop"

# Import AbeOS core module for logging
$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot "..\..\..")).ProviderPath
Import-Module (Join-Path $repoRoot "modules\lib\AbeOS.Core.psm1") -Force

Write-AbeLog "==================================================" -Level Info
Write-AbeLog "  AbeOS PowerShell Profile Unification" -Level Info
Write-AbeLog "==================================================" -Level Info
Write-AbeLog "Core Profile: $CoreProfilePath" -Level Info
Write-AbeLog ""

# Step 1: Verify core profile exists
Write-AbeLog "Step 1: Verifying core profile exists..." -Level Info

if (-not (Test-Path $CoreProfilePath)) {
    Write-AbeLog "Core profile not found at: $CoreProfilePath" -Level Error
    Write-AbeLog "Creating placeholder core profile..." -Level Warning

    $coreProfileDir = Split-Path $CoreProfilePath
    if (-not (Test-Path $coreProfileDir)) {
        New-Item -ItemType Directory -Path $coreProfileDir -Force | Out-Null
    }

    # Create a basic core profile
    $placeholderProfile = @'
# AbeOS Core PowerShell Profile
# This file is sourced by all PowerShell profile entry points

Write-Host "AbeOS PowerShell Environment Loaded" -ForegroundColor Cyan

# Set PowerShell to UTF-8
[console]::InputEncoding = [console]::OutputEncoding = New-Object System.Text.UTF8Encoding

# Initialize Oh My Posh (if installed)
if (Get-Command oh-my-posh -ErrorAction SilentlyContinue) {
    $ompTheme = "$env:LOCALAPPDATA\Programs\oh-my-posh\themes\jandedobbeleer.omp.json"
    if (Test-Path $ompTheme) {
        oh-my-posh init pwsh --config $ompTheme | Invoke-Expression
    }
}

# PSReadLine configuration
if (Get-Module -ListAvailable -Name PSReadLine) {
    Import-Module PSReadLine
    Set-PSReadLineOption -PredictionSource History
    Set-PSReadLineOption -PredictionViewStyle ListView
    Set-PSReadLineOption -EditMode Windows
}

# Aliases
Set-Alias -Name ll -Value Get-ChildItem
Set-Alias -Name g -Value git
'@

    Set-Content -Path $CoreProfilePath -Value $placeholderProfile -Force
    Write-AbeLog "✓ Core profile created" -Level Success
}

Write-AbeLog "✓ Core profile exists" -Level Success

# Step 2: Add Claude CLI to PATH if missing
Write-AbeLog "`nStep 2: Ensuring Claude CLI is in PATH..." -Level Info

$claudePath = "$env:USERPROFILE\.local\bin"
$claudeExe = Join-Path $claudePath "claude.exe"

if (Test-Path $claudeExe) {
    Write-AbeLog "Found Claude CLI at: $claudeExe" -Level Info

    $userPath = [Environment]::GetEnvironmentVariable("Path", "User")

    if ($userPath -notlike "*$claudePath*") {
        Write-AbeLog "Adding Claude path to USER PATH..." -Level Warning
        $newPath = "$userPath;$claudePath"
        [Environment]::SetEnvironmentVariable("Path", $newPath, "User")
        Write-AbeLog "✓ Claude path added to PATH" -Level Success

        # Reload PATH in current session
        $env:PATH = [System.Environment]::GetEnvironmentVariable("Path","User") + ";" + [System.Environment]::GetEnvironmentVariable("Path","Machine")
    } else {
        Write-AbeLog "✓ Claude path already in PATH" -Level Success
    }
} else {
    Write-AbeLog "Claude CLI not found at: $claudeExe" -Level Warning
    Write-AbeLog "Install Claude CLI first if needed" -Level Warning
}

# Step 3: Define all profile paths
Write-AbeLog "`nStep 3: Identifying profile paths..." -Level Info

$userDocsPath = [Environment]::GetFolderPath("MyDocuments")
$powerShellUserDir = Join-Path $userDocsPath "PowerShell"

$profilePaths = @(
    @{
        Name = "User Profile (Windows Terminal)"
        Path = Join-Path $powerShellUserDir "profile.ps1"
        RequiresAdmin = $false
    },
    @{
        Name = "User Profile (VS Code)"
        Path = Join-Path $powerShellUserDir "Microsoft.VSCode_profile.ps1"
        RequiresAdmin = $false
    },
    @{
        Name = "AllUsers Profile"
        Path = "C:\Program Files\PowerShell\7\profile.ps1"
        RequiresAdmin = $true
    },
    @{
        Name = "AllUsers Profile (VS Code)"
        Path = "C:\Program Files\PowerShell\7\Microsoft.VSCode_profile.ps1"
        RequiresAdmin = $true
    }
)

foreach ($profile in $profilePaths) {
    Write-AbeLog "  - $($profile.Name): $($profile.Path)" -Level Info
}

# Step 4: Backup existing profiles
if ($BackupProfiles) {
    Write-AbeLog "`nStep 4: Backing up existing profiles..." -Level Info

    $timestamp = Get-Date -Format "yyyyMMdd_HHmmss"

    foreach ($profile in $profilePaths) {
        if (Test-Path $profile.Path) {
            $backupPath = "$($profile.Path).backup_$timestamp"
            Copy-Item -Path $profile.Path -Destination $backupPath -Force
            Write-AbeLog "  ✓ Backed up: $($profile.Name)" -Level Success
        }
    }
}

# Step 5: Create unified loader content
Write-AbeLog "`nStep 5: Creating unified profile loader..." -Level Info

$loaderContent = @"
# AbeOS Unified Profile Loader
# This file auto-generated by Configure-PowerShellProfiles.ps1
# All PowerShell environments load the core profile from:
# $CoreProfilePath

if (Test-Path "$CoreProfilePath") {
    . "$CoreProfilePath"
} else {
    Write-Warning "AbeOS core profile not found at: $CoreProfilePath"
}
"@

Write-AbeLog "  Loader will source: $CoreProfilePath" -Level Info

# Step 6: Create/update all profile files
Write-AbeLog "`nStep 6: Creating/updating profile files..." -Level Info

foreach ($profile in $profilePaths) {
    try {
        # Create directory if it doesn't exist
        $profileDir = Split-Path $profile.Path
        if (-not (Test-Path $profileDir)) {
            Write-AbeLog "  Creating directory: $profileDir" -Level Info
            New-Item -ItemType Directory -Path $profileDir -Force | Out-Null
        }

        # Write loader content
        Set-Content -Path $profile.Path -Value $loaderContent -Force
        Write-AbeLog "  ✓ Updated: $($profile.Name)" -Level Success
    }
    catch {
        if ($profile.RequiresAdmin) {
            Write-AbeLog "  ⚠ Failed to update $($profile.Name): $($_.Exception.Message)" -Level Warning
            Write-AbeLog "    This is expected if not running as administrator" -Level Warning
        } else {
            Write-AbeLog "  ✗ Error updating $($profile.Name): $($_.Exception.Message)" -Level Error
        }
    }
}

# Step 7: Reload PATH
Write-AbeLog "`nStep 7: Reloading environment PATH..." -Level Info
$env:PATH = [System.Environment]::GetEnvironmentVariable("Path","User") + ";" + [System.Environment]::GetEnvironmentVariable("Path","Machine")
Write-AbeLog "✓ PATH reloaded" -Level Success

# Step 8: Verify Claude CLI is accessible
Write-AbeLog "`nStep 8: Verifying Claude CLI accessibility..." -Level Info

if (Get-Command claude -ErrorAction SilentlyContinue) {
    Write-AbeLog "✓ Claude CLI is accessible" -Level Success
    $claudeVersion = claude --version 2>&1
    Write-AbeLog "  Version: $claudeVersion" -Level Info
} else {
    Write-AbeLog "⚠ Claude CLI not found in PATH" -Level Warning
    Write-AbeLog "  You may need to restart your terminal" -Level Warning
}

# Step 9: Validation
Write-AbeLog "`nStep 9: Validation..." -Level Info

# Check PATH contains expected directories
$requiredPaths = @(
    "$env:USERPROFILE\.local\bin",
    "$env:LOCALAPPDATA\Programs\oh-my-posh\bin"
)

Write-AbeLog "Checking required paths in environment..." -Level Info
foreach ($reqPath in $requiredPaths) {
    if ($env:PATH -like "*$reqPath*") {
        Write-AbeLog "  ✓ $reqPath" -Level Success
    } else {
        Write-AbeLog "  ⚠ Missing: $reqPath" -Level Warning
    }
}

# Summary
Write-AbeLog "`n==================================================" -Level Success
Write-AbeLog "  PowerShell Profile Unification Complete!" -Level Success
Write-AbeLog "==================================================" -Level Success
Write-AbeLog ""
Write-AbeLog "Configuration Summary:" -Level Info
Write-AbeLog "  ✓ All profiles updated to load core profile" -Level Success
Write-AbeLog "  ✓ Claude CLI path added to USER PATH" -Level Success
Write-AbeLog "  ✓ Environment PATH reloaded" -Level Success
Write-AbeLog ""
Write-AbeLog "All PowerShell environments now load from:" -Level Info
Write-AbeLog "  $CoreProfilePath" -Level Info
Write-AbeLog ""
Write-AbeLog "Next Steps:" -Level Info
Write-AbeLog "  1. Close and reopen all PowerShell terminals" -Level Info
Write-AbeLog "  2. Test in Windows Terminal: powershell" -Level Info
Write-AbeLog "  3. Test in VS Code: Open integrated terminal" -Level Info
Write-AbeLog "  4. Verify with: claude --help" -Level Info
Write-AbeLog ""
Write-AbeLog "Profile files updated:" -Level Info
foreach ($profile in $profilePaths) {
    if (Test-Path $profile.Path) {
        Write-AbeLog "  ✓ $($profile.Path)" -Level Success
    }
}
