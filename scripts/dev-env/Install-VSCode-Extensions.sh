#!/bin/bash
# =============================================================================
# Install-VSCode-Extensions.sh
# VS Code Extensions Installation Script
# =============================================================================

set -e

echo "=================================================="
echo "VS Code Extensions Installation"
echo "=================================================="
echo ""

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib/common.sh"

# Check if code command is available
if ! command -v code &> /dev/null; then
    log_error "VS Code CLI 'code' command not found!"
    log_info "Make sure VS Code is installed and added to PATH"
    log_info "In VS Code: Cmd/Ctrl+Shift+P > 'Shell Command: Install code command in PATH'"
    exit 1
fi

log_success "VS Code CLI found: $(code --version | head -1)"

# Extension list file
EXTENSIONS_FILE="/mnt/c/AbeOS/configs/vscode/extensions.txt"

if [ ! -f "$EXTENSIONS_FILE" ]; then
    log_error "Extensions file not found: $EXTENSIONS_FILE"
    exit 1
fi

log_info "Reading extensions from: $EXTENSIONS_FILE"

# Count extensions
TOTAL_EXTENSIONS=$(grep -v '^#' "$EXTENSIONS_FILE" | grep -v '^$' | wc -l)
log_info "Found $TOTAL_EXTENSIONS extensions to install"
echo ""

# Install extensions
INSTALLED=0
FAILED=0
SKIPPED=0

while IFS= read -r extension; do
    # Skip comments and empty lines
    [[ "$extension" =~ ^#.*$ ]] && continue
    [[ -z "$extension" ]] && continue

    log_info "Installing: $extension"

    if code --install-extension "$extension" --force 2>&1 | grep -q "already installed"; then
        log_info "  Already installed, skipping"
        ((SKIPPED++))
    elif code --install-extension "$extension" --force > /dev/null 2>&1; then
        log_success "  Installed successfully"
        ((INSTALLED++))
    else
        log_warning "  Failed to install"
        ((FAILED++))
    fi
done < "$EXTENSIONS_FILE"

echo ""
echo "=================================================="
log_success "VS Code Extensions Installation Complete!"
echo "=================================================="
echo ""
echo "Summary:"
echo "  Total extensions: $TOTAL_EXTENSIONS"
echo "  Newly installed: $INSTALLED"
echo "  Already installed: $SKIPPED"
echo "  Failed: $FAILED"
echo ""

if [ $FAILED -gt 0 ]; then
    log_warning "Some extensions failed to install. This might be normal if they're deprecated or renamed."
fi

# List all installed extensions
echo ""
log_info "All installed extensions:"
code --list-extensions | sort

echo ""
log_info "To uninstall all extensions, run: code --list-extensions | xargs -L 1 code --uninstall-extension"
echo ""
