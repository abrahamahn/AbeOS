# AbeOS-Cleanup-OldUsers.ps1
# Cleans old local users, profile folders, ProfileList SIDs, and Installer\UserData for those SIDs.
# Keeps only: abe, Administrator (+ core system accounts)

# =========================
#  CONFIG
# =========================
$dryRun = $true   # 👉 CHANGE TO $false TO ACTUALLY DELETE

$keepUsers = @('abe', 'Administrator')
# System/builtin accounts we should not touch even if you didn't list them
$systemUsers = @('DefaultAccount', 'Guest', 'WDAGUtilityAccount', 'defaultuser0')
$allKeepUsers = $keepUsers + $systemUsers

$profileRoot = 'C:\Users'
$keepProfiles = @('abe', 'Administrator', 'Public', 'Default', 'Default User', 'All Users')

Write-Host "=== AbeOS Old User Cleanup ===" -ForegroundColor Cyan
Write-Host "Dry run mode: $dryRun`n" -ForegroundColor Yellow

# Ensure admin
If (-not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole(`
    [Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Error "You must run this script as Administrator."
    return
}

# =========================
# 1) LOCAL USER ACCOUNTS
# =========================
Write-Host "Step 1: Local user accounts..." -ForegroundColor Cyan

try {
    $usersToRemove = Get-LocalUser | Where-Object {
        $allKeepUsers -notcontains $_.Name
    }

    if (-not $usersToRemove) {
        Write-Host "  No extra local users found." -ForegroundColor Green
    } else {
        Write-Host "  Users to remove:" -ForegroundColor Yellow
        $usersToRemove | ForEach-Object { Write-Host "   - $($_.Name)" }

        if (-not $dryRun) {
            foreach ($u in $usersToRemove) {
                Write-Host "  Removing local user: $($u.Name)" -ForegroundColor Red
                Remove-LocalUser -Name $u.Name -ErrorAction SilentlyContinue
            }
        }
    }
} catch {
    Write-Warning "  Could not enumerate/remove local users: $_"
}

# =========================
# 2) PROFILE FOLDERS
# =========================
Write-Host "`nStep 2: C:\Users profile folders..." -ForegroundColor Cyan

if (Test-Path $profileRoot) {
    $profilesToRemove = Get-ChildItem $profileRoot -Directory | Where-Object {
        $keepProfiles -notcontains $_.Name
    }

    if (-not $profilesToRemove) {
        Write-Host "  No extra profile folders found." -ForegroundColor Green
    } else {
        Write-Host "  Profile folders to remove:" -ForegroundColor Yellow
        $profilesToRemove | ForEach-Object { Write-Host "   - $($_.FullName)" }

        if (-not $dryRun) {
            foreach ($p in $profilesToRemove) {
                Write-Host "  Deleting folder: $($p.FullName)" -ForegroundColor Red
                Remove-Item -LiteralPath $p.FullName -Recurse -Force -ErrorAction SilentlyContinue
            }
        }
    }
} else {
    Write-Warning "  Profile root '$profileRoot' not found."
}

# =========================
# 3) PROFILELIST REGISTRY HIVES
# =========================
Write-Host "`nStep 3: ProfileList registry SIDs..." -ForegroundColor Cyan

$profileListKey = 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\ProfileList'
if (Test-Path $profileListKey) {
    $profileSids = Get-ChildItem $profileListKey

    # Build set of SIDs to keep based on keepProfiles
    $keepSidSet = @()
    foreach ($sidKey in $profileSids) {
        $profilePath = (Get-ItemProperty -Path $sidKey.PSPath -Name ProfileImagePath -ErrorAction SilentlyContinue).ProfileImagePath
        if ($profilePath) {
            $leaf = Split-Path $profilePath -Leaf
            if ($keepProfiles -contains $leaf) {
                $keepSidSet += $sidKey.PSChildName
            }
        }
    }

    $sidsToRemove = $profileSids | Where-Object {
        $keepSidSet -notcontains $_.PSChildName
    }

    if (-not $sidsToRemove) {
        Write-Host "  No extra ProfileList SIDs found." -ForegroundColor Green
    } else {
        Write-Host "  ProfileList SIDs to remove:" -ForegroundColor Yellow
        $sidsToRemove | ForEach-Object { Write-Host "   - $($_.PSChildName)" }

        if (-not $dryRun) {
            foreach ($sidKey in $sidsToRemove) {
                Write-Host "  Removing ProfileList key: $($sidKey.PSChildName)" -ForegroundColor Red
                Remove-Item -Path $sidKey.PSPath -Recurse -Force -ErrorAction SilentlyContinue
            }
        }
    }
} else {
    Write-Warning "  ProfileList key not found."
}

# =========================
# 4) INSTALLER\UserData (MSI)
# =========================
Write-Host "`nStep 4: Installer\\UserData SIDs..." -ForegroundColor Cyan

$installerRoot = 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Installer\UserData'
if (Test-Path $installerRoot) {
    $installerSidKeys = Get-ChildItem $installerRoot

    # Keep system SIDs (+ any SIDs mapped to keepProfiles)
    $systemSids = @('S-1-5-18', 'S-1-5-19', 'S-1-5-20') # LocalSystem, LocalService, NetworkService

    $keepInstallerSids = New-Object System.Collections.Generic.HashSet[string]
    $systemSids | ForEach-Object { [void]$keepInstallerSids.Add($_) }
    $keepSidSet | ForEach-Object { [void]$keepInstallerSids.Add($_) }

    $installerSidsToRemove = $installerSidKeys | Where-Object {
        -not $keepInstallerSids.Contains($_.PSChildName)
    }

    if (-not $installerSidsToRemove) {
        Write-Host "  No extra Installer\\UserData SIDs found." -ForegroundColor Green
    } else {
        Write-Host "  Installer\\UserData SIDs to remove:" -ForegroundColor Yellow
        $installerSidsToRemove | ForEach-Object { Write-Host "   - $($_.PSChildName)" }

        if (-not $dryRun) {
            foreach ($sidKey in $installerSidsToRemove) {
                Write-Host "  Deleting Installer\\UserData key: $($sidKey.PSChildName)" -ForegroundColor Red
                Remove-Item -Path $sidKey.PSPath -Recurse -Force -ErrorAction SilentlyContinue
            }
        }
    }
} else {
    Write-Warning "  Installer\\UserData key not found."
}

Write-Host "`n=== Done. Dry run: $dryRun ===" -ForegroundColor Cyan
Write-Host "If this looked correct, edit the script and set \$dryRun = \$false, then run again." -ForegroundColor Yellow
