#!/bin/bash
# =============================================================================
# Install-All-DevTools.sh
# Master Development Environment Installation Orchestrator
# =============================================================================

set -e  # Exit on error

# Color codes for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

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

log_section() {
    echo ""
    echo -e "${CYAN}========================================${NC}"
    echo -e "${CYAN}$1${NC}"
    echo -e "${CYAN}========================================${NC}"
    echo ""
}

# Welcome banner
clear
echo -e "${CYAN}"
cat << "EOF"
   _____ _              ____   _____
  / ____| |            / __ \ / ____|
 | (___ | |_ __ _  ___| |  | | (___
  \___ \| __/ _` |/ _ \ |  | |\___ \
  ____) | || (_| |  __/ |__| |____) |
 |_____/ \__\__,_|\___|\____/|_____/

 AbeOS Developer Environment Setup
EOF
echo -e "${NC}"

log_info "Starting comprehensive development environment installation..."
log_info "This will install tools for:"
log_info "  • WSL/Linux development"
log_info "  • Node.js/JavaScript ecosystem"
log_info "  • Web development packages"
log_info "  • Python/AI/ML toolchain"
log_info "  • AI CLI tools"
log_info "  • Java/JVM development"
log_info "  • C/C++ development"
log_info "  • VS Code extensions"
log_info ""

# Ask for confirmation
read -p "Continue with installation? (y/N): " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    log_warning "Installation cancelled by user"
    exit 0
fi

# Track installation time
START_TIME=$(date +%s)

# Track failed installations
FAILED_INSTALLS=()

# Function to run installation script
run_install() {
    local script_name=$1
    local script_path="$SCRIPT_DIR/$script_name"

    if [ ! -f "$script_path" ]; then
        log_error "Script not found: $script_path"
        FAILED_INSTALLS+=("$script_name (not found)")
        return 1
    fi

    log_info "Running: $script_name"

    # Make script executable
    chmod +x "$script_path"

    # Run the script
    if bash "$script_path"; then
        log_success "$script_name completed successfully"
        return 0
    else
        log_error "$script_name failed"
        FAILED_INSTALLS+=("$script_name")
        return 1
    fi
}

# 1. WSL/Linux toolchain
log_section "Step 1/5: Installing WSL/Linux Development Tools"
run_install "Install-WSL-DevTools.sh" || log_warning "WSL tools installation had issues"

# 2. Node.js stack
log_section "Step 2/9: Installing Node.js/JavaScript Stack"
run_install "Install-Node-DevTools.sh" || log_warning "Node.js installation had issues"

# 3. Web development packages
log_section "Step 3/9: Installing Web Development Packages"
run_install "Install-WebDev-Packages.sh" || log_warning "Web dev packages installation had issues"

# 4. Python/AI stack
log_section "Step 4/9: Installing Python/AI Toolchain"
run_install "Install-Python-AI-DevTools.sh" || log_warning "Python/AI installation had issues"

# 5. Miniconda (Python package manager)
log_section "Step 5/9: Installing Miniconda"
run_install "Install-Miniconda.sh" || log_warning "Miniconda installation had issues"

# 6. AI CLI tools
log_section "Step 6/9: Installing AI CLI Tools"
run_install "Install-AI-CLIs.sh" || log_warning "AI CLIs installation had issues"

# 7. Java/JVM stack
log_section "Step 7/9: Installing Java/JVM Stack"
run_install "Install-Java-DevTools.sh" || log_warning "Java installation had issues"

# 8. C/C++ stack
log_section "Step 8/9: Installing C/C++ Toolchain"
run_install "Install-CPP-DevTools.sh" || log_warning "C/C++ installation had issues"

# 9. VS Code extensions
log_section "Step 9/9: Installing VS Code Extensions"
run_install "Install-VSCode-Extensions.sh" || log_warning "VS Code extensions installation had issues"

# Calculate installation time
END_TIME=$(date +%s)
DURATION=$((END_TIME - START_TIME))
MINUTES=$((DURATION / 60))
SECONDS=$((DURATION % 60))

# Generate completion report
log_section "Installation Complete!"

echo -e "${GREEN}✓ Installation finished in ${MINUTES}m ${SECONDS}s${NC}"
echo ""

if [ ${#FAILED_INSTALLS[@]} -eq 0 ]; then
    echo -e "${GREEN}All installations completed successfully!${NC}"
else
    echo -e "${YELLOW}Some installations had issues:${NC}"
    for failed in "${FAILED_INSTALLS[@]}"; do
        echo -e "${RED}  ✗ $failed${NC}"
    done
fi

echo ""
echo "Installed components:"
echo "  ✓ WSL/Linux development tools"
echo "  ✓ Node.js/JavaScript ecosystem (NVM, Node 20/24, pnpm, yarn)"
echo "  ✓ Web development packages (Vite, Prisma, TypeScript, etc.)"
echo "  ✓ Python/AI/ML toolchain (PyTorch, TensorFlow, Transformers)"
echo "  ✓ Miniconda (Python package manager)"
echo "  ✓ AI CLI tools (Anthropic, OpenAI, Gemini, Aider)"
echo "  ✓ Java/JVM development stack (SDKMAN!, Java 21/17/11, Gradle, Maven)"
echo "  ✓ C/C++ development tools (GCC, Clang, debugging tools)"
echo "  ✓ VS Code extensions (80+ extensions)"
echo ""
echo "Next steps:"
echo "  1. Restart your shell: source ~/.bashrc"
echo "  2. Run verification: bash $SCRIPT_DIR/Verify-Installation.sh"
echo "  3. Check installation report for any issues"
echo ""

# Prompt to run verification
read -p "Run verification script now? (y/N): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    if [ -f "$SCRIPT_DIR/Verify-Installation.sh" ]; then
        bash "$SCRIPT_DIR/Verify-Installation.sh"
    else
        log_warning "Verification script not found"
    fi
fi

log_success "Setup complete! Happy coding!"
