# Apply-AbeOS-Theme.ps1 - Verify and apply AbeOS Cyberpunk/Neon Cyan theme settings.
# Only changes values that differ from the desired state.
# Usage: .\Apply-AbeOS-Theme.ps1 [-SkipTerminal] [-SkipEditors] [-SkipChrome] [-DryRun]
param(
    [switch]$SkipTerminal,
    [switch]$SkipEditors,
    [switch]$SkipChrome,
    [switch]$DryRun
)

$ErrorActionPreference = "SilentlyContinue"

$AbeOSRoot = "C:\AbeOS"

Write-Host "=== AbeOS Cyberpunk Theme ===" -ForegroundColor Cyan
if ($DryRun) { Write-Host "[DRY RUN] No changes will be made." -ForegroundColor Yellow }
Write-Host ""

$changesCount = 0

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

function Set-RegistryIfDifferent {
    param(
        [string]$Path,
        [string]$Name,
        $DesiredValue,
        [string]$Type = "DWord",
        [string]$Label
    )

    $current = Get-ItemProperty -Path $Path -Name $Name -ErrorAction SilentlyContinue
    $currentVal = $(if ($current) { $current.$Name } else { $null })

    # For DWord values, compare lower 32 bits to handle signed/unsigned mismatch.
    $isMatch = $false
    if ($null -eq $currentVal) {
        $isMatch = $false
    } elseif ($Type -eq "DWord") {
        $isMatch = (([int64]$currentVal -band 0xFFFFFFFF) -eq ([int64]$DesiredValue -band 0xFFFFFFFF))
    } else {
        $isMatch = ($currentVal -eq $DesiredValue)
    }

    if ($isMatch) {
        Write-Host "  [OK] ${Label}" -ForegroundColor Green
        return $false
    }

    if ($DryRun) {
        Write-Host "  [WOULD SET] ${Label}: $currentVal -> $DesiredValue" -ForegroundColor Yellow
    } else {
        if (-not (Test-Path $Path)) {
            New-Item -Path $Path -Force | Out-Null
        }
        Set-ItemProperty -Path $Path -Name $Name -Value $DesiredValue -Type $Type -ErrorAction SilentlyContinue
        Write-Host "  [SET] ${Label}: $currentVal -> $DesiredValue" -ForegroundColor Green
    }
    return $true
}

# Compare two files by SHA-256 hash. Copy canonical over target when they differ.
function Sync-ConfigFile {
    param(
        [string]$CanonicalPath,
        [string]$TargetPath,
        [string]$Label
    )

    if (-not (Test-Path $CanonicalPath)) {
        Write-Host "  [ERR] Canonical not found: $CanonicalPath" -ForegroundColor Red
        return $false
    }

    if (-not (Test-Path $TargetPath)) {
        if ($DryRun) {
            Write-Host "  [WOULD CREATE] ${Label}" -ForegroundColor Yellow
        } else {
            $dir = Split-Path $TargetPath -Parent
            if (-not (Test-Path $dir)) { New-Item -Path $dir -ItemType Directory -Force | Out-Null }
            Copy-Item -Path $CanonicalPath -Destination $TargetPath -Force
            Write-Host "  [CREATED] ${Label}" -ForegroundColor Green
        }
        return $true
    }

    $canonicalHash = (Get-FileHash $CanonicalPath -Algorithm SHA256).Hash
    $targetHash = (Get-FileHash $TargetPath -Algorithm SHA256).Hash

    if ($canonicalHash -eq $targetHash) {
        Write-Host "  [OK] ${Label}" -ForegroundColor Green
        return $false
    }

    if ($DryRun) {
        Write-Host "  [WOULD SYNC] ${Label} (files differ)" -ForegroundColor Yellow
    } else {
        Copy-Item -Path $CanonicalPath -Destination $TargetPath -Force
        Write-Host "  [SYNCED] ${Label}" -ForegroundColor Green
    }
    return $true
}

# ---------------------------------------------------------------------------
# DARK MODE & TRANSPARENCY
# ---------------------------------------------------------------------------
Write-Host "[DARK MODE]" -ForegroundColor Yellow
$personalize = "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Themes\Personalize"

