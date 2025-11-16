# Phase 1.3 — Developer Environment

**Status**: ✅ Complete (Debugged and Fixed)

## Overview

This phase brings the coding and AI tooling layer online after the baseline system is stable. All scripts have been rewritten to fix issues documented in `DEBUG.md`, `DEBUG2.md`, `DEBUG3.md`, and `DEBUG4.md`.

## Components Installed

- ✅ **WSL2 (Ubuntu 22.04)** - Properly configured with systemd, no Windows PATH pollution
- ✅ **Node.js** - Installed via NVM (not apt), with correct npm global prefix
- ✅ **VS Code** - Clean installation with proper PATH and settings integration
- ✅ **PowerShell Profiles** - Unified across all terminal hosts
- ✅ **System PATH** - Cleaned and rebuilt for Zephyrus G14
- ✅ **Bloat Removal** - Removes unnecessary packages and tools

### Planned (Not Yet Implemented)
- ⏳ Python 3, pipenv, and Poetry
- ⏳ Docker Desktop with WSL integration
- ⏳ CUDA Toolkit, cuDNN, and PyTorch (GPU acceleration)
- ⏳ GitHub CLI, SSH keys, and repo bootstrap

---

## Installation Scripts

### 🚀 Quick Start (Recommended)

Run the master installation script that executes all steps in order:

```powershell
# Run as Administrator
.\Install-DevEnvironment.ps1
```

This will:
1. Remove bloated packages
2. Repair system PATH
3. Configure PowerShell profiles
4. Install WSL2 with Ubuntu 22.04
5. Install Node.js via NVM
6. Install VS Code

**Duration**: 30-60 minutes (depending on internet speed)

---

### 📋 Individual Scripts

If you prefer to run scripts individually:

#### 1. Remove Bloated Packages

```powershell
.\Remove-BloatPackages.ps1
```

Removes packages listed in `DEBUG.md`:
- notepad++, playnite, jetbrains toolbox
- llvm, ninja, cmake, visual studio build tools
- 7-zip, powertoys, postman
- Duplicate package managers (bun, gradle, maven, etc.)

---

#### 2. Repair System PATH

```powershell
.\Repair-SystemPATH.ps1
```

Fixes issues from `DEBUG4.md`:
- Removes duplicate and invalid PATH entries
- Rebuilds clean Machine and User PATH
- Ensures tools like `code`, `oh-my-posh`, `git`, etc. are accessible

**Creates backup** before making changes.

---

#### 3. Configure PowerShell Profiles

```powershell
.\Configure-PowerShellProfiles.ps1
```

Fixes issues from `DEBUG2.md`:
- Unifies all PowerShell profile entry points
- Ensures VS Code, Windows Terminal, and Admin shells load the same configuration
- Adds Claude CLI to PATH (`C:\Users\abe\.local\bin`)
- All profiles source: `C:\AbeOS\configs\core\terminal\pwsh.core.profile.ps1`

---

#### 4. Install WSL2

```powershell
.\Install-WSL.ps1
```

Fixes issues from `DEBUG.md` and `DEBUG3.md`:
- Installs WSL2 with Ubuntu 22.04
- Creates `/etc/wsl.conf` with **LF line endings** (not CRLF)
- Disables Windows PATH injection (`appendWindowsPath=false`)
- Enables systemd
- Verifies clean PATH and root filesystem

**May require reboot** if WSL features are not enabled.

---

#### 5. Install Node.js (via NVM)

```powershell
.\Install-NodeJS.ps1
```

Fixes issues from `DEBUG3.md`:
- **Removes** system Node.js installed via apt (v12)
- Installs NVM (Node Version Manager)
- Installs Node.js v20 LTS via NVM
- Configures npm global prefix to `~/.npm-global`
- Fixes PATH to include npm global binaries
- Installs essential packages: pnpm, yarn, typescript, etc.

**Prerequisite**: WSL2 must be installed first.

---

#### 6. Install VS Code

```powershell
.\Install-VSCode.ps1
```

Fixes issues from `DEBUG4.md`:
- Clean installation of VS Code
- Adds `code` CLI to PATH
- Creates symlink to AbeOS `settings.json`
- Configures terminal font (CaskaydiaCove Nerd Font)
- Installs essential extensions

Optional: Use `-CleanInstall` flag to remove existing VS Code first.

---

#### 7. Sync Shell Profiles (Existing)

```powershell
.\Sync-ShellProfiles.ps1
```

Syncs PowerShell and Bash profiles from AbeOS configs to system locations.

---

## Debugging Documentation

All issues encountered during Phase 3 setup are documented:

- **`DEBUG.md`** - WSL configuration issues, PATH cleansing, bloat removal list
- **`DEBUG2.md`** - PowerShell profile unification and Claude CLI PATH issues
- **`DEBUG3.md`** - Node.js/npm issues, wsl.conf SYSTEM.INI problem, Codex CLI
- **`DEBUG4.md`** - System PATH corruption, VS Code removal/reinstall, font configuration

---

## Verification

After installation, verify with:

### Windows (PowerShell)
```powershell
# Verify PATH cleanup
echo $env:PATH

# Verify tools
git --version
code --version
oh-my-posh --version
claude --version
wsl --version
```

### WSL (Ubuntu)
```bash
# Enter WSL
wsl

# Reload shell
source ~/.bashrc

# Verify configuration
cat /etc/wsl.conf
echo $PATH | grep -v "/mnt/c"  # Should return nothing

# Verify Node.js
node --version   # Should be v20.x
npm --version
npm root -g      # Should be ~/.npm-global/lib/node_modules

# Verify NVM
nvm --version
nvm list
```

---

## Troubleshooting

### WSL not starting after reboot
```powershell
wsl --shutdown
wsl
```

### Node.js command not found in WSL
```bash
source ~/.bashrc
nvm use 20
```

### VS Code `code` command not found
Restart terminal or add to PATH manually:
```powershell
$env:PATH += ";$env:LOCALAPPDATA\Programs\Microsoft VS Code\bin"
```

### Claude CLI not found
Check PATH includes:
```powershell
$env:USERPROFILE\.local\bin
```

---

## Next Steps

After completing Phase 1.3:

1. **Reboot your computer** to ensure all PATH changes take effect
2. Test all tools as shown in the Verification section
3. Continue to **Phase 2**: Music Production setup
4. Optionally install Docker Desktop and CUDA Toolkit (scripts pending)

---

## Notes for Future Development

### Pending Scripts
- `Install-Python.ps1` - Python, pipenv, Poetry setup
- `Install-Docker.ps1` - Docker Desktop with WSL integration
- `Install-CUDA.ps1` - CUDA Toolkit, cuDNN, PyTorch for GPU acceleration
- `Setup-Git.ps1` - GitHub CLI, SSH keys, repo cloning

### Integration
When scripts are validated, register them in `configs/manifest/phases.json` under `phase1-dev`.
