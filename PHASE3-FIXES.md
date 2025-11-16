# PHASE 3 Development Environment Fixes

**Date:** 2025-11-16
**Target System:** Windows 11 + WSL2 (Ubuntu 22.04) on ASUS Zephyrus G14
**Based on:** DEBUG.md, DEBUG2.md, DEBUG3.md

---

## Overview

This document summarizes all fixes applied to the AbeOS development environment installation scripts based on debugging sessions that identified critical issues with WSL configuration, Node.js installation, and bloated software packages.

---

## Issues Fixed

### 1. **Bloated Software Removal**

Removed unnecessary packages to streamline the installation:

#### Windows (Install-Windows-DevTools.ps1)
- ❌ Notepad++
- ❌ JetBrains Toolbox
- ❌ LLVM
- ❌ Ninja
- ❌ CMake
- ❌ Visual Studio Build Tools
- ❌ 7-Zip
- ❌ PowerToys
- ❌ Postman
- ❌ Eclipse Temurin
- ❌ Gradle
- ❌ Maven
- ❌ Miniconda3
- ❌ Starship
- ❌ Ripgrep
- ❌ FZF
- ❌ vcpkg

#### WSL/Linux (Install-WSL-DevTools.sh)
- ❌ CMake
- ❌ Ninja-build
- ❌ Ripgrep
- ❌ FZF
- ❌ tmux
- ❌ Zoxide

#### Web Dev (Install-WebDev-Packages.sh)
- ❌ create-vite
- ❌ create-next-app
- ❌ express-generator

#### Node Dev (Install-Node-DevTools.sh)
- ❌ Turbo
- ❌ Bun

#### Python/AI (Install-Python-AI-DevTools.sh)
- ❌ pipx (removed as global tool, use per-project instead)
- ❌ Poetry
- ❌ pipenv
- ❌ Seaborn

---

### 2. **WSL Configuration Fixes**

**Problem:** `/etc/wsl.conf` had CRLF line endings, causing WSL to treat it as "Windows SYSTEM.INI" and ignore it, leading to Windows PATH contamination.

**Solution:** Created `Configure-WSL.sh` that:
- ✅ Creates `/etc/wsl.conf` with proper LF line endings
- ✅ Enables systemd
- ✅ Sets default user
- ✅ Disables `appendWindowsPath` to prevent Windows PATH contamination
- ✅ Verifies file integrity and filesystem
- ✅ Creates diagnostic script for validation

**Configuration:**
```ini
[boot]
systemd=true

[user]
default=<username>

[interop]
appendWindowsPath=false
```

---

### 3. **Node.js Installation Fixes**

**Problem:** System Node.js installed via `apt` caused:
- npm global prefix pointing to Windows paths (`/mnt/c/Users/...`)
- Permission errors (EACCES)
- Global packages not linking properly
- Incompatible with modern tooling (v12 vs v20+)

**Solution:**
- ✅ Auto-detect and remove system Node.js from apt
- ✅ Use NVM exclusively for Node.js management
- ✅ Configure npm global prefix to `~/.npm-global`
- ✅ Add npm global bin to PATH
- ✅ Prevent Windows PATH contamination

**Updated Install-Node-DevTools.sh:**
```bash
# Remove system Node if installed via apt
if [[ "$(which node)" == "/usr/bin/node" ]]; then
    sudo apt purge -y nodejs npm
fi

# Configure npm global prefix
npm config set prefix "$HOME/.npm-global"
export PATH="$HOME/.npm-global/bin:$PATH"
```

---

### 4. **Validation & Diagnostics**

Created comprehensive validation script (`~/verify-wsl.sh`) that checks:
- ✅ WSL version and root filesystem
- ✅ `/etc/wsl.conf` status and contents
- ✅ PATH contamination (no `/mnt/c` paths)
- ✅ Node.js location and version
- ✅ npm global prefix
- ✅ systemd status

---

## Files Modified

