# =============================================================================
# Test-DNSSpeed.ps1
# Test and Compare DNS Server Performance
# =============================================================================

param(
    [int]$Iterations = 10,
    [switch]$Detailed
)

function Write-ColorOutput {
    param([string]$Message, [string]$Color = 'White')
    Write-Host $Message -ForegroundColor $Color
}

function Test-DNSPerformance {
    param(
        [string]$DNSServer,
        [string]$Name,
        [array]$TestDomains
    )

    $results = @()

    foreach ($domain in $TestDomains) {
        $totalTime = 0
        $successCount = 0

        for ($i = 0; $i -lt $Iterations; $i++) {
            try {
                $start = Get-Date
                Resolve-DnsName -Name $domain -Server $DNSServer -DnsOnly -ErrorAction Stop | Out-Null
                $end = Get-Date
                $latency = ($end - $start).TotalMilliseconds
                $totalTime += $latency
                $successCount++
            } catch {
                # Ignore errors
            }
        }

        if ($successCount -gt 0) {
            $avgLatency = $totalTime / $successCount
            $results += $avgLatency
        }
    }

    if ($results.Count -gt 0) {
        $avgTotal = ($results | Measure-Object -Average).Average
        return [math]::Round($avgTotal, 2)
    }

    return $null
}

Write-ColorOutput "========================================" "Cyan"
Write-ColorOutput "DNS Speed Comparison Test" "Cyan"
Write-ColorOutput "========================================" "Cyan"
Write-Host ""

Write-ColorOutput "Testing with $Iterations queries per domain..." "Gray"
Write-Host ""

# Test domains (mix of popular sites)
$testDomains = @(
    'google.com',
    'youtube.com',
    'amazon.com',
    'facebook.com',
    'twitter.com',
    'reddit.com',
    'github.com',
    'microsoft.com'
)

# DNS servers to test
$dnsServers = @{
    'Your ISP (Current)' = (Get-DnsClientServerAddress -AddressFamily IPv4 | Where-Object {$_.ServerAddresses.Count -gt 0} | Select-Object -First 1).ServerAddresses[0]
    'Cloudflare (1.1.1.1)' = '1.1.1.1'
    'Cloudflare Family (1.1.1.3)' = '1.1.1.3'
    'Google DNS (8.8.8.8)' = '8.8.8.8'
    'OpenDNS (208.67.222.222)' = '208.67.222.222'
    'OpenDNS Family (208.67.222.123)' = '208.67.222.123'
    'Quad9 (9.9.9.9)' = '9.9.9.9'
}

if ((Get-Service -Name "AdGuardHome" -ErrorAction SilentlyContinue).Status -eq 'Running') {
    $dnsServers['AdGuard Home (Local)'] = '127.0.0.1'
}

$results = @{}

foreach ($server in $dnsServers.Keys) {
    Write-Host "Testing: $server ($($dnsServers[$server]))... " -NoNewline

    $avgLatency = Test-DNSPerformance -DNSServer $dnsServers[$server] -Name $server -TestDomains $testDomains

    if ($avgLatency) {
        $results[$server] = $avgLatency
        Write-ColorOutput "$avgLatency ms" "Green"
    } else {
        Write-ColorOutput "FAILED" "Red"
    }
}

Write-Host ""
Write-ColorOutput "========================================" "Cyan"
Write-ColorOutput "Results Summary" "Yellow"
Write-ColorOutput "========================================" "Cyan"
Write-Host ""

# Sort by speed (fastest first)
$sorted = $results.GetEnumerator() | Sort-Object Value

$rank = 1
foreach ($entry in $sorted) {
    $medal = switch ($rank) {
        1 { "🥇" }
        2 { "🥈" }
        3 { "🥉" }
        default { "  " }
    }

    $color = switch ($rank) {
        1 { "Green" }
        2 { "Yellow" }
        3 { "White" }
        default { "Gray" }
    }

    $name = $entry.Key.PadRight(30)
    $speed = "$($entry.Value) ms"

    Write-Host "$medal " -NoNewline
    Write-ColorOutput "$name $speed" $color

    $rank++
}

Write-Host ""

# Speed difference calculation
$fastest = ($sorted | Select-Object -First 1).Value
$slowest = ($sorted | Select-Object -Last 1).Value
$difference = $slowest - $fastest
$percentDiff = [math]::Round((($difference / $slowest) * 100), 1)

Write-ColorOutput "Performance Analysis:" "Yellow"
Write-ColorOutput "  Fastest: $fastest ms" "Green"
Write-ColorOutput "  Slowest: $slowest ms" "Red"
Write-ColorOutput "  Difference: $difference ms ($percentDiff% improvement)" "Cyan"
Write-Host ""

