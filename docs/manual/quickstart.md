# AbeOS Quick Start

Fast track to get your development environment running.

## One-Click Setup (Recommended)

### Windows (PowerShell as Administrator)

```powershell
cd C:\AbeOS\scripts\dev-environment
.\Setup-DevEnvironment.ps1
```

**That's it!** The orchestrator handles:
- ✅ Windows development tools installation
- ✅ Automatic restart (if needed for Docker Desktop)
- ✅ WSL2 configuration with PATH isolation
- ✅ All development tools (Node.js, Python, Java, C++, etc.)
- ✅ Profile setup (Bash + PowerShell)
- ✅ Resume after restart automatically

**Time Required:** 1-2 hours (including downloads)

---

## Manual Step-by-Step (Advanced)

If you prefer manual control or need to troubleshoot:

### Windows (PowerShell as Administrator)

```powershell
cd C:\AbeOS\scripts\dev-environment
.\Install-Windows-DevTools.ps1

# RESTART COMPUTER if Docker Desktop was installed
```

### After Restart - WSL2

```bash
cd /mnt/c/AbeOS/scripts/dev-environment

# Configure WSL (CRITICAL: PATH isolation, systemd)
./Configure-WSL.sh

# Shutdown and restart WSL
exit
# In PowerShell: wsl --shutdown
# Then reopen WSL

# Install everything
./Install-All-DevTools.sh

# Set up profiles
./Setup-Bash-Profile.sh

# In PowerShell:
# .\Setup-PowerShell-Profile.ps1

# Verify installation
./Verify-Installation.sh
```

### Configure Git

```bash
git config --global user.name "Your Name"
git config --global user.email "your.email@example.com"

gh auth login
```

### Done!

Test it:
```bash
sysinfo
node --version
python3 --version
java -version
```

## What's Installed?

- ✅ WSL2 Ubuntu
- ✅ Node.js 20 & 24 (via NVM)
- ✅ Python 3.12 + AI/ML tools
- ✅ Java 21, 17, 11
- ✅ GCC, Clang, CMake
- ✅ Docker, VS Code
- ✅ Git, GitHub CLI
- ✅ 100+ modern dev tools

## Next Steps

1. Read the full [Setup Guide](./SETUP-GUIDE.md)
2. Check [Scripts README](./scripts/dev-environment/README.md)
3. Start coding!

```bash
cdproj
new-node my-awesome-app
```

## Troubleshooting

See [Setup Guide - Troubleshooting](./SETUP-GUIDE.md#troubleshooting)

**Time Required:** 1-2 hours (including downloads)
