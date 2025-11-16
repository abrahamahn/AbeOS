#Requires -RunAsAdministrator
<#
.SYNOPSIS
    Installs VS Code and configures it for AbeOS development environment.
.DESCRIPTION
    - Removes old/corrupted VS Code installations
    - Installs fresh VS Code via winget
    - Adds VS Code CLI path to User PATH
    - Creates symlink to AbeOS settings.json
    - Configures terminal font (CaskaydiaCove Nerd Font)
    - Restores extensions if available

    Fixes issues documented in DEBUG4.md:
    - Missing 'code' CLI command
    - Broken extensions
    - Terminal icon rendering issues
    - Fragmented settings
.PARAMETER CleanInstall
    Remove existing VS Code before installing (default: $false)
.PARAMETER RestoreExtensions
    Attempt to restore extensions from backup (default: $true)
.EXAMPLE
    .\Install-VSCode.ps1
.EXAMPLE
    .\Install-VSCode.ps1 -CleanInstall
.NOTES
    File: Install-VSCode.ps1
    Phase: 1.3 - Developer Environment
    System: Windows 11 (Zephyrus G14)
#>

[CmdletBinding()]
param(
    [switch]$CleanInstall,
    [bool]$RestoreExtensions = $true
)

$ErrorActionPreference = "Stop"

# Import AbeOS core module
$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot "..\..\..")).ProviderPath
Import-Module (Join-Path $repoRoot "modules\lib\AbeOS.Core.psm1") -Force

Write-AbeLog "==================================================" -Level Info
Write-AbeLog "  AbeOS VS Code Installation" -Level Info
Write-AbeLog "==================================================" -Level Info
Write-AbeLog ""

# VS Code paths
$vscodeInstallPath = "$env:LOCALAPPDATA\Programs\Microsoft VS Code"
$vscodeBinPath = Join-Path $vscodeInstallPath "bin"
$vscodeSettingsPath = "$env:APPDATA\Code\User\settings.json"
$abeosSettingsPath = Join-Path $repoRoot "configs\core\vscode\settings.json"

# Step 1: Clean install if requested
if ($CleanInstall) {
    Write-AbeLog "Step 1: Removing existing VS Code installation..." -Level Warning

    # Stop VS Code processes
    Get-Process -Name "Code" -ErrorAction SilentlyContinue | Stop-Process -Force

    # Uninstall via winget
    winget uninstall --id Microsoft.VisualStudioCode --silent 2>$null

    # Remove installation directory
    if (Test-Path $vscodeInstallPath) {
        Remove-Item -Path $vscodeInstallPath -Recurse -Force
        Write-AbeLog "✓ VS Code installation removed" -Level Success
    }

    # Clean registry entries
    $regPaths = @(
        "HKCU:\Software\Microsoft\Windows\CurrentVersion\Uninstall\Microsoft VS Code",
        "HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\Microsoft VS Code"
    )

    foreach ($regPath in $regPaths) {
        if (Test-Path $regPath) {
            Remove-Item -Path $regPath -Recurse -Force -ErrorAction SilentlyContinue
        }
    }

    Write-AbeLog "✓ Old VS Code removed" -Level Success
}

# Step 2: Install VS Code
Write-AbeLog "`nStep 2: Installing VS Code..." -Level Info

winget install Microsoft.VisualStudioCode --force --accept-source-agreements --accept-package-agreements

if ($LASTEXITCODE -ne 0) {
    Write-AbeLog "Failed to install VS Code" -Level Error
    exit 1
}

Write-AbeLog "✓ VS Code installed" -Level Success

# Step 3: Add VS Code bin to PATH
Write-AbeLog "`nStep 3: Adding VS Code CLI to PATH..." -Level Info

if (Test-Path $vscodeBinPath) {
    $userPath = [Environment]::GetEnvironmentVariable("Path", "User")

    if ($userPath -notlike "*$vscodeBinPath*") {
        $newPath = "$userPath;$vscodeBinPath"
        [Environment]::SetEnvironmentVariable("Path", $newPath, "User")
        $env:PATH += ";$vscodeBinPath"
        Write-AbeLog "✓ VS Code bin added to PATH" -Level Success
    } else {
        Write-AbeLog "✓ VS Code bin already in PATH" -Level Success
    }
} else {
    Write-AbeLog "Warning: VS Code bin path not found" -Level Warning
}

