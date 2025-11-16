#!/bin/bash
# =============================================================================
# Configure-WSL.sh
# WSL2 Configuration Script - Fixes PATH contamination and systemd setup
# Based on DEBUG.md, DEBUG2.md, and DEBUG3.md findings
# =============================================================================

set -e  # Exit on error

echo "=================================================="
echo "WSL2 Configuration Setup"
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

# Check if running in WSL
if ! grep -q microsoft /proc/version; then
    log_error "This script must be run inside WSL2"
    exit 1
fi

log_success "Running inside WSL2"

# Get current WSL username
WSL_USER=$(whoami)
log_info "Current user: $WSL_USER"

# Step 1: Create /etc/wsl.conf with proper LF line endings
log_info "Creating /etc/wsl.conf with proper configuration..."

# CRITICAL: Use sudo tee to create file with LF endings, not CRLF
sudo tee /etc/wsl.conf >/dev/null <<EOF
[boot]
systemd=true

[user]
default=$WSL_USER

[interop]
appendWindowsPath=false
EOF

log_success "/etc/wsl.conf created"

# Step 2: Convert any CRLF to LF (just in case)
log_info "Ensuring LF line endings..."
sudo sed -i 's/\r$//' /etc/wsl.conf
log_success "Line endings verified"

# Step 3: Verify file integrity
log_info "Verifying file integrity..."

# Check file encoding
FILE_TYPE=$(file /etc/wsl.conf)
log_info "File type: $FILE_TYPE"

# Check for CRLF
if xxd /etc/wsl.conf | grep -q "0d0a"; then
    log_error "CRLF line endings detected! File may be corrupted."
    exit 1
else
    log_success "No CRLF detected - file is clean"
fi

# Check file permissions
PERMS=$(stat -c "%a" /etc/wsl.conf)
if [ "$PERMS" != "644" ]; then
    log_info "Setting correct permissions (644)..."
    sudo chmod 644 /etc/wsl.conf
fi

log_success "File permissions: $(stat -c "%a" /etc/wsl.conf)"

# Step 4: Verify root filesystem
log_info "Verifying root filesystem..."
ROOT_FS=$(mount | grep " on / " | awk '{print $5}')
if [ "$ROOT_FS" = "ext4" ]; then
    log_success "Root filesystem is ext4 (correct)"
else
    log_warning "Root filesystem is $ROOT_FS (expected ext4)"
fi

# Step 5: Display current configuration
log_info "Current /etc/wsl.conf contents:"
echo "---"
cat /etc/wsl.conf
echo "---"

# Step 6: Verify PATH doesn't contain Windows paths
log_info "Checking PATH for Windows contamination..."
if echo "$PATH" | grep -q "/mnt/c"; then
    log_warning "Windows paths detected in current PATH"
    log_warning "These will be removed after WSL restart"
    echo "Current PATH with Windows paths:"
    echo "$PATH" | tr ':' '\n' | grep "/mnt/c" || true
else
    log_success "No Windows paths in current PATH"
fi

# Step 7: Remove system Node.js if installed via apt
log_info "Checking for system Node.js installation..."
if command -v node &> /dev/null; then
    NODE_PATH=$(which node)
    if [[ "$NODE_PATH" == "/usr/bin/node" ]]; then
        log_warning "System Node.js found (installed via apt)"
        log_info "This should be removed in favor of NVM"
        log_info "Run: sudo apt purge -y nodejs npm && sudo apt autoremove -y"
    else
        log_success "Node.js is not from apt: $NODE_PATH"
    fi
else
    log_success "No system Node.js found (good - will use NVM)"
fi

# Step 8: Create helpful diagnostic script
log_info "Creating diagnostic script..."
cat > "$HOME/verify-wsl.sh" <<'DIAGNOSTIC_EOF'
#!/bin/bash
# WSL Verification Script

echo "=== WSL Environment Diagnostics ==="
echo ""

echo "1. WSL Version:"
cat /proc/version | grep -i microsoft
echo ""

echo "2. Root Filesystem:"
mount | grep " on / "
echo ""

echo "3. /etc/wsl.conf Status:"
file /etc/wsl.conf
stat /etc/wsl.conf
echo ""

echo "4. /etc/wsl.conf Contents:"
cat /etc/wsl.conf
echo ""

echo "5. PATH Check (should NOT contain /mnt/c):"
echo "$PATH" | tr ':' '\n' | grep "/mnt/c" && echo "WARNING: Windows paths found!" || echo "OK: No Windows paths"
echo ""

echo "6. Node.js Location:"
which node 2>/dev/null || echo "Node not installed"
node --version 2>/dev/null || echo "Node not installed"
echo ""

echo "7. npm global prefix:"
npm root -g 2>/dev/null || echo "npm not installed"
echo ""

echo "8. systemd Status:"
systemctl is-system-running 2>/dev/null || echo "systemd not running (WSL needs restart)"
echo ""

DIAGNOSTIC_EOF

chmod +x "$HOME/verify-wsl.sh"
log_success "Diagnostic script created: ~/verify-wsl.sh"

echo ""
echo "=================================================="
log_success "WSL2 configuration complete!"
echo "=================================================="
echo ""
echo "What was configured:"
echo "  ✓ /etc/wsl.conf created with LF line endings"
echo "  ✓ systemd enabled"
echo "  ✓ Default user set to: $WSL_USER"
echo "  ✓ Windows PATH injection disabled"
echo "  ✓ File integrity verified"
echo ""
echo "CRITICAL NEXT STEPS:"
echo ""
log_warning "1. Exit WSL and shutdown from Windows PowerShell:"
echo "   wsl --shutdown"
echo ""
log_warning "2. Restart WSL to apply changes"
echo ""
log_warning "3. After restart, run the diagnostic script:"
echo "   ~/verify-wsl.sh"
echo ""
echo "4. Install Node.js via NVM (not apt):"
echo "   curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.1/install.sh | bash"
echo "   source ~/.bashrc"
echo "   nvm install 20"
echo ""
echo "5. Configure npm global prefix:"
echo "   npm config set prefix ~/.npm-global"
echo "   echo 'export PATH=\"\$HOME/.npm-global/bin:\$PATH\"' >> ~/.bashrc"
echo ""
log_info "For more details, see DEBUG.md, DEBUG2.md, and DEBUG3.md"
echo ""
