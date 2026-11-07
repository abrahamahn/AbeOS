# AbeOS Development Environment - Installation Manifest

**Complete reference of all applications, packages, and tools installed by the automation scripts.**

Last Updated: 2025-01-15
Version: 1.0.0

---

## Quick Start

### One-Command Setup (Windows + WSL)

```powershell
# Windows (PowerShell as Admin)
cd C:\AbeOS\scripts\dev-env
.\Setup-DevEnvironment.ps1
```

This master orchestrator handles:
- ✅ Windows tools installation
- ✅ WSL2 setup and configuration
- ✅ All WSL development tools
- ✅ Shell profile configuration
- ✅ State management (survives restarts)
- ✅ Error handling and resume capability

---

## What Gets Installed

### Phase 1: Windows Tools (PowerShell)

**Script:** `Install-Windows-DevTools.ps1`
**Requires:** Administrator privileges
**Estimated Time:** 15-30 minutes

#### Via winget

| Package | Description | Version |
|---------|-------------|---------|
| `Git.Git` | Git version control | Latest |
| `Microsoft.VisualStudioCode` | VS Code editor | Latest |
| `Microsoft.PowerShell` | PowerShell 7+ | Latest |
| `Microsoft.WindowsTerminal` | Windows Terminal | Latest |
| `JanDeDobbeleer.OhMyPosh` | Shell prompt theming | Latest |
| `Docker.DockerDesktop` | Docker containerization | Latest |
| `Python.Python.3.12` | Python 3.12 (Windows) | 3.12.x |
| `Python.Launcher` | Python version launcher | Latest |
| `GitHub.cli` | GitHub CLI (gh) | Latest |
| `Notepad++.Notepad++` | Lightweight text editor | Latest |
| `Gyan.FFmpeg` | Media processing toolkit | Latest |
| `JetBrains.WebStorm` | JavaScript/TypeScript IDE | Latest |
| `CoreyButler.NVMforWindows` | Node Version Manager (Windows) | Latest |

#### Via Chocolatey

| Package | Description |
|---------|-------------|
| `vcredist140` | Visual C++ Redistributables |
| `dotnet-sdk` | .NET SDK |
| `httpie` | HTTP client |
| `fd` | Fast file finder |
| `jq` | JSON processor |
| `yq` | YAML processor |
| `make` | GNU Make |
| `wget` | File downloader |
| `curl` | Data transfer tool |
| `cascadia-code-nerd-font` | Cascadia Code Nerd Font |
| `jetbrainsmono-nerd-font` | JetBrains Mono Nerd Font |

**Note:** `yarn` and `pnpm` are installed via npm in WSL, not via Chocolatey on Windows.

#### Additional Configuration

- ✅ WSL2 installation and updates
- ✅ Git global config (autocrlf, default branch)
- ✅ Developer Mode enabled
- ✅ PowerShell execution policy set
- ✅ Directory structure: `C:\projects\{personal,work,experiments}`

**Removed from original script:**
- ❌ Oracle Java JRE (use WSL Java via SDKMAN! instead)
- ❌ Rust (not needed for this environment)
- ❌ Go (not needed for this environment)
- ❌ yarn/pnpm via Chocolatey (installed via npm in WSL instead)

---

### Phase 2: WSL Configuration

**Script:** `Configure-WSL.sh`
**Estimated Time:** 2-5 minutes

- ✅ PATH isolation (Windows apps removed from WSL PATH)
- ✅ systemd enabled
- ✅ WSL configuration optimizations
- ✅ **Restart WSL** after configuration

---

### Phase 3: WSL Development Tools

**Script:** `Install-All-DevTools.sh` (Master Orchestrator)
**Estimated Time:** 15-30 minutes

This runs 9 sub-scripts in sequence:

---

#### 3.1 WSL/Linux Toolchain

**Script:** `Install-WSL-DevTools.sh`

**Build Essentials:**
- `build-essential` (gcc, g++, make)
- `cmake`
- `ninja-build`
- `ccache`
- `autoconf`, `automake`, `libtool`
- `pkg-config`

**Development Libraries:**
- `libssl-dev`
- `zlib1g-dev`
- `libbz2-dev`
- `libreadline-dev`
- `libsqlite3-dev`
- `libncursesw5-dev`
- `xz-utils`
- `tk-dev`
- `libxml2-dev`
- `libxmlsec1-dev`
- `libffi-dev`
- `liblzma-dev`

**Multimedia Tools:**
- `ffmpeg`
- `imagemagick`

