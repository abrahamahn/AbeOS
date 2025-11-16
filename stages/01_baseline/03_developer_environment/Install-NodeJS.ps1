#Requires -RunAsAdministrator
<#
.SYNOPSIS
    Installs Node.js via NVM inside WSL2 for AbeOS development environment.
.DESCRIPTION
    - Removes any system-installed Node.js from apt (broken v12)
    - Installs NVM (Node Version Manager) inside WSL
    - Installs Node.js LTS (v20) via NVM
    - Configures npm global prefix to ~/.npm-global
    - Fixes PATH to include npm global binaries
    - Verifies installation and PATH configuration

    Fixes all issues documented in DEBUG3.md:
    - No more apt-installed Node v12
    - No more npm prefix pointing to Windows paths
    - Global npm packages install correctly
    - Codex and other CLI tools work properly
.PARAMETER NodeVersion
    Node.js version to install (default: 20)
.PARAMETER DistroName
    WSL distribution name (default: Ubuntu-22.04)
.EXAMPLE
    .\Install-NodeJS.ps1
.EXAMPLE
    .\Install-NodeJS.ps1 -NodeVersion 18
.NOTES
    File: Install-NodeJS.ps1
    Phase: 1.3 - Developer Environment
    System: Windows 11 (Zephyrus G14)

    Prerequisites:
    - WSL2 must be installed (run Install-WSL.ps1 first)
#>

[CmdletBinding()]
param(
    [string]$NodeVersion = "20",
    [string]$DistroName = "Ubuntu-22.04"
)

$ErrorActionPreference = "Stop"

# Import AbeOS core module for logging
$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot "..\..\..")).ProviderPath
Import-Module (Join-Path $repoRoot "modules\lib\AbeOS.Core.psm1") -Force

Write-AbeLog "==================================================" -Level Info
Write-AbeLog "  AbeOS Node.js Installation (via NVM)" -Level Info
Write-AbeLog "==================================================" -Level Info
Write-AbeLog "Target Distribution: $DistroName" -Level Info
Write-AbeLog "Node Version: v$NodeVersion (LTS)" -Level Info
Write-AbeLog ""

# Step 1: Verify WSL is installed
Write-AbeLog "Step 1: Verifying WSL is installed..." -Level Info
$wslInstalled = wsl -l -v 2>&1 | Out-String
if ($wslInstalled -notmatch $DistroName) {
    Write-AbeLog "WSL distribution '$DistroName' not found!" -Level Error
    Write-AbeLog "Please run Install-WSL.ps1 first." -Level Error
    exit 1
}
Write-AbeLog "✓ WSL is installed" -Level Success

# Step 2: Remove system Node.js if installed
Write-AbeLog "`nStep 2: Removing system Node.js (if installed via apt)..." -Level Info

$nodeCheck = wsl -d $DistroName bash -c "which node" 2>&1
if ($nodeCheck -match "/usr/bin/node") {
    Write-AbeLog "Found system Node.js installed via apt. Removing..." -Level Warning

    wsl -d $DistroName bash -c @"
sudo apt purge -y nodejs npm
sudo apt autoremove -y
sudo rm -rf /usr/lib/node_modules
sudo rm -rf /usr/local/lib/node_modules
"@

    Write-AbeLog "✓ System Node.js removed" -Level Success
} else {
    Write-AbeLog "✓ No system Node.js found (good)" -Level Success
}

# Step 3: Install NVM
Write-AbeLog "`nStep 3: Installing NVM (Node Version Manager)..." -Level Info

$nvmCheck = wsl -d $DistroName bash -c "command -v nvm" 2>&1
if ($LASTEXITCODE -eq 0 -and $nvmCheck) {
    Write-AbeLog "NVM is already installed" -Level Info
} else {
    Write-AbeLog "Downloading and installing NVM..." -Level Info

    $nvmInstallScript = @'
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.1/install.sh | bash
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
nvm --version
'@

    wsl -d $DistroName bash -c $nvmInstallScript

    if ($LASTEXITCODE -eq 0) {
        Write-AbeLog "✓ NVM installed successfully" -Level Success
    } else {
        Write-AbeLog "Failed to install NVM" -Level Error
        exit 1
    }
}

# Step 4: Install Node.js via NVM
Write-AbeLog "`nStep 4: Installing Node.js v$NodeVersion via NVM..." -Level Info

$nodeInstallScript = @"
export NVM_DIR="`$HOME/.nvm"
[ -s "`$NVM_DIR/nvm.sh" ] && \. "`$NVM_DIR/nvm.sh"

# Install Node
nvm install $NodeVersion
nvm use $NodeVersion
nvm alias default $NodeVersion

# Verify
node --version
npm --version
"@

wsl -d $DistroName bash -c $nodeInstallScript

if ($LASTEXITCODE -eq 0) {
    Write-AbeLog "✓ Node.js v$NodeVersion installed" -Level Success
} else {
    Write-AbeLog "Failed to install Node.js" -Level Error
    exit 1
}

# Step 5: Fix npm global prefix
Write-AbeLog "`nStep 5: Configuring npm global prefix..." -Level Info

