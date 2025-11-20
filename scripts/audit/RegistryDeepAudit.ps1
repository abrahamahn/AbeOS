<#
    AbeOS Registry Deep Audit
    Modes:
      A - Safe audit + auto-delete verified orphan entries
      B - Audit + ask before deleting each category
      C - Aggressive audit + ask before deleting each entry
      D - Audit only + create cleanup script (no deletions)

    Output: C:\AbeOS\logs\registry-audit-YYYYMMDD-HHMMSS\
#>

# ============================================================
# 0. Mode Selection
# ============================================================

Write-Host ""
Write-Host "AbeOS Registry Deep Audit" -ForegroundColor Cyan
Write-Host ""
Write-Host "Select audit mode:"
Write-Host "  A) Safe Audit + Auto-Delete Verified Orphans"
Write-Host "  B) Audit + Prompt Before Deleting Category"
Write-Host "  C) Aggressive Audit + Prompt Before Each Entry"
Write-Host "  D) Audit Only (Generate Cleanup Script)"
Write-Host ""

$mode = Read-Host "Enter A / B / C / D"
$mode = $mode.ToUpper()

if ($mode -notin @("A", "B", "C", "D")) {
    Write-Host "Invalid mode. Exiting." -ForegroundColor Red
    exit
}

# ============================================================
# 1. Setup logging
# ============================================================

$timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
$baseLogDir = "C:\AbeOS\logs"
if (-not (Test-Path $baseLogDir)) { New-Item -ItemType Directory -Path $baseLogDir | Out-Null }

$logDir = Join-Path $baseLogDir "registry-audit-$timestamp"
New-Item -ItemType Directory -Path $logDir -Force | Out-Null

$cleanupScript = Join-Path $logDir "CleanupCommands.ps1"

Write-Host "[+] Logging to: $logDir" -ForegroundColor Cyan

# ============================================================
# Helper: Action depending on mode
# ============================================================

function Handle-Entry {
    param(
        [string]$description,
        [string]$deleteCommand,
        [string]$category
    )

    switch ($mode) {
        "A" {
            # Auto-delete verified safe entries
            Invoke-Expression $deleteCommand
        }
        "B" {
            # Ask per category (once)
            if (-not $script:confirmedCategory.ContainsKey($category)) {
                $answer = Read-Host "Delete category '$category'? (y/n)"
                $script:confirmedCategory[$category] = ($answer -eq "y")
            }
            if ($script:confirmedCategory[$category]) {
                Invoke-Expression $deleteCommand
            }
        }
        "C" {
            # Ask per entry
            $ans = Read-Host "Delete entry: $description ? (y/n)"
            if ($ans -eq "y") { Invoke-Expression $deleteCommand }
        }
        "D" {
            # Dump cleanup commands only
            $deleteCommand | Out-File -FilePath $cleanupScript -Append
        }
    }
}

$script:confirmedCategory = @{}
# ============================================================
# 2. Audit: Orphan Uninstall Keys (with fuzzy-safe detection)
# ============================================================

Write-Host "[1] Auditing orphan uninstall entries (fuzzy-safe)..."

# Roots to scan
$unistRoots = @(
    "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall",
    "HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall",
    "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall"
)

$unistReport = Join-Path $logDir "OrphanUninstall_Fuzzy.csv"
$unistResults = @()

# Preload services & processes once for performance
$allServices  = Get-Service -ErrorAction SilentlyContinue
$allProcesses = Get-Process -ErrorAction SilentlyContinue

# Roots to search on disk for fuzzy app presence
$searchRoots = @(
    "C:\Program Files",
    "C:\Program Files (x86)",
    "C:\ProgramData",
    "C:\Users\abe\AppData\Local",
    "C:\Users\abe\AppData\Roaming"
) | Where-Object { Test-Path $_ }

function Get-AppSearchTokens {
    param(
        [string]$DisplayName
    )
    if ([string]::IsNullOrWhiteSpace($DisplayName)) { return @() }

    $stopWords = @(
        "microsoft","update","redistributable","driver","runtime","x64","x86",
        "setup","installer","visual","c++","client","service","tools","helper",
        "framework","library"
    )

    $rawTokens = $DisplayName -split '\s+' |
                 ForEach-Object { $_.Trim().Trim(',','.','-','_','(',')') } |
                 Where-Object { $_.Length -ge 3 }

    $tokens = $rawTokens | Where-Object {
        $lower = $_.ToLowerInvariant()
        $stopWords -notcontains $lower
    }

    return ($tokens | Select-Object -Unique | Select-Object -First 3)
}

function Test-ExeExistsFromCommand {
    param(
        [string]$CommandLine
    )
    if ([string]::IsNullOrWhiteSpace($CommandLine)) { return $false }

    # Strip quotes and arguments: "C:\path\app.exe" /foo /bar
    $clean = $CommandLine.Trim()
    if ($clean.StartsWith('"')) {
        $secondQuote = $clean.IndexOf('"', 1)
        if ($secondQuote -gt 1) {
            $exe = $clean.Substring(1, $secondQuote - 1)
        } else {
            $exe = $clean.Trim('"')
        }
    } else {
        $exe = $clean.Split(" ")[0]
    }

    if (-not [string]::IsNullOrWhiteSpace($exe)) {
        try {
            return (Test-Path -LiteralPath $exe)
        } catch { return $false }
    }

    return $false
}

