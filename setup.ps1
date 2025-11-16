#Requires -RunAsAdministrator
<#
.SYNOPSIS
    AbeOS Master Setup Script
.DESCRIPTION
    Drives AbeOS installations via a manifest so that only tested steps/phases run.
    Supports resuming at a specific step and stopping after a given step.
.PARAMETER SkipBackup
    Skip the registry backup step defined in the manifest.
.PARAMETER SkipReboot
    Skip the reboot prompt at the end of execution.
.PARAMETER MaxStatus
    Highest manifest status to include (stable, experimental, planned).
.PARAMETER Phase
    One or more phase identifiers to run (phase1-core, phase1-drivers, phase1-dev, all).
.PARAMETER StartAtStep
    Step identifier to start execution from (inclusive).
.PARAMETER StopAfterStep
    Step identifier to stop after (inclusive).
.EXAMPLE
    .\setup.ps1
.EXAMPLE
    .\setup.ps1 -Phase phase1-core -MaxStatus stable -StartAtStep explorer-indexing
.NOTES
    Version: 2.0
    Phase Coverage: Manifest-driven
    Last Updated: November 2025
#>

param(
    [switch]$SkipBackup,
    [switch]$SkipReboot,

    [ValidateSet("stable", "experimental", "planned")]
    [string]$MaxStatus = "stable",

    [ValidateSet("phase1-core", "phase1-drivers", "phase1-dev", "phase2-music", "all")]
    [string[]]$Phase = @("phase1-core"),

    [string]$StartAtStep,
    [string]$StopAfterStep
)

$ErrorActionPreference = "Stop"

$modulePath = Join-Path $PSScriptRoot "modules\lib\AbeOS.Core.psm1"
if (-not (Test-Path $modulePath)) {
    throw "Required module not found at $modulePath"
}
Import-Module $modulePath -Force

$AbeOSRoot = Get-AbeOSRoot
$logsPath = Get-AbeOSPath "logs"
$backupRoot = Get-AbeOSPath "configs\core\backup\registry"
$manifest = Get-AbeOSManifest
$maxRank = Get-AbeOSStatusRank -Status $MaxStatus

# ============================================
# BANNER
# ============================================
Clear-Host
Write-Host ""
Write-Host "  █████╗ ██████╗ ███████╗ ██████╗ ███████╗" -ForegroundColor Cyan
Write-Host " ██╔══██╗██╔══██╗██╔════╝██╔═══██╗██╔════╝" -ForegroundColor Cyan
Write-Host " ███████║██████╔╝█████╗  ██║   ██║███████╗" -ForegroundColor Cyan
Write-Host " ██╔══██║██╔══██╗██╔══╝  ██║   ██║╚════██║" -ForegroundColor Cyan
Write-Host " ██║  ██║██████╔╝███████╗╚██████╔╝███████║" -ForegroundColor Cyan
Write-Host " ╚═╝  ╚═╝╚═════╝ ╚══════╝ ╚═════╝ ╚══════╝" -ForegroundColor Cyan
Write-Host ""
Write-Host " Hyper-Personalized Windows 11 Environment" -ForegroundColor White
Write-Host " Manifest-driven installer (Max status: $MaxStatus)" -ForegroundColor Yellow
Write-Host ""

# ============================================
# PRE-FLIGHT CHECKS
# ============================================
Write-Host "=== PRE-FLIGHT CHECKS ===" -ForegroundColor Cyan

$currentPrincipal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
$isAdmin = $currentPrincipal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

if (-not $isAdmin) {
    Write-Host "[✗] ERROR: This script must be run as Administrator" -ForegroundColor Red
    Write-Host "    Right-click and select 'Run as Administrator'" -ForegroundColor Yellow
    exit 1
}
Write-Host "[✓] Running as Administrator" -ForegroundColor Green

if (-not (Test-Path $AbeOSRoot)) {
    Write-Host "[✗] ERROR: AbeOS directory not found at $AbeOSRoot" -ForegroundColor Red
    exit 1
}
Write-Host "[✓] AbeOS directory found" -ForegroundColor Green

if (-not $manifest.phases) {
    Write-Host "[✗] ERROR: Manifest contains no phases" -ForegroundColor Red
    exit 1
}

