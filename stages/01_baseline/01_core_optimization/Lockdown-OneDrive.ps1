#Requires -RunAsAdministrator
<#
.SYNOPSIS
    Blocks OneDrive folder redirection and sync for AbeOS baseline installs.
.DESCRIPTION
    Applies policy keys that prevent OneDrive from hijacking Desktop/Documents/Pictures,
    kills any running sync client, resets known folder paths back to %USERPROFILE%, and
    disables shell integration plus auto-start entries. Designed to be safe/run repeatedly.
.NOTES
    Version: 1.0
    Last Updated: November 2025
#>

param(
    [switch]$SkipExplorerRestart
)

$ErrorActionPreference = "Stop"
$scriptName = "Lockdown-OneDrive"

$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot "..\..\..")).ProviderPath
$modulePath = Join-Path $repoRoot "modules\lib\AbeOS.Core.psm1"
Import-Module $modulePath -Force

$logFile = Initialize-AbeOSLogging -ScriptName $scriptName

function Write-Step {
    param(
        [string]$Message,
        [string]$Level = "INFO"
    )
    Write-AbeOSLog -Message $Message -Level $Level -LogFile $logFile
}

function Ensure-RegistryPath {
    param([string]$Path)
    if (-not (Test-Path $Path)) {
        New-Item -Path $Path -Force | Out-Null
    }
}

function Set-RegistryValue {
    param(
        [string]$Path,
        [string]$Name,
        [object]$Value,
        [Microsoft.Win32.RegistryValueKind]$Type = [Microsoft.Win32.RegistryValueKind]::DWord
    )

    Ensure-RegistryPath -Path $Path
    New-ItemProperty -Path $Path -Name $Name -Value $Value -PropertyType $Type -Force | Out-Null
}

function Remove-RegistryValue {
    param(
        [string]$Path,
        [string]$Name
    )

    if (Test-Path $Path) {
        try {
            Remove-ItemProperty -Path $Path -Name $Name -ErrorAction Stop
        } catch {
            # Value might already be missing; ignore
        }
    }
}

function Reset-KnownFolderPaths {
    $userProfile = $env:USERPROFILE
    $shellFolders = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Shell Folders"
    $userShellFolders = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\User Shell Folders"

    $folders = @(
        @{ Name = "Desktop";    Key = "Desktop";   Expand = "%USERPROFILE%\Desktop";   Literal = (Join-Path $userProfile "Desktop") },
        @{ Name = "Documents";  Key = "Personal";  Expand = "%USERPROFILE%\Documents"; Literal = (Join-Path $userProfile "Documents") },
        @{ Name = "Pictures";   Key = "My Pictures"; Expand = "%USERPROFILE%\Pictures"; Literal = (Join-Path $userProfile "Pictures") },
        @{ Name = "Music";      Key = "My Music";    Expand = "%USERPROFILE%\Music";   Literal = (Join-Path $userProfile "Music") },
        @{ Name = "Videos";     Key = "My Video";    Expand = "%USERPROFILE%\Videos";  Literal = (Join-Path $userProfile "Videos") }
    )

    foreach ($folder in $folders) {
        foreach ($target in @(
                @{ Path = $userShellFolders; Value = $folder.Expand; Type = [Microsoft.Win32.RegistryValueKind]::ExpandString },
                @{ Path = $shellFolders;    Value = $folder.Literal; Type = [Microsoft.Win32.RegistryValueKind]::String }
            )) {

            Ensure-RegistryPath -Path $target.Path
            $current = (Get-ItemProperty -Path $target.Path -Name $folder.Key -ErrorAction SilentlyContinue).$($folder.Key)
            if ($null -eq $current) {
                Set-RegistryValue -Path $target.Path -Name $folder.Key -Value $target.Value -Type $target.Type
                Write-Step ("[+] Set {0} -> {1}" -f $folder.Name, $target.Value) -Level "INFO"
                continue
            }

            if ($current -match "OneDrive") {
                Set-RegistryValue -Path $target.Path -Name $folder.Key -Value $target.Value -Type $target.Type
                Write-Step ("[✓] Reset {0} path to {1}" -f $folder.Name, $target.Value) -Level "SUCCESS"
            } else {
                Write-Step ("[-] {0} already points to {1}" -f $folder.Name, $current) -Level "INFO"
            }
        }
    }
}