**Modern CLI Tools:**
- `ripgrep` (rg)
- `fd-find` (fd)
- `fzf` (fuzzy finder)
- `jq` (JSON processor)
- `yq` (YAML processor)
- `direnv` (environment switcher)
- `bat` (cat with syntax highlighting)
- `eza` (modern ls)
- `zoxide` (smart cd)

---

#### 3.2 Node.js/JavaScript Stack

**Script:** `Install-Node-DevTools.sh`

**Node Version Manager:**
- NVM v0.39.7

**Node.js Versions:**
- Node.js v20 (LTS) - **default**
- Node.js v24

**Package Managers:**
- Corepack (enabled)
- pnpm (latest, via corepack)
- yarn (stable, via corepack)

**Global npm Packages:**
```
eslint@latest
prettier@latest
typescript@latest
ts-node@latest
nodemon@latest
pnpm@latest
yarn@latest
@anthropic-ai/claude-code@latest
nx@latest
concurrently@latest
rimraf@latest
npm-check-updates@latest
dotenv-cli@latest
cross-env@latest
serve@latest
http-server@latest
```

**Configuration:**
- npm global prefix: `$HOME/.npm-global`
- npm settings: save-exact, engine-strict, no fund/audit

---

#### 3.3 Web Development Packages

**Script:** `Install-WebDev-Packages.sh`

*Note: This script installs web development frameworks and tools as needed per project.*

---

#### 3.4 Python/AI Toolchain

**Script:** `Install-Python-AI-DevTools.sh`

**System Packages:**
- `python3-pip`
- `python3-dev`
- `python3-venv`
- `python3-setuptools`
- `python3-wheel`

**Python Tools:**
- `uv` (fast package installer)
- `pyenv` (Python version manager)

**AI/ML Virtual Environment:** `~/.virtualenvs/ai-tools`

**Core Libraries (in venv):**
```
numpy
pandas
matplotlib
scipy
scikit-learn
pillow
opencv-python
tqdm
requests
```

**Hugging Face Ecosystem:**
```
transformers
datasets
tokenizers
accelerate
huggingface-hub[cli]
```

**AI/ML Frameworks:**
```
torch (PyTorch) - CUDA 12.1 if GPU detected, else CPU
torchvision
torchaudio
tensorflow
```

**Additional AI Tools:**
```
openai-whisper
sentencepiece
bitsandbytes
onnxruntime
optimum
```

**Helper Script:** `~/.virtualenvs/activate-ai.sh`

---

#### 3.5 Miniconda

**Script:** `Install-Miniconda.sh`

- Miniconda3 (Python environment manager)
- Alternative to virtualenv for isolated ML environments

---

#### 3.6 AI CLI Tools

**Script:** `Install-AI-CLIs.sh`

```
Anthropic Claude CLI
OpenAI CLI
Google Gemini CLI
Aider (AI pair programming)
```

---

#### 3.7 Java/JVM Stack

**Script:** `Install-Java-DevTools.sh`

**SDKMAN! (Java Version Manager)**

**Java Versions:**
- Java 21 (Temurin) - **default**
- Java 17 (Temurin)
- Java 11 (Temurin)

**Build Tools:**
- Gradle
- Maven

**JVM Languages:**
- Kotlin
- Scala
- sbt (Scala Build Tool)

---

#### 3.8 C/C++ Toolchain

**Script:** `Install-CPP-DevTools.sh`

**Compilers:**
- GCC/G++
- Clang/LLVM
- Clang++

**Build Tools:**
- make
- cmake
- ninja-build
- ccache
- meson

**Debuggers:**
- gdb
- lldb
- cgdb

**Profiling Tools:**
- valgrind
- strace
- ltrace

**Static Analysis:**
- cppcheck
- clang-tidy

**Package Managers:**
- vcpkg
- Conan

**Development Libraries:**
- Boost
- Eigen
- and others

---

#### 3.9 VS Code Extensions

**Script:** `Install-VSCode-Extensions.sh`

Installs **80+ extensions** including:

**Remote Development:**
- Remote - WSL
- Remote - SSH
- Remote - Containers

**Languages:**
- Python
- ESLint
- Prettier
- C/C++
- Java
- Go
- Rust

**AI/ML:**
- GitHub Copilot
- Jupyter

**Databases:**
- Prisma
- MongoDB

**API Testing:**
- Thunder Client

**And many more...**

---

### Phase 4: Shell Profile Configuration

#### 4.1 Bash Profile

**Script:** `Setup-Bash-Profile.sh`

