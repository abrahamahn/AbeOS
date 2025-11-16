#Requires -RunAsAdministrator
<#
.SYNOPSIS
    Master script to install and configure AbeOS developer environment (Phase 1.3).
.DESCRIPTION
    Orchestrates the complete developer environment setup for Windows 11 on Zephyrus G14.

    Execution order:
    1. Remove bloated packages
    2. Repair system PATH
    3. Configure PowerShell profiles
    4. Install WSL2 with Ubuntu 22.04
    5. Install Node.js via NVM (inside WSL)
    6. Install VS Code
    7. Verify installation

    Fixes all issues documented in DEBUG.md, DEBUG2.md, DEBUG3.md, and DEBUG4.md.
.PARAMETER SkipBloatRemoval
    Skip removing bloated packages
.PARAMETER SkipPATHRepair
    Skip PATH cleanup and rebuild
.PARAMETER SkipWSL
    Skip WSL2 installation
.PARAMETER SkipNodeJS
    Skip Node.js installation
.PARAMETER SkipVSCode
    Skip VS Code installation
.EXAMPLE
    .\Install-DevEnvironment.ps1
.EXAMPLE
    .\Install-DevEnvironment.ps1 -SkipBloatRemoval -SkipPATHRepair
.NOTES
    File: Install-DevEnvironment.ps1
    Phase: 1.3 - Developer Environment
    System: Windows 11 (Zephyrus G14)

    Prerequisites:
    - Windows 11 (or Windows 10 version 2004+)
    - Administrator privileges
    - Internet connection
    - BIOS virtualization enabled

    Duration: ~30-60 minutes depending on internet speed
#>

[CmdletBinding()]
param(
    [switch]$SkipBloatRemoval,
    [switch]$SkipPATHRepair,
    [switch]$SkipWSL,
    [switch]$SkipNodeJS,
    [switch]$SkipVSCode
)

$ErrorActionPreference = "Stop"

# Import AbeOS core module
$scriptRoot = $PSScriptRoot
$repoRoot = (Resolve-Path (Join-Path $scriptRoot "..\..\..")).ProviderPath
Import-Module (Join-Path $repoRoot "modules\lib\AbeOS.Core.psm1") -Force

Write-AbeLog "==================================================================" -Level Info
Write-AbeLog "  AbeOS Developer Environment Installation (Phase 1.3)" -Level Info
Write-AbeLog "==================================================================" -Level Info
Write-AbeLog "System: Windows 11 (Zephyrus G14)" -Level Info
Write-AbeLog "Date: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" -Level Info
Write-AbeLog ""
Write-AbeLog "This will install and configure:" -Level Info
Write-AbeLog "  - WSL2 with Ubuntu 22.04" -Level Info
Write-AbeLog "  - Node.js (via NVM)" -Level Info
Write-AbeLog "  - VS Code" -Level Info
Write-AbeLog "  - PowerShell profile unification" -Level Info
Write-AbeLog "  - Clean system PATH" -Level Info
Write-AbeLog ""
Write-AbeLog "Duration: ~30-60 minutes" -Level Warning
Write-AbeLog "==================================================================" -Level Info
Write-AbeLog ""

$startTime = Get-Date

# Confirmation
$response = Read-Host "Continue with installation? (Y/N)"
if ($response -ne "Y") {
    Write-AbeLog "Installation cancelled by user" -Level Warning
    exit 0
}

Write-AbeLog ""

# Track errors
$errors = @()

# Step 1: Remove bloated packages
if (-not $SkipBloatRemoval) {
    Write-AbeLog "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -Level Info
    Write-AbeLog "STEP 1: Removing bloated packages" -Level Info
    Write-AbeLog "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -Level Info

    try {
        & (Join-Path $scriptRoot "Remove-BloatPackages.ps1")
        Write-AbeLog "✓ Bloat removal complete" -Level Success
    } catch {
        $errors += "Bloat removal failed: $_"
        Write-AbeLog "✗ Error: $_" -Level Error
    }
} else {
    Write-AbeLog "Skipping bloat removal (as requested)" -Level Warning
}

Write-AbeLog ""

# Step 2: Repair system PATH
if (-not $SkipPATHRepair) {
    Write-AbeLog "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -Level Info
    Write-AbeLog "STEP 2: Repairing system PATH" -Level Info
    Write-AbeLog "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -Level Info

    try {
        & (Join-Path $scriptRoot "Repair-SystemPATH.ps1")
        Write-AbeLog "✓ PATH repair complete" -Level Success
    } catch {
        $errors += "PATH repair failed: $_"
        Write-AbeLog "✗ Error: $_" -Level Error
    }
} else {
    Write-AbeLog "Skipping PATH repair (as requested)" -Level Warning
}

Write-AbeLog ""

# Step 3: Configure PowerShell profiles
Write-AbeLog "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -Level Info
Write-AbeLog "STEP 3: Configuring PowerShell profiles" -Level Info
Write-AbeLog "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -Level Info

try {
    & (Join-Path $scriptRoot "Configure-PowerShellProfiles.ps1")
    Write-AbeLog "✓ PowerShell profiles configured" -Level Success
} catch {
    $errors += "PowerShell profile configuration failed: $_"
    Write-AbeLog "✗ Error: $_" -Level Error
}

Write-AbeLog ""

