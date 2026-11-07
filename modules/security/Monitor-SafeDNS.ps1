# Monitor-SafeDNS.ps1 — Report DNS, SafeSearch, and content filtering status.
# Usage: .\Monitor-SafeDNS.ps1

$ErrorActionPreference = "SilentlyContinue"

Write-Host "=== AbeOS DNS & Content Filter Monitor ===" -ForegroundColor Cyan
Write-Host ""

# --- DNS Configuration ---
Write-Host "[DNS ADAPTERS]" -ForegroundColor Yellow
$adapters = Get-NetAdapter | Where-Object { $_.Status -eq "Up" }
foreach ($adapter in $adapters) {
    $dns4 = (Get-DnsClientServerAddress -InterfaceAlias $adapter.Name -AddressFamily IPv4).ServerAddresses
    $dns6 = (Get-DnsClientServerAddress -InterfaceAlias $adapter.Name -AddressFamily IPv6).ServerAddresses
    Write-Host "  $($adapter.Name)" -ForegroundColor White
    if ($dns4) {
        Write-Host "    IPv4: $($dns4 -join ', ')" -ForegroundColor DarkGray
    } else {
        Write-Host "    IPv4: DHCP (automatic)" -ForegroundColor DarkGray
    }
    if ($dns6) {
        Write-Host "    IPv6: $($dns6 -join ', ')" -ForegroundColor DarkGray
    }
}

# Identify provider
$primaryDns = (Get-DnsClientServerAddress -AddressFamily IPv4 | Where-Object { $_.ServerAddresses.Count -gt 0 } | Select-Object -First 1).ServerAddresses[0]
$providerMap = @{
    "1.1.1.3"       = "Cloudflare Family"
    "1.1.1.1"       = "Cloudflare (no filtering)"
    "208.67.222.123" = "OpenDNS FamilyShield"
    "208.67.222.222" = "OpenDNS (no filtering)"
    "185.228.168.168" = "CleanBrowsing Family"
    "9.9.9.9"        = "Quad9 (malware blocking)"
    "94.140.14.15"   = "AdGuard DNS Family"
    "127.0.0.1"      = "AdGuard Home (local)"
}
$detectedProvider = $providerMap[$primaryDns]
Write-Host ""
if ($detectedProvider) {
    Write-Host "[PROVIDER] $detectedProvider" -ForegroundColor Green
} else {
    Write-Host "[PROVIDER] Unknown ($primaryDns)" -ForegroundColor Yellow
}

# --- SafeSearch (Registry) ---
Write-Host ""
Write-Host "[SAFESEARCH]" -ForegroundColor Yellow

# Google SafeSearch (Chrome policy)
$googleSafe = Get-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Google\Chrome" -Name "ForceGoogleSafeSearch" -ErrorAction SilentlyContinue
if ($googleSafe -and $googleSafe.ForceGoogleSafeSearch -eq 1) {
    Write-Host "  Google SafeSearch: ENFORCED" -ForegroundColor Green
} else {
    Write-Host "  Google SafeSearch: NOT ENFORCED" -ForegroundColor Red
}

# Bing SafeSearch (Edge policy)
$bingSafe = Get-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Edge" -Name "ForceBingSafeSearch" -ErrorAction SilentlyContinue
if ($bingSafe -and $bingSafe.ForceBingSafeSearch -ge 1) {
    Write-Host "  Bing SafeSearch: ENFORCED (level $($bingSafe.ForceBingSafeSearch))" -ForegroundColor Green
} else {
    Write-Host "  Bing SafeSearch: NOT ENFORCED" -ForegroundColor Red
}

# --- SmartScreen ---
Write-Host ""
Write-Host "[SMARTSCREEN]" -ForegroundColor Yellow
$smartscreen = Get-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer" -Name "SmartScreenEnabled" -ErrorAction SilentlyContinue
if ($smartscreen -and $smartscreen.SmartScreenEnabled -ne "Off") {
    Write-Host "  Windows SmartScreen: ENABLED ($($smartscreen.SmartScreenEnabled))" -ForegroundColor Green
} else {
    Write-Host "  Windows SmartScreen: DISABLED" -ForegroundColor Red
}

# --- Hosts File ---
Write-Host ""
Write-Host "[HOSTS FILE]" -ForegroundColor Yellow
$hostsPath = "$env:SystemRoot\System32\drivers\etc\hosts"
if (Test-Path $hostsPath) {
    $hostsLines = Get-Content $hostsPath | Where-Object { $_ -match "^\s*0\.0\.0\.0|^\s*127\.0\.0\.1" -and $_ -notmatch "localhost" }
    Write-Host "  Blocked entries: $($hostsLines.Count)" -ForegroundColor White
} else {
    Write-Host "  Hosts file not found" -ForegroundColor Red
}

# --- DNS Resolution Test ---
Write-Host ""
Write-Host "[CONNECTIVITY TEST]" -ForegroundColor Yellow
try {
    $resolve = Resolve-DnsName -Name "google.com" -Type A -DnsOnly -ErrorAction Stop
    Write-Host "  DNS resolution: OK (google.com -> $($resolve[0].IPAddress))" -ForegroundColor Green
} catch {
    Write-Host "  DNS resolution: FAILED" -ForegroundColor Red
}

Write-Host ""
Write-Host "Done." -ForegroundColor Cyan