Configures:
- NVM initialization
- pyenv configuration
- SDKMAN! initialization
- direnv hooks
- Custom aliases
- PATH configuration

#### 4.2 PowerShell Profile

**Script:** `Setup-PowerShell-Profile.ps1`

Configures:
- Oh My Posh theme
- Custom aliases
- PowerShell modules
- PATH configuration

---

## Environment Variables Reference

### Required for Manual Configuration

| Variable | Purpose | Example Value | Set By |
|----------|---------|---------------|--------|
| `CUDA_PATH` | CUDA Toolkit location | `/usr/local/cuda` | User (manual) |
| `NPM_TOKEN` | npm registry authentication | `npm_xxxxxxxxxxxx` | User (manual) |

### Auto-Configured by Scripts

| Variable | Purpose | Value | Set By |
|----------|---------|-------|--------|
| `NVM_DIR` | NVM installation path | `$HOME/.nvm` | Install-Node-DevTools.sh |
| `PYENV_ROOT` | pyenv installation path | `$HOME/.pyenv` | Install-Python-AI-DevTools.sh |
| `SDKMAN_DIR` | SDKMAN! installation path | `$HOME/.sdkman` | Install-Java-DevTools.sh |
| `VCPKG_ROOT` | vcpkg installation path | `$HOME/vcpkg` (Linux)<br>`C:\tools\vcpkg` (Windows) | Install-CPP-DevTools.sh |
| `BUN_INSTALL` | Bun runtime path | `$HOME/.bun` | Install-Node-DevTools.sh |

### PATH Additions

Scripts automatically add to PATH:
- `$HOME/.local/bin` (Python user packages)
- `$HOME/.npm-global/bin` (npm global packages)
- `$NVM_DIR/versions/node/*/bin` (Node.js)
- `$PYENV_ROOT/bin` (pyenv)
- `$SDKMAN_DIR/bin` (SDKMAN!)
- `$HOME/vcpkg` (vcpkg)

---

## Verification

**Script:** `Verify-Installation.sh`

Checks **80+ tools** across all categories:

```bash
cd /mnt/c/AbeOS/scripts/dev-env
bash Verify-Installation.sh
```

**Output includes:**
- ✅ Pass/Warning/Fail status for each tool
- Version numbers
- Success rate percentage
- CUDA support detection (PyTorch)
- Virtual environment activation test

---

## Directory Structure Created

```
Windows:
C:\projects\
├── personal\
├── work\
└── experiments\

WSL/Linux:
~/.nvm/                          # Node versions
~/.npm-global/                   # npm global packages
~/.pyenv/                        # Python versions
~/.sdkman/                       # Java versions
~/.virtualenvs/
│   ├── ai-tools/                # AI/ML virtual environment
│   └── activate-ai.sh           # Activation script
~/vcpkg/                         # C++ packages
```

---

## Execution Summary

### What Gets Executed (in order)

**Windows (PowerShell as Admin):**
1. `Setup-DevEnvironment.ps1` → Master orchestrator
   - → `Install-Windows-DevTools.ps1`
   - → `Configure-WSL.sh` (via wsl)
   - → WSL shutdown and restart
   - → `Install-All-DevTools.sh` (via wsl)
   - → `Setup-Bash-Profile.sh` (via wsl)
   - → `Setup-PowerShell-Profile.ps1`

**WSL (Bash):**
2. `Install-All-DevTools.sh` → Master orchestrator
   - → `Install-WSL-DevTools.sh`
   - → `Install-Node-DevTools.sh`
   - → `Install-WebDev-Packages.sh`
   - → `Install-Python-AI-DevTools.sh`
   - → `Install-Miniconda.sh`
   - → `Install-AI-CLIs.sh`
   - → `Install-Java-DevTools.sh`
   - → `Install-CPP-DevTools.sh`
   - → `Install-VSCode-Extensions.sh`
3. `Verify-Installation.sh` (optional)

---

## Total Installation Time

| Phase | Duration |
|-------|----------|
| Windows Tools | 15-30 minutes |
| WSL Configuration | 2-5 minutes |
| WSL Development Tools | 15-30 minutes |
| Shell Profile Setup | 2-5 minutes |
| **Total (first run)** | **35-70 minutes** |

*Actual time depends on internet speed and hardware.*

---

## Post-Installation Checklist

