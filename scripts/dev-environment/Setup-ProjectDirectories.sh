#!/bin/bash
# =============================================================================
# Setup-ProjectDirectories.sh
# Creates the recommended project directory structure
# =============================================================================

set -e

echo "=================================================="
echo "Project Directory Structure Setup"
echo "=================================================="
echo ""

# Color codes
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

# Base project directories
WINDOWS_PROJECTS="/mnt/c/projects"
WSL_HOME_PROJECTS="$HOME/projects"

# Create Windows projects directory structure
log_info "Creating Windows project directories in: $WINDOWS_PROJECTS"

mkdir -p "$WINDOWS_PROJECTS"/{personal,work,experiments,clients,archived}
mkdir -p "$WINDOWS_PROJECTS"/personal/{web,mobile,desktop,ai,cli,libraries}
mkdir -p "$WINDOWS_PROJECTS"/work/{current,archived}
mkdir -p "$WINDOWS_PROJECTS"/experiments/{prototypes,learning,hackathons}

log_success "Windows project structure created"

# Create WSL home projects (for Linux-specific projects)
log_info "Creating WSL project directories in: $WSL_HOME_PROJECTS"

mkdir -p "$WSL_HOME_PROJECTS"/{system,scripts,dotfiles,configs}

log_success "WSL project structure created"

# Create common subdirectories in AbeOS
log_info "Creating AbeOS subdirectories..."

mkdir -p /mnt/c/AbeOS/{docs,assets,backups,temp}
mkdir -p /mnt/c/AbeOS/assets/{images,icons,fonts,cursors}
mkdir -p /mnt/c/AbeOS/backups/{registry,configs,data}
mkdir -p /mnt/c/AbeOS/docs/{guides,references,troubleshooting}

log_success "AbeOS subdirectories created"

# Create .gitkeep files to preserve empty directories
log_info "Creating .gitkeep files..."

find "$WINDOWS_PROJECTS" -type d -empty -exec touch {}/.gitkeep \;
find "$WSL_HOME_PROJECTS" -type d -empty -exec touch {}/.gitkeep \;

log_success ".gitkeep files created"

# Create README files for main directories
log_info "Creating README files..."

cat > "$WINDOWS_PROJECTS/README.md" << 'EOF'
# Projects Directory

Main development workspace for all projects.

## Structure

- **personal/** - Personal projects and side projects
  - **web/** - Web applications and websites
  - **mobile/** - Mobile apps (iOS, Android, React Native)
  - **desktop/** - Desktop applications
  - **ai/** - AI/ML projects and experiments
  - **cli/** - Command-line tools
  - **libraries/** - Reusable libraries and packages

- **work/** - Work-related projects
  - **current/** - Active work projects
  - **archived/** - Completed work projects

- **experiments/** - Experimental and learning projects
  - **prototypes/** - Quick prototypes and POCs
  - **learning/** - Learning projects and tutorials
  - **hackathons/** - Hackathon projects

- **clients/** - Client projects (if freelancing)

- **archived/** - Old/archived projects

## Best Practices

1. Each project should have its own Git repository
2. Use meaningful project names (lowercase-with-hyphens)
3. Include a README.md in each project
4. Add .gitignore appropriate for the project type
5. Use consistent project structure within categories

## Quick Start

```bash
# Navigate to projects
cdproj

# Create new Node.js project
new-node my-project-name

# Create new Python project
new-python my-project-name
```
EOF

cat > "$WSL_HOME_PROJECTS/README.md" << 'EOF'
# WSL Projects

Linux-specific projects and system configurations.

## Structure

- **system/** - System utilities and tools
- **scripts/** - Shell scripts and automation
- **dotfiles/** - Configuration files
- **configs/** - System configurations

## Notes

- These directories are in WSL's filesystem for better performance
- Use for Linux-specific development
- Windows projects should be in /mnt/c/projects
EOF

log_success "README files created"

# Display directory tree
echo ""
log_info "Directory structure created:"
echo ""
echo "Windows Projects ($WINDOWS_PROJECTS):"
tree -L 2 -d "$WINDOWS_PROJECTS" 2>/dev/null || find "$WINDOWS_PROJECTS" -type d -maxdepth 2 | sed 's|[^/]*/|  |g'

echo ""
echo "WSL Projects ($WSL_HOME_PROJECTS):"
tree -L 2 -d "$WSL_HOME_PROJECTS" 2>/dev/null || find "$WSL_HOME_PROJECTS" -type d -maxdepth 2 | sed 's|[^/]*/|  |g'

echo ""
echo "=================================================="
log_success "Project directory structure setup complete!"
echo "=================================================="
echo ""
echo "Quick navigation:"
echo "  cdproj          - Go to Windows projects directory"
echo "  cd ~/projects   - Go to WSL projects directory"
echo "  cdabe           - Go to AbeOS directory"
echo ""
echo "Create new projects:"
echo "  new-node <name>     - Create new Node.js project"
echo "  new-python <name>   - Create new Python project"
echo ""
