<#
    AbeOS-Master-System-Repair.ps1

    Goals:
      - Fully detach OneDrive (services, tasks, env, registry) from this profile
      - Re-assert LOCAL shell folders (Documents, Desktop, Downloads, Pictures, Music, Videos)
      - Log and inspect ghost profile: C:\Users\abe.ABE-ZEPHYRUS (NO deletion yet)
      - Validate PATH entries and log missing folders (no dangerous auto-removal)
      - Set policies to prevent future OneDrive auto-hooking of user folders

    Run as: abe (PowerShell 7 is fine; admin recommended)
#>

$ErrorActionPreference = "Stop"

# -----------------------------
# 0. Basic setup
# -----------------------------
$UserName          = "abe"
$UserRoot          = "C:\Users\$UserName"
$AltProfileRoot    = "C:\Users\abe.ABE-ZEPHYRUS"
$SystemRoot        = $env:SystemRoot   # e.g., C:\Windows

$abeOSRoot         = "C:\AbeOS"
$scriptsRoot       = Join-Path $abeOSRoot "scripts"
$backupRoot        = Join-Path $abeOSRoot "backups"
$logRoot           = Join-Path $abeOSRoot "logs"

$timestamp         = Get-Date -Format "yyyyMMdd-HHmmss"
$sessionId         = "repair-$timestamp"

$backupDir         = Join-Path $backupRoot $sessionId
$logDir            = Join-Path $logRoot   $sessionId

New-Item -ItemType Directory -Path $backupDir -Force | Out-Null
New-Item -ItemType Directory -Path $logDir   -Force | Out-Null

$logFile           = Join-Path $logDir "AbeOS-Master-System-Repair.log"

function Write-Log {
    param(
        [string]$Message
    )
    $stamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $line  = "[$stamp] $Message"
    Write-Host $line
    Add-Content -Path $logFile -Value $line
}

Write-Log "=== AbeOS Master System Repair started ==="
Write-Log "Backup directory: $backupDir"
Write-Log "Log directory   : $logDir"
Write-Log "User profile    : $UserRoot"

# Safety check
if (-not (Test-Path $UserRoot)) {
    Write-Log "ERROR: User root $UserRoot does not exist. Aborting."
    throw "User root not found."
}

# -----------------------------
# 1. Registry backups
# -----------------------------
Write-Log "Step 1: Exporting key registry hives for backup..."

$regExports = @(
    @{ Key = "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\User Shell Folders"; File = "HKCU_UserShellFolders.reg" },
    @{ Key = "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Shell Folders";      File = "HKCU_ShellFolders.reg" },
    @{ Key = "HKCU\Software\Microsoft\OneDrive";                                           File = "HKCU_OneDrive.reg" },
    @{ Key = "HKLM\Software\Microsoft\OneDrive";                                           File = "HKLM_OneDrive.reg" },
    @{ Key = "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\ProfileList";              File = "HKLM_ProfileList.reg" }
)

foreach ($item in $regExports) {
    $key  = $item.Key
    $file = Join-Path $backupDir $item.File
    try {
        Write-Log "  Exporting $key -> $file"
        & reg.exe export $key $file /y | Out-Null
    } catch {
        Write-Log "  (Warning: Could not export $key; it may not exist.)"
    }
}

# -----------------------------
# 2. Ensure local user folders exist
# -----------------------------
Write-Log "Step 2: Ensuring local user folders exist..."

$localFolders = @(
    "Desktop",
    "Documents",
    "Downloads",
    "Pictures",
    "Music",
    "Videos"
)

foreach ($name in $localFolders) {
    $path = Join-Path $UserRoot $name
    if (-not (Test-Path $path)) {
        Write-Log "  Creating folder: $path"
        New-Item -ItemType Directory -Path $path -Force | Out-Null
    } else {
        Write-Log "  Exists: $path"
    }
}

# -----------------------------
# 3. OneDrive: stop processes, uninstall, clean folders
# -----------------------------
Write-Log "Step 3: OneDrive cleanup (processes, binaries, folders)..."

# 3a. Kill running OneDrive-related processes
$procNames = @("OneDrive", "FileCoAuth", "FileSyncConfig", "FileSyncHelper")
foreach ($name in $procNames) {
    try {
        $procs = Get-Process -Name $name -ErrorAction SilentlyContinue
        if ($procs) {
            Write-Log "  Killing process: $name"
            $procs | Stop-Process -Force
        } else {
            Write-Log "  Process not running: $name"
        }
    } catch {
        Write-Log "  (Warning: Could not kill process $name)"
    }
}

# 3b. Attempt OneDrive uninstaller (both 64-bit and 32-bit)
$oneDriveSetup64 = Join-Path $SystemRoot "System32\OneDriveSetup.exe"
$oneDriveSetup32 = Join-Path $SystemRoot "SysWOW64\OneDriveSetup.exe"

