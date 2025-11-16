# =============================================================================
# Start-BatchDownload.ps1
# Batch download manager with queue, retry logic, and progress tracking
# =============================================================================

[CmdletBinding()]
param(
    [Parameter(Mandatory=$false)]
    [string]$QueueFile = "$PSScriptRoot\..\..\configs\cache\download-queue.json",

    [Parameter(Mandatory=$false)]
    [string]$OutputDirectory = "C:\AbeOS\downloads\installers",

    [switch]$Interactive,
    [switch]$Resume,
    [int]$MaxRetries = 3,
    [int]$MaxConcurrent = 3
)

$ErrorActionPreference = "Stop"

# =============================================================================
# Configuration
# =============================================================================

$ProgressFile = Join-Path (Split-Path $QueueFile) "download-progress.json"

New-Item -ItemType Directory -Path $OutputDirectory -Force | Out-Null
New-Item -ItemType Directory -Path (Split-Path $QueueFile) -Force | Out-Null

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
# Download Functions
# =============================================================================

function Get-FileNameFromUrl {
    param([string]$Url, [string]$ContentDisposition = $null)

    $filename = [System.IO.Path]::GetFileName($Url)

    if ($ContentDisposition -and $ContentDisposition -match 'filename="?([^"]+)"?') {
        $filename = $matches[1]
    }

    # Clean up URL parameters
    if ($filename -match '\?') {
        $filename = $filename -replace '\?.*$', ''
    }

    return $filename
}

function Start-SingleDownload {
    param(
        [hashtable]$DownloadItem,
        [string]$OutputPath
    )

    $url = $DownloadItem.url
    $filename = if ($DownloadItem.filename) { $DownloadItem.filename } else { Get-FileNameFromUrl -Url $url }
    $filepath = Join-Path $OutputPath $filename

    # Check if already downloaded and valid
    if (Test-Path $filepath) {
        if ($DownloadItem.ContainsKey('size') -and $DownloadItem.size -gt 0) {
            $actualSize = (Get-Item $filepath).Length
            $expectedSize = $DownloadItem.size

            if ($actualSize -eq $expectedSize) {
                Write-Info "Already downloaded and verified: $filename"
                return @{
                    Success = $true
                    Skipped = $true
                    Path = $filepath
                    Message = "Already exists"
                }
            } else {
                Write-Warning "File exists but size mismatch. Re-downloading..."
                Remove-Item $filepath -Force
            }
        } else {
            Write-Info "File exists (size not verified): $filename"
            return @{
                Success = $true
                Skipped = $true
                Path = $filepath
                Message = "Already exists (unverified)"
            }
        }
    }

    Write-Info "Downloading: $filename"
    Write-Info "From: $url"

    $startTime = Get-Date
    $retries = 0

    while ($retries -lt $MaxRetries) {
        try {
            # Attempt download
            $webRequest = @{
                Uri = $url
                OutFile = $filepath
                UseBasicParsing = $true
                UserAgent = "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36"
            }

            # Show progress for large files
            if ($DownloadItem.size -gt 10MB) {
                $ProgressPreference = 'Continue'
                Write-Host "  Progress: " -NoNewline
            } else {
                $ProgressPreference = 'SilentlyContinue'
            }

            Invoke-WebRequest @webRequest

            $ProgressPreference = 'Continue'

            # Verify download
            if (Test-Path $filepath) {
                $downloadedSize = (Get-Item $filepath).Length
                $duration = (Get-Date) - $startTime

                Write-Success "Downloaded: $filename ($([math]::Round($downloadedSize / 1MB, 2)) MB in $($duration.TotalSeconds)s)"

                return @{
                    Success = $true
                    Skipped = $false
                    Path = $filepath
                    Size = $downloadedSize
                    Duration = $duration.TotalSeconds
                    Message = "Download successful"
                }
            }

        } catch {
            $retries++
            Write-Warning "Download failed (attempt $retries/$MaxRetries): $_"

            if ($retries -lt $MaxRetries) {
                $waitTime = [Math]::Pow(2, $retries)  # Exponential backoff
                Write-Info "Retrying in $waitTime seconds..."
                Start-Sleep -Seconds $waitTime
            } else {
                Write-Error-Custom "Download failed after $MaxRetries attempts"

                # Clean up partial download
                if (Test-Path $filepath) {
                    Remove-Item $filepath -Force
                }

                return @{
                    Success = $false
                    Skipped = $false
                    Path = $null
                    Error = $_.Exception.Message
                    Message = "Download failed after $MaxRetries attempts"
                }
            }
        }
    }
}

# =============================================================================
# Queue Management
# =============================================================================

function Load-DownloadQueue {
    if (-not (Test-Path $QueueFile)) {
        Write-Info "Creating sample download queue..."

        $sampleQueue = @{
            downloads = @(
                @{
                    name = "Visual Studio Code"
                    url = "https://code.visualstudio.com/sha/download?build=stable&os=win32-x64-user"
                    filename = "VSCodeUserSetup-x64.exe"
                    category = "development"
                    priority = 1
                }
                @{
                    name = "Git for Windows"
                    url = "https://github.com/git-for-windows/git/releases/download/v2.43.0.windows.1/Git-2.43.0-64-bit.exe"
                    filename = "Git-2.43.0-64-bit.exe"
                    size = 50MB
                    category = "development"
                    priority = 1
                }
                @{
                    name = "7-Zip"
                    url = "https://www.7-zip.org/a/7z2301-x64.exe"
                    filename = "7z2301-x64.exe"
                    category = "utility"
                    priority = 2
                }
            )
            metadata = @{
                created = (Get-Date).ToString("o")
                totalItems = 3
            }
        }

        $sampleQueue | ConvertTo-Json -Depth 10 | Set-Content $QueueFile
        Write-Success "Sample queue created at: $QueueFile"
        Write-Info "Edit this file to add your download URLs"
    }

    return Get-Content $QueueFile -Raw | ConvertFrom-Json
}

