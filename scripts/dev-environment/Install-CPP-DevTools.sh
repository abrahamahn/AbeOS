#!/bin/bash
# =============================================================================
# Install-CPP-DevTools.sh
# C/C++ Development Toolchain Installation Script
# =============================================================================

set -e  # Exit on error

echo "=================================================="
echo "C/C++ Development Toolchain Installation"
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

# Install GCC/G++ and build tools
log_info "Installing GCC/G++ toolchain..."
sudo apt install -y \
    gcc \
    g++ \
    gdb \
    make \
    cmake \
    ninja-build \
    ccache

log_success "GCC/G++ toolchain installed"

# Install Clang/LLVM
log_info "Installing Clang/LLVM..."
sudo apt install -y \
    clang \
    lldb \
    lld \
    clang-format \
    clang-tidy \
    libc++-dev \
    libc++abi-dev

log_success "Clang/LLVM installed"

# Install debugging and profiling tools
log_info "Installing debugging and profiling tools..."
sudo apt install -y \
    valgrind \
    gdb \
    cgdb \
    strace \
    ltrace

log_success "Debugging tools installed"

# Install static analysis tools
log_info "Installing static analysis tools..."
sudo apt install -y \
    cppcheck \
    clang-tidy

log_success "Static analysis tools installed"

# Install additional development libraries
log_info "Installing development libraries..."
sudo apt install -y \
    libboost-all-dev \
    libeigen3-dev \
    libssl-dev \
    libcurl4-openssl-dev \
    libsqlite3-dev \
    libpq-dev \
    libmysqlclient-dev

log_success "Development libraries installed"

# Install vcpkg (C++ package manager)
log_info "Installing vcpkg..."
VCPKG_DIR="$HOME/vcpkg"
if [ ! -d "$VCPKG_DIR" ]; then
    git clone https://github.com/Microsoft/vcpkg.git "$VCPKG_DIR"
    cd "$VCPKG_DIR"
    ./bootstrap-vcpkg.sh

    # Add vcpkg to PATH
    if ! grep -q "vcpkg" ~/.bashrc; then
        echo '' >> ~/.bashrc
        echo '# vcpkg' >> ~/.bashrc
        echo 'export VCPKG_ROOT="$HOME/vcpkg"' >> ~/.bashrc
        echo 'export PATH="$VCPKG_ROOT:$PATH"' >> ~/.bashrc
    fi

    log_success "vcpkg installed"
else
    log_info "vcpkg already installed"
fi

# Install Conan (C++ package manager)
log_info "Installing Conan..."
if ! command -v conan &> /dev/null; then
    pip3 install --user conan
    log_success "Conan installed"
else
    log_info "Conan already installed"
fi

# Install meson (build system)
log_info "Installing Meson..."
pip3 install --user meson
log_success "Meson installed"

# Display installed versions
echo ""
log_info "Installed versions:"
gcc --version | head -1
g++ --version | head -1
clang --version | head -1
cmake --version | head -1
gdb --version | head -1

echo ""
echo "=================================================="
log_success "C/C++ toolchain installation complete!"
echo "=================================================="
echo ""
echo "Installed components:"
echo "  ✓ GCC/G++ (GNU Compiler Collection)"
echo "  ✓ Clang/LLVM (alternative compiler)"
echo "  ✓ Build tools (make, cmake, ninja, ccache)"
echo "  ✓ Debuggers (gdb, lldb, cgdb)"
echo "  ✓ Profiling tools (valgrind, strace, ltrace)"
echo "  ✓ Static analysis (cppcheck, clang-tidy)"
echo "  ✓ Package managers (vcpkg, Conan)"
echo "  ✓ Build systems (Meson)"
echo "  ✓ Development libraries (Boost, Eigen, etc.)"
echo ""
echo "Next steps:"
echo "  1. Restart your shell or run: source ~/.bashrc"
echo "  2. Test with: gcc --version && clang --version"
echo "  3. vcpkg search <package> to find C++ libraries"
echo "  4. Create C++ project with CMake or Meson"
echo ""
