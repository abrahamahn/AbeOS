# AbeOS Quick Start

Fast track to get your development environment running.

## For the Impatient

### Windows (PowerShell as Administrator)

```powershell
cd C:\AbeOS\scripts\dev-environment
.\Install-Windows-DevTools.ps1

# RESTART COMPUTER
```

### After Restart - WSL2

```bash
cd /mnt/c/AbeOS/scripts/dev-environment

# Install everything
./Install-All-DevTools.sh

# Reload shell
source ~/.bashrc

# Set up projects
./Setup-ProjectDirectories.sh

# Install VS Code extensions
./Install-VSCode-Extensions.sh

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