# ============================================
# BUILD STEP LIST FROM MANIFEST
# ============================================
function Get-SelectedPhases {
    param(
        [array]$ManifestPhases,
        [string[]]$RequestedPhaseIds
    )

    $idSet = @()
    if ($RequestedPhaseIds -contains "all") {
        $idSet = $ManifestPhases.id
    } else {
        $idSet = $RequestedPhaseIds
    }

    $idSet = $idSet | ForEach-Object { $_.ToLowerInvariant() }

    $result = @()
    foreach ($phase in $ManifestPhases) {
        if ($idSet -contains $phase.id.ToLowerInvariant()) {
            $result += $phase
        }
    }

    return $result
}

$selectedPhases = Get-SelectedPhases -ManifestPhases $manifest.phases -RequestedPhaseIds $Phase

if (-not $selectedPhases -or $selectedPhases.Count -eq 0) {
    Write-Host "[✗] ERROR: No phases matched selection ($Phase)" -ForegroundColor Red
    exit 1
}

$stepsToRun = New-Object System.Collections.Generic.List[object]

foreach ($phase in $selectedPhases) {
    $phaseRank = Get-AbeOSStatusRank -Status $phase.status
    if ($phaseRank -gt $maxRank) {
        continue
    }

    if (-not $phase.steps) {
        continue
    }

    foreach ($step in $phase.steps) {
        if (-not $step) { continue }

        $stepRank = Get-AbeOSStatusRank -Status $step.status
        if ($stepRank -gt $maxRank) {
            continue
        }

        if ($SkipBackup -and $step.skipFlag -eq "SkipBackup") {
            continue
        }

        if ([string]::IsNullOrWhiteSpace($step.script)) {
            continue
        }

        $scriptPath = Get-AbeOSPath $step.script

        if (-not (Test-Path $scriptPath)) {
            throw "Manifest references missing script: $($step.script)"
        }

        $stepsToRun.Add([pscustomobject]@{
            PhaseId     = $phase.id
            PhaseName   = $phase.name
            StepId      = $step.id
            StepName    = $step.name
            Description = $step.description
            ScriptPath  = $scriptPath
            Parameters  = $step.parameters
            Status      = $step.status
        })
    }
}

if ($stepsToRun.Count -eq 0) {
    Write-Host "[!] No steps matched the provided filters. Nothing to do." -ForegroundColor Yellow
    exit 0
}

if ($StartAtStep) {
    $startIndex = -1
    for ($i = 0; $i -lt $stepsToRun.Count; $i++) {
        if ($stepsToRun[$i].StepId -eq $StartAtStep) {
            $startIndex = $i
            break
        }
    }

    if ($startIndex -lt 0) {
        throw "StartAtStep '$StartAtStep' was not found in the filtered steps."
    }

    $stepsToRun = $stepsToRun[$startIndex..($stepsToRun.Count - 1)]
}

if ($StopAfterStep) {
    $stopIndex = -1
    for ($i = 0; $i -lt $stepsToRun.Count; $i++) {
        if ($stepsToRun[$i].StepId -eq $StopAfterStep) {
            $stopIndex = $i
            break
        }
    }

    if ($stopIndex -lt 0) {
        throw "StopAfterStep '$StopAfterStep' was not found in the filtered steps."
    }

    $stepsToRun = $stepsToRun[0..$stopIndex]
}

$totalSteps = $stepsToRun.Count
$phaseNames = ($stepsToRun | Select-Object -ExpandProperty PhaseName -Unique)

# ============================================
# SUMMARY + CONFIRMATION
# ============================================
Write-Host ""
Write-Host "=== INSTALLATION SUMMARY ===" -ForegroundColor Cyan
Write-Host ("Phases: {0}" -f ($phaseNames -join ", ")) -ForegroundColor White
Write-Host ("Steps to run: {0}" -f $totalSteps) -ForegroundColor White
Write-Host ("Max status: {0}" -f $MaxStatus) -ForegroundColor White

if ($SkipBackup) {
    Write-Host "Registry backup step will be skipped (per -SkipBackup)" -ForegroundColor Yellow
}
if ($StartAtStep) {
    Write-Host ("Starting at step: {0}" -f $StartAtStep) -ForegroundColor Yellow
}
if ($StopAfterStep) {
    Write-Host ("Will stop after step: {0}" -f $StopAfterStep) -ForegroundColor Yellow
}

Write-Host ""
for ($i = 0; $i -lt $stepsToRun.Count; $i++) {
    $step = $stepsToRun[$i]
    $line = "{0}. [{1}] {2} ({3}) - {4}" -f ($i + 1), $step.StepId, $step.StepName, $step.PhaseName, $step.Status
    Write-Host ("  " + $line) -ForegroundColor White
    if ($step.Description) {
        Write-Host ("     " + $step.Description) -ForegroundColor DarkGray
    }
}

