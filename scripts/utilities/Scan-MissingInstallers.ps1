# =============================================================================
# Scan-MissingInstallers.ps1
# Scan existing config files for missing installers and suggest downloads
# =============================================================================

#Requires -RunAsAdministrator

[CmdletBinding()]
param(
    [Parameter(Mandatory=$false)]
    [ValidateSet("All", "Drivers", "AudioPlugins", "Apps")]
    [string]$Category = "All",

    [switch]$SuggestDownloads,
    [switch]$GenerateReport
)

$ErrorActionPreference = "Stop"

# =============================================================================
# Configuration
# =============================================================================

$ProjectRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
$DriversConfig = Join-Path $ProjectRoot "configs\installers\drivers.json"
$AudioPluginsConfig = Join-Path $ProjectRoot "configs\installers\audio-plugins.json"
$InstallersDir = Join-Path $ProjectRoot "installations\drivers"
$ReportDir = Join-Path $ProjectRoot "docs\reports"

New-Item -ItemType Directory -Path $ReportDir -Force | Out-Null

# =============================================================================
# Helper Functions
# =============================================================================

function Write-ColorOutput {
    param([string]$Message, [string]$Color = "White")
    Write-Host $Message -ForegroundColor $Color
}

function Write-Info { param([string]$Message) Write-ColorOutput "[INFO] $Message" "Cyan" }
function Write-Success { param([string]$Message) Write-ColorOutput "[✓] $Message" "Green" }
function Write-Warning { param([string]$Message) Write-ColorOutput "[!] $Message" "Yellow" }
function Write-Error-Custom { param([string]$Message) Write-ColorOutput "[✗] $Message" "Red" }
function Write-Section {
    param([string]$Message)
    Write-Host ""
    Write-ColorOutput "========================================" "Magenta"
    Write-ColorOutput $Message "Magenta"
    Write-ColorOutput "========================================" "Magenta"
    Write-Host ""
}

# =============================================================================
# Common Download URLs Database
# =============================================================================

$KnownDownloadSources = @{
    "NVIDIA GeForce Driver" = @{
        searchUrl = "https://www.nvidia.com/Download/index.aspx"
        autoDownload = $false
        notes = "Requires GPU model selection"
    }
    "AMD Chipset Driver" = @{
        searchUrl = "https://www.amd.com/en/support"
        autoDownload = $false
        notes = "Requires chipset model selection"
    }
    "Realtek Audio Driver" = @{
        searchUrl = "https://www.realtek.com/en/downloads"
        autoDownload = $false
        notes = "Multiple versions available"
    }
    "Intel Driver & Support Assistant" = @{
        directUrl = "https://www.intel.com/content/www/us/en/download/19347/intel-driver-support-assistant.html"
        autoDownload = $true
        notes = "Can detect and download Intel drivers automatically"
    }
    "Fabfilter Pro-Q 3" = @{
        searchUrl = "https://www.fabfilter.com/products/pro-q-3-equalizer-plug-in"
        autoDownload = $false
        notes = "Requires purchase/license"
    }
    "Serum" = @{
        searchUrl = "https://xferrecords.com/products/serum"
        autoDownload = $false
        notes = "Requires purchase via Splice or direct"
    }
    "Native Instruments Komplete" = @{
        searchUrl = "https://www.native-instruments.com/en/products/komplete/bundles/komplete-14/"
        autoDownload = $false
        notes = "Requires Native Access app and license"
    }
}

# =============================================================================
# Scan Functions
# =============================================================================

function Scan-DriverInstallers {
    Write-Section "Scanning Driver Installers"

    if (-not (Test-Path $DriversConfig)) {
        Write-Warning "Drivers config not found: $DriversConfig"
        return @{
            Total = 0
            Found = 0
            Missing = 0
            Drivers = @()
        }
    }

    $driversData = Get-Content $DriversConfig -Raw | ConvertFrom-Json
    $results = @{
        Total = 0
        Found = 0
        Missing = 0
        Drivers = @()
    }

    Write-Info "Checking drivers in: $InstallersDir"
    Write-Host ""

    foreach ($driver in $driversData.drivers) {
        $results.Total++

        $installerPath = Join-Path $InstallersDir $driver.installer
        $exists = Test-Path $installerPath

        $driverInfo = @{
            Name = $driver.name
            Installer = $driver.installer
            Enabled = $driver.enabled
            Silent = $driver.silent
            Arguments = $driver.arguments
            Found = $exists
            Path = $installerPath
            DownloadInfo = $null
        }

        # Check if we have download info
        if ($KnownDownloadSources.ContainsKey($driver.name)) {
            $driverInfo.DownloadInfo = $KnownDownloadSources[$driver.name]
        }

        if ($exists) {
            $results.Found++
            $fileSize = (Get-Item $installerPath).Length / 1MB
            Write-Success "$($driver.name) - Found ($([math]::Round($fileSize, 2)) MB)"
        } else {
            $results.Missing++
            Write-Warning "$($driver.name) - Missing"
            if ($driverInfo.DownloadInfo) {
                if ($driverInfo.DownloadInfo.autoDownload) {
                    Write-Info "  → Auto-download available: $($driverInfo.DownloadInfo.directUrl)"
                } else {
                    Write-Info "  → Manual download: $($driverInfo.DownloadInfo.searchUrl)"
                    Write-Info "  → Note: $($driverInfo.DownloadInfo.notes)"
                }
            }
        }

        $results.Drivers += $driverInfo
    }

    return $results
}