if (Test-Path $oneDriveSetup64) {
    Write-Log "  Running OneDrive uninstaller (64-bit)..."
    try {
        & $oneDriveSetup64 /uninstall | Out-Null
    } catch {
        Write-Log "  (Warning: OneDrive 64-bit uninstall may have already been done.)"
    }
} else {
    Write-Log "  OneDriveSetup.exe (64-bit) not found."
}

if (Test-Path $oneDriveSetup32) {
    Write-Log "  Running OneDrive uninstaller (32-bit)..."
    try {
        & $oneDriveSetup32 /uninstall | Out-Null
    } catch {
        Write-Log "  (Warning: OneDrive 32-bit uninstall may have already been done.)"
    }
} else {
    Write-Log "  OneDriveSetup.exe (32-bit) not found."
}

# 3c. Remove known OneDrive folders if present
$oneDrivePaths = @(
    "$env:LOCALAPPDATA\Microsoft\OneDrive",
    "$env:PROGRAMDATA\Microsoft OneDrive",
    (Join-Path $UserRoot "OneDrive"),
    "C:\OneDriveTemp"
)

foreach ($p in $oneDrivePaths) {
    if (Test-Path $p) {
        Write-Log "  Removing OneDrive folder: $p"
        try {
            Remove-Item $p -Recurse -Force
        } catch {
            Write-Log "  (Warning: Failed to remove $p, may be partially locked.)"
        }
    } else {
        Write-Log "  OneDrive path not found: $p"
    }
}

# 3d. Remove reparse points that might still exist for OneDrive base
$reparseTargets = @(
    (Join-Path $UserRoot "OneDrive"),
    "C:\OneDriveTemp"
)

foreach ($rp in $reparseTargets) {
    try {
        Write-Log "  Ensuring $rp is not a reparse point..."
        & fsutil reparsepoint delete $rp 2>$null
    } catch {
        Write-Log "  (Info: Could not delete reparse point $rp; may not exist.)"
    }
}

# -----------------------------
# 4. Shell folders: force LOCAL paths
# -----------------------------
Write-Log "Step 4: Re-assert LOCAL shell folder mappings..."

$envUserProfile = "%USERPROFILE%"

# User Shell Folders (expandable)
$userShellKey = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\User Shell Folders"
if (-not (Test-Path $userShellKey)) {
    New-Item -Path $userShellKey -Force | Out-Null
}

$userShellMap = @{
    "Personal"                               = "$envUserProfile\Documents"
    "Desktop"                                = "$envUserProfile\Desktop"
    "My Pictures"                            = "$envUserProfile\Pictures"
    "My Music"                               = "$envUserProfile\Music"
    "My Video"                               = "$envUserProfile\Videos"
    "{374DE290-123F-4565-9164-39C4925E467B}" = "$envUserProfile\Downloads"
}

foreach ($name in $userShellMap.Keys) {
    $value = $userShellMap[$name]
    Write-Log "  User Shell Folders: $name = $value"
    New-ItemProperty -Path $userShellKey -Name $name -Value $value -PropertyType ExpandString -Force | Out-Null
}

# Shell Folders (absolute)
$shellKey = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Shell Folders"
if (-not (Test-Path $shellKey)) {
    New-Item -Path $shellKey -Force | Out-Null
}

$shellMapAbs = @{
    "Personal"                               = "$UserRoot\Documents"
    "Desktop"                                = "$UserRoot\Desktop"
    "My Pictures"                            = "$UserRoot\Pictures"
    "My Music"                               = "$UserRoot\Music"
    "My Video"                               = "$UserRoot\Videos"
    "{374DE290-123F-4565-9164-39C4925E467B}" = "$UserRoot\Downloads"
}

foreach ($name in $shellMapAbs.Keys) {
    $value = $shellMapAbs[$name]
    Write-Log "  Shell Folders: $name = $value"
    New-ItemProperty -Path $shellKey -Name $name -Value $value -PropertyType String -Force | Out-Null
}

# -----------------------------
# 5. Remove OneDrive registry hooks + set policies to block it
# -----------------------------
Write-Log "Step 5: Registry cleanup for OneDrive + hard-disable policies..."

# Direct OneDrive keys
$oneDriveRegKeys = @(
    "HKCU\Software\Microsoft\OneDrive",
    "HKLM\Software\Microsoft\OneDrive"
)

foreach ($key in $oneDriveRegKeys) {
    Write-Log "  Deleting registry key (if exists): $key"
    try {
        & reg.exe delete $key /f | Out-Null
    } catch {
        Write-Log "  (Info: $key may already be gone.)"
    }
}

# Policies to block auto-onboarding and known folder move
$policyKey = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\OneDrive"
if (-not (Test-Path $policyKey)) {
    Write-Log "  Creating OneDrive policy key: $policyKey"
    New-Item -Path $policyKey -Force | Out-Null
}

Write-Log "  Setting DisableFileSyncNGSC = 1 (disable OneDrive sync engine)"
New-ItemProperty -Path $policyKey -Name "DisableFileSyncNGSC" -Value 1 -PropertyType DWord -Force | Out-Null

