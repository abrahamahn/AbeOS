#!/bin/bash
# =============================================================================
# Install-Node-DevTools.sh
# Node.js/JavaScript Development Stack Installation Script
# =============================================================================

set -e  # Exit on error

echo "=================================================="
echo "Node.js/JavaScript Development Stack Installation"
echo "=================================================="
echo ""

# Color codes for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if NVM is installed
if [ ! -d "$HOME/.nvm" ]; then
    log_info "Installing NVM..."
    curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.7/install.sh | bash

    # Load NVM
    export NVM_DIR="$HOME/.nvm"
    [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"

    log_success "NVM installed"
else
    log_info "NVM already installed"
    # Load NVM
    export NVM_DIR="$HOME/.nvm"
    [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
fi

# Install Node.js LTS versions
log_info "Installing Node.js v20 (LTS)..."
nvm install 20
nvm alias default 20
log_success "Node.js v20 installed and set as default"

log_info "Installing Node.js v24..."
nvm install 24
log_success "Node.js v24 installed"

# Use Node 20 as default
nvm use 20

log_info "Current Node version: $(node --version)"
log_info "Current npm version: $(npm --version)"

# Enable Corepack for pnpm/yarn version management
log_info "Enabling Corepack..."
corepack enable
log_success "Corepack enabled"

# Install global npm packages
log_info "Installing global npm packages..."

GLOBAL_PACKAGES=(
    "eslint@latest"
    "prettier@latest"
    "typescript@latest"
    "ts-node@latest"
    "nodemon@latest"
    "pnpm@latest"
    "yarn@latest"
    "@anthropic-ai/claude-code@latest"
    "turbo@latest"
    "nx@latest"
    "concurrently@latest"
    "rimraf@latest"
    "npm-check-updates@latest"
    "dotenv-cli@latest"
    "cross-env@latest"
    "serve@latest"
    "http-server@latest"
)

for package in "${GLOBAL_PACKAGES[@]}"; do
    log_info "Installing $package..."
    npm install -g "$package" --silent
done

log_success "Global npm packages installed"

# Install pnpm via corepack and set up
log_info "Setting up pnpm..."
corepack prepare pnpm@latest --activate
log_success "pnpm configured"

# Install yarn via corepack
log_info "Setting up yarn..."
corepack prepare yarn@stable --activate
log_success "yarn configured"

# Configure npm for better performance
log_info "Configuring npm settings..."
npm config set save-exact true
npm config set engine-strict true
npm config set fund false
npm config set audit false
log_success "npm configured"

# Install Bun (optional modern runtime)
log_info "Installing Bun..."
if ! command -v bun &> /dev/null; then
    curl -fsSL https://bun.sh/install | bash
    log_success "Bun installed"

    # Add Bun to PATH in bashrc if not present
    if ! grep -q ".bun/bin" ~/.bashrc; then
        echo 'export BUN_INSTALL="$HOME/.bun"' >> ~/.bashrc
        echo 'export PATH="$BUN_INSTALL/bin:$PATH"' >> ~/.bashrc
        log_info "Bun added to PATH in ~/.bashrc"
    fi
else
    log_info "Bun already installed"
fi

# List installed global packages
echo ""
log_info "Installed global packages:"
npm list -g --depth=0

echo ""
echo "=================================================="
log_success "Node.js/JavaScript stack installation complete!"
echo "=================================================="
echo ""
echo "Installed components:"
echo "  ✓ NVM (Node Version Manager)"
echo "  ✓ Node.js v20 (LTS) - default"
echo "  ✓ Node.js v24"
echo "  ✓ Corepack (pnpm/yarn management)"
echo "  ✓ Global packages (eslint, prettier, typescript, etc.)"
echo "  ✓ pnpm, yarn, Bun"
echo "  ✓ Nx, Turbo (monorepo tools)"
echo ""
echo "Next steps:"
echo "  1. Restart your shell or run: source ~/.bashrc"
echo "  2. Test with: node --version && npm --version"
echo "  3. Create a project with: npm create vite@latest"
echo ""
