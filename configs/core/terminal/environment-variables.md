# AbeOS Environment Variables

This document lists all environment variables used in the AbeOS development environment.

## Node.js / JavaScript

### NVM (Node Version Manager)
```bash
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"
```

### Bun
```bash
export BUN_INSTALL="$HOME/.bun"
export PATH="$BUN_INSTALL/bin:$PATH"
```

### Corepack
```bash
# Enable corepack for pnpm/yarn version management
# Run: corepack enable
```

### NPM Configuration
```bash
# Optional: Set NPM auth token for private registries
export NPM_TOKEN="your-token-here"

# Optional: Configure NPM registry
# npm config set registry https://registry.npmjs.org/
```

## Python / AI

### Pyenv
```bash
export PYENV_ROOT="$HOME/.pyenv"
[[ -d $PYENV_ROOT/bin ]] && export PATH="$PYENV_ROOT/bin:$PATH"
eval "$(pyenv init -)"
```

### UV (Fast Python Package Installer)
```bash
export UV_USE_PYTHON="python3.12"
```

### Poetry
```bash
export PATH="$HOME/.local/bin:$PATH"
```

### CUDA (NVIDIA GPU)
```bash
# CUDA Toolkit path (if installed)
export CUDA_PATH="/usr/local/cuda"
export CUDA_HOME="/usr/local/cuda"
export PATH="/usr/local/cuda/bin:$PATH"
export LD_LIBRARY_PATH="/usr/local/cuda/lib64:$LD_LIBRARY_PATH"
```

### cuDNN
```bash
export CUDNN_PATH="/usr/local/cuda"
```

### TensorRT
```bash
export TENSORRT_PATH="/usr/local/TensorRT"
export LD_LIBRARY_PATH="$TENSORRT_PATH/lib:$LD_LIBRARY_PATH"
```

### PyTorch
```bash
# Force PyTorch to use specific CUDA version
export TORCH_CUDA_ARCH_LIST="8.6"  # For RTX 4070
```

### Hugging Face
```bash
# Hugging Face token for model downloads
export HUGGINGFACE_TOKEN="your-token-here"
export HF_HOME="$HOME/.cache/huggingface"
```

### OpenAI
```bash
export OPENAI_API_KEY="your-api-key-here"
```

### Anthropic
```bash
export ANTHROPIC_API_KEY="your-api-key-here"
```

## Java / JVM

### SDKMAN!
```bash
export SDKMAN_DIR="$HOME/.sdkman"
[[ -s "$HOME/.sdkman/bin/sdkman-init.sh" ]] && source "$HOME/.sdkman/bin/sdkman-init.sh"
```

### Java Home (auto-managed by SDKMAN)
```bash
# SDKMAN manages JAVA_HOME automatically
# Manual override if needed:
# export JAVA_HOME="$HOME/.sdkman/candidates/java/current"
```

### Android SDK (Optional)
```bash
export ANDROID_HOME="$HOME/Android/Sdk"
export PATH="$ANDROID_HOME/emulator:$PATH"
export PATH="$ANDROID_HOME/tools:$PATH"
export PATH="$ANDROID_HOME/tools/bin:$PATH"
export PATH="$ANDROID_HOME/platform-tools:$PATH"
```

## C / C++

### vcpkg
```bash
export VCPKG_ROOT="$HOME/vcpkg"
export PATH="$VCPKG_ROOT:$PATH"
```

### CMake
```bash
# vcpkg CMake toolchain
export CMAKE_TOOLCHAIN_FILE="$VCPKG_ROOT/scripts/buildsystems/vcpkg.cmake"
```

### Compiler Preferences
```bash
# Prefer Clang over GCC
export CC=clang
export CXX=clang++

# Or use GCC
# export CC=gcc
# export CXX=g++
```

## Rust

```bash
export PATH="$HOME/.cargo/bin:$PATH"
```

## Go

```bash
export GOPATH="$HOME/go"
export PATH="$GOPATH/bin:$PATH"
```

