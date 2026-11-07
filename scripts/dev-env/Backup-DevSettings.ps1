# Backup-DevSettings.ps1 - Export and restore VS Code and IDE settings.
# Usage: .\Backup-DevSettings.ps1 -Action <Backup|Restore>
param(
    [Parameter(Position = 0)]
    [ValidateSet("Backup", "Restore")]
    [string]$Action = "Backup"
)

$ErrorActionPreference = "Stop"

$BackupRoot = "C:\AbeOS\backups\dev-settings"

# ---------------------------------------------------------------------------
# VS Code paths
# ---------------------------------------------------------------------------

$VsCodeUserDir = "$env:APPDATA\Code\User"
$VsCodeSettings = "$VsCodeUserDir\settings.json"
$VsCodeKeybindings = "$VsCodeUserDir\keybindings.json"
$VsCodeSnippetsDir = "$VsCodeUserDir\snippets"

# ---------------------------------------------------------------------------
# AntiGravity IDE - search common install locations
# ---------------------------------------------------------------------------

function Find-AntiGravityConfig {
    $searchPaths = @(
        "$env:APPDATA\AntiGravity",
        "$env:APPDATA\AntiGravity IDE",
        "$env:LOCALAPPDATA\AntiGravity",
        "$env:LOCALAPPDATA\AntiGravity IDE",
        "$env:USERPROFILE\.antigravity",
        "$env:USERPROFILE\AntiGravity"
    )
    foreach ($p in $searchPaths) {
        if (Test-Path $p) { return $p }
    }

    # Search Program Files for clues
    $programDirs = @("$env:ProgramFiles", "${env:ProgramFiles(x86)}")
    foreach ($base in $programDirs) {
        $match = Get-ChildItem -Path $base -Directory -Filter "*AntiGravity*" -ErrorAction SilentlyContinue | Select-Object -First 1
        if ($match) {
            # Check for a config subfolder
            $configSub = Join-Path $match.FullName "config"
            if (Test-Path $configSub) { return $configSub }
            return $match.FullName
        }
    }
    return $null
}

# ---------------------------------------------------------------------------
# Backup
# ---------------------------------------------------------------------------

function Invoke-Backup {
    $timestamp = Get-Date -Format "yyyy-MM-dd_HHmmss"
    $backupDir = Join-Path $BackupRoot $timestamp

    Write-Host "=== AbeOS Dev Settings Backup ===" -ForegroundColor Cyan
    Write-Host "Destination: $backupDir" -ForegroundColor DarkGray
    Write-Host ""

    New-Item -ItemType Directory -Path $backupDir -Force | Out-Null

    # --- VS Code ---
    $vsDir = Join-Path $backupDir "vscode"
    New-Item -ItemType Directory -Path $vsDir -Force | Out-Null

    Write-Host "[VS Code]" -ForegroundColor Yellow

    # Extensions list
    $codeCmd = Get-Command code -ErrorAction SilentlyContinue
    if ($codeCmd) {
        $extensions = code --list-extensions 2>&1
        $extensions | Out-File -FilePath "$vsDir\extensions.txt" -Encoding UTF8
        $extCount = ($extensions | Measure-Object -Line).Lines
        Write-Host "  [OK] Extensions list: $extCount extensions" -ForegroundColor Green
    } else {
        Write-Host "  [SKIP] VS Code CLI not found" -ForegroundColor DarkGray
    }

    # settings.json
    if (Test-Path $VsCodeSettings) {
        Copy-Item -Path $VsCodeSettings -Destination "$vsDir\settings.json" -Force
        Write-Host "  [OK] settings.json" -ForegroundColor Green
    } else {
        Write-Host "  [--] settings.json not found" -ForegroundColor DarkGray
    }

    # keybindings.json
    if (Test-Path $VsCodeKeybindings) {
        Copy-Item -Path $VsCodeKeybindings -Destination "$vsDir\keybindings.json" -Force
        Write-Host "  [OK] keybindings.json" -ForegroundColor Green
    } else {
        Write-Host "  [--] keybindings.json not found" -ForegroundColor DarkGray
    }

    # Snippets directory
    if (Test-Path $VsCodeSnippetsDir) {
        $snipDest = Join-Path $vsDir "snippets"
        Copy-Item -Path $VsCodeSnippetsDir -Destination $snipDest -Recurse -Force
        $snipCount = (Get-ChildItem -Path $VsCodeSnippetsDir -File).Count
        Write-Host "  [OK] Snippets: $snipCount files" -ForegroundColor Green
    } else {
        Write-Host "  [--] Snippets directory not found" -ForegroundColor DarkGray
    }

    # --- AntiGravity IDE ---
    Write-Host ""
    Write-Host "[AntiGravity IDE]" -ForegroundColor Yellow

    $agPath = Find-AntiGravityConfig
    if ($agPath) {
        $agDir = Join-Path $backupDir "antigravity"
        Copy-Item -Path $agPath -Destination $agDir -Recurse -Force
        $agFileCount = (Get-ChildItem -Path $agPath -Recurse -File).Count
        Write-Host "  [OK] Backed up $agFileCount files from $agPath" -ForegroundColor Green
    } else {
        Write-Host "  [--] AntiGravity IDE config not found in standard locations" -ForegroundColor DarkGray
        Write-Host "       Searched: AppData, LocalAppData, UserProfile, Program Files" -ForegroundColor DarkGray
    }

    # --- Write a latest pointer ---
    $latestFile = Join-Path $BackupRoot "LATEST"
    $timestamp | Out-File -FilePath $latestFile -Encoding UTF8 -NoNewline

    Write-Host ""
    Write-Host "=== Backup Complete ===" -ForegroundColor Cyan
    Write-Host "Saved to: $backupDir" -ForegroundColor Green
    Write-Host ""
    Write-Host "Done." -ForegroundColor Cyan
}

