# SystemDeepAudit.ps1 - Comprehensive system state audit.
# Usage: .\SystemDeepAudit.ps1

$ErrorActionPreference = "SilentlyContinue"

Write-Host "=== AbeOS System Deep Audit ===" -ForegroundColor Cyan
Write-Host "Generated: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" -ForegroundColor DarkGray
Write-Host ""

# --- OS Information ---
Write-Host "[OPERATING SYSTEM]" -ForegroundColor Yellow
$os = Get-CimInstance -ClassName Win32_OperatingSystem
$cs = Get-CimInstance -ClassName Win32_ComputerSystem
Write-Host "  Edition: $($os.Caption)" -ForegroundColor White
Write-Host "  Version: $($os.Version) (Build $($os.BuildNumber))" -ForegroundColor White
Write-Host "  Architecture: $($os.OSArchitecture)" -ForegroundColor DarkGray
Write-Host "  Hostname: $($cs.Name)" -ForegroundColor DarkGray
Write-Host "  Domain: $($cs.Domain)" -ForegroundColor DarkGray
Write-Host "  Install Date: $($os.InstallDate.ToString('yyyy-MM-dd'))" -ForegroundColor DarkGray

# --- Hardware ---
Write-Host ""
Write-Host "[HARDWARE]" -ForegroundColor Yellow
$cpu = Get-CimInstance -ClassName Win32_Processor
Write-Host "  CPU: $($cpu.Name)" -ForegroundColor White
Write-Host "  Cores: $($cpu.NumberOfCores) / Threads: $($cpu.NumberOfLogicalProcessors)" -ForegroundColor DarkGray
Write-Host "  System: $($cs.Manufacturer) $($cs.Model)" -ForegroundColor White
Write-Host "  RAM: $([math]::Round($cs.TotalPhysicalMemory / 1GB, 0)) GB" -ForegroundColor White

# GPU
$gpus = Get-CimInstance -ClassName Win32_VideoController
foreach ($gpu in $gpus) {
    $vramGB = [math]::Round($gpu.AdapterRAM / 1GB, 1)
    Write-Host "  GPU: $($gpu.Name) ($vramGB GB)" -ForegroundColor White
}

# --- Disks ---
Write-Host ""
Write-Host "[STORAGE]" -ForegroundColor Yellow
$physicalDisks = Get-CimInstance -ClassName Win32_DiskDrive
foreach ($pd in $physicalDisks) {
    $sizeGB = [math]::Round($pd.Size / 1GB, 0)
    Write-Host "  $($pd.Model) - $sizeGB GB ($($pd.MediaType))" -ForegroundColor White
}
Write-Host ""
$logicalDisks = Get-CimInstance -ClassName Win32_LogicalDisk -Filter "DriveType=3"
foreach ($ld in $logicalDisks) {
    $totalGB = [math]::Round($ld.Size / 1GB, 1)
    $freeGB = [math]::Round($ld.FreeSpace / 1GB, 1)
    $pct = [math]::Round((($totalGB - $freeGB) / $totalGB) * 100, 0)
    $color = $(if ($pct -gt 90) { "Red" } elseif ($pct -gt 75) { "Yellow" } else { "Green" })
    Write-Host "  $($ld.DeviceID) $freeGB GB free / $totalGB GB ($pct% used) [$($ld.FileSystem)]" -ForegroundColor $color
}

# --- Network ---
Write-Host ""
Write-Host "[NETWORK]" -ForegroundColor Yellow
$adapters = Get-NetAdapter | Where-Object { $_.Status -eq "Up" }
foreach ($adapter in $adapters) {
    $ip = (Get-NetIPAddress -InterfaceAlias $adapter.Name -AddressFamily IPv4 -ErrorAction SilentlyContinue).IPAddress
    $dns = (Get-DnsClientServerAddress -InterfaceAlias $adapter.Name -AddressFamily IPv4 -ErrorAction SilentlyContinue).ServerAddresses
    Write-Host "  $($adapter.Name): $ip ($($adapter.LinkSpeed))" -ForegroundColor White
    Write-Host "    MAC: $($adapter.MacAddress)" -ForegroundColor DarkGray
    if ($dns) { Write-Host "    DNS: $($dns -join ', ')" -ForegroundColor DarkGray }
}

