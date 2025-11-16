#Requires -RunAsAdministrator
<#
.SYNOPSIS
    AbeOS Phase 1.1 - Privacy and UI Cleanup
.DESCRIPTION
    Disables Windows login tips, welcome popups, and consumer features
    Note: Run privacy.sexy script separately for comprehensive telemetry disabling
.NOTES
    Version: 1.0
    Last Updated: November 2025
#>

param(
    [switch]$SkipReboot
)

$ErrorActionPreference = "Stop"
$scriptName = "Privacy-UI"

$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot "..\..\..")).ProviderPath
$modulePath = Join-Path $repoRoot "modules\lib\AbeOS.Core.psm1"
Import-Module $modulePath -Force

Write-Host "`n=== ABEOS PRIVACY & UI CLEANUP ===" -ForegroundColor Cyan

$logFile = Initialize-AbeOSLogging -ScriptName $scriptName

try {
    # ============================================
    # 1. DISABLE LOGIN TIPS & WELCOME POPUPS
    # ============================================
    Write-AbeOSLog -Message "Disabling login tips and welcome popups..." -Level "INFO" -LogFile $logFile

    $contentDeliveryKeys = @(
        "SubscribedContent-310093Enabled",
        "SubscribedContent-338387Enabled",
        "SubscribedContent-338388Enabled",
        "SubscribedContent-338389Enabled",
        "SubscribedContent-353694Enabled",
        "SubscribedContent-353696Enabled"
    )

    foreach ($key in $contentDeliveryKeys) {
        reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" /v $key /t REG_DWORD /d 0 /f | Out-Null
    }

    Write-AbeOSLog -Message "[✓] Login tips disabled" -Level "SUCCESS" -LogFile $logFile

    # ============================================
    # 2. DISABLE "GET STARTED" APP
    # ============================================
    Write-AbeOSLog -Message "Disabling Windows Consumer Features..." -Level "INFO" -LogFile $logFile
    reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\CloudContent" /v DisableWindowsConsumerFeatures /t REG_DWORD /d 1 /f | Out-Null
    Write-AbeOSLog -Message "[✓] Consumer features disabled" -Level "SUCCESS" -LogFile $logFile

    # ============================================
    # 3. KILL TIPS PROCESSES
    # ============================================
    Write-AbeOSLog -Message "Stopping tips processes..." -Level "INFO" -LogFile $logFile
    taskkill /f /im "StartMenuExperienceHost.exe" 2>$null
    Write-AbeOSLog -Message "[✓] Tips processes stopped" -Level "SUCCESS" -LogFile $logFile

    # ============================================
    # 4. REFRESH SYSTEM
    # ============================================
    Write-AbeOSLog -Message "Refreshing system parameters..." -Level "INFO" -LogFile $logFile
    RUNDLL32.EXE user32.dll,UpdatePerUserSystemParameters
    Write-AbeOSLog -Message "[✓] System parameters refreshed" -Level "SUCCESS" -LogFile $logFile

    # ============================================
    # 5. ADDITIONAL PRIVACY TWEAKS
    # ============================================
    Write-AbeOSLog -Message "Applying additional privacy tweaks..." -Level "INFO" -LogFile $logFile

    # Disable app suggestions
    reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" /v SilentInstalledAppsEnabled /t REG_DWORD /d 0 /f | Out-Null

    # Disable Windows Spotlight
    reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" /v RotatingLockScreenEnabled /t REG_DWORD /d 0 /f | Out-Null

    # Disable feedback requests
    reg add "HKCU\Software\Microsoft\Siuf\Rules" /v NumberOfSIUFInPeriod /t REG_DWORD /d 0 /f | Out-Null

    Write-AbeOSLog -Message "[✓] Additional privacy tweaks applied" -Level "SUCCESS" -LogFile $logFile

    # ============================================
    # COMPLETION
    # ============================================
    Write-Host "`n=== PRIVACY & UI CLEANUP COMPLETE ===" -ForegroundColor Cyan
    Write-AbeOSLog -Message "Privacy and UI cleanup completed successfully" -Level "SUCCESS" -LogFile $logFile
    Write-AbeOSLog -Message "Log file: $logFile" -Level "INFO" -LogFile $logFile
    Write-Host "`nNote: For comprehensive telemetry disabling, run privacy.sexy script separately" -ForegroundColor Yellow

} catch {
    Write-AbeOSLog -Message "ERROR: $($_.Exception.Message)" -Level "ERROR" -LogFile $logFile
    Write-AbeOSLog -Message "Stack trace: $($_.ScriptStackTrace)" -Level "ERROR" -LogFile $logFile
    exit 1
}
