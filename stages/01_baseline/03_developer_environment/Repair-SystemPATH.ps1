#Requires -RunAsAdministrator
<#
.SYNOPSIS
    Cleans and rebuilds System and User PATH environment variables for Zephyrus G14.
.DESCRIPTION
    Fixes corrupted, duplicated, and missing PATH entries documented in DEBUG4.md.

    Creates a clean, deterministic, reproducible PATH configuration:
    - Machine PATH: Windows system folders, development tools, CUDA, etc.
    - User PATH: WindowsApps, oh-my-posh, node, Python, GitHub CLI, local bin

    Removes:
    - Duplicate entries
    - Invalid/non-existent paths
    - Bloated tool paths (that were uninstalled)

    Ensures critical tools are accessible:
    - code (VS Code)
    - oh-my-posh
    - git, node, python
    - winget, docker, cuda
.PARAMETER BackupPATH
    Create backup of current PATH before modifying (default: $true)
.PARAMETER WhatIf
    Preview changes without applying them
.EXAMPLE
    .\Repair-SystemPATH.ps1
.EXAMPLE
    .\Repair-SystemPATH.ps1 -WhatIf
.NOTES
    File: Repair-SystemPATH.ps1
    Phase: 1.3 - Developer Environment
    System: Windows 11 (Zephyrus G14)

    WARNING: This script modifies system environment variables.
    A backup will be created before changes.
#>

[CmdletBinding(SupportsShouldProcess)]
param(
    [bool]$BackupPATH = $true
)

$ErrorActionPreference = "Stop"

# Import AbeOS core module for logging
$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot "..\..\..")).ProviderPath
Import-Module (Join-Path $repoRoot "modules\lib\AbeOS.Core.psm1") -Force

Write-AbeLog "==================================================" -Level Info
Write-AbeLog "  AbeOS System PATH Repair (Zephyrus G14)" -Level Info
Write-AbeLog "==================================================" -Level Info
Write-AbeLog ""

# Step 1: Backup current PATH
if ($BackupPATH) {
    Write-AbeLog "Step 1: Backing up current PATH..." -Level Info

    $timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
    $backupDir = Join-Path $repoRoot "backups\path"

    if (-not (Test-Path $backupDir)) {
        New-Item -ItemType Directory -Path $backupDir -Force | Out-Null
    }

    $backupFile = Join-Path $backupDir "PATH_backup_$timestamp.json"

    $pathBackup = @{
        Timestamp = $timestamp
        MachinePATH = [Environment]::GetEnvironmentVariable("Path", "Machine")
        UserPATH = [Environment]::GetEnvironmentVariable("Path", "User")
    }

    $pathBackup | ConvertTo-Json | Set-Content -Path $backupFile

    Write-AbeLog "✓ PATH backed up to: $backupFile" -Level Success
}

# Step 2: Define clean Machine PATH
Write-AbeLog "`nStep 2: Building clean Machine PATH..." -Level Info

$machinePaths = @(
    # Windows System
    "C:\Windows\system32",
    "C:\Windows",
    "C:\Windows\System32\Wbem",
    "C:\Windows\System32\WindowsPowerShell\v1.0\",
    "C:\Windows\System32\OpenSSH\",

    # PowerShell 7
    "C:\Program Files\PowerShell\7\",

    # Git
    "C:\Program Files\Git\cmd",

    # .NET
    "C:\Program Files\dotnet\",

    # Docker
    "C:\Program Files\Docker\Docker\resources\bin",

    # NVIDIA CUDA 12.9
    "C:\Program Files\NVIDIA GPU Computing Toolkit\CUDA\v12.9\bin",
    "C:\Program Files\NVIDIA GPU Computing Toolkit\CUDA\v12.9\libnvvp",

    # NVIDIA PhysX & Tools
    "C:\Program Files (x86)\NVIDIA Corporation\PhysX\Common",
    "C:\Program Files\NVIDIA Corporation\Nsight Compute 2025.2.1\",
    "C:\Program Files\NVIDIA Corporation\NVIDIA App\NvDLISR",

    # Java Development Kit
    "C:\Program Files\Eclipse Adoptium\jdk-21.0.9.10-hotspot\bin",
    "C:\Program Files\OpenJDK\jdk-21\bin",
    "C:\Program Files (x86)\Common Files\Oracle\Java\javapath",

    # Python 3.14
    "C:\Python314\",
    "C:\Python314\Scripts\",

    # Database Tools
    "C:\Program Files\Microsoft SQL Server\170\Tools\Binn\",
    "C:\Program Files\Microsoft SQL Server\Client SDK\ODBC\170\Tools\Binn\",
    "C:\Program Files\PostgreSQL\17\bin",

    # MinGW & Chocolatey
    "C:\ProgramData\mingw64\mingw64\bin",
    "C:\ProgramData\chocolatey\bin",

    # Yarn
    "C:\Program Files (x86)\Yarn\bin\",

    # Rust
    "C:\Program Files\Rust stable MSVC 1.91\bin",

    # Go
    "C:\Program Files\Go\bin",

    # Tailscale
    "C:\Program Files\Tailscale\"
)

# Step 3: Filter and validate Machine PATH entries
Write-AbeLog "Validating Machine PATH entries..." -Level Info

$validMachinePaths = @()
$skippedPaths = @()

foreach ($path in $machinePaths) {
    $trimmedPath = $path.Trim()

    if ([string]::IsNullOrWhiteSpace($trimmedPath)) {
        continue
    }

    if (Test-Path $trimmedPath) {
        $validMachinePaths += $trimmedPath
        Write-AbeLog "  ✓ $trimmedPath" -Level Success
    } else {
        $skippedPaths += $trimmedPath
        Write-AbeLog "  ⚠ Skipped (not found): $trimmedPath" -Level Warning
    }
}