Write-Log "  Setting DisableLibrariesDefaultSaveToOneDrive = 1"
New-ItemProperty -Path $policyKey -Name "DisableLibrariesDefaultSaveToOneDrive" -Value 1 -PropertyType DWord -Force | Out-Null

Write-Log "  Setting DisableFileSync = 1 (legacy block)"
New-ItemProperty -Path $policyKey -Name "DisableFileSync" -Value 1 -PropertyType DWord -Force | Out-Null

# Environment variables related to OneDrive
Write-Log "  Clearing OneDrive-related environment variables..."

$envKeys = @(
    "OneDrive",
    "OneDriveConsumer",
    "OneDriveCommercial"
)

foreach ($name in $envKeys) {
    Write-Log "    Clearing user env var: $name"
    [System.Environment]::SetEnvironmentVariable($name, $null, "User")
    Write-Log "    Clearing machine env var: $name"
    [System.Environment]::SetEnvironmentVariable($name, $null, "Machine")
}

# -----------------------------
# 6. Remove OneDrive Scheduled Tasks
# -----------------------------
Write-Log "Step 6: Removing OneDrive-related scheduled tasks..."

try {
    $tasks = Get-ScheduledTask | Where-Object { $_.TaskName -like "*OneDrive*" -or $_.TaskPath -like "*OneDrive*" }
    foreach ($t in $tasks) {
        Write-Log "  Unregistering task: $($t.TaskName)"
        Unregister-ScheduledTask -TaskName $t.TaskName -Confirm:$false -TaskPath $t.TaskPath
    }
} catch {
    Write-Log "  (Info: No OneDrive tasks found or task removal failed.)"
}

# -----------------------------
# 7. Ghost profile inspection: C:\Users\abe.ABE-ZEPHYRUS
# -----------------------------
Write-Log "Step 7: Inspecting ghost profile: $AltProfileRoot (NO deletion in this script)..."

$ghostSummaryFile = Join-Path $logDir "GhostProfile_abe.ABE-ZEPHYRUS.txt"

if (Test-Path $AltProfileRoot) {
    Write-Log "  Ghost profile EXISTS. Logging top-level structure."

    # Basic info
    $sizeBytes = (Get-ChildItem $AltProfileRoot -Recurse -ErrorAction SilentlyContinue | Measure-Object -Property Length -Sum).Sum
    $sizeGB    = [Math]::Round(($sizeBytes / 1GB), 3)

    "Ghost profile: $AltProfileRoot" | Out-File -FilePath $ghostSummaryFile -Encoding UTF8
    "Approx size (GB): $sizeGB"       | Out-File -FilePath $ghostSummaryFile -Encoding UTF8 -Append
    "`r`nTop-level items:"            | Out-File -FilePath $ghostSummaryFile -Encoding UTF8 -Append

    Get-ChildItem $AltProfileRoot | Select-Object Name, FullName, Mode, LastWriteTime |
        Format-Table -AutoSize | Out-String |
        Out-File -FilePath $ghostSummaryFile -Encoding UTF8 -Append

    Write-Log "  Ghost profile summary written to: $ghostSummaryFile"
    Write-Log "  NOTE: No deletion performed. Review log, then we can safely design a targeted cleanup."
} else {
    Write-Log "  Ghost profile path does NOT exist. Nothing to do."
}

# -----------------------------
# 8. PATH validation (log-only)
# -----------------------------
Write-Log "Step 8: PATH validation (logging missing folders, NO edits)..."

$pathAuditCsv = Join-Path $logDir "PATH_Validation.csv"

$rawPath = [System.Environment]::GetEnvironmentVariable("PATH", "Machine") + ";" +
           [System.Environment]::GetEnvironmentVariable("PATH", "User")

$pathEntries = $rawPath -split ";" | Where-Object { $_ -and $_.Trim() -ne "" } | Select-Object -Unique

$pathReport = foreach ($entry in $pathEntries) {
    $trimmed = $entry.Trim()
    $exists  = Test-Path $trimmed
    [PSCustomObject]@{
        PathEntry = $trimmed
        Exists    = $exists
    }
}

$pathReport | Sort-Object Exists, PathEntry | Export-Csv -Path $pathAuditCsv -NoTypeInformation -Encoding UTF8

Write-Log "  PATH validation written to: $pathAuditCsv"
Write-Log "  (We are NOT editing PATH automatically here, only logging status.)"

# -----------------------------
# 9. Final summary + reminders
# -----------------------------
Write-Log "=== AbeOS Master System Repair completed ==="
Write-Log "Please REBOOT Windows to let Explorer, shell folders, and policies fully reload."
Write-Log "After reboot, verify:"
Write-Log "  - Documents, Desktop, Downloads, Pictures, Music, Videos all under C:\Users\abe"
Write-Log "  - OneDrive does NOT auto-start or appear as active sync"
Write-Log "  - No new OneDrive reparse points or tasks"
Write-Log "  - Dev tools still run (Git, Node, Python, etc.)"