function Scan-AudioPluginInstallers {
    Write-Section "Scanning Audio Plugin Installers"

    if (-not (Test-Path $AudioPluginsConfig)) {
        Write-Warning "Audio plugins config not found: $AudioPluginsConfig"
        return @{
            Total = 0
            Installed = 0
            NotInstalled = 0
            Categories = @{}
        }
    }

    $pluginsData = Get-Content $AudioPluginsConfig -Raw | ConvertFrom-Json
    $results = @{
        Total = 0
        Installed = 0
        NotInstalled = 0
        Categories = @{}
    }

    foreach ($category in $pluginsData.PSObject.Properties.Name) {
        if ($category -eq "metadata") { continue }

        $categoryPlugins = $pluginsData.$category
        Write-Host ""
        Write-Info "Category: $category"
        Write-Info "Plugins: $($categoryPlugins.Count)"

        $categoryResults = @{
            Total = $categoryPlugins.Count
            Installed = 0
            NotInstalled = 0
            Plugins = @()
        }

        foreach ($plugin in $categoryPlugins) {
            $results.Total++
            $categoryResults.Total++

            $pluginInfo = @{
                Name = $plugin.name
                Publisher = $plugin.publisher
                Type = $plugin.type
                Installed = $plugin.installed
                VST3 = $plugin.vst3
                Notes = $plugin.notes
                DownloadInfo = $null
            }

            if ($plugin.installed) {
                $results.Installed++
                $categoryResults.Installed++
            } else {
                $results.NotInstalled++
                $categoryResults.NotInstalled++

                # Check if we have download info
                if ($KnownDownloadSources.ContainsKey($plugin.name)) {
                    $pluginInfo.DownloadInfo = $KnownDownloadSources[$plugin.name]
                }
            }

            $categoryResults.Plugins += $pluginInfo
        }

        $results.Categories[$category] = $categoryResults

        Write-Info "  Installed: $($categoryResults.Installed)"
        Write-Warning "  Not installed: $($categoryResults.NotInstalled)"
    }

    return $results
}

# =============================================================================
# Report Generation
# =============================================================================

