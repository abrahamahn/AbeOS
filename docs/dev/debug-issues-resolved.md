# ✅ Debug Issues - Resolution Verification

**Last Updated:** 2025-11-16
**Status:** All critical issues from DEBUG.md, DEBUG2.md, DEBUG3.md are RESOLVED

---

## 📋 Summary

All major issues encountered during the initial developer environment setup have been addressed in the current installation scripts. This document verifies that each problem has a corresponding fix.

---

## 🐛 Issue 1: WSL PATH Contamination

### Problem (from debug-wsl-setup.md)
- Windows paths bleeding into WSL environment
- `/mnt/c/Program Files/nodejs`, `/mnt/c/Windows/...` appearing in `$PATH`
- Caused conflicts between Windows and WSL tools

### ✅ Solution Implemented
**Script:** `scripts/dev-environment/Configure-WSL.sh`

**Lines 54-63:**
```bash
sudo tee /etc/wsl.conf >/dev/null <<EOF
[boot]
systemd=true

[user]
default=$WSL_USER

[interop]
appendWindowsPath=false
EOF
```

**Verification:**
- ✅ Creates `/etc/wsl.conf` with `appendWindowsPath=false`
- ✅ Explicitly disables Windows PATH injection
- ✅ Includes diagnostic check (lines 112-120)
- ✅ Creates `~/verify-wsl.sh` for post-install validation

---

## 🐛 Issue 2: wsl.conf CRLF Line Endings

### Problem (from debug-root-cause-analysis.md)
- `/etc/wsl.conf` showing as "Windows SYSTEM.INI"
- DOS-style CRLF endings (`\r\n`) instead of LF
- WSL silently ignored the config file
- Resulted in Windows PATH still being appended

### ✅ Solution Implemented
**Script:** `scripts/dev-environment/Configure-WSL.sh`

**Lines 67-85:**
```bash
# Step 2: Convert any CRLF to LF (just in case)
log_info "Ensuring LF line endings..."
sudo sed -i 's/\r$//' /etc/wsl.conf
log_success "Line endings verified"

# Step 3: Verify file integrity
log_info "Verifying file integrity..."

# Check for CRLF
if xxd /etc/wsl.conf | grep -q "0d0a"; then
    log_error "CRLF line endings detected! File may be corrupted."
    exit 1
else
    log_success "No CRLF detected - file is clean"
fi
```

**Verification:**
- ✅ Uses `sudo tee` which creates proper LF endings
- ✅ Explicitly converts CRLF to LF with `sed -i 's/\r$//'`
- ✅ Verifies with `xxd` hex dump check
- ✅ Exits with error if CRLF detected
- ✅ File integrity check before continuing

---

## 🐛 Issue 3: npm Global Prefix Pointing to Windows

### Problem (from debug-root-cause-analysis.md)
- `npm root -g` returned: `C:\Users\abe\AppData\Roaming\npm\node_modules`
- Global packages installed to Windows paths
- WSL could not execute Windows-installed npm binaries
- `codex: command not found` despite installation
- Permission errors on `npm install -g`

### ✅ Solution Implemented
**Script:** `scripts/dev-environment/Install-Node-DevTools.sh`

**Lines 135-147:**
```bash
# CRITICAL: Set npm global prefix to avoid Windows PATH contamination
npm config set prefix "$HOME/.npm-global"
log_success "npm configured with global prefix: $HOME/.npm-global"

# Add npm global bin to PATH if not present
if ! grep -q ".npm-global/bin" ~/.bashrc; then
    echo 'export PATH="$HOME/.npm-global/bin:$PATH"' >> ~/.bashrc
    log_info "Added npm global bin to PATH in ~/.bashrc"
fi

# Export for current session
export PATH="$HOME/.npm-global/bin:$PATH"
log_success "npm global bin added to PATH for current session"
```

**Verification:**
- ✅ Sets npm global prefix to `~/.npm-global`
- ✅ Adds to PATH in `~/.bashrc`
- ✅ Exports for current session
- ✅ Prevents Windows path contamination

**Expected Result:**
```bash
npm root -g
# Output: /home/<user>/.npm-global/lib/node_modules
```

---

## 🐛 Issue 4: System Node.js from apt

### Problem (from debug-root-cause-analysis.md)
- Ubuntu system Node.js v12.22.9 installed via `apt`
- Ancient version incompatible with modern tools
- Conflicted with NVM installation
- `@openai/codex` requires Node ≥16

### ✅ Solution Implemented
**Script:** `scripts/dev-environment/Install-Node-DevTools.sh`

**Lines 37-48:**
```bash
# CRITICAL: Remove system Node.js if installed via apt
# This prevents conflicts with NVM (see DEBUG.md for details)
if command -v node &> /dev/null; then
    NODE_PATH=$(which node)
    if [[ "$NODE_PATH" == "/usr/bin/node" ]]; then
        log_warning "System Node.js found (installed via apt)"
        log_warning "Removing to prevent conflicts with NVM..."
        sudo apt purge -y nodejs npm
        sudo apt autoremove -y
        log_success "System Node.js removed"
    fi
fi
```

