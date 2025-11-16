# =============================================================================
# Check-AvailablePackages.ps1
# Check availability of packages across multiple sources and auto-download
# =============================================================================

#Requires -RunAsAdministrator

[CmdletBinding()]
param(
    [Parameter(Mandatory=$false)]
    [string]$ConfigFile = "$PSScriptRoot\..\..\configs\installers\auto-download.json",

    [switch]$Download,
    [switch]$CheckOnly,
    [switch]$UpdateUrls
)

$ErrorActionPreference = "Stop"

# =============================================================================
# Configuration
# =============================================================================

$DownloadDirectory = "C:\AbeOS\downloads\installers"
$CacheFile = "$PSScriptRoot\..\..\configs\cache\package-availability.json"

# Ensure directories exist
New-Item -ItemType Directory -Path $DownloadDirectory -Force | Out-Null
New-Item -ItemType Directory -Path (Split-Path $CacheFile) -Force | Out-Null

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
# Package Manager Checks
# =============================================================================

function Test-WingetAvailable {
    param([string]$PackageId)

    try {
        $result = winget search --id $PackageId --exact 2>&1
        if ($LASTEXITCODE -eq 0) {
            return @{
                Available = $true
                Source = "winget"
                PackageId = $PackageId
                Method = "winget install $PackageId"
            }
        }
    } catch {}

    return @{ Available = $false }
}

function Test-ChocoAvailable {
    param([string]$PackageName)

    try {
        $result = choco search $PackageName --exact --limit-output 2>&1
        if ($result -and $result -notmatch "0 packages found") {
            return @{
                Available = $true
                Source = "chocolatey"
                PackageId = $PackageName
                Method = "choco install $PackageName -y"
            }
        }
    } catch {}

    return @{ Available = $false }
}

function Test-ScoopAvailable {
    param([string]$PackageName)

    if (-not (Get-Command scoop -ErrorAction SilentlyContinue)) {
        return @{ Available = $false }
    }

    try {
        $result = scoop search $PackageName 2>&1
        if ($result -match $PackageName) {
            return @{
                Available = $true
                Source = "scoop"
                PackageId = $PackageName
                Method = "scoop install $PackageName"
            }
        }
    } catch {}

    return @{ Available = $false }
}

# =============================================================================
# Direct Download Functions
# =============================================================================

function Get-LatestGitHubRelease {
    param(
        [string]$Repo,  # Format: "owner/repo"
        [string]$AssetPattern = "\.exe$|\.msi$"
    )

    try {
        $apiUrl = "https://api.github.com/repos/$Repo/releases/latest"
        $headers = @{
            "User-Agent" = "AbeOS-PackageManager"
        }

        $release = Invoke-RestMethod -Uri $apiUrl -Headers $headers
        $asset = $release.assets | Where-Object { $_.name -match $AssetPattern } | Select-Object -First 1

        if ($asset) {
            return @{
                Available = $true
                Source = "GitHub"
                Url = $asset.browser_download_url
                Version = $release.tag_name
                Filename = $asset.name
                Size = [math]::Round($asset.size / 1MB, 2)
            }
        }
    } catch {
        Write-Verbose "GitHub API error for $Repo : $_"
    }

    return @{ Available = $false }
}

function Test-DirectDownloadUrl {
    param([string]$Url)

    try {
        $response = Invoke-WebRequest -Uri $Url -Method Head -UseBasicParsing -TimeoutSec 10

        if ($response.StatusCode -eq 200) {
            $filename = [System.IO.Path]::GetFileName($Url)
            if ($response.Headers["Content-Disposition"]) {
                $contentDisposition = $response.Headers["Content-Disposition"]
                if ($contentDisposition -match 'filename="?([^"]+)"?') {
                    $filename = $matches[1]
                }
            }

            $size = 0
            if ($response.Headers["Content-Length"]) {
                $size = [math]::Round([int64]$response.Headers["Content-Length"] / 1MB, 2)
            }

            return @{
                Available = $true
                Source = "Direct"
                Url = $Url
                Filename = $filename
                Size = $size
            }
        }
    } catch {
        Write-Verbose "Direct download check failed for $Url : $_"
    }

    return @{ Available = $false }
}

# =============================================================================
# Download Functions
# =============================================================================

