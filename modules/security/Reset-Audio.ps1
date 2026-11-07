# Reset-Audio.ps1 - Safely restart the Windows audio stack.
# Usage: .\Reset-Audio.ps1

$ErrorActionPreference = "Stop"

Write-Host "=== AbeOS Audio Stack Reset ===" -ForegroundColor Cyan
Write-Host ""

$services = @(
    @{ Name = "Audiosrv"; Label = "Windows Audio" }
    @{ Name = "AudioEndpointBuilder"; Label = "Audio Endpoint Builder" }
)

# Report current state
Write-Host "[CURRENT STATE]" -ForegroundColor Yellow
foreach ($svc in $services) {
    $status = (Get-Service -Name $svc.Name -ErrorAction SilentlyContinue).Status
    $color = $(if ($status -eq "Running") { "Green" } else { "Red" })
    Write-Host "  $($svc.Label): $status" -ForegroundColor $color
}

# Stop services (reverse order: Audio first, then Endpoint Builder)
Write-Host ""
Write-Host "[STOPPING]" -ForegroundColor Yellow
foreach ($svc in $services) {
    $current = Get-Service -Name $svc.Name -ErrorAction SilentlyContinue
    if ($current.Status -eq "Running") {
        Write-Host "  Stopping $($svc.Label)..." -ForegroundColor DarkGray
        Stop-Service -Name $svc.Name -Force -ErrorAction SilentlyContinue
        Start-Sleep -Milliseconds 500
    }
}

Start-Sleep -Seconds 1

# Start services (forward order: Endpoint Builder first, then Audio)
Write-Host ""
Write-Host "[STARTING]" -ForegroundColor Yellow
$reversed = $services | Sort-Object { [array]::IndexOf($services, $_) } -Descending
foreach ($svc in $reversed) {
    Write-Host "  Starting $($svc.Label)..." -ForegroundColor DarkGray
    Start-Service -Name $svc.Name -ErrorAction SilentlyContinue
    Start-Sleep -Milliseconds 500
}

Start-Sleep -Seconds 1

# Verify
Write-Host ""
Write-Host "[VERIFICATION]" -ForegroundColor Yellow
$allOk = $true
foreach ($svc in $services) {
    $status = (Get-Service -Name $svc.Name -ErrorAction SilentlyContinue).Status
    $color = $(if ($status -eq "Running") { "Green" } else { "Red" })
    Write-Host "  $($svc.Label): $status" -ForegroundColor $color
    if ($status -ne "Running") { $allOk = $false }
}

# List active audio devices
Write-Host ""
Write-Host "[AUDIO DEVICES]" -ForegroundColor Yellow
$devices = Get-CimInstance -ClassName Win32_SoundDevice -ErrorAction SilentlyContinue
if ($devices) {
    foreach ($dev in $devices) {
        $statusText = $(if ($dev.Status -eq "OK") { "OK" } else { $dev.Status })
        $color = $(if ($dev.Status -eq "OK") { "Green" } else { "Yellow" })
        Write-Host "  $($dev.Name) - $statusText" -ForegroundColor $color
    }
} else {
    Write-Host "  No audio devices detected" -ForegroundColor Red
}

Write-Host ""
if ($allOk) {
    Write-Host "[OK] Audio stack restarted successfully." -ForegroundColor Green
} else {
    Write-Host "[WARN] Some services failed to restart. Try running as Administrator." -ForegroundColor Yellow
}
Write-Host ""
Write-Host "Done." -ForegroundColor Cyan