foreach ($root in $unistRoots) {
    if (-not (Test-Path $root)) { continue }

    foreach ($key in Get-ChildItem $root -ErrorAction SilentlyContinue) {
        try {
            $p = Get-ItemProperty $key.PSPath -ErrorAction SilentlyContinue
        } catch {
            continue
        }

        $displayName    = $p.DisplayName
        $displayVersion = $p.DisplayVersion
        $publisher      = $p.Publisher
        $installLoc     = $p.InstallLocation
        $uninstallStr   = $p.UninstallString
        $displayIcon    = $p.DisplayIcon

        # Skip totally empty/anonymous entries
        if (-not $displayName -and -not $installLoc -and -not $uninstallStr -and -not $displayIcon) {
            continue
        }

        # 1) InstallLocation exists?
        $installExists = $false
        if ($installLoc) {
            try { $installExists = Test-Path -LiteralPath $installLoc } catch { $installExists = $false }
        }

        # 2) DisplayIcon exe exists?
        $iconExists = $false
        if ($displayIcon) {
            $iconPath = $displayIcon.Trim('"')
            # strip arguments if any after .exe
            $exeIndex = $iconPath.ToLower().IndexOf(".exe")
            if ($exeIndex -ge 0) {
                $iconPath = $iconPath.Substring(0, $exeIndex + 4)
            }
            try { $iconExists = Test-Path -LiteralPath $iconPath } catch { $iconExists = $false }
        }

        # 3) UninstallString exe exists?
        $uninstExists = Test-ExeExistsFromCommand -CommandLine $uninstallStr

        # 4) Fuzzy on-disk search using tokens from DisplayName
        $tokens = Get-AppSearchTokens -DisplayName $displayName
        $foundOnDisk = $false
        if ($tokens.Count -gt 0) {
            foreach ($rootDir in $searchRoots) {
                if ($foundOnDisk) { break }
                try {
                    $topDirs = Get-ChildItem $rootDir -Directory -ErrorAction SilentlyContinue
                    foreach ($t in $tokens) {
                        if ($topDirs | Where-Object { $_.Name -like "*$t*" }) {
                            $foundOnDisk = $true
                            break
                        }
                    }
                } catch {}
            }
        }

        # 5) Fuzzy service match
        $foundService = $false
        if ($tokens.Count -gt 0 -and $allServices) {
            foreach ($t in $tokens) {
                if ($allServices | Where-Object {
                    $_.Name -like "*$t*" -or $_.DisplayName -like "*$t*"
                }) {
                    $foundService = $true
                    break
                }
            }
        }

        # 6) Fuzzy process match
        $foundProcess = $false
        if ($tokens.Count -gt 0 -and $allProcesses) {
            foreach ($t in $tokens) {
                if ($allProcesses | Where-Object {
                    $_.ProcessName -like "*$t*"
                }) {
                    $foundProcess = $true
                    break
                }
            }
        }

        # FINAL ORPHAN DECISION:
        # Only consider this an orphan if NOTHING indicates the app still exists.
        $isOrphan = -not $installExists -and `
                    -not $iconExists -and `
                    -not $uninstExists -and `
                    -not $foundOnDisk -and `
                    -not $foundService -and `
                    -not $foundProcess

        if ($isOrphan) {
            $unistResults += [PSCustomObject]@{
                RootKey          = $root
                KeyPath          = $key.PSPath
                KeyName          = $key.PSChildName
                DisplayName      = $displayName
                DisplayVersion   = $displayVersion
                Publisher        = $publisher
                InstallLocation  = $installLoc
                InstallExists    = $installExists
                DisplayIcon      = $displayIcon
                IconExists       = $iconExists
                UninstallString  = $uninstallStr
                UninstallExeOK   = $uninstExists
                FoundOnDisk      = $foundOnDisk
                FoundService     = $foundService
                FoundProcess     = $foundProcess
            }

            $del = "Remove-Item -Path '$($key.PSPath)' -Recurse -Force"
            Handle-Entry -description $displayName -deleteCommand $del -category "UninstallKeys"
        }
    }
}

$unistResults | Export-Csv -Path $unistReport -NoTypeInformation
Write-Host "    -> Fuzzy-safe orphan uninstall keys written to $unistReport"

# ============================================================
# 3. Orphan ProfileList SIDs
# ============================================================

Write-Host "[2] Auditing orphan ProfileList SIDs..."

$profKey = "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\ProfileList"
$profReport = Join-Path $logDir "ProfileList_Orphans.csv"
$profResults = @()

foreach ($sid in Get-ChildItem $profKey) {
    $img = (Get-ItemProperty $sid.PSPath).ProfileImagePath
    if ($img -and -not (Test-Path $img)) {
        $profResults += [PSCustomObject]@{
            SID   = $sid.PSChildName
            Path  = $img
        }

        $del = "Remove-Item -Path '$($sid.PSPath)' -Recurse -Force"
        Handle-Entry -description $sid.PSChildName -deleteCommand $del -category "SIDs"
    }
}

$profResults | Export-Csv -Path $profReport -NoTypeInformation
Write-Host "    -> Orphan ProfileList SIDs written."

# ============================================================
# 4. Orphan Installer\UserData SIDs
# ============================================================

Write-Host "[3] Auditing orphan Installer\\UserData SIDs..."

$instRoot = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Installer\UserData"
$instReport = Join-Path $logDir "InstallerUserData_Orphans.csv"
$instResults = @()

$validSIDs = @(
    "S-1-5-18","S-1-5-19","S-1-5-20"
)

foreach ($sid in Get-ChildItem $instRoot) {
    if ($sid.PSChildName -in $validSIDs) { continue }

    # Check if SID belongs to a real user
    if (-not (Get-LocalUser | Where-Object SID -eq $sid.PSChildName)) {
        $instResults += [PSCustomObject]@{
            SID = $sid.PSChildName
        }

        $del = "Remove-Item -Path '$($sid.PSPath)' -Recurse -Force"
        Handle-Entry -description $sid.PSChildName -deleteCommand $del -category "InstallerUserData"
    }
}

$instResults | Export-Csv -Path $instReport -NoTypeInformation
Write-Host "    -> Orphan Installer SIDs written."

# ============================================================
# 5. App Paths Audit (Missing EXEs)
# ============================================================

Write-Host "[4] Auditing App Paths..."

$appPaths = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\App Paths"
$appPathsReport = Join-Path $logDir "AppPaths_Orphans.csv"
$appPathsRes = @()

foreach ($key in Get-ChildItem $appPaths) {
    try {
        $exe = (Get-ItemProperty $key.PSPath)."(Default)"
    } catch { continue }

    if ($exe -and -not (Test-Path $exe)) {
        $appPathsRes += [PSCustomObject]@{
            Key = $key.PSPath
            Target = $exe
        }

        $del = "Remove-Item -Path '$($key.PSPath)' -Recurse -Force"
        Handle-Entry -description $exe -deleteCommand $del -category "AppPaths"
    }
}

$appPathsRes | Export-Csv -Path $appPathsReport -NoTypeInformation
Write-Host "    -> App Paths audit written."

# ============================================================
# 6. Shell Extensions Audit (Broken CLSIDs)
# ============================================================

Write-Host "[5] Auditing shell extensions..."

$shellRoots = @(
    "HKCR:\*\shellex",
    "HKCR:\Directory\shellex",
    "HKCR:\Folder\shellex"
)

$shellReport = Join-Path $logDir "ShellExtensions_Orphans.csv"
$shellRes = @()

foreach ($root in $shellRoots) {
    if (-not (Test-Path $root)) { continue }

    foreach ($sub in Get-ChildItem $root -Recurse) {
        if ($sub.PSChildName -match "^\{.+\}$") {
            $clsid = "HKCR:\CLSID\$($sub.PSChildName)"
            if (-not (Test-Path $clsid)) {
                $shellRes += [PSCustomObject]@{
                    MissingCLSID = $sub.PSChildName
                    RefPath = $sub.PSPath
                }

                $del = "Remove-Item -Path '$($sub.PSPath)' -Recurse -Force"
                Handle-Entry -description $sub.PSChildName -deleteCommand $del -category "ShellExtensions"
            }
        }
    }
}

$shellRes | Export-Csv -Path $shellReport -NoTypeInformation
Write-Host "    -> Shell extension audit written."

# ============================================================
# 7. Service Entries with Missing Binaries
# ============================================================

Write-Host "[6] Auditing services whose ImagePath is broken..."

$svcReport = Join-Path $logDir "Service_Orphans.csv"
$svcRes = @()

foreach ($svc in Get-ChildItem "HKLM:\System\CurrentControlSet\Services") {
    try {
        $img = (Get-ItemProperty $svc.PSPath).ImagePath
    } catch { continue }

    if ($img -and $img -match "\.exe") {
        $clean = $img.Trim('"')
        $exe = $clean.Split(" ")[0]

        if (-not (Test-Path $exe)) {
            $svcRes += [PSCustomObject]@{
                Service = $svc.PSChildName
                ImagePath = $img
            }

            $del = "Remove-Item -Path '$($svc.PSPath)' -Recurse -Force"
            Handle-Entry -description $svc.PSChildName -deleteCommand $del -category "Services"
        }
    }
}

$svcRes | Export-Csv -Path $svcReport -NoTypeInformation
Write-Host "    -> Service audit written."

# ============================================================
# Finish
# ============================================================

Write-Host ""
Write-Host "=== Registry Audit Complete ===" -ForegroundColor Cyan
Write-Host "Logs saved to: $logDir" -ForegroundColor Cyan

if ($mode -eq "D") {
    Write-Host "Cleanup commands saved to:" -ForegroundColor Yellow
    Write-Host "  $cleanupScript"
}
