#Requires -RunAsAdministrator
<#
.SYNOPSIS
    AbeOS Phase 1.1 - Core System Optimization
.DESCRIPTION
    Consolidates: Power management, hibernation, fast startup, SysMain, and pagefile configuration
    Based on tested scripts from Phase 1 Part 1 completion
.NOTES
    Version: 1.0
    Last Updated: November 2025
#>

param(
    [switch]$SkipReboot
)

$ErrorActionPreference = "Stop"
$scriptName = "System-Optimization"

$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot "..\..\..")).ProviderPath
$modulePath = Join-Path $repoRoot "modules\lib\AbeOS.Core.psm1"
Import-Module $modulePath -Force

Write-Host "`n=== ABEOS PHASE 1.1 - SYSTEM OPTIMIZATION ===" -ForegroundColor Cyan
Write-Host "Starting: $scriptName" -ForegroundColor Yellow

$logFile = Initialize-AbeOSLogging -ScriptName $scriptName

try {
    # ============================================
    # 1. DISABLE HIBERNATION
    # ============================================
    Write-AbeOSLog -Message "Disabling hibernation..." -Level "INFO" -LogFile $logFile
    powercfg /hibernate off
    if ($LASTEXITCODE -eq 0) {
        Write-AbeOSLog -Message "[✓] Hibernation disabled (freed ~20-30GB)" -Level "SUCCESS" -LogFile $logFile
    } else {
        Write-AbeOSLog -Message "[!] Hibernation disable failed" -Level "WARNING" -LogFile $logFile
    }

    # ============================================
    # 2. DISABLE FAST STARTUP
    # ============================================
    Write-AbeOSLog -Message "Disabling Fast Startup..." -Level "INFO" -LogFile $logFile
    reg add "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Power" /v HiberbootEnabled /t REG_DWORD /d 0 /f | Out-Null
    Write-AbeOSLog -Message "[✓] Fast Startup disabled (fixes GPU/audio/stutter)" -Level "SUCCESS" -LogFile $logFile

    # ============================================
    # 3. DISABLE SYSMAIN (SUPERFETCH)
    # ============================================
    Write-AbeOSLog -Message "Disabling SysMain..." -Level "INFO" -LogFile $logFile
    Stop-Service -Name "SysMain" -Force -ErrorAction SilentlyContinue
    Set-Service -Name "SysMain" -StartupType Disabled
    Write-AbeOSLog -Message "[✓] SysMain (Superfetch) disabled" -Level "SUCCESS" -LogFile $logFile

    # ============================================
    # 4. SET FIXED PAGEFILE SIZE (16GB)
    # ============================================
    Write-AbeOSLog -Message "Setting fixed pagefile size to 16GB..." -Level "INFO" -LogFile $logFile
    Set-ItemProperty "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management" `
        -Name "PagingFiles" -Type MultiString -Value "C:\pagefile.sys 16384 16384"
    Write-AbeOSLog -Message "[✓] Pagefile set to fixed 16GB (16384MB)" -Level "SUCCESS" -LogFile $logFile

    # ============================================
    # 5. CREATE CUSTOM POWER PLAN
    # ============================================
    Write-AbeOSLog -Message "Creating AbeOS Balanced Ultimate power plan..." -Level "INFO" -LogFile $logFile

    # Duplicate Balanced plan
    $guidOutput = powercfg -duplicatescheme SCHEME_BALANCED
    $guidBalanced = ($guidOutput -split '\s+')[-1]

    # Rename the plan
    powercfg -changename $guidBalanced "AbeOS - Balanced Ultimate"

    # CPU optimization (max performance on AC)
    powercfg -setacvalueindex $guidBalanced SUB_PROCESSOR PROCTHROTTLEMAX 100
    powercfg -setdcvalueindex $guidBalanced SUB_PROCESSOR PROCTHROTTLEMAX 100

    # PCIe latency fix for stutters
    powercfg -setacvalueindex $guidBalanced SUB_PCIE ASPM 0
    powercfg -setdcvalueindex $guidBalanced SUB_PCIE ASPM 0

    # Disable hybrid sleep
    powercfg -setacvalueindex $guidBalanced SUB_SLEEP HYBRIDSLEEP 0
    powercfg -setdcvalueindex $guidBalanced SUB_SLEEP HYBRIDSLEEP 0

    # Allow wake timers
    powercfg -setacvalueindex $guidBalanced SUB_SLEEP ALLOWWAKE 1
    powercfg -setdcvalueindex $guidBalanced SUB_SLEEP ALLOWWAKE 1

    # Auto-hibernate after 12 hours of sleep (720 minutes)
    powercfg -setacvalueindex $guidBalanced SUB_SLEEP HIBERNATEIDLE 720
    powercfg -setdcvalueindex $guidBalanced SUB_SLEEP HIBERNATEIDLE 720

    # Activate the plan
    powercfg -setactive $guidBalanced

    Write-AbeOSLog -Message "[✓] AbeOS Balanced Ultimate plan created and activated" -Level "SUCCESS" -LogFile $logFile

    # ============================================
    # 6. OLED BRIGHTNESS & HDR FIX
    # ============================================
    Write-AbeOSLog -Message "Applying OLED resume brightness fix..." -Level "INFO" -LogFile $logFile
    reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\VideoSettings" /v EnableHDRSurfaceBrightnessFix /t REG_DWORD /d 1 /f | Out-Null
    Write-AbeOSLog -Message "[✓] OLED brightness fix applied" -Level "SUCCESS" -LogFile $logFile

    # ============================================
    # 7. MODERN STANDBY OPTIMIZATION
    # ============================================
    Write-AbeOSLog -Message "Optimizing Modern Standby..." -Level "INFO" -LogFile $logFile
    reg add "HKLM\SYSTEM\CurrentControlSet\Control\Power" /v PlatformAoAcOverride /t REG_DWORD /d 0 /f | Out-Null
    Write-AbeOSLog -Message "[✓] Modern Standby optimized" -Level "SUCCESS" -LogFile $logFile

    # ============================================
    # COMPLETION
    # ============================================
    Write-Host "`n=== SYSTEM OPTIMIZATION COMPLETE ===" -ForegroundColor Cyan
    Write-AbeOSLog -Message "System optimization completed successfully" -Level "SUCCESS" -LogFile $logFile
    Write-AbeOSLog -Message "Log file: $logFile" -Level "INFO" -LogFile $logFile

    if (-not $SkipReboot) {
        Write-Host "`nA reboot is required to apply all changes." -ForegroundColor Yellow
        $response = Read-Host "Reboot now? (y/n)"
        if ($response -eq 'y') {
            Write-AbeOSLog -Message "Initiating system reboot..." -Level "INFO" -LogFile $logFile
            Restart-Computer -Force
        }
    }

} catch {
    Write-AbeOSLog -Message "ERROR: $($_.Exception.Message)" -Level "ERROR" -LogFile $logFile
    Write-AbeOSLog -Message "Stack trace: $($_.ScriptStackTrace)" -Level "ERROR" -LogFile $logFile
    exit 1
}