function Start-PackageDownload {
    param(
        [hashtable]$PackageInfo,
        [string]$OutputPath
    )

    if (-not $PackageInfo.Url) {
        Write-Error-Custom "No download URL available"
        return $false
    }

    $filename = $PackageInfo.Filename
    $filepath = Join-Path $OutputPath $filename

    # Check if already downloaded
    if (Test-Path $filepath) {
        Write-Info "Already downloaded: $filename"
        return $true
    }

    Write-Info "Downloading: $filename ($($PackageInfo.Size) MB)"
    Write-Info "From: $($PackageInfo.Source)"

    try {
        # Download with progress
        $ProgressPreference = 'SilentlyContinue'
        Invoke-WebRequest -Uri $PackageInfo.Url -OutFile $filepath -UseBasicParsing
        $ProgressPreference = 'Continue'

        if (Test-Path $filepath) {
            Write-Success "Downloaded: $filename"
            return $true
        }
    } catch {
        Write-Error-Custom "Download failed: $_"
        if (Test-Path $filepath) {
            Remove-Item $filepath -Force
        }
        return $false
    }

    return $false
}

# =============================================================================
# Main Check Function
# =============================================================================

function Find-PackageSource {
    param(
        [string]$Name,
        [hashtable]$PackageConfig
    )

    Write-Info "Checking: $Name"

    $results = @{
        Name = $Name
        Available = $false
        Sources = @()
    }

    # 1. Check winget
    if ($PackageConfig.winget) {
        $wingetResult = Test-WingetAvailable -PackageId $PackageConfig.winget
        if ($wingetResult.Available) {
            $results.Sources += $wingetResult
            $results.Available = $true
            Write-Success "  ✓ Found in winget: $($PackageConfig.winget)"
        }
    }

    # 2. Check Chocolatey
    if ($PackageConfig.choco) {
        $chocoResult = Test-ChocoAvailable -PackageName $PackageConfig.choco
        if ($chocoResult.Available) {
            $results.Sources += $chocoResult
            $results.Available = $true
            Write-Success "  ✓ Found in Chocolatey: $($PackageConfig.choco)"
        }
    }

    # 3. Check GitHub releases
    if ($PackageConfig.github) {
        $githubResult = Get-LatestGitHubRelease -Repo $PackageConfig.github -AssetPattern $PackageConfig.assetPattern
        if ($githubResult.Available) {
            $results.Sources += $githubResult
            $results.Available = $true
            Write-Success "  ✓ Found on GitHub: $($githubResult.Version) - $($githubResult.Filename)"
        }
    }

    # 4. Check direct download URL
    if ($PackageConfig.url) {
        $directResult = Test-DirectDownloadUrl -Url $PackageConfig.url
        if ($directResult.Available) {
            $results.Sources += $directResult
            $results.Available = $true
            Write-Success "  ✓ Direct download available: $($directResult.Filename)"
        }
    }

    # 5. Check Scoop
    if ($PackageConfig.scoop) {
        $scoopResult = Test-ScoopAvailable -PackageName $PackageConfig.scoop
        if ($scoopResult.Available) {
            $results.Sources += $scoopResult
            $results.Available = $true
            Write-Success "  ✓ Found in Scoop: $($PackageConfig.scoop)"
        }
    }

    if (-not $results.Available) {
        Write-Warning "  ! Not found in any source"
    }

    return $results
}

# =============================================================================
# Main Execution
# =============================================================================

Write-Section "AbeOS Package Availability Checker"

# Check if config file exists
if (-not (Test-Path $ConfigFile)) {
    Write-Error-Custom "Configuration file not found: $ConfigFile"
    Write-Info "Creating sample configuration..."

    $sampleConfig = @{
        packages = @{
            "NVIDIA GeForce Game Ready Driver" = @{
                description = "NVIDIA Graphics Driver"
                url = "https://www.nvidia.com/Download/index.aspx"
                manual = $true
                notes = "Requires manual download from NVIDIA website"
            }
            "Docker Desktop" = @{
                description = "Docker Desktop for Windows"
                winget = "Docker.DockerDesktop"
                choco = "docker-desktop"
                url = "https://desktop.docker.com/win/main/amd64/Docker%20Desktop%20Installer.exe"
            }
            "OBS Studio" = @{
                description = "Open Broadcaster Software"
                winget = "OBSProject.OBSStudio"
                choco = "obs-studio"
                github = "obsproject/obs-studio"
                assetPattern = "OBS-Studio.*-Windows\.exe"
            }
            "Visual Studio Code" = @{
                description = "Code Editor"
                winget = "Microsoft.VisualStudioCode"
                choco = "vscode"
                url = "https://code.visualstudio.com/sha/download?build=stable&os=win32-x64-user"
            }
        }
    }

    $sampleConfig | ConvertTo-Json -Depth 10 | Set-Content $ConfigFile
    Write-Success "Sample configuration created at: $ConfigFile"
    Write-Info "Please edit this file with your desired packages"
    exit 0
}