$r = Set-RegistryIfDifferent -Path $personalize -Name "AppsUseLightTheme" -DesiredValue 0 -Label "Apps dark mode"
if ($r) { $changesCount++ }

$r = Set-RegistryIfDifferent -Path $personalize -Name "SystemUsesLightTheme" -DesiredValue 0 -Label "System dark mode"
if ($r) { $changesCount++ }

$r = Set-RegistryIfDifferent -Path $personalize -Name "EnableTransparency" -DesiredValue 1 -Label "Transparency effects"
if ($r) { $changesCount++ }

# ---------------------------------------------------------------------------
# DWM WINDOW CHROME
# ---------------------------------------------------------------------------
Write-Host ""
Write-Host "[DWM]" -ForegroundColor Yellow
$dwm = "HKCU:\SOFTWARE\Microsoft\Windows\DWM"

# No colored title bars - use default dark chrome.
$r = Set-RegistryIfDifferent -Path $dwm -Name "ColorPrevalence" -DesiredValue 0 -Label "Colored title bars (off)"
if ($r) { $changesCount++ }

$r = Set-RegistryIfDifferent -Path $personalize -Name "ColorPrevalence" -DesiredValue 0 -Label "Taskbar accent (off)"
if ($r) { $changesCount++ }

$r = Set-RegistryIfDifferent -Path $dwm -Name "EnableWindowColorization" -DesiredValue 1 -Label "Window border colorization"
if ($r) { $changesCount++ }

# AccentColor / AccentColorInactive use ABGR DWord format (signed Int32).
# Both set to #1A1A1A (near-black) for minimal, no-accent borders.
# #1A1A1A -> ABGR 0xFF1A1A1A -> signed -14540774
$r = Set-RegistryIfDifferent -Path $dwm -Name "AccentColor" -DesiredValue (-14540774) -Label "Active border (near-black #1A1A1A)"
if ($r) { $changesCount++ }

$r = Set-RegistryIfDifferent -Path $dwm -Name "AccentColorInactive" -DesiredValue (-14540774) -Label "Inactive border (near-black #1A1A1A)"
if ($r) { $changesCount++ }

# ColorizationColor: purple accent tint for DWM chrome.
# #B146C2 with ~77% opacity -> 0xC4B146C2 -> signed -995014974
$r = Set-RegistryIfDifferent -Path $dwm -Name "ColorizationColor" -DesiredValue (-995014974) -Label "Colorization tint (purple #B146C2)"
if ($r) { $changesCount++ }

$r = Set-RegistryIfDifferent -Path $dwm -Name "ColorizationAfterglow" -DesiredValue (-995014974) -Label "Colorization afterglow (purple #B146C2)"
if ($r) { $changesCount++ }

# ---------------------------------------------------------------------------
# SYSTEM ACCENT PALETTE
# ---------------------------------------------------------------------------
Write-Host ""
Write-Host "[ACCENT PALETTE]" -ForegroundColor Yellow
$accentPath = "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Accent"

# 8 colors x 4 bytes (R,G,B,padding) = 32 bytes, lightest to darkest purple.
$purplePalette = [byte[]](
    0xF1,0xBB,0xF4,0x00,
    0xD8,0x8D,0xE1,0x00,
    0xBD,0x5B,0xCB,0x00,
    0xB1,0x46,0xC2,0x00,
    0x9E,0x3A,0xB0,0x00,
    0x6F,0x23,0x82,0x00,
    0x46,0x0D,0x5A,0x00,
    0xFF,0x8C,0x00,0x00
)

$currentPalette = Get-ItemProperty -Path $accentPath -Name "AccentPalette" -ErrorAction SilentlyContinue
$needsUpdate = $true
if ($currentPalette) {
    $currentBytes = $currentPalette.AccentPalette
    if ($currentBytes -and $currentBytes.Length -eq 32) {
        $needsUpdate = (($currentBytes -join ',') -ne ($purplePalette -join ','))
    }
}

if (-not $needsUpdate) {
    Write-Host "  [OK] AccentPalette = purple shades" -ForegroundColor Green
} elseif ($DryRun) {
    Write-Host "  [WOULD SET] AccentPalette -> purple shades (8 colors)" -ForegroundColor Yellow
} else {
    if (-not (Test-Path $accentPath)) {
        New-Item -Path $accentPath -Force | Out-Null
    }
    Set-ItemProperty -Path $accentPath -Name "AccentPalette" -Value $purplePalette -Type Binary -ErrorAction SilentlyContinue
    Write-Host "  [SET] AccentPalette -> purple shades (8 colors)" -ForegroundColor Green
    $changesCount++
}

