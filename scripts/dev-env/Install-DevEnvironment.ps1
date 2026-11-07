# Install-DevEnvironment.ps1 - Detect and install Windows dev tools by category.
# Usage: .\Install-DevEnvironment.ps1 -Category <WebDev|VSTDev|MLDev|AITools|All>
param(
    [Parameter(Position = 0)]
    [ValidateSet("WebDev", "VSTDev", "MLDev", "AITools", "All")]
    [string]$Category = "All"
)

$ErrorActionPreference = "SilentlyContinue"

# ---------------------------------------------------------------------------
# Tool definitions: Name, WingetId (or empty), CheckCmd, CheckArgs, InstallType
# InstallType: winget | npm | pip | manual
# WslInstall: if true, also install in WSL after Windows install
# ---------------------------------------------------------------------------

$WebDevTools = @(
    @{ Name = "Node.js";       WingetId = "OpenJS.NodeJS.LTS";           CheckCmd = "node";       CheckArgs = "--version" }
    @{ Name = "pnpm";          WingetId = "pnpm.pnpm";                   CheckCmd = "pnpm";       CheckArgs = "--version" }
    @{ Name = "Bun";           WingetId = "Oven-sh.Bun";                 CheckCmd = "bun";        CheckArgs = "--version" }
    @{ Name = "Git";           WingetId = "Git.Git";                      CheckCmd = "git";        CheckArgs = "--version" }
    @{ Name = "Python";        WingetId = "Python.Python.3.12";           CheckCmd = "python";     CheckArgs = "--version" }
    @{ Name = "Docker";        WingetId = "Docker.DockerDesktop";         CheckCmd = "docker";     CheckArgs = "--version" }
    @{ Name = "Rust";          WingetId = "Rustlang.Rustup";              CheckCmd = "rustc";      CheckArgs = "--version" }
    @{ Name = "Go";            WingetId = "GoLang.Go";                    CheckCmd = "go";         CheckArgs = "version" }
    @{ Name = "Java JDK";      WingetId = "EclipseAdoptium.Temurin.21.JDK"; CheckCmd = "java";    CheckArgs = "--version" }
    @{ Name = ".NET SDK";      WingetId = "Microsoft.DotNet.SDK.8";       CheckCmd = "dotnet";     CheckArgs = "--version" }
    @{ Name = "VS Code";       WingetId = "Microsoft.VisualStudioCode";   CheckCmd = "code";       CheckArgs = "--version" }
    @{ Name = "TypeScript";    WingetId = ""; CheckCmd = "tsc"; CheckArgs = "--version"; InstallType = "npm"; NpmPkg = "typescript" }
)

$VSTDevTools = @(
    @{ Name = "VS Build Tools"; WingetId = "Microsoft.VisualStudio.2022.BuildTools"; CheckCmd = "cl"; CheckArgs = ""; Override = "--add Microsoft.VisualStudio.Workload.VCTools --passive --wait" }
    @{ Name = "CMake";          WingetId = "Kitware.CMake";                CheckCmd = "cmake";      CheckArgs = "--version" }
    @{ Name = "JUCE";           WingetId = "JUCE.JUCE";                   CheckCmd = ""; CheckArgs = ""; ManualCheck = "$env:ProgramFiles\JUCE" }
    @{ Name = "Rust";           WingetId = "Rustlang.Rustup";             CheckCmd = "rustc";      CheckArgs = "--version" }
    @{ Name = "Git";            WingetId = "Git.Git";                      CheckCmd = "git";        CheckArgs = "--version" }
    @{ Name = "Python";         WingetId = "Python.Python.3.12";           CheckCmd = "python";     CheckArgs = "--version" }
    @{ Name = "VS Code";        WingetId = "Microsoft.VisualStudioCode";   CheckCmd = "code";       CheckArgs = "--version" }
)