try {
    Write-Step "=== BEGIN ONEDRIVE LOCKDOWN ==="

    # 1. Stop any running OneDrive processes
    Write-Step "Stopping OneDrive processes..."
    Get-Process OneDrive -ErrorAction SilentlyContinue | Stop-Process -Force -ErrorAction SilentlyContinue
    Start-Process -FilePath "taskkill.exe" -ArgumentList "/f","/im","OneDrive.exe" -NoNewWindow -Wait -ErrorAction SilentlyContinue
    Write-Step "[✓] OneDrive processes terminated" -Level "SUCCESS"

    # 2. Apply global policy keys (HKLM)
    $policyRoot = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\OneDrive"
    Write-Step "Applying OneDrive policy keys..."
    Set-RegistryValue -Path $policyRoot -Name "DisableFileSync" -Value 1
    Set-RegistryValue -Path $policyRoot -Name "DisableFolderBackup" -Value 1
    Set-RegistryValue -Path $policyRoot -Name "DisableFileSyncNGSC" -Value 1
    Set-RegistryValue -Path $policyRoot -Name "DisableFirstRunWizard" -Value 1

    $oneDrivePolicyRoot = "HKLM:\SOFTWARE\Policies\Microsoft\OneDrive"
    Set-RegistryValue -Path $oneDrivePolicyRoot -Name "DisablePersonalSync" -Value 1
    Set-RegistryValue -Path $oneDrivePolicyRoot -Name "SilentAccountConfig" -Value 0
    Set-RegistryValue -Path $oneDrivePolicyRoot -Name "KFMBlockOptIn" -Value 1

    Write-Step "[✓] Policies applied" -Level "SUCCESS"

    # 3. Remove auto-start entries and user-mode prompts
    Write-Step "Removing OneDrive auto-start entry..."
    Remove-RegistryValue -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Run" -Name "OneDrive"
    Write-Step "[✓] Auto-start disabled" -Level "SUCCESS"

    Write-Step "Marking user OneDrive sync disabled..."
    Set-RegistryValue -Path "HKCU:\Software\Microsoft\OneDrive" -Name "DisablePersonalSync" -Value 1
    Set-RegistryValue -Path "HKCU:\Software\Microsoft\OneDrive" -Name "PreventNetworkTrafficPreUserLogon" -Value 1

    # 4. Remove shell namespace pinning + Explorer entry
    Write-Step "Removing File Explorer namespace pin..."
    $clsid = "HKCR:\CLSID\{018D5C66-4533-4307-9B53-224DE2ED1FE6}"
    Set-RegistryValue -Path $clsid -Name "System.IsPinnedToNameSpaceTree" -Value 0
    Write-Step "[✓] Explorer namespace cleaned up" -Level "SUCCESS"

    # 5. Force Explorer to prefer local known folders
    Write-Step "Resetting known folder paths..."
    Reset-KnownFolderPaths

    # 6. Disable Explorer/OneDrive integration toggles
    $explorerAdvanced = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced"
    Set-RegistryValue -Path $explorerAdvanced -Name "UseOneDriveForFileStorage" -Value 0
    Write-Step "[✓] Explorer prevented from using OneDrive for storage" -Level "SUCCESS"

    Write-Step "=== ONEDRIVE LOCKDOWN COMPLETE ===" -Level "SUCCESS"
    Write-Step "Log file: $logFile"

    if (-not $SkipExplorerRestart) {
        Write-Host "`nRestarting Explorer to release folder handles..." -ForegroundColor Yellow
        Stop-Process -Name explorer -Force -ErrorAction SilentlyContinue
        Start-Process explorer.exe
    }

    Write-Host "`nOneDrive folder redirect has been disabled. Reboot recommended before signing in to Microsoft 365 apps." -ForegroundColor Green

} catch {
    Write-Step ("ERROR: {0}" -f $_.Exception.Message) -Level "ERROR"
    Write-Step ("STACK: {0}" -f $_.ScriptStackTrace) -Level "ERROR"
    throw
}
