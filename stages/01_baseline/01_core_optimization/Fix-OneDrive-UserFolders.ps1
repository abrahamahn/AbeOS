<#
    Fix-UserFolders-And-OneDrive.ps1
    - Move remaining OneDrive user data to local folders
    - Reset HKCU shell folders to local paths
    - Clean remaining OneDrive registry/env hooks

    Run in: PowerShell 7 or Windows PowerShell
    Recommended: Run as the logged-in user "abe"
#>

$ErrorActionPreference = "Stop"

# -----------------------------
# 0. Setup paths & backup dir
# -----------------------------
$UserName  = "abe"
$UserRoot  = "C:\Users\$UserName"
$OneDriveRoot = Join-Path $UserRoot "OneDrive"
$backupRoot = "C:\AbeOS\backups"
$timestamp  = Get-Date -Format "yyyyMMdd-HHmmss"
$backupDir  = Join-Path $backupRoot "onedrive-fix-$timestamp"

if (-not (Test-Path $backupRoot)) {
    New-Item -ItemType Directory -Path $backupRoot -Force | Out-Null
}
New-Item -ItemType Directory -Path $backupDir -Force | Out-Null

Write-Host "Backup directory: $backupDir"

# -----------------------------
# 1. Backup relevant registry keys
# -----------------------------
Write-Host "Backing up registry keys..."

$regExports = @(
    @{ Key = "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\User Shell Folders"; File = "HKCU_UserShellFolders.reg" },
    @{ Key = "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Shell Folders";      File = "HKCU_ShellFolders.reg" },
    @{ Key = "HKCU\Software\Microsoft\OneDrive";                                           File = "HKCU_OneDrive.reg" },
    @{ Key = "HKLM\Software\Microsoft\OneDrive";                                           File = "HKLM_OneDrive.reg" }
)

foreach ($item in $regExports) {
    $key  = $item.Key
    $file = Join-Path $backupDir $item.File

    Write-Host "  -> Exporting $key ..."
    try {
        reg.exe export $key $file /y | Out-Null
    } catch {
        Write-Host "    (Could not export $key, it may not exist.)"
    }
}

# -----------------------------
# 2. Ensure local folders exist
# -----------------------------
Write-Host "Ensuring local user folders exist..."

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
        Write-Host "  -> Creating $path"
        New-Item -ItemType Directory -Path $path -Force | Out-Null
    }
}

# -----------------------------
# 3. Migrate remaining OneDrive data (if any)
# -----------------------------
Write-Host "Migrating remaining OneDrive data (if present)..."

$oneDriveSubfolders = @(
    @{ Source = "Desktop";   Target = "Desktop"   },
    @{ Source = "Documents"; Target = "Documents" },
    @{ Source = "Downloads"; Target = "Downloads" },
    @{ Source = "Pictures";  Target = "Pictures"  },
    @{ Source = "Music";     Target = "Music"     },
    @{ Source = "Videos";    Target = "Videos"    }
)

foreach ($entry in $oneDriveSubfolders) {
    $src = Join-Path $OneDriveRoot $entry.Source
    $dst = Join-Path $UserRoot    $entry.Target

    if (Test-Path $src) {
        Write-Host "  -> Moving from $src to $dst"
        # Use MOVE to fully detach from OneDrive, but with limited retries
        robocopy $src $dst /E /COPYALL /MOVE /R:3 /W:5 | Out-Null
    } else {
        Write-Host "  -> Skipping $src (does not exist)"
    }
}

# -----------------------------
# 4. Reset HKCU shell folders to LOCAL paths
# -----------------------------
Write-Host "Resetting HKCU shell folders to local paths..."

# Use %USERPROFILE% so it survives future rename/migration
$envUserProfile = "%USERPROFILE%"

# User Shell Folders (expandable)
$userShellKey = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\User Shell Folders"

if (-not (Test-Path $userShellKey)) {
    New-Item -Path $userShellKey -Force | Out-Null
}

$map = @{
    "Personal" = "$envUserProfile\Documents"
    "Desktop"  = "$envUserProfile\Desktop"
    "My Pictures" = "$envUserProfile\Pictures"
    "My Music"    = "$envUserProfile\Music"
    "My Video"    = "$envUserProfile\Videos"
    # Downloads special GUID: {374DE290-123F-4565-9164-39C4925E467B}
    "{374DE290-123F-4565-9164-39C4925E467B}" = "$envUserProfile\Downloads"
}

foreach ($name in $map.Keys) {
    $value = $map[$name]
    Write-Host "  -> User Shell Folders: $name = $value"
    New-ItemProperty -Path $userShellKey -Name $name -Value $value -PropertyType ExpandString -Force | Out-Null
}

# Shell Folders (non-expandable, absolute paths)
$shellKey = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Shell Folders"

if (-not (Test-Path $shellKey)) {
    New-Item -Path $shellKey -Force | Out-Null
}

$mapAbsolute = @{
    "Personal" = "$UserRoot\Documents"
    "Desktop"  = "$UserRoot\Desktop"
    "My Pictures" = "$UserRoot\Pictures"
    "My Music"    = "$UserRoot\Music"
    "My Video"    = "$UserRoot\Videos"
    "{374DE290-123F-4565-9164-39C4925E467B}" = "$UserRoot\Downloads"
}

foreach ($name in $mapAbsolute.Keys) {
    $value = $mapAbsolute[$name]
    Write-Host "  -> Shell Folders: $name = $value"
    New-ItemProperty -Path $shellKey -Name $name -Value $value -PropertyType String -Force | Out-Null
}

# -----------------------------
# 5. Remove OneDrive registry hooks (HKCU/HKLM Software\Microsoft\OneDrive)
# -----------------------------
Write-Host "Removing remaining OneDrive registry hooks..."

$oneDriveRegKeys = @(
    "HKCU\Software\Microsoft\OneDrive",
    "HKLM\Software\Microsoft\OneDrive"
)

foreach ($key in $oneDriveRegKeys) {
    Write-Host "  -> Deleting $key (if exists)..."
    try {
        reg.exe delete $key /f | Out-Null
    } catch {
        Write-Host "     (Could not delete $key, may not exist.)"
    }
}

# -----------------------------
# 6. Clean OneDrive-related environment variables
# -----------------------------
Write-Host "Cleaning OneDrive-related environment variables..."

$envKeys = @(
    "OneDrive",
    "OneDriveConsumer",
    "OneDriveCommercial"
)

foreach ($name in $envKeys) {
    Write-Host "  -> Removing user env var: $name"
    [System.Environment]::SetEnvironmentVariable($name, $null, "User")

    Write-Host "  -> Removing machine env var: $name"
    [System.Environment]::SetEnvironmentVariable($name, $null, "Machine")
}

Write-Host ""
Write-Host "================================================"
Write-Host " DONE: OneDrive migration + shell-folder reset  "
Write-Host "================================================"
Write-Host "Actions:"
Write-Host "  - Remaining OneDrive subfolders moved to local user folders (if present)"
Write-Host "  - HKCU Shell Folders and User Shell Folders now point to local paths"
Write-Host "  - Microsoft\\OneDrive registry keys removed (with backups in $backupDir)"
Write-Host "  - OneDrive-related environment variables cleared"
Write-Host ""
Write-Host "IMPORTANT: Please reboot Windows to let Explorer and apps pick up the new paths."