$MLDevTools = @(
    @{ Name = "Python";        WingetId = "Python.Python.3.12";           CheckCmd = "python";     CheckArgs = "--version" }
    @{ Name = "Miniconda";     WingetId = "Anaconda.Miniconda3";          CheckCmd = "conda";      CheckArgs = "--version" }
    @{ Name = "CUDA Toolkit";  WingetId = "Nvidia.CUDA";                  CheckCmd = "nvcc";       CheckArgs = "--version" }
    @{ Name = "Git";           WingetId = "Git.Git";                      CheckCmd = "git";        CheckArgs = "--version" }
    @{ Name = "VS Code";       WingetId = "Microsoft.VisualStudioCode";   CheckCmd = "code";       CheckArgs = "--version" }
    @{ Name = "Jupyter";       WingetId = ""; CheckCmd = "jupyter"; CheckArgs = "--version"; InstallType = "pip"; PipPkg = "jupyterlab" }
)

$AIToolsTools = @(
    @{ Name = "GitHub CLI";    WingetId = "GitHub.cli";                   CheckCmd = "gh";         CheckArgs = "--version" }
    @{ Name = "Claude CLI";    WingetId = ""; CheckCmd = "claude"; CheckArgs = "--version"; InstallType = "npm"; NpmPkg = "@anthropic-ai/claude-code"; WslInstall = $true }
    @{ Name = "Codex CLI";     WingetId = ""; CheckCmd = "codex"; CheckArgs = "--version"; InstallType = "npm"; NpmPkg = "@openai/codex"; WslInstall = $true }
    @{ Name = "Gemini CLI";    WingetId = ""; CheckCmd = "gemini"; CheckArgs = "--version"; InstallType = "npm"; NpmPkg = "@anthropic-ai/gemini-cli"; WslInstall = $true }
    @{ Name = "Node.js";       WingetId = "OpenJS.NodeJS.LTS";           CheckCmd = "node";       CheckArgs = "--version" }
)

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

function Refresh-Path {
    $env:Path = [System.Environment]::GetEnvironmentVariable("Path", "Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path", "User")
}

function Test-Tool {
    param([hashtable]$Tool)
    try {
        # Manual directory check (for tools without CLI commands like JUCE)
        if ($Tool.ManualCheck -and (Test-Path $Tool.ManualCheck)) {
            return "installed ($(Split-Path $Tool.ManualCheck -Leaf))"
        }
        if (-not $Tool.CheckCmd) { return $null }

        $cmd = $Tool.CheckCmd
        $found = Get-Command $cmd -ErrorAction SilentlyContinue
        if (-not $found) { return $null }
        if ($Tool.CheckArgs) {
            $ver = & $cmd $Tool.CheckArgs 2>&1 | Select-Object -First 1
            return "$ver".Trim()
        }
        return "found"
    } catch {
        return $null
    }
}

function Install-Tool {
    param([hashtable]$Tool)

    $type = $(if ($Tool.InstallType) { $Tool.InstallType } else { "winget" })

    switch ($type) {
        "winget" {
            if (-not $Tool.WingetId) {
                Write-Host "    [SKIP] No winget package for $($Tool.Name)" -ForegroundColor DarkGray
                return $false
            }
            $wingetArgs = @("install", "--id", $Tool.WingetId, "--accept-source-agreements", "--accept-package-agreements", "--silent")
            if ($Tool.Override) {
                $wingetArgs += @("--override", $Tool.Override)
            }
            Write-Host "    winget install $($Tool.WingetId)" -ForegroundColor DarkGray
            $proc = Start-Process -FilePath "winget" -ArgumentList $wingetArgs -Wait -PassThru -NoNewWindow 2>&1
            Refresh-Path
            $verify = Test-Tool $Tool
            if ($verify) {
                Write-Host "    [OK] $($Tool.Name) installed: $verify" -ForegroundColor Green
                return $true
            } else {
                Write-Host "    [WARN] Installed but not on PATH yet - restart may be needed" -ForegroundColor Yellow
                return $true
            }
        }
        "npm" {
            $npmCmd = Get-Command npm -ErrorAction SilentlyContinue
            if (-not $npmCmd) {
                Write-Host "    [SKIP] npm not available - install Node.js first" -ForegroundColor Yellow
                return $false
            }
            Write-Host "    npm install -g $($Tool.NpmPkg)" -ForegroundColor DarkGray
            npm install -g $Tool.NpmPkg 2>&1 | Out-Null
            Refresh-Path
            return $true
        }
        "pip" {
            $pipCmd = Get-Command pip -ErrorAction SilentlyContinue
            if (-not $pipCmd) {
                Write-Host "    [SKIP] pip not available - install Python first" -ForegroundColor Yellow
                return $false
            }
            Write-Host "    pip install $($Tool.PipPkg)" -ForegroundColor DarkGray
            pip install $Tool.PipPkg 2>&1 | Out-Null
            Refresh-Path
            return $true
        }
    }
    return $false
}

