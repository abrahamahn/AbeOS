#Requires -RunAsAdministrator
<#
.SYNOPSIS
    AbeOS Registry Backup Utility
.DESCRIPTION
    Creates timestamped backups of critical registry keys before system modifications
.PARAMETER BackupType
    Type of backup:
    - Quick: Only AbeOS-modified Windows system keys (power, explorer, privacy)
    - Programs: All installed programs (64/32-bit) and software configurations
    - Audio: VST/VST3 plugins, DAWs, ASIO drivers, and audio software
    - Complete: System + Programs + Audio (recommended before fresh install)
    - Full: Entire HKLM and HKCU registry (massive, slow, use with caution)
.EXAMPLE
    .\Backup-Registry.ps1 -BackupType Quick
    Backs up only Windows settings that AbeOS scripts modify
.EXAMPLE
    .\Backup-Registry.ps1 -BackupType Audio
    Backs up all VST plugins, DAWs, and audio software configurations
.EXAMPLE
    .\Backup-Registry.ps1 -BackupType Complete
    Comprehensive backup of system, programs, and audio (recommended)
.NOTES
    Version: 2.0
    Last Updated: November 2025
    Backup Location: C:\AbeOS\configs\core\backup\registry
#>

param(
    [Parameter(Mandatory=$false)]
    [ValidateSet("Full", "Quick", "Programs", "Audio", "Complete")]
    [string]$BackupType = "Quick"
)

$ErrorActionPreference = "Stop"

$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot "..\..\..")).ProviderPath
$modulePath = Join-Path $repoRoot "modules\lib\AbeOS.Core.psm1"
Import-Module $modulePath -Force

Write-Host "`n=== ABEOS REGISTRY BACKUP UTILITY ===" -ForegroundColor Cyan

$backupPath = Get-AbeOSPath "configs\core\backup\registry"
$timestamp = Get-Date -Format "yyyyMMdd-HHmmss"

# Create backup directory if it doesn't exist
if (-not (Test-Path $backupPath)) {
    New-Item -ItemType Directory -Path $backupPath -Force | Out-Null
}

function Backup-RegistryKey {
    param(
        [string]$KeyPath,
        [string]$FileName
    )

    try {
        $outputFile = "$backupPath\$timestamp-$FileName.reg"
        reg export $KeyPath $outputFile /y >$null 2>&1

        if ($LASTEXITCODE -eq 0) {
            Write-Host "[✓] Backed up: $FileName" -ForegroundColor Green
            return $true
        } else {
            Write-Host "[!] Skipped: $FileName (key may not exist)" -ForegroundColor Yellow
            return $false
        }
    } catch {
        Write-Host "[!] Error backing up: $FileName" -ForegroundColor Red
        return $false
    }
}

