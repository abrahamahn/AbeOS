# =============================================================================
# Install-AdGuardHome.ps1
# Install and Configure AdGuard Home for Local DNS Filtering
# =============================================================================

#Requires -RunAsAdministrator

param(
    [string]$InstallPath = "C:\Program Files\AdGuardHome",
    [int]$WebPort = 3000,
    [int]$DNSPort = 53,
    [switch]$SkipServiceInstall,
    [switch]$WhatIf
)

$ErrorActionPreference = "Stop"

function Write-ColorOutput {
    param([string]$Message, [string]$Color = 'White')
    Write-Host $Message -ForegroundColor $Color
}

Write-ColorOutput "========================================" "Cyan"
Write-ColorOutput "AdGuard Home Installation" "Cyan"
Write-ColorOutput "========================================" "Cyan"
Write-Host ""

# Check if already installed
if (Test-Path "$InstallPath\AdGuardHome.exe") {
    Write-ColorOutput "AdGuard Home is already installed!" "Yellow"
    $response = Read-Host "Reinstall? (y/N)"
    if ($response -ne 'y') {
        Write-ColorOutput "Installation cancelled" "Yellow"
        exit 0
    }
}

# Download latest release
Write-ColorOutput "Downloading AdGuard Home..." "Cyan"
$downloadUrl = "https://static.adtidy.org/adguardhome/release/AdGuardHome_windows_amd64.zip"
$zipPath = "$env:TEMP\AdGuardHome.zip"
$extractPath = "$env:TEMP\AdGuardHome"

try {
    if (-not $WhatIf) {
        Invoke-WebRequest -Uri $downloadUrl -OutFile $zipPath -UseBasicParsing
        Write-ColorOutput "✓ Downloaded successfully" "Green"
    } else {
        Write-ColorOutput "[WHATIF] Would download from: $downloadUrl" "Gray"
    }
} catch {
    Write-ColorOutput "✗ Download failed: $_" "Red"
    exit 1
}

# Extract
Write-ColorOutput "Extracting..." "Cyan"
if (-not $WhatIf) {
    Expand-Archive -Path $zipPath -DestinationPath $extractPath -Force

    # Create install directory
    if (-not (Test-Path $InstallPath)) {
        New-Item -Path $InstallPath -ItemType Directory -Force | Out-Null
    }

    # Copy files
    Copy-Item -Path "$extractPath\AdGuardHome\*" -Destination $InstallPath -Recurse -Force
    Write-ColorOutput "✓ Extracted to: $InstallPath" "Green"
}

# Clean up
Remove-Item $zipPath -Force -ErrorAction SilentlyContinue
Remove-Item $extractPath -Recurse -Force -ErrorAction SilentlyContinue

# Create configuration
Write-ColorOutput "Creating configuration..." "Cyan"

$configYaml = @"
bind_host: 127.0.0.1
bind_port: $WebPort
users:
  - name: admin
    password: "" # Will be set on first login

http_proxy: ""
language: en
theme: auto

dns:
  bind_hosts:
    - 127.0.0.1
  port: $DNSPort
  anonymize_client_ip: false
  protection_enabled: true
  blocking_mode: default
  blocking_ipv4: ""
  blocking_ipv6: ""
  blocked_response_ttl: 10
  parental_block_host: family-block.dns.adguard.com
  safebrowsing_block_host: standard-block.dns.adguard.com
  ratelimit: 0
  refuse_any: true
  upstream_dns:
    - https://dns.cloudflare.com/dns-query
    - https://dns.google/dns-query
  upstream_dns_file: ""
  bootstrap_dns:
    - 1.1.1.1
    - 8.8.8.8
  all_servers: false
  fastest_addr: false
  fastest_timeout: 1s
  allowed_clients: []
  disallowed_clients: []
  blocked_hosts:
    - version.bind
    - id.server
    - hostname.bind
  cache_size: 4194304
  cache_ttl_min: 0
  cache_ttl_max: 0
  cache_optimistic: false
  bogus_nxdomain: []
  aaaa_disabled: false
  enable_dnssec: false
  edns_client_subnet: false
  max_goroutines: 300
  ipset: []
  filtering_enabled: true
  filters_update_interval: 24
  parental_enabled: true
  safebrowsing_enabled: true
  safesearch_enabled: true

tls:
  enabled: false

