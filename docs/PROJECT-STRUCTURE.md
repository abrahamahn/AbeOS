# AbeOS Project Structure

**Last Updated:** 2025-11-16
**Version:** 1.0.0

---

## 📁 Directory Layout

```
AbeOS/
├── 📄 README.md                    # Main project README
├── 📄 setup.ps1                    # Master setup script (Phase 1.1)
│
├── 📁 docs/                        # All documentation
│   ├── 📁 manual/                  # User-facing documentation
│   │   ├── quickstart.md           # Quick start guide
│   │   ├── installation-guide.md   # Detailed installation guide
│   │   ├── setup-guide.md          # Complete setup walkthrough
│   │   ├── installation-summary.md # Installation overview
│   │   ├── installation-checklist.md # Step-by-step checklist
│   │   ├── quick-reference.md      # Command reference
│   │   ├── power-plan-guide.md     # Power plan documentation
│   │   └── audio-plugins-list.md   # Audio production software list
│   │
│   ├── 📁 dev/                     # Developer documentation
│   │   ├── debug-wsl-setup.md      # WSL debugging guide
│   │   ├── debug-powershell-profiles.md # PowerShell profile fixes
│   │   ├── debug-root-cause-analysis.md # Root cause analysis
│   │   ├── debug-session-4.md      # Additional debugging
│   │   ├── phase3-fixes.md         # Phase 3 comprehensive fixes
│   │   ├── asset-management-system.md # Asset management docs
│   │   ├── documentation-index.md  # Documentation index
│   │   ├── changelog.md            # Project changelog
│   │   └── todo.md                 # Project TODO list
│   │
│   ├── PROJECT-STRUCTURE.md        # This file
│   └── ARCHITECTURE.md             # System architecture overview
│
├── 📁 assets/                      # Static assets
│   └── icons/                      # Icon files
│
├── 📁 configs/                     # Configuration files
│   ├── apps/                       # Application configs
│   ├── core/                       # Core system configs
│   │   ├── powershell/             # PowerShell configurations
│   │   ├── terminal/               # Terminal profiles and themes
│   │   │   ├── bashrc              # Bash profile loader
│   │   │   ├── bashrc.core         # Core bash configuration
│   │   │   ├── abeos.pwsh.profile.ps1 # PowerShell core profile
│   │   │   ├── Microsoft.PowerShell_profile.ps1 # PS profile
│   │   │   └── abe.omp.json        # Oh My Posh theme
│   │   └── vscode/                 # VS Code settings
│   ├── installers/                 # Installation configurations
│   │   ├── drivers.json            # Driver installation config
│   │   └── audio-plugins.json      # Audio plugins inventory
│   ├── manifest/                   # Manifest files
│   │   └── phases.json             # Installation phases
│   ├── ui/                         # UI configurations
│   └── vscode/                     # Additional VS Code configs
│
├── 📁 modules/                     # Modular components
│   ├── audio/                      # Audio-related modules
│   ├── lib/                        # Shared libraries
│   ├── performance/                # Performance optimization modules
│   ├── revert/                     # Rollback/revert scripts
│   └── security/                   # Security modules
│       ├── Install-AdGuardHome.ps1
│       └── README.md
│
├── 📁 scripts/                     # Automation scripts
│   └── dev-environment/            # Development environment setup
│       ├── Configure-WSL.sh        # WSL configuration
│       ├── Configure-OhMyPosh-Theme.sh # Terminal theme setup
│       ├── Setup-Bash-Profile.sh   # Bash profile setup
│       ├── Setup-PowerShell-Profile.ps1 # PowerShell profile setup
│       ├── Install-Windows-DevTools.ps1 # Windows dev tools
│       ├── Install-WSL-DevTools.sh # WSL/Linux toolchain
│       ├── Install-Node-DevTools.sh # Node.js stack
│       ├── Install-Python-AI-DevTools.sh # Python/AI stack
│       ├── Install-WebDev-Packages.sh # Web development packages
│       ├── Install-AI-CLIs.sh      # AI CLI tools
│       ├── Install-Java-DevTools.sh # Java/JVM stack
│       ├── Install-CPP-DevTools.sh # C/C++ toolchain
│       ├── Install-VSCode-Extensions.sh # VS Code extensions
│       ├── Install-Miniconda.sh    # Python package manager
│       ├── Install-All-DevTools.sh # Master installation script
│       ├── Setup-ProjectDirectories.sh # Project structure setup
│       ├── Verify-Installation.sh  # Installation verification
│       ├── README.md                # Dev environment documentation
│       └── COVERAGE-CHECKLIST.md   # Feature coverage checklist
│
└── 📁 stages/                      # Installation phases
    ├── 01_baseline/                # Phase 1: Baseline system setup
    │   ├── 01_core_optimization/   # Core system optimization
    │   │   └── Verify-Installation.ps1
    │   ├── 02_drivers_bios/        # Hardware drivers and BIOS
    │   │   ├── Install-Drivers.ps1
    │   │   └── README.md
    │   └── 03_developer_environment/ # Developer tools
    │       └── README.md
    │
    ├── 02_music_production/        # Phase 2: Music production
    │   └── 01_daw_plugins/         # DAW and plugin installation
    │       └── README.md
    │
    └── 08_automation/              # Phase 8: Automation
        └── 01_mode_switcher/       # Mode switching automation
            └── README.md
```

