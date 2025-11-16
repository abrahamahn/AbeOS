# AbeOS Complete Setup Guide

Complete step-by-step guide to set up the AbeOS development environment.

## Overview

This guide will set up a complete development environment with:
- WSL2 Ubuntu
- Node.js, Python, Java, C/C++ development stacks
- AI/ML tools (PyTorch, TensorFlow, Hugging Face)
- Modern CLI tools and productivity enhancers
- VS Code with optimized configuration
- Docker Desktop with WSL integration

**Estimated Time:** 2-3 hours
**Disk Space Required:** ~15-20 GB

---

## Phase 1: Windows Setup

### 1.1 Prerequisites Check

Open PowerShell as Administrator and verify:

```powershell
# Check Windows version (need Windows 10 2004+ or Windows 11)
winver

# Check virtualization is enabled
Get-ComputerInfo | Select-Object HyperVisorPresent, HyperVRequirementVirtualizationFirmwareEnabled
```

### 1.2 Install Windows Development Tools

```powershell
# Navigate to AbeOS directory
cd C:\AbeOS\scripts\dev-environment

# Run Windows installation script
.\Install-Windows-DevTools.ps1
```

This installs:
- WSL2
- Git, GitHub CLI
- Visual Studio Code & Build Tools
- Docker Desktop
- Windows Terminal, Oh My Posh
- Python, Node.js, Java
- CMake, Ninja, LLVM, vcpkg
- Modern CLI tools (ripgrep, fd, fzf, jq, yq)
- Nerd Fonts (Cascadia Code, JetBrains Mono)

**⚠️ RESTART YOUR COMPUTER** after this step to complete WSL2 installation.

### 1.3 Post-Restart Windows Configuration

```powershell
# Update WSL
wsl --update

# Install Ubuntu (if not already installed)
wsl --install -d Ubuntu

# Set WSL2 as default
wsl --set-default-version 2

# Set Ubuntu as default distribution
wsl --set-default Ubuntu
```

---

## Phase 2: WSL2/Ubuntu Setup

### 2.1 Initial WSL Configuration

Launch Ubuntu from Windows Terminal and complete the initial setup:

```bash
# Update system
sudo apt update && sudo apt upgrade -y

# Navigate to AbeOS scripts
cd /mnt/c/AbeOS/scripts/dev-environment
```

### 2.2 Run Complete Installation

**Option A: Install Everything (Recommended)**

```bash
./Install-All-DevTools.sh
```

This runs all installation scripts in sequence. You'll be prompted for sudo password several times.

**Option B: Install Selectively**

```bash
# 1. WSL/Linux Tools
./Install-WSL-DevTools.sh

# 2. Node.js/JavaScript
./Install-Node-DevTools.sh

# 3. Python/AI
./Install-Python-AI-DevTools.sh

# 4. Java/JVM
./Install-Java-DevTools.sh

# 5. C/C++
./Install-CPP-DevTools.sh
```

### 2.3 Reload Shell Configuration

```bash
source ~/.bashrc
```

You should see: "AbeOS Development Environment Loaded"

---

## Phase 3: Configuration

### 3.1 Set Up Project Directories

```bash
cd /mnt/c/AbeOS/scripts/dev-environment
./Setup-ProjectDirectories.sh
```

This creates:
- `/mnt/c/projects/` - Main Windows projects directory
- `~/projects/` - WSL-specific projects
- Organized subdirectories for personal, work, experiments, etc.

### 3.2 Configure VS Code

#### Install VS Code Extensions

```bash
./Install-VSCode-Extensions.sh
```

This installs 80+ extensions for:
- Remote development (WSL, SSH, Containers)
- Language support (JS/TS, Python, Java, C++, Rust, Go)
- AI assistants (GitHub Copilot, Claude)
- Git tools (GitLens)
- Productivity (Error Lens, TODO Tree, etc.)

#### Apply VS Code Settings

1. Open VS Code
2. Press `Ctrl+Shift+P` (or `Cmd+Shift+P` on Mac)
3. Type: "Preferences: Open User Settings (JSON)"
4. Copy contents from: `/mnt/c/AbeOS/configs/vscode/settings.json`
5. Paste into your settings

