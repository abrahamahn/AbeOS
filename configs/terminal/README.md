# Terminal Configuration - Environment Variables

**Reference for all environment variables used by AbeOS development environment.**

---

## Critical Environment Variables

### Manual Configuration Required

These must be set manually if you need them:

#### NPM Token (Private Registry Authentication)

```bash
# ~/.bashrc or ~/.zshrc
export NPM_TOKEN="npm_xxxxxxxxxxxxxxxxxxxx"

# Configure npm to use the token
npm config set //registry.npmjs.org/:_authToken=${NPM_TOKEN}
```

**Usage:** Required for accessing private npm packages.

**How to get:**
1. Log in to npmjs.com
2. Go to Access Tokens
3. Generate a new token
4. Copy and set as `NPM_TOKEN`

---

#### CUDA Path (GPU Computing)

```bash
# ~/.bashrc or ~/.zshrc
export CUDA_PATH=/usr/local/cuda
export PATH=$CUDA_PATH/bin:$PATH
export LD_LIBRARY_PATH=$CUDA_PATH/lib64:$LD_LIBRARY_PATH
```

**Usage:** Required for GPU-accelerated machine learning (PyTorch, TensorFlow).

**Prerequisites:**
- NVIDIA GPU
- NVIDIA drivers installed
- CUDA Toolkit installed

**Verify:**
```bash
nvcc --version
nvidia-smi
```

---

## Auto-Configured Variables

These are set automatically by installation scripts:

### Node.js

#### NVM_DIR
```bash
export NVM_DIR="$HOME/.nvm"
```
- **Purpose:** NVM (Node Version Manager) installation directory
- **Set by:** `Install-Node-DevTools.sh`
- **Used by:** NVM to manage Node.js versions

#### BUN_INSTALL
```bash
export BUN_INSTALL="$HOME/.bun"
```
- **Purpose:** Bun JavaScript runtime installation directory
- **Set by:** `Install-Node-DevTools.sh`
- **Used by:** Bun runtime

#### NPM Global Prefix
```bash
# npm config, not environment variable
npm config set prefix "$HOME/.npm-global"
export PATH="$HOME/.npm-global/bin:$PATH"
```
- **Purpose:** Location for global npm packages (avoids Windows PATH pollution)
- **Set by:** `Install-Node-DevTools.sh`
- **Prevents:** Conflicts with Windows Node.js installations

---

### Python

#### PYENV_ROOT
```bash
export PYENV_ROOT="$HOME/.pyenv"
export PATH="$PYENV_ROOT/bin:$PATH"
eval "$(pyenv init -)"
```
- **Purpose:** pyenv (Python version manager) installation directory
- **Set by:** `Install-Python-AI-DevTools.sh`
- **Used by:** pyenv to manage Python versions

#### Python Virtual Environment Path
```bash
# Not an environment variable, but important path
~/.virtualenvs/ai-tools
```
- **Purpose:** AI/ML Python virtual environment
- **Activate:** `source ~/.virtualenvs/activate-ai.sh`
- **Contains:** PyTorch, TensorFlow, Transformers, etc.

#### UV_USE_PYTHON (Optional)
```bash
export UV_USE_PYTHON=python3.12
```
- **Purpose:** Specify Python version for `uv` package installer
- **Default:** Uses system Python if not set
- **Set manually if needed**

---

### Java/JVM

#### SDKMAN_DIR
```bash
export SDKMAN_DIR="$HOME/.sdkman"
[[ -s "$SDKMAN_DIR/bin/sdkman-init.sh" ]] && source "$SDKMAN_DIR/bin/sdkman-init.sh"
```
- **Purpose:** SDKMAN! (Java version manager) installation directory
- **Set by:** `Install-Java-DevTools.sh`
- **Used by:** SDKMAN! to manage Java, Gradle, Maven, Kotlin, Scala

---

### C/C++

#### VCPKG_ROOT
```bash
# Linux/WSL
export VCPKG_ROOT="$HOME/vcpkg"
export PATH="$VCPKG_ROOT:$PATH"

# Windows
export VCPKG_ROOT="C:\tools\vcpkg"
```
- **Purpose:** vcpkg (C++ package manager) installation directory
- **Set by:** `Install-CPP-DevTools.sh`
- **Used by:** vcpkg to manage C++ libraries

---

### AI/ML (Optional)

#### HUGGING_FACE_HUB_TOKEN (Optional)
```bash
export HUGGING_FACE_HUB_TOKEN="hf_xxxxxxxxxxxxxxxxxxxx"
```
- **Purpose:** Authenticate with Hugging Face Hub for model downloads
- **Required:** Only for private models or gated models
- **Set manually if needed**