---

## 📋 Directory Descriptions

### `/docs` - Documentation
Centralized location for all project documentation, separated into user-facing and developer-facing content.

- **`manual/`** - End-user guides, installation instructions, reference materials
- **`dev/`** - Development notes, debugging guides, technical documentation

### `/configs` - Configuration Files
All configuration files for system components, organized by category.

- **`core/`** - Essential system configurations (terminal, PowerShell, VS Code)
- **`installers/`** - JSON configurations for installation automation
- **`manifest/`** - Installation phase manifests

### `/modules` - Modular Components
Reusable, independent modules that can be installed/uninstalled separately.

- Each module is self-contained
- Includes rollback/revert capabilities
- Can be enabled/disabled independently

### `/scripts` - Automation Scripts
Installation and setup automation scripts.

- **`dev-environment/`** - Complete development environment setup (Phase 3)
- Organized by technology stack (Windows, WSL, Node, Python, Java, C++)

### `/stages` - Installation Phases
Staged installation process for organized setup.

- **`01_baseline/`** - Phase 1: Core system, drivers, dev environment
- **`02_music_production/`** - Phase 2: Audio production software
- **`08_automation/`** - Phase 8: Advanced automation

---

## 🔄 Installation Flow

```
Phase 1.1: Core Optimization
  └─> setup.ps1

Phase 1.2: Drivers & BIOS
  └─> stages/01_baseline/02_drivers_bios/

Phase 1.3: Developer Environment
  ├─> Windows: scripts/dev-environment/Install-Windows-DevTools.ps1
  ├─> WSL Config: scripts/dev-environment/Configure-WSL.sh
  ├─> Bash Profile: scripts/dev-environment/Setup-Bash-Profile.sh
  ├─> PowerShell: scripts/dev-environment/Setup-PowerShell-Profile.ps1
  └─> WSL Tools: scripts/dev-environment/Install-All-DevTools.sh

Phase 2: Music Production
  └─> stages/02_music_production/01_daw_plugins/
```

---

## 📝 File Naming Conventions

### Scripts
- **PowerShell**: `Verb-Noun.ps1` (PascalCase)
  - Examples: `Install-Windows-DevTools.ps1`, `Setup-PowerShell-Profile.ps1`

- **Bash**: `Verb-Noun.sh` (PascalCase for consistency)
  - Examples: `Install-Node-DevTools.sh`, `Configure-WSL.sh`

### Documentation
- **User Docs**: `lowercase-with-hyphens.md`
  - Examples: `installation-guide.md`, `quick-reference.md`

- **Dev Docs**: `descriptive-name.md`
  - Examples: `debug-wsl-setup.md`, `phase3-fixes.md`

### Configuration
- **JSON**: `lowercase-with-hyphens.json`
  - Examples: `audio-plugins.json`, `drivers.json`

---

## 🎯 Quick Navigation

| Looking for... | Go to... |
|----------------|----------|
| Quick start guide | `docs/manual/quickstart.md` |
| Installation instructions | `docs/manual/installation-guide.md` |
| Debugging WSL issues | `docs/dev/debug-wsl-setup.md` |
| Phase 3 fixes | `docs/dev/phase3-fixes.md` |
| Audio plugins list | `docs/manual/audio-plugins-list.md` |
| Dev environment scripts | `scripts/dev-environment/` |
| PowerShell profile | `configs/core/terminal/abeos.pwsh.profile.ps1` |
| Bash profile | `configs/core/terminal/bashrc.core` |

---

## 📚 Related Documentation

- [ARCHITECTURE.md](./ARCHITECTURE.md) - System architecture overview
- [docs/manual/installation-guide.md](./manual/installation-guide.md) - Detailed installation guide
- [docs/dev/phase3-fixes.md](./dev/phase3-fixes.md) - Phase 3 comprehensive fixes
- [README.md](../README.md) - Main project README

---

**Target System:** Windows 11 Pro + WSL2 Ubuntu 22.04 + ASUS Zephyrus G14