# AccentColorMenu: accent used in Start menu and WinUI controls (ABGR format).
# #B146C2 (purple) -> ABGR 0xFFC246B1 -> signed -4045135
$r = Set-RegistryIfDifferent -Path $accentPath -Name "AccentColorMenu" -DesiredValue (-4045135) -Label "Accent menu color (purple #B146C2)"
if ($r) { $changesCount++ }

# StartColorMenu: Start menu accent shade (ABGR format).
# #9E3AB0 (darker purple) -> ABGR 0xFFB03A9E -> signed -5227874
$r = Set-RegistryIfDifferent -Path $accentPath -Name "StartColorMenu" -DesiredValue (-5227874) -Label "Start menu color (dark purple #9E3AB0)"
if ($r) { $changesCount++ }

# ---------------------------------------------------------------------------
# TASKBAR DECLUTTER
# ---------------------------------------------------------------------------
Write-Host ""
Write-Host "[TASKBAR]" -ForegroundColor Yellow
$search = "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Search"
$explorer = "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced"

$r = Set-RegistryIfDifferent -Path $search -Name "SearchboxTaskbarMode" -DesiredValue 0 -Label "Hide search"
if ($r) { $changesCount++ }

$r = Set-RegistryIfDifferent -Path $explorer -Name "ShowCopilotButton" -DesiredValue 0 -Label "Hide Copilot"
if ($r) { $changesCount++ }

$r = Set-RegistryIfDifferent -Path $explorer -Name "ShowTaskViewButton" -DesiredValue 0 -Label "Hide Task View"
if ($r) { $changesCount++ }

$r = Set-RegistryIfDifferent -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced\TaskbarDa" -Name "VisibilityLevel" -DesiredValue 0 -Label "Hide Widgets"
if ($r) { $changesCount++ }

# ---------------------------------------------------------------------------
# GAME BAR
# ---------------------------------------------------------------------------
Write-Host ""
Write-Host "[GAME BAR]" -ForegroundColor Yellow
$gameBar = "HKCU:\SOFTWARE\Microsoft\GameBar"
$r = Set-RegistryIfDifferent -Path $gameBar -Name "UseNexusForGameBarEnabled" -DesiredValue 0 -Label "Game Bar disabled"
if ($r) { $changesCount++ }

# ---------------------------------------------------------------------------
# VERBOSE BOOT
# ---------------------------------------------------------------------------
Write-Host ""
Write-Host "[BOOT]" -ForegroundColor Yellow
$bootPath = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System"
$r = Set-RegistryIfDifferent -Path $bootPath -Name "VerboseStatus" -DesiredValue 1 -Label "Verbose boot"
if ($r) { $changesCount++ }

# ---------------------------------------------------------------------------
# WINDOWS TERMINAL  (canonical copy from C:\AbeOS\configs\terminal\)
# ---------------------------------------------------------------------------
if (-not $SkipTerminal) {
    Write-Host ""
    Write-Host "[TERMINAL]" -ForegroundColor Yellow

    # Sync full Windows Terminal settings from canonical config.
    # Canonical file defines: Cyberpunk color scheme, CyberpunkDark UI theme,
    # JetBrainsMono NF, hidden scrollbar, acrylic, full keybindings, profile list.
    $wtCanonical = "$AbeOSRoot\configs\terminal\windows-terminal-settings.json"
    $wtSettingsPath = "$env:LOCALAPPDATA\Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState\settings.json"
    if (-not (Test-Path $wtSettingsPath)) {
        $wtSettingsPath = "$env:LOCALAPPDATA\Microsoft\Windows Terminal\settings.json"
    }

    if (Test-Path (Split-Path $wtSettingsPath -Parent)) {
        $r = Sync-ConfigFile -CanonicalPath $wtCanonical -TargetPath $wtSettingsPath -Label "Windows Terminal settings (Cyberpunk theme)"
        if ($r) { $changesCount++ }
    } else {
        Write-Host "  [SKIP] Windows Terminal not installed" -ForegroundColor DarkGray
    }

    # Verify Oh My Posh theme config exists (profile reads it in-place).
    Write-Host ""
    Write-Host "[OH MY POSH]" -ForegroundColor Yellow
    $ompConfig = "$AbeOSRoot\configs\terminal\abe.omp.json"
    if (Test-Path $ompConfig) {
        Write-Host "  [OK] Config present: $ompConfig" -ForegroundColor Green
    } else {
        Write-Host "  [WARN] Config missing: $ompConfig" -ForegroundColor Red
    }
} else {
    Write-Host ""
    Write-Host "[TERMINAL] Skipped" -ForegroundColor DarkGray
    Write-Host "[OH MY POSH] Skipped" -ForegroundColor DarkGray
}

