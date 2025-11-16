# =============================================================================
# Fix-MissingPackages.ps1
# Install packages that failed in the initial installation
# =============================================================================

#Requires -RunAsAdministrator

$ErrorActionPreference = "Continue"

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Fixing Missing Packages" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
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

# Fix 1: Gradle (correct package name)
Log-Info "Installing Gradle..."
if (-not (Get-Command gradle -ErrorAction SilentlyContinue)) {
    choco install gradle -y
    Log-Success "Gradle installed"
} else {
    Log-Info "Gradle already installed: $(gradle --version | Select-String 'Gradle')"
}

# Fix 2: Maven (correct package name)
Log-Info "Installing Maven..."
if (-not (Get-Command mvn -ErrorAction SilentlyContinue)) {
    choco install maven -y
    Log-Success "Maven installed"
} else {
    Log-Info "Maven already installed: $(mvn --version | Select-String 'Apache Maven')"
}

# Fix 3: Nerd Fonts (correct package names)
Log-Info "Installing Nerd Fonts..."

# CascadiaCode Nerd Font
Log-Info "Installing CascadiaCode Nerd Font..."
choco install cascadia-code-nerd-font -y --ignore-checksums
if ($LASTEXITCODE -eq 0) {
    Log-Success "CascadiaCode Nerd Font installed"
} else {
    Log-Warning "CascadiaCode installation failed - trying alternative method..."
    # Manual download and install
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

        Remove-Item $fontZip -Force
        Remove-Item $fontDir -Recurse -Force
        Log-Success "CascadiaCode Nerd Font installed manually"
    } catch {
        Log-Warning "Manual font installation failed: $_"
    }
}

# JetBrainsMono Nerd Font
Log-Info "Installing JetBrainsMono Nerd Font..."
choco install jetbrainsmono-nerd-font -y --ignore-checksums
if ($LASTEXITCODE -eq 0) {
    Log-Success "JetBrainsMono Nerd Font installed"
} else {
    Log-Warning "JetBrainsMono installation failed - trying alternative method..."
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

        Remove-Item $fontZip -Force
        Remove-Item $fontDir -Recurse -Force
        Log-Success "JetBrainsMono Nerd Font installed manually"
    } catch {
        Log-Warning "Manual font installation failed: $_"
    }
}

# Fix 4: NVM for Windows (if failed)
Log-Info "Checking NVM for Windows..."
if (-not (Test-Path "$env:APPDATA\nvm")) {
    Log-Info "Installing NVM for Windows..."
    choco install nvm -y
    Log-Success "NVM for Windows installed"
} else {
    Log-Info "NVM for Windows already installed"
}

# Fix 5: Visual C++ Redistributables (try alternative)
Log-Info "Installing Visual C++ Redistributables..."
choco install vcredist140 -y
if ($LASTEXITCODE -eq 0) {
    Log-Success "VC++ Redistributables installed"
}

# Fix 6: OpenSSH (Windows built-in)
Log-Info "Enabling Windows OpenSSH..."
$openssh = Get-WindowsCapability -Online | Where-Object Name -like 'OpenSSH.Client*'
if ($openssh.State -ne 'Installed') {
    Add-WindowsCapability -Online -Name $openssh.Name
    Log-Success "OpenSSH enabled"
} else {
    Log-Info "OpenSSH already enabled"
}

# Additional missing packages from your list

# Miniconda
Log-Info "Installing Miniconda3..."
if (-not (Test-Path "$env:USERPROFILE\miniconda3")) {
    choco install miniconda3 -y --params="/AddToPath:1"
    Log-Success "Miniconda3 installed"
} else {
    Log-Info "Miniconda3 already installed"
}

# Starship (alternative prompt)
Log-Info "Installing Starship prompt..."
if (-not (Get-Command starship -ErrorAction SilentlyContinue)) {
    choco install starship -y
    Log-Success "Starship installed"
} else {
    Log-Info "Starship already installed"
}

# HTTPie
Log-Info "Installing HTTPie..."
if (-not (Get-Command http -ErrorAction SilentlyContinue)) {
    choco install httpie -y
    Log-Success "HTTPie installed"
} else {
    Log-Info "HTTPie already installed"
}

# Refresh environment
$env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Verification" -ForegroundColor Yellow
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Verify installations
$tools = @(
    @{Name="Gradle"; Command="gradle"},
    @{Name="Maven"; Command="mvn"},
    @{Name="NVM"; Command="nvm"},
    @{Name="Miniconda"; Command="conda"},
    @{Name="Starship"; Command="starship"},
    @{Name="HTTPie"; Command="http"}
)

foreach ($tool in $tools) {
    Write-Host "  $($tool.Name): " -NoNewline
    if (Get-Command $tool.Command -ErrorAction SilentlyContinue) {
        Write-Host "✓ Installed" -ForegroundColor Green
    } else {
        Write-Host "✗ Not found" -ForegroundColor Red
    }
}

# Check fonts
Write-Host "  Nerd Fonts: " -NoNewline
$fontsInstalled = 0
$fontFamilies = (New-Object System.Drawing.Text.InstalledFontCollection).Families
if ($fontFamilies.Name -like "*CaskaydiaCove*" -or $fontFamilies.Name -like "*Cascadia*Nerd*") {
    $fontsInstalled++
}
if ($fontFamilies.Name -like "*JetBrainsMono*Nerd*") {
    $fontsInstalled++
}

if ($fontsInstalled -gt 0) {
    Write-Host "✓ $fontsInstalled font(s) installed" -ForegroundColor Green
} else {
    Write-Host "✗ Not found" -ForegroundColor Red
}

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Log-Success "Missing packages installation complete!"
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

Write-Host "Next steps:" -ForegroundColor Yellow
Write-Host "  1. Close and reopen your terminal to refresh PATH" -ForegroundColor White
Write-Host "  2. Verify with: gradle --version, mvn --version" -ForegroundColor White
Write-Host "  3. Check fonts in Windows Terminal settings" -ForegroundColor White
Write-Host ""
