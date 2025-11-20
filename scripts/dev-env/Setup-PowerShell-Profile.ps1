# =============================================================================
# Setup-PowerShell-Profile.ps1
# PowerShell Profile Unification - Based on DEBUG2.md
# =============================================================================

#Requires -Version 7

$ErrorActionPreference = "Stop"

Write-Host "==================================================" -ForegroundColor Cyan
Write-Host "AbeOS PowerShell Profile Unification" -ForegroundColor Cyan
Write-Host "==================================================" -ForegroundColor Cyan
Write-Host ""

function Log-Info {
    param([string]$Message)
    Write-Host "[INFO] $Message" -ForegroundColor Blue
}

function Log-Success {
    param([string]$Message)
    Write-Host "[SUCCESS] $Message" -ForegroundColor Green
}

function Log-Warning {
    param([string]$Message)
    Write-Host "[WARNING] $Message" -ForegroundColor Yellow
}

function Log-Error {
    param([string]$Message)
    Write-Host "[ERROR] $Message" -ForegroundColor Red
}

# Determine AbeOS core profile location
$AbeosCoreProfile = "C:\AbeOS\configs\core\terminal\abeos.pwsh.profile.ps1"

if (-not (Test-Path $AbeosCoreProfile)) {
    Log-Error "AbeOS core profile not found at: $AbeosCoreProfile"
    exit 1
}

Log-Success "Found AbeOS core profile: $AbeosCoreProfile"

# Ensure Claude CLI is in PATH
$ClaudePath = "$env:USERPROFILE\.local\bin"
Log-Info "Checking Claude CLI path: $ClaudePath"

if (-not (Test-Path "$ClaudePath\claude.exe")) {
    Log-Warning "Claude CLI not found at: $ClaudePath\claude.exe"
    Log-Info "Claude CLI may need to be reinstalled"
} else {
    Log-Success "Claude CLI found"
}

# Add Claude path to USER PATH if missing
$UserPath = [Environment]::GetEnvironmentVariable("Path", "User")
if ($UserPath -notlike "*$ClaudePath*") {
    Log-Info "Adding Claude path to USER PATH..."
    $NewPath = $UserPath + ";" + $ClaudePath
    [Environment]::SetEnvironmentVariable("Path", $NewPath, "User")
    Log-Success "Claude path added to USER PATH"

    # Reload PATH for current session
    $env:Path = [System.Environment]::GetEnvironmentVariable("Path", "User") + ";" +
                [System.Environment]::GetEnvironmentVariable("Path", "Machine")
} else {
    Log-Success "Claude path already in USER PATH"
}

# Define all PowerShell profile locations
$ProfileLocations = @(
    # User profiles (non-admin)
    @{
        Path = "$env:USERPROFILE\OneDrive\Documents\PowerShell\profile.ps1"
        Description = "User CurrentUserAllHosts (OneDrive)"
        RequiresAdmin = $false
    },
    @{
        Path = "$env:USERPROFILE\OneDrive\Documents\PowerShell\Microsoft.PowerShell_profile.ps1"
        Description = "User CurrentUserCurrentHost (OneDrive)"
        RequiresAdmin = $false
    },
    @{
        Path = "$env:USERPROFILE\OneDrive\Documents\PowerShell\Microsoft.VSCode_profile.ps1"
        Description = "VS Code Profile (OneDrive)"
        RequiresAdmin = $false
    },
    # AllUsers profiles (require admin)
    @{
        Path = "$env:ProgramFiles\PowerShell\7\profile.ps1"
        Description = "AllUsers AllHosts"
        RequiresAdmin = $true
    },
    @{
        Path = "$env:ProgramFiles\PowerShell\7\Microsoft.PowerShell_profile.ps1"
        Description = "AllUsers CurrentHost"
        RequiresAdmin = $true
    },
    @{
        Path = "$env:ProgramFiles\PowerShell\7\Microsoft.VSCode_profile.ps1"
        Description = "AllUsers VS Code"
        RequiresAdmin = $true
    }
)

# Unified profile loader content
$LoaderContent = @"
# AbeOS PowerShell Profile Loader
# This file sources the unified AbeOS PowerShell configuration
. "$AbeosCoreProfile"
"@

# Check if running as admin
$IsAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

if (-not $IsAdmin) {
    Log-Warning "Not running as Administrator"
    Log-Info "Will only configure user profiles (non-admin)"
}

# Backup and create/update profiles
$ProfilesConfigured = 0
$ProfilesSkipped = 0