function Save-DownloadProgress {
    param([hashtable]$Progress)

    $Progress | ConvertTo-Json -Depth 10 | Set-Content $ProgressFile
}

function Load-DownloadProgress {
    if (Test-Path $ProgressFile) {
        return Get-Content $ProgressFile -Raw | ConvertFrom-Json
    }

    return @{
        completed = @()
        failed = @()
        skipped = @()
        lastRun = $null
    }
}

# =============================================================================
# Main Execution
# =============================================================================

Write-Section "AbeOS Batch Download Manager"

# Load queue
Write-Info "Loading download queue from: $QueueFile"
$queue = Load-DownloadQueue

$totalItems = $queue.downloads.Count
Write-Info "Total items in queue: $totalItems"
Write-Info "Output directory: $OutputDirectory"

# Load progress if resuming
$progress = if ($Resume) {
    Write-Info "Resuming previous download session..."
    Load-DownloadProgress
} else {
    @{
        completed = @()
        failed = @()
        skipped = @()
        lastRun = (Get-Date).ToString("o")
        statistics = @{
            totalBytes = 0
            totalDuration = 0
            successCount = 0
            failureCount = 0
            skipCount = 0
        }
    }
}

# Interactive mode - let user select downloads
if ($Interactive) {
    Write-Section "Interactive Mode"

    Write-Host "Available downloads:" -ForegroundColor Yellow
    for ($i = 0; $i -lt $queue.downloads.Count; $i++) {
        $item = $queue.downloads[$i]
        Write-Host "  [$($i + 1)] $($item.name) - $($item.category)"
    }

    Write-Host ""
    $selection = Read-Host "Enter numbers to download (comma-separated, or 'all')"

    if ($selection -eq "all") {
        $selectedItems = $queue.downloads
    } else {
        $indices = $selection -split ',' | ForEach-Object { [int]$_.Trim() - 1 }
        $selectedItems = $indices | ForEach-Object { $queue.downloads[$_] }
    }

    $queue.downloads = $selectedItems
    Write-Info "Selected $($selectedItems.Count) items for download"
}

# Sort by priority
$sortedDownloads = $queue.downloads | Sort-Object -Property @{Expression = {$_.priority}; Ascending = $true}

Write-Section "Starting Downloads"

$currentItem = 0

foreach ($item in $sortedDownloads) {
    $currentItem++

    Write-Host ""
    Write-Info "[$currentItem/$totalItems] $($item.name)"

    # Convert PSCustomObject to hashtable
    $downloadHash = @{}
    $item.PSObject.Properties | ForEach-Object {
        $downloadHash[$_.Name] = $_.Value
    }

    $result = Start-SingleDownload -DownloadItem $downloadHash -OutputPath $OutputDirectory

    # Update progress
    if ($result.Success) {
        if ($result.Skipped) {
            $progress.skipped += @{
                name = $item.name
                path = $result.Path
                timestamp = (Get-Date).ToString("o")
            }
            $progress.statistics.skipCount++
        } else {
            $progress.completed += @{
                name = $item.name
                path = $result.Path
                size = $result.Size
                duration = $result.Duration
                timestamp = (Get-Date).ToString("o")
            }
            $progress.statistics.successCount++
            $progress.statistics.totalBytes += $result.Size
            $progress.statistics.totalDuration += $result.Duration
        }
    } else {
        $progress.failed += @{
            name = $item.name
            url = $item.url
            error = $result.Error
            timestamp = (Get-Date).ToString("o")
        }
        $progress.statistics.failureCount++
    }

    # Save progress periodically
    Save-DownloadProgress -Progress $progress

    # Rate limiting
    Start-Sleep -Milliseconds 500
}

# =============================================================================
# Final Summary
# =============================================================================

Write-Section "Download Summary"

Write-Success "Completed: $($progress.statistics.successCount) downloads"
if ($progress.statistics.skipCount -gt 0) {
    Write-Info "Skipped: $($progress.statistics.skipCount) (already downloaded)"
}
if ($progress.statistics.failureCount -gt 0) {
    Write-Warning "Failed: $($progress.statistics.failureCount) downloads"
}

if ($progress.statistics.totalBytes -gt 0) {
    $totalMB = [math]::Round($progress.statistics.totalBytes / 1MB, 2)
    $avgSpeed = if ($progress.statistics.totalDuration -gt 0) {
        [math]::Round($totalMB / $progress.statistics.totalDuration, 2)
    } else { 0 }

    Write-Host ""
    Write-Info "Total downloaded: $totalMB MB"
    Write-Info "Total time: $([math]::Round($progress.statistics.totalDuration, 2))s"
    Write-Info "Average speed: $avgSpeed MB/s"
}

Write-Host ""
Write-Info "Downloads saved to: $OutputDirectory"
Write-Info "Progress saved to: $ProgressFile"

if ($progress.failed.Count -gt 0) {
    Write-Host ""
    Write-Warning "Failed downloads:"
    foreach ($failed in $progress.failed) {
        Write-Host "  - $($failed.name): $($failed.error)" -ForegroundColor Red
    }
}

Write-Host ""
Write-Section "Complete!"

Write-Host "Next steps:" -ForegroundColor Yellow
Write-Host "  1. Check downloads: explorer $OutputDirectory"
Write-Host "  2. Retry failed: .\Start-BatchDownload.ps1 -Resume"
Write-Host "  3. Add more URLs: Edit $QueueFile"
Write-Host ""
