#!/bin/bash
# =============================================================================
# Setup-Bash-Profile.sh
# Link/copy AbeOS custom bash profile to user's home directory
# =============================================================================

set -e

echo "=================================================="
echo "AbeOS Bash Profile Setup"
echo "=================================================="
echo ""

# Color codes
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

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

# Check if running in WSL
if ! grep -q microsoft /proc/version; then
    log_error "This script must be run inside WSL2"
    exit 1
fi

# Determine AbeOS location (try WSL mount first, then Linux location)
if [ -d "/mnt/c/AbeOS/configs/core/terminal" ]; then
    ABEOS_CONFIG_DIR="/mnt/c/AbeOS/configs/core/terminal"
    log_info "Using AbeOS configs from Windows: $ABEOS_CONFIG_DIR"
elif [ -d "/home/user/AbeOS/configs/core/terminal" ]; then
    ABEOS_CONFIG_DIR="/home/user/AbeOS/configs/core/terminal"
    log_info "Using AbeOS configs from Linux: $ABEOS_CONFIG_DIR"
else
    log_error "AbeOS configs not found. Expected at:"
    echo "  /mnt/c/AbeOS/configs/core/terminal OR"
    echo "  /home/user/AbeOS/configs/core/terminal"
    exit 1
fi

# Backup existing .bashrc
if [ -f "$HOME/.bashrc" ]; then
    BACKUP_FILE="$HOME/.bashrc.backup.$(date +%Y%m%d_%H%M%S)"
    log_info "Backing up existing .bashrc to: $BACKUP_FILE"
    cp "$HOME/.bashrc" "$BACKUP_FILE"
    log_success "Backup created"
fi

# Check if AbeOS custom bashrc exists
if [ ! -f "$ABEOS_CONFIG_DIR/bashrc" ]; then
    log_error "AbeOS bashrc not found at: $ABEOS_CONFIG_DIR/bashrc"
    exit 1
fi

# Option 1: Copy the custom bashrc (recommended for WSL)
log_info "Copying AbeOS custom bashrc to ~/.bashrc..."
cp "$ABEOS_CONFIG_DIR/bashrc" "$HOME/.bashrc"

# Update the path in bashrc to point to the correct location
log_info "Updating bashrc.core path reference..."
if [ "$ABEOS_CONFIG_DIR" == "/home/user/AbeOS/configs/core/terminal" ]; then
    # If using Linux location, update the path
    sed -i "s|/mnt/c/AbeOS/configs/core/terminal/bashrc.core|$ABEOS_CONFIG_DIR/bashrc.core|g" "$HOME/.bashrc"
    log_info "Updated path to Linux location"
fi

log_success "Custom bashrc installed"

# Verify the setup
log_info "Verifying setup..."

# Check if bashrc sources bashrc.core
if grep -q "bashrc.core" "$HOME/.bashrc"; then
    log_success "bashrc is configured to load bashrc.core"
else
    log_error "bashrc does not load bashrc.core - setup may be incomplete"
    exit 1
fi

# Add npm global bin to PATH if not present (critical for global packages)
if ! grep -q ".npm-global/bin" "$HOME/.bashrc"; then
    log_info "Adding npm global bin to PATH..."
    cat >> "$HOME/.bashrc" << 'EOF'

# npm global packages
export PATH="$HOME/.npm-global/bin:$PATH"
EOF
    log_success "npm global bin added to PATH"
fi

# Ensure the bashrc.core file is accessible
BASHRC_CORE_PATH=$(grep -oP "(?<=\. ).*bashrc\.core" "$HOME/.bashrc" | head -1)
if [ -f "$BASHRC_CORE_PATH" ]; then
    log_success "bashrc.core found at: $BASHRC_CORE_PATH"
else
    log_error "bashrc.core not found at: $BASHRC_CORE_PATH"
    log_error "You may need to adjust the path in ~/.bashrc"
fi

# Display the loader configuration
echo ""
log_info "Current bashrc configuration:"
echo "---"
head -10 "$HOME/.bashrc"
echo "..."
echo "---"

echo ""
echo "=================================================="
log_success "Bash profile setup complete!"
echo "=================================================="
echo ""
echo "What was configured:"
echo "  ✓ Custom AbeOS bashrc installed at: ~/.bashrc"
echo "  ✓ Bashrc loads core config from: $BASHRC_CORE_PATH"
echo "  ✓ npm global bin added to PATH"
echo "  ✓ Previous bashrc backed up"
echo ""
echo "Features included in AbeOS bashrc:"
echo "  ✓ NVM initialization"
echo "  ✓ Oh My Posh theme"
echo "  ✓ Windows PATH filtering"
echo "  ✓ Custom aliases and functions"
echo "  ✓ Smart ls for Windows mounts"
echo ""
echo "Next steps:"
echo "  1. Reload your shell: source ~/.bashrc"
echo "  2. Verify NVM works: nvm --version"
echo "  3. Verify Oh My Posh: oh-my-posh --version"
echo "  4. Check PATH has no /mnt/c contamination: echo \$PATH"
echo ""
log_warning "If you see errors, check that bashrc.core path is correct"
echo ""