**Verification:**
- ✅ Detects system Node.js from apt
- ✅ Automatically removes with `apt purge`
- ✅ Cleans up dependencies with `autoremove`
- ✅ Only proceeds if Node is in `/usr/bin/node`

---

## 🐛 Issue 5: PowerShell Profile Fragmentation

### Problem (from debug-powershell-profiles.md)
- Multiple profile locations:
  - `C:\Users\abe\OneDrive\Documents\PowerShell\profile.ps1`
  - `C:\Users\abe\OneDrive\Documents\PowerShell\Microsoft.VSCode_profile.ps1`
  - `C:\Program Files\PowerShell\7\profile.ps1`
  - `C:\Program Files\PowerShell\7\Microsoft.VSCode_profile.ps1`
- Different behavior in VS Code vs Windows Terminal
- Claude CLI worked in Admin terminal but not VS Code
- PATH inconsistencies across environments

### ✅ Solution Implemented
**Script:** `scripts/dev-environment/Setup-PowerShell-Profile.ps1`

**Lines 72-112:**
```powershell
# Define all PowerShell profile locations
$ProfileLocations = @(
    @{
        Path = "$env:USERPROFILE\OneDrive\Documents\PowerShell\profile.ps1"
        Description = "User CurrentUserAllHosts (OneDrive)"
        RequiresAdmin = $false
    },
    @{
        Path = "$env:USERPROFILE\OneDrive\Documents\PowerShell\Microsoft.PowerShell_profile.ps1"
        Description = "User CurrentUserCurrentHost (OneDrive)"
        RequiresAdmin = $false
    },
    @{
        Path = "$env:USERPROFILE\OneDrive\Documents\PowerShell\Microsoft.VSCode_profile.ps1"
        Description = "VS Code Profile (OneDrive)"
        RequiresAdmin = $false
    },
    # AllUsers profiles (require admin)
    @{
        Path = "$env:ProgramFiles\PowerShell\7\profile.ps1"
        Description = "AllUsers AllHosts"
        RequiresAdmin = $true
    },
    @{
        Path = "$env:ProgramFiles\PowerShell\7\Microsoft.PowerShell_profile.ps1"
        Description = "AllUsers CurrentHost"
        RequiresAdmin = $true
    },
    @{
        Path = "$env:ProgramFiles\PowerShell\7\Microsoft.VSCode_profile.ps1"
        Description = "AllUsers VS Code"
        RequiresAdmin = $true
    }
)

# Unified profile loader content
$LoaderContent = @"
# AbeOS PowerShell Profile Loader
# This file sources the unified AbeOS PowerShell configuration
. "$AbeosCoreProfile"
"@
```

**Lines 164-168:**
```powershell
# Write unified loader
try {
    Set-Content -Path $ProfilePath -Value $LoaderContent -Force -Encoding UTF8
    Log-Success "  Configured successfully"
    $ProfilesConfigured++
```

**Verification:**
- ✅ Configures ALL 6 PowerShell profile locations
- ✅ Each profile sources single core: `abeos.pwsh.profile.ps1`
- ✅ Backs up existing profiles before modification
- ✅ Handles admin vs non-admin scenarios
- ✅ Creates directories if missing
- ✅ UTF8 encoding for all profiles

---

## 🐛 Issue 6: Claude CLI Not in PATH

### Problem (from debug-powershell-profiles.md)
- `C:\Users\abe\.local\bin` missing from USER PATH
- Claude CLI installed but not accessible
- `claude: command not found` in some terminals

### ✅ Solution Implemented
**Script:** `scripts/dev-environment/Setup-PowerShell-Profile.ps1`

**Lines 56-69:**
```powershell
# Add Claude path to USER PATH if missing
$UserPath = [Environment]::GetEnvironmentVariable("Path", "User")
if ($UserPath -notlike "*$ClaudePath*") {
    Log-Info "Adding Claude path to USER PATH..."
    $NewPath = $UserPath + ";" + $ClaudePath
    [Environment]::SetEnvironmentVariable("Path", $NewPath, "User")
    Log-Success "Claude path added to USER PATH"

    # Reload PATH for current session
    $env:Path = [System.Environment]::GetEnvironmentVariable("Path", "User") + ";" +
                [System.Environment]::GetEnvironmentVariable("Path", "Machine")
} else {
    Log-Success "Claude path already in USER PATH"
}
```

**Verification:**
- ✅ Checks if `$env:USERPROFILE\.local\bin` in PATH
- ✅ Adds to USER environment variable (persistent)
- ✅ Reloads PATH in current session
- ✅ Validates Claude CLI exists before proceeding

---

## 🐛 Issue 7: Oh My Posh Theme Not Loading

### Problem
- Oh My Posh theme not loading consistently
- Different themes in different terminals
- Theme file path issues

### ✅ Solution Implemented
**File:** `configs/core/terminal/bashrc.core`

**Lines 69-73:**
```bash
# --- Oh My Posh Initialization (WSL Safe) ---
# Only run if the binary exists — prevents errors
if command -v oh-my-posh >/dev/null 2>&1; then
  eval "$(oh-my-posh init bash --config '/mnt/c/AbeOS/configs/core/terminal/abe.omp.json')"
fi
```

