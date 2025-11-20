#!/usr/bin/env bash
set -euo pipefail

echo "Updating package lists..."
sudo apt update -y

echo "Installing core tools..."
sudo apt install -y build-essential curl wget git unzip jq ripgrep fd-find bat eza tree htop

# Node.js via nvm (latest LTS)
export NVM_DIR="$HOME/.nvm"
if [ ! -s "$NVM_DIR/nvm.sh" ]; then
    echo "Installing nvm..."
    curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.1/install.sh | bash
fi

source "$NVM_DIR/nvm.sh"
nvm install --lts
nvm use --lts
corepack enable   # enables pnpm, yarn without global install

# Python + tools
echo "Installing Python tooling..."
sudo apt install -y python3 python3-pip python3-venv python3.11-venv
pip3 install --user --upgrade pip
pip3 install --user poetry pipenv virtualenv

# Docker (client only inside WSL — Docker Desktop handles daemon)
sudo apt install -y docker.io
sudo usermod -aG docker $USER

# Neovim (optional but everyone has it now)
if ! command -v nvim >/dev/null; then
    echo "Installing Neovim..."
    curl -LO https://github.com/neovim/neovim/releases/latest/download/nvim.appimage
    chmod +x nvim.appimage
    sudo mv nvim.appimage /usr/local/bin/nvim
fi

# VS Code server will auto-install on first run, but pre-download extensions?
# code --install-extension ms-python.python --install-extension esbenp.prettier-vscode ...

echo "WSL dev tools installed!"
