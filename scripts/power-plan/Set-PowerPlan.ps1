# Set-PowerPlan.ps1 - Toggle ASUS ROG Zephyrus BIOS performance profile via ACPI WMI.
# Matches G-Helper / Fn+F5 profiles written in BIOS.
# Usage: .\Set-PowerPlan.ps1 <Silent|Balanced|Turbo>
param(
    [Parameter(Position = 0)]
    [ValidateSet("Silent", "Balanced", "Turbo")]
    [string]$Mode = "Balanced"
)

$ErrorActionPreference = "Stop"

Write-Host "=== AbeOS Performance Profile ===" -ForegroundColor Cyan
Write-Host ""

# ASUS ACPI performance mode device ID
$PERF_DEVICE = [uint32]0x00120075

# BIOS mode values (matches G-Helper / ASUS ACPI)
$modeValues = @{
    "Balanced" = [uint32]0
    "Turbo"    = [uint32]1
    "Silent"   = [uint32]2
}

$modeNames = @{ 0 = "Balanced"; 1 = "Turbo"; 2 = "Silent" }

# Connect to ASUS ATK WMI interface
try {
    $asus = Get-WmiObject -Namespace root\WMI -Class AsusAtkWmi_WMNB -ErrorAction Stop
} catch {
    Write-Host "[ERROR] ASUS ATK WMI interface not found." -ForegroundColor Red
    Write-Host "Ensure ASUS ATK drivers or G-Helper is installed." -ForegroundColor Yellow
    exit 1
}

# Read current BIOS performance mode
try {
    $current = $asus.DSTS($PERF_DEVICE)
    $currentValue = $current.Data -band 0xFF
    $currentName = $(if ($modeNames.ContainsKey([int]$currentValue)) { $modeNames[[int]$currentValue] } else { "Unknown ($currentValue)" })
    Write-Host "[CURRENT] $currentName" -ForegroundColor DarkGray
} catch {
    $currentName = "Unknown"
    Write-Host "[WARN] Could not read current mode" -ForegroundColor Yellow
}

# Check if already in target mode
if ($currentName -eq $Mode) {
    Write-Host "[OK] Already on '$Mode' - no change needed." -ForegroundColor Green
    exit 0
}

# Set the new BIOS performance mode
$targetValue = $modeValues[$Mode]
Write-Host "[SWITCHING] $Mode (ACPI value: $targetValue)" -ForegroundColor Yellow

try {
    $null = $asus.DEVS($PERF_DEVICE, $targetValue)

    # Brief wait for BIOS to apply
    Start-Sleep -Milliseconds 500

    # Verify
    $verify = $asus.DSTS($PERF_DEVICE)
    $verifyValue = $verify.Data -band 0xFF
    $verifyName = $(if ($modeNames.ContainsKey([int]$verifyValue)) { $modeNames[[int]$verifyValue] } else { "Unknown ($verifyValue)" })

    Write-Host ""
    Write-Host "[ACTIVE] $verifyName" -ForegroundColor Green
} catch {
    Write-Host "[ERROR] Failed to set mode: $_" -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "Done." -ForegroundColor Cyan