**How to get:**
1. Log in to huggingface.co
2. Go to Settings → Access Tokens
3. Create a new token
4. Copy and set as `HUGGING_FACE_HUB_TOKEN`

---

## PATH Configuration

The installation scripts add these to your PATH (in order of precedence):

```bash
# User local binaries (Python user packages)
export PATH="$HOME/.local/bin:$PATH"

# npm global packages
export PATH="$HOME/.npm-global/bin:$PATH"

# Node.js (via NVM)
# Handled by NVM automatically

# pyenv
export PATH="$PYENV_ROOT/bin:$PATH"

# SDKMAN!
# Handled by SDKMAN! init script

# vcpkg
export PATH="$VCPKG_ROOT:$PATH"

# CUDA (if installed)
export PATH="$CUDA_PATH/bin:$PATH"
```

---

## Configuration Files

### Bash (.bashrc)

Located: `~/.bashrc`

Contains initialization for:
- NVM
- pyenv
- SDKMAN!
- direnv
- Custom aliases
- PATH additions

**Reload:**
```bash
source ~/.bashrc
```

### PowerShell Profile

Located: `~\Documents\PowerShell\Microsoft.PowerShell_profile.ps1`

Template: `/mnt/c/AbeOS/configs/terminal/Microsoft.PowerShell_profile.ps1`

Contains:
- Oh My Posh theme initialization
- Custom aliases
- PATH additions
- PowerShell modules

**Reload:**
```powershell
. $PROFILE
```

---

## Verification

### Check All Environment Variables

```bash
# Node.js
echo $NVM_DIR
nvm --version
node --version

# Python
echo $PYENV_ROOT
pyenv --version
python3 --version

# Java
echo $SDKMAN_DIR
sdk version
java -version

# C++
echo $VCPKG_ROOT
vcpkg version

# CUDA (if installed)
echo $CUDA_PATH
nvcc --version
```

### Run Full Verification

```bash
cd /mnt/c/AbeOS/scripts/dev-env
bash Verify-Installation.sh
```

---

## Adding Custom Variables

### Temporary (current session only)

```bash
export MY_VAR="value"
```

### Permanent (add to ~/.bashrc)

```bash
echo 'export MY_VAR="value"' >> ~/.bashrc
source ~/.bashrc
```

### Permanent (Windows PowerShell)

```powershell
# Add to profile
"$env:MY_VAR = 'value'" | Add-Content $PROFILE
. $PROFILE
```

---

## Security Notes

### Sensitive Variables

**Never commit these to git:**
- `NPM_TOKEN`
- `HUGGING_FACE_HUB_TOKEN`
- API keys
- Access tokens
- Passwords

### Best Practices

1. **Use `.env` files for project-specific secrets**
   ```bash
   # .env (add to .gitignore!)
   NPM_TOKEN=npm_xxxx
   OPENAI_API_KEY=sk-xxxx
   ```

2. **Load `.env` files with direnv**
   ```bash
   # .envrc
   dotenv
   ```

3. **Use keychain/credential manager for long-term storage**
   ```bash
   # Example: Use gh auth for GitHub tokens
   gh auth login
   ```

---

## Troubleshooting

### Variable Not Found

```bash
# Check if variable is set
echo $VARIABLE_NAME

# Check PATH
echo $PATH | tr ':' '\n'

# Reload configuration
source ~/.bashrc
```

### Tool Not Found After Installation

```bash
# Ensure PATH includes the tool's bin directory
which <tool-name>

# If not found, add to PATH
export PATH="/path/to/tool/bin:$PATH"

# Make permanent
echo 'export PATH="/path/to/tool/bin:$PATH"' >> ~/.bashrc
```

### Conflicts Between Windows and WSL

```bash
# WSL PATH should NOT include Windows directories (except /mnt/c/Windows/System32)
# Check with:
echo $PATH

# If Windows paths are present, ensure Configure-WSL.sh has been run
bash /mnt/c/AbeOS/scripts/dev-env/Configure-WSL.sh
wsl --shutdown
```

---

## Related Documentation

- **Installation Guide:** `/mnt/c/AbeOS/scripts/dev-env/README.md`
- **Installation Manifest:** `/mnt/c/AbeOS/docs/dev/INSTALLATION_MANIFEST.md`
- **Setup Scripts:** `/mnt/c/AbeOS/scripts/dev-env/`

---

**Last Updated:** 2025-01-15
**Maintainer:** AbeOS Team
