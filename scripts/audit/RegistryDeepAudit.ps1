# RegistryDeepAudit.ps1 - Audit critical registry settings for AbeOS compliance.
# Usage: .\RegistryDeepAudit.ps1

$ErrorActionPreference = "SilentlyContinue"

Write-Host "=== AbeOS Registry Deep Audit ===" -ForegroundColor Cyan
Write-Host "Generated: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" -ForegroundColor DarkGray
Write-Host ""

$issueCount = 0

function Check-Registry {
    param(
        [string]$Path,
        [string]$Name,
        $ExpectedValue,
        [string]$Label,
        [string]$Category = ""
    )

    $current = Get-ItemProperty -Path $Path -Name $Name -ErrorAction SilentlyContinue
    $currentVal = $(if ($current) { $current.$Name } else { "(not set)" })

    if ($currentVal -eq $ExpectedValue) {
        Write-Host "  [OK] ${Label} = $currentVal" -ForegroundColor Green
        return $false
    } else {
        Write-Host "  [!!] ${Label} = $currentVal (expected: $ExpectedValue)" -ForegroundColor Red
        return $true
    }
}

# --- Theme & Appearance ---
Write-Host "[THEME & APPEARANCE]" -ForegroundColor Yellow
$personalize = "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Themes\Personalize"
$dwm = "HKCU:\SOFTWARE\Microsoft\Windows\DWM"

$r = Check-Registry -Path $personalize -Name "AppsUseLightTheme" -ExpectedValue 0 -Label "Apps dark mode"
if ($r) { $issueCount++ }

$r = Check-Registry -Path $personalize -Name "SystemUsesLightTheme" -ExpectedValue 0 -Label "System dark mode"
if ($r) { $issueCount++ }

$r = Check-Registry -Path $dwm -Name "ColorPrevalence" -ExpectedValue 1 -Label "Window colorization"
if ($r) { $issueCount++ }

$r = Check-Registry -Path $personalize -Name "ColorPrevalence" -ExpectedValue 1 -Label "Taskbar colorization"
if ($r) { $issueCount++ }

# --- Taskbar ---
Write-Host ""
Write-Host "[TASKBAR]" -ForegroundColor Yellow
$explorer = "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced"
$search = "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Search"

$r = Check-Registry -Path $search -Name "SearchboxTaskbarMode" -ExpectedValue 0 -Label "Search hidden"
if ($r) { $issueCount++ }

$r = Check-Registry -Path $explorer -Name "ShowCopilotButton" -ExpectedValue 0 -Label "Copilot hidden"
if ($r) { $issueCount++ }

$r = Check-Registry -Path $explorer -Name "ShowTaskViewButton" -ExpectedValue 0 -Label "Task View hidden"
if ($r) { $issueCount++ }

$r = Check-Registry -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced\TaskbarDa" -Name "VisibilityLevel" -ExpectedValue 0 -Label "Widgets hidden"
if ($r) { $issueCount++ }

# --- Game Bar ---
Write-Host ""
Write-Host "[GAME BAR]" -ForegroundColor Yellow
$r = Check-Registry -Path "HKCU:\SOFTWARE\Microsoft\GameBar" -Name "UseNexusForGameBarEnabled" -ExpectedValue 0 -Label "Game Bar disabled"
if ($r) { $issueCount++ }

# --- Boot ---
Write-Host ""
Write-Host "[BOOT CONFIGURATION]" -ForegroundColor Yellow
$r = Check-Registry -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" -Name "VerboseStatus" -ExpectedValue 1 -Label "Verbose boot"
if ($r) { $issueCount++ }

# --- Power & Performance ---
Write-Host ""
Write-Host "[POWER & PERFORMANCE]" -ForegroundColor Yellow

$r = Check-Registry -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Power" -Name "HiberbootEnabled" -ExpectedValue 0 -Label "Fast Startup disabled"
if ($r) { $issueCount++ }