Write-Host ""
Write-Host "Estimated time: 5-10 minutes for Phase 1.1" -ForegroundColor Yellow
Write-Host "A system reboot will be required after completion." -ForegroundColor Yellow
Write-Host ""

$response = Read-Host "Continue with installation? (yes/no)"
if ($response -notin @("yes", "y")) {
    Write-Host "Installation cancelled." -ForegroundColor Yellow
    exit 0
}

# ============================================
# EXECUTION
# ============================================
$failedSteps = @()
$completedSteps = 0

for ($i = 0; $i -lt $stepsToRun.Count; $i++) {
    $step = $stepsToRun[$i]
    Write-Host ""
    Write-Host ("=== STEP {0}/{1}: {2} ===" -f ($i + 1), $totalSteps, $step.StepName.ToUpper()) -ForegroundColor Cyan
    Write-Host ("Phase: {0} ({1})" -f $step.PhaseName, $step.Status) -ForegroundColor Yellow

    try {
        $params = @{}
        if ($step.Parameters) {
            foreach ($prop in $step.Parameters.PSObject.Properties) {
                $params[$prop.Name] = $prop.Value
            }
        }

        & $step.ScriptPath @params
        Write-Host "[✓] $($step.StepName) completed" -ForegroundColor Green
        $completedSteps++
    } catch {
        Write-Host "[✗] $($step.StepName) failed" -ForegroundColor Red
        Write-Host ("    Error: {0}" -f $_.Exception.Message) -ForegroundColor Red
        $failedSteps += $step.StepId

        $continueAnyway = Read-Host "Continue with remaining steps? (yes/no)"
        if ($continueAnyway -notin @("yes", "y")) {
            break
        }
    }

    if ($StopAfterStep -and $step.StepId -eq $StopAfterStep) {
        Write-Host "`nStopAfterStep reached ($StopAfterStep). Ending run as requested." -ForegroundColor Yellow
        break
    }
}

# ============================================
# COMPLETION
# ============================================
Write-Host ""
Write-Host "╔════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║                                                            ║" -ForegroundColor Cyan
Write-Host "║          ABEOS INSTALLATION RUN COMPLETE                  ║" -ForegroundColor Cyan
Write-Host "║                                                            ║" -ForegroundColor Cyan
Write-Host "╚════════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
Write-Host ""

if ($failedSteps.Count -gt 0) {
    Write-Host ("⚠️  Completed {0}/{1} steps. Failures: {2}" -f $completedSteps, $totalSteps, ($failedSteps -join ", ")) -ForegroundColor Yellow
    Write-Host ("Check logs in {0} for details." -f $logsPath) -ForegroundColor Yellow
} else {
    Write-Host ("✓ Completed {0}/{1} steps without errors." -f $completedSteps, $totalSteps) -ForegroundColor Green
}

Write-Host ""
Write-Host "Next Steps:" -ForegroundColor Cyan
Write-Host "  1. Reboot to apply all changes" -ForegroundColor White
Write-Host "  2. Verify status: .\stages\01_baseline\01_core_optimization\Verify-Installation.ps1" -ForegroundColor White
Write-Host ("  3. Review logs: {0}" -f $logsPath) -ForegroundColor White
Write-Host "  4. Run privacy.sexy script for telemetry hardening" -ForegroundColor White
Write-Host ""
Write-Host "Rollback resources:" -ForegroundColor Yellow
Write-Host ("  - Registry backups: {0}" -f $backupRoot) -ForegroundColor White
Write-Host "  - Restore: Right-click .reg file → Merge" -ForegroundColor White
Write-Host ""

# ============================================
# REBOOT PROMPT
# ============================================
if (-not $SkipReboot -and $failedSteps.Count -eq 0) {
    Write-Host "═══════════════════════════════════════════════════════════" -ForegroundColor Cyan
    $reboot = Read-Host "Reboot now to complete setup? (yes/no)"
    if ($reboot -in @("yes", "y")) {
        Write-Host ""
        Write-Host "Rebooting in 10 seconds..." -ForegroundColor Yellow
        Write-Host "Press Ctrl+C to cancel" -ForegroundColor Yellow
        Start-Sleep -Seconds 10
        Restart-Computer -Force
    } else {
        Write-Host "Remember to reboot manually to apply all changes!" -ForegroundColor Yellow
    }
} elseif ($failedSteps.Count -gt 0) {
    Write-Host "Reboot skipped because failures occurred." -ForegroundColor Yellow
}

Write-Host ""
Write-Host "Thank you for using AbeOS! 🚀" -ForegroundColor Cyan
Write-Host ""
