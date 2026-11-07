# Daily-Maintenance.ps1 - Safe routine maintenance tasks.
# Usage: .\Daily-Maintenance.ps1

$ErrorActionPreference = "SilentlyContinue"

Write-Host "=== AbeOS Daily Maintenance ===" -ForegroundColor Cyan
Write-Host "Started: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" -ForegroundColor DarkGray
Write-Host ""

$totalReclaimed = 0

# --- Temp Files Cleanup ---
Write-Host "[TEMP FILES]" -ForegroundColor Yellow

# User temp
$userTemp = $env:TEMP
$userTempFiles = Get-ChildItem -Path $userTemp -Recurse -File -ErrorAction SilentlyContinue |
    Where-Object { $_.LastWriteTime -lt (Get-Date).AddDays(-3) }
$userTempSize = ($userTempFiles | Measure-Object -Property Length -Sum).Sum
$userTempMB = [math]::Round($userTempSize / 1MB, 1)

if ($userTempFiles.Count -gt 0) {
    $userTempFiles | Remove-Item -Force -ErrorAction SilentlyContinue
    Write-Host "  User temp: Cleaned $($userTempFiles.Count) files ($userTempMB MB)" -ForegroundColor Green
    $totalReclaimed += $userTempSize
} else {
    Write-Host "  User temp: Clean" -ForegroundColor DarkGray
}

# Windows temp
$winTemp = "$env:SystemRoot\Temp"
$winTempFiles = Get-ChildItem -Path $winTemp -Recurse -File -ErrorAction SilentlyContinue |
    Where-Object { $_.LastWriteTime -lt (Get-Date).AddDays(-3) }
$winTempSize = ($winTempFiles | Measure-Object -Property Length -Sum).Sum
$winTempMB = [math]::Round($winTempSize / 1MB, 1)

if ($winTempFiles.Count -gt 0) {
    $winTempFiles | Remove-Item -Force -ErrorAction SilentlyContinue
    Write-Host "  Windows temp: Cleaned $($winTempFiles.Count) files ($winTempMB MB)" -ForegroundColor Green
    $totalReclaimed += $winTempSize
} else {
    Write-Host "  Windows temp: Clean" -ForegroundColor DarkGray
}

# --- Windows Update Cache (older than 7 days) ---
Write-Host ""
Write-Host "[UPDATE CACHE]" -ForegroundColor Yellow
$updateCache = "$env:SystemRoot\SoftwareDistribution\Download"
if (Test-Path $updateCache) {
    $cacheFiles = Get-ChildItem -Path $updateCache -Recurse -File -ErrorAction SilentlyContinue |
        Where-Object { $_.LastWriteTime -lt (Get-Date).AddDays(-7) }
    $cacheSize = ($cacheFiles | Measure-Object -Property Length -Sum).Sum
    $cacheMB = [math]::Round($cacheSize / 1MB, 1)
    if ($cacheFiles.Count -gt 0) {
        $cacheFiles | Remove-Item -Force -ErrorAction SilentlyContinue
        Write-Host "  Cleaned $($cacheFiles.Count) stale update files ($cacheMB MB)" -ForegroundColor Green
        $totalReclaimed += $cacheSize
    } else {
        Write-Host "  No stale update files" -ForegroundColor DarkGray
    }
} else {
    Write-Host "  Update cache not found" -ForegroundColor DarkGray
}

# --- Prefetch Cleanup (older than 14 days) ---
Write-Host ""
Write-Host "[PREFETCH]" -ForegroundColor Yellow
$prefetch = "$env:SystemRoot\Prefetch"
if (Test-Path $prefetch) {
    $prefetchFiles = Get-ChildItem -Path $prefetch -File -ErrorAction SilentlyContinue |
        Where-Object { $_.LastWriteTime -lt (Get-Date).AddDays(-14) }
    $prefetchSize = ($prefetchFiles | Measure-Object -Property Length -Sum).Sum
    $prefetchMB = [math]::Round($prefetchSize / 1MB, 1)
    if ($prefetchFiles.Count -gt 0) {
        $prefetchFiles | Remove-Item -Force -ErrorAction SilentlyContinue
        Write-Host "  Cleaned $($prefetchFiles.Count) old prefetch files ($prefetchMB MB)" -ForegroundColor Green
        $totalReclaimed += $prefetchSize
    } else {
        Write-Host "  No stale prefetch files" -ForegroundColor DarkGray
    }
} else {
    Write-Host "  Prefetch directory not accessible" -ForegroundColor DarkGray
}

# --- Recycle Bin ---
Write-Host ""
Write-Host "[RECYCLE BIN]" -ForegroundColor Yellow
try {
    $shell = New-Object -ComObject Shell.Application
    $recycleBin = $shell.Namespace(0x0a)
    $itemCount = $recycleBin.Items().Count
    if ($itemCount -gt 0) {
        Clear-RecycleBin -Force -ErrorAction SilentlyContinue
        Write-Host "  Emptied $itemCount items" -ForegroundColor Green
    } else {
        Write-Host "  Already empty" -ForegroundColor DarkGray
    }
} catch {
    Write-Host "  Could not access recycle bin" -ForegroundColor DarkGray
}

# --- Disk Space Report ---
Write-Host ""
Write-Host "[DISK SPACE]" -ForegroundColor Yellow
$disks = Get-CimInstance -ClassName Win32_LogicalDisk -Filter "DriveType=3"
foreach ($disk in $disks) {
    $freeGB = [math]::Round($disk.FreeSpace / 1GB, 1)
    $totalGB = [math]::Round($disk.Size / 1GB, 1)
    $pct = [math]::Round((($totalGB - $freeGB) / $totalGB) * 100, 0)
    $color = $(if ($pct -gt 90) { "Red" } elseif ($pct -gt 75) { "Yellow" } else { "Green" })
    Write-Host "  $($disk.DeviceID) $freeGB GB free / $totalGB GB ($pct% used)" -ForegroundColor $color
}

# --- Windows Update Status ---
Write-Host ""
Write-Host "[WINDOWS UPDATE]" -ForegroundColor Yellow
try {
    $session = New-Object -ComObject Microsoft.Update.Session
    $searcher = $session.CreateUpdateSearcher()
    $results = $searcher.Search("IsInstalled=0 AND IsHidden=0")
    if ($results.Updates.Count -gt 0) {
        Write-Host "  $($results.Updates.Count) update(s) available:" -ForegroundColor Yellow
        foreach ($update in $results.Updates) {
            Write-Host "    - $($update.Title)" -ForegroundColor DarkGray
        }
    } else {
        Write-Host "  System is up to date" -ForegroundColor Green
    }
} catch {
    Write-Host "  Could not check for updates" -ForegroundColor DarkGray
}

# --- Summary ---
$totalMB = [math]::Round($totalReclaimed / 1MB, 1)
Write-Host ""
Write-Host "=== Summary ===" -ForegroundColor Cyan
Write-Host "  Total space reclaimed: $totalMB MB" -ForegroundColor White
Write-Host "  Completed: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" -ForegroundColor DarkGray
Write-Host ""
Write-Host "Done." -ForegroundColor Cyan