**File:** `configs/core/terminal/bashrc`

**Lines 1-9:**
```bash
# Remove Windows NodeJS (handles spaces and escapes)
PATH=$(echo "$PATH" | tr ':' '\n' | grep -vE '/mnt/c/Program(\\)? Files/nodejs' | paste -sd:)
export PATH

if [ -f /mnt/c/AbeOS/configs/core/terminal/bashrc.core ]; then
  . /mnt/c/AbeOS/configs/core/terminal/bashrc.core
else
  echo "AbeOS bash profile not found at /mnt/c/AbeOS/configs/core/terminal/bashrc.core" >&2
fi
```

**Verification:**
- ✅ Unified loader in `bashrc` sources `bashrc.core`
- ✅ Oh My Posh loaded from single theme file: `abe.omp.json`
- ✅ Conditional loading (only if oh-my-posh exists)
- ✅ Removes Windows Node.js from PATH before loading
- ✅ Fallback error message if profile not found

---

## 📊 Verification Checklist

### WSL Environment
Run these commands in WSL to verify fixes:

```bash
# 1. Check wsl.conf is correct
cat /etc/wsl.conf
# Expected: appendWindowsPath=false, systemd=true

# 2. Verify no CRLF
xxd /etc/wsl.conf | grep "0d0a"
# Expected: No output

# 3. Check PATH has no Windows contamination
echo "$PATH" | tr ':' '\n' | grep "/mnt/c"
# Expected: No output (or only intentional mounts)

# 4. Verify npm global prefix
npm root -g
# Expected: /home/<user>/.npm-global/lib/node_modules

# 5. Check Node.js is from NVM
which node
# Expected: /home/<user>/.nvm/versions/node/v20.x.x/bin/node

# 6. Verify global binaries work
which codex
# Expected: /home/<user>/.npm-global/bin/codex

# 7. Test Oh My Posh loading
echo $OMP_CONTAINER
# Expected: WSL
```

### PowerShell Environment
Run these commands in PowerShell:

```powershell
# 1. Check Claude CLI in PATH
$env:PATH -split ';' | Select-String "\.local\\bin"
# Expected: C:\Users\<user>\.local\bin

# 2. Verify Claude CLI works
claude --version
# Expected: Version output

# 3. Check profile locations
$PROFILE | Get-Member -MemberType NoteProperty
# All should point to profile files

# 4. Verify unified loader
Get-Content $PROFILE.CurrentUserCurrentHost
# Expected: . "C:\AbeOS\configs\core\terminal\abeos.pwsh.profile.ps1"

# 5. Test profile loaded
$AbeOSLoaded
# Expected: $true (if defined in abeos.pwsh.profile.ps1)
```

---

## 🎯 Summary

All **7 critical issues** from the debug sessions are now resolved:

| Issue | Script | Status |
|-------|--------|--------|
| 1. WSL PATH contamination | Configure-WSL.sh | ✅ Fixed |
| 2. wsl.conf CRLF endings | Configure-WSL.sh | ✅ Fixed |
| 3. npm global prefix to Windows | Install-Node-DevTools.sh | ✅ Fixed |
| 4. System Node.js from apt | Install-Node-DevTools.sh | ✅ Fixed |
| 5. PowerShell profile fragmentation | Setup-PowerShell-Profile.ps1 | ✅ Fixed |
| 6. Claude CLI not in PATH | Setup-PowerShell-Profile.ps1 | ✅ Fixed |
| 7. Oh My Posh theme inconsistency | bashrc + bashrc.core | ✅ Fixed |

---

## 🔧 How to Apply These Fixes

### Automated (Recommended):
```powershell
# Run the master orchestrator
cd C:\AbeOS\scripts\dev-environment
.\Setup-DevEnvironment.ps1
```

This handles:
- Windows tool installation
- WSL configuration
- Automatic restarts
- All development tools
- Profile setup

### Manual (for troubleshooting):
```powershell
# 1. Configure WSL
wsl bash /mnt/c/AbeOS/scripts/dev-environment/Configure-WSL.sh

# 2. Restart WSL
wsl --shutdown
# Wait 5 seconds, then reopen WSL

# 3. Install Node.js tools
wsl bash /mnt/c/AbeOS/scripts/dev-environment/Install-Node-DevTools.sh

# 4. Setup PowerShell profiles
.\Setup-PowerShell-Profile.ps1

# 5. Setup Bash profile
wsl bash /mnt/c/AbeOS/scripts/dev-environment/Setup-Bash-Profile.sh
```

---

## 📝 Related Documentation

- [debug-wsl-setup.md](./debug-wsl-setup.md) - Original WSL PATH issues
- [debug-powershell-profiles.md](./debug-powershell-profiles.md) - PowerShell fragmentation
- [debug-root-cause-analysis.md](./debug-root-cause-analysis.md) - npm and Node.js issues
- [phase3-fixes.md](./phase3-fixes.md) - Comprehensive fix documentation

---

**Conclusion:** All critical PATH, profile, and configuration issues have been resolved in the current scripts. The installation process is now robust and reproducible.
