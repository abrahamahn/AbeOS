#Requires -RunAsAdministrator
<#
.SYNOPSIS
    AbeOS Power Plan Manager
.DESCRIPTION
    Create and switch between Creator and Performance power modes
.PARAMETER Mode
    The power mode to activate: Balanced, Performance, Creator
.EXAMPLE
    .\Set-PowerPlan.ps1 -Mode Performance
.NOTES
    Version: 1.0
    Last Updated: November 2025
#>

param(
    [Parameter(Mandatory=$true)]
    [ValidateSet("Balanced", "Performance", "Creator")]
    [string]$Mode
)

$ErrorActionPreference = "Stop"

Write-Host "`n=== ABEOS POWER PLAN MANAGER ===" -ForegroundColor Cyan

function Get-AbeOSPowerPlan {
    param([string]$Name)

    $plans = powercfg /list
    foreach ($line in $plans) {
        if ($line -match $Name -and $line -match '([0-9a-f-]{36})') {
            return $matches[1]
        }
    }
    return $null
}

try {
    switch ($Mode) {
        "Balanced" {
            Write-Host "Activating AbeOS Balanced Ultimate plan..." -ForegroundColor Yellow

            $guid = Get-AbeOSPowerPlan "AbeOS - Balanced Ultimate"

            if ($guid) {
                powercfg -setactive $guid
                Write-Host "[✓] Balanced mode activated" -ForegroundColor Green
            } else {
                Write-Host "[!] AbeOS Balanced plan not found. Run installation scripts first." -ForegroundColor Red
                exit 1
            }
        }

        "Performance" {
            Write-Host "Creating/Activating Performance mode..." -ForegroundColor Yellow

            # Check if performance plan exists
            $guid = Get-AbeOSPowerPlan "AbeOS Performance"

            if (-not $guid) {
                # Create new performance plan
                $guidOutput = powercfg -duplicatescheme SCHEME_BALANCED
                $guid = ($guidOutput -split '\s+')[-1]
                powercfg -changename $guid "AbeOS Performance"

                # Max CPU performance
                powercfg -setacvalueindex $guid SUB_PROCESSOR PROCTHROTTLEMIN 100
                powercfg -setacvalueindex $guid SUB_PROCESSOR PROCTHROTTLEMAX 100
                powercfg -setacvalueindex $guid SUB_PROCESSOR PERFBOOSTMODE 2
                powercfg -setacvalueindex $guid SUB_PROCESSOR PERFINCPOL 2
                powercfg -setacvalueindex $guid SUB_PROCESSOR PERFDECPOL 1

                # Core parking
                powercfg -setacvalueindex $guid SUB_PROCESSOR CPMINCORES 100
                powercfg -setacvalueindex $guid SUB_PROCESSOR CPMAXCORES 100

                # Disable idle
                powercfg -setacvalueindex $guid SUB_PROCESSOR IDLEDISABLE 1 2>$null

                Write-Host "[✓] Performance plan created" -ForegroundColor Green
            }

            powercfg -setactive $guid
            Write-Host "[✓] Performance mode activated (Max GPU/CPU)" -ForegroundColor Green
        }

        "Creator" {
            Write-Host "Creating/Activating Creator mode..." -ForegroundColor Yellow

            # Check if creator plan exists
            $guid = Get-AbeOSPowerPlan "AbeOS Creator"

            if (-not $guid) {
                # Create new creator plan (balanced with audio optimizations)
                $guidOutput = powercfg -duplicatescheme SCHEME_BALANCED
                $guid = ($guidOutput -split '\s+')[-1]
                powercfg -changename $guid "AbeOS Creator"

                # Balanced CPU (85% max to reduce heat/noise)
                powercfg -setacvalueindex $guid SUB_PROCESSOR PROCTHROTTLEMAX 85

                # Low latency for audio
                powercfg -setacvalueindex $guid SUB_PCIE ASPM 0

                # Prevent sleep during sessions
                powercfg -setacvalueindex $guid SUB_SLEEP STANDBYIDLE 0

                Write-Host "[✓] Creator plan created" -ForegroundColor Green
            }

            powercfg -setactive $guid
            Write-Host "[✓] Creator mode activated (Balanced, Low Latency)" -ForegroundColor Green
        }
    }

    Write-Host "`nCurrent power plan:" -ForegroundColor Cyan
    powercfg /list | Select-String "\*"

} catch {
    Write-Host "ERROR: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}