# Load configuration
Write-Info "Loading configuration from: $ConfigFile"
$config = Get-Content $ConfigFile -Raw | ConvertFrom-Json

$allResults = @{}
$downloadablePackages = @()

# Check each package
foreach ($packageName in $config.packages.PSObject.Properties.Name) {
    $packageConfig = $config.packages.$packageName

    # Convert PSCustomObject to hashtable
    $configHash = @{}
    $packageConfig.PSObject.Properties | ForEach-Object {
        $configHash[$_.Name] = $_.Value
    }

    $result = Find-PackageSource -Name $packageName -PackageConfig $configHash
    $allResults[$packageName] = $result

    # Collect downloadable packages
    $downloadSource = $result.Sources | Where-Object { $_.Url } | Select-Object -First 1
    if ($downloadSource) {
        $downloadablePackages += @{
            Name = $packageName
            Source = $downloadSource
        }
    }

    Start-Sleep -Milliseconds 500  # Rate limiting
}

# =============================================================================
# Results Summary
# =============================================================================

Write-Section "Summary"

$available = ($allResults.Values | Where-Object { $_.Available }).Count
$total = $allResults.Count
$percentage = [math]::Round(($available / $total) * 100, 1)

Write-Info "Packages checked: $total"
Write-Success "Available: $available ($percentage%)"
Write-Warning "Not found: $($total - $available)"

Write-Host ""
Write-Host "Availability by source:" -ForegroundColor Yellow

$sources = @{}
foreach ($result in $allResults.Values) {
    foreach ($source in $result.Sources) {
        $sourceName = $source.Source
        if (-not $sources.ContainsKey($sourceName)) {
            $sources[$sourceName] = 0
        }
        $sources[$sourceName]++
    }
}

foreach ($source in $sources.Keys | Sort-Object) {
    Write-Host "  $source : $($sources[$source]) packages" -ForegroundColor Cyan
}

# =============================================================================
# Download Phase
# =============================================================================

if ($Download -and $downloadablePackages.Count -gt 0) {
    Write-Section "Downloading Packages"

    Write-Info "Found $($downloadablePackages.Count) packages with download URLs"
    Write-Info "Download directory: $DownloadDirectory"
    Write-Host ""

    $downloaded = 0
    $failed = 0

    foreach ($pkg in $downloadablePackages) {
        Write-Host ""
        $success = Start-PackageDownload -PackageInfo $pkg.Source -OutputPath $DownloadDirectory

        if ($success) {
            $downloaded++
        } else {
            $failed++
        }
    }

    Write-Host ""
    Write-Section "Download Summary"
    Write-Success "Downloaded: $downloaded packages"
    if ($failed -gt 0) {
        Write-Warning "Failed: $failed packages"
    }
    Write-Info "Location: $DownloadDirectory"
}

# =============================================================================
# Save Cache
# =============================================================================

Write-Info "Saving results to cache: $CacheFile"

$cacheData = @{
    LastChecked = (Get-Date).ToString("o")
    Results = $allResults
    Statistics = @{
        Total = $total
        Available = $available
        Percentage = $percentage
        Sources = $sources
    }
}

$cacheData | ConvertTo-Json -Depth 10 | Set-Content $CacheFile

Write-Host ""
Write-Section "Complete!"

Write-Host "Next steps:" -ForegroundColor Yellow
Write-Host "  1. Review results in: $CacheFile"
Write-Host "  2. Download packages: .\Check-AvailablePackages.ps1 -Download"
Write-Host "  3. Update config: Edit $ConfigFile"
Write-Host ""
