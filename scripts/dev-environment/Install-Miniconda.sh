#!/bin/bash
# =============================================================================
# Install-Miniconda.sh
# Miniconda3 Installation for ML Environment Management
# =============================================================================

set -e

echo "=================================================="
echo "Miniconda3 Installation"
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

# Check if Miniconda is already installed
if [ -d "$HOME/miniconda3" ]; then
    log_warning "Miniconda3 already installed at $HOME/miniconda3"
    read -p "Do you want to reinstall? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        log_info "Skipping installation"
        exit 0
    fi
fi

# Download Miniconda installer
log_info "Downloading Miniconda3 installer..."
MINICONDA_URL="https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh"
INSTALLER="/tmp/miniconda.sh"

wget -O "$INSTALLER" "$MINICONDA_URL"
log_success "Download complete"

# Install Miniconda
log_info "Installing Miniconda3..."
bash "$INSTALLER" -b -u -p "$HOME/miniconda3"
rm "$INSTALLER"
log_success "Miniconda3 installed"

# Initialize conda
log_info "Initializing conda..."
"$HOME/miniconda3/bin/conda" init bash
source "$HOME/.bashrc"
log_success "Conda initialized"

# Update conda
log_info "Updating conda..."
conda update -n base -c defaults conda -y
log_success "Conda updated"

# Configure conda
log_info "Configuring conda..."
conda config --set auto_activate_base false
conda config --set channel_priority strict
log_success "Conda configured"

# Create base ML environment
log_info "Creating ML environment (ml-base)..."
conda create -n ml-base python=3.12 -y

# Activate and install packages
source "$HOME/miniconda3/bin/activate" ml-base

conda install -y \
    numpy \
    pandas \
    matplotlib \
    seaborn \
    scikit-learn \
    jupyter \
    jupyterlab \
    ipython

# Install PyTorch
log_info "Installing PyTorch..."
if command -v nvidia-smi &> /dev/null; then
    log_info "NVIDIA GPU detected - installing CUDA version"
    conda install -y pytorch torchvision torchaudio pytorch-cuda=12.1 -c pytorch -c nvidia
else
    log_info "No GPU detected - installing CPU version"
    conda install -y pytorch torchvision torchaudio cpuonly -c pytorch
fi

# Install additional ML packages
conda install -y \
    transformers \
    datasets \
    tokenizers \
    accelerate \
    -c conda-forge

log_success "ML environment created"
conda deactivate

# Create activation helper
cat > "$HOME/.conda_activate_ml.sh" << 'EOF'
#!/bin/bash
source "$HOME/miniconda3/bin/activate" ml-base
echo "ML environment activated (Conda)"
echo "Python: $(python --version)"
echo "PyTorch: $(python -c 'import torch; print(torch.__version__)' 2>/dev/null || echo 'not found')"
EOF

chmod +x "$HOME/.conda_activate_ml.sh"

echo ""
echo "=================================================="
log_success "Miniconda3 installation complete!"
echo "=================================================="
echo ""
echo "Installation summary:"
echo "  ✓ Miniconda3 installed to: $HOME/miniconda3"
echo "  ✓ Base environment: ml-base (Python 3.12)"
echo "  ✓ Packages: numpy, pandas, scikit-learn, matplotlib"
echo "  ✓ PyTorch with CUDA support (if GPU available)"
echo "  ✓ Transformers ecosystem"
echo ""
echo "Usage:"
echo "  conda activate ml-base           # Activate ML environment"
echo "  source ~/.conda_activate_ml.sh   # Quick activation helper"
echo "  conda deactivate                 # Deactivate environment"
echo ""
echo "Conda commands:"
echo "  conda env list                   # List environments"
echo "  conda create -n myenv python=3.12  # Create new environment"
echo "  conda install package-name       # Install package"
echo "  conda update --all               # Update all packages"
echo ""
echo "Note: Restart your shell or run: source ~/.bashrc"
echo ""
