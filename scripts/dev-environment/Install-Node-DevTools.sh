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

# CRITICAL: Remove system Node.js if installed via apt
# This prevents conflicts with NVM (see DEBUG.md for details)
if command -v node &> /dev/null; then
    NODE_PATH=$(which node)
    if [[ "$NODE_PATH" == "/usr/bin/node" ]]; then
        log_warning "System Node.js found (installed via apt)"
        log_warning "Removing to prevent conflicts with NVM..."
        sudo apt purge -y nodejs npm
        sudo apt autoremove -y
        log_success "System Node.js removed"
    fi
fi

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
    "nx@latest"
    "concurrently@latest"
    "rimraf@latest"
    "npm-check-updates@latest"
    "dotenv-cli@latest"
    "cross-env@latest"
    "serve@latest"
    "http-server@latest"
    # Removed bloat: turbo
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

# Configure npm for better performance and correct global path
log_info "Configuring npm settings..."
npm config set save-exact true
npm config set engine-strict true
npm config set fund false
npm config set audit false

# CRITICAL: Set npm global prefix to avoid Windows PATH contamination
npm config set prefix "$HOME/.npm-global"
log_success "npm configured with global prefix: $HOME/.npm-global"

# Add npm global bin to PATH if not present
if ! grep -q ".npm-global/bin" ~/.bashrc; then
    echo 'export PATH="$HOME/.npm-global/bin:$PATH"' >> ~/.bashrc
    log_info "npm global bin added to PATH in ~/.bashrc"
fi

# Export PATH for current session
export PATH="$HOME/.npm-global/bin:$PATH"

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
echo "  ✓ pnpm, yarn"
echo "  ✓ Nx (monorepo tool)"
echo "  ✓ npm global prefix configured: ~/.npm-global"
echo ""
echo "Next steps:"
echo "  1. Restart your shell or run: source ~/.bashrc"
echo "  2. Test with: node --version && npm --version"
echo "  3. Verify npm global path: npm root -g"
echo "  4. Create a project with: npm create vite@latest"
echo ""
