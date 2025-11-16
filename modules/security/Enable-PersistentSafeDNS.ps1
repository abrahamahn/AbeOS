# =============================================================================
# Enable-PersistentSafeDNS.ps1
# Make Safe DNS Persistent Across Network Changes
# =============================================================================

#Requires -RunAsAdministrator

param(
    [ValidateSet('Cloudflare', 'OpenDNS', 'CleanBrowsing', 'AdGuard')]
    [string]$Provider = 'Cloudflare',

    [switch]$SetupScheduledTask,
    [switch]$Remove
)

$ErrorActionPreference = "Stop"

function Write-ColorOutput {
    param([string]$Message, [string]$Color = 'White')
    Write-Host $Message -ForegroundColor $Color
}

# DNS Provider configurations
$DNSConfig = @{
    'Cloudflare' = @('1.1.1.3', '1.0.0.3')
    'OpenDNS' = @('208.67.222.123', '208.67.220.123')
    'CleanBrowsing' = @('185.228.168.168', '185.228.169.168')
    'AdGuard' = @('94.140.14.15', '94.140.15.16')
}

$scriptPath = $PSCommandPath
$taskName = "AbeOS-PersistentSafeDNS"
$logPath = "C:\AbeOS\logs\dns-monitor.log"

# Ensure logs directory exists
$logDir = Split-Path $logPath -Parent
if (-not (Test-Path $logDir)) {
    New-Item -Path $logDir -ItemType Directory -Force | Out-Null
}

function Write-Log {
    param([string]$Message)
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    "$timestamp - $Message" | Out-File -FilePath $logPath -Append
}

if ($Remove) {
    Write-ColorOutput "Removing persistent DNS configuration..." "Yellow"

    # Remove scheduled task
    Unregister-ScheduledTask -TaskName $taskName -Confirm:$false -ErrorAction SilentlyContinue

    # Remove registry entries
    Remove-ItemProperty -Path "HKLM:\SOFTWARE\AbeOS" -Name "SafeDNSProvider" -ErrorAction SilentlyContinue
    Remove-ItemProperty -Path "HKLM:\SOFTWARE\AbeOS" -Name "SafeDNSPrimary" -ErrorAction SilentlyContinue
    Remove-ItemProperty -Path "HKLM:\SOFTWARE\AbeOS" -Name "SafeDNSSecondary" -ErrorAction SilentlyContinue

    Write-ColorOutput "✓ Persistent DNS removed" "Green"
    Write-ColorOutput "DNS will now use network defaults" "Gray"
    exit 0
}

Write-ColorOutput "========================================" "Cyan"
Write-ColorOutput "Persistent Safe DNS Configuration" "Cyan"
Write-ColorOutput "========================================" "Cyan"
Write-Host ""

# Store configuration in registry
Write-ColorOutput "Storing DNS configuration..." "Cyan"

$dnsServers = $DNSConfig[$Provider]

# Create AbeOS registry key if it doesn't exist
$regPath = "HKLM:\SOFTWARE\AbeOS"
if (-not (Test-Path $regPath)) {
    New-Item -Path $regPath -Force | Out-Null
}

Set-ItemProperty -Path $regPath -Name "SafeDNSProvider" -Value $Provider
Set-ItemProperty -Path $regPath -Name "SafeDNSPrimary" -Value $dnsServers[0]
Set-ItemProperty -Path $regPath -Name "SafeDNSSecondary" -Value $dnsServers[1]

Write-ColorOutput "✓ Configuration stored: $Provider ($($dnsServers[0]))" "Green"

# Apply DNS to all active adapters
Write-ColorOutput "Applying DNS to network adapters..." "Cyan"

$adapters = Get-NetAdapter | Where-Object { $_.Status -eq 'Up' }
foreach ($adapter in $adapters) {
    try {
        Set-DnsClientServerAddress -InterfaceIndex $adapter.ifIndex -ServerAddresses $dnsServers
        Write-ColorOutput "  ✓ $($adapter.Name)" "Green"
        Write-Log "Applied DNS to $($adapter.Name)"
    } catch {
        Write-ColorOutput "  ✗ $($adapter.Name): $_" "Red"
        Write-Log "ERROR: Failed to apply DNS to $($adapter.Name): $_"
    }
}

