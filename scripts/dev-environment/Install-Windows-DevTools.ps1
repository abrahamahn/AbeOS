# =============================================================================
# Install-Windows-DevTools.ps1
# Windows Development Tools Installation Script
# =============================================================================

#Requires -RunAsAdministrator

$ErrorActionPreference = "Continue"

Write-Host "==================================================" -ForegroundColor Cyan
Write-Host "Windows Development Tools Installation" -ForegroundColor Cyan
Write-Host "==================================================" -ForegroundColor Cyan
Write-Host ""

function Log-Info {
    param([string]$Message)
    Write-Host "[INFO] $Message" -ForegroundColor Blue
}

function Log-Success {
    param([string]$Message)
    Write-Host "[SUCCESS] $Message" -ForegroundColor Green
}

function Log-Warning {
    param([string]$Message)
    Write-Host "[WARNING] $Message" -ForegroundColor Yellow
}

function Log-Error {
    param([string]$Message)
    Write-Host "[ERROR] $Message" -ForegroundColor Red
}

# Check if winget is available
if (-not (Get-Command winget -ErrorAction SilentlyContinue)) {
    Log-Error "winget is not installed. Please install it from the Microsoft Store."
    exit 1
}

Log-Success "winget is available"

# Install Windows Subsystem for Linux (WSL2)
Log-Info "Checking WSL2 installation..."
$wslStatus = wsl --status 2>&1
if ($LASTEXITCODE -ne 0) {
    Log-Info "Installing WSL2..."
    wsl --install
    Log-Success "WSL2 installed. You may need to restart your computer."
} else {
    Log-Info "WSL2 already installed"
}

# Update WSL
Log-Info "Updating WSL..."
wsl --update

# Install development tools via winget
Log-Info "Installing development tools via winget..."

$WingetPackages = @(
    "Git.Git"
    "Microsoft.VisualStudioCode"
    "Microsoft.VisualStudio.2022.BuildTools"
    "Microsoft.PowerShell"
    "Microsoft.WindowsTerminal"
    "JanDeDobbeleer.OhMyPosh"
    "Docker.DockerDesktop"
    "Python.Python.3.12"
    # "OpenJS.NodeJS.LTS"  # Skip - conflicts with NVM
    "Kitware.CMake"
    "Ninja-build.Ninja"
    "LLVM.LLVM"
    "JetBrains.Toolbox"
    "Notepad++.Notepad++"
    "7zip.7zip"
    "GitHub.cli"
    "Microsoft.PowerToys"
    "Postman.Postman"
    "Oracle.JavaRuntimeEnvironment"
    "EclipseAdoptium.Temurin.21.JDK"
    # Gradle/Maven via Chocolatey instead (better package names)
)

foreach ($package in $WingetPackages) {
    Log-Info "Installing $package..."
    winget install --id $package --silent --accept-source-agreements --accept-package-agreements
    if ($LASTEXITCODE -eq 0) {
        Log-Success "$package installed"
    } else {
        Log-Warning "$package installation failed or already installed"
    }
}

# Install Chocolatey (alternative package manager)
Log-Info "Installing Chocolatey..."
if (-not (Get-Command choco -ErrorAction SilentlyContinue)) {
    Set-ExecutionPolicy Bypass -Scope Process -Force
    [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072
    Invoke-Expression ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))
    Log-Success "Chocolatey installed"
} else {
    Log-Info "Chocolatey already installed"
}

# Install additional tools via Chocolatey
Log-Info "Installing additional tools via Chocolatey..."

$ChocoPackages = @(
    "vcredist140"       # VC++ Redistributables (correct package)
    "dotnet-sdk"
    # "nodejs-lts"      # Skip - using NVM instead
    "gradle"            # Correct package name
    "maven"             # Correct package name
    "yarn"
    "pnpm"
    "miniconda3"        # Python package/env manager
    "starship"          # Modern prompt
    "httpie"            # HTTP client
    "ripgrep"
    "fd"
    "fzf"
    "jq"
    "yq"
    "make"
    "wget"
    "curl"
    # "openssh"         # Use Windows built-in capability instead
)