try {
    Write-Host "Backup type: $BackupType" -ForegroundColor Yellow
    Write-Host "Backup location: $backupPath" -ForegroundColor Cyan
    Write-Host ""

    if ($BackupType -eq "Full") {
        Write-Host "Creating full system registry backup..." -ForegroundColor Yellow
        Write-Host "(This may take several minutes)" -ForegroundColor Yellow
        Write-Host ""

        # Full registry backup
        Backup-RegistryKey "HKLM" "HKLM-FULL"
        Backup-RegistryKey "HKCU" "HKCU-FULL"

    } elseif ($BackupType -eq "Programs") {
        Write-Host "Creating backup of installed programs..." -ForegroundColor Yellow
        Write-Host ""

        # Installed programs (both 32-bit and 64-bit)
        Backup-RegistryKey "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall" "Programs-System-64bit"
        Backup-RegistryKey "HKLM\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall" "Programs-System-32bit"
        Backup-RegistryKey "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall" "Programs-User"

        # User-installed software configurations
        Backup-RegistryKey "HKCU\SOFTWARE" "User-Software-Settings"
        Backup-RegistryKey "HKLM\SOFTWARE" "System-Software-Settings"

        # Windows features and components
        Backup-RegistryKey "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Component Based Servicing" "Windows-Components"

    } elseif ($BackupType -eq "Audio") {
        Write-Host "Creating backup of VST plugins and audio software..." -ForegroundColor Yellow
        Write-Host ""

        # VST Plugin Paths (standard locations)
        Backup-RegistryKey "HKLM\SOFTWARE\VST" "VST-Paths-System"
        Backup-RegistryKey "HKCU\SOFTWARE\VST" "VST-Paths-User"
        Backup-RegistryKey "HKLM\SOFTWARE\WOW6432Node\VST" "VST-Paths-32bit"

        # VST3 Plugin Settings
        Backup-RegistryKey "HKLM\SOFTWARE\VST3" "VST3-Settings-System"
        Backup-RegistryKey "HKCU\SOFTWARE\VST3" "VST3-Settings-User"

        # ASIO Drivers
        Backup-RegistryKey "HKLM\SOFTWARE\ASIO" "ASIO-Drivers"
        Backup-RegistryKey "HKLM\SOFTWARE\WOW6432Node\ASIO" "ASIO-Drivers-32bit"

        # Common DAW Registry Keys
        Backup-RegistryKey "HKCU\SOFTWARE\Ableton" "Ableton-Live"
        Backup-RegistryKey "HKLM\SOFTWARE\Ableton" "Ableton-System"
        Backup-RegistryKey "HKCU\SOFTWARE\Image-Line" "FL-Studio"
        Backup-RegistryKey "HKLM\SOFTWARE\Image-Line" "FL-Studio-System"
        Backup-RegistryKey "HKCU\SOFTWARE\Steinberg" "Steinberg-DAWs"
        Backup-RegistryKey "HKLM\SOFTWARE\Steinberg" "Steinberg-System"
        Backup-RegistryKey "HKCU\SOFTWARE\PreSonus" "PreSonus-StudioOne"
        Backup-RegistryKey "HKLM\SOFTWARE\PreSonus" "PreSonus-System"
        Backup-RegistryKey "HKCU\SOFTWARE\Avid" "ProTools-User"
        Backup-RegistryKey "HKLM\SOFTWARE\Avid" "ProTools-System"
        Backup-RegistryKey "HKCU\SOFTWARE\Cockos" "Reaper"
        Backup-RegistryKey "HKLM\SOFTWARE\Cockos" "Reaper-System"
        Backup-RegistryKey "HKCU\SOFTWARE\Bitwig" "Bitwig-Studio"
        Backup-RegistryKey "HKLM\SOFTWARE\Bitwig" "Bitwig-System"

        # Common VST Plugin Vendors
        Backup-RegistryKey "HKCU\SOFTWARE\Native Instruments" "Native-Instruments"
        Backup-RegistryKey "HKLM\SOFTWARE\Native Instruments" "Native-Instruments-System"
        Backup-RegistryKey "HKCU\SOFTWARE\Arturia" "Arturia"
        Backup-RegistryKey "HKLM\SOFTWARE\Arturia" "Arturia-System"
        Backup-RegistryKey "HKCU\SOFTWARE\iZotope" "iZotope"
        Backup-RegistryKey "HKLM\SOFTWARE\iZotope" "iZotope-System"
        Backup-RegistryKey "HKCU\SOFTWARE\FabFilter" "FabFilter"
        Backup-RegistryKey "HKLM\SOFTWARE\FabFilter" "FabFilter-System"
        Backup-RegistryKey "HKCU\SOFTWARE\Waves Audio" "Waves"
        Backup-RegistryKey "HKLM\SOFTWARE\Waves Audio" "Waves-System"
        Backup-RegistryKey "HKCU\SOFTWARE\Spectrasonics" "Spectrasonics"
        Backup-RegistryKey "HKLM\SOFTWARE\Spectrasonics" "Spectrasonics-System"
        Backup-RegistryKey "HKCU\SOFTWARE\Output" "Output"
        Backup-RegistryKey "HKLM\SOFTWARE\Output" "Output-System"
        Backup-RegistryKey "HKCU\SOFTWARE\Splice" "Splice"
        Backup-RegistryKey "HKLM\SOFTWARE\Splice" "Splice-System"
        Backup-RegistryKey "HKCU\SOFTWARE\Serum" "Serum-Xfer"
        Backup-RegistryKey "HKLM\SOFTWARE\Xfer Records" "Xfer-System"
        Backup-RegistryKey "HKCU\SOFTWARE\Lennar Digital" "Sylenth1"
        Backup-RegistryKey "HKLM\SOFTWARE\Lennar Digital" "Sylenth1-System"
        Backup-RegistryKey "HKCU\SOFTWARE\u-he" "u-he-Plugins"
        Backup-RegistryKey "HKLM\SOFTWARE\u-he" "u-he-System"
        Backup-RegistryKey "HKCU\SOFTWARE\Valhalla DSP" "Valhalla-DSP"
        Backup-RegistryKey "HKLM\SOFTWARE\Valhalla DSP" "Valhalla-System"
        Backup-RegistryKey "HKCU\SOFTWARE\UVI" "UVI"
        Backup-RegistryKey "HKLM\SOFTWARE\UVI" "UVI-System"

        # Audio Interfaces and Drivers
        Backup-RegistryKey "HKLM\SOFTWARE\Focusrite" "Focusrite"
        Backup-RegistryKey "HKLM\SOFTWARE\Universal Audio" "UAD"
        Backup-RegistryKey "HKLM\SOFTWARE\RME" "RME-Audio"
        Backup-RegistryKey "HKLM\SOFTWARE\M-Audio" "M-Audio"
        Backup-RegistryKey "HKLM\SOFTWARE\PreSonus\AudioBox" "PreSonus-AudioBox"

    } elseif ($BackupType -eq "Complete") {
        Write-Host "Creating complete backup (System + Programs + Audio)..." -ForegroundColor Yellow
        Write-Host "(This may take several minutes)" -ForegroundColor Yellow
        Write-Host ""

        # System settings (Quick backup content)
        Write-Host "`n--- Windows System Settings ---" -ForegroundColor Cyan
        Backup-RegistryKey "HKLM\SYSTEM\CurrentControlSet\Control\Power" "Power-Settings"
        Backup-RegistryKey "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Power" "Session-Manager-Power"
        Backup-RegistryKey "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management" "Memory-Management"
        Backup-RegistryKey "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer" "Explorer-Settings"
        Backup-RegistryKey "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" "Explorer-Advanced"
        Backup-RegistryKey "HKCU\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" "ContentDelivery"
        Backup-RegistryKey "HKLM\SOFTWARE\Policies\Microsoft\Windows\CloudContent" "CloudContent-Policies"
        Backup-RegistryKey "HKCU\Software\Microsoft\Windows\CurrentVersion\VideoSettings" "Video-Settings"
        Backup-RegistryKey "HKCU\Control Panel\Desktop" "Desktop-Settings"

        # Installed programs
        Write-Host "`n--- Installed Programs ---" -ForegroundColor Cyan
        Backup-RegistryKey "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall" "Programs-System-64bit"
        Backup-RegistryKey "HKLM\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall" "Programs-System-32bit"
        Backup-RegistryKey "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall" "Programs-User"

        # VST and Audio (abbreviated to avoid duplication)
        Write-Host "`n--- Audio Software & VST Plugins ---" -ForegroundColor Cyan
        Backup-RegistryKey "HKLM\SOFTWARE\VST" "VST-Paths-System"
        Backup-RegistryKey "HKCU\SOFTWARE\VST" "VST-Paths-User"
        Backup-RegistryKey "HKLM\SOFTWARE\VST3" "VST3-Settings-System"
        Backup-RegistryKey "HKLM\SOFTWARE\ASIO" "ASIO-Drivers"
        Backup-RegistryKey "HKCU\SOFTWARE\Ableton" "Ableton-Live"
        Backup-RegistryKey "HKCU\SOFTWARE\Image-Line" "FL-Studio"
        Backup-RegistryKey "HKCU\SOFTWARE\Steinberg" "Steinberg-DAWs"
        Backup-RegistryKey "HKCU\SOFTWARE\Native Instruments" "Native-Instruments"
        Backup-RegistryKey "HKCU\SOFTWARE\Arturia" "Arturia"
        Backup-RegistryKey "HKCU\SOFTWARE\iZotope" "iZotope"
        Backup-RegistryKey "HKCU\SOFTWARE\FabFilter" "FabFilter"
        Backup-RegistryKey "HKCU\SOFTWARE\Waves Audio" "Waves"
        Backup-RegistryKey "HKCU\SOFTWARE\Spectrasonics" "Spectrasonics"

    } else {
        Write-Host "Creating quick backup of AbeOS-modified keys..." -ForegroundColor Yellow
        Write-Host ""

        # Power settings
        Backup-RegistryKey "HKLM\SYSTEM\CurrentControlSet\Control\Power" "Power-Settings"
        Backup-RegistryKey "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Power" "Session-Manager-Power"

        # Memory management (pagefile)
        Backup-RegistryKey "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management" "Memory-Management"

        # Explorer settings
        Backup-RegistryKey "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer" "Explorer-Settings"
        Backup-RegistryKey "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" "Explorer-Advanced"

        # Content delivery & privacy
        Backup-RegistryKey "HKCU\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" "ContentDelivery"
        Backup-RegistryKey "HKLM\SOFTWARE\Policies\Microsoft\Windows\CloudContent" "CloudContent-Policies"

        # Video settings (OLED fixes)
        Backup-RegistryKey "HKCU\Software\Microsoft\Windows\CurrentVersion\VideoSettings" "Video-Settings"

        # Desktop settings
        Backup-RegistryKey "HKCU\Control Panel\Desktop" "Desktop-Settings"
    }

    Write-Host ""
    Write-Host "=== BACKUP COMPLETE ===" -ForegroundColor Cyan
    Write-Host ("Location: {0}" -f (Join-Path $backupPath "$timestamp-*.reg")) -ForegroundColor Green
    Write-Host ""
    Write-Host "To restore a key, right-click the .reg file and select 'Merge'" -ForegroundColor Yellow

    # Create a manifest file
    $manifestFile = "$backupPath\$timestamp-MANIFEST.txt"
    $manifest = @"
AbeOS Registry Backup Manifest
===============================
Timestamp: $timestamp
Backup Type: $BackupType
Computer: $env:COMPUTERNAME
User: $env:USERNAME
OS Version: $((Get-WmiObject Win32_OperatingSystem).Caption)

Files Created:
"@

    Get-ChildItem "$backupPath\$timestamp-*.reg" | ForEach-Object {
        $size = "{0:N2} KB" -f ($_.Length / 1KB)
        $manifest += "`n  - $($_.Name) ($size)"
    }

    $manifest | Out-File $manifestFile -Encoding UTF8

} catch {
    Write-Host "ERROR: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}
