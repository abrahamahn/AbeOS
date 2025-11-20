<#
    SystemDeepAudit.ps1
    Deep, read-only system audit for:
      - PATH issues
      - Broken app installs
      - Orphan app folders
      - OneDrive remnants
      - Reparse points

    Output:
      C:\AbeOS\logs\system-audit-YYYYMMDD-HHMMSS\
#>

#region Setup output directory
$timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
$baseLogDir = "C:\AbeOS\logs"
if (-not (Test-Path $baseLogDir)) {
    New-Item -ItemType Directory -Path $baseLogDir -Force | Out-Null
}
$logDir = Join-Path $baseLogDir "system-audit-$timestamp"
New-Item -ItemType Directory -Path $logDir -Force | Out-Null
Write-Host "[-] Writing audit output to: $logDir"
#endregion

#region Helper: Safe test-path for directories
function Test-DirExists {
    param(
        [string]$Path
    )
    if ([string]::IsNullOrWhiteSpace($Path)) { return $false }
    try {
        return (Test-Path -LiteralPath $Path -PathType Container)
    } catch {
        return $false
    }
}

#region Helper: Run external command with timeout and optional append logging
function Invoke-CommandWithTimeout {
    param(
        [string]$FilePath,
        [string[]]$Arguments,
        [string]$OutputFile,
        [int]$TimeoutSeconds = 90,
        [switch]$Append
    )

    $tempFile = [System.IO.Path]::GetTempFileName()
    try {
        $proc = Start-Process -FilePath $FilePath -ArgumentList $Arguments -NoNewWindow `
            -RedirectStandardOutput $tempFile -RedirectStandardError $tempFile -PassThru
    } catch {
        "Failed to start $FilePath $Arguments : $_" | Out-File -FilePath $OutputFile -Encoding UTF8 -Append:$Append
        return
    }

    $exited = $proc.WaitForExit($TimeoutSeconds * 1000)
    if (-not $exited) {
        try { $proc.Kill() } catch {}
        "Command timed out after ${TimeoutSeconds}s: $FilePath $Arguments" | Out-File -FilePath $OutputFile -Encoding UTF8 -Append:$Append
    } else {
        try {
            Get-Content -Path $tempFile -Encoding UTF8 | Out-File -FilePath $OutputFile -Append:$Append -Encoding UTF8
        } catch {
            "Failed to capture output for $FilePath $Arguments : $_" | Out-File -FilePath $OutputFile -Encoding UTF8 -Append:$Append
        }
    }
    "`r`n" | Out-File -FilePath $OutputFile -Append:$Append -Encoding UTF8

    try { Remove-Item $tempFile -ErrorAction SilentlyContinue } catch {}
}
#endregion

#region 1. PATH audit (Machine + User)
Write-Host "[1] Auditing PATH (Machine + User)..."

$pathAudit = @()

$scopes = @(
    @{ Scope = "Machine"; Kind = "System" },
    @{ Scope = "User";    Kind = "User"   }
)

foreach ($scopeInfo in $scopes) {
    $scopeName = $scopeInfo.Scope
    $kind      = $scopeInfo.Kind

    $rawPath = [System.Environment]::GetEnvironmentVariable("PATH", $scopeName)
    if (-not $rawPath) {
        continue
    }

    $split = $rawPath -split ';' | ForEach-Object { $_.Trim() } | Where-Object { $_ -ne "" }

    # Track duplicates within this scope
    $seen = @{}
    for ($i = 0; $i -lt $split.Count; $i++) {
        $entry = $split[$i]
        $lower = $entry.ToLowerInvariant()

        $isDir   = $entry -match "^[A-Za-z]:\\"
        $exists  = $false
        if ($isDir) {
            $exists = Test-DirExists $entry
        }

        $isDup = $seen.ContainsKey($lower)
        if (-not $isDup) { $seen[$lower] = $true }

        $pathAudit += [PSCustomObject]@{
            Scope       = $kind
            Index       = $i
            Original    = $entry
            IsDirectory = $isDir
            Exists      = $exists
            IsDuplicate = $isDup
        }
    }
}

$pathCsv = Join-Path $logDir "PATH_Audit.csv"
$pathAudit | Sort-Object Scope, Exists, IsDuplicate, Original | Export-Csv -NoTypeInformation -Path $pathCsv -Encoding UTF8
Write-Host "    -> PATH audit written to $pathCsv"
#endregion

#region 2. Registry uninstall audit (installed apps vs disk)
Write-Host "[2] Auditing registry uninstall entries..."

$uninstallRoots = @(
    "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall",
    "HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall",
    "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall"
)

$appEntries = @()

foreach ($root in $uninstallRoots) {
    if (-not (Test-Path $root)) { continue }

    Get-ChildItem $root -ErrorAction SilentlyContinue | ForEach-Object {
        try {
            $p = Get-ItemProperty -LiteralPath $_.PSPath -ErrorAction SilentlyContinue
        } catch {
            return
        }

        $displayName    = $p.DisplayName
        $displayVersion = $p.DisplayVersion
        $publisher      = $p.Publisher
        $installLoc     = $p.InstallLocation
        $uninstallStr   = $p.UninstallString
        $displayIcon    = $p.DisplayIcon

        if (-not $displayName -and -not $installLoc -and -not $uninstallStr) {
            return
        }

        $installExists = $false
        if ($installLoc) {
            $installExists = Test-DirExists $installLoc
        }

        # Try to check DisplayIcon path (strip arguments and quotes)
        $iconExists = $null
        if ($displayIcon) {
            $iconPath = $displayIcon
            # Remove quotes
            $iconPath = $iconPath.Trim('"')
            # Remove arguments if any
            $spaceIndex = $iconPath.IndexOf(".exe ")
            if ($spaceIndex -gt 0) {
                $iconPath = $iconPath.Substring(0, $spaceIndex + 4)
            }
            if ($iconPath.EndsWith(".exe", [System.StringComparison]::OrdinalIgnoreCase)) {
                try {
                    $iconExists = Test-Path -LiteralPath $iconPath
                } catch {
                    $iconExists = $false
                }
            }
        }

        $appEntries += [PSCustomObject]@{
            RootKey          = $root
            KeyName          = $_.PSChildName
            DisplayName      = $displayName
            DisplayVersion   = $displayVersion
            Publisher        = $publisher
            InstallLocation  = $installLoc
            InstallExists    = $installExists
            UninstallString  = $uninstallStr
            DisplayIcon      = $displayIcon
            DisplayIconExists= $iconExists
        }
    }
}

$appCsv = Join-Path $logDir "InstalledApps_RegistryAudit.csv"
$appEntries | Sort-Object InstallExists, DisplayName | Export-Csv -NoTypeInformation -Path $appCsv -Encoding UTF8
Write-Host "    -> Installed apps registry audit written to $appCsv"
#endregion

#region 3. Orphan app folder audit (no uninstall entry)
Write-Host "[3] Auditing app folders without uninstall entries..."

$appRoots = @(
    "C:\Program Files",
    "C:\Program Files (x86)",
    "C:\Users\abe\AppData\Local",
    "C:\Users\abe\AppData\Roaming"
)

# Build set of known InstallLocations from registry
$knownInstallDirs = $appEntries |
    Where-Object { $_.InstallLocation -and $_.InstallExists } |
    ForEach-Object { $_.InstallLocation.TrimEnd('\').ToLowerInvariant() } |
    Sort-Object -Unique

$orphanFolders = @()

foreach ($root in $appRoots) {
    if (-not (Test-Path $root)) { continue }

    Write-Host "    -> Scanning $root (top-level only)..."
    Get-ChildItem $root -Directory -ErrorAction SilentlyContinue | ForEach-Object {
        $dirPath = $_.FullName.TrimEnd('\')
        $dirLower = $dirPath.ToLowerInvariant()

        $matched = $knownInstallDirs -contains $dirLower

        if (-not $matched) {
            $orphanFolders += [PSCustomObject]@{
                Root        = $root
                FolderName  = $_.Name
                FullPath    = $dirPath
                HasRegistryInstallEntry = $false
            }
        }
    }
}

$orphanCsv = Join-Path $logDir "OrphanAppFolders.csv"
$orphanFolders | Sort-Object Root, FolderName | Export-Csv -NoTypeInformation -Path $orphanCsv -Encoding UTF8
Write-Host "    -> Orphan app folder audit written to $orphanCsv"
#endregion

#region 4. Reparse points / symlinks (potential leftovers, OneDrive, etc.)
Write-Host "[4] Scanning for reparse points (symlinks/junctions)..."

$reparseRoots = @(
    "C:\Users\abe",
    "C:\Program Files",
    "C:\Program Files (x86)",
    "C:\"
)

$reparseEntries = @()

foreach ($root in $reparseRoots) {
    if (-not (Test-Path $root)) { continue }

    Write-Host "    -> Searching reparse points under $root..."
    try {
        Get-ChildItem $root -Recurse -Attributes ReparsePoint -ErrorAction SilentlyContinue | ForEach-Object {
            $reparseEntries += [PSCustomObject]@{
                Root   = $root
                Name   = $_.Name
                FullPath = $_.FullName
                Attributes = $_.Attributes
            }
        }
    } catch {
        # Ignore heavy access errors
    }
}

$reparseCsv = Join-Path $logDir "ReparsePoints.csv"
$reparseEntries | Sort-Object Root, FullPath | Export-Csv -NoTypeInformation -Path $reparseCsv -Encoding UTF8
Write-Host "    -> Reparse points written to $reparseCsv"
#endregion

#region 5. OneDrive remnants (registry search)
Write-Host "[5] Searching registry for OneDrive remnants (this may take a bit)..."

$oneDriveRegLog = Join-Path $logDir "OneDrive_RegistrySearch.txt"

$commands = @(
    'reg query HKCU /f "OneDrive" /s',
    'reg query HKLM /f "OneDrive" /s'
)

$regTimeoutSeconds = 90

foreach ($cmd in $commands) {
    "=== $cmd (timeout ${regTimeoutSeconds}s) ===" | Out-File -FilePath $oneDriveRegLog -Append -Encoding UTF8
    Invoke-CommandWithTimeout -FilePath "cmd.exe" -Arguments @("/c", $cmd) -OutputFile $oneDriveRegLog -TimeoutSeconds $regTimeoutSeconds -Append
}

Write-Host "    -> OneDrive registry search written to $oneDriveRegLog"
#endregion

#region 6. Shell folder mappings (Documents/Desktop/Pictures)
Write-Host "[6] Capturing current shell folder mappings..."

$shellFoldersReport = Join-Path $logDir "ShellFolders.txt"

$keys = @(
    "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\User Shell Folders",
    "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Shell Folders"
)

foreach ($key in $keys) {
    if (-not (Test-Path $key)) { continue }

    "=== $key ===" | Out-File -FilePath $shellFoldersReport -Append -Encoding UTF8
    try {
        Get-ItemProperty $key | Out-File -FilePath $shellFoldersReport -Append -Encoding UTF8
    } catch {
        "Error reading ${key}: $_" | Out-File -FilePath $shellFoldersReport -Append -Encoding UTF8
    }
    "`r`n" | Out-File -FilePath $shellFoldersReport -Append -Encoding UTF8
}

Write-Host "    -> Shell folder mappings written to $shellFoldersReport"
#endregion

#region 7. Quick known tool locations (VS Code, Git, Node, Python, etc.)
Write-Host "[7] Checking some common developer tools..."

$toolReport = Join-Path $logDir "DevTools_QuickCheck.txt"

$tools = @(
    @{ Name = "VSCode";  Path = "C:\Users\abe\AppData\Local\Programs\Microsoft VS Code\Code.exe" },
    @{ Name = "Git";     Path = "C:\Program Files\Git\cmd\git.exe" },
    @{ Name = "Node";    Path = "C:\Program Files\nodejs\node.exe" },
    @{ Name = "Python";  Path = "C:\Python314\python.exe" },
    @{ Name = "PowerShell7"; Path = "C:\Program Files\PowerShell\7\pwsh.exe" }
)

foreach ($t in $tools) {
    $exists = Test-Path -LiteralPath $t.Path
    "$($t.Name): $($t.Path) -> Exists: $exists" | Out-File -FilePath $toolReport -Append -Encoding UTF8
}

Write-Host "    -> Dev tools quick check written to $toolReport"
#endregion

#region 8. UWP / AppX Applications Audit
Write-Host "[8] Auditing UWP/AppX packages..."

$appxCsv = Join-Path $logDir "UWP_Apps.csv"
try {
    Get-AppxPackage |
        Select Name, PackageFullName, InstallLocation, Publisher, Version |
        Export-Csv -Path $appxCsv -NoTypeInformation -Encoding UTF8
} catch {
    "Get-AppxPackage failed: $_" | Out-File -FilePath $appxCsv -Encoding UTF8
}

Write-Host "    -> UWP apps written to $appxCsv"
#endregion

#region 9. Winget Installed Applications
Write-Host "[9] Auditing Winget package list..."

$wingetCsv = Join-Path $logDir "Winget_Apps.csv"
try {
    winget list --accept-source-agreements 2>&1 |
        Out-File -FilePath $wingetCsv -Encoding UTF8
} catch {
    "winget not available: $_" | Out-File -FilePath $wingetCsv -Encoding UTF8
}

Write-Host "    -> Winget list written to $wingetCsv"
#endregion

#region 10. PowerShell Modules
Write-Host "[10] Auditing PowerShell modules..."

$psModulesCsv = Join-Path $logDir "PowerShell_Modules.csv"
try {
    Get-Module -ListAvailable |
        Select Name, Version, Path |
        Export-Csv -Path $psModulesCsv -NoTypeInformation -Encoding UTF8
} catch {
    "Get-Module failed: $_" | Out-File -FilePath $psModulesCsv -Encoding UTF8
}

Write-Host "    -> PowerShell modules written to $psModulesCsv"
#endregion

#region 11. Node.js Global Packages
Write-Host "[11] Auditing Node.js global packages..."

$npmReport = Join-Path $logDir "Node_Global.txt"
try {
    npm -g list --depth=0 2>&1 |
        Out-File -FilePath $npmReport -Encoding UTF8
} catch {
    "npm not available: $_" | Out-File -FilePath $npmReport -Encoding UTF8
}

Write-Host "    -> Node global packages written to $npmReport"
#endregion

#region 12. Python Packages (pip)
Write-Host "[12] Auditing Python pip packages..."

$pythonReport = Join-Path $logDir "Python_Packages.txt"
try {
    pip list 2>&1 |
        Out-File -FilePath $pythonReport -Encoding UTF8
} catch {
    "pip not available: $_" | Out-File -FilePath $pythonReport -Encoding UTF8
}

Write-Host "    -> Python packages written to $pythonReport"
#endregion

#region 13. Rust / Cargo Audit
Write-Host "[13] Auditing Rust / Cargo..."

$cargoReport = Join-Path $logDir "Cargo_Packages.txt"
try {
    cargo install --list 2>&1 |
        Out-File -FilePath $cargoReport -Encoding UTF8
} catch {
    "cargo not available: $_" | Out-File -FilePath $cargoReport -Encoding UTF8
}

Write-Host "    -> Cargo packages written to $cargoReport"
#endregion

#region 14. WSL Ubuntu Audit (dpkg, pip, npm)
Write-Host "[14] Auditing WSL (Ubuntu) packages..."

$wslDir = Join-Path $logDir "WSL"
New-Item -ItemType Directory -Path $wslDir -Force | Out-Null

# dpkg
try {
    wsl -d Ubuntu-22.04 dpkg -l 2>&1 |
        Out-File -FilePath (Join-Path $wslDir "dpkg_list.txt") -Encoding UTF8
} catch {
    "dpkg list failed: $_" | Out-File -FilePath (Join-Path $wslDir "dpkg_list.txt") -Encoding UTF8
}

# pip
try {
    wsl -d Ubuntu-22.04 pip list 2>&1 |
        Out-File -FilePath (Join-Path $wslDir "pip_list.txt") -Encoding UTF8
} catch {
    "pip list failed: $_" | Out-File -FilePath (Join-Path $wslDir "pip_list.txt") -Encoding UTF8
}

# npm
try {
    wsl -d Ubuntu-22.04 npm -g list --depth=0 2>&1 |
        Out-File -FilePath (Join-Path $wslDir "npm_global.txt") -Encoding UTF8
} catch {
    "npm list failed: $_" | Out-File -FilePath (Join-Path $wslDir "npm_global.txt") -Encoding UTF8
}

Write-Host "    -> WSL audit written to $wslDir"
#endregion

#region 15. Drivers
Write-Host "[15] Auditing drivers..."

$driverReport = Join-Path $logDir "Drivers.txt"
try {
    pnputil /enum-drivers 2>&1 |
        Out-File -FilePath $driverReport -Encoding UTF8
} catch {
    "pnputil not available: $_" | Out-File -FilePath $driverReport -Encoding UTF8
}

Write-Host "    -> Drivers written to $driverReport"
#endregion

#region 16. Services
Write-Host "[16] Auditing services..."

$serviceReport = Join-Path $logDir "Services.csv"
try {
    Get-Service |
        Select Name, Status, StartType |
        Export-Csv -Path $serviceReport -NoTypeInformation -Encoding UTF8
} catch {
    "Get-Service failed: $_" | Out-File -FilePath $serviceReport -Encoding UTF8
}

Write-Host "    -> Services written to $serviceReport"
#endregion

#region 17. Scheduled Tasks
Write-Host "[17] Auditing scheduled tasks..."

$taskReport = Join-Path $logDir "ScheduledTasks.txt"
try {
    schtasks /query /fo LIST /v 2>&1 |
        Out-File -FilePath $taskReport -Encoding UTF8
} catch {
    "schtasks failed: $_" | Out-File -FilePath $taskReport -Encoding UTF8
}

Write-Host "    -> Scheduled tasks written to $taskReport"
#endregion

#region 18. PATH Binary Discovery
Write-Host "[18] Enumerating binaries in PATH..."

$pathBinDir = Join-Path $logDir "PATH_Binaries"
New-Item -ItemType Directory -Path $pathBinDir -Force | Out-Null

$allPaths = @(
    ($env:PATH -split ';' | ForEach-Object { $_.Trim() } | Where-Object { $_ -ne "" })
)

foreach ($p in $allPaths) {
    if (-not (Test-Path $p)) { continue }
    $folderName = ($p -replace "[:\\]", "_")
    $fileOutput = Join-Path $pathBinDir "$folderName.txt"
    try {
        Get-ChildItem $p -File -ErrorAction SilentlyContinue |
            Select-Object Name, FullName |
            Out-File -FilePath $fileOutput -Encoding UTF8
    } catch {
        "Enumeration failed for $p : $_" | Out-File -FilePath $fileOutput -Append -Encoding UTF8
    }
}

Write-Host "    -> PATH binaries written to $pathBinDir"
#endregion

#region Summary
$summaryFile = Join-Path $logDir "SUMMARY.txt"
@"
System Deep Audit - $timestamp

Generated at:  $((Get-Date).ToString("u"))
Log directory: $logDir

Artifacts:
  - PATH_Audit.csv
  - InstalledApps_RegistryAudit.csv
  - OrphanAppFolders.csv
  - ReparsePoints.csv
  - OneDrive_RegistrySearch.txt
  - ShellFolders.txt
  - DevTools_QuickCheck.txt
  - UWP_Apps.csv
  - Winget_Apps.csv
  - PowerShell_Modules.csv
  - Node_Global.txt
  - Python_Packages.txt
  - Cargo_Packages.txt
  - WSL\\dpkg_list.txt / pip_list.txt / npm_global.txt
  - Drivers.txt
  - Services.csv
  - ScheduledTasks.txt
  - PATH_Binaries\\*.txt

Next step:
  Review these files and decide what to fix:
    * Broken PATH entries
    * Apps with InstallLocation missing on disk
    * Orphan folders under Program Files / AppData
    * Any remaining OneDrive hooks
"@ | Out-File -FilePath $summaryFile -Encoding UTF8

Write-Host ""
Write-Host "==== AUDIT COMPLETE ====" -ForegroundColor Cyan
Write-Host "All results saved under: $logDir" -ForegroundColor Cyan
#endregion
