# Phase 1.3 — Developer Environment

**Status**: ✅ Complete

## Overview

This phase brings the coding and AI tooling layer online after the baseline system is stable. All Windows and WSL2 developer environment installation scripts have been consolidated into `C:\AbeOS\scripts\dev-env\`.

## Components Installed

- ✅ **Windows Tooling (`scripts/dev-env/Install-DevEnvironment.ps1`)** - Categorized installation (`WebDev`, `VSTDev`, `MLDev`, `AITools`, `All`) via `winget`, `npm`, and `pip`
- ✅ **WSL2 Configuration (`scripts/dev-env/Configure-WSL.sh`)** - Properly configured `/etc/wsl.conf` with systemd and `appendWindowsPath=false`
- ✅ **WSL2 Linux Toolchain (`scripts/dev-env/Install-WSL-DevTools.sh`)** - Build essentials, multimedia tools, modern CLI utilities
- ✅ **Node.js Stack (`scripts/dev-env/Install-Node-DevTools.sh`)** - Installed via NVM with `~/.npm-global` prefix and Corepack
- ✅ **Python / AI / ML Stack (`scripts/dev-env/Install-Python-AI-DevTools.sh` & `Install-Miniconda.sh`)** - `uv`, `pyenv`, Miniconda, PyTorch, Hugging Face
- ✅ **AI CLI Assistants (`scripts/dev-env/Install-AI-CLIs.sh`)** - Claude Code, Codex, Gemini CLI, Aider
- ✅ **Java & C/C++ Stacks (`Install-Java-DevTools.sh`, `Install-CPP-DevTools.sh`)** - SDKMAN!, Temurin JDK 21/17/11, GCC/Clang, CMake, vcpkg
- ✅ **Shell Profiles & IDE Settings (`Setup-Bash-Profile.sh`, `Install-VSCode-Extensions.sh`, `Backup-DevSettings.ps1`)** - Unified PowerShell and WSL bash profiles (`configs/terminal/bashrc.core`) and VS Code / Antigravity IDE configuration sync

## Quick Start

### Windows (PowerShell)

```powershell
C:\AbeOS\scripts\dev-env\Install-DevEnvironment.ps1 -Category All
```

### WSL2 (Ubuntu)

```bash
cd /mnt/c/AbeOS/scripts/dev-env
bash Configure-WSL.sh
bash Setup-Bash-Profile.sh
bash Install-All-DevTools.sh
bash Verify-Installation.sh
```