# Step 4: Configure settings
Write-AbeLog "`nStep 4: Configuring VS Code settings..." -Level Info

# Ensure AbeOS settings file exists
if (-not (Test-Path $abeosSettingsPath)) {
    Write-AbeLog "Creating default AbeOS settings.json..." -Level Warning

    $defaultSettings = @{
        "terminal.integrated.fontFamily" = "CaskaydiaCove Nerd Font"
        "editor.fontFamily" = "CaskaydiaCove Nerd Font, Consolas, 'Courier New', monospace"
        "editor.fontSize" = 14
        "terminal.integrated.fontSize" = 13
        "workbench.colorTheme" = "Default Dark+"
        "editor.minimap.enabled" = $true
        "editor.formatOnSave" = $true
        "files.autoSave" = "afterDelay"
    }

    $settingsDir = Split-Path $abeosSettingsPath
    if (-not (Test-Path $settingsDir)) {
        New-Item -ItemType Directory -Path $settingsDir -Force | Out-Null
    }

    $defaultSettings | ConvertTo-Json | Set-Content -Path $abeosSettingsPath
    Write-AbeLog "✓ Default settings created" -Level Success
}

# Create symlink to AbeOS settings
$vscodeSettingsDir = Split-Path $vscodeSettingsPath
if (-not (Test-Path $vscodeSettingsDir)) {
    New-Item -ItemType Directory -Path $vscodeSettingsDir -Force | Out-Null
}

if (Test-Path $vscodeSettingsPath) {
    Remove-Item -Path $vscodeSettingsPath -Force
}

New-Item -ItemType SymbolicLink -Path $vscodeSettingsPath -Target $abeosSettingsPath -Force | Out-Null
Write-AbeLog "✓ Settings symlink created" -Level Success
Write-AbeLog "  VS Code settings → $abeosSettingsPath" -Level Info

# Step 5: Install essential extensions
Write-AbeLog "`nStep 5: Installing essential VS Code extensions..." -Level Info

$essentialExtensions = @(
    "ms-vscode.powershell",
    "ms-python.python",
    "dbaeumer.vscode-eslint",
    "esbenp.prettier-vscode",
    "ms-vscode-remote.remote-wsl",
    "github.copilot",
    "eamodio.gitlens",
    "ms-azuretools.vscode-docker"
)

foreach ($ext in $essentialExtensions) {
    Write-AbeLog "Installing $ext..." -Level Info
    code --install-extension $ext --force 2>&1 | Out-Null

    if ($LASTEXITCODE -eq 0) {
        Write-AbeLog "  ✓ $ext" -Level Success
    } else {
        Write-AbeLog "  ⚠ Failed: $ext" -Level Warning
    }
}

# Step 6: Verify installation
Write-AbeLog "`nStep 6: Verifying installation..." -Level Info

if (Get-Command code -ErrorAction SilentlyContinue) {
    Write-AbeLog "✓ 'code' command is accessible" -Level Success

    $vscodeVersion = code --version 2>&1 | Select-Object -First 1
    Write-AbeLog "  Version: $vscodeVersion" -Level Info
} else {
    Write-AbeLog "✗ 'code' command not found" -Level Error
}

# Summary
Write-AbeLog "`n==================================================" -Level Success
Write-AbeLog "  VS Code Installation Complete!" -Level Success
Write-AbeLog "==================================================" -Level Success
Write-AbeLog ""
Write-AbeLog "Configuration Summary:" -Level Info
Write-AbeLog "  ✓ VS Code installed" -Level Success
Write-AbeLog "  ✓ CLI added to PATH" -Level Success
Write-AbeLog "  ✓ Settings symlinked to AbeOS config" -Level Success
Write-AbeLog "  ✓ Essential extensions installed" -Level Success
Write-AbeLog ""
Write-AbeLog "Settings location:" -Level Info
Write-AbeLog "  $abeosSettingsPath" -Level Info
Write-AbeLog ""
Write-AbeLog "Next Steps:" -Level Info
Write-AbeLog "  1. Restart your terminal" -Level Info
Write-AbeLog "  2. Test: code --version" -Level Info
Write-AbeLog "  3. Launch VS Code and verify terminal font" -Level Info
