#!/bin/bash
# =============================================================================
# Install-WSL-DevTools.sh
# WSL2/Linux Development Toolchain Installation Script
# =============================================================================

set -e  # Exit on error

echo "=================================================="
echo "WSL2/Linux Development Toolchain Installation"
echo "=================================================="
echo ""

# Color codes for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Logging function
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
    log_warning "This script is designed for WSL2. Continuing anyway..."
fi

# Update package lists
log_info "Updating package lists..."
sudo apt update

# Install build essentials
log_info "Installing build essentials..."
sudo apt install -y \
    build-essential \
    gcc \
    g++ \
    make \
    pkg-config \
    autoconf \
    automake \
    libtool

log_success "Build essentials installed"
# Removed bloat: cmake, ninja-build

# Install development libraries
log_info "Installing development libraries..."
sudo apt install -y \
    libssl-dev \
    zlib1g-dev \
    libbz2-dev \
    libreadline-dev \
    libsqlite3-dev \
    libncursesw5-dev \
    libxml2-dev \
    libxmlsec1-dev \
    libffi-dev \
    liblzma-dev

log_success "Development libraries installed"

# Install multimedia tools
log_info "Installing multimedia tools..."
sudo apt install -y \
    ffmpeg \
    imagemagick \
    libavcodec-dev \
    libavformat-dev \
    libswscale-dev

log_success "Multimedia tools installed"

# Install modern CLI tools
log_info "Installing modern CLI tools..."
sudo apt install -y \
    fd-find \
    jq \
    curl \
    wget \
    git \
    vim \
    neovim \
    htop \
    tree \
    zip \
    unzip

log_success "Modern CLI tools installed"
# Removed bloat: ripgrep, fzf, tmux

# Install yq (YAML processor)
log_info "Installing yq..."
YQ_VERSION="v4.40.5"
YQ_BINARY="yq_linux_amd64"
sudo wget -qO /usr/local/bin/yq "https://github.com/mikefarah/yq/releases/download/${YQ_VERSION}/${YQ_BINARY}"
sudo chmod +x /usr/local/bin/yq
log_success "yq installed"

# Install direnv
log_info "Installing direnv..."
sudo apt install -y direnv
log_success "direnv installed"

# Add direnv hook to bashrc if not already present
if ! grep -q "direnv hook bash" ~/.bashrc; then
    echo 'eval "$(direnv hook bash)"' >> ~/.bashrc
    log_info "direnv hook added to ~/.bashrc"
fi

# Install bat (better cat)
log_info "Installing bat..."
sudo apt install -y bat
# Create symlink if it doesn't exist
if [ ! -f ~/.local/bin/bat ] && [ -f /usr/bin/batcat ]; then
    mkdir -p ~/.local/bin
    ln -sf /usr/bin/batcat ~/.local/bin/bat
    log_info "Created bat symlink"
fi

# Install eza (modern ls replacement)
log_info "Installing eza..."
if ! command -v eza &> /dev/null; then
    sudo mkdir -p /etc/apt/keyrings
    wget -qO- https://raw.githubusercontent.com/eza-community/eza/main/deb.asc | sudo gpg --dearmor -o /etc/apt/keyrings/gierens.gpg
    echo "deb [signed-by=/etc/apt/keyrings/gierens.gpg] http://deb.gierens.de stable main" | sudo tee /etc/apt/sources.list.d/gierens.list
    sudo chmod 644 /etc/apt/keyrings/gierens.gpg /etc/apt/sources.list.d/gierens.list
    sudo apt update
    sudo apt install -y eza
    log_success "eza installed"
else
    log_info "eza already installed"
fi

# Clean up
log_info "Cleaning up..."
sudo apt autoremove -y
sudo apt clean

echo ""
echo "=================================================="
log_success "WSL2/Linux toolchain installation complete!"
echo "=================================================="
echo ""
echo "Installed components:"
echo "  ✓ Build essentials (gcc, g++, make)"
echo "  ✓ Development libraries (ssl, zlib, readline, etc.)"
echo "  ✓ Multimedia tools (FFmpeg, ImageMagick)"
echo "  ✓ Modern CLI tools (fd, jq, yq)"
echo "  ✓ Productivity tools (direnv, bat, eza)"
echo ""
echo "Next steps:"
echo "  1. Restart your shell or run: source ~/.bashrc"
echo "  2. Run verification script to confirm installation"
echo ""
