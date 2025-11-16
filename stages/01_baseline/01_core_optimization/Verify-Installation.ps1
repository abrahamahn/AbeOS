<#
.SYNOPSIS
    AbeOS Installation Verification Script
.DESCRIPTION
    Verifies that all Phase 1.1 components were installed correctly
.NOTES
    Version: 1.0
    Last Updated: November 2025
#>

$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot "..\..\..")).ProviderPath
$modulePath = Join-Path $repoRoot "modules\lib\AbeOS.Core.psm1"
Import-Module $modulePath -Force

Write-Host "`n=== ABEOS INSTALLATION VERIFICATION ===" -ForegroundColor Cyan
Write-Host "Checking Phase 1.1 installation status...`n" -ForegroundColor Yellow

$allPassed = $true
$backupPath = Get-AbeOSPath "configs\core\backup\registry"
$logPath = Get-AbeOSPath "logs"

# ============================================
# 1. CHECK HIBERNATION STATUS
# ============================================
Write-Host "[1/8] Checking hibernation status..." -ForegroundColor White
$hibStatus = powercfg /a | Select-String "Hibernation has not been enabled"
if ($hibStatus) {
    Write-Host "      ✓ Hibernation is disabled" -ForegroundColor Green
} else {
    Write-Host "      ✗ Hibernation may still be enabled" -ForegroundColor Red
    $allPassed = $false
}

# ============================================
# 2. CHECK SYSMAIN SERVICE
# ============================================
Write-Host "[2/8] Checking SysMain service..." -ForegroundColor White
$sysMain = Get-Service -Name "SysMain" -ErrorAction SilentlyContinue
if ($sysMain -and $sysMain.Status -eq "Stopped" -and $sysMain.StartType -eq "Disabled") {
    Write-Host "      ✓ SysMain is stopped and disabled" -ForegroundColor Green
} else {
    Write-Host "      ✗ SysMain is not properly disabled" -ForegroundColor Red
    $allPassed = $false
}

# ============================================
# 3. CHECK POWER PLAN
# ============================================
Write-Host "[3/8] Checking power plan..." -ForegroundColor White
$powerPlan = powercfg /list | Select-String "AbeOS"
if ($powerPlan) {
    Write-Host "      ✓ AbeOS power plan exists" -ForegroundColor Green
    $activePlan = powercfg /list | Select-String "\*"
    if ($activePlan -match "AbeOS") {
        Write-Host "      ✓ AbeOS power plan is active" -ForegroundColor Green
    } else {
        Write-Host "      ! AbeOS power plan exists but is not active" -ForegroundColor Yellow
    }
} else {
    Write-Host "      ✗ AbeOS power plan not found" -ForegroundColor Red
    $allPassed = $false
}

# ============================================
# 4. CHECK PAGEFILE CONFIGURATION
# ============================================
Write-Host "[4/8] Checking pagefile configuration..." -ForegroundColor White
try {
    $pagefile = Get-ItemProperty "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management" -Name "PagingFiles"
    if ($pagefile.PagingFiles -match "16384") {
        Write-Host "      ✓ Pagefile is set to 16GB" -ForegroundColor Green
    } else {
        Write-Host "      ! Pagefile size: $($pagefile.PagingFiles)" -ForegroundColor Yellow
    }
} catch {
    Write-Host "      ✗ Could not verify pagefile configuration" -ForegroundColor Red
    $allPassed = $false
}

# ============================================
# 5. CHECK FAST STARTUP
# ============================================
Write-Host "[5/8] Checking Fast Startup..." -ForegroundColor White
try {
    $fastStartup = Get-ItemProperty "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Power" -Name "HiberbootEnabled" -ErrorAction SilentlyContinue
    if ($fastStartup.HiberbootEnabled -eq 0) {
        Write-Host "      ✓ Fast Startup is disabled" -ForegroundColor Green
    } else {
        Write-Host "      ✗ Fast Startup is still enabled" -ForegroundColor Red
        $allPassed = $false
    }
} catch {
    Write-Host "      ✗ Could not verify Fast Startup status" -ForegroundColor Red
    $allPassed = $false
}

