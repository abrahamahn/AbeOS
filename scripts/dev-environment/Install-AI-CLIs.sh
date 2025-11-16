#!/bin/bash
# =============================================================================
# Install-AI-CLIs.sh
# AI Coding Assistants CLI Tools
# =============================================================================

set -e

echo "=================================================="
echo "AI Coding Assistants CLI Installation"
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

# Ensure pipx is installed
if ! command -v pipx &> /dev/null; then
    log_info "Installing pipx..."
    python3 -m pip install --user pipx
    python3 -m pipx ensurepath
    export PATH="$HOME/.local/bin:$PATH"
    log_success "pipx installed"
else
    log_info "pipx already installed: $(pipx --version)"
fi

# Install AI CLI tools
log_info "Installing AI coding assistant CLIs..."

# Google Gemini CLI
log_info "Installing Google Gemini CLI..."
if ! command -v gemini &> /dev/null; then
    pipx install google-generativeai
    log_success "Google Gemini CLI installed"
else
    log_info "Gemini CLI already installed"
fi

# Anthropic Claude
log_info "Installing Anthropic Claude CLI..."
if ! pipx list | grep -q "anthropic"; then
    pipx install anthropic
    log_success "Anthropic CLI installed"
else
    log_info "Anthropic CLI already installed"
fi

# OpenAI CLI
log_info "Installing OpenAI CLI..."
if ! pipx list | grep -q "openai"; then
    pipx install openai
    log_success "OpenAI CLI installed"
else
    log_info "OpenAI CLI already installed"
fi

# GitHub Copilot CLI (if available)
log_info "Checking for GitHub Copilot CLI..."
if command -v gh &> /dev/null; then
    if ! gh extension list | grep -q "copilot"; then
        log_info "Installing GitHub Copilot extension..."
        gh extension install github/gh-copilot || log_warning "Could not install GitHub Copilot extension"
    else
        log_info "GitHub Copilot extension already installed"
    fi
else
    log_warning "GitHub CLI not found. Install it to use GitHub Copilot CLI"
fi

# Aider (AI pair programming)
log_info "Installing Aider (AI pair programming)..."
if ! command -v aider &> /dev/null; then
    pipx install aider-chat
    log_success "Aider installed"
else
    log_info "Aider already installed"
fi

# Continue (VS Code extension CLI)
log_info "Installing Continue CLI..."
if ! command -v continue &> /dev/null; then
    npm install -g continue
    log_success "Continue CLI installed"
else
    log_info "Continue CLI already installed"
fi

# List installed AI tools
echo ""
log_info "Installed AI CLI tools:"
pipx list

echo ""
echo "=================================================="
log_success "AI CLIs installation complete!"
echo "=================================================="
echo ""
echo "Installed AI assistants:"
echo "  ✓ Google Gemini CLI"
echo "  ✓ Anthropic Claude CLI"
echo "  ✓ OpenAI CLI"
echo "  ✓ Aider (AI pair programming)"
echo "  ✓ Continue CLI"
if command -v gh &> /dev/null && gh extension list | grep -q "copilot"; then
    echo "  ✓ GitHub Copilot CLI"
fi
echo ""
echo "API Key Setup Required:"
echo ""
echo "1. Google Gemini:"
echo "   export GEMINI_API_KEY='your-key-here'"
echo "   Add to ~/.env.local"
echo ""
echo "2. Anthropic Claude:"
echo "   export ANTHROPIC_API_KEY='sk-ant-...'"
echo "   Add to ~/.env.local"
echo ""
echo "3. OpenAI:"
echo "   export OPENAI_API_KEY='sk-...'"
echo "   Add to ~/.env.local"
echo ""
echo "4. GitHub Copilot:"
echo "   gh copilot config"
echo ""
echo "Test your installations:"
echo "  python -m anthropic"
echo "  python -m openai"
echo "  aider --help"
echo ""