## Development Tools

### direnv
```bash
eval "$(direnv hook bash)"
```

### zoxide (smarter cd)
```bash
eval "$(zoxide init bash)"
```

### fzf (fuzzy finder)
```bash
[ -f ~/.fzf.bash ] && source ~/.fzf.bash
```

## Oh My Posh

```bash
# Oh My Posh theme
eval "$(oh-my-posh init bash --config /mnt/c/AbeOS/configs/core/terminal/abe.omp.json)"
```

## Docker

### Docker Host (for WSL)
```bash
export DOCKER_HOST=unix:///var/run/docker.sock
```

## Project Directories

```bash
# Helper aliases for project navigation
export PROJECTS_DIR="/mnt/c/projects"
export ABEOS_DIR="/mnt/c/AbeOS"

# Aliases
alias cdproj='cd $PROJECTS_DIR'
alias cdabe='cd $ABEOS_DIR'
alias mcl='cd $PROJECTS_DIR && ls -la'
```

## VS Code

```bash
# VS Code remote server
export VSCODE_WSL_EXT_LOCATION="/mnt/c/Users/abe/.vscode/extensions"
```

## GitHub

### GitHub CLI
```bash
# GitHub token (managed by gh auth)
# export GITHUB_TOKEN="your-token-here"
```

### Git Configuration
```bash
# Git editor
export GIT_EDITOR=vim

# GPG signing
export GPG_TTY=$(tty)
```

## SSH

### YubiKey
```bash
# YubiKey SSH authentication
export SSH_AUTH_SOCK=$(gpgconf --list-dirs agent-ssh-socket)
```

## Performance

### Ccache (C++ compilation cache)
```bash
export USE_CCACHE=1
export CCACHE_DIR="$HOME/.ccache"
```

## Windows Interop (WSL Specific)

```bash
# Access Windows commands from WSL
export PATH="$PATH:/mnt/c/Windows/System32"
export PATH="$PATH:/mnt/c/Program Files/Git/cmd"
export PATH="$PATH:/mnt/c/Program Files/Docker/Docker/resources/bin"
```

## Complete .bashrc Integration

Add this to your `~/.bashrc`:

```bash
# Source AbeOS environment variables
if [ -f "/mnt/c/AbeOS/configs/core/terminal/environment.sh" ]; then
    source "/mnt/c/AbeOS/configs/core/terminal/environment.sh"
fi
```

## Complete Environment Setup Script

Location: `/mnt/c/AbeOS/configs/core/terminal/environment.sh`

This file should contain all non-secret environment variables and be sourced from `.bashrc`.

## Security Notes

**Never commit secrets to version control!**

For sensitive tokens and API keys:
1. Create a `.env.local` file in your home directory
2. Add it to `.gitignore`
3. Source it from `.bashrc`:

```bash
# Load local secrets (not in version control)
if [ -f "$HOME/.env.local" ]; then
    source "$HOME/.env.local"
fi
```

Example `~/.env.local`:
```bash
export OPENAI_API_KEY="sk-..."
export ANTHROPIC_API_KEY="sk-ant-..."
export HUGGINGFACE_TOKEN="hf_..."
export GITHUB_TOKEN="ghp_..."
export NPM_TOKEN="npm_..."
```

## Verification

Check which environment variables are set:

```bash
# Show all environment variables
printenv | sort

# Check specific variable
echo $NVM_DIR
echo $JAVA_HOME
echo $CUDA_PATH
```

## Troubleshooting

### Variable not set after adding to .bashrc

```bash
# Reload bashrc
source ~/.bashrc

# Or restart your terminal
```

### PATH not updating

```bash
# Check current PATH
echo $PATH

# Verify additions
echo $PATH | tr ':' '\n'
```

### CUDA not found

```bash
# Check if CUDA is installed
nvcc --version
nvidia-smi

# Verify CUDA path
ls -la /usr/local/cuda
```

---

**Last Updated:** 2025-01-15
**Maintained by:** AbeOS Team