$sysMain = (Get-Service -Name "SysMain" -ErrorAction SilentlyContinue).StartType
if ($sysMain -eq "Disabled") {
    Write-Host "  [OK] SysMain (Superfetch) = Disabled" -ForegroundColor Green
} else {
    Write-Host "  [!!] SysMain (Superfetch) = $sysMain (expected: Disabled)" -ForegroundColor Red
    $issueCount++
}

# --- Privacy & Security ---
Write-Host ""
Write-Host "[PRIVACY & SECURITY]" -ForegroundColor Yellow

$smartscreen = Get-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer" -Name "SmartScreenEnabled" -ErrorAction SilentlyContinue
if ($smartscreen -and $smartscreen.SmartScreenEnabled -ne "Off") {
    Write-Host "  [OK] SmartScreen = $($smartscreen.SmartScreenEnabled)" -ForegroundColor Green
} else {
    Write-Host "  [!!] SmartScreen = Off (should be enabled)" -ForegroundColor Red
    $issueCount++
}

# SafeSearch policies
$googleSafe = Get-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Google\Chrome" -Name "ForceGoogleSafeSearch" -ErrorAction SilentlyContinue
if ($googleSafe -and $googleSafe.ForceGoogleSafeSearch -eq 1) {
    Write-Host "  [OK] Google SafeSearch = Enforced" -ForegroundColor Green
} else {
    Write-Host "  [!!] Google SafeSearch = Not enforced" -ForegroundColor Yellow
    $issueCount++
}

$bingSafe = Get-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Edge" -Name "ForceBingSafeSearch" -ErrorAction SilentlyContinue
if ($bingSafe -and $bingSafe.ForceBingSafeSearch -ge 1) {
    Write-Host "  [OK] Bing SafeSearch = Enforced" -ForegroundColor Green
} else {
    Write-Host "  [!!] Bing SafeSearch = Not enforced" -ForegroundColor Yellow
    $issueCount++
}

# --- OEM Branding ---
Write-Host ""
Write-Host "[OEM BRANDING]" -ForegroundColor Yellow
$oem = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\OEMInformation"
$manufacturer = (Get-ItemProperty -Path $oem -Name "Manufacturer" -ErrorAction SilentlyContinue).Manufacturer
$model = (Get-ItemProperty -Path $oem -Name "Model" -ErrorAction SilentlyContinue).Model
$mfgDisplay = $(if ($manufacturer) { $manufacturer } else { "(not set)" })
$modelDisplay = $(if ($model) { $model } else { "(not set)" })
Write-Host "  Manufacturer: $mfgDisplay" -ForegroundColor White
Write-Host "  Model: $modelDisplay" -ForegroundColor White

# --- Explorer Settings ---
Write-Host ""
Write-Host "[EXPLORER]" -ForegroundColor Yellow
$r = Check-Registry -Path $explorer -Name "HideFileExt" -ExpectedValue 0 -Label "Show file extensions"
if ($r) { $issueCount++ }

$r = Check-Registry -Path $explorer -Name "Hidden" -ExpectedValue 1 -Label "Show hidden files"
if ($r) { $issueCount++ }

# --- User Account Check ---
Write-Host ""
Write-Host "[USER ACCOUNTS]" -ForegroundColor Yellow
$users = Get-LocalUser | Where-Object { $_.Enabled }
$suspiciousUsers = $users | Where-Object { $_.Name -match "^(temp|newadmin|default|test)" }
if ($suspiciousUsers) {
    foreach ($u in $suspiciousUsers) {
        Write-Host "  [!!] Suspicious active account: $($u.Name)" -ForegroundColor Red
        $issueCount++
    }
} else {
    $userNames = ($users | ForEach-Object { $_.Name }) -join ", "
    Write-Host "  [OK] Active accounts: $userNames" -ForegroundColor Green
}

# --- Summary ---
Write-Host ""
Write-Host "=== Summary ===" -ForegroundColor Cyan
if ($issueCount -eq 0) {
    Write-Host "  Zero issues - Registry is AbeOS compliant." -ForegroundColor Green
} else {
    Write-Host "  $issueCount issue(s) found. Run Apply-AbeOS-Theme.ps1 to fix theme settings." -ForegroundColor Yellow
}
Write-Host ""
Write-Host "Done." -ForegroundColor Cyan