function Install-ToolInWsl {
    param([hashtable]$Tool)
    $wslAvailable = Get-Command wsl -ErrorAction SilentlyContinue
    if (-not $wslAvailable) {
        Write-Host "    [SKIP] WSL not available" -ForegroundColor DarkGray
        return
    }
    if ($Tool.InstallType -eq "npm" -and $Tool.NpmPkg) {
        Write-Host "    [WSL] npm install -g $($Tool.NpmPkg)" -ForegroundColor DarkGray
        wsl bash -c "npm install -g $($Tool.NpmPkg) 2>&1 || true" 2>&1 | Out-Null
        $check = wsl bash -c "command -v $($Tool.CheckCmd) 2>/dev/null && $($Tool.CheckCmd) --version 2>&1 | head -1 || echo ''" 2>&1
        $checkStr = "$check".Trim()
        if ($checkStr) {
            Write-Host "    [WSL OK] $($Tool.Name): $checkStr" -ForegroundColor Green
        } else {
            Write-Host "    [WSL WARN] $($Tool.Name) installed but not on PATH in WSL" -ForegroundColor Yellow
        }
    }
}

# ---------------------------------------------------------------------------
# Build tool list for selected category (deduplicated)
# ---------------------------------------------------------------------------

$toolMap = [ordered]@{}

function Add-Tools {
    param([array]$Tools)
    foreach ($t in $Tools) {
        if (-not $toolMap.Contains($t.Name)) {
            $toolMap[$t.Name] = $t
        }
    }
}

switch ($Category) {
    "WebDev"  { Add-Tools $WebDevTools }
    "VSTDev"  { Add-Tools $VSTDevTools }
    "MLDev"   { Add-Tools $MLDevTools }
    "AITools" { Add-Tools $AIToolsTools }
    "All"     {
        Add-Tools $WebDevTools
        Add-Tools $VSTDevTools
        Add-Tools $MLDevTools
        Add-Tools $AIToolsTools
    }
}

$tools = $toolMap.Values

# ---------------------------------------------------------------------------
# Phase 1: Detection
# ---------------------------------------------------------------------------

Write-Host "=== AbeOS Dev Environment Installer ===" -ForegroundColor Cyan
Write-Host "Category: $Category" -ForegroundColor DarkGray
Write-Host "Checking $($tools.Count) tools..." -ForegroundColor DarkGray
Write-Host ""

Write-Host "[DETECTION]" -ForegroundColor Yellow

$installed = @()
$missing = @()

foreach ($tool in $tools) {
    $ver = Test-Tool $tool
    if ($ver) {
        Write-Host "  [OK] $($tool.Name) - $ver" -ForegroundColor Green
        $installed += $tool
    } else {
        Write-Host "  [--] $($tool.Name) - not found" -ForegroundColor Red
        $missing += $tool
    }
}

# ---------------------------------------------------------------------------
# Phase 2: Summary
# ---------------------------------------------------------------------------

