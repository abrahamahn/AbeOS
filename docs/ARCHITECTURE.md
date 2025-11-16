# AbeOS Architecture

**Last Updated:** 2025-11-16
**Version:** 1.0.0

---

## 🏗️ System Overview

AbeOS is a **Windows 11 overlay system** designed for creative professionals, developers, and power users. It operates as a modular, reproducible configuration layer that sits *alongside* Windows rather than modifying it directly.

```
┌─────────────────────────────────────────────────────────────┐
│                         AbeOS Layer                         │
│  ┌────────────┬─────────────┬─────────────┬──────────────┐  │
│  │  Configs   │   Scripts   │   Modules   │    Stages    │  │
│  │  Terminal  │   Install   │   Audio     │   Phase 1-8  │  │
│  │  VSCode    │   Setup     │   Security  │   Baseline   │  │
│  │  PowerPlan │   Configure │   Perf      │   Dev Env    │  │
│  └────────────┴─────────────┴─────────────┴──────────────┘  │
└─────────────────────────────────────────────────────────────┘
                            ↓
┌─────────────────────────────────────────────────────────────┐
│                    Windows 11 Pro Base                      │
│  ┌────────────────────────────────────────────────────────┐ │
│  │              WSL2 (Ubuntu 22.04)                       │ │
│  │  ┌───────────────────────────────────────────────────┐│ │
│  │  │  Development Environment                          ││ │
│  │  │  Node.js, Python, Java, C++, Rust, Go, Zig       ││ │
│  │  └───────────────────────────────────────────────────┘│ │
│  └────────────────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────────────┘
                            ↓
┌─────────────────────────────────────────────────────────────┐
│                     Hardware Layer                          │
│  ASUS ROG Zephyrus G14 | RTX 4070 | Ryzen 9 | NVMe SSD     │
└─────────────────────────────────────────────────────────────┘
```

---

## 🎯 Design Principles

### 1. **Overlay Architecture**
- AbeOS lives in `C:\AbeOS` as a self-contained overlay
- Does not modify critical Windows system files
- Can be completely removed without breaking Windows

### 2. **Modularity**
- Each component can be installed/uninstalled independently
- Modules have clear dependencies and interfaces
- Rollback capabilities for every change

### 3. **Reproducibility**
- Declarative configuration files (JSON, scripts)
- Git-tracked for version control
- Disaster recovery: clone repo + run scripts = full restore

### 4. **Performance-First**
- Zero-latency audio optimizations
- Gaming-optimized power plans
- Development environment streamlined for speed

### 5. **Dual-Environment**
- **Windows side**: Native tools (VS Code, PowerShell, Docker Desktop)
- **WSL2 side**: Linux toolchain (compilers, interpreters, CLI tools)
- Seamless integration between both

---

## 📦 Component Architecture

### Configuration Layer (`/configs`)

Stores all system configurations:

```
configs/
├── core/                  # Core system configs
│   ├── terminal/          # Shell profiles and themes
│   │   ├── bashrc.core    # Bash configuration
│   │   ├── abeos.pwsh.profile.ps1  # PowerShell profile
│   │   └── abe.omp.json   # Oh My Posh theme
│   ├── powershell/        # PowerShell configs
│   └── vscode/            # VS Code settings
│
├── installers/            # Installation configs
│   ├── drivers.json       # Driver metadata
│   └── audio-plugins.json # Audio software inventory
│
└── manifest/              # Installation manifests
    └── phases.json        # Multi-phase setup definition
```

**Key Features:**
- Centralized configuration management
- Easy backup and restore
- Version-controlled settings

---

### Script Layer (`/scripts`)

Automation scripts for installation and setup:

```
scripts/
└── dev-environment/       # Development environment automation
    ├── Windows (PowerShell):
    │   ├── Install-Windows-DevTools.ps1  # Windows native tools
    │   └── Setup-PowerShell-Profile.ps1  # PowerShell unification
    │
    ├── WSL2 (Bash):
    │   ├── Configure-WSL.sh              # WSL configuration
    │   ├── Setup-Bash-Profile.sh         # Bash profile linking
    │   ├── Install-WSL-DevTools.sh       # Linux toolchain
    │   ├── Install-Node-DevTools.sh      # Node.js stack
    │   ├── Install-Python-AI-DevTools.sh # Python/AI stack
    │   ├── Install-Java-DevTools.sh      # Java/JVM stack
    │   ├── Install-CPP-DevTools.sh       # C/C++ stack
    │   └── Install-All-DevTools.sh       # Master installer
    │
    └── Utilities:
        ├── Verify-Installation.sh        # Validation
        └── Setup-ProjectDirectories.sh   # Project structure
```

