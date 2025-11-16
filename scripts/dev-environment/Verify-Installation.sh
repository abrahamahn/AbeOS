#!/bin/bash
# =============================================================================
# Verify-Installation.sh
# Development Environment Verification Script
# =============================================================================

# Color codes for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Counters
TOTAL_CHECKS=0
PASSED_CHECKS=0
FAILED_CHECKS=0
WARNING_CHECKS=0

log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[✓]${NC} $1"
    ((PASSED_CHECKS++))
    ((TOTAL_CHECKS++))
}

log_warning() {
    echo -e "${YELLOW}[⚠]${NC} $1"
    ((WARNING_CHECKS++))
    ((TOTAL_CHECKS++))
}

log_error() {
    echo -e "${RED}[✗]${NC} $1"
    ((FAILED_CHECKS++))
    ((TOTAL_CHECKS++))
}

log_section() {
    echo ""
    echo -e "${CYAN}========================================${NC}"
    echo -e "${CYAN}$1${NC}"
    echo -e "${CYAN}========================================${NC}"
}

# Function to check if command exists and optionally check version
check_command() {
    local cmd=$1
    local name=$2
    local version_cmd=$3

    if command -v "$cmd" &> /dev/null; then
        if [ -n "$version_cmd" ]; then
            local version=$(eval "$version_cmd" 2>&1 | head -1)
            log_success "$name installed: $version"
        else
            log_success "$name installed"
        fi
        return 0
    else
        log_error "$name not found"
        return 1
    fi
}

# Function to check directory exists
check_directory() {
    local dir=$1
    local name=$2

    if [ -d "$dir" ]; then
        log_success "$name directory exists: $dir"
        return 0
    else
        log_warning "$name directory not found: $dir"
        return 1
    fi
}

# Function to check file exists
check_file() {
    local file=$1
    local name=$2

    if [ -f "$file" ]; then
        log_success "$name exists: $file"
        return 0
    else
        log_warning "$name not found: $file"
        return 1
    fi
}

# Clear screen and show banner
clear
echo -e "${CYAN}"
cat << "EOF"
 __      __        _  __
 \ \    / /       (_)/ _|
  \ \  / /__  _ __ _| |_ _   _
   \ \/ / _ \| '__| |  _| | | |
    \  /  __/| |  | | | | |_| |
     \/ \___||_|  |_|_|  \__, |
                          __/ |
                         |___/

 AbeOS Development Environment Verification
EOF
echo -e "${NC}"

log_info "Starting verification..."
log_info "This will check all installed development tools"
echo ""

# =============================================================================
# System Information
# =============================================================================
log_section "System Information"

log_info "OS: $(uname -s)"
log_info "Kernel: $(uname -r)"
log_info "Architecture: $(uname -m)"

if grep -q microsoft /proc/version; then
    log_success "Running in WSL2"
else
    log_warning "Not running in WSL2"
fi

# =============================================================================
# WSL/Linux Development Tools
# =============================================================================
log_section "WSL/Linux Development Tools"

check_command "gcc" "GCC" "gcc --version | head -1"
check_command "g++" "G++" "g++ --version | head -1"
check_command "make" "Make" "make --version | head -1"
check_command "cmake" "CMake" "cmake --version | head -1"
check_command "ninja" "Ninja" "ninja --version"
check_command "pkg-config" "pkg-config" "pkg-config --version"

check_command "ffmpeg" "FFmpeg" "ffmpeg -version | head -1"
check_command "convert" "ImageMagick" "convert --version | head -1"

check_command "rg" "ripgrep" "rg --version"
check_command "fd" "fd" "fd --version"
check_command "fzf" "fzf" "fzf --version"
check_command "jq" "jq" "jq --version"
check_command "yq" "yq" "yq --version"

check_command "direnv" "direnv" "direnv --version"
check_command "bat" "bat" "bat --version | head -1"
check_command "eza" "eza" "eza --version"
check_command "zoxide" "zoxide" "zoxide --version"

# =============================================================================
# Node.js/JavaScript Stack
# =============================================================================
log_section "Node.js/JavaScript Stack"

check_directory "$HOME/.nvm" "NVM"