# ---------------------------------------------------------------------------
# Restore
# ---------------------------------------------------------------------------

function Invoke-Restore {
    Write-Host "=== AbeOS Dev Settings Restore ===" -ForegroundColor Cyan

    # Find latest backup
    $latestFile = Join-Path $BackupRoot "LATEST"
    if (-not (Test-Path $latestFile)) {
        # Fallback: find most recent directory
        $dirs = Get-ChildItem -Path $BackupRoot -Directory -ErrorAction SilentlyContinue | Sort-Object Name -Descending
        if ($dirs.Count -eq 0) {
            Write-Host "[ERROR] No backups found in $BackupRoot" -ForegroundColor Red
            exit 1
        }
        $latestDir = $dirs[0].FullName
    } else {
        $latestName = (Get-Content -Path $latestFile -Raw).Trim()
        $latestDir = Join-Path $BackupRoot $latestName
    }

    if (-not (Test-Path $latestDir)) {
        Write-Host "[ERROR] Backup directory not found: $latestDir" -ForegroundColor Red
        exit 1
    }

    Write-Host "Restoring from: $latestDir" -ForegroundColor DarkGray
    Write-Host ""

    # --- VS Code ---
    $vsDir = Join-Path $latestDir "vscode"

    Write-Host "[VS Code]" -ForegroundColor Yellow

    # Restore extensions
    $extFile = Join-Path $vsDir "extensions.txt"
    if (Test-Path $extFile) {
        $codeCmd = Get-Command code -ErrorAction SilentlyContinue
        if ($codeCmd) {
            $extensions = Get-Content -Path $extFile | Where-Object { $_.Trim() }
            $total = $extensions.Count
            $current = 0
            foreach ($ext in $extensions) {
                $current++
                Write-Host "  [$current/$total] Installing: $ext" -ForegroundColor DarkGray
                code --install-extension $ext --force 2>&1 | Out-Null
            }
            Write-Host "  [OK] Restored $total extensions" -ForegroundColor Green
        } else {
            Write-Host "  [SKIP] VS Code CLI not found - extensions not restored" -ForegroundColor Yellow
        }
    }

    # Restore settings.json
    $settingsBackup = Join-Path $vsDir "settings.json"
    if (Test-Path $settingsBackup) {
        New-Item -ItemType Directory -Path $VsCodeUserDir -Force | Out-Null
        Copy-Item -Path $settingsBackup -Destination $VsCodeSettings -Force
        Write-Host "  [OK] settings.json restored" -ForegroundColor Green
    }

    # Restore keybindings.json
    $keybindingsBackup = Join-Path $vsDir "keybindings.json"
    if (Test-Path $keybindingsBackup) {
        Copy-Item -Path $keybindingsBackup -Destination $VsCodeKeybindings -Force
        Write-Host "  [OK] keybindings.json restored" -ForegroundColor Green
    }

    # Restore snippets
    $snipBackup = Join-Path $vsDir "snippets"
    if (Test-Path $snipBackup) {
        Copy-Item -Path $snipBackup -Destination $VsCodeSnippetsDir -Recurse -Force
        Write-Host "  [OK] Snippets restored" -ForegroundColor Green
    }

    # --- AntiGravity IDE ---
    Write-Host ""
    Write-Host "[AntiGravity IDE]" -ForegroundColor Yellow

    $agBackup = Join-Path $latestDir "antigravity"
    if (Test-Path $agBackup) {
        $agPath = Find-AntiGravityConfig
        if ($agPath) {
            Copy-Item -Path "$agBackup\*" -Destination $agPath -Recurse -Force
            Write-Host "  [OK] Restored to $agPath" -ForegroundColor Green
        } else {
            Write-Host "  [WARN] AntiGravity IDE config location not found - files saved at:" -ForegroundColor Yellow
            Write-Host "         $agBackup" -ForegroundColor DarkGray
        }
    } else {
        Write-Host "  [--] No AntiGravity backup found" -ForegroundColor DarkGray
    }

    Write-Host ""
    Write-Host "=== Restore Complete ===" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "Done." -ForegroundColor Cyan
}

# ---------------------------------------------------------------------------
# Entry point
# ---------------------------------------------------------------------------

# Ensure backup root exists
New-Item -ItemType Directory -Path $BackupRoot -Force | Out-Null

switch ($Action) {
    "Backup"  { Invoke-Backup }
    "Restore" { Invoke-Restore }
}
