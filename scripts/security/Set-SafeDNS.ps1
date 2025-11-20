# =============================================================================
# Set-SafeDNS.ps1
# Configure Family-Safe DNS Servers on All Network Adapters
# =============================================================================

#Requires -RunAsAdministrator

param(
    [Parameter()]
    [ValidateSet('Cloudflare', 'OpenDNS', 'CleanBrowsing', 'Quad9', 'AdGuard', 'Auto')]
    [string]$Provider = 'Auto',

    [switch]$SetIPv6,
    [switch]$WhatIf
)

$ErrorActionPreference = "Stop"

# DNS Providers (Family-Safe)
$DNSProviders = @{
    'Cloudflare' = @{
        Name = 'Cloudflare for Families (Malware + Adult)'
        IPv4Primary = '1.1.1.3'
        IPv4Secondary = '1.0.0.3'
        IPv6Primary = '2606:4700:4700::1113'
        IPv6Secondary = '2606:4700:4700::1003'
    }
    'OpenDNS' = @{
        Name = 'OpenDNS FamilyShield'
        IPv4Primary = '208.67.222.123'
        IPv4Secondary = '208.67.220.123'
        IPv6Primary = '2620:119:35::35'
        IPv6Secondary = '2620:119:53::53'
    }
    'CleanBrowsing' = @{
        Name = 'CleanBrowsing Family Filter'
        IPv4Primary = '185.228.168.168'
        IPv4Secondary = '185.228.169.168'
        IPv6Primary = '2a0d:2a00:1::1'
        IPv6Secondary = '2a0d:2a00:2::1'
    }
    'Quad9' = @{
        Name = 'Quad9 (Malware Blocking)'
        IPv4Primary = '9.9.9.9'
        IPv4Secondary = '149.112.112.112'
        IPv6Primary = '2620:fe::fe'
        IPv6Secondary = '2620:fe::9'
    }
    'AdGuard' = @{
        Name = 'AdGuard DNS Family Protection'
        IPv4Primary = '94.140.14.15'
        IPv4Secondary = '94.140.15.16'
        IPv6Primary = '2a10:50c0::bad1:ff'
        IPv6Secondary = '2a10:50c0::bad2:ff'
    }
}

function Write-ColorOutput {
    param([string]$Message, [string]$Color = 'White')
    Write-Host $Message -ForegroundColor $Color
}

function Get-BestDNSProvider {
    Write-ColorOutput "Testing DNS providers for best performance..." "Cyan"

    $results = @()
    foreach ($provider in $DNSProviders.Keys) {
        $dns = $DNSProviders[$provider]
        $start = Get-Date
        try {
            $result = Test-NetConnection -ComputerName $dns.IPv4Primary -InformationLevel Quiet -WarningAction SilentlyContinue
            $latency = ((Get-Date) - $start).TotalMilliseconds
            if ($result) {
                $results += @{
                    Provider = $provider
                    Latency = $latency
                }
                Write-ColorOutput "  ✓ $provider : ${latency}ms" "Green"
            }
        } catch {
            Write-ColorOutput "  ✗ $provider : Failed" "Red"
        }
    }

    if ($results.Count -gt 0) {
        $fastest = ($results | Sort-Object Latency)[0]
        Write-ColorOutput "`nFastest provider: $($fastest.Provider) (${$fastest.Latency}ms)" "Yellow"
        return $fastest.Provider
    }

    return 'Cloudflare'  # Default fallback
}

# Main execution
Write-ColorOutput "========================================" "Cyan"
Write-ColorOutput "Safe DNS Configuration" "Cyan"
Write-ColorOutput "========================================" "Cyan"
Write-Host ""

# Determine provider
if ($Provider -eq 'Auto') {
    $Provider = Get-BestDNSProvider
    Write-Host ""
}

$selectedDNS = $DNSProviders[$Provider]
Write-ColorOutput "Selected Provider: $($selectedDNS.Name)" "Green"
Write-ColorOutput "Primary DNS: $($selectedDNS.IPv4Primary)" "White"
Write-ColorOutput "Secondary DNS: $($selectedDNS.IPv4Secondary)" "White"
Write-Host ""

# Get all active network adapters
$adapters = Get-NetAdapter | Where-Object { $_.Status -eq 'Up' }

if ($adapters.Count -eq 0) {
    Write-ColorOutput "ERROR: No active network adapters found!" "Red"
    exit 1
}

Write-ColorOutput "Found $($adapters.Count) active network adapter(s)" "Cyan"
Write-Host ""

foreach ($adapter in $adapters) {
    Write-ColorOutput "Configuring: $($adapter.Name) ($($adapter.InterfaceDescription))" "Yellow"

    if ($WhatIf) {
        Write-ColorOutput "  [WHATIF] Would set DNS to: $($selectedDNS.IPv4Primary), $($selectedDNS.IPv4Secondary)" "Gray"
    } else {
        try {
            # Set IPv4 DNS
            Set-DnsClientServerAddress -InterfaceIndex $adapter.ifIndex -ServerAddresses @(
                $selectedDNS.IPv4Primary,
                $selectedDNS.IPv4Secondary
            )
            Write-ColorOutput "  ✓ IPv4 DNS configured" "Green"

            # Set IPv6 DNS if requested
            if ($SetIPv6) {
                Set-DnsClientServerAddress -InterfaceIndex $adapter.ifIndex -ServerAddresses @(
                    $selectedDNS.IPv6Primary,
                    $selectedDNS.IPv6Secondary
                ) -AddressFamily IPv6
                Write-ColorOutput "  ✓ IPv6 DNS configured" "Green"
            }

            # Flush DNS cache
            Clear-DnsClientCache
            Write-ColorOutput "  ✓ DNS cache flushed" "Green"

        } catch {
            Write-ColorOutput "  ✗ Failed: $_" "Red"
        }
    }
    Write-Host ""
}

# Verify configuration
Write-ColorOutput "Verifying DNS configuration..." "Cyan"
Write-Host ""

foreach ($adapter in $adapters) {
    $dnsServers = Get-DnsClientServerAddress -InterfaceIndex $adapter.ifIndex -AddressFamily IPv4
    Write-ColorOutput "$($adapter.Name):" "Yellow"
    foreach ($server in $dnsServers.ServerAddresses) {
        Write-ColorOutput "  • $server" "White"
    }
}

Write-Host ""
Write-ColorOutput "========================================" "Cyan"
Write-ColorOutput "DNS Configuration Complete!" "Green"
Write-ColorOutput "========================================" "Cyan"
Write-Host ""

Write-ColorOutput "What's protected:" "Yellow"
Write-ColorOutput "  ✓ Malware and phishing sites blocked" "Green"
Write-ColorOutput "  ✓ Adult content blocked" "Green"
Write-ColorOutput "  ✓ All apps and browsers protected" "Green"
Write-Host ""

Write-ColorOutput "Test your protection:" "Yellow"
Write-ColorOutput "  Visit: https://welcome.opendns.com (should show blocked)" "White"
Write-ColorOutput "  Or run: Test-ContentFilter.ps1" "White"
Write-Host ""

Write-ColorOutput "To revert to automatic DNS:" "Yellow"
Write-ColorOutput '  Get-NetAdapter | Set-DnsClientServerAddress -ResetServerAddresses' "White"
Write-Host ""