foreach ($package in $ChocoPackages) {
    Log-Info "Installing $package..."
    choco install $package -y
    if ($LASTEXITCODE -eq 0) {
        Log-Success "$package installed"
    } else {
        Log-Warning "$package installation failed or already installed"
    }
}

# Install NVM for Windows
Log-Info "Installing NVM for Windows..."
if (-not (Test-Path "$env:USERPROFILE\AppData\Roaming\nvm")) {
    winget install --id CoreyButler.NVMforWindows --silent
    Log-Success "NVM for Windows installed"
} else {
    Log-Info "NVM for Windows already installed"
}

# Install Nerd Fonts (with fallback to manual download)
Log-Info "Installing Nerd Fonts..."

# CascadiaCode Nerd Font
Log-Info "Installing CascadiaCode Nerd Font..."
choco install cascadia-code-nerd-font -y --ignore-checksums
if ($LASTEXITCODE -ne 0) {
    Log-Warning "Chocolatey installation failed - trying manual download..."
    $fontUrl = "https://github.com/ryanoasis/nerd-fonts/releases/latest/download/CascadiaCode.zip"
    $fontZip = "$env:TEMP\CascadiaCode.zip"
    $fontDir = "$env:TEMP\CascadiaCode"

    try {
        Invoke-WebRequest -Uri $fontUrl -OutFile $fontZip -UseBasicParsing
        Expand-Archive -Path $fontZip -DestinationPath $fontDir -Force

        # Install fonts
        $fonts = Get-ChildItem -Path $fontDir -Filter "*.ttf" -Recurse
        $fontsFolder = (New-Object -ComObject Shell.Application).Namespace(0x14)

        foreach ($font in $fonts) {
            $fontsFolder.CopyHere($font.FullName)
            Log-Info "  Installed: $($font.Name)"
        }

        Remove-Item $fontZip -Force -ErrorAction SilentlyContinue
        Remove-Item $fontDir -Recurse -Force -ErrorAction SilentlyContinue
        Log-Success "CascadiaCode Nerd Font installed manually"
    } catch {
        Log-Warning "Manual font installation failed: $_"
    }
} else {
    Log-Success "CascadiaCode Nerd Font installed"
}

# JetBrainsMono Nerd Font
Log-Info "Installing JetBrainsMono Nerd Font..."
choco install jetbrainsmono-nerd-font -y --ignore-checksums
if ($LASTEXITCODE -ne 0) {
    Log-Warning "Chocolatey installation failed - trying manual download..."
    $fontUrl = "https://github.com/ryanoasis/nerd-fonts/releases/latest/download/JetBrainsMono.zip"
    $fontZip = "$env:TEMP\JetBrainsMono.zip"
    $fontDir = "$env:TEMP\JetBrainsMono"

    try {
        Invoke-WebRequest -Uri $fontUrl -OutFile $fontZip -UseBasicParsing
        Expand-Archive -Path $fontZip -DestinationPath $fontDir -Force

        $fonts = Get-ChildItem -Path $fontDir -Filter "*.ttf" -Recurse
        $fontsFolder = (New-Object -ComObject Shell.Application).Namespace(0x14)

        foreach ($font in $fonts) {
            $fontsFolder.CopyHere($font.FullName)
            Log-Info "  Installed: $($font.Name)"
        }

        Remove-Item $fontZip -Force -ErrorAction SilentlyContinue
        Remove-Item $fontDir -Recurse -Force -ErrorAction SilentlyContinue
        Log-Success "JetBrainsMono Nerd Font installed manually"
    } catch {
        Log-Warning "Manual font installation failed: $_"
    }
} else {
    Log-Success "JetBrainsMono Nerd Font installed"
}

# Configure Git
Log-Info "Configuring Git..."
git config --global core.autocrlf input
git config --global init.defaultBranch main
git config --global pull.rebase false
Log-Success "Git configured"

