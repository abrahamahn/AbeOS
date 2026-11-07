# PluginsDeepAudit.ps1 - Inventory VST2/VST3 plugins and audio software.
# Usage: .\PluginsDeepAudit.ps1

$ErrorActionPreference = "SilentlyContinue"

Write-Host "=== AbeOS Plugin Deep Audit ===" -ForegroundColor Cyan
Write-Host "Generated: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" -ForegroundColor DarkGray
Write-Host ""

$totalPlugins = 0

# --- VST2 Plugins ---
Write-Host "[VST2 PLUGINS]" -ForegroundColor Yellow
$vst2Path = "C:\Production\Library\VST2"
if (Test-Path $vst2Path) {
    $vst2Files = Get-ChildItem -Path $vst2Path -Recurse -Include "*.dll" -ErrorAction SilentlyContinue
    $vst2Count = $vst2Files.Count
    $totalPlugins += $vst2Count
    Write-Host "  Path: $vst2Path" -ForegroundColor DarkGray
    Write-Host "  Count: $vst2Count plugin(s)" -ForegroundColor White
    $vst2SizeMB = [math]::Round(($vst2Files | Measure-Object -Property Length -Sum).Sum / 1MB, 1)
    Write-Host "  Size: $vst2SizeMB MB" -ForegroundColor DarkGray

    if ($vst2Count -gt 0 -and $vst2Count -le 50) {
        Write-Host ""
        foreach ($file in ($vst2Files | Sort-Object Name)) {
            $sizeMB = [math]::Round($file.Length / 1MB, 1)
            Write-Host "    $($file.Name) ($sizeMB MB)" -ForegroundColor DarkGray
        }
    } elseif ($vst2Count -gt 50) {
        Write-Host "  (Showing first 50 of $vst2Count)" -ForegroundColor DarkGray
        Write-Host ""
        foreach ($file in ($vst2Files | Sort-Object Name | Select-Object -First 50)) {
            $sizeMB = [math]::Round($file.Length / 1MB, 1)
            Write-Host "    $($file.Name) ($sizeMB MB)" -ForegroundColor DarkGray
        }
    }
} else {
    Write-Host "  Path not found: $vst2Path" -ForegroundColor DarkGray
    Write-Host "  No VST2 plugins directory" -ForegroundColor Yellow
}

# --- VST3 Plugins ---
Write-Host ""
Write-Host "[VST3 PLUGINS]" -ForegroundColor Yellow
$vst3Path = "C:\Program Files\Common Files\VST3"
if (Test-Path $vst3Path) {
    $vst3Files = Get-ChildItem -Path $vst3Path -Recurse -Include "*.vst3" -ErrorAction SilentlyContinue
    $vst3Count = $vst3Files.Count
    $totalPlugins += $vst3Count
    Write-Host "  Path: $vst3Path" -ForegroundColor DarkGray
    Write-Host "  Count: $vst3Count plugin(s)" -ForegroundColor White
    $vst3SizeMB = [math]::Round(($vst3Files | Measure-Object -Property Length -Sum).Sum / 1MB, 1)
    Write-Host "  Size: $vst3SizeMB MB" -ForegroundColor DarkGray

    if ($vst3Count -gt 0 -and $vst3Count -le 50) {
        Write-Host ""
        foreach ($file in ($vst3Files | Sort-Object Name)) {
            $sizeMB = [math]::Round($file.Length / 1MB, 1)
            Write-Host "    $($file.BaseName) ($sizeMB MB)" -ForegroundColor DarkGray
        }
    } elseif ($vst3Count -gt 50) {
        Write-Host "  (Showing first 50 of $vst3Count)" -ForegroundColor DarkGray
        Write-Host ""
        foreach ($file in ($vst3Files | Sort-Object Name | Select-Object -First 50)) {
            $sizeMB = [math]::Round($file.Length / 1MB, 1)
            Write-Host "    $($file.BaseName) ($sizeMB MB)" -ForegroundColor DarkGray
        }
    }
} else {
    Write-Host "  Path not found: $vst3Path" -ForegroundColor DarkGray
    Write-Host "  No VST3 plugins directory" -ForegroundColor Yellow
}

# --- CLAP Plugins ---
Write-Host ""
Write-Host "[CLAP PLUGINS]" -ForegroundColor Yellow
$clapPath = "C:\Program Files\Common Files\CLAP"
if (Test-Path $clapPath) {
    $clapFiles = Get-ChildItem -Path $clapPath -Recurse -Include "*.clap" -ErrorAction SilentlyContinue
    $clapCount = $clapFiles.Count
    $totalPlugins += $clapCount
    Write-Host "  Path: $clapPath" -ForegroundColor DarkGray
    Write-Host "  Count: $clapCount plugin(s)" -ForegroundColor White
    if ($clapCount -gt 0) {
        foreach ($file in ($clapFiles | Sort-Object Name)) {
            Write-Host "    $($file.BaseName)" -ForegroundColor DarkGray
        }
    }
} else {
    Write-Host "  No CLAP directory found" -ForegroundColor DarkGray
}

# --- Audio Service ---
Write-Host ""
Write-Host "[AUDIO SERVICE]" -ForegroundColor Yellow
$audioSvc = Get-Service -Name "Audiosrv" -ErrorAction SilentlyContinue
$endpointSvc = Get-Service -Name "AudioEndpointBuilder" -ErrorAction SilentlyContinue
$audioColor = $(if ($audioSvc.Status -eq "Running") { "Green" } else { "Red" })
$endpointColor = $(if ($endpointSvc.Status -eq "Running") { "Green" } else { "Red" })
Write-Host "  Windows Audio: $($audioSvc.Status)" -ForegroundColor $audioColor
Write-Host "  Endpoint Builder: $($endpointSvc.Status)" -ForegroundColor $endpointColor

# --- Audio Devices ---
Write-Host ""
Write-Host "[AUDIO DEVICES]" -ForegroundColor Yellow
$devices = Get-CimInstance -ClassName Win32_SoundDevice
if ($devices) {
    foreach ($dev in $devices) {
        $color = $(if ($dev.Status -eq "OK") { "Green" } else { "Yellow" })
        Write-Host "  $($dev.Name) - $($dev.Status)" -ForegroundColor $color
    }
} else {
    Write-Host "  No audio devices found" -ForegroundColor Red
}

# --- DAW Installations ---
Write-Host ""
Write-Host "[DAW SOFTWARE]" -ForegroundColor Yellow
$daws = @(
    @{ Name = "FL Studio"; Path = "C:\Program Files\Image-Line\FL Studio*" }
    @{ Name = "Ableton Live"; Path = "C:\ProgramData\Ableton\Live*" }
    @{ Name = "Studio One"; Path = "C:\Program Files\PreSonus\Studio One*" }
    @{ Name = "Reaper"; Path = "C:\Program Files\REAPER*" }
    @{ Name = "Bitwig Studio"; Path = "C:\Program Files\Bitwig Studio*" }
)
$foundDaws = 0
foreach ($daw in $daws) {
    if (Test-Path $daw.Path) {
        Write-Host "  [OK] $($daw.Name)" -ForegroundColor Green
        $foundDaws++
    }
}
if ($foundDaws -eq 0) {
    Write-Host "  No DAW software detected" -ForegroundColor DarkGray
}

# --- Summary ---
Write-Host ""
Write-Host "=== Summary ===" -ForegroundColor Cyan
Write-Host "  Total plugins: $totalPlugins" -ForegroundColor White
Write-Host "  DAWs found: $foundDaws" -ForegroundColor White
Write-Host ""
Write-Host "Done." -ForegroundColor Cyan