# ---------------------------------------------------------------------------
# EDITORS  (canonical copy + AntiGravity sync)
# ---------------------------------------------------------------------------
if (-not $SkipEditors) {

    # --- VS Code ---
    Write-Host ""
    Write-Host "[VS CODE]" -ForegroundColor Yellow

    # Sync full VS Code settings from canonical config.
    # Canonical file defines: Synthwave '2077 theme, Neon Cyan Hacker color scheme,
    # material-icon-theme, JetBrainsMono Nerd Font, Prettier/ESLint formatters, all preferences.
    $vscodeCanonical = "$AbeOSRoot\configs\vscode\settings.json"
    $vscodeSettings = "$env:APPDATA\Code\User\settings.json"

    if (Test-Path "$env:APPDATA\Code") {
        $r = Sync-ConfigFile -CanonicalPath $vscodeCanonical -TargetPath $vscodeSettings -Label "VS Code settings.json (Synthwave '2077 / Neon Cyan Hacker)"
        if ($r) { $changesCount++ }
    } else {
        Write-Host "  [SKIP] VS Code not installed" -ForegroundColor DarkGray
    }

    # --- AntiGravity IDE ---
    # Sync full settings from same canonical config as VS Code.
    # Both editors share identical settings (Synthwave '2077 / Neon Cyan Hacker).
    Write-Host ""
    Write-Host "[ANTIGRAVITY IDE]" -ForegroundColor Yellow

    $agSettings = "$env:APPDATA\Antigravity\User\settings.json"

    if (Test-Path "$env:APPDATA\Antigravity") {
        $r = Sync-ConfigFile -CanonicalPath $vscodeCanonical -TargetPath $agSettings -Label "Antigravity settings.json (Synthwave '2077 / Neon Cyan Hacker)"
        if ($r) { $changesCount++ }
    } else {
        Write-Host "  [SKIP] Antigravity IDE not installed" -ForegroundColor DarkGray
    }
} else {
    Write-Host ""
    Write-Host "[EDITORS] Skipped" -ForegroundColor DarkGray
}

# ---------------------------------------------------------------------------
# CHROME
# ---------------------------------------------------------------------------
if (-not $SkipChrome) {
    Write-Host ""
    Write-Host "[CHROME]" -ForegroundColor Yellow
    $chromePrefs = "$env:LOCALAPPDATA\Google\Chrome\User Data\Default\Preferences"
    if (Test-Path $chromePrefs) {
        Write-Host "  [OK] Chrome profile found" -ForegroundColor Green
    } else {
        Write-Host "  [SKIP] Chrome profile not found" -ForegroundColor DarkGray
    }
} else {
    Write-Host ""
    Write-Host "[CHROME] Skipped" -ForegroundColor DarkGray
}

# ---------------------------------------------------------------------------
# SUMMARY
# ---------------------------------------------------------------------------
Write-Host ""
Write-Host "=== Summary ===" -ForegroundColor Cyan
if ($changesCount -eq 0) {
    Write-Host "  All settings already match AbeOS Cyberpunk theme. No changes needed." -ForegroundColor Green
} else {
    $verb = $(if ($DryRun) { "would be changed" } else { "applied" })
    Write-Host "  $changesCount setting(s) $verb." -ForegroundColor White
    if (-not $DryRun) {
        Write-Host "  Some changes require Explorer restart or app relaunch to take effect." -ForegroundColor DarkGray
    }
}
Write-Host ""
Write-Host "Done." -ForegroundColor Cyan