# ============================================
# 6. CHECK WINDOWS SEARCH SERVICE
# ============================================
Write-Host "[6/8] Checking Windows Search service..." -ForegroundColor White
$wSearch = Get-Service -Name "WSearch" -ErrorAction SilentlyContinue
if ($wSearch -and $wSearch.StartType -eq "Automatic") {
    Write-Host "      ✓ Windows Search is configured correctly" -ForegroundColor Green
} else {
    Write-Host "      ! Windows Search service status: $($wSearch.Status)" -ForegroundColor Yellow
}

# ============================================
# 7. CHECK REGISTRY BACKUPS
# ============================================
Write-Host "[7/8] Checking registry backups..." -ForegroundColor White
if (Test-Path $backupPath) {
    $backupFiles = Get-ChildItem $backupPath -Filter "*.reg" -ErrorAction SilentlyContinue
    if ($backupFiles.Count -gt 0) {
        Write-Host "      ✓ Registry backups found ($($backupFiles.Count) files)" -ForegroundColor Green
        $latest = $backupFiles | Sort-Object LastWriteTime -Descending | Select-Object -First 1
        Write-Host "      Latest backup: $($latest.Name)" -ForegroundColor Cyan
    } else {
        Write-Host "      ! No registry backup files found" -ForegroundColor Yellow
    }
} else {
    Write-Host "      ✗ Backup directory not found" -ForegroundColor Red
    $allPassed = $false
}

# ============================================
# 8. CHECK LOG FILES
# ============================================
Write-Host "[8/8] Checking log files..." -ForegroundColor White
if (Test-Path $logPath) {
    $logFiles = Get-ChildItem $logPath -Filter "*.log" -ErrorAction SilentlyContinue
    if ($logFiles.Count -gt 0) {
        Write-Host "      ✓ Log files found ($($logFiles.Count) files)" -ForegroundColor Green
        $latest = $logFiles | Sort-Object LastWriteTime -Descending | Select-Object -First 1
        Write-Host "      Latest log: $($latest.Name)" -ForegroundColor Cyan
    } else {
        Write-Host "      ! No log files found (scripts may not have run)" -ForegroundColor Yellow
    }
} else {
    Write-Host "      ✗ Log directory not found" -ForegroundColor Red
}

# ============================================
# SUMMARY
# ============================================
Write-Host "`n=== VERIFICATION SUMMARY ===" -ForegroundColor Cyan

if ($allPassed) {
    Write-Host "✓ All critical checks passed!" -ForegroundColor Green
    Write-Host "AbeOS Phase 1.1 is properly installed." -ForegroundColor Green
} else {
    Write-Host "⚠ Some checks failed." -ForegroundColor Yellow
    Write-Host ("Review the results above and check logs in {0}" -f $logPath) -ForegroundColor Yellow
}

Write-Host "`nSystem Information:" -ForegroundColor Cyan
Write-Host "  OS: $((Get-WmiObject Win32_OperatingSystem).Caption)" -ForegroundColor White
Write-Host "  Computer: $env:COMPUTERNAME" -ForegroundColor White
Write-Host "  User: $env:USERNAME" -ForegroundColor White

Write-Host "`nNext Steps:" -ForegroundColor Cyan
Write-Host "  1. Review TODO.md for upcoming phases" -ForegroundColor White
Write-Host "  2. Switch power modes: .\modules\performance\Set-PowerPlan.ps1 -Mode [Balanced|Performance|Creator]" -ForegroundColor White
Write-Host "  3. Create additional backups: .\stages\01_baseline\01_core_optimization\Backup-Registry.ps1" -ForegroundColor White
Write-Host ""