- [ ] Restart terminal/VS Code
- [ ] Run `bash Verify-Installation.sh`
- [ ] Test Node: `node --version`
- [ ] Test Python: `python3 --version`
- [ ] Test Java: `java -version`
- [ ] Test Docker: `docker --version`
- [ ] Test Git: `git --version`
- [ ] Activate AI env: `source ~/.virtualenvs/activate-ai.sh`
- [ ] Test PyTorch: `python -c 'import torch; print(torch.__version__)'`
- [ ] Configure VS Code Remote - WSL
- [ ] Set up `NPM_TOKEN` if needed
- [ ] Set up `CUDA_PATH` if using NVIDIA GPU

---

## Manual Configuration Required

### NPM Token (if using private npm registry)

```bash
# In WSL
npm config set //registry.npmjs.org/:_authToken=NPM_TOKEN
```

### CUDA Toolkit (if using NVIDIA GPU)

1. Download CUDA Toolkit 12.1+ from NVIDIA
2. Install in WSL: `sudo apt install nvidia-cuda-toolkit`
3. Verify: `nvcc --version`
4. Set environment variable:
   ```bash
   echo 'export CUDA_PATH=/usr/local/cuda' >> ~/.bashrc
   echo 'export PATH=$CUDA_PATH/bin:$PATH' >> ~/.bashrc
   echo 'export LD_LIBRARY_PATH=$CUDA_PATH/lib64:$LD_LIBRARY_PATH' >> ~/.bashrc
   source ~/.bashrc
   ```
5. Re-run `Install-Python-AI-DevTools.sh` to get GPU-accelerated PyTorch

---

## Troubleshooting

### Script Failures

All scripts support re-running safely. They check for existing installations before attempting to install.

### State Management

`Setup-DevEnvironment.ps1` tracks progress:
- State file: `$env:TEMP\AbeOS-DevEnv-State.json`
- Log file: `$env:TEMP\AbeOS-DevEnv-Setup.log`
- Resume after restart: `.\Setup-DevEnvironment.ps1 -Resume`

### Selective Installation

Skip components:
```powershell
.\Setup-DevEnvironment.ps1 -SkipWindowsTools  # Skip Windows tools
.\Setup-DevEnvironment.ps1 -SkipWSLConfig     # Skip WSL config
```

Or run individual scripts:
```bash
bash Install-Node-DevTools.sh        # Just Node.js
bash Install-Python-AI-DevTools.sh   # Just Python/AI
bash Install-Java-DevTools.sh        # Just Java
bash Install-CPP-DevTools.sh         # Just C++
```

---

## Maintenance

### Update All Tools

**Node.js:**
```bash
nvm install --lts --latest-npm
npm update -g
```

**Python:**
```bash
source ~/.virtualenvs/ai-tools/bin/activate
pip install --upgrade pip
pip list --outdated | tail -n +3 | cut -d ' ' -f1 | xargs pip install --upgrade
```

**Java:**
```bash
sdk update
sdk upgrade
```

**System (WSL):**
```bash
sudo apt update && sudo apt upgrade -y
```

**Windows:**
```powershell
winget upgrade --all
choco upgrade all -y
```

---

## Files Reference

| File | Purpose | Location |
|------|---------|----------|
| Master orchestrator (Windows) | Full setup | `scripts/dev-env/Setup-DevEnvironment.ps1` |
| Master orchestrator (WSL) | WSL tools | `scripts/dev-env/Install-All-DevTools.sh` |
| Verification script | Check installations | `scripts/dev-env/Verify-Installation.sh` |
| Installation guide | Setup instructions | `scripts/dev-env/README.md` |
| **This manifest** | What gets installed | `docs/dev/INSTALLATION_MANIFEST.md` |

---

## Package Changes Log

### 2025-12-26 - Cleanup and additions based on system audit

**Removed from Windows installation:**
- Oracle Java JRE - Use WSL Java via SDKMAN! instead
- Rust - Not needed for this environment
- Go - Not needed for this environment
- yarn (Chocolatey) - Installed via npm in WSL
- pnpm (Chocolatey) - Installed via npm in WSL

**Added to Windows installation:**
- Python Launcher - Manage multiple Python versions
- Notepad++ - Lightweight text editor
- FFmpeg - Media processing toolkit
- WebStorm - JavaScript/TypeScript IDE

**Updated:**
- Ubuntu version: 22.04 → 24.04
- SystemDeepAudit.ps1 now targets Ubuntu-24.04
- Clarified that yarn/pnpm are WSL-only installations via npm

**Version:** 1.2.0
**Last Updated:** 2025-12-26

---

**For more detailed usage instructions, see:** `scripts/dev-env/README.md`
