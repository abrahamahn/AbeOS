#!/bin/bash
# =============================================================================
# Configure-OhMyPosh-Theme.sh
# Apply custom Oh My Posh theme from AbeOS configs
# =============================================================================

set -e

echo "=================================================="
echo "Oh My Posh Theme Configuration"
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

# Paths
THEME_PATH="/mnt/c/AbeOS/configs/core/terminal/abe.omp.json"
BASHRC="$HOME/.bashrc"

# Check if theme file exists
if [ ! -f "$THEME_PATH" ]; then
    log_error "Theme file not found: $THEME_PATH"
    exit 1
fi

log_success "Theme file found: $THEME_PATH"

# Check if Oh My Posh is installed
if ! command -v oh-my-posh &> /dev/null; then
    log_warning "Oh My Posh not installed. Installing..."

    # Install Oh My Posh
    curl -s https://ohmyposh.dev/install.sh | bash -s

    # Add to PATH
    export PATH="$HOME/.local/bin:$PATH"

    if command -v oh-my-posh &> /dev/null; then
        log_success "Oh My Posh installed successfully"
    else
        log_error "Failed to install Oh My Posh"
        exit 1
    fi
else
    log_info "Oh My Posh already installed: $(oh-my-posh --version)"
fi

# Backup existing .bashrc
log_info "Backing up .bashrc..."
cp "$BASHRC" "$BASHRC.backup.$(date +%Y%m%d_%H%M%S)"
log_success "Backup created"

# Remove existing Oh My Posh initialization (if any)
log_info "Removing old Oh My Posh configuration..."
sed -i '/oh-my-posh/d' "$BASHRC"

# Add Oh My Posh initialization to .bashrc
log_info "Adding Oh My Posh configuration to .bashrc..."
cat >> "$BASHRC" << EOF

# Oh My Posh - AbeOS Custom Theme
if command -v oh-my-posh &> /dev/null; then
    eval "\$(oh-my-posh init bash --config '$THEME_PATH')"
fi
EOF

log_success "Configuration added to .bashrc"

# Install Nerd Font if not present
log_info "Checking for Nerd Font..."
if ! fc-list | grep -qi "nerd"; then
    log_warning "No Nerd Font detected. Installing CaskaydiaCove Nerd Font..."

    # Create fonts directory
    mkdir -p ~/.local/share/fonts

    # Download and install CaskaydiaCove Nerd Font
    FONT_URL="https://github.com/ryanoasis/nerd-fonts/releases/latest/download/CascadiaCode.zip"
    FONT_ZIP="/tmp/CascadiaCode.zip"

    wget -O "$FONT_ZIP" "$FONT_URL"
    unzip -o "$FONT_ZIP" -d ~/.local/share/fonts/
    rm "$FONT_ZIP"

    # Refresh font cache
    fc-cache -fv

    log_success "Nerd Font installed"
    log_warning "You may need to change your terminal font to 'CaskaydiaCove Nerd Font'"
else
    log_info "Nerd Font already installed"
fi

# Test theme
log_info "Testing theme configuration..."
if oh-my-posh print config --config="$THEME_PATH" &> /dev/null; then
    log_success "Theme configuration is valid"
else
    log_error "Theme configuration has errors"
    exit 1
fi

echo ""
echo "=================================================="
log_success "Oh My Posh theme configuration complete!"
echo "=================================================="
echo ""
echo "Configuration summary:"
echo "  ✓ Oh My Posh installed"
echo "  ✓ AbeOS theme configured: $THEME_PATH"
echo "  ✓ .bashrc updated (backup created)"
echo "  ✓ Nerd Font installed"
echo ""
echo "Next steps:"
echo "  1. Restart your terminal or run: source ~/.bashrc"
echo "  2. Set your terminal font to: CaskaydiaCove Nerd Font (or any Nerd Font)"
echo "  3. Your custom theme should now be active!"
echo ""
echo "Theme preview:"
oh-my-posh print config --config="$THEME_PATH" | head -10
echo ""
echo "Troubleshooting:"
echo "  - If icons don't show: Install a Nerd Font and set it in terminal settings"
echo "  - If colors are wrong: Check terminal supports 256 colors"
echo "  - To switch themes: Edit path in ~/.bashrc"
echo ""