# Check if safe DNS is faster than current
$currentDNS = $results['Your ISP (Current)']
$cloudflareFamily = $results['Cloudflare Family (1.1.1.3)']

if ($cloudflareFamily -and $currentDNS) {
    if ($cloudflareFamily -lt $currentDNS) {
        $improvement = $currentDNS - $cloudflareFamily
        $percentImprovement = [math]::Round((($improvement / $currentDNS) * 100), 1)

        Write-ColorOutput "💡 Good News!" "Green"
        Write-ColorOutput "  Cloudflare Family (safe DNS) is ${improvement}ms FASTER than your ISP!" "Green"
        Write-ColorOutput "  That's a $percentImprovement% speed IMPROVEMENT with filtering!" "Green"
        Write-Host ""
    }
}

# AdGuard Home check
if ($results.ContainsKey('AdGuard Home (Local)')) {
    $adguardSpeed = $results['AdGuard Home (Local)']

    Write-ColorOutput "🏠 AdGuard Home (Local Filtering):" "Cyan"
    Write-ColorOutput "  Speed: $adguardSpeed ms" "White"

    if ($adguardSpeed -lt 5) {
        Write-ColorOutput "  Status: ⚡ EXCELLENT (local caching)" "Green"
    } elseif ($adguardSpeed -lt 20) {
        Write-ColorOutput "  Status: ✅ VERY GOOD" "Green"
    } else {
        Write-ColorOutput "  Status: ⚠️ Acceptable" "Yellow"
    }

    Write-Host ""
    Write-ColorOutput "  Benefits:" "Yellow"
    Write-ColorOutput "    • Blocks ads = Faster page loads" "Green"
    Write-ColorOutput "    • Local caching = Instant repeat lookups" "Green"
    Write-ColorOutput "    • Blocks trackers = Less bandwidth used" "Green"
}

Write-Host ""
Write-ColorOutput "========================================" "Cyan"
Write-ColorOutput "Recommendation" "Yellow"
Write-ColorOutput "========================================" "Cyan"
Write-Host ""

$recommended = ($sorted | Select-Object -First 1).Key

Write-ColorOutput "Fastest DNS: $recommended" "Green"
Write-ColorOutput "Speed: $fastest ms" "Green"
Write-Host ""

if ($recommended -match "Family|OpenDNS Family|Quad9") {
    Write-ColorOutput "✅ BONUS: This DNS includes content filtering!" "Green"
    Write-ColorOutput "   You get speed AND safety!" "Green"
} else {
    Write-ColorOutput "⚠️ Note: This DNS does not include content filtering" "Yellow"
    Write-ColorOutput "   For safety + speed, use: Cloudflare Family" "Cyan"
}

Write-Host ""
Write-ColorOutput "Apply fastest safe DNS:" "Yellow"
Write-ColorOutput "  .\Set-SafeDNS.ps1 -Provider Cloudflare" "Cyan"
Write-ColorOutput "  .\Enable-PersistentSafeDNS.ps1 -Provider Cloudflare -SetupScheduledTask" "Cyan"
Write-Host ""

if ($Detailed) {
    Write-ColorOutput "========================================" "Cyan"
    Write-ColorOutput "Detailed Analysis" "Yellow"
    Write-ColorOutput "========================================" "Cyan"
    Write-Host ""

    Write-ColorOutput "Why Safe DNS is Often FASTER:" "Yellow"
    Write-Host ""
    Write-ColorOutput "1. ISP DNS Issues:" "Cyan"
    Write-ColorOutput "   • Often slower and less reliable" "White"
    Write-ColorOutput "   • May inject ads (slowing down pages)" "White"
    Write-ColorOutput "   • Less infrastructure investment" "White"
    Write-Host ""

    Write-ColorOutput "2. Cloudflare/Google Benefits:" "Cyan"
    Write-ColorOutput "   • Global network of servers" "White"
    Write-ColorOutput "   • Anycast routing (closest server)" "White"
    Write-ColorOutput "   • Better caching" "White"
    Write-ColorOutput "   • No logging = faster processing" "White"
    Write-Host ""

    Write-ColorOutput "3. Blocking = Speed Boost:" "Cyan"
    Write-ColorOutput "   • Ads blocked = Fewer resources to load" "White"
    Write-ColorOutput "   • Trackers blocked = Less bandwidth" "White"
    Write-ColorOutput "   • Malware blocked = No redirects" "White"
    Write-Host ""

    Write-ColorOutput "Real-world impact:" "Yellow"
    Write-ColorOutput "  • DNS lookup: 2-50ms" "Gray"
    Write-ColorOutput "  • Ad trackers blocked: Save 100-500ms PER PAGE" "Green"
    Write-ColorOutput "  • Malware/redirects blocked: Save 1000+ ms" "Green"
    Write-Host ""
}
