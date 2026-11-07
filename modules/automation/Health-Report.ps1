# Health-Report.ps1 - Quick system health snapshot.
# Usage: .\Health-Report.ps1

$ErrorActionPreference = "SilentlyContinue"

Write-Host "=== AbeOS Health Report ===" -ForegroundColor Cyan
Write-Host "Generated: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" -ForegroundColor DarkGray
Write-Host ""

# --- CPU ---
Write-Host "[CPU]" -ForegroundColor Yellow
$cpu = Get-CimInstance -ClassName Win32_Processor
Write-Host "  Model: $($cpu.Name)" -ForegroundColor White
Write-Host "  Cores: $($cpu.NumberOfCores) / Threads: $($cpu.NumberOfLogicalProcessors)" -ForegroundColor DarkGray
$cpuLoad = [math]::Round($cpu.LoadPercentage, 1)
$cpuColor = $(if ($cpuLoad -gt 80) { "Red" } elseif ($cpuLoad -gt 50) { "Yellow" } else { "Green" })
Write-Host "  Load: $cpuLoad%" -ForegroundColor $cpuColor

# --- Memory ---
Write-Host ""
Write-Host "[MEMORY]" -ForegroundColor Yellow
$os = Get-CimInstance -ClassName Win32_OperatingSystem
$totalGB = [math]::Round($os.TotalVisibleMemorySize / 1MB, 1)
$freeGB = [math]::Round($os.FreePhysicalMemory / 1MB, 1)
$usedGB = [math]::Round($totalGB - $freeGB, 1)
$pct = [math]::Round(($usedGB / $totalGB) * 100, 0)
$memColor = $(if ($pct -gt 85) { "Red" } elseif ($pct -gt 70) { "Yellow" } else { "Green" })
Write-Host "  Total: ${totalGB} GB" -ForegroundColor White
Write-Host "  Used: ${usedGB} GB ($pct%)" -ForegroundColor $memColor
Write-Host "  Free: ${freeGB} GB" -ForegroundColor DarkGray

# --- Disks ---
Write-Host ""
Write-Host "[DISKS]" -ForegroundColor Yellow
$disks = Get-CimInstance -ClassName Win32_LogicalDisk -Filter "DriveType=3"
foreach ($disk in $disks) {
    $totalDiskGB = [math]::Round($disk.Size / 1GB, 1)
    $freeDiskGB = [math]::Round($disk.FreeSpace / 1GB, 1)
    $usedDiskGB = [math]::Round($totalDiskGB - $freeDiskGB, 1)
    $diskPct = [math]::Round(($usedDiskGB / $totalDiskGB) * 100, 0)
    $diskColor = $(if ($diskPct -gt 90) { "Red" } elseif ($diskPct -gt 75) { "Yellow" } else { "Green" })
    Write-Host "  $($disk.DeviceID) ${usedDiskGB}/${totalDiskGB} GB ($diskPct%)" -ForegroundColor $diskColor
}

# --- Uptime ---
Write-Host ""
Write-Host "[UPTIME]" -ForegroundColor Yellow
$bootTime = $os.LastBootUpTime
$uptime = (Get-Date) - $bootTime
$uptimeStr = "{0}d {1}h {2}m" -f $uptime.Days, $uptime.Hours, $uptime.Minutes
$uptimeColor = $(if ($uptime.Days -gt 7) { "Yellow" } else { "Green" })
Write-Host "  Last boot: $($bootTime.ToString('yyyy-MM-dd HH:mm'))" -ForegroundColor DarkGray
Write-Host "  Uptime: $uptimeStr" -ForegroundColor $uptimeColor

# --- Critical Services ---
Write-Host ""
Write-Host "[CRITICAL SERVICES]" -ForegroundColor Yellow
$criticalServices = @(
    @{ Name = "wuauserv"; Label = "Windows Update" }
    @{ Name = "WinDefend"; Label = "Windows Defender" }
    @{ Name = "Audiosrv"; Label = "Audio" }
    @{ Name = "Dnscache"; Label = "DNS Client" }
    @{ Name = "LanmanWorkstation"; Label = "Workstation" }
    @{ Name = "Dhcp"; Label = "DHCP Client" }
)
foreach ($svc in $criticalServices) {
    $status = (Get-Service -Name $svc.Name -ErrorAction SilentlyContinue).Status
    $color = $(if ($status -eq "Running") { "Green" } elseif ($status -eq "Stopped") { "Red" } else { "Yellow" })
    $symbol = $(if ($status -eq "Running") { "OK" } else { $status })
    Write-Host "  $($svc.Label): $symbol" -ForegroundColor $color
}

# --- Windows Defender ---
Write-Host ""
Write-Host "[DEFENDER]" -ForegroundColor Yellow
try {
    $defender = Get-MpComputerStatus -ErrorAction Stop
    $rtColor = $(if ($defender.RealTimeProtectionEnabled) { "Green" } else { "Red" })
    Write-Host "  Real-time protection: $(if ($defender.RealTimeProtectionEnabled) { 'ON' } else { 'OFF' })" -ForegroundColor $rtColor
    Write-Host "  Definitions: $($defender.AntivirusSignatureLastUpdated.ToString('yyyy-MM-dd HH:mm'))" -ForegroundColor DarkGray
    $defAge = ((Get-Date) - $defender.AntivirusSignatureLastUpdated).Days
    $defColor = $(if ($defAge -gt 3) { "Red" } elseif ($defAge -gt 1) { "Yellow" } else { "Green" })
    Write-Host "  Definition age: $defAge day(s)" -ForegroundColor $defColor
} catch {
    Write-Host "  Could not query Defender status" -ForegroundColor DarkGray
}

# --- Network ---
Write-Host ""
Write-Host "[NETWORK]" -ForegroundColor Yellow
$activeAdapters = Get-NetAdapter | Where-Object { $_.Status -eq "Up" }
foreach ($adapter in $activeAdapters) {
    $ip = (Get-NetIPAddress -InterfaceAlias $adapter.Name -AddressFamily IPv4 -ErrorAction SilentlyContinue).IPAddress
    Write-Host "  $($adapter.Name): $ip ($($adapter.LinkSpeed))" -ForegroundColor White
}

# --- Power Plan ---
Write-Host ""
Write-Host "[POWER]" -ForegroundColor Yellow
$activePlan = powercfg /getactivescheme 2>&1
Write-Host "  $activePlan" -ForegroundColor White

# --- Recent Errors (Event Log, last 24h) ---
Write-Host ""
Write-Host "[RECENT ERRORS (24h)]" -ForegroundColor Yellow
$since = (Get-Date).AddHours(-24)
$errors = Get-WinEvent -FilterHashtable @{LogName='System'; Level=2; StartTime=$since} -MaxEvents 5 -ErrorAction SilentlyContinue
if ($errors) {
    foreach ($err in $errors) {
        $msgLen = $err.Message.Length
        $snippet = $err.Message.Substring(0, [Math]::Min(100, $msgLen))
        Write-Host "  [$($err.TimeCreated.ToString('HH:mm'))] $($err.ProviderName): $snippet..." -ForegroundColor Red
    }
} else {
    Write-Host "  No critical errors in the last 24 hours." -ForegroundColor Green
}

Write-Host ""
Write-Host "=== Health Report Complete ===" -ForegroundColor Cyan
