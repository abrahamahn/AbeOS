# AbeOS Development Environment Setup Scripts

Comprehensive development environment installation and configuration scripts for Windows + WSL2.

## Overview

This directory contains automated installation scripts for setting up a complete development environment across:

- **Windows** (PowerShell scripts)
- **WSL2/Linux** (Bash scripts)

## Scripts

### Windows (PowerShell)

#### `Install-Windows-DevTools.ps1`
Installs Windows-specific development tools via winget and Chocolatey.

**Requires:** Administrator privileges

**Installs:**
- WSL2
- Visual Studio Code & Build Tools
- Git, GitHub CLI
- Docker Desktop
- Windows Terminal, Oh My Posh
- Python, Node.js, Java
- CMake, Ninja, LLVM
- vcpkg, Rust, Go
- PowerToys, modern CLI tools
- Nerd Fonts

**Usage:**
```powershell
# Run as Administrator
.\Install-Windows-DevTools.ps1
```

### WSL2/Linux (Bash)

#### `Install-All-DevTools.sh`
Master orchestrator that runs all Linux installation scripts in sequence.

**Usage:**
```bash
bash Install-All-DevTools.sh
```

#### `Install-WSL-DevTools.sh`
Installs WSL2/Linux development tools and utilities.

**Installs:**
- Build essentials (gcc, g++, make, cmake, ninja)
- Development libraries (ssl, zlib, readline, etc.)
- Multimedia tools (FFmpeg, ImageMagick)
- Modern CLI tools (ripgrep, fd, fzf, jq, yq)
- Productivity tools (direnv, bat, eza, zoxide)

**Usage:**
```bash
bash Install-WSL-DevTools.sh
```

#### `Install-Node-DevTools.sh`
Installs Node.js/JavaScript development ecosystem.

**Installs:**
- NVM (Node Version Manager)
- Node.js v20 (LTS) and v24
- Corepack (pnpm/yarn management)
- Global npm packages (eslint, prettier, typescript, etc.)
- Bun runtime
- Nx, Turbo (monorepo tools)

**Usage:**
```bash
bash Install-Node-DevTools.sh
```

#### `Install-Python-AI-DevTools.sh`
Installs Python and AI/ML development toolchain.

**Installs:**
- pipx, Poetry, pipenv, uv
- pyenv (Python version manager)
- Development tools (black, ruff, mypy, pytest, jupyter)
- AI/ML frameworks (PyTorch, TensorFlow)
- Hugging Face ecosystem
- OpenAI Whisper
- Additional ML tools

**Creates:**
- Virtual environment at `~/.virtualenvs/ai-tools`
- Activation script at `~/.virtualenvs/activate-ai.sh`

**Usage:**
```bash
bash Install-Python-AI-DevTools.sh
```

#### `Install-Java-DevTools.sh`
Installs Java/JVM development stack.

**Installs:**
- SDKMAN! (Java version manager)
- Java 21 (Temurin) - default
- Java 17, 11 (LTS versions)
- Gradle, Maven
- Kotlin, Scala, sbt

**Usage:**
```bash
bash Install-Java-DevTools.sh
```

#### `Install-CPP-DevTools.sh`
Installs C/C++ development toolchain.

**Installs:**
- GCC/G++, Clang/LLVM
- Build tools (make, cmake, ninja, ccache)
- Debuggers (gdb, lldb, cgdb)
- Profiling tools (valgrind, strace, ltrace)
- Static analysis (cppcheck, clang-tidy)
- Package managers (vcpkg, Conan)
- Development libraries (Boost, Eigen, etc.)

**Usage:**
```bash
bash Install-CPP-DevTools.sh
```

#### `Verify-Installation.sh`
Comprehensive verification script that checks all installed tools.

**Features:**
- Checks 80+ development tools
- Verifies versions
- Tests Python/AI environment
- Generates success rate report
- Color-coded output

**Usage:**
```bash
bash Verify-Installation.sh
```

## Installation Flow

### Recommended: Complete Setup

1. **On Windows (as Administrator):**
   ```powershell
   cd C:\AbeOS\scripts\dev-environment
   .\Install-Windows-DevTools.ps1
   ```

2. **Restart your computer** to complete WSL2 installation

3. **In WSL2:**
   ```bash
   cd /mnt/c/AbeOS/scripts/dev-environment
   bash Install-All-DevTools.sh
   ```

4. **Verify installation:**
   ```bash
   bash Verify-Installation.sh
   ```

### Selective Installation

