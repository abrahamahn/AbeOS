#!/bin/bash
# =============================================================================
# AbeOS Environment Variables
# Source this file from ~/.bashrc
# =============================================================================

# Project directories
export PROJECTS_DIR="/mnt/c/projects"
export ABEOS_DIR="/mnt/c/AbeOS"

# Add local bin to PATH
export PATH="$HOME/.local/bin:$PATH"

# Node.js / NVM
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"

# Bun
export BUN_INSTALL="$HOME/.bun"
[ -d "$BUN_INSTALL/bin" ] && export PATH="$BUN_INSTALL/bin:$PATH"

# Python / Pyenv
export PYENV_ROOT="$HOME/.pyenv"
[[ -d $PYENV_ROOT/bin ]] && export PATH="$PYENV_ROOT/bin:$PATH"
command -v pyenv >/dev/null && eval "$(pyenv init -)"

# Java / SDKMAN
export SDKMAN_DIR="$HOME/.sdkman"
[[ -s "$HOME/.sdkman/bin/sdkman-init.sh" ]] && source "$HOME/.sdkman/bin/sdkman-init.sh"

# C++ / vcpkg
export VCPKG_ROOT="$HOME/vcpkg"
[ -d "$VCPKG_ROOT" ] && export PATH="$VCPKG_ROOT:$PATH"
[ -d "$VCPKG_ROOT" ] && export CMAKE_TOOLCHAIN_FILE="$VCPKG_ROOT/scripts/buildsystems/vcpkg.cmake"

# Rust
[ -d "$HOME/.cargo/bin" ] && export PATH="$HOME/.cargo/bin:$PATH"

# Go
export GOPATH="$HOME/go"
[ -d "$GOPATH/bin" ] && export PATH="$GOPATH/bin:$PATH"

# CUDA (if installed)
if [ -d "/usr/local/cuda" ]; then
    export CUDA_PATH="/usr/local/cuda"
    export CUDA_HOME="/usr/local/cuda"
    export PATH="/usr/local/cuda/bin:$PATH"
    export LD_LIBRARY_PATH="/usr/local/cuda/lib64:${LD_LIBRARY_PATH:+:${LD_LIBRARY_PATH}}"
fi

# Hugging Face cache
export HF_HOME="$HOME/.cache/huggingface"

# direnv hook
command -v direnv >/dev/null && eval "$(direnv hook bash)"

# zoxide hook
command -v zoxide >/dev/null && eval "$(zoxide init bash)"

# fzf
[ -f ~/.fzf.bash ] && source ~/.fzf.bash

# Oh My Posh theme
if command -v oh-my-posh >/dev/null; then
    eval "$(oh-my-posh init bash --config /mnt/c/AbeOS/configs/core/terminal/abe.omp.json)"
fi

# Git editor
export GIT_EDITOR=vim
export EDITOR=vim
export VISUAL=vim

# GPG for commit signing
export GPG_TTY=$(tty)

# Aliases
alias cdproj='cd $PROJECTS_DIR'
alias cdabe='cd $ABEOS_DIR'
alias mcl='cd $PROJECTS_DIR && ls -la'

# Modern CLI replacements
command -v bat >/dev/null && alias cat='bat'
command -v eza >/dev/null && alias ls='eza --icons'
command -v eza >/dev/null && alias ll='eza --icons -la'
command -v eza >/dev/null && alias tree='eza --tree'

# Git aliases
alias gs='git status'
alias ga='git add'
alias gc='git commit'
alias gp='git push'
alias gl='git pull'
alias gd='git diff'
alias gco='git checkout'
alias gb='git branch'
alias glog='git log --oneline --graph --decorate'

# Docker aliases
alias d='docker'
alias dc='docker-compose'
alias dps='docker ps'
alias di='docker images'

# Python aliases
alias py='python3'
alias pip='pip3'
alias activate-ai='source $HOME/.virtualenvs/activate-ai.sh'

# Node aliases
alias nr='npm run'
alias ni='npm install'
alias nid='npm install --save-dev'
alias nig='npm install -g'

# Load local secrets (not in version control)
if [ -f "$HOME/.env.local" ]; then
    source "$HOME/.env.local"
fi

# Custom functions
mkcd() {
    mkdir -p "$1" && cd "$1"
}

# Git commit with conventional commits
gcm() {
    local type="$1"
    shift
    git commit -m "${type}: $*"
}

# Quick project creation
new-node() {
    local name="$1"
    mkdir -p "$PROJECTS_DIR/$name"
    cd "$PROJECTS_DIR/$name"
    npm init -y
    git init
    echo "node_modules/" > .gitignore
    echo "Created new Node.js project: $name"
}

new-python() {
    local name="$1"
    mkdir -p "$PROJECTS_DIR/$name"
    cd "$PROJECTS_DIR/$name"
    python3 -m venv venv
    source venv/bin/activate
    git init
    echo "venv/" > .gitignore
    echo "__pycache__/" >> .gitignore
    echo "*.pyc" >> .gitignore
    echo "Created new Python project: $name"
}

# Update all tools
update-all() {
    echo "Updating system packages..."
    sudo apt update && sudo apt upgrade -y

    echo "Updating Node.js packages..."
    npm update -g

    if command -v pipx >/dev/null; then
        echo "Updating pipx packages..."
        pipx upgrade-all
    fi

    if command -v poetry >/dev/null; then
        echo "Updating Poetry..."
        poetry self update
    fi

    if command -v rustup >/dev/null; then
        echo "Updating Rust..."
        rustup update
    fi

    echo "All tools updated!"
}

# System information
sysinfo() {
    echo "=== System Information ==="
    echo "OS: $(uname -s)"
    echo "Kernel: $(uname -r)"
    echo "Architecture: $(uname -m)"
    echo ""
    echo "=== Installed Versions ==="
    command -v node >/dev/null && echo "Node: $(node --version)"
    command -v python3 >/dev/null && echo "Python: $(python3 --version)"
    command -v java >/dev/null && echo "Java: $(java -version 2>&1 | head -1)"
    command -v gcc >/dev/null && echo "GCC: $(gcc --version | head -1)"
    command -v docker >/dev/null && echo "Docker: $(docker --version)"
    command -v git >/dev/null && echo "Git: $(git --version)"
}

# Welcome message
echo "AbeOS Development Environment Loaded"
echo "Type 'sysinfo' for system information"
