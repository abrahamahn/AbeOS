#!/bin/bash
# =============================================================================
# Install-Python-AI-DevTools.sh
# Python/AI Development Toolchain Installation Script
# =============================================================================

set -e  # Exit on error

echo "=================================================="
echo "Python/AI Development Toolchain Installation"
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

# Ensure Python 3.11+ is installed
log_info "Checking Python version..."
PYTHON_VERSION=$(python3 --version | cut -d' ' -f2 | cut -d'.' -f1,2)
log_info "Found Python $PYTHON_VERSION"

if [ ! -x "$(command -v python3)" ]; then
    log_error "Python3 not found! Installing..."
    sudo apt install -y python3 python3-dev python3-pip python3-venv
fi

# Install system Python packages
log_info "Installing Python development packages..."
sudo apt install -y \
    python3-pip \
    python3-dev \
    python3-venv \
    python3-setuptools \
    python3-wheel

log_success "Python packages installed"

# Ensure ~/.local/bin is in PATH (needed for various tools)
if ! grep -q ".local/bin" ~/.bashrc; then
    echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.bashrc
fi
export PATH="$HOME/.local/bin:$PATH"

# Removed bloat: pipx, poetry, pipenv

# Install uv (fast Python package installer)
log_info "Installing uv..."
if ! command -v uv &> /dev/null; then
    curl -LsSf https://astral.sh/uv/install.sh | sh
    log_success "uv installed"
else
    log_info "uv already installed"
fi

# Install pyenv for Python version management
log_info "Installing pyenv..."
if [ ! -d "$HOME/.pyenv" ]; then
    curl https://pyenv.run | bash

    # Add pyenv to bashrc
    cat >> ~/.bashrc << 'EOF'

# Pyenv configuration
export PYENV_ROOT="$HOME/.pyenv"
[[ -d $PYENV_ROOT/bin ]] && export PATH="$PYENV_ROOT/bin:$PATH"
eval "$(pyenv init -)"
EOF

    log_success "pyenv installed"
else
    log_info "pyenv already installed"
fi

# Note: Python development tools (black, ruff, mypy, pytest, etc.)
# should be installed per-project using virtual environments or uv
log_info "Python development tools should be installed per-project"

# Install AI/ML Python packages
log_info "Installing AI/ML Python packages..."

# Create a virtual environment for AI tools
AI_VENV="$HOME/.virtualenvs/ai-tools"
if [ ! -d "$AI_VENV" ]; then
    mkdir -p "$HOME/.virtualenvs"
    python3 -m venv "$AI_VENV"
fi

source "$AI_VENV/bin/activate"

# Upgrade pip
pip install --upgrade pip setuptools wheel

# Install AI/ML packages
log_info "Installing core AI/ML libraries..."
pip install --upgrade \
    numpy \
    pandas \
    matplotlib \
    scipy \
    scikit-learn \
    pillow \
    opencv-python \
    tqdm \
    requests
# Removed bloat: seaborn (can be installed per-project if needed)

# Install Hugging Face ecosystem
log_info "Installing Hugging Face tools..."
pip install --upgrade \
    transformers \
    datasets \
    tokenizers \
    accelerate \
    "huggingface-hub[cli]"

# Install OpenAI Whisper
log_info "Installing OpenAI Whisper..."
pip install --upgrade openai-whisper

# Install other AI tools
log_info "Installing additional AI tools..."
pip install --upgrade \
    sentencepiece \
    bitsandbytes \
    onnxruntime \
    optimum

deactivate

log_success "AI/ML packages installed in virtual environment: $AI_VENV"

# Check for CUDA availability
log_info "Checking for CUDA availability..."
if command -v nvidia-smi &> /dev/null; then
    log_info "NVIDIA GPU detected"
    CUDA_AVAILABLE=true

    # Get CUDA version if available
    if [ -d "/usr/local/cuda" ]; then
        CUDA_VERSION=$(nvcc --version 2>/dev/null | grep "release" | awk '{print $6}' | cut -d',' -f1 || echo "unknown")
        log_info "CUDA version: $CUDA_VERSION"
    else
        log_warning "CUDA toolkit not found in /usr/local/cuda"
        log_info "PyTorch installation will use CPU version"
        CUDA_AVAILABLE=false
    fi
else
    log_warning "No NVIDIA GPU detected. Installing CPU versions of ML frameworks."
    CUDA_AVAILABLE=false
fi

# Install PyTorch
source "$AI_VENV/bin/activate"

log_info "Installing PyTorch..."
if [ "$CUDA_AVAILABLE" = true ]; then
    # Install CUDA version
    pip install --upgrade torch torchvision torchaudio --index-url https://download.pytorch.org/whl/cu121
    log_success "PyTorch with CUDA support installed"
else
    # Install CPU version
    pip install --upgrade torch torchvision torchaudio --index-url https://download.pytorch.org/whl/cpu
    log_success "PyTorch (CPU version) installed"
fi

# Install TensorFlow (if needed)
log_info "Installing TensorFlow..."
pip install --upgrade tensorflow
log_success "TensorFlow installed"

deactivate

# Create activation helper script
cat > "$HOME/.virtualenvs/activate-ai.sh" << 'EOF'
#!/bin/bash
source "$HOME/.virtualenvs/ai-tools/bin/activate"
echo "AI/ML virtual environment activated"
echo "Python: $(python --version)"
echo "PyTorch: $(python -c 'import torch; print(torch.__version__)' 2>/dev/null || echo 'not found')"
EOF

chmod +x "$HOME/.virtualenvs/activate-ai.sh"

echo ""
echo "=================================================="
log_success "Python/AI toolchain installation complete!"
echo "=================================================="
echo ""
echo "Installed components:"
echo "  ✓ uv (fast Python package installer)"
echo "  ✓ pyenv (Python version manager)"
echo "  ✓ AI/ML frameworks (PyTorch, TensorFlow)"
echo "  ✓ Hugging Face ecosystem (transformers, datasets, etc.)"
echo "  ✓ OpenAI Whisper"
echo "  ✓ Additional ML tools (onnxruntime, bitsandbytes, etc.)"
echo ""
echo "AI/ML virtual environment: $AI_VENV"
echo "To activate: source $HOME/.virtualenvs/activate-ai.sh"
echo ""
echo "Next steps:"
echo "  1. Restart your shell or run: source ~/.bashrc"
echo "  2. Test with: python3 --version"
echo "  3. Activate AI env: source ~/.virtualenvs/activate-ai.sh"
echo "  4. Test PyTorch: python -c 'import torch; print(torch.__version__)'"
echo ""
echo "Note: Install per-project tools (black, ruff, pytest, etc.) using uv or venv"
echo ""
if [ "$CUDA_AVAILABLE" = false ]; then
    log_warning "CUDA was not detected. If you have an NVIDIA GPU:"
    echo "  1. Install CUDA Toolkit from NVIDIA"
    echo "  2. Re-run this script to install GPU-accelerated packages"
fi
echo ""