**Installation Flow:**

```
Windows PowerShell (Admin)
    ↓
Install-Windows-DevTools.ps1
    ├─> Git, VS Code, Docker Desktop
    ├─> PowerShell 7, Windows Terminal
    ├─> Nerd Fonts, Oh My Posh
    └─> NVM for Windows
    ↓
Setup-PowerShell-Profile.ps1
    └─> Unified PowerShell profiles
    ↓
WSL --shutdown & Restart
    ↓
WSL2 Ubuntu Bash
    ↓
Configure-WSL.sh
    ├─> /etc/wsl.conf (LF endings)
    ├─> Disable Windows PATH injection
    └─> Enable systemd
    ↓
Setup-Bash-Profile.sh
    └─> Link AbeOS bashrc.core
    ↓
Install-WSL-DevTools.sh
    ├─> Build essentials
    ├─> Development libraries
    └─> Modern CLI tools
    ↓
Install-Node-DevTools.sh
    ├─> NVM for Linux
    ├─> Node 20 & 24
    ├─> pnpm, yarn, global packages
    └─> npm global prefix: ~/.npm-global
    ↓
Install-Python-AI-DevTools.sh
    ├─> pyenv, uv
    ├─> PyTorch, TensorFlow
    └─> Transformers, Whisper
    ↓
Install-Java-DevTools.sh
    ├─> SDKMAN!
    └─> Java 21/17/11, Gradle, Maven
    ↓
Install-CPP-DevTools.sh
    ├─> GCC, Clang
    └─> Debugging tools
```

---

### Module Layer (`/modules`)

Self-contained, reusable components:

```
modules/
├── audio/           # Audio-specific modules
├── lib/             # Shared libraries
├── performance/     # Performance optimization
├── revert/          # Rollback capabilities
└── security/        # Security enhancements
    └── AdGuard Home DNS filtering
```

**Module Pattern:**
- Each module is independent
- Includes installation + removal scripts
- Can be toggled on/off

---

### Stage Layer (`/stages`)

Multi-phase installation system:

```
stages/
├── 01_baseline/              # Phase 1: Foundation
│   ├── 01_core_optimization/ # System tweaks (setup.ps1)
│   ├── 02_drivers_bios/      # Hardware optimization
│   └── 03_developer_environment/ # Dev tools (scripts/dev-environment)
│
├── 02_music_production/      # Phase 2: Audio production
│   └── 01_daw_plugins/       # DAWs, VST plugins
│
└── 08_automation/            # Phase 8: Advanced automation
    └── 01_mode_switcher/     # Mode switching (work/game/music)
```

**Phase Progression:**
1. **Phase 1.1** - Core system optimization (✅ Done)
2. **Phase 1.2** - Drivers and BIOS (🔄 In Progress)
3. **Phase 1.3** - Developer environment (✅ Done)
4. **Phase 2** - Music production (🔄 Planned)
5. **Phase 3+** - Gaming, streaming, automation

---

## 🔧 Key Subsystems

### 1. Profile Management

**Problem:** Multiple PowerShell/Bash profiles causing inconsistencies

**Solution:** Unified profile architecture

```
PowerShell (Windows):
  All profiles → Load → C:\AbeOS\configs\core\terminal\abeos.pwsh.profile.ps1

Bash (WSL):
  ~/.bashrc → Source → /mnt/c/AbeOS/configs/core/terminal/bashrc.core
```

**Scripts:**
- `Setup-PowerShell-Profile.ps1` - Unifies all PS profiles
- `Setup-Bash-Profile.sh` - Links bash to AbeOS core

---

### 2. PATH Management

**Problem:** Windows PATH contaminating WSL, npm global path issues

**Solution:** Isolation and proper configuration

