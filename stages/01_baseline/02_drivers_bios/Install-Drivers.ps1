#Requires -RunAsAdministrator
<#
.SYNOPSIS
    AbeOS Phase 1.2 - Driver/Bios installer runner
.DESCRIPTION
    Reads driver metadata from configs/installers/drivers.json and executes each enabled installer once.
.PARAMETER ConfigPath
    Optional override for the driver metadata path.
.EXAMPLE
    .\Install-Drivers.ps1
.EXAMPLE
    .\Install-Drivers.ps1 -ConfigPath C:\AbeOS\configs\installers\drivers.json -WhatIf
.NOTES
    Version: 0.1 (experimental until real metadata is supplied)
    Last Updated: November 2025
#>

[CmdletBinding(SupportsShouldProcess = $true)]
param(
    [string]$ConfigPath
)

$ErrorActionPreference = "Stop"
$scriptName = "Install-Drivers"

$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot "..\..\..")).ProviderPath
$modulePath = Join-Path $repoRoot "modules\lib\AbeOS.Core.psm1"
Import-Module $modulePath -Force

if (-not $ConfigPath) {
    $ConfigPath = Get-AbeOSPath "configs\installers\drivers.json"
}

Write-Host "`n=== ABEOS DRIVER INSTALLER RUNNER ===" -ForegroundColor Cyan
Write-Host ("Config: {0}" -f $ConfigPath) -ForegroundColor Yellow

if (-not (Test-Path $ConfigPath)) {
    throw "Driver config not found at $ConfigPath"
}

$logFile = Initialize-AbeOSLogging -ScriptName $scriptName

function Get-DriverEntries {
    param([string]$Path)

    $raw = Get-Content -Path $Path -Raw -ErrorAction Stop
    $json = $raw | ConvertFrom-Json
    if (-not $json.drivers) { return @() }
    return $json.drivers | Where-Object { $_.enabled -ne $false }
}

try {
    $drivers = Get-DriverEntries -Path $ConfigPath

    if ($drivers.Count -eq 0) {
        Write-AbeOSLog -Message "No enabled driver entries found. Edit configs\installers\drivers.json to add installers." -Level "WARNING" -LogFile $logFile
        return
    }

    $installRoot = Get-AbeOSPath "installations\drivers"
    $rebootRequired = $false

    foreach ($driver in $drivers) {
        $installerPath = Join-Path $installRoot $driver.installer

        if (-not (Test-Path $installerPath)) {
            Write-AbeOSLog -Message ("[!] Installer missing for {0}: {1}" -f $driver.name, $installerPath) -Level "WARNING" -LogFile $logFile
            continue
        }

        $arguments = $driver.arguments
        $displayName = if ($driver.name) { $driver.name } else { $driver.id }

        Write-AbeOSLog -Message ("Preparing to install {0} ({1})" -f $displayName, (Split-Path $installerPath -Leaf)) -Level "INFO" -LogFile $logFile

        if ($PSCmdlet.ShouldProcess($displayName, "Install driver")) {
            $startInfo = @{
                FilePath     = $installerPath
                ArgumentList = $arguments
                Wait         = $true
                PassThru     = $true
            }

            $process = Start-Process @startInfo
            if ($process.ExitCode -eq 0) {
                Write-AbeOSLog -Message ("[✓] {0} installed successfully" -f $displayName) -Level "SUCCESS" -LogFile $logFile
                if ($driver.requiresReboot -eq $true) {
                    $rebootRequired = $true
                }
            } else {
                Write-AbeOSLog -Message ("[✗] {0} failed with exit code {1}" -f $displayName, $process.ExitCode) -Level "ERROR" -LogFile $logFile
            }
        } else {
            Write-AbeOSLog -Message ("Skipped {0} due to WhatIf/confirmation." -f $displayName) -Level "WARNING" -LogFile $logFile
        }
    }

    if ($rebootRequired) {
        Write-AbeOSLog -Message "At least one driver requested a reboot. Reboot after installers finish." -Level "WARNING" -LogFile $logFile
    }

    Write-AbeOSLog -Message "Driver installation batch complete." -Level "SUCCESS" -LogFile $logFile
    Write-AbeOSLog -Message ("Log file: {0}" -f $logFile) -Level "INFO" -LogFile $logFile

} catch {
    Write-AbeOSLog -Message ("ERROR: {0}" -f $_.Exception.Message) -Level "ERROR" -LogFile $logFile
    Write-AbeOSLog -Message ("Stack trace: {0}" -f $_.ScriptStackTrace) -Level "ERROR" -LogFile $logFile
    throw
}