Write-Host ""
Write-Host "[SUMMARY]" -ForegroundColor Yellow
Write-Host "  Installed: $($installed.Count) / $($tools.Count)" -ForegroundColor Green
Write-Host "  Missing:   $($missing.Count) / $($tools.Count)" -ForegroundColor $(if ($missing.Count -gt 0) { "Red" } else { "Green" })

if ($missing.Count -eq 0) {
    Write-Host ""
    Write-Host "All tools are already installed." -ForegroundColor Green
    Write-Host ""
    Write-Host "Done." -ForegroundColor Cyan
    exit 0
}

# ---------------------------------------------------------------------------
# Phase 3: Installation (Windows)
# ---------------------------------------------------------------------------

# Verify winget is available for winget-type installs
$wingetCmd = Get-Command winget -ErrorAction SilentlyContinue
if (-not $wingetCmd) {
    Write-Host ""
    Write-Host "[WARN] winget not found. Winget-based installs will be skipped." -ForegroundColor Yellow
    Write-Host "Install App Installer from the Microsoft Store for full support." -ForegroundColor DarkGray
}

Write-Host ""
Write-Host "[INSTALLING] $($missing.Count) tool(s) on Windows" -ForegroundColor Yellow

$successCount = 0
$failCount = 0

foreach ($tool in $missing) {
    Write-Host ""
    Write-Host "  Installing $($tool.Name)..." -ForegroundColor Cyan
    $ok = Install-Tool $tool
    if ($ok) { $successCount++ } else { $failCount++ }
}

# ---------------------------------------------------------------------------
# Phase 4: WSL Installation (for tools with WslInstall flag)
# ---------------------------------------------------------------------------

$wslTools = @($tools | Where-Object { $_.WslInstall -eq $true })
if ($wslTools.Count -gt 0) {
    $wslAvailable = Get-Command wsl -ErrorAction SilentlyContinue
    if ($wslAvailable) {
        Write-Host ""
        Write-Host "[WSL INSTALLS] $($wslTools.Count) tool(s)" -ForegroundColor Yellow

        # Ensure Node.js/npm is available in WSL
        $wslNode = wsl bash -c "command -v node 2>/dev/null || echo ''" 2>&1
        if (-not "$wslNode".Trim()) {
            Write-Host "  [WSL] Node.js not found in WSL - installing via nvm..." -ForegroundColor DarkGray
            wsl bash -c "curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.1/install.sh | bash && export NVM_DIR=\$HOME/.nvm && . \$NVM_DIR/nvm.sh && nvm install --lts 2>&1" 2>&1 | Out-Null
        }

        foreach ($tool in $wslTools) {
            Install-ToolInWsl $tool
        }
    } else {
        Write-Host ""
        Write-Host "[SKIP] WSL not available - skipping WSL installs" -ForegroundColor DarkGray
    }
}

# ---------------------------------------------------------------------------
# Phase 5: Post-install verification
# ---------------------------------------------------------------------------

Write-Host ""
Write-Host "[VERIFICATION]" -ForegroundColor Yellow

Refresh-Path

foreach ($tool in $missing) {
    $ver = Test-Tool $tool
    if ($ver) {
        Write-Host "  [OK] $($tool.Name) - $ver" -ForegroundColor Green
    } else {
        Write-Host "  [!!] $($tool.Name) - not on PATH (restart terminal or reboot)" -ForegroundColor Yellow
    }
}

# ---------------------------------------------------------------------------
# Final report
# ---------------------------------------------------------------------------

Write-Host ""
Write-Host "=== Complete ===" -ForegroundColor Cyan
Write-Host "  Installed: $successCount" -ForegroundColor Green
if ($failCount -gt 0) {
    Write-Host "  Failed:    $failCount" -ForegroundColor Red
}
Write-Host ""
Write-Host "Some tools may require a terminal restart to appear on PATH." -ForegroundColor DarkGray
Write-Host ""
Write-Host "Done." -ForegroundColor Cyan