foreach ($ProfileInfo in $ProfileLocations) {
    $ProfilePath = $ProfileInfo.Path
    $Description = $ProfileInfo.Description
    $RequiresAdmin = $ProfileInfo.RequiresAdmin

    # Skip admin profiles if not running as admin
    if ($RequiresAdmin -and -not $IsAdmin) {
        Log-Warning "Skipping $Description (requires admin)"
        $ProfilesSkipped++
        continue
    }

    Log-Info "Configuring: $Description"
    Log-Info "  Path: $ProfilePath"

    # Create parent directory if it doesn't exist
    $ProfileDir = Split-Path -Parent $ProfilePath
    if (-not (Test-Path $ProfileDir)) {
        try {
            New-Item -Path $ProfileDir -ItemType Directory -Force | Out-Null
            Log-Info "  Created directory: $ProfileDir"
        } catch {
            Log-Error "  Failed to create directory: $_"
            continue
        }
    }

    # Backup existing profile
    if (Test-Path $ProfilePath) {
        $BackupPath = "$ProfilePath.backup.$(Get-Date -Format 'yyyyMMddHHmmss')"
        try {
            Copy-Item -Path $ProfilePath -Destination $BackupPath -Force
            Log-Info "  Backed up to: $BackupPath"
        } catch {
            Log-Warning "  Failed to backup: $_"
        }
    }

    # Write unified loader
    try {
        Set-Content -Path $ProfilePath -Value $LoaderContent -Force -Encoding UTF8
        Log-Success "  Configured successfully"
        $ProfilesConfigured++
    } catch {
        Log-Error "  Failed to configure: $_"
    }
}

# Reload PATH in current session
Log-Info "Reloading environment PATH..."
$env:Path = [System.Environment]::GetEnvironmentVariable("Path", "User") + ";" +
            [System.Environment]::GetEnvironmentVariable("Path", "Machine")

# Validate Claude CLI is now accessible
Log-Info "Validating Claude CLI..."
$ClaudeAvailable = $false
try {
    $ClaudeVersion = & claude --version 2>&1
    if ($LASTEXITCODE -eq 0) {
        Log-Success "Claude CLI is accessible: $ClaudeVersion"
        $ClaudeAvailable = $true
    }
} catch {
    Log-Warning "Claude CLI not found in PATH"
    Log-Info "You may need to restart your terminal or reinstall Claude CLI"
}

# Verify PATH contains Claude folder
Log-Info "Verifying PATH contains Claude folder..."
$PathEntries = $env:Path -split ";"
$ClaudeInPath = $PathEntries | Where-Object { $_ -like "*\.local\bin*" }

if ($ClaudeInPath) {
    Log-Success "Claude path found in PATH: $ClaudeInPath"
} else {
    Log-Warning "Claude path not found in current PATH"
    Log-Info "You may need to restart your terminal"
}

Write-Host ""
Write-Host "==================================================" -ForegroundColor Cyan
Log-Success "PowerShell profile unification complete!"
Write-Host "==================================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Configuration summary:" -ForegroundColor White
Write-Host "  ✓ Profiles configured: $ProfilesConfigured" -ForegroundColor Green
if ($ProfilesSkipped -gt 0) {
    Write-Host "  ⚠ Profiles skipped: $ProfilesSkipped (run as admin to configure)" -ForegroundColor Yellow
}
Write-Host "  ✓ All profiles now load: $AbeosCoreProfile" -ForegroundColor Green
Write-Host "  ✓ Claude CLI path added to USER PATH" -ForegroundColor Green
if ($ClaudeAvailable) {
    Write-Host "  ✓ Claude CLI verified and working" -ForegroundColor Green
} else {
    Write-Host "  ⚠ Claude CLI not yet accessible (restart terminal)" -ForegroundColor Yellow
}
Write-Host ""
Write-Host "Profile locations configured:" -ForegroundColor White
foreach ($ProfileInfo in $ProfileLocations) {
    if ($ProfileInfo.RequiresAdmin -and -not $IsAdmin) {
        Write-Host "  ⚠ $($ProfileInfo.Description) - SKIPPED (run as admin)" -ForegroundColor Yellow
    } else {
        if (Test-Path $ProfileInfo.Path) {
            Write-Host "  ✓ $($ProfileInfo.Description)" -ForegroundColor Green
        } else {
            Write-Host "  ✗ $($ProfileInfo.Description) - FAILED" -ForegroundColor Red
        }
    }
}
Write-Host ""
Write-Host "Next steps:" -ForegroundColor Yellow
Write-Host "  1. RESTART your PowerShell terminal" -ForegroundColor Yellow
Write-Host "  2. Test in Windows Terminal: your custom profile should load" -ForegroundColor Yellow
Write-Host "  3. Test in VS Code: your custom profile should load" -ForegroundColor Yellow
Write-Host "  4. Test Claude CLI: claude --help" -ForegroundColor Yellow
if ($ProfilesSkipped -gt 0) {
    Write-Host "  5. Re-run this script as Administrator to configure AllUsers profiles" -ForegroundColor Yellow
}
Write-Host ""
Write-Host "All PowerShell hosts now share the same configuration!" -ForegroundColor Green
Write-Host "Edit the core profile at: $AbeosCoreProfile" -ForegroundColor Cyan
Write-Host ""