filters:
  - enabled: true
    url: https://adguardteam.github.io/HostlistsRegistry/assets/filter_1.txt
    name: AdGuard DNS filter
    id: 1
  - enabled: true
    url: https://adguardteam.github.io/HostlistsRegistry/assets/filter_2.txt
    name: AdAway Default Blocklist
    id: 2
  - enabled: true
    url: https://big.oisd.nl/
    name: OISD Big List
    id: 3
  - enabled: true
    url: https://raw.githubusercontent.com/StevenBlack/hosts/master/alternates/fakenews-gambling-porn/hosts
    name: Steven Black (Malware + Adult + Gambling)
    id: 4
  - enabled: true
    url: https://block.energized.pro/ultimate/formats/hosts.txt
    name: Energized Ultimate
    id: 5

whitelist_filters: []

user_rules: []

dhcp:
  enabled: false

clients:
  runtime_sources:
    whois: true
    arp: true
    rdns: true
    dhcp: true
    hosts: true
  persistent: []

log_compress: false
log_localtime: false
log_max_backups: 0
log_max_size: 100
log_max_age: 3
log_file: ""

verbose: false

os:
  group: ""
  user: ""
  rlimit_nofile: 0

schema_version: 20
"@

$configPath = "$InstallPath\AdGuardHome.yaml"
if (-not $WhatIf) {
    $configYaml | Out-File -FilePath $configPath -Encoding UTF8
    Write-ColorOutput "✓ Configuration created" "Green"
}

# Install as Windows Service
if (-not $SkipServiceInstall -and -not $WhatIf) {
    Write-ColorOutput "Installing Windows Service..." "Cyan"

    # Stop existing service if running
    $service = Get-Service -Name "AdGuardHome" -ErrorAction SilentlyContinue
    if ($service) {
        Stop-Service -Name "AdGuardHome" -Force
        & "$InstallPath\AdGuardHome.exe" -s uninstall
    }

    # Install service
    & "$InstallPath\AdGuardHome.exe" -s install
    Start-Service -Name "AdGuardHome"
    Write-ColorOutput "✓ Service installed and started" "Green"
}

# Configure firewall
Write-ColorOutput "Configuring Windows Firewall..." "Cyan"
if (-not $WhatIf) {
    New-NetFirewallRule -DisplayName "AdGuard Home - Web UI" -Direction Inbound -LocalPort $WebPort -Protocol TCP -Action Allow -ErrorAction SilentlyContinue
    New-NetFirewallRule -DisplayName "AdGuard Home - DNS" -Direction Inbound -LocalPort $DNSPort -Protocol UDP -Action Allow -ErrorAction SilentlyContinue
    Write-ColorOutput "✓ Firewall rules added" "Green"
}

Write-Host ""
Write-ColorOutput "========================================" "Cyan"
Write-ColorOutput "AdGuard Home Installation Complete!" "Green"
Write-ColorOutput "========================================" "Cyan"
Write-Host ""

Write-ColorOutput "Next steps:" "Yellow"
Write-ColorOutput "  1. Open: http://localhost:$WebPort" "White"
Write-ColorOutput "  2. Complete initial setup wizard" "White"
Write-ColorOutput "  3. Set admin password" "White"
Write-ColorOutput "  4. Configure system DNS to 127.0.0.1:" "White"
Write-ColorOutput "     Run: Set-SafeDNS.ps1 -Provider AdGuard" "Cyan"
Write-Host ""

Write-ColorOutput "Configuration:" "Yellow"
Write-ColorOutput "  Install Path: $InstallPath" "White"
Write-ColorOutput "  Web UI: http://localhost:$WebPort" "White"
Write-ColorOutput "  DNS Port: $DNSPort" "White"
Write-ColorOutput "  Config: $configPath" "White"
Write-Host ""

Write-ColorOutput "Pre-configured blocklists:" "Yellow"
Write-ColorOutput "  ✓ AdGuard DNS filter" "Green"
Write-ColorOutput "  ✓ OISD Big List (comprehensive)" "Green"
Write-ColorOutput "  ✓ Steven Black (malware + adult + gambling)" "Green"
Write-ColorOutput "  ✓ Energized Ultimate" "Green"
Write-Host ""

Write-ColorOutput "Service management:" "Yellow"
Write-ColorOutput "  Start:   Start-Service AdGuardHome" "White"
Write-ColorOutput "  Stop:    Stop-Service AdGuardHome" "White"
Write-ColorOutput "  Status:  Get-Service AdGuardHome" "White"
Write-Host ""