### Core Installation Scripts
1. `scripts/dev-environment/Install-Windows-DevTools.ps1`
   - Removed bloated Windows packages
   - Updated component list

2. `scripts/dev-environment/Install-WSL-DevTools.sh`
   - Removed bloated Linux packages
   - Updated build essentials

3. `scripts/dev-environment/Install-Node-DevTools.sh`
   - Added system Node.js removal
   - Fixed npm global prefix configuration
   - Removed Bun and Turbo

4. `scripts/dev-environment/Install-WebDev-Packages.sh`
   - Removed project generators (create-vite, create-next-app, express-generator)

5. `scripts/dev-environment/Install-Python-AI-DevTools.sh`
   - Removed pipx, poetry, pipenv, seaborn
   - Switched to per-project tool installation model

### New Scripts
6. `scripts/dev-environment/Configure-WSL.sh` ⭐ **NEW**
   - WSL configuration with proper line endings
   - PATH contamination prevention
   - Validation and diagnostics

---

## Installation Order (PHASE 3)

For fresh Windows 11 + WSL2 setup:

### Phase 3A: Windows Side
```powershell
# Run as Administrator
.\scripts\dev-environment\Install-Windows-DevTools.ps1
```

### Phase 3B: WSL Side (Run in order)
```bash
# 1. Configure WSL properly
./scripts/dev-environment/Configure-WSL.sh

# 2. Exit and shutdown WSL from PowerShell
wsl --shutdown

# 3. Restart WSL and continue
./scripts/dev-environment/Install-WSL-DevTools.sh
./scripts/dev-environment/Install-Node-DevTools.sh
./scripts/dev-environment/Install-Python-AI-DevTools.sh
./scripts/dev-environment/Install-WebDev-Packages.sh
./scripts/dev-environment/Install-AI-CLIs.sh

# 4. Verify installation
~/verify-wsl.sh
```

---

## Validation Checklist

After installation, verify:

- [ ] `/etc/wsl.conf` exists with LF endings (not CRLF)
- [ ] `file /etc/wsl.conf` shows "ASCII text", NOT "Windows SYSTEM.INI"
- [ ] `echo $PATH` does NOT contain `/mnt/c` paths
- [ ] `which node` returns `$HOME/.nvm/versions/node/...`
- [ ] `npm root -g` returns `$HOME/.npm-global/lib/node_modules`
- [ ] `node --version` shows v20+
- [ ] `systemctl is-system-running` works
- [ ] No Windows packages bleeding into WSL

---

## Key Learnings (from DEBUG sessions)

1. **CRLF vs LF matters:** WSL ignores `/etc/wsl.conf` if it has CRLF endings
2. **PATH contamination is real:** Windows paths in WSL cause npm to install globally to Windows
3. **System Node.js is problematic:** Always use NVM, never `apt install nodejs`
4. **npm global prefix must be set:** Default behavior tries to use Windows paths
5. **WSL needs restart:** Changes to `/etc/wsl.conf` require `wsl --shutdown`
6. **Bloat accumulates:** Only install what's actually needed

---

## References

- DEBUG.md - WSL distribution status and PATH issues
- DEBUG2.md - PowerShell profile unification
- DEBUG3.md - Root cause analysis and fix protocol

---

## Testing Notes

**Tested on:**
- Windows 11 Pro
- ASUS Zephyrus G14
- WSL 2 with Ubuntu 22.04
- PowerShell 7

**Expected Behavior:**
- Clean WSL environment with no Windows PATH contamination
- NVM-managed Node.js with proper global prefix
- All development tools isolated in WSL
- Fast, reproducible environment setup

---

## Future Improvements

- [ ] Add automatic rollback on script failure
- [ ] Create unified setup script that runs both PowerShell and Bash parts
- [ ] Add progress indicators for long-running installations
- [ ] Create Docker-based testing environment for validation
- [ ] Add Windows Terminal profile auto-configuration

---

**End of PHASE 3 Fixes**