# Enable Developer Mode
Log-Info "Enabling Developer Mode..."
try {
    reg add "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\AppModelUnlock" /t REG_DWORD /f /v "AllowDevelopmentWithoutDevLicense" /d "1"
    Log-Success "Developer Mode enabled"
} catch {
    Log-Warning "Failed to enable Developer Mode"
}

# Configure PowerShell execution policy
Log-Info "Configuring PowerShell execution policy..."
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser -Force
Log-Success "PowerShell execution policy set"

# Create Dev Drive directory structure (if on ReFS)
Log-Info "Creating development directory structure..."
$DevPaths = @(
    "C:\projects"
    "C:\projects\personal"
    "C:\projects\work"
    "C:\projects\experiments"
)

foreach ($path in $DevPaths) {
    if (-not (Test-Path $path)) {
        New-Item -Path $path -ItemType Directory -Force | Out-Null
        Log-Info "Created directory: $path"
    }
}

Log-Success "Directory structure created"

# Install vcpkg (C++ package manager)
Log-Info "Installing vcpkg..."
$vcpkgPath = "C:\tools\vcpkg"
if (-not (Test-Path $vcpkgPath)) {
    git clone https://github.com/Microsoft/vcpkg.git $vcpkgPath
    & "$vcpkgPath\bootstrap-vcpkg.bat"

    # Set environment variable
    [System.Environment]::SetEnvironmentVariable("VCPKG_ROOT", $vcpkgPath, [System.EnvironmentVariableTarget]::User)
    Log-Success "vcpkg installed"
} else {
    Log-Info "vcpkg already installed"
}

# Install Rust (optional but useful)
Log-Info "Installing Rust..."
if (-not (Get-Command rustc -ErrorAction SilentlyContinue)) {
    winget install --id Rustlang.Rust.MSVC --silent
    Log-Success "Rust installed"
} else {
    Log-Info "Rust already installed"
}

# Install Go (optional but useful)
Log-Info "Installing Go..."
if (-not (Get-Command go -ErrorAction SilentlyContinue)) {
    winget install --id GoLang.Go --silent
    Log-Success "Go installed"
} else {
    Log-Info "Go already installed"
}

Write-Host ""
Write-Host "==================================================" -ForegroundColor Cyan
Log-Success "Windows development tools installation complete!"
Write-Host "==================================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Installed components:" -ForegroundColor White
Write-Host "  ✓ WSL2 (Windows Subsystem for Linux)" -ForegroundColor Green
Write-Host "  ✓ Git, GitHub CLI" -ForegroundColor Green
Write-Host "  ✓ Visual Studio Code + Build Tools" -ForegroundColor Green
Write-Host "  ✓ Windows Terminal + Oh My Posh" -ForegroundColor Green
Write-Host "  ✓ Docker Desktop" -ForegroundColor Green
Write-Host "  ✓ Python 3.12" -ForegroundColor Green
Write-Host "  ✓ Node.js (LTS) + NVM for Windows" -ForegroundColor Green
Write-Host "  ✓ Java (Temurin 21), Gradle, Maven" -ForegroundColor Green
Write-Host "  ✓ CMake, Ninja, LLVM" -ForegroundColor Green
Write-Host "  ✓ vcpkg (C++ package manager)" -ForegroundColor Green
Write-Host "  ✓ Rust, Go" -ForegroundColor Green
Write-Host "  ✓ PowerToys, Postman, Notepad++" -ForegroundColor Green
Write-Host "  ✓ Modern CLI tools (ripgrep, fd, fzf, jq, yq)" -ForegroundColor Green
Write-Host "  ✓ Fonts (Cascadia Code, JetBrains Mono)" -ForegroundColor Green
Write-Host ""
Write-Host "Next steps:" -ForegroundColor Yellow
Write-Host "  1. RESTART YOUR COMPUTER to complete WSL2 installation" -ForegroundColor Yellow
Write-Host "  2. Open WSL2 and run the Linux installation scripts" -ForegroundColor Yellow
Write-Host "  3. Configure Docker Desktop to use WSL2 integration" -ForegroundColor Yellow
Write-Host "  4. Configure VS Code with Remote - WSL extension" -ForegroundColor Yellow
Write-Host ""