Or via command line:
```bash
# Backup existing settings
cp ~/.config/Code/User/settings.json ~/.config/Code/User/settings.json.backup

# Copy AbeOS settings
cp /mnt/c/AbeOS/configs/vscode/settings.json ~/.config/Code/User/settings.json
```

### 3.3 Configure Git

```bash
# Set your identity
git config --global user.name "Your Name"
git config --global user.email "your.email@example.com"

# Set default branch
git config --global init.defaultBranch main

# Configure line endings
git config --global core.autocrlf input

# Enable credential helper
git config --global credential.helper store

# Optional: Set up commit signing (if using GPG/YubiKey)
# git config --global commit.gpgsign true
# git config --global user.signingkey YOUR_KEY_ID
```

### 3.4 Configure GitHub CLI

```bash
# Authenticate with GitHub
gh auth login

# Follow the prompts to authenticate
# Choose: GitHub.com > HTTPS > Login with web browser

# Verify authentication
gh auth status
```

### 3.5 Configure Docker

1. Open Docker Desktop
2. Go to Settings > Resources > WSL Integration
3. Enable integration with Ubuntu
4. Click "Apply & Restart"

Test Docker:
```bash
docker --version
docker run hello-world
```

---

## Phase 4: Verification

### 4.1 Run Verification Script

```bash
cd /mnt/c/AbeOS/scripts/dev-environment
./Verify-Installation.sh
```

This checks:
- All installed development tools
- Version numbers
- Configuration files
- Virtual environments
- CUDA availability (if NVIDIA GPU)

**Expected Success Rate:** 85-100%

### 4.2 Manual Verification

Test key components:

```bash
# System info
sysinfo

# Node.js
node --version
npm --version
pnpm --version

# Python
python3 --version
pip3 --version
poetry --version

# Activate AI environment
source ~/.virtualenvs/activate-ai.sh
python -c 'import torch; print(f"PyTorch {torch.__version__}")'
python -c 'import transformers; print(f"Transformers {transformers.__version__}")'
deactivate

# Java
java -version
gradle --version
mvn --version

# C/C++
gcc --version
clang --version
cmake --version

# Tools
git --version
docker --version
gh --version
code --version
```

---

## Phase 5: Post-Installation

### 5.1 Update .bashrc

Ensure AbeOS environment is loaded:

```bash
# Add to ~/.bashrc if not already present
echo 'source /mnt/c/AbeOS/configs/core/terminal/environment.sh' >> ~/.bashrc

# Reload
source ~/.bashrc
```

### 5.2 Create Local Secrets File

```bash
# Create .env.local for API keys (not in version control)
touch ~/.env.local
chmod 600 ~/.env.local

# Add your secrets
nano ~/.env.local
```

Example `~/.env.local`:
```bash
export OPENAI_API_KEY="sk-..."
export ANTHROPIC_API_KEY="sk-ant-..."
export HUGGINGFACE_TOKEN="hf_..."
export GITHUB_TOKEN="ghp_..."
export NPM_TOKEN="npm_..."
```

### 5.3 Test Project Creation

```bash
# Navigate to projects
cdproj

# Create a test Node.js project
new-node test-node-app
cd test-node-app
npm install express
node -e "console.log('Node.js works!')"

# Create a test Python project
cdproj
new-python test-python-app
cd test-python-app
pip install requests
python -c "print('Python works!')"
```

---

## Phase 6: Optional Enhancements

### 6.1 Install CUDA (for NVIDIA GPU)

If you have an NVIDIA GPU (like RTX 4070):

**Windows:**
1. Download CUDA Toolkit from NVIDIA
2. Download cuDNN
3. Install both

**WSL:**
```bash
# Follow NVIDIA's WSL-Ubuntu CUDA installation guide
# https://docs.nvidia.com/cuda/wsl-user-guide/index.html

# Reinstall PyTorch with CUDA support
source ~/.virtualenvs/activate-ai.sh
pip install --upgrade torch torchvision torchaudio --index-url https://download.pytorch.org/whl/cu121

# Test CUDA
python -c "import torch; print(f'CUDA available: {torch.cuda.is_available()}')"
```

