#Requires -RunAsAdministrator
<#
.SYNOPSIS
    AbeOS Registry Backup Utility
.DESCRIPTION
    Creates timestamped backups of critical registry keys before system modifications
.PARAMETER BackupType
    Type of backup: Full (all keys) or Quick (AbeOS-related keys only)
.EXAMPLE
    .\Backup-Registry.ps1 -BackupType Quick
.NOTES
    Version: 1.0
    Last Updated: November 2025
#>

param(
    [Parameter(Mandatory=$false)]
    [ValidateSet("Full", "Quick")]
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

    } else {
        Write-Host "Creating quick backup of modified keys..." -ForegroundColor Yellow
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