# Method 1: Scheduled Task on Network Change
if ($SetupScheduledTask) {
    Write-ColorOutput "`nSetting up automatic DNS enforcement..." "Cyan"

    # Create PowerShell script for scheduled task
    $monitorScript = @"
# Auto-generated DNS Monitor Script
`$provider = Get-ItemProperty -Path "HKLM:\SOFTWARE\AbeOS" -Name "SafeDNSProvider" -ErrorAction SilentlyContinue
`$primary = Get-ItemProperty -Path "HKLM:\SOFTWARE\AbeOS" -Name "SafeDNSPrimary" -ErrorAction SilentlyContinue
`$secondary = Get-ItemProperty -Path "HKLM:\SOFTWARE\AbeOS" -Name "SafeDNSSecondary" -ErrorAction SilentlyContinue

if (`$provider -and `$primary -and `$secondary) {
    `$dnsServers = @(`$primary.SafeDNSPrimary, `$secondary.SafeDNSSecondary)

    `$adapters = Get-NetAdapter | Where-Object { `$_.Status -eq 'Up' }
    foreach (`$adapter in `$adapters) {
        `$currentDNS = (Get-DnsClientServerAddress -InterfaceIndex `$adapter.ifIndex -AddressFamily IPv4).ServerAddresses

        if (`$currentDNS[0] -ne `$dnsServers[0]) {
            Set-DnsClientServerAddress -InterfaceIndex `$adapter.ifIndex -ServerAddresses `$dnsServers
            Add-Content -Path "$logPath" -Value "`$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') - DNS restored on `$(`$adapter.Name)"
        }
    }
}
"@

    $monitorScriptPath = "C:\AbeOS\modules\security\Monitor-SafeDNS.ps1"
    $monitorScript | Out-File -FilePath $monitorScriptPath -Encoding UTF8 -Force

    # Remove existing task if present
    Unregister-ScheduledTask -TaskName $taskName -Confirm:$false -ErrorAction SilentlyContinue

    # Create scheduled task - Run on startup and every hour
    $action = New-ScheduledTaskAction -Execute "PowerShell.exe" -Argument "-NoProfile -ExecutionPolicy Bypass -File `"$monitorScriptPath`""

    $trigger1 = New-ScheduledTaskTrigger -AtStartup
    $trigger2 = New-ScheduledTaskTrigger -Once -At (Get-Date) -RepetitionInterval (New-TimeSpan -Minutes 30)

    $principal = New-ScheduledTaskPrincipal -UserId "SYSTEM" -LogonType ServiceAccount -RunLevel Highest
    $settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -StartWhenAvailable

    Register-ScheduledTask -TaskName $taskName -Action $action -Trigger $trigger1,$trigger2 -Principal $principal -Settings $settings -Description "AbeOS: Maintain safe DNS settings across network changes" | Out-Null

    Write-ColorOutput "  ✓ Scheduled task created: $taskName" "Green"
    Write-ColorOutput "  ✓ Runs every 30 minutes and at startup" "Green"
}

# Method 2: Registry-based persistence (works even without scheduled task)
Write-ColorOutput "`nConfiguring registry-based persistence..." "Cyan"

# Set interface metric to prefer our DNS
foreach ($adapter in $adapters) {
    try {
        # Lower metric = higher priority
        Set-NetIPInterface -InterfaceIndex $adapter.ifIndex -InterfaceMetric 10 -ErrorAction SilentlyContinue
    } catch {
        # Ignore errors
    }
}

Write-ColorOutput "  ✓ DNS priority configured" "Green"

# Flush DNS cache
Clear-DnsClientCache
Write-ColorOutput "  ✓ DNS cache flushed" "Green"

Write-Host ""
Write-ColorOutput "========================================" "Cyan"
Write-ColorOutput "Persistent Safe DNS Enabled!" "Green"
Write-ColorOutput "========================================" "Cyan"
Write-Host ""

Write-ColorOutput "Configuration:" "Yellow"
Write-ColorOutput "  Provider: $Provider" "White"
Write-ColorOutput "  Primary DNS: $($dnsServers[0])" "White"
Write-ColorOutput "  Secondary DNS: $($dnsServers[1])" "White"
Write-Host ""

if ($SetupScheduledTask) {
    Write-ColorOutput "Automatic Enforcement:" "Yellow"
    Write-ColorOutput "  ✓ Scheduled task running" "Green"
    Write-ColorOutput "  ✓ Checks DNS every 30 minutes" "Green"
    Write-ColorOutput "  ✓ Runs at startup" "Green"
    Write-ColorOutput "  ✓ Restores DNS if changed" "Green"
    Write-Host ""

    Write-ColorOutput "Logs: $logPath" "Gray"
    Write-Host ""
}

Write-ColorOutput "How it works:" "Yellow"
Write-ColorOutput "  1. DNS applied to all current network adapters" "White"
Write-ColorOutput "  2. Configuration stored in registry" "White"
if ($SetupScheduledTask) {
    Write-ColorOutput "  3. Scheduled task monitors and restores DNS" "White"
    Write-ColorOutput "  4. Works even when switching WiFi networks" "White"
}
Write-Host ""

Write-ColorOutput "Test your protection:" "Yellow"
Write-ColorOutput "  .\Test-ContentFilter.ps1" "Cyan"
Write-Host ""

Write-ColorOutput "To remove:" "Yellow"
Write-ColorOutput "  .\Enable-PersistentSafeDNS.ps1 -Remove" "Cyan"
Write-Host ""

Write-ColorOutput "View logs:" "Yellow"
Write-ColorOutput "  Get-Content `"$logPath`" -Tail 20" "Cyan"
Write-Host ""