# --- Firewall ---
Write-Host ""
Write-Host "[FIREWALL]" -ForegroundColor Yellow
$fwProfiles = Get-NetFirewallProfile
foreach ($profile in $fwProfiles) {
    $color = $(if ($profile.Enabled) { "Green" } else { "Red" })
    $status = $(if ($profile.Enabled) { "ON" } else { "OFF" })
    Write-Host "  $($profile.Name): $status" -ForegroundColor $color
}

# --- Defender ---
Write-Host ""
Write-Host "[WINDOWS DEFENDER]" -ForegroundColor Yellow
try {
    $defender = Get-MpComputerStatus -ErrorAction Stop
    $rtColor = $(if ($defender.RealTimeProtectionEnabled) { "Green" } else { "Red" })
    Write-Host "  Real-time: $(if ($defender.RealTimeProtectionEnabled) { 'ON' } else { 'OFF' })" -ForegroundColor $rtColor
    Write-Host "  Definitions: $($defender.AntivirusSignatureLastUpdated.ToString('yyyy-MM-dd HH:mm'))" -ForegroundColor DarkGray
    Write-Host "  Engine: $($defender.AMEngineVersion)" -ForegroundColor DarkGray
    Write-Host "  Last scan: $($defender.FullScanEndTime.ToString('yyyy-MM-dd HH:mm'))" -ForegroundColor DarkGray
} catch {
    Write-Host "  Could not query Defender" -ForegroundColor DarkGray
}

# --- Power Configuration ---
Write-Host ""
Write-Host "[POWER]" -ForegroundColor Yellow
$activePlan = powercfg /getactivescheme 2>&1
Write-Host "  Active: $activePlan" -ForegroundColor White
$hibernate = powercfg /a 2>&1 | Select-String "Hibernate"
$fastStartup = Get-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Power" -Name "HiberbootEnabled" -ErrorAction SilentlyContinue
if ($fastStartup) {
    $fsColor = $(if ($fastStartup.HiberbootEnabled -eq 0) { "Green" } else { "Yellow" })
    Write-Host "  Fast Startup: $(if ($fastStartup.HiberbootEnabled -eq 1) { 'ON' } else { 'OFF' })" -ForegroundColor $fsColor
}

# --- Installed Updates (last 10) ---
Write-Host ""
Write-Host "[RECENT UPDATES (last 10)]" -ForegroundColor Yellow
$updates = Get-HotFix | Sort-Object -Property InstalledOn -Descending | Select-Object -First 10
foreach ($upd in $updates) {
    Write-Host "  $($upd.HotFixID) - $($upd.InstalledOn.ToString('yyyy-MM-dd')) ($($upd.Description))" -ForegroundColor DarkGray
}

# --- Startup Programs ---
Write-Host ""
Write-Host "[STARTUP PROGRAMS]" -ForegroundColor Yellow
$startups = Get-CimInstance -ClassName Win32_StartupCommand
foreach ($startup in $startups) {
    Write-Host "  $($startup.Name) - $($startup.Location)" -ForegroundColor DarkGray
}

# --- WSL ---
Write-Host ""
Write-Host "[WSL]" -ForegroundColor Yellow
$wslList = wsl --list --verbose 2>&1
if ($LASTEXITCODE -eq 0) {
    $wslList | ForEach-Object { Write-Host "  $_" -ForegroundColor White }
} else {
    Write-Host "  WSL not available" -ForegroundColor DarkGray
}

# --- User Accounts ---
Write-Host ""
Write-Host "[USER ACCOUNTS]" -ForegroundColor Yellow
$users = Get-LocalUser
foreach ($user in $users) {
    $color = $(if ($user.Enabled) { "White" } else { "DarkGray" })
    $status = $(if ($user.Enabled) { "Active" } else { "Disabled" })
    Write-Host "  $($user.Name) - $status" -ForegroundColor $color
}

# --- Scheduled Tasks (AbeOS) ---
Write-Host ""
Write-Host "[ABEOS SCHEDULED TASKS]" -ForegroundColor Yellow
$tasks = schtasks /query /fo CSV 2>&1 | ConvertFrom-Csv | Where-Object { $_.TaskName -match "AbeOS|abe" }
if ($tasks) {
    foreach ($task in $tasks) {
        Write-Host "  $($task.TaskName) - $($task.Status)" -ForegroundColor White
    }
} else {
    Write-Host "  No AbeOS scheduled tasks found" -ForegroundColor DarkGray
}

Write-Host ""
Write-Host "=== System Deep Audit Complete ===" -ForegroundColor Cyan