```
WSL Configuration (/etc/wsl.conf):
  [interop]
  appendWindowsPath=false  ← Prevents Windows PATH pollution

npm Configuration:
  npm config set prefix ~/.npm-global  ← Local npm globals
  export PATH="$HOME/.npm-global/bin:$PATH"
```

**Scripts:**
- `Configure-WSL.sh` - Sets up WSL isolation
- `Install-Node-DevTools.sh` - Configures npm properly

---

### 3. Development Environment

**Dual-Installation Strategy:**

| Tool | Windows | WSL2 | Why? |
|------|---------|------|------|
| Git | ✅ | ✅ | Different use cases (GUI vs CLI) |
| VS Code | ✅ | - | Native Windows app |
| Docker | ✅ | - | Desktop app with WSL backend |
| Node.js | ✅ (NVM-Win) | ✅ (NVM) | Windows GUI tools + WSL dev |
| Python | ✅ | ✅ | Windows apps + Linux dev |
| PowerShell | ✅ | - | Windows shell |
| Bash | - | ✅ | Linux shell |

**Integration:**
- VS Code Remote - WSL extension bridges both environments
- Docker Desktop uses WSL2 backend
- Git credentials shared via Windows Credential Manager

---

### 4. Configuration Synchronization

**Terminal Themes:**
```
Oh My Posh Theme:
  Windows PowerShell: Uses C:\AbeOS\configs\core\terminal\abe.omp.json
  WSL Bash:          Uses /mnt/c/AbeOS/configs/core/terminal/abe.omp.json

  Same theme, both environments! 🎨
```

**VS Code Settings:**
```
Windows: Uses configs/core/vscode/settings.json
WSL: Syncs via VS Code Remote - WSL
```

---

## 🚀 Installation Architecture

### Master Setup Script (`setup.ps1`)

Phase 1.1 entry point:

```powershell
setup.ps1
  ├─> Validate prerequisites
  ├─> Create backups
  ├─> Apply registry tweaks
  ├─> Configure power plan
  ├─> Optimize Windows Search
  ├─> Disable telemetry
  └─> Generate rollback scripts
```

### Multi-Stage Installer

```
Stage 1: Core Optimization
  └─> setup.ps1

Stage 2: Developer Environment
  ├─> Windows: Install-Windows-DevTools.ps1
  ├─> WSL Config: Configure-WSL.sh
  ├─> Profiles: Setup-*-Profile.*
  └─> Tools: Install-*-DevTools.sh

Stage 3: Verification
  └─> Verify-Installation.sh
```

---

## 🔐 Security & Isolation

### WSL2 Isolation
- Windows PATH disabled in WSL (`appendWindowsPath=false`)
- Separate package managers (winget/choco vs apt)
- Independent development environments

### Rollback Capabilities
- Registry backups before changes
- Module-level uninstall scripts
- Version-controlled configs for quick restore

### Sandboxing
- Each development stack is isolated (NVM, pyenv, SDKMAN!)
- Virtual environments for Python projects
- Container-based workflows via Docker

---

## 📊 Data Flow

### Configuration Updates

```
User edits config file
  ↓
Commits to Git
  ↓
Runs setup script
  ↓
Script applies changes
  ↓
Creates backup/rollback script
  ↓
Changes take effect
```

### Software Installation

```
User runs Install-* script
  ↓
Script checks prerequisites
  ↓
Downloads and installs software
  ↓
Configures PATH and environment
  ↓
Verifies installation
  ↓
Logs results
```

---

## 🎯 Target Environment

**Hardware:**
- ASUS ROG Zephyrus G14
- RTX 4070 GPU
- AMD Ryzen 9 CPU
- NVMe SSD

**Software:**
- Windows 11 Pro
- WSL2 with Ubuntu 22.04
- PowerShell 7+
- Windows Terminal

---

## 📚 Related Documentation

- [PROJECT-STRUCTURE.md](./PROJECT-STRUCTURE.md) - File organization
- [docs/dev/phase3-fixes.md](./dev/phase3-fixes.md) - Phase 3 technical details
- [docs/manual/installation-guide.md](./manual/installation-guide.md) - Installation walkthrough

---

**Philosophy:** *"Configuration as Code, Reproducibility as Default"*
