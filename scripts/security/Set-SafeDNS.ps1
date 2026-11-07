# Set-SafeDNS.ps1 — Switch DNS provider on all active network adapters.
# Usage: .\Set-SafeDNS.ps1 -Provider CloudflareFamily
param(
    [Parameter(Mandatory)]
    [ValidateSet("Cloudflare", "Google", "CloudflareFamily", "OpenDNS", "CleanBrowsing", "Quad9")]
    [string]$Provider,

    [switch]$SetIPv6
)

$ErrorActionPreference = "Stop"

$dnsProviders = @{
    "Cloudflare" = @{
        Primary   = "1.1.1.1"
        Secondary = "1.0.0.1"
        IPv6Pri   = "2606:4700:4700::1111"
        IPv6Sec   = "2606:4700:4700::1001"
        Label     = "Cloudflare (fastest, lowest latency)"
    }
    "Google" = @{
        Primary   = "8.8.8.8"
        Secondary = "8.8.4.4"
        IPv6Pri   = "2001:4860:4860::8888"
        IPv6Sec   = "2001:4860:4860::8844"
        Label     = "Google DNS (reliable, low latency)"
    }
    "CloudflareFamily" = @{
        Primary   = "1.1.1.3"
        Secondary = "1.0.0.3"
        IPv6Pri   = "2606:4700:4700::1113"
        IPv6Sec   = "2606:4700:4700::1003"
        Label     = "Cloudflare Family (malware + adult blocking)"
    }
    "OpenDNS" = @{
        Primary   = "208.67.222.123"
        Secondary = "208.67.220.123"
        IPv6Pri   = "::ffff:208.67.222.123"
        IPv6Sec   = "::ffff:208.67.220.123"
        Label     = "OpenDNS FamilyShield"
    }
    "CleanBrowsing" = @{
        Primary   = "185.228.168.168"
        Secondary = "185.228.169.168"
        IPv6Pri   = "2a0d:2a00:1::"
        IPv6Sec   = "2a0d:2a00:2::"
        Label     = "CleanBrowsing Family Filter"
    }
    "Quad9" = @{
        Primary   = "9.9.9.9"
        Secondary = "149.112.112.112"
        IPv6Pri   = "2620:fe::fe"
        IPv6Sec   = "2620:fe::9"
        Label     = "Quad9 (malware blocking)"
    }
}

$dns = $dnsProviders[$Provider]

Write-Host "=== AbeOS Safe DNS ===" -ForegroundColor Cyan
Write-Host "Provider: $($dns.Label)" -ForegroundColor White
Write-Host "DNS: $($dns.Primary), $($dns.Secondary)" -ForegroundColor DarkGray
Write-Host ""

# Get active physical adapters (skip virtual, Bluetooth, etc.)
$adapters = Get-NetAdapter | Where-Object {
    $_.Status -eq "Up" -and
    $_.InterfaceDescription -notmatch "Virtual|Bluetooth|Loopback"
}

if ($adapters.Count -eq 0) {
    Write-Host "[WARN] No active network adapters found." -ForegroundColor Yellow
    exit 1
}

foreach ($adapter in $adapters) {
    $name = $adapter.Name
    Write-Host "[$name]" -ForegroundColor Yellow

    # Read current DNS
    $currentDns = (Get-DnsClientServerAddress -InterfaceAlias $name -AddressFamily IPv4).ServerAddresses
    if ($currentDns) {
        Write-Host "  Current: $($currentDns -join ', ')" -ForegroundColor DarkGray
    } else {
        Write-Host "  Current: DHCP (automatic)" -ForegroundColor DarkGray
    }

    # Check if already set
    if ($currentDns -and $currentDns[0] -eq $dns.Primary) {
        Write-Host "  [OK] Already set to $Provider" -ForegroundColor Green
    } else {
        Set-DnsClientServerAddress -InterfaceAlias $name -ServerAddresses @($dns.Primary, $dns.Secondary)
        Write-Host "  [SET] IPv4 -> $($dns.Primary), $($dns.Secondary)" -ForegroundColor Green
    }

    if ($SetIPv6) {
        Set-DnsClientServerAddress -InterfaceAlias $name -ServerAddresses @($dns.IPv6Pri, $dns.IPv6Sec) -ErrorAction SilentlyContinue
        Write-Host "  [SET] IPv6 -> $($dns.IPv6Pri), $($dns.IPv6Sec)" -ForegroundColor Green
    }
}

# Flush DNS cache
Write-Host ""
Write-Host "Flushing DNS cache..." -ForegroundColor DarkGray
Clear-DnsClientCache
Write-Host "[OK] DNS cache flushed." -ForegroundColor Green

# Verify
Write-Host ""
Write-Host "=== Verification ===" -ForegroundColor Cyan
foreach ($adapter in $adapters) {
    $verify = (Get-DnsClientServerAddress -InterfaceAlias $adapter.Name -AddressFamily IPv4).ServerAddresses
    Write-Host "  $($adapter.Name): $($verify -join ', ')" -ForegroundColor White
}
Write-Host ""
Write-Host "Done." -ForegroundColor Cyan