Install only specific stacks:

```bash
# Just Node.js
bash Install-Node-DevTools.sh

# Just Python/AI
bash Install-Python-AI-DevTools.sh

# Just Java
bash Install-Java-DevTools.sh

# Just C++
bash Install-CPP-DevTools.sh
```

## Post-Installation

### Reload Shell Configuration

After installation, reload your shell:

```bash
source ~/.bashrc
```

Or restart your terminal.

### Activate AI/ML Environment

To use AI/ML tools:

```bash
source ~/.virtualenvs/activate-ai.sh

# Test PyTorch
python -c 'import torch; print(torch.__version__)'
```

### Switch Node Versions

```bash
nvm use 20     # Use Node 20
nvm use 24     # Use Node 24
nvm list       # List installed versions
```

### Switch Java Versions

```bash
sdk use java 21.0.1-tem    # Use Java 21
sdk use java 17.0.9-tem    # Use Java 17
sdk list java              # List installed versions
```

## Environment Variables

Key environment variables set by these scripts:

### Node.js
- `NVM_DIR=$HOME/.nvm`
- `BUN_INSTALL=$HOME/.bun`

### Python
- `PYENV_ROOT=$HOME/.pyenv`

### Java
- `SDKMAN_DIR=$HOME/.sdkman`

### C++
- `VCPKG_ROOT=$HOME/vcpkg` (Linux)
- `VCPKG_ROOT=C:\tools\vcpkg` (Windows)

## Directory Structure

```
C:\projects\              # Windows project directory
/mnt/c/projects/          # WSL access to Windows projects
~/.virtualenvs/           # Python virtual environments
~/.nvm/                   # Node versions
~/.sdkman/                # Java versions
~/.pyenv/                 # Python versions
~/vcpkg/                  # C++ packages (Linux)
C:\tools\vcpkg\           # C++ packages (Windows)
```

## Troubleshooting

### WSL2 Installation Issues

If WSL2 fails to install:
1. Ensure virtualization is enabled in BIOS
2. Run: `dism.exe /online /enable-feature /featurename:Microsoft-Windows-Subsystem-Linux /all /norestart`
3. Run: `dism.exe /online /enable-feature /featurename:VirtualMachinePlatform /all /norestart`
4. Restart computer
5. Run: `wsl --set-default-version 2`

### NVM Not Found

If NVM is not found after installation:
```bash
source ~/.bashrc
# or
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
```

### CUDA Support for PyTorch

If you have an NVIDIA GPU but PyTorch shows CPU-only:
1. Install CUDA Toolkit from NVIDIA
2. Install cuDNN
3. Re-run: `bash Install-Python-AI-DevTools.sh`

### Permission Denied

If scripts fail with permission errors:
```bash
chmod +x *.sh
```

## Verification Checklist

After installation, verify:

- [ ] `node --version` shows Node.js version
- [ ] `python3 --version` shows Python 3.11+
- [ ] `java -version` shows Java 21
- [ ] `gcc --version` shows GCC
- [ ] `docker --version` shows Docker
- [ ] `git --version` shows Git
- [ ] `code --version` shows VS Code

Run full verification:
```bash
bash Verify-Installation.sh
```

## Customization

### Adding Custom Packages

Edit the respective installation script and add to the package array:

**Node.js packages:** Edit `GLOBAL_PACKAGES` in `Install-Node-DevTools.sh`

**Python tools:** Edit `PYTHON_TOOLS` in `Install-Python-AI-DevTools.sh`

**Windows packages:** Edit `$WingetPackages` or `$ChocoPackages` in `Install-Windows-DevTools.ps1`

### Skipping Components

Comment out sections in the scripts you don't need:

```bash
# Comment out Java installation
# run_install "Install-Java-DevTools.sh"
```

## Maintenance

### Update All Tools

**Node.js:**
```bash
nvm install --lts --latest-npm
npm update -g
```

**Python:**
```bash
pipx upgrade-all
poetry self update
```

**Java:**
```bash
sdk update
sdk upgrade
```

**System packages:**
```bash
sudo apt update && sudo apt upgrade -y
```

**Windows:**
```powershell
winget upgrade --all
choco upgrade all -y
```

## Support

For issues or questions:
1. Check the verification script output
2. Review individual script logs
3. Ensure all prerequisites are met
4. Check environment variables

## License

Part of the AbeOS project.

---

**Last Updated:** 2025-01-15
**Version:** 1.0.0
**Maintainer:** AbeOS Team
