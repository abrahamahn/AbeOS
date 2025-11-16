# =============================================================================
# Test-ContentFilter.ps1
# Test Content Filtering and DNS Protection
# =============================================================================

param(
    [switch]$Detailed
)

function Write-ColorOutput {
    param([string]$Message, [string]$Color = 'White')
    Write-Host $Message -ForegroundColor $Color
}

function Test-DomainBlocking {
    param([string]$Domain, [string]$Category)

    Write-Host "  Testing: $Domain " -NoNewline

    try {
        $result = Resolve-DnsName -Name $Domain -ErrorAction Stop 2>$null

        if ($result) {
            # Check if it's a blocked IP (typical blocking IPs)
            $blockedIPs = @('0.0.0.0', '127.0.0.1', '::1', '::')
            $isBlocked = $false

            foreach ($record in $result) {
                if ($record.IPAddress -and $blockedIPs -contains $record.IPAddress) {
                    $isBlocked = $true
                    break
                }
            }

            if ($isBlocked) {
                Write-ColorOutput "✓ BLOCKED" "Green"
                return $true
            } else {
                Write-ColorOutput "✗ NOT BLOCKED (Accessible)" "Red"
                return $false
            }
        }
    } catch {
        Write-ColorOutput "✓ BLOCKED (DNS Error)" "Green"
        return $true
    }

    Write-ColorOutput "? UNKNOWN" "Yellow"
    return $false
}

Write-ColorOutput "========================================" "Cyan"
Write-ColorOutput "Content Filter Protection Test" "Cyan"
Write-ColorOutput "========================================" "Cyan"
Write-Host ""

# Check current DNS servers
Write-ColorOutput "Current DNS Configuration:" "Yellow"
$dnsServers = Get-DnsClientServerAddress -AddressFamily IPv4 | Where-Object { $_.ServerAddresses.Count -gt 0 }

foreach ($adapter in $dnsServers) {
    if ((Get-NetAdapter -InterfaceIndex $adapter.InterfaceIndex).Status -eq 'Up') {
        $adapterName = (Get-NetAdapter -InterfaceIndex $adapter.InterfaceIndex).Name
        Write-ColorOutput "  $adapterName" "White"
        foreach ($dns in $adapter.ServerAddresses) {
            # Identify DNS provider
            $provider = switch ($dns) {
                '1.1.1.3' { '(Cloudflare Family)' }
                '208.67.222.123' { '(OpenDNS FamilyShield)' }
                '185.228.168.168' { '(CleanBrowsing)' }
                '94.140.14.15' { '(AdGuard Family)' }
                '127.0.0.1' { '(AdGuard Home - Local)' }
                default { '' }
            }
            Write-ColorOutput "    • $dns $provider" "Gray"
        }
    }
}

Write-Host ""

# Test known bad domains (these should be blocked)
Write-ColorOutput "Testing Protection (Safe test domains):" "Yellow"
Write-Host ""

$testDomains = @{
    'Malware Test' = @(
        'malware.testing.google.test',
        'malware.wicar.org'
    )
    'Adult Content Test' = @(
        'test.adult-filter.com'
    )
}

$totalTests = 0
$blockedCount = 0

foreach ($category in $testDomains.Keys) {
    Write-ColorOutput "$category" "Cyan"
    foreach ($domain in $testDomains[$category]) {
        $totalTests++
        if (Test-DomainBlocking -Domain $domain -Category $category) {
            $blockedCount++
        }
    }
    Write-Host ""
}

# Calculate protection score
$protectionScore = [math]::Round(($blockedCount / $totalTests) * 100, 0)

Write-ColorOutput "========================================" "Cyan"
Write-ColorOutput "Test Results:" "Yellow"
Write-ColorOutput "========================================" "Cyan"
Write-Host ""

Write-ColorOutput "Blocked: $blockedCount / $totalTests" "White"
Write-ColorOutput "Protection Score: $protectionScore%" $(if ($protectionScore -ge 80) { "Green" } elseif ($protectionScore -ge 50) { "Yellow" } else { "Red" })
Write-Host ""

if ($protectionScore -lt 50) {
    Write-ColorOutput "⚠ WARNING: Low protection!" "Red"
    Write-ColorOutput "Recommendations:" "Yellow"
    Write-ColorOutput "  1. Run: Set-SafeDNS.ps1 -Provider Cloudflare" "White"
    Write-ColorOutput "  2. Or install: Install-AdGuardHome.ps1" "White"
    Write-Host ""
} elseif ($protectionScore -lt 80) {
    Write-ColorOutput "⚠ Moderate protection - consider additional layers" "Yellow"
    Write-Host ""
} else {
    Write-ColorOutput "✓ Good protection enabled!" "Green"
    Write-Host ""
}

# Additional checks
Write-ColorOutput "Additional Security Checks:" "Yellow"
Write-Host ""

# Check if AdGuard Home is running
Write-Host "  AdGuard Home Service: " -NoNewline
$adguardService = Get-Service -Name "AdGuardHome" -ErrorAction SilentlyContinue
if ($adguardService -and $adguardService.Status -eq 'Running') {
    Write-ColorOutput "✓ Running" "Green"
    Write-ColorOutput "    Dashboard: http://localhost:3000" "Gray"
} else {
    Write-ColorOutput "✗ Not installed/running" "Yellow"
}

# Check SafeSearch
Write-Host "  SafeSearch (Google): " -NoNewline
try {
    $googleTest = Invoke-WebRequest -Uri "https://www.google.com" -UseBasicParsing -TimeoutSec 5
    if ($googleTest.Content -match "SafeSearch") {
        Write-ColorOutput "✓ Enabled" "Green"
    } else {
        Write-ColorOutput "? Unknown" "Yellow"
    }
} catch {
    Write-ColorOutput "✗ Cannot verify" "Red"
}

# Check Windows Defender SmartScreen
Write-Host "  Windows SmartScreen: " -NoNewline
$smartScreen = Get-MpPreference -ErrorAction SilentlyContinue
if ($smartScreen -and $smartScreen.EnableNetworkProtection -eq 1) {
    Write-ColorOutput "✓ Enabled" "Green"
} else {
    Write-ColorOutput "✗ Disabled" "Yellow"
}

Write-Host ""
Write-ColorOutput "========================================" "Cyan"
Write-Host ""

if ($Detailed) {
    Write-ColorOutput "Detailed DNS Query Test:" "Yellow"
    Write-Host ""

    Write-Host "  Query for blocked domain..."
    $query = Resolve-DnsName -Name "malware.wicar.org" -Type A -ErrorAction SilentlyContinue
    if ($query) {
        $query | Format-Table -AutoSize
    } else {
        Write-ColorOutput "  Blocked (no result)" "Green"
    }
}

Write-ColorOutput "For more protection:" "Yellow"
Write-ColorOutput "  • Install AdGuard Home: Install-AdGuardHome.ps1" "White"
Write-ColorOutput "  • Configure safe DNS: Set-SafeDNS.ps1" "White"
Write-ColorOutput "  • Enable browser extensions: uBlock Origin" "White"
Write-Host ""