function Generate-MarkdownReport {
    param(
        [hashtable]$DriverResults,
        [hashtable]$AudioResults
    )

    $reportPath = Join-Path $ReportDir "missing-installers-$(Get-Date -Format 'yyyyMMdd-HHmmss').md"

    $report = @"
# Missing Installers Report

**Generated:** $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")

---

## Executive Summary

### Drivers
- **Total:** $($DriverResults.Total)
- **Found:** $($DriverResults.Found)
- **Missing:** $($DriverResults.Missing)
- **Completion:** $([math]::Round(($DriverResults.Found / $DriverResults.Total) * 100, 1))%

### Audio Plugins
- **Total:** $($AudioResults.Total)
- **Installed:** $($AudioResults.Installed)
- **Not Installed:** $($AudioResults.NotInstalled)
- **Completion:** $([math]::Round(($AudioResults.Installed / $AudioResults.Total) * 100, 1))%

---

## Missing Drivers

| Driver Name | Installer File | Auto-Download | Download Link |
|-------------|----------------|---------------|---------------|
"@

    foreach ($driver in $DriverResults.Drivers | Where-Object { -not $_.Found }) {
        $autoDownload = if ($driver.DownloadInfo -and $driver.DownloadInfo.autoDownload) { "✓ Yes" } else { "✗ No" }
        $downloadLink = if ($driver.DownloadInfo) {
            if ($driver.DownloadInfo.directUrl) {
                "[Direct Link]($($driver.DownloadInfo.directUrl))"
            } else {
                "[Search]($($driver.DownloadInfo.searchUrl))"
            }
        } else {
            "N/A"
        }

        $report += "`n| $($driver.Name) | ``$($driver.Installer)`` | $autoDownload | $downloadLink |"
    }

    $report += @"

---

## Not Installed Audio Plugins

"@

    foreach ($category in $AudioResults.Categories.Keys | Sort-Object) {
        $categoryData = $AudioResults.Categories[$category]
        $notInstalled = $categoryData.Plugins | Where-Object { -not $_.Installed }

        if ($notInstalled.Count -gt 0) {
            $report += @"

### $category

| Plugin Name | Publisher | Type | Download Available |
|-------------|-----------|------|---------------------|
"@

            foreach ($plugin in $notInstalled) {
                $downloadAvailable = if ($plugin.DownloadInfo) { "✓" } else { "✗" }
                $report += "`n| $($plugin.Name) | $($plugin.Publisher) | $($plugin.Type) | $downloadAvailable |"
            }
        }
    }

    $report += @"

---

## Recommended Actions

### Immediate Actions (Critical)
1. Download missing hardware drivers from manufacturer websites
2. Install core DAW software (FL Studio, Ableton, Reaper)
3. Set up license management tools (Native Access, iLok)

### Short Term (High Priority)
1. Install essential plugins (synthesizers, EQs, compressors)
2. Set up VST plugin directories
3. Configure DAW plugin paths

### Long Term (Medium Priority)
1. Download remaining effect plugins
2. Install sample libraries
3. Set up template projects

---

## Download Automation Possibilities

### Fully Automatable ($($DriverResults.Drivers | Where-Object { $_.DownloadInfo.autoDownload } | Measure-Object | Select-Object -ExpandProperty Count) drivers)
"@

    foreach ($driver in $DriverResults.Drivers | Where-Object { $_.DownloadInfo.autoDownload }) {
        $report += "`n- **$($driver.Name)**: $($driver.DownloadInfo.directUrl)"
    }

    $report += @"

### Requires Manual Download
"@

    foreach ($driver in $DriverResults.Drivers | Where-Object { -not $_.Found -and $_.DownloadInfo -and -not $_.DownloadInfo.autoDownload }) {
        $report += "`n- **$($driver.Name)**: $($driver.DownloadInfo.notes)"
    }

    $report += "`n`n---`n`n*Report generated by AbeOS Scan-MissingInstallers.ps1*`n"

    $report | Set-Content $reportPath -Encoding UTF8

    Write-Success "Report saved: $reportPath"
    return $reportPath
}

# =============================================================================
# Main Execution
# =============================================================================

Write-Section "AbeOS Missing Installers Scanner"

$driverResults = @{ Total = 0; Found = 0; Missing = 0; Drivers = @() }
$audioResults = @{ Total = 0; Installed = 0; NotInstalled = 0; Categories = @{} }

# Scan based on category
if ($Category -eq "All" -or $Category -eq "Drivers") {
    $driverResults = Scan-DriverInstallers
}

if ($Category -eq "All" -or $Category -eq "AudioPlugins") {
    $audioResults = Scan-AudioPluginInstallers
}

# Generate summary
Write-Section "Summary"

if ($driverResults.Total -gt 0) {
    Write-Host "Drivers:" -ForegroundColor Yellow
    Write-Success "  Found: $($driverResults.Found) / $($driverResults.Total)"
    if ($driverResults.Missing -gt 0) {
        Write-Warning "  Missing: $($driverResults.Missing)"
    }
}

if ($audioResults.Total -gt 0) {
    Write-Host ""
    Write-Host "Audio Plugins:" -ForegroundColor Yellow
    Write-Success "  Installed: $($audioResults.Installed) / $($audioResults.Total)"
    if ($audioResults.NotInstalled -gt 0) {
        Write-Warning "  Not installed: $($audioResults.NotInstalled)"
    }
}

# Generate report
if ($GenerateReport) {
    Write-Host ""
    $reportPath = Generate-MarkdownReport -DriverResults $driverResults -AudioResults $audioResults
    Write-Host ""
    Write-Info "View report: code $reportPath"
}

Write-Host ""
Write-Section "Complete!"

Write-Host "Next steps:" -ForegroundColor Yellow
Write-Host "  1. Generate detailed report: .\Scan-MissingInstallers.ps1 -GenerateReport"
Write-Host "  2. Check available packages: ..\Check-AvailablePackages.ps1"
Write-Host "  3. Download missing installers manually or via automation"
Write-Host ""
