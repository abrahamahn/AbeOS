# AbeOS Dev Environment - Complete Execution Flow

**What happens when you run `Setup-DevEnvironment.ps1`**

---

## Master Orchestration Chain

```
Setup-DevEnvironment.ps1 (PowerShell - Windows)
│
├─ Step 1: Install-Windows-DevTools.ps1
│   └─ Installs via winget + Chocolatey
│
├─ Step 2: Configure-WSL.sh (via wsl)
│   └─ WSL2 configuration
│
├─ Step 3: WSL Shutdown + Restart
│
├─ Step 4: Install-All-DevTools.sh (via wsl) ⭐ THIS IS THE KEY
│   │
│   ├─ Install-WSL-DevTools.sh
│   │   └─ Linux build tools, CLI utilities
│   │
│   ├─ Install-Node-DevTools.sh
│   │   └─ NVM, Node 20/24, npm packages
│   │
│   ├─ Install-WebDev-Packages.sh
│   │   └─ Web development tools
│   │
│   ├─ Install-Python-AI-DevTools.sh
│   │   └─ Python, PyTorch, TensorFlow, Transformers
│   │
│   ├─ Install-Miniconda.sh
│   │   └─ Conda environment manager
│   │
│   ├─ Install-AI-CLIs.sh
│   │   └─ Claude, OpenAI, Gemini, Aider
│   │
│   ├─ Install-Java-DevTools.sh
│   │   └─ SDKMAN!, Java 21/17/11, Gradle, Maven
│   │
│   ├─ Install-CPP-DevTools.sh
│   │   └─ GCC, Clang, cmake, debugging tools
│   │
│   └─ Install-VSCode-Extensions.sh
│       └─ 80+ VS Code extensions
│
├─ Step 5: Setup-Bash-Profile.sh (via wsl)
│   └─ Configure ~/.bashrc
│
└─ Step 6: Setup-PowerShell-Profile.ps1
    └─ Configure PowerShell profile
```

---

## Answer: YES! ✅

**`Setup-DevEnvironment.ps1` runs ALL the .sh scripts** through this chain:

1. Runs `Install-Windows-DevTools.ps1` (Windows packages)
2. Runs `Configure-WSL.sh` (WSL setup)
3. **Runs `Install-All-DevTools.sh`** ⭐ **This is the master WSL orchestrator**
4. Runs `Setup-Bash-Profile.sh` (Shell config)
5. Runs `Setup-PowerShell-Profile.ps1` (Windows shell config)

---

## What Install-All-DevTools.sh Does

This script runs **9 installation scripts sequentially**:

```bash
# From Install-All-DevTools.sh (lines 112-146)

Step 1/9: Install-WSL-DevTools.sh
Step 2/9: Install-Node-DevTools.sh
Step 3/9: Install-WebDev-Packages.sh
Step 4/9: Install-Python-AI-DevTools.sh
Step 5/9: Install-Miniconda.sh
Step 6/9: Install-AI-CLIs.sh
Step 7/9: Install-Java-DevTools.sh
Step 8/9: Install-CPP-DevTools.sh
Step 9/9: Install-VSCode-Extensions.sh
```

---

## Execution Order (Complete)

When you run:
```powershell
.\Setup-DevEnvironment.ps1
```

This happens **automatically**:

### Phase 1: Windows Setup
```
1. Install-Windows-DevTools.ps1
   ├─ 13 packages via winget
   ├─ 9 packages via Chocolatey
   ├─ NVM for Windows
   └─ Nerd Fonts
```

### Phase 2: WSL Configuration
```
2. Configure-WSL.sh
   ├─ PATH isolation
   └─ systemd enablement

3. WSL Shutdown & Restart
```

