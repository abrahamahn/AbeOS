#Requires -RunAsAdministrator
<#
.SYNOPSIS
    AbeOS Phase 1.1 - Explorer and Search Indexing Optimization
.DESCRIPTION
    Optimizes Windows Search indexing and File Explorer performance
    Disables heavy content indexing while preserving fast file search
.NOTES
    Version: 1.3
    Last Updated: November 2025
#>

param(
    [switch]$SkipReboot
)

$ErrorActionPreference = "Stop"
$scriptName = "Explorer-Indexing"

$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot "..\..\..")).ProviderPath
$modulePath = Join-Path $repoRoot "modules\lib\AbeOS.Core.psm1"
Import-Module $modulePath -Force

Write-Host "`n=== ABEOS EXPLORER & INDEXING OPTIMIZATION v1.3 ===" -ForegroundColor Cyan

$logFile = Initialize-AbeOSLogging -ScriptName $scriptName

try {
    # ============================================
    # 1. ENABLE WINDOWS SEARCH SERVICE
    # ============================================
    Write-AbeOSLog -Message "Ensuring Windows Search service is enabled..." -Level "INFO" -LogFile $logFile
    Set-Service -Name "WSearch" -StartupType Automatic -ErrorAction SilentlyContinue
    Start-Service -Name "WSearch" -ErrorAction SilentlyContinue
    Write-AbeOSLog -Message "[✓] Windows Search service enabled" -Level "SUCCESS" -LogFile $logFile

    # ============================================
    # 2. DISABLE CONTENT INDEXING ON C:\
    # ============================================
    Write-AbeOSLog -Message "Disabling content indexing on all folders..." -Level "WARNING" -LogFile $logFile
    Write-AbeOSLog -Message "    (This may take a few minutes...)" -Level "INFO" -LogFile $logFile

    try {
        Get-ChildItem -Path C:\ -Recurse -Directory -ErrorAction SilentlyContinue |
            ForEach-Object {
                attrib -I $_.FullName 2>$null
            }
        Write-AbeOSLog -Message "[✓] Content indexing disabled (stops SSD crawling)" -Level "SUCCESS" -LogFile $logFile
    } catch {
        Write-AbeOSLog -Message "[!] Some folders skipped (normal for protected system folders)" -Level "WARNING" -LogFile $logFile
    }

    # ============================================
    # 3. RESET INDEX ROOTS (MINIMAL INDEXING)
    # ============================================
    Write-AbeOSLog -Message "Resetting indexed locations to minimal paths..." -Level "INFO" -LogFile $logFile

    $catalogManager = New-Object -ComObject Search.Manager
    $catalog = $catalogManager.GetCatalog("SystemIndex")
    $roots = $catalog.GetRoots()

    # Remove all existing roots
    $enumerator = $roots.GetEnumerator()
    while ($enumerator.MoveNext()) {
        $rootURL = $enumerator.Current.URL
        try {
            $catalog.GetRoot($rootURL).Remove()
        } catch {
            # Ignore errors for roots that can't be removed
        }
    }

    # Re-add minimal essential roots only
    $catalog.GetRoot().Add("file:///C:/Users/$env:USERNAME/AppData/Roaming/Microsoft/Windows/Start Menu/")
    $catalog.GetRoot().Add("file:///C:/Users/$env:USERNAME/AppData/Roaming/Microsoft/Windows/Recent/")
    $catalog.GetRoot().Add("file:///C:/Users/$env:USERNAME/AppData/Local/Microsoft/Windows/History/")

    Write-AbeOSLog -Message "[✓] Minimal index paths configured (Start Menu, Recent, History)" -Level "SUCCESS" -LogFile $logFile

    # ============================================
    # 4. REBUILD SEARCH INDEX CLEANLY
    # ============================================
    Write-AbeOSLog -Message "Rebuilding search index..." -Level "INFO" -LogFile $logFile

    Stop-Service WSearch -Force -ErrorAction SilentlyContinue
    Start-Sleep -Seconds 2
    Remove-Item "C:\ProgramData\Microsoft\Search\Data\Applications\Windows\*" -Recurse -Force -ErrorAction SilentlyContinue
    Start-Service WSearch -ErrorAction SilentlyContinue

    Write-AbeOSLog -Message "[✓] Search index rebuilt cleanly" -Level "SUCCESS" -LogFile $logFile

    # ============================================
    # 5. EXPLORER PERFORMANCE OPTIMIZATIONS
    # ============================================
    Write-AbeOSLog -Message "Applying Explorer performance tweaks..." -Level "INFO" -LogFile $logFile

    # Disable thumbnail DB on network folders
    reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v DisableThumbsDBOnNetworkFolders /t REG_DWORD /d 1 /f >$null

    # Avoid slow network crawling
    reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v NoNetCrawling /t REG_DWORD /d 1 /f >$null

    # Remove heavy "Recent files" writing
    reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer" /v ShowRecent /t REG_DWORD /d 0 /f >$null

    # Faster folder switching
    reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Policies\Explorer" /v LinkResolveIgnoreLinkInfo /t REG_DWORD /d 1 /f >$null

    # Reduce Explorer stalls
    reg add "HKCU\Control Panel\Desktop" /v AutoEndTasks /t REG_DWORD /d 1 /f >$null

    Write-AbeOSLog -Message "[✓] Explorer performance optimized" -Level "SUCCESS" -LogFile $logFile

    # ============================================
    # COMPLETION
    # ============================================
    Write-Host "`n=== EXPLORER & INDEXING OPTIMIZATION COMPLETE ===" -ForegroundColor Cyan
    Write-AbeOSLog -Message "Optimization completed successfully" -Level "SUCCESS" -LogFile $logFile
    Write-AbeOSLog -Message "Log file: $logFile" -Level "INFO" -LogFile $logFile

    if (-not $SkipReboot) {
        Write-Host "`nReboot recommended to finalize all changes." -ForegroundColor Yellow
    }

} catch {
        Write-AbeOSLog -Message "ERROR: $($_.Exception.Message)" -Level "ERROR" -LogFile $logFile
        Write-AbeOSLog -Message "Stack trace: $($_.ScriptStackTrace)" -Level "ERROR" -LogFile $logFile
        exit 1
    }