$npmConfigScript = @'
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"

# Set npm global prefix
npm config set prefix "$HOME/.npm-global"

# Add to PATH in .bashrc if not already there
if ! grep -q "\.npm-global/bin" ~/.bashrc; then
    echo 'export PATH="$HOME/.npm-global/bin:$PATH"' >> ~/.bashrc
fi

# Verify
npm config get prefix
'@

$npmPrefix = wsl -d $DistroName bash -c $npmConfigScript

Write-AbeLog "  npm global prefix: $npmPrefix" -Level Info

if ($npmPrefix -match "/.npm-global") {
    Write-AbeLog "✓ npm global prefix configured correctly" -Level Success
} else {
    Write-AbeLog "Warning: npm prefix might not be configured correctly" -Level Warning
}

# Step 6: Update .bashrc to load NVM on shell startup
Write-AbeLog "`nStep 6: Updating .bashrc to load NVM automatically..." -Level Info

$bashrcUpdate = @'
# Check if NVM initialization is in .bashrc
if ! grep -q "NVM_DIR" ~/.bashrc; then
    cat >> ~/.bashrc << 'EOF'

# NVM initialization
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion
EOF
    echo "NVM initialization added to .bashrc"
else
    echo "NVM initialization already in .bashrc"
fi
'@

wsl -d $DistroName bash -c $bashrcUpdate
Write-AbeLog "✓ .bashrc updated" -Level Success

# Step 7: Install essential global npm packages
Write-AbeLog "`nStep 7: Installing essential global npm packages..." -Level Info

$globalPackages = @(
    "pnpm",
    "yarn",
    "typescript",
    "ts-node",
    "nodemon",
    "pm2"
)

foreach ($package in $globalPackages) {
    Write-AbeLog "Installing $package..." -Level Info

    $installScript = @"
export NVM_DIR="`$HOME/.nvm"
[ -s "`$NVM_DIR/nvm.sh" ] && \. "`$NVM_DIR/nvm.sh"
npm install -g $package
"@

    wsl -d $DistroName bash -c $installScript

    if ($LASTEXITCODE -eq 0) {
        Write-AbeLog "  ✓ $package installed" -Level Success
    } else {
        Write-AbeLog "  Warning: Failed to install $package" -Level Warning
    }
}

# Step 8: Verify installation
Write-AbeLog "`nStep 8: Verifying Node.js installation..." -Level Info

$verifyScript = @'
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"

echo "=== Node.js Version ==="
node --version

echo ""
echo "=== npm Version ==="
npm --version

echo ""
echo "=== npm global root ==="
npm root -g

echo ""
echo "=== npm global prefix ==="
npm config get prefix

echo ""
echo "=== PATH (checking for npm-global) ==="
echo $PATH | grep -o "[^:]*npm-global[^:]*"

echo ""
echo "=== which node ==="
which node

echo ""
echo "=== which npm ==="
which npm

echo ""
echo "=== Global packages installed ==="
npm list -g --depth=0
'@

Write-AbeLog ""
Write-AbeLog "Verification Results:" -Level Info
Write-AbeLog "----------------------------------------" -Level Info
$verifyOutput = wsl -d $DistroName bash -c $verifyScript
Write-AbeLog $verifyOutput -Level Info
Write-AbeLog "----------------------------------------" -Level Info

# Check for Windows paths in npm root
if ($verifyOutput -match "/mnt/c" -or $verifyOutput -match "C:\\") {
    Write-AbeLog "⚠ Warning: Windows paths detected in npm configuration!" -Level Warning
    Write-AbeLog "This should not happen. Please check your WSL configuration." -Level Warning
} else {
    Write-AbeLog "✓ No Windows paths detected (good)" -Level Success
}

# Summary
Write-AbeLog "`n==================================================" -Level Success
Write-AbeLog "  Node.js Installation Complete!" -Level Success
Write-AbeLog "==================================================" -Level Success
Write-AbeLog ""
Write-AbeLog "Configuration Summary:" -Level Info
Write-AbeLog "  ✓ NVM installed and configured" -Level Success
Write-AbeLog "  ✓ Node.js v$NodeVersion installed via NVM" -Level Success
Write-AbeLog "  ✓ npm global prefix set to ~/.npm-global" -Level Success
Write-AbeLog "  ✓ PATH configured for global npm packages" -Level Success
Write-AbeLog "  ✓ Essential npm packages installed" -Level Success
Write-AbeLog ""
Write-AbeLog "Next Steps:" -Level Info
Write-AbeLog "  1. Run 'wsl -d $DistroName' to enter WSL" -Level Info
Write-AbeLog "  2. Run 'source ~/.bashrc' to reload shell configuration" -Level Info
Write-AbeLog "  3. Test with 'node --version' and 'npm --version'" -Level Info
Write-AbeLog "  4. Install project-specific packages with 'npm install -g <package>'" -Level Info
Write-AbeLog ""
Write-AbeLog "To install other Node versions:" -Level Info
Write-AbeLog "  nvm install <version>" -Level Info
Write-AbeLog "  nvm use <version>" -Level Info
Write-AbeLog "  nvm alias default <version>" -Level Info