# Remove duplicates and sort
$cleanMachinePATH = $validMachinePaths | Select-Object -Unique | Sort-Object

Write-AbeLog "`n✓ Machine PATH: $($cleanMachinePATH.Count) entries" -Level Success

# Step 4: Define clean User PATH
Write-AbeLog "`nStep 3: Building clean User PATH..." -Level Info

$userPaths = @(
    # Windows Apps
    "$env:LOCALAPPDATA\Microsoft\WindowsApps",

    # Oh My Posh
    "$env:LOCALAPPDATA\Programs\oh-my-posh\bin",

    # Claude CLI & Local binaries
    "$env:USERPROFILE\.local\bin",

    # GitHub CLI
    "C:\Program Files\GitHub CLI\",

    # Node.js (Windows)
    "C:\Program Files\nodejs\",

    # Python (User)
    "C:\Python314\",
    "C:\Python314\Scripts\",

    # VS Code
    "$env:LOCALAPPDATA\Programs\Microsoft VS Code\bin"
)

# Step 5: Filter and validate User PATH entries
Write-AbeLog "Validating User PATH entries..." -Level Info

$validUserPaths = @()

foreach ($path in $userPaths) {
    # Expand environment variables
    $expandedPath = [Environment]::ExpandEnvironmentVariables($path)
    $trimmedPath = $expandedPath.Trim()

    if ([string]::IsNullOrWhiteSpace($trimmedPath)) {
        continue
    }

    if (Test-Path $trimmedPath) {
        $validUserPaths += $trimmedPath
        Write-AbeLog "  ✓ $trimmedPath" -Level Success
    } else {
        Write-AbeLog "  ⚠ Skipped (not found): $trimmedPath" -Level Warning
    }
}

# Remove duplicates
$cleanUserPATH = $validUserPaths | Select-Object -Unique

Write-AbeLog "`n✓ User PATH: $($cleanUserPATH.Count) entries" -Level Success

# Step 6: Apply changes
Write-AbeLog "`nStep 4: Applying PATH changes..." -Level Info

if ($PSCmdlet.ShouldProcess("Machine PATH", "Update")) {
    $machinePathString = $cleanMachinePATH -join ";"
    [Environment]::SetEnvironmentVariable("Path", $machinePathString, "Machine")
    Write-AbeLog "✓ Machine PATH updated" -Level Success
}

if ($PSCmdlet.ShouldProcess("User PATH", "Update")) {
    $userPathString = $cleanUserPATH -join ";"
    [Environment]::SetEnvironmentVariable("Path", $userPathString, "User")
    Write-AbeLog "✓ User PATH updated" -Level Success
}

# Step 7: Reload PATH in current session
Write-AbeLog "`nStep 5: Reloading PATH in current session..." -Level Info
$env:PATH = [Environment]::GetEnvironmentVariable("Path", "User") + ";" + [Environment]::GetEnvironmentVariable("Path", "Machine")
Write-AbeLog "✓ PATH reloaded" -Level Success

# Step 8: Verify critical tools
Write-AbeLog "`nStep 6: Verifying critical tools are accessible..." -Level Info

$criticalTools = @(
    "git",
    "node",
    "python",
    "oh-my-posh",
    "code",
    "winget",
    "docker"
)

$toolStatus = @()

foreach ($tool in $criticalTools) {
    if (Get-Command $tool -ErrorAction SilentlyContinue) {
        Write-AbeLog "  ✓ $tool" -Level Success
        $toolStatus += @{ Tool = $tool; Status = "OK" }
    } else {
        Write-AbeLog "  ✗ $tool (not found)" -Level Warning
        $toolStatus += @{ Tool = $tool; Status = "NOT FOUND" }
    }
}

# Step 9: Summary
Write-AbeLog "`n==================================================" -Level Success
Write-AbeLog "  System PATH Repair Complete!" -Level Success
Write-AbeLog "==================================================" -Level Success
Write-AbeLog ""
Write-AbeLog "Configuration Summary:" -Level Info
Write-AbeLog "  Machine PATH entries: $($cleanMachinePATH.Count)" -Level Info
Write-AbeLog "  User PATH entries: $($cleanUserPATH.Count)" -Level Info
Write-AbeLog "  Total PATH entries: $($cleanMachinePATH.Count + $cleanUserPATH.Count)" -Level Info
Write-AbeLog ""

if ($skippedPaths.Count -gt 0) {
    Write-AbeLog "Skipped paths (not found on system):" -Level Warning
    foreach ($skipped in $skippedPaths) {
        Write-AbeLog "  - $skipped" -Level Warning
    }
    Write-AbeLog ""
}

Write-AbeLog "Tool Accessibility:" -Level Info
$okTools = ($toolStatus | Where-Object { $_.Status -eq "OK" }).Count
$missingTools = ($toolStatus | Where-Object { $_.Status -eq "NOT FOUND" }).Count
Write-AbeLog "  ✓ Accessible: $okTools" -Level Success
if ($missingTools -gt 0) {
    Write-AbeLog "  ✗ Missing: $missingTools" -Level Warning
}
Write-AbeLog ""

Write-AbeLog "Next Steps:" -Level Info
Write-AbeLog "  1. RESTART your terminal windows to apply PATH changes" -Level Warning
Write-AbeLog "  2. Test critical tools (git, node, python, code, etc.)" -Level Info
Write-AbeLog "  3. If tools are still missing, install them or check their installation paths" -Level Info
Write-AbeLog ""
Write-AbeLog "Backup Location:" -Level Info
if ($BackupPATH) {
    Write-AbeLog "  $backupFile" -Level Info
}
