---

# 🧩 **AbeOS Debug Log — System PATH, Terminal, and VS Code Recovery**

**Date:** 2025-11-16
**Author:** Abe (with ChatGPT assistance)
**Category:** Core System / Terminal / VS Code / Environment Repair

---

# 1. ⚙️ SYSTEM PATH CLEANUP & REBUILD

### **Problem**

- PATH was corrupted, duplicated, bloated, or missing expected entries.
- Tools like `code` were not recognized.
- Oh-My-Posh failed (`'oh-my-posh' is not recognized`).
- `winget` also not found temporarily.

### **Why**

- Several reinstalls, environment resets, and tool migrations caused:

  - Duplicated entries
  - Missing core entries
  - Invalid entries
  - Broken “user vs machine” PATH separation
  - WSL and AbeOS scripts interfering

---

## ✅ **Actions Taken**

### **1.1 Built a clean MACHINE PATH (`$systemClean`)**

We constructed a **minimal, deterministic, reproducible list** of core machine paths:

Includes:

- Windows system folders
- PowerShell 7
- Git
- dotnet
- Docker
- NVIDIA CUDA
- JDK
- Python 3.14
- SQL Server
- mingw64
- rust
- Go
- Tailscale

**Script used:**

```pwsh
$systemClean = @(
  "C:\Windows\system32",
  "C:\Windows",
  "C:\Windows\System32\Wbem",
  "C:\Windows\System32\WindowsPowerShell\v1.0\",
  "C:\Windows\System32\OpenSSH\",
  "C:\Program Files\PowerShell\7\",
  "C:\Program Files\Git\cmd",
  "C:\Program Files\dotnet\",
  "C:\Program Files\Docker\Docker\resources\bin",
  "C:\Program Files\CMake\bin",
  "C:\Program Files\NVIDIA GPU Computing Toolkit\CUDA\v12.9\bin",
  "C:\Program Files\NVIDIA GPU Computing Toolkit\CUDA\v12.9\libnvvp",
  "C:\Program Files (x86)\NVIDIA Corporation\PhysX\Common",
  "C:\Program Files\NVIDIA Corporation\Nsight Compute 2025.2.1\",
  "C:\Program Files\NVIDIA Corporation\NVIDIA App\NvDLISR",
  "C:\Program Files (x86)\Common Files\Intel\Shared Files\cpp\bin\ia32",
  "C:\Program Files (x86)\Common Files\Intel\Shared Files\cpp\bin\Intel64",
  "C:\Program Files (x86)\Common Files\Oracle\Java\java8path",
  "C:\Program Files (x86)\Common Files\Oracle\Java\javapath",
  "C:\Program Files\Eclipse Adoptium\jdk-21.0.9.10-hotspot\bin",
  "C:\Program Files\OpenJDK\jdk-21\bin",
  "C:\Python314\",
  "C:\Python314\Scripts\",
  "C:\Program Files\Microsoft SQL Server\170\Tools\Binn\",
  "C:\Program Files\Microsoft SQL Server\Client SDK\ODBC\170\Tools\Binn\",
  "C:\ProgramData\mingw64\mingw64\bin",
  "C:\ProgramData\chocolatey\bin",
  "C:\Program Files\PostgreSQL\17\bin",
  "C:\Program Files (x86)\Yarn\bin\",
  "C:\Program Files\Rust stable MSVC 1.91\bin",
  "C:\Program Files\Go\bin",
  "C:\Program Files\Tailscale\"
)

$systemFinal = $systemClean | ForEach-Object { $_.Trim() } | Sort-Object -Unique
[Environment]::SetEnvironmentVariable("PATH", ($systemFinal -join ";"), "Machine")
```

### **1.2 Rebuilt USER PATH**

User PATH kept only:

- WindowsApps
- oh-my-posh
- node
- Python
- GitHub CLI
- Local bin folder
- No duplicates, no invalid paths

**Script used:**

```pwsh
$user = @(
  "$env:LOCALAPPDATA\Microsoft\WindowsApps",
  "$env:LOCALAPPDATA\Programs\oh-my-posh\bin",
  "$env:USERPROFILE\AppData\Local\.local\bin",
  "C:\Program Files\GitHub CLI\",
  "C:\Program Files\nodejs\",
  "C:\Python314\",
  "C:\Python314\Scripts\"
)

$userFinal = $user | ForEach-Object { $_.Trim() } | Sort-Object -Unique
[Environment]::SetEnvironmentVariable("PATH", ($userFinal -join ";"), "User")
```