if [ -d "$HOME/.nvm" ]; then
    export NVM_DIR="$HOME/.nvm"
    [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
fi

check_command "node" "Node.js" "node --version"
check_command "npm" "npm" "npm --version"
check_command "pnpm" "pnpm" "pnpm --version"
check_command "yarn" "Yarn" "yarn --version"
check_command "bun" "Bun" "bun --version"

check_command "eslint" "ESLint" "eslint --version"
check_command "prettier" "Prettier" "prettier --version"
check_command "tsc" "TypeScript" "tsc --version"
check_command "ts-node" "ts-node" "ts-node --version"
check_command "nodemon" "nodemon" "nodemon --version"
check_command "turbo" "Turbo" "turbo --version"
check_command "nx" "Nx" "nx --version"

# =============================================================================
# Python/AI Toolchain
# =============================================================================
log_section "Python/AI Toolchain"

check_command "python3" "Python 3" "python3 --version"
check_command "pip3" "pip3" "pip3 --version"
check_command "pipx" "pipx" "pipx --version"
check_command "poetry" "Poetry" "poetry --version"
check_command "pipenv" "pipenv" "pipenv --version"
check_command "uv" "uv" "uv --version"

check_directory "$HOME/.pyenv" "pyenv"

check_command "black" "Black" "black --version"
check_command "ruff" "Ruff" "ruff --version"
check_command "mypy" "mypy" "mypy --version"
check_command "pytest" "pytest" "pytest --version"
check_command "ipython" "IPython" "ipython --version"
check_command "jupyter" "Jupyter" "jupyter --version"

# Check AI virtual environment
AI_VENV="$HOME/.virtualenvs/ai-tools"
if [ -d "$AI_VENV" ]; then
    log_success "AI virtual environment exists: $AI_VENV"

    # Activate and check packages
    source "$AI_VENV/bin/activate"

    if python -c "import torch" 2>/dev/null; then
        TORCH_VERSION=$(python -c "import torch; print(torch.__version__)" 2>/dev/null)
        log_success "PyTorch installed: $TORCH_VERSION"

        if python -c "import torch; assert torch.cuda.is_available()" 2>/dev/null; then
            log_success "PyTorch CUDA support available"
        else
            log_warning "PyTorch CUDA support not available (CPU-only)"
        fi
    else
        log_error "PyTorch not found in AI environment"
    fi

    if python -c "import transformers" 2>/dev/null; then
        TRANSFORMERS_VERSION=$(python -c "import transformers; print(transformers.__version__)" 2>/dev/null)
        log_success "Transformers installed: $TRANSFORMERS_VERSION"
    else
        log_error "Transformers not found in AI environment"
    fi

    deactivate
else
    log_error "AI virtual environment not found: $AI_VENV"
fi

check_command "whisper" "OpenAI Whisper" "whisper --help | head -1"

# =============================================================================
# Java/JVM Stack
# =============================================================================
log_section "Java/JVM Stack"

check_directory "$HOME/.sdkman" "SDKMAN!"

if [ -d "$HOME/.sdkman" ]; then
    source "$HOME/.sdkman/bin/sdkman-init.sh"
fi

check_command "java" "Java" "java -version 2>&1 | head -1"
check_command "javac" "Java Compiler" "javac -version 2>&1"
check_command "gradle" "Gradle" "gradle --version | head -1"
check_command "mvn" "Maven" "mvn --version | head -1"
check_command "kotlin" "Kotlin" "kotlin -version"
check_command "scala" "Scala" "scala -version 2>&1 | head -1"
check_command "sbt" "sbt" "sbt --version"

# =============================================================================
# C/C++ Toolchain
# =============================================================================
log_section "C/C++ Toolchain"

check_command "clang" "Clang" "clang --version | head -1"
check_command "clang++" "Clang++" "clang++ --version | head -1"
check_command "gdb" "GDB" "gdb --version | head -1"
check_command "lldb" "LLDB" "lldb --version | head -1"
check_command "valgrind" "Valgrind" "valgrind --version"
check_command "cppcheck" "cppcheck" "cppcheck --version"

check_directory "$HOME/vcpkg" "vcpkg"
check_command "conan" "Conan" "conan --version"
check_command "meson" "Meson" "meson --version"

# =============================================================================
# Development Tools
# =============================================================================
log_section "Development Tools"

check_command "git" "Git" "git --version"
check_command "gh" "GitHub CLI" "gh --version | head -1"
check_command "docker" "Docker" "docker --version"
check_command "docker-compose" "Docker Compose" "docker-compose --version"
check_command "code" "VS Code CLI" "code --version | head -1"

# =============================================================================
# Configuration Files
# =============================================================================
log_section "Configuration Files"

check_file "$HOME/.bashrc" "Bash configuration"
check_file "$HOME/.gitconfig" "Git configuration"

if [ -f "$HOME/.bashrc" ]; then
    if grep -q "direnv" ~/.bashrc; then
        log_success "direnv hook configured in .bashrc"
    else
        log_warning "direnv hook not found in .bashrc"
    fi

    if grep -q "nvm" ~/.bashrc; then
        log_success "NVM configured in .bashrc"
    else
        log_warning "NVM not configured in .bashrc"
    fi
fi

# =============================================================================
# Project Directories
# =============================================================================
log_section "Project Directories"

check_directory "/mnt/c/projects" "Windows projects directory"
check_directory "$HOME" "Linux home directory"

# =============================================================================
# Summary
# =============================================================================
log_section "Verification Summary"

echo ""
echo -e "${CYAN}Total checks: $TOTAL_CHECKS${NC}"
echo -e "${GREEN}Passed: $PASSED_CHECKS${NC}"
echo -e "${YELLOW}Warnings: $WARNING_CHECKS${NC}"
echo -e "${RED}Failed: $FAILED_CHECKS${NC}"
echo ""

if [ $FAILED_CHECKS -eq 0 ]; then
    if [ $WARNING_CHECKS -eq 0 ]; then
        echo -e "${GREEN}✓ All checks passed! Your development environment is fully set up.${NC}"
    else
        echo -e "${YELLOW}⚠ Environment is mostly set up, but some optional components are missing.${NC}"
    fi
else
    echo -e "${RED}✗ Some required components are missing. Please review the failed checks above.${NC}"
fi

echo ""

# Calculate success rate
SUCCESS_RATE=$(echo "scale=1; ($PASSED_CHECKS * 100) / $TOTAL_CHECKS" | bc)
echo -e "Success rate: ${CYAN}${SUCCESS_RATE}%${NC}"

echo ""
log_info "Verification complete!"
echo ""

# Exit with appropriate code
if [ $FAILED_CHECKS -gt 0 ]; then
    exit 1
else
    exit 0
fi
