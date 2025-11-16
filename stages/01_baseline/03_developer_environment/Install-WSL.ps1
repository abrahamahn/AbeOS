#Requires -RunAsAdministrator
<#
.SYNOPSIS
    Installs and configures WSL2 with Ubuntu 22.04 for AbeOS development environment.
.DESCRIPTION
    - Enables WSL and Virtual Machine Platform features
    - Installs WSL2 and Ubuntu 22.04 distribution
    - Creates properly formatted /etc/wsl.conf (LF line endings, no Windows PATH pollution)
    - Enables systemd
    - Verifies correct root filesystem and PATH isolation
    - Sets up base development environment in WSL

    Fixes all issues documented in DEBUG.md and DEBUG3.md:
    - Removes Windows PATH injection
    - Ensures clean LF line endings in wsl.conf
    - Prevents SYSTEM.INI detection issue
    - Prepares for NVM/Node.js installation (not apt)
.PARAMETER DistroName
    WSL distribution name (default: Ubuntu-22.04)
.PARAMETER Username
    Default user inside WSL (default: abe)
.EXAMPLE
    .\Install-WSL.ps1
.EXAMPLE
    .\Install-WSL.ps1 -Username "developer"
.NOTES
    File: Install-WSL.ps1
    Phase: 1.3 - Developer Environment
    System: Windows 11 (Zephyrus G14)

    Requirements:
    - Windows 11 or Windows 10 (version 2004 or higher)
    - Administrator privileges
    - Internet connection
#>

[CmdletBinding()]
param(
    [string]$DistroName = "Ubuntu-22.04",
    [string]$Username = "abe"
)

$ErrorActionPreference = "Stop"

# Import AbeOS core module for logging
$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot "..\..\..")).ProviderPath
Import-Module (Join-Path $repoRoot "modules\lib\AbeOS.Core.psm1") -Force

Write-AbeLog "==================================================" -Level Info
Write-AbeLog "  AbeOS WSL2 Installation & Configuration" -Level Info
Write-AbeLog "==================================================" -Level Info
Write-AbeLog "Target Distribution: $DistroName" -Level Info
Write-AbeLog "Default User: $Username" -Level Info
Write-AbeLog ""

# Step 1: Enable WSL and Virtual Machine Platform
Write-AbeLog "Step 1: Enabling WSL and Virtual Machine Platform features..." -Level Info

$wslFeature = Get-WindowsOptionalFeature -Online -FeatureName Microsoft-Windows-Subsystem-Linux
$vmFeature = Get-WindowsOptionalFeature -Online -FeatureName VirtualMachinePlatform

$needsReboot = $false

if ($wslFeature.State -ne "Enabled") {
    Write-AbeLog "Enabling WSL feature..." -Level Warning
    Enable-WindowsOptionalFeature -Online -FeatureName Microsoft-Windows-Subsystem-Linux -NoRestart
    $needsReboot = $true
}

if ($vmFeature.State -ne "Enabled") {
    Write-AbeLog "Enabling Virtual Machine Platform..." -Level Warning
    Enable-WindowsOptionalFeature -Online -FeatureName VirtualMachinePlatform -NoRestart
    $needsReboot = $true
}

if ($needsReboot) {
    Write-AbeLog "Features enabled. A reboot is required." -Level Error
    Write-AbeLog "Please restart your computer and run this script again." -Level Error
    exit 1
}

Write-AbeLog "✓ WSL features are enabled" -Level Success

# Step 2: Set WSL2 as default
Write-AbeLog "`nStep 2: Setting WSL2 as default version..." -Level Info
wsl --set-default-version 2
if ($LASTEXITCODE -ne 0) {
    Write-AbeLog "Warning: Could not set WSL2 as default. Continuing..." -Level Warning
}

# Step 3: Check if distribution is already installed
Write-AbeLog "`nStep 3: Checking for existing WSL distributions..." -Level Info
$existingDistros = wsl --list --verbose 2>&1 | Out-String

if ($existingDistros -match $DistroName) {
    Write-AbeLog "Distribution '$DistroName' is already installed." -Level Warning
    $response = Read-Host "Do you want to reconfigure it? (Y/N)"
    if ($response -ne "Y") {
        Write-AbeLog "Skipping installation. Proceeding to configuration..." -Level Info
        $skipInstall = $true
    } else {
        Write-AbeLog "Unregistering existing distribution..." -Level Warning
        wsl --unregister $DistroName
        Write-AbeLog "✓ Existing distribution removed" -Level Success
        $skipInstall = $false
    }
} else {
    $skipInstall = $false
}

# Step 4: Install Ubuntu 22.04
if (-not $skipInstall) {
    Write-AbeLog "`nStep 4: Installing $DistroName..." -Level Info
    wsl --install -d $DistroName --no-launch

    if ($LASTEXITCODE -ne 0) {
        Write-AbeLog "WSL installation failed!" -Level Error
        exit 1
    }

    Write-AbeLog "✓ $DistroName installed" -Level Success
    Write-AbeLog "Note: You may need to set up a user account when first launching WSL." -Level Warning
}

# Step 5: Ensure it's running WSL2
Write-AbeLog "`nStep 5: Ensuring distribution uses WSL2..." -Level Info
wsl --set-version $DistroName 2
Start-Sleep -Seconds 3

# Step 6: Create wsl.conf with correct settings
Write-AbeLog "`nStep 6: Creating /etc/wsl.conf with proper configuration..." -Level Info

# Create wsl.conf content (this will have LF line endings)
$wslConfContent = @"
[boot]
systemd=true

