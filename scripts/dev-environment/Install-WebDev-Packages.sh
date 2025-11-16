#!/bin/bash
# =============================================================================
# Install-WebDev-Packages.sh
# Web Development Global Packages (PERN Stack + Modern Tools)
# =============================================================================

set -e

echo "=================================================="
echo "Web Development Packages Installation"
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

# Check if Node.js is installed
if ! command -v node &> /dev/null; then
    log_warning "Node.js not found! Please run Install-Node-DevTools.sh first"
    exit 1
fi

log_info "Node.js version: $(node --version)"
log_info "npm version: $(npm --version)"

# Check if pnpm is available
if ! command -v pnpm &> /dev/null; then
    log_info "Installing pnpm..."
    npm install -g pnpm
    log_success "pnpm installed"
else
    log_info "pnpm already installed: $(pnpm --version)"
fi

# Install web development global packages
log_info "Installing web development global packages..."

WEB_PACKAGES=(
    "vite"
    "prisma"
    "typescript"
    "ts-node"
    "tsx"
    "eslint"
    "prettier"
    "eslint-config-prettier"
    "eslint-plugin-prettier"
    "@tailwindcss/cli"
    "postcss"
    "autoprefixer"
    "nodemon"
    "concurrently"
    "dotenv-cli"
    "cross-env"
    "rimraf"
    "npm-check-updates"
    "serve"
    "http-server"
    "pm2"
    "vercel"
    "netlify-cli"
    # Removed bloat: create-vite, create-next-app, express-generator
)

for package in "${WEB_PACKAGES[@]}"; do
    log_info "Installing $package..."
    pnpm add -g "$package" 2>&1 | grep -v "Already up to date" || true
done

log_success "Web development packages installed"

# Install PostgreSQL client
log_info "Installing PostgreSQL client..."
if ! command -v psql &> /dev/null; then
    sudo apt install -y postgresql-client
    log_success "PostgreSQL client installed"
else
    log_info "PostgreSQL client already installed"
fi

# Install additional database clients
log_info "Installing additional database tools..."
sudo apt install -y \
    postgresql-client \
    mysql-client \
    sqlite3

log_success "Database clients installed"

# List installed global packages
echo ""
log_info "Installed global packages:"
pnpm list -g --depth=0

echo ""
echo "=================================================="
log_success "Web development packages installation complete!"
echo "=================================================="
echo ""
echo "Installed tools:"
echo "  ✓ Vite (instant dev server)"
echo "  ✓ Prisma (ORM)"
echo "  ✓ TypeScript + ts-node + tsx"
echo "  ✓ ESLint + Prettier"
echo "  ✓ Tailwind CSS CLI"
echo "  ✓ Database clients (PostgreSQL, MySQL, SQLite)"
echo "  ✓ Deployment tools (Vercel, Netlify)"
echo "  ✓ Development utilities (nodemon, pm2, serve)"
echo ""
echo "Quick start:"
echo "  pnpm create vite my-app          # Create Vite project"
echo "  pnpm create next-app my-app      # Create Next.js project"
echo "  prisma init                       # Initialize Prisma"
echo ""
