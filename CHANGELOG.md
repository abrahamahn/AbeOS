# Changelog

All notable changes to AbeOS will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.0.0] - 2025-11-15

### Added
- **Master setup script** (`setup.ps1`) with automated Phase 1.1 execution
- **System optimization script** consolidating power management, hibernation, pagefile settings
- **Explorer indexing optimization** for improved file system performance
- **Privacy and UI cleanup script** to disable telemetry and bloat
- **Power plan manager** for switching between Balanced, Performance, and Creator modes
- **Registry backup utility** with automatic backups before system changes
- **Comprehensive logging** for all operations
- **Project structure** with organized directories for configs, scripts, assets, and logs
- **Documentation**: README.md, TODO.md, CHANGELOG.md
- **Git configuration**: .gitignore with appropriate exclusions

### Phase 1.1 Completed Features
- ✅ Hibernation disabled (freed ~20-30GB)
- ✅ Fast Startup disabled (fixes GPU/audio issues)
- ✅ SysMain (Superfetch) disabled
- ✅ Fixed 16GB pagefile configuration
- ✅ Custom "AbeOS Balanced Ultimate" power plan
- ✅ PCIe latency optimization
- ✅ OLED brightness and HDR fixes
- ✅ Modern Standby optimization
- ✅ Windows Search index minimized to essential paths
- ✅ Content indexing disabled on all drives
- ✅ Explorer performance tweaks (network crawling, thumbnails, etc.)
- ✅ Login tips and welcome popups disabled
- ✅ Windows Consumer Features disabled
- ✅ App suggestions and feedback requests disabled

### Repository Setup
- Initialized Git repository
- Created proper folder structure matching architecture design
- Consolidated redundant scripts from testing phase
- Organized terminal configurations (Oh My Posh theme, PowerShell profile)
- Added safety features and error handling to all scripts

### Notes
- All Phase 1 Part 1 tasks marked complete in TODO.md
- Scripts tested individually during development
- Registry modifications are safely backed up before execution
- All changes are reversible via registry restore

## [Unreleased]

### Planned for Phase 1.2
- BIOS updates and driver installation automation
- GPU fan calibration and undervolting
- GHelper profile management

### Planned for Phase 1.3
- WSL2 and Docker setup
- Node.js, Python, and development tools installation
- VS Code configuration and extensions
- Terminal font installation and configuration
- GitHub CLI and SSH key setup

### Planned for Phase 2
- Music production environment (DAW, VST management)
- Audio routing profiles (VoiceMeeter, ASIO4All)
- Sample library organization
- Plugin license management

### Planned for Phase 3
- Gaming platform installations
- Emulator configuration
- GPU performance optimization
- Frame rate monitoring tools

### Planned for Phase 4
- OBS and streaming setup
- Scene management
- Audio routing for streaming
- GPU-aware mode switching

### Planned for Phase 5
- macOS-inspired UI customization
- Taskbar and dock modifications
- Wallpaper and theme management
- Gesture controls

### Planned for Phase 6
- iOS file transfer integration
- Clipboard sync
- Project file synchronization

### Planned for Phase 7
- 3-2-1 backup strategy implementation
- Automated maintenance scripts
- Security hardening
- Disaster recovery system

### Planned for Phase 8
- Mode-Switcher automation
- Audio stack reset utilities
- Health monitoring and reporting
- Scheduled maintenance jobs

---

## Version History

- **1.0.0** (2025-11-15): Initial release with Phase 1.1 complete