### 6.2 Set Up Android Development

```bash
# Install Android Studio (Windows)
winget install Google.AndroidStudio

# Or install command-line tools only
# Download from: https://developer.android.com/studio#command-tools
```

### 6.3 Clone Your Repositories

```bash
# Navigate to projects
cdproj

# Clone your key repos
gh repo clone username/repo1 personal/web/repo1
gh repo clone username/repo2 personal/ai/repo2

# Or use git directly
git clone git@github.com:username/repo.git
```

### 6.4 Set Up Database Tools

**PostgreSQL:**
```bash
sudo apt install postgresql postgresql-contrib
sudo service postgresql start
```

**MySQL:**
```bash
sudo apt install mysql-server
sudo service mysql start
```

**MongoDB:**
```bash
# Install MongoDB Community Edition for Ubuntu
# Follow: https://docs.mongodb.com/manual/tutorial/install-mongodb-on-ubuntu/
```

**Redis:**
```bash
sudo apt install redis-server
sudo service redis-server start
```

---

## Troubleshooting

### WSL2 Issues

**WSL not starting:**
```powershell
# Reset WSL
wsl --shutdown
wsl --unregister Ubuntu
wsl --install -d Ubuntu
```

**Slow file access:**
- Work in WSL filesystem (`~/`) instead of Windows (`/mnt/c/`)
- Use Dev Drive (ReFS) on Windows for better performance

### Node.js Issues

**NVM not found:**
```bash
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
```

**Wrong Node version:**
```bash
nvm use 20
nvm alias default 20
```

### Python Issues

**Module not found:**
```bash
# Ensure you're in the correct virtual environment
source ~/.virtualenvs/activate-ai.sh
```

**CUDA not available in PyTorch:**
- Install NVIDIA drivers
- Install CUDA Toolkit
- Reinstall PyTorch with CUDA support

### Permission Issues

**Scripts not executable:**
```bash
chmod +x /mnt/c/AbeOS/scripts/dev-environment/*.sh
```

**Sudo password:**
- WSL requires Ubuntu password for sudo commands
- Set password: `sudo passwd $USER`

---

## Maintenance

### Keep Everything Updated

```bash
# Run the update-all function
update-all

# Or manually:
sudo apt update && sudo apt upgrade -y
npm update -g
pipx upgrade-all
sdk update && sdk upgrade
rustup update
```

### Backup Configuration

```bash
# Backup important configs
cp ~/.bashrc ~/bashrc.backup
cp ~/.gitconfig ~/.gitconfig.backup

# AbeOS configs are already in version control at:
# /mnt/c/AbeOS/configs/
```

---

## Quick Reference

### Essential Commands

```bash
# Navigation
cdproj          # Go to projects directory
cdabe           # Go to AbeOS directory
mcl             # Go to projects and list

# Version Management
nvm use 20      # Switch Node version
sdk use java 21 # Switch Java version
pyenv global 3.12 # Switch Python version

# Project Creation
new-node <name>    # Create Node.js project
new-python <name>  # Create Python project

# Environment
activate-ai     # Activate AI/ML Python environment
sysinfo        # Show system information

# Updates
update-all     # Update all tools
```

### Useful Aliases

```bash
# Git
gs    # git status
ga    # git add
gc    # git commit
gp    # git push
gl    # git pull

# Docker
d     # docker
dc    # docker-compose
dps   # docker ps

# Python
py    # python3

# Node
nr    # npm run
ni    # npm install
```

---

## Next Steps

1. **Start a Project:** Create your first project with `new-node` or `new-python`
2. **Learn the Tools:** Explore the installed tools and their features
3. **Customize:** Adjust configs in `/mnt/c/AbeOS/configs/` to your preferences
4. **Build Something:** Put your new environment to work!

---

## Support

- **AbeOS Documentation:** `/mnt/c/AbeOS/docs/`
- **Scripts README:** `/mnt/c/AbeOS/scripts/dev-environment/README.md`
- **Environment Variables:** `/mnt/c/AbeOS/configs/core/terminal/environment-variables.md`

---

**Setup Version:** 1.0.0
**Last Updated:** 2025-01-15
**Maintainer:** AbeOS Team