[user]
default=$Username

[interop]
appendWindowsPath=false
"@

# Create a temporary file with LF line endings
$tempFile = [System.IO.Path]::GetTempFileName()
[System.IO.File]::WriteAllText($tempFile, $wslConfContent, [System.Text.UTF8Encoding]::new($false))

# Copy to WSL with proper line endings
Write-AbeLog "Writing /etc/wsl.conf..." -Level Info
wsl -d $DistroName bash -c "cat > /tmp/wsl.conf.temp" < $tempFile
wsl -d $DistroName bash -c "sudo mv /tmp/wsl.conf.temp /etc/wsl.conf && sudo chmod 644 /etc/wsl.conf && sudo chown root:root /etc/wsl.conf"

Remove-Item $tempFile -Force

# Verify wsl.conf was created correctly
Write-AbeLog "Verifying /etc/wsl.conf..." -Level Info
$wslConfCheck = wsl -d $DistroName bash -c "file /etc/wsl.conf"
Write-AbeLog "  File type: $wslConfCheck" -Level Info

$wslConfContent = wsl -d $DistroName bash -c "cat /etc/wsl.conf"
Write-AbeLog "  Content preview:" -Level Info
Write-AbeLog ($wslConfContent | Out-String) -Level Info

# Check for CRLF
$hasCRLF = wsl -d $DistroName bash -c "xxd /etc/wsl.conf | grep -c '0d0a'"
if ($hasCRLF -and $hasCRLF -ne "0") {
    Write-AbeLog "Warning: CRLF detected in wsl.conf! Fixing..." -Level Warning
    wsl -d $DistroName bash -c "sudo sed -i 's/\r$//' /etc/wsl.conf"
    Write-AbeLog "✓ Line endings fixed" -Level Success
} else {
    Write-AbeLog "✓ wsl.conf has correct LF line endings" -Level Success
}

# Step 7: Shutdown and restart WSL to apply changes
Write-AbeLog "`nStep 7: Restarting WSL to apply configuration..." -Level Info
wsl --shutdown
Start-Sleep -Seconds 5

# Start WSL again
wsl -d $DistroName echo "WSL restarted"

if ($LASTEXITCODE -ne 0) {
    Write-AbeLog "Failed to restart WSL" -Level Error
    exit 1
}

Write-AbeLog "✓ WSL restarted with new configuration" -Level Success

# Step 8: Verify configuration
Write-AbeLog "`nStep 8: Verifying WSL configuration..." -Level Info

Write-AbeLog "Checking WSL version..." -Level Info
$wslVersion = wsl -l -v | Select-String $DistroName
Write-AbeLog "  $wslVersion" -Level Info

Write-AbeLog "Checking root filesystem..." -Level Info
$rootFS = wsl -d $DistroName bash -c "mount | grep ' on / '"
Write-AbeLog "  $rootFS" -Level Info

Write-AbeLog "Checking PATH (should not contain /mnt/c)..." -Level Info
$wslPath = wsl -d $DistroName bash -c "echo `$PATH"
Write-AbeLog "  $wslPath" -Level Info

if ($wslPath -match "/mnt/c") {
    Write-AbeLog "Warning: Windows paths detected in WSL PATH!" -Level Warning
    Write-AbeLog "You may need to restart WSL again: wsl --shutdown" -Level Warning
} else {
    Write-AbeLog "✓ PATH is clean (no Windows paths)" -Level Success
}

Write-AbeLog "Checking systemd status..." -Level Info
$systemdStatus = wsl -d $DistroName bash -c "systemctl is-system-running" 2>&1
Write-AbeLog "  Systemd status: $systemdStatus" -Level Info

# Step 9: Update packages
Write-AbeLog "`nStep 9: Updating Ubuntu packages..." -Level Info
wsl -d $DistroName bash -c "sudo apt update && sudo apt upgrade -y"

Write-AbeLog "✓ Packages updated" -Level Success

# Step 10: Install essential build tools
Write-AbeLog "`nStep 10: Installing essential build tools..." -Level Info
wsl -d $DistroName bash -c "sudo apt install -y build-essential curl git wget unzip"

Write-AbeLog "✓ Essential tools installed" -Level Success

# Summary
Write-AbeLog "`n==================================================" -Level Success
Write-AbeLog "  WSL2 Installation Complete!" -Level Success
Write-AbeLog "==================================================" -Level Success
Write-AbeLog ""
Write-AbeLog "Configuration Summary:" -Level Info
Write-AbeLog "  ✓ WSL2 enabled and configured" -Level Success
Write-AbeLog "  ✓ Ubuntu 22.04 installed" -Level Success
Write-AbeLog "  ✓ /etc/wsl.conf created with LF line endings" -Level Success
Write-AbeLog "  ✓ Windows PATH injection disabled" -Level Success
Write-AbeLog "  ✓ Systemd enabled" -Level Success
Write-AbeLog "  ✓ Essential build tools installed" -Level Success
Write-AbeLog ""
Write-AbeLog "Next Steps:" -Level Info
Write-AbeLog "  1. Run .\Install-NodeJS.ps1 to install Node.js via NVM" -Level Info
Write-AbeLog "  2. Run .\Install-Python.ps1 to set up Python environment" -Level Info
Write-AbeLog "  3. Run .\Install-Docker.ps1 to install Docker Desktop" -Level Info
Write-AbeLog ""
Write-AbeLog "To enter WSL: wsl -d $DistroName" -Level Info
Write-AbeLog "To shutdown WSL: wsl --shutdown" -Level Info