# Step 4: Install WSL2
if (-not $SkipWSL) {
    Write-AbeLog "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -Level Info
    Write-AbeLog "STEP 4: Installing WSL2" -Level Info
    Write-AbeLog "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -Level Info

    try {
        & (Join-Path $scriptRoot "Install-WSL.ps1")
        Write-AbeLog "✓ WSL2 installation complete" -Level Success
    } catch {
        $errors += "WSL2 installation failed: $_"
        Write-AbeLog "✗ Error: $_" -Level Error
        Write-AbeLog "Note: If reboot is required, run this script again after reboot" -Level Warning
    }
} else {
    Write-AbeLog "Skipping WSL2 installation (as requested)" -Level Warning
}

Write-AbeLog ""

# Step 5: Install Node.js via NVM
if (-not $SkipNodeJS -and -not $SkipWSL) {
    Write-AbeLog "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -Level Info
    Write-AbeLog "STEP 5: Installing Node.js via NVM" -Level Info
    Write-AbeLog "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -Level Info

    try {
        & (Join-Path $scriptRoot "Install-NodeJS.ps1")
        Write-AbeLog "✓ Node.js installation complete" -Level Success
    } catch {
        $errors += "Node.js installation failed: $_"
        Write-AbeLog "✗ Error: $_" -Level Error
    }
} else {
    if ($SkipNodeJS) {
        Write-AbeLog "Skipping Node.js installation (as requested)" -Level Warning
    } else {
        Write-AbeLog "Skipping Node.js installation (WSL not installed)" -Level Warning
    }
}

Write-AbeLog ""

# Step 6: Install VS Code
if (-not $SkipVSCode) {
    Write-AbeLog "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -Level Info
    Write-AbeLog "STEP 6: Installing VS Code" -Level Info
    Write-AbeLog "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -Level Info

    try {
        & (Join-Path $scriptRoot "Install-VSCode.ps1")
        Write-AbeLog "✓ VS Code installation complete" -Level Success
    } catch {
        $errors += "VS Code installation failed: $_"
        Write-AbeLog "✗ Error: $_" -Level Error
    }
} else {
    Write-AbeLog "Skipping VS Code installation (as requested)" -Level Warning
}

Write-AbeLog ""

# Step 7: Final verification
Write-AbeLog "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -Level Info
Write-AbeLog "STEP 7: Final verification" -Level Info
Write-AbeLog "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -Level Info

$verificationTools = @(
    @{ Name = "git"; Description = "Git version control" },
    @{ Name = "code"; Description = "VS Code CLI" },
    @{ Name = "wsl"; Description = "WSL command" },
    @{ Name = "oh-my-posh"; Description = "Oh My Posh" }
)

Write-AbeLog "`nVerifying tools..." -Level Info
foreach ($tool in $verificationTools) {
    if (Get-Command $tool.Name -ErrorAction SilentlyContinue) {
        Write-AbeLog "  ✓ $($tool.Description)" -Level Success
    } else {
        Write-AbeLog "  ✗ $($tool.Description) (not found)" -Level Warning
    }
}

# Verify WSL
if (-not $SkipWSL) {
    Write-AbeLog "`nVerifying WSL..." -Level Info
    $wslList = wsl -l -v 2>&1 | Out-String
    if ($wslList -match "Ubuntu") {
        Write-AbeLog "  ✓ Ubuntu installed in WSL" -Level Success
    } else {
        Write-AbeLog "  ✗ Ubuntu not found in WSL" -Level Warning
    }
}

# Calculate duration
$endTime = Get-Date
$duration = $endTime - $startTime

# Final summary
Write-AbeLog ""
Write-AbeLog "==================================================================" -Level Success
Write-AbeLog "  Installation Complete!" -Level Success
Write-AbeLog "==================================================================" -Level Success
Write-AbeLog ""
Write-AbeLog "Duration: $($duration.ToString('hh\:mm\:ss'))" -Level Info
Write-AbeLog ""

if ($errors.Count -eq 0) {
    Write-AbeLog "✓ All steps completed successfully!" -Level Success
} else {
    Write-AbeLog "⚠ Some steps encountered errors:" -Level Warning
    foreach ($error in $errors) {
        Write-AbeLog "  - $error" -Level Warning
    }
}

Write-AbeLog ""
Write-AbeLog "Next Steps:" -Level Info
Write-AbeLog "  1. RESTART your computer to apply all changes" -Level Warning
Write-AbeLog "  2. After restart, open PowerShell and verify:" -Level Info
Write-AbeLog "     - git --version" -Level Info
Write-AbeLog "     - code --version" -Level Info
Write-AbeLog "     - wsl --version" -Level Info
Write-AbeLog "  3. Enter WSL and verify Node.js:" -Level Info
Write-AbeLog "     - wsl" -Level Info
Write-AbeLog "     - source ~/.bashrc" -Level Info
Write-AbeLog "     - node --version" -Level Info
Write-AbeLog "     - npm --version" -Level Info
Write-AbeLog "  4. Continue with Phase 2: Music Production setup" -Level Info
Write-AbeLog ""
Write-AbeLog "Documentation:" -Level Info
Write-AbeLog "  - DEBUG.md - Issues encountered" -Level Info
Write-AbeLog "  - DEBUG2.md - PowerShell profile fixes" -Level Info
Write-AbeLog "  - DEBUG3.md - WSL and Node.js fixes" -Level Info
Write-AbeLog "  - DEBUG4.md - PATH and VS Code fixes" -Level Info
Write-AbeLog "==================================================================" -Level Info
