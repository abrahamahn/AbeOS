# 🧠 AbeOS - Hyper-Personalized Windows 11 Environment

> **A modular, reproducible Windows overlay for Music Production 🎹 + Gaming 🎮 + Coding 💻 + Streaming 📡**

[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)
[![Platform](https://img.shields.io/badge/Platform-Windows%2011-blue)](https://www.microsoft.com/windows/windows-11)
[![PowerShell](https://img.shields.io/badge/PowerShell-7.0+-blue.svg)](https://github.com/PowerShell/PowerShell)

## 📋 Overview

AbeOS is a comprehensive Windows 11 customization framework designed for creative professionals and power users. It provides automated setup scripts, performance optimizations, and workflow enhancements while maintaining full reversibility and disaster recovery capabilities.

### Hardware Target
- **Device**: ASUS ROG Zephyrus G14
- **GPU**: RTX 4070
- **CPU**: AMD Ryzen 9
- **Storage**: NVMe SSD

### Design Philosophy
- **Overlay Architecture**: Lives *alongside* Windows, not *inside* it
- **Modular**: Install/uninstall components independently
- **Reproducible**: Declarative scripts for disaster recovery
- **Performance-First**: Zero-latency audio, max FPS gaming
- **Aesthetic**: macOS-inspired UI with cyberpunk elements

## 🚀 Quick Start

### Prerequisites
- Windows 11 Pro (clean install recommended)
- Administrator privileges
- PowerShell 7.0 or higher

### Two-Path Installation

#### Option 1: System Optimization Only (Fast - ~15 min)

```powershell
# Clone AbeOS
git clone https://github.com/yourusername/AbeOS.git C:\AbeOS
cd C:\AbeOS

# Run core optimization
.\setup.ps1
```

This installs:
- ✅ System performance optimizations
- ✅ Registry tweaks and backups
- ✅ Custom power plans
- ✅ Privacy and telemetry controls

#### Option 2: Complete Developer Environment (Full - ~2 hrs)

See **[docs/manual/quickstart.md](./docs/manual/quickstart.md)** or **[docs/manual/setup-guide.md](./docs/manual/setup-guide.md)**

```powershell
# Windows (PowerShell as Admin)
cd C:\AbeOS\scripts\dev-environment
.\Install-Windows-DevTools.ps1

# RESTART COMPUTER

# WSL2 (after restart)
cd /mnt/c/AbeOS/scripts/dev-environment
./Install-All-DevTools.sh
```

This installs:
- ✅ WSL2 + Ubuntu
- ✅ Node.js, Python, Java, C/C++ stacks
- ✅ AI/ML tools (PyTorch, TensorFlow, Hugging Face)
- ✅ Docker, VS Code, Git, GitHub CLI
- ✅ 100+ modern development tools

## 📦 What's Included

### Phase 1.1 - Core System Optimization (✅ Completed)
- ✅ Hibernation, Fast Startup, SysMain disabled
- ✅ Fixed 16GB pagefile configuration
- ✅ Custom "AbeOS Balanced Ultimate" power plan
- ✅ Windows Search indexing optimization
- ✅ File Explorer performance tweaks
- ✅ Login tips and consumer features disabled
- ✅ Automated registry backups

### Phase 1.3 - Developer Environment (✅ Completed)
- ✅ **WSL2/Linux Toolchain**: Build tools, FFmpeg, modern CLI (ripgrep, fd, fzf, jq, yq)
- ✅ **Node.js Stack**: NVM, Node 20 & 24, pnpm, yarn, Bun, global packages
- ✅ **Python/AI Stack**: PyTorch, TensorFlow, Transformers, Whisper, Poetry, pipx
- ✅ **Java/JVM**: SDKMAN!, Java 21/17/11, Gradle, Maven, Kotlin, Scala
- ✅ **C/C++ Toolchain**: GCC, Clang, CMake, vcpkg, Conan, debugging tools
- ✅ **VS Code**: 80+ extensions, optimized settings, WSL integration
- ✅ **Project Structure**: Organized workspace with templates
- ✅ **Shell Configuration**: Oh My Posh, custom aliases, environment automation

### Upcoming Phases
- 🔄 Phase 1.2 - Hardware drivers and BIOS optimization
- 🔄 Phase 2 - Music production environment
- 🔄 Phase 3 - Gaming optimization
- 🔄 Phase 4 - Streaming and creator tools
- 🔄 Phase 5 - UI customization (macOS aesthetic)
- 🔄 Phase 6 - iOS interoperability
- 🔄 Phase 7 - Backup, security, and reliability
- 🔄 Phase 8 - Automation and maintenance

## 📁 Directory Structure

```
C:\AbeOS
├── setup.ps1                    # Master setup script
├── README.md                    # This file
├── .gitignore
│
├── docs/                        # 📚 All documentation
│   ├── manual/                  # User guides and references
│   ├── dev/                     # Developer and debugging docs
│   ├── PROJECT-STRUCTURE.md     # Complete file structure
│   └── ARCHITECTURE.md          # System architecture
│
├── configs/
│   ├── core/
│   │   ├── terminal/            # Shell profiles (bashrc, PS profile, Oh My Posh)
│   │   │   ├── environment.sh           # Shared environment variables
│   │   │   ├── environment-variables.md # Documentation
│   │   │   ├── Microsoft.PowerShell_profile.ps1
│   │   │   ├── bashrc
│   │   │   └── abe.omp.json            # Oh My Posh theme
│   │   └── backup/              # Registry backups
│   ├── vscode/
│   │   ├── settings.json        # VS Code settings
│   │   └── extensions.txt       # Extension list
│   ├── apps/                    # App presets (OBS, VoiceMeeter, GHelper)
│   ├── ui/                      # Theme assets
│   ├── installers/              # Installer metadata
│   └── manifest/                # Phase manifest (phases.json)
│
├── scripts/
│   └── dev-environment/         # Developer environment automation
│       ├── README.md                         # Detailed script documentation
│       ├── Install-All-DevTools.sh           # Master installer
│       ├── Install-WSL-DevTools.sh           # WSL/Linux tools
│       ├── Install-Node-DevTools.sh          # Node.js ecosystem
│       ├── Install-Python-AI-DevTools.sh     # Python/AI stack
│       ├── Install-Java-DevTools.sh          # Java/JVM tools
│       ├── Install-CPP-DevTools.sh           # C/C++ toolchain
│       ├── Install-Windows-DevTools.ps1      # Windows tools (PowerShell)
│       ├── Install-VSCode-Extensions.sh      # VS Code extensions
│       ├── Setup-ProjectDirectories.sh       # Project structure
│       └── Verify-Installation.sh            # Verification script
│
├── stages/                      # Phase runbooks
│   ├── 01_baseline/
│   │   ├── 01_core_optimization/
│   │   ├── 02_drivers_bios/
│   │   └── 03_developer_environment/
│   └── 02_music_production/
│
├── modules/                     # Reusable modules
│   ├── performance/
│   ├── audio/, revert/
│   └── lib/
│
├── assets/                      # Visual assets
│   ├── wallpapers/
│   ├── icons/
│   ├── cursors/
│   └── fonts/
│
├── logs/                        # Execution logs
│
└── installations/               # Installers (gitignored)
```

## 🛠️ Key Scripts

### Master Setup
```powershell
.\setup.ps1                                               # Run all stable steps from manifest
.\setup.ps1 -SkipBackup                                   # Skip registry backup (not recommended)
.\setup.ps1 -SkipReboot                                   # Don't prompt for reboot
.\setup.ps1 -Phase phase1-core -StartAtStep explorer-indexing
.\setup.ps1 -Phase all -MaxStatus experimental            # Include experimental steps once added
.\setup.ps1 -StopAfterStep privacy-ui                     # Stop after a specific step
```

### Individual Components
```powershell
# System optimization
.\stages\01_baseline\01_core_optimization\System-Optimization.ps1

# Explorer and indexing
.\stages\01_baseline\01_core_optimization\Explorer-Indexing.ps1

# Privacy and UI cleanup
.\stages\01_baseline\01_core_optimization\Privacy-UI.ps1
```

### Driver Batch Install
1. Drop vendor installers into `C:\AbeOS\installations\drivers\`.
2. Edit `configs/installers/drivers.json` and flip `enabled` to `true` for each entry, supplying the correct silent arguments.
3. Run:
   ```powershell
   .\stages\01_baseline\02_drivers_bios\Install-Drivers.ps1           # executes enabled installers
   .\stages\01_baseline\02_drivers_bios\Install-Drivers.ps1 -WhatIf   # dry-run to verify config
   ```
4. (Optional) invoke via the manifest runner with `.\setup.ps1 -Phase phase1-drivers -MaxStatus experimental`.

### Manifest Controls
- All steps now originate from `configs/manifest/phases.json`, which records the current phase, status (`stable`, `experimental`, `planned`), script path, and default parameters.
- Use `-Phase` to target a subset of phases (e.g. `phase1-core`) or `all` once future phases are marked ready.
- `-MaxStatus` gates how far up the roadmap the runner should go—by default only `stable` (tested) steps are executed.
- `-StartAtStep` / `-StopAfterStep` let you resume or halt at exact checkpoints (step IDs match the manifest, e.g. `explorer-indexing`).
- When `-SkipBackup` is supplied, the manifest entry flagged with `skipFlag: "SkipBackup"` is automatically removed from the run.

### Power Management
```powershell
# Switch between power modes
.\modules\performance\Set-PowerPlan.ps1 -Mode Balanced
.\modules\performance\Set-PowerPlan.ps1 -Mode Performance
.\modules\performance\Set-PowerPlan.ps1 -Mode Creator
```

### Backup & Restore
```powershell
# Create registry backup
.\stages\01_baseline\01_core_optimization\Backup-Registry.ps1 -BackupType Quick
.\stages\01_baseline\01_core_optimization\Backup-Registry.ps1 -BackupType Full

# Restore: Right-click any .reg file → Merge
```

### Shell Profiles
```powershell
# Sync PowerShell $PROFILE and WSL ~/.bashrc to the AbeOS-managed stubs
.\stages\01_baseline\03_developer_environment\Sync-ShellProfiles.ps1
```

### Developer Environment
```bash
# Complete installation (WSL)
cd /mnt/c/AbeOS/scripts/dev-environment
./Install-All-DevTools.sh              # Install everything
./Verify-Installation.sh               # Check what's installed

# Individual stacks
./Install-WSL-DevTools.sh              # Linux tools only
./Install-Node-DevTools.sh             # Node.js only
./Install-Python-AI-DevTools.sh        # Python/AI only
./Install-Java-DevTools.sh             # Java only
./Install-CPP-DevTools.sh              # C/C++ only

# Configuration
./Setup-ProjectDirectories.sh          # Create project structure
./Install-VSCode-Extensions.sh         # Install VS Code extensions
```

```powershell
# Windows tools (PowerShell as Admin)
cd C:\AbeOS\scripts\dev-environment
.\Install-Windows-DevTools.ps1         # WSL2, Docker, Git, VS Code, etc.
```

## 📚 Documentation

Comprehensive documentation is available in the [`docs/`](./docs/) directory:

### User Documentation ([`docs/manual/`](./docs/manual/))
- **[Quick Start](./docs/manual/quickstart.md)** - Get started in 5 minutes
- **[Installation Guide](./docs/manual/installation-guide.md)** - Detailed setup instructions
- **[Setup Guide](./docs/manual/setup-guide.md)** - Complete walkthrough
- **[Quick Reference](./docs/manual/quick-reference.md)** - Command cheat sheet
- **[Audio Plugins List](./docs/manual/audio-plugins-list.md)** - 400+ audio production plugins

### Developer Documentation ([`docs/dev/`](./docs/dev/))
- **[WSL Debugging](./docs/dev/debug-wsl-setup.md)** - WSL configuration and troubleshooting
- **[PowerShell Profiles](./docs/dev/debug-powershell-profiles.md)** - Profile unification guide
- **[Phase 3 Fixes](./docs/dev/phase3-fixes.md)** - Comprehensive fixes and learnings
- **[Changelog](./docs/dev/changelog.md)** - Project changelog

### Architecture Documentation
- **[Project Structure](./docs/PROJECT-STRUCTURE.md)** - Complete file layout and navigation
- **[Architecture Overview](./docs/ARCHITECTURE.md)** - System design and data flow

## 📊 Logging

All scripts generate detailed logs in `C:\AbeOS\logs\`:
```
logs/
├── System-Optimization-20251115-143022.log
├── Explorer-Indexing-20251115-143156.log
└── Privacy-UI-20251115-143245.log
```

## 🔒 Safety Features

### Registry Backups
- Automatic backups before any system changes
- Timestamped for easy identification
- Located in `configs/core/backup/registry/`
- Simple restore via double-click

### Rollback
All changes are reversible:
1. Navigate to `configs/core/backup/registry/`
2. Find the backup with your desired timestamp
3. Right-click the `.reg` file → Merge
4. Reboot

### Error Handling
- All scripts validate prerequisites
- Failed steps don't block subsequent operations
- Detailed error logging for troubleshooting

## 🎯 Use Cases

### For Music Producers
- Low-latency audio optimizations
- Centralized VST management
- VoiceMeeter routing profiles
- Creator Mode power plan (balanced, quiet)

### For Gamers
- Max performance power plan
- GPU optimization scripts
- Game launcher integration (Playnite)
- FPS monitoring and benchmarking

### For Developers
- WSL2 + Docker integration
- Terminal customization (Oh My Posh)
- VS Code workspace management
- GitHub CLI automation

### For Streamers
- OBS scene management
- Audio routing (VoiceMeeter)
- Stream Deck integration
- Mode-switching automation

## 🤝 Contributing

AbeOS is a personal project but contributions are welcome! Feel free to:
- Report issues
- Suggest optimizations
- Share your customizations
- Submit pull requests

## 📄 License

MIT License - Feel free to use and modify for your own setup.

## ⚠️ Disclaimer

**This project modifies Windows registry and system settings.** While all scripts include safety features:
- Always create backups before running (done automatically)
- Test in a VM or on a non-critical system first
- Review scripts before execution
- Use at your own risk

## 🙏 Acknowledgments

- [Oh My Posh](https://ohmyposh.dev/) - Beautiful terminal prompts
- [privacy.sexy](https://privacy.sexy/) - Windows telemetry disabling
- [O&O AppBuster](https://www.oo-software.com/en/ooappbuster) - Bloatware removal
- The Windows optimization community

## 📞 Support

For questions or issues:
1. Check the logs in `C:\AbeOS\logs\`
2. Review **[docs/dev/todo.md](./docs/dev/todo.md)** for implementation details
3. See **[docs/dev/](./docs/dev/)** for debugging guides
4. Check **[docs/PROJECT-STRUCTURE.md](./docs/PROJECT-STRUCTURE.md)** for navigation
5. Open an issue on GitHub

---

**AbeOS Philosophy**: *Modular. Aesthetic. Performant. Reproducible. Secure.*

> A Windows environment so optimized, it behaves like a personalized OS layer.