### **1.3 After reboot**

- All major tools worked:

  - `git`, `node`, `python`, `oh-my-posh`

- `code` still missing (because VS Code was broken)

---

# 2. 🧹 VS CODE FULL REMOVAL & CLEAN INSTALL

### **Problem**

- `code` command missing
- PATH entries existed but executable missing
- VS Code corrupted due to partial installs and AbeOS migrations

### **2.1 Fully removed old VS Code**

```pwsh
Remove-Item "$env:LOCALAPPDATA\Programs\Microsoft VS Code" -Recurse -Force
```

### **2.2 Verified registry uninstall keys**

```pwsh
reg delete "HKCU\Software\Microsoft\Windows\CurrentVersion\Uninstall\Microsoft VS Code" /f
reg delete "HKLM\Software\Microsoft\Windows\CurrentVersion\Uninstall\Microsoft VS Code" /f
```

### **2.3 Installed clean version via winget**

```pwsh
winget install Microsoft.VisualStudioCode --force
```

This installs **User setup** (`C:\Users\abe\AppData\Local\Programs\Microsoft VS Code`).

---

# 3. ✔️ FIXED `code` CLI PATH

VS Code normally adds:

```
C:\Users\abe\AppData\Local\Programs\Microsoft VS Code\bin
```

The new PATH rebuild removed that path.

### **Added back:**

```pwsh
[Environment]::SetEnvironmentVariable(
  "PATH",
  "$env:PATH;C:\Users\abe\AppData\Local\Programs\Microsoft VS Code\bin",
  "User"
)
```

Restarted terminal → `code` worked.

---

# 4. ➕ EXTENSION RESTORE

### **Detected:**

Your old extension folder survived at:

```
C:\Users\abe\.vscode\extensions
```

### **Reinstalled extensions from folder list (publisher IDs lost)**

Extensions like:

```
aaron-bond.better-comments-3.0.2
adpyke.codesnap-1.3.4
...
```

were _folder names_, not VS Code IDs.

### **We used extension.json manifests inside each folder**

→ Extracted real publisher.name format
→ Reinstalled via:

```pwsh
code --install-extension publisher.extension --force
```

---

# 5. 🎨 FONTS (CaskaydiaCove Nerd Font)

### **Problem**

- Terminal (PowerShell 7) shows icons correctly
- VS Code terminal showed broken icons

### **Reason**

VS Code uses its own font setting, not Windows Terminal fonts.

### **Fix**

Add to VS Code settings.json:

```json
{
  "terminal.integrated.fontFamily": "CaskaydiaCove Nerd Font"
}
```

VS Code now renders Nerd Font icons correctly.

---

# 6. 🔧 CUSTOM SETTINGS STORAGE (AbeOS)

### **You wanted:**

Use:

```
C:\AbeOS\configs\core\vscode\settings.json
```

### **Solution (symlink method):**

```pwsh
Remove-Item "$env:APPDATA\Code\User\settings.json" -Force

New-Item -ItemType SymbolicLink `
  -Path "$env:APPDATA\Code\User\settings.json" `
  -Target "C:\AbeOS\configs\core\vscode\settings.json"
```

Now VS Code uses AbeOS settings directly.

---

# 7. 🧩 Summary of Today’s Fixes

### ✔ PATH repair (Machine + User)

### ✔ Oh-My-Posh working again

### ✔ Winget restored

### ✔ VS Code fully removed + clean reinstall

### ✔ `code` CLI restored

### ✔ Extensions restored

### ✔ Nerd Font fixed in VS Code terminal

### ✔ Custom AbeOS settings.json integrated (symlink)

---

# 8. 📘 If you want, I can generate…

### 🔧 **AbeOS Repair Script**

1-click command that:

- fixes PATH,
- reinstalls VS Code,
- restores settings,
- restores fonts,
- restores extensions.

### 📄 **AbeOS Documentation Folder**

Auto-generated:

- PATH spec
- Terminal spec
- VS Code setup & recovery
- Fonts & theming
- Error-reference handbook

### 🚀 **AbeOS Bootstrap Installer (v1)**

Turns a fresh Windows install into your full AbeOS environment.

---
