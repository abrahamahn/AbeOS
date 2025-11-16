# 🛠️ `DEBUG.md`

**AbeOS Development Environment — Root Cause Analysis & Fix Guide**
_(WSL, Node, npm, PATH, Codex, and PowerShell Profile issues)_

---

# 1. Overview

This document tracks the **major issues encountered** during the setup of AbeOS development environments across:

- **Windows (PowerShell 7 / VS Code Terminal)**
- **WSL Ubuntu 22.04**
- **Node.js + npm (dual installs between Windows and WSL)**
- **Global npm packages not linking**
- **Codex CLI not available**
- **Broken PATH propagation**
- **WSL config incorrectly recognized as SYSTEM.INI**

The problems originated from a **mix of multiple environments**, each injecting paths that conflict with one another.

This document defines **root causes**, **repro steps**, **diagnosis commands**, and the **correct repair procedure**.

---

# 2. Symptoms

### ❌ WSL Node is incorrect

Inside WSL:

```
node -v → v12.22.9   # ancient, installed from apt
npm -v → 8.5.1       # system npm
```

This causes:

- `npm install -g` → `EACCES` (permission denied)
- `@openai/codex` cannot run because Node <16
- `npm root -g` returns Windows paths (`C:\Users\abe\AppData\Roaming`)
- Global binaries are never symlinked → `codex: command not found`

---

### ❌ WSL global npm prefix points to Windows paths

In WSL:

```
npm root -g → C:\Users\abe\AppData\Roaming\npm\node_modules
```

This is **fundamentally broken**:

- WSL cannot run Windows global npm binaries
- Windows cannot see WSL-installed npm tools

---

### ❌ `/etc/wsl.conf` showing as "Windows SYSTEM.INI"

WSL reported:

```
file /etc/wsl.conf → Windows SYSTEM.INI
```

Cause:

- DOS-style CRLF endings (`\r\n`)
- WSL refuses to interpret file as config → silently ignores it

---

### ❌ PowerShell profiles split across locations

Profiles existed in:

```
C:\Users\abe\OneDrive\Documents\PowerShell\profile.ps1
C:\Users\abe\OneDrive\Documents\PowerShell\Microsoft.VSCode_profile.ps1
C:\Program Files\PowerShell\7\profile.ps1
C:\Program Files\PowerShell\7\Microsoft.VSCode_profile.ps1
```

This caused:

- different behavior in VS Code vs Windows Terminal
- Claude CLI available in Admin terminal, not in VS Code

---

### ❌ Codex CLI never appears inside WSL

Repeated messages:

```
codex: command not found
npm root -g → Windows folder
npm install -g @openai/codex → permission issues + no symlink
```

---

# 3. Root Causes Summary

| Root Cause                                      | Description                                                                |
| ----------------------------------------------- | -------------------------------------------------------------------------- |
| **1. System Node installed from apt**           | Ubuntu installed Node v12 → incompatible with modern tooling               |
| **2. npm global prefix mapped to Windows**      | Caused Codex to install to `/mnt/c/...` which WSL cannot execute           |
| **3. WSL missing or broken `/etc/wsl.conf`**    | CRLF → WSL treated it as SYSTEM.INI → PATH was polluted with Windows paths |
| **4. Multiple conflicting PowerShell profiles** | VS Code, Windows Terminal, and Admin PS had different PATHs                |
| **5. Missing `$HOME/.npm-global/bin` in PATH**  | No global binaries visible                                                 |
| **6. Missing WSL binary shims**                 | Installing global npm packages did not produce `/usr/bin/codex`            |

---

# 4. Diagnostic Commands

_(Run inside WSL)_

```
node -v
npm -v
npm root -g
which codex
which node
which npm
file /etc/wsl.conf
stat /etc/wsl.conf
xxd /etc/wsl.conf | head
mount | grep " on / "
```

---

# 5. The Fix — EXACT PROTOCOL

## ✔ Step 1 — Remove broken system Node

```bash
sudo apt purge -y nodejs npm
sudo apt autoremove -y
```

Verify it's gone:

```bash
which node
which npm
```

Both should be empty.

---

## ✔ Step 2 — Install Node properly via NVM

```bash
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.1/install.sh | bash
source ~/.bashrc

nvm install 20
nvm use 20
```

Verify:

```bash
node -v
npm -v
```

---

## ✔ Step 3 — Fix global npm path

```bash
npm config set prefix ~/.npm-global
echo 'export PATH="$HOME/.npm-global/bin:$PATH"' >> ~/.bashrc
source ~/.bashrc
```

Check:

```bash
npm root -g
```

Should be:

```
/home/abe/.npm-global/lib/node_modules
```

---

## ✔ Step 4 — Recreate `/etc/wsl.conf` properly

```bash
sudo tee /etc/wsl.conf >/dev/null <<EOF
[boot]
systemd=true

[user]
default=abe

[interop]
appendWindowsPath=false
EOF

sudo sed -i 's/\r$//' /etc/wsl.conf
```

Reboot WSL:

```bash
wsl.exe --shutdown
```

---

## ✔ Step 5 — Install Codex CLI (works now)

Inside WSL:

```bash
npm install -g @openai/codex
```

Check:

```bash
which codex
codex --help
```

---

# 6. Verification Checklist

| Test                 | Expected                            |                     |
| -------------------- | ----------------------------------- | ------------------- |
| `node -v`            | ≥ v20                               |                     |
| `npm root -g`        | `~/.npm-global/...`                 |                     |
| `codex --help`       | prints usage                        |                     |
| `which codex`        | `/home/abe/.npm-global/bin/codex`   |                     |
| `file /etc/wsl.conf` | ASCII text, NOT SYSTEM.INI          |                     |
| `mount               | grep "on / "`                       | ext4 root, not NTFS |
| PowerShell `claude`  | works in VS Code + Windows Terminal |                     |

---

# 7. Notes for Agents (Claude Code / Cursor)

### ALWAYS enforce:

- No `apt install nodejs`
- nvm as the only Node provider
- npm global path = `$HOME/.npm-global`
- `/etc/wsl.conf` must have LF line endings
- Avoid any Windows paths leaking into WSL

If WSL PATH ever contains:

```
/mnt/c/Program Files/nodejs
```

→ This is **an error**.

---

# 8. Recovery Procedure

If WSL becomes corrupted again:

```
wsl.exe --shutdown
wsl --unregister Ubuntu-22.04
wsl --install -d Ubuntu-22.04
```

Then reapply Steps 1–5.

---

# 9. Conclusion

This `DEBUG.md` captures:

- The environment conflicts
- Why Codex was never found
- Why WSL treated `/etc/wsl.conf` as SYSTEM.INI
- How Windows and WSL PATH contamination caused cross-environment failures
- And the definitive, correct setup protocol

Your AbeOS agents can now **automate**, **lint**, and **enforce** this configuration.

---