### Phase 3: WSL Development Tools (Install-All-DevTools.sh)
```
4. Install-WSL-DevTools.sh
   └─ build-essential, cmake, FFmpeg, ripgrep, fd, fzf, etc.

5. Install-Node-DevTools.sh
   └─ NVM, Node 20/24, 16 global npm packages

6. Install-WebDev-Packages.sh
   └─ Web development frameworks

7. Install-Python-AI-DevTools.sh
   └─ PyTorch, TensorFlow, Transformers, Whisper

8. Install-Miniconda.sh
   └─ Miniconda3 environment manager

9. Install-AI-CLIs.sh
   └─ Claude CLI, OpenAI, Gemini, Aider

10. Install-Java-DevTools.sh
    └─ SDKMAN!, Java 21/17/11, Gradle, Maven, Kotlin, Scala

11. Install-CPP-DevTools.sh
    └─ GCC, Clang, gdb, valgrind, vcpkg, Conan

12. Install-VSCode-Extensions.sh
    └─ 80+ VS Code extensions
```

### Phase 4: Shell Configuration
```
13. Setup-Bash-Profile.sh
    └─ Configure NVM, pyenv, SDKMAN!, direnv in ~/.bashrc

14. Setup-PowerShell-Profile.ps1
    └─ Configure Oh My Posh, aliases in PowerShell profile
```

---

## Files That Get Executed

**Total: 14 scripts run automatically**

### PowerShell (Windows):
1. `Setup-DevEnvironment.ps1` ⭐ **YOU RUN THIS**
2. `Install-Windows-DevTools.ps1`
3. `Setup-PowerShell-Profile.ps1`

### Bash (WSL):
4. `Configure-WSL.sh`
5. `Install-All-DevTools.sh` ⭐ **WSL ORCHESTRATOR**
6. `Install-WSL-DevTools.sh`
7. `Install-Node-DevTools.sh`
8. `Install-WebDev-Packages.sh`
9. `Install-Python-AI-DevTools.sh`
10. `Install-Miniconda.sh`
11. `Install-AI-CLIs.sh`
12. `Install-Java-DevTools.sh`
13. `Install-CPP-DevTools.sh`
14. `Install-VSCode-Extensions.sh`
15. `Setup-Bash-Profile.sh`

---

## Manual Scripts (NOT auto-run)

These exist but are NOT run by Setup-DevEnvironment.ps1:

- `Verify-Installation.sh` - Run manually after setup
- `Setup-ProjectDirectories.sh` - Run manually if needed
- Individual install scripts - Can be run standalone if you want only specific tools

---

## One-Command Full Setup

**Yes, ONE command installs EVERYTHING:**

```powershell
# PowerShell as Administrator
cd C:\AbeOS\scripts\dev-env
.\Setup-DevEnvironment.ps1
```

This runs all 14 scripts automatically and installs:
- ✅ 13 Windows packages (winget)
- ✅ 9 Windows packages (Chocolatey)
- ✅ 100+ WSL packages (apt, NVM, pyenv, SDKMAN!, etc.)
- ✅ 16+ Node.js global packages
- ✅ 20+ Python/AI packages
- ✅ 10+ Java/JVM packages
- ✅ 20+ C/C++ packages
- ✅ 80+ VS Code extensions
- ✅ Shell profiles configured

**Total time:** ~35-70 minutes (depending on internet speed)

---

## State Management

`Setup-DevEnvironment.ps1` tracks progress in:
- `$env:TEMP\AbeOS-DevEnv-State.json`

**If interrupted:**
```powershell
.\Setup-DevEnvironment.ps1 -Resume
```

**Skip certain steps:**
```powershell
.\Setup-DevEnvironment.ps1 -SkipWindowsTools
.\Setup-DevEnvironment.ps1 -SkipWSLConfig
```

---

## Summary

**Q: Is Setup-DevEnvironment.ps1 installing all the things from the *.sh files?**

**A: YES! ✅**

It orchestrates:
- All Windows installations (*.ps1)
- All WSL installations (*.sh via Install-All-DevTools.sh)
- All configurations (profiles, PATH, etc.)

**You literally just run ONE PowerShell script and everything gets installed automatically!** 🚀

---

**Last Updated:** 2025-12-26
