# 🧠 Abraham's **AbeOS** — Hyper-Personalized Windows 11 Environment

_(for Music Production 🎹 + Gaming 🎮 + Coding 💻 + Streaming 📡 + macOS Aesthetic 🍎 + Automation 🤖 + Backup & Security 🔒)_

> **Hardware:** ASUS ROG Zephyrus G14 (RTX 4070 / Ryzen 9)
> **Core Concept:** _Dual-Mode Workstation with Modular Overlay_ > **Design Modes:**
>
> - 🎨 **Creator Mode** → Music Production / Streaming (Low Latency, GPU-Conserving)
> - ⚡ **Performance Mode** → Gaming / Development (Max Clocks, FPS, Fidelity)
>   **System Philosophy:**
> - Overlay architecture (AbeOS lives _alongside_, not _inside_ Windows OS)
> - Modular install / uninstall
> - Reproducible setup via declarative scripts
> - Aesthetic harmony + zero-latency performance
> - Full disaster recovery and automated maintenance

**Last Updated:** `November 2025`
## ✅ PHASE 1 — BASELINE SYSTEM SETUP

### 1. Windows Core Optimization

- [x] Clean install Windows 11 Home
- [x] Remove OEM and bloatware via `O&O AppBuster`
- [x] Remove OneDrivie and decouple it as a default User folders.
- [x] Set local user folders (i.e.: Documents, Pictures, Videos, Downloads, etc)
- [x] Enable Ultimate Performance power plan
- [x] Disable Hibernation, Fast Startup, SysMain
- [x] Optimize file indexing + Explorer performance
- [x] Set pagefile to manual fixed size
- [x] Sync Microsoft account (for license, backup)

### 2. Hardware Drivers & BIOS

- [x] Install latest BIOS (ASUS)
- [x] Install NVIDIA, AMD, chipset, audio, and USB drivers
- [x] Undervolt GPU via MSI Afterburner
- [x] Undervolt CPU and calibrate fan power level for different modes for GHelper

### ✅ PHASE 2 - DEVELOPER ENVIRONMENT

### 1 Shell Foundations

- [x] Capture current PowerShell profile into repo (`configs/terminal/Microsoft.PowerShell_profile.ps1`) and keep `$PROFILE` synced.
- [x] Capture current `~/.bashrc` into `configs/terminal/bashrc` and source it from WSL installs.
- [x] Ensure both shells load the shared Oh My Posh theme from `configs/terminal/abe.omp.json`.
- [x] Align default working directories (`C:\projects` vs `/mnt/c/projects`) and helper aliases (`cdproj`, `mcl`, etc.).

### 2 WSL2 / Linux Toolchain

- [x] Confirm WSL2 features enabled + Ubuntu distro updated (`wsl --update`, `apt upgrade`).

### 3 Node.js / JavaScript Stack

- [x] WSL: Manage Node versions with NVM (currently v20.19.5 default, v24.11.1 installed). Ensure `npm list -g` global packages stay mirrored (eslint, prettier, ts-node, pnpm, yarn, nodemon, @anthropic-ai/claude-code, @openai/codex, etc.). → Install-Node-DevTools.sh + Install-WebDev-Packages.sh
- [x] Windows: Audit NVM for Windows / Corepack status; install matching Node LTS, PNPM, Yarn. → Install-Windows-DevTools.ps1
- [x] Configure project templates for PERN stack (Postgres, Node, Tailwind CLI)

### 4 Python / AI Toolchain

- [x] Install Python 3.11+ on Windows + WSL. → Install-Python-AI-DevTools.sh + Install-Windows-DevTools.ps1
- [x] Install CUDA Toolkit, cuDNN, TensorRT, and PyTorch builds matching GPU (4070) for Windows + WSL. → Install-Python-AI-DevTools.sh (PyTorch with CUDA)
- [x] Install Hugging Face CLI, `whisper`, FFmpeg bindings, dependencies. → Install-Python-AI-DevTools.sh
- [x] Set up Conda for ML sandboxing. → Install-Miniconda.sh + Install-Python-AI-DevTools.sh (UV)

### 6 Dev Productivity

- [x] Install Docker Desktop with WSL integration → Install-Windows-DevTools.ps1
- [x] Install PgAdmin4, Pycharm, WSL
- [x] Install VS Code + Extensions list (Remote - WSL, Remote SSH, GitHub Copilot, Prisma, Thunder Client, etc.). → Install-Windows-DevTools.ps1 + Install-VSCode-Extensions.sh
- [x] Clone key repos from githubb.com/abrahamahn/ (Blendtune, ProScan, ABE-Stack, etc.) onto Dev Drive with sparse checkout templates. → Setup-ProjectDirectories.sh (creates structure)
- [x] Configure GitHub CLI + SSH keys (YubiKey integration) and gpg-sign commits. → Install-Windows-DevTools.ps1 (GitHub CLI)
- [x] CaskaydiaCove Nerd Font Mono globally; ensure Windows Terminal / VS Code pick it up. → Install-Windows-DevTools.ps1

### 8 Automation

- [ ] Script `Install-DevTools.ps1` / `Install-DevTools.sh` to apply the above packages sequentially per shell. → Setup-DevEnvironment.ps1 (Master orchestrator), Install-All-DevTools.sh
- [ ] Add verification script to ensure Node/Python/Java/C++/CUDA/WSL components report expected versions. → Verify-Installation.sh
- [ ] Document environment variables (`UV_USE_PYTHON`, `CUDA_PATH`, `NPM_TOKEN`, etc.) in `configs/core/terminal/README.md`.

### 9 Check

- [x] Check if everything was successfully installed. → Verify-Installation.sh provides comprehensive verification

---

## 🎮 PHASE 3 — GAMING ENVIRONMENT

### 1. Platforms & Tools

- [x] Install Steam + Steam Games
  [x] Install Emulators: PS1–PS4, Dream Sega, N64, Xbox
- [x] Organize all ROMs under `C:\Gaming\ROMS`
- [x] Install Lossless Scaling, ReShade, SpecialK
- [x] Benchmark with CapFrameX + RTSS

### 2. Performance & GPU Settings

- [x] Optimize NVIDIA Control Panel

---

## 📡 PHASE 4 — STREAMING & CREATOR MODE

### 1. OBS & Encoder Setup

- [X] Install OBS + StreamLabs
- [x] Create scenes:
  - Game + Chat
  - DAW + Mixer
  - Just Chatting
- [x] NVENC Settings
- [x] Add Hotkeys:
  - `Ctrl+Shift+S` → Start Stream
  - `Ctrl+Shift+R` → Record Session

### 2. Audio Routing (VoiceMeeter)

- [x ] Install Voicemeeter Banana
- [x ] Route:
  - Mic → Input 1
  - FL Studio → AUX1
  - Game Audio → AUX2
  - Output → OBS Virtual Cable
- [x ] Save profiles:
  - `Music.xml`, `Gaming.xml`, `Streaming.xml`
- [ x] Integrate in `Mode-Switcher.ps1`

### 3. GPU-Aware Mode Switching

- [ ] Implement Afterburner + GHelper profiles:
  - Creator Mode → 85W GPU, Balanced Fans
  - Performance Mode → Max Clocks, Turbo Fans
- [ ] Apply via:
  ```powershell
  .\stages\08_automation\01_mode_switcher\Mode-Switcher.ps1 Creator
  ```
---

## 🍎 PHASE 5 — UI CUSTOMIZATION (macOS + Cyberpunk Fusion)

### 1. Visual Enhancements

- [x] Install Mica For Everyone + Explorer Mica for translucent Window Effects
- [x] Install StartAllBack, and init themes with customized docks
- [x] Set Windows 11 default settings personalization into dark mode, accent colors.
- [x] Set Transparency Effects and Animation Effects 'On'
- [x] Set custom static wallpaper

### 2. Fonts & Icons

- [x] CaskaydiaCove Nerd Font Mono Nerd Font Mono
- [x] macOS-style icon pack
- [x] Custom cursors (AeroLite / macOS)
- [x] Apply color scheme:

### 3. Gestures & Input

- [x] Custom Settings on Bluetooth & Devices > Touchpad

---

## 🎹 PHASE 6 — MUSIC PRODUCTION ENVIRONMENT

### 1. DAW + Plugins

- [ ] Install FL Studio + Ableton Live
- [ ] Centralize all VST2/VST3 paths:
  - `C:\Production\VST2`
  - `C:\Production\VST3`
- [ ] Fix registry paths for relocated plugins
- [ ] Use `Vst-Registry.psm1` to sync all plugin entries
- [ ] Organize by type:
  - Instruments / FX / Dynamics / Reverbs / Utilities
- [ ] Validate all plugin licenses
- [ ] Setup plugin managers (Arturia, Waves, NI, iLok, etc.)
- [ ] Backup license states (`licenses/STATUS.md`)

### 2. Audio Routing & Interfaces

- [ ] Install VoiceMeeter Potato + Virtual Cables
- [ ] Install ASIO4All + OBS-ASIO + ReaRoute
- [ ] Configure Apogee Duet 3 as master interface
- [ ] Create 3 routing profiles:
  - 🎧 **Music** – ASIO only
  - 🎮 **Gaming** – FlexASIO
  - 📡 **Streaming** – VoiceMeeter Hybrid
- [ ] Implement `Set-AudioMode.ps1` for quick switching
- [ ] Add `Reset-Audio.ps1` (restart audio services)

### 3. Library Organization

- [ ] Organize Samples: `C:\Production\Samples`
- [ ] Categorize Drums, FX, Loops, Vocals, MIDI
- [ ] Deduplicate using `fdupes` or PowerShell scripts
- [ ] Organize Presets (Instruments / FX)
- [ ] Create “Master Template Project” per DAW
- [ ] Backup Projects to Cloud + External SSD

---

## 📱 PHASE 7 — iOS INTEROPERABILITY

### 1. File Transfer (Airdrop)

* [ ] Install LocalSend (Windows + iOS)
* [ ] Add context menu: “Send to iPhone via LocalSend”
* [ ] Backup fallback: Snapdrop web app

### 2. Clipboard Sync

* [ ] Use LocalSend text sharing or PushBullet API
* [ ] PowerShell bridge: monitor clipboard and push to iOS
* [ ] Add AutoHotKey shortcut: `Ctrl+C` → sync clipboard

### 3. File Sync

* [ ] Setup Syncthing: `C:\Production\Mobile` ↔ iPhone “Files”
* [ ] Sync Obsidian vaults for project notes

---

## 🔐 PHASE 8 — BACKUP, SECURITY & RELIABILITY

### 1. Backup Strategy (3–2–1)

| Layer    | Tool                     | Frequency                      | Destination  |
| -------- | ------------------------ | ------------------------------ | ------------ |
| Local    | Macrium Reflect / Hasleo | Weekly Full, Daily Incremental | E:\Images    |
| External | Veeam Agent              | 15-min Backup for Production   | F:\Veeam     |
| Cloud    | rclone + Backblaze B2    | Nightly                        | `b2://abeos` |

### 2. Automation

* [ ] `Daily-Maintenance.ps1`

  * Winget upgrade all
  * Clean temp + caches
  * Registry snapshot
  * Backup system logs
* [ ] `Auto-Backup.ps1`

  * Mirror C:\Production → E:\Backups\Daily
* [ ] Schedule:

  * Logon → Mode-Switcher.ps1 (Performance)
  * OBS Launch → Set Creator Mode
  * 3 AM → Daily Maintenance

### 3. Security

* [ ] AppLocker (Pro/Enterprise) → whitelist only signed apps
* [ ] Defender Firewall → outbound block except whitelisted
* [ ] YubiKey → Windows Hello + Git auth
* [ ] AdGuard Home → local DNS filtering
* [ ] Windows Sandbox → test plugins safely
* [ ] Registry export nightly → `C:\AbeOS\configs\core\backup\reg\`
- [ ] Encrypt SSD with Bitcrypt or something

#### 4 Content Filtering & Parental Controls

**Goal:** Block porn, gambling, NSFW, malicious, and harmful websites system-wide

**Multi-Layer Approach:**

- [x] **DNS-Level Filtering (Primary)**
- [x] Configure DNS to use family-safe servers:
- [ ] Cloudflare Family (1.1.1.3 / 1.0.0.3) - Blocks malware + adult content
- [ ] OpenDNS FamilyShield (208.67.222.123 / 208.67.220.123)
- [ ] CleanBrowsing Family (185.228.168.168 / 185.228.169.168)
- [ ] Apply via: Network adapter settings + Router settings (double protection)
- [ ] Script: `Set-SafeDNS.ps1` → Auto-configure all adapters
- [ ] **Local DNS Filtering (AdGuard Home / Pi-hole)**
- [ ] Install AdGuard Home locally (runs as Windows service)
- [ ] Import blocklists:
    * OISD Big List (comprehensive)
    * Steven Black's hosts (malware + adult)
    * Gambling blocklist
    * Energized Ultimate
- [ ] Point system DNS to 127.0.0.1 (localhost)
- [ ] Script: `Install-AdGuardHome.ps1` → Automated setup
- [ ] **Browser-Level Protection**
- [ ] Enable SafeSearch (Google, Bing, DuckDuckGo)
- [ ] Install browser extensions:
- uBlock Origin (with adult content filters)
- WebFilter Pro
- [ ] Script: `Configure-SafeSearch.ps1` → Lock SafeSearch on

- [ ] **Windows Built-in Controls**
- [ ] Enable Microsoft Family Safety
- [ ] Configure Windows Defender SmartScreen
- [ ] Block adult content in Microsoft Edge-
- [ ] Script: `Enable-FamilySafety.ps1`

* [ ] **Network-Level Backup**
- [ ] Configure router-level DNS filtering
- [ ] Enable router's parental controls (ASUS ROG router)
- [ ] Fallback if local DNS bypassed

* [ ] **Monitoring & Reporting**
  * [ ] AdGuard Home dashboard (localhost:3000)
  * [ ] Weekly reports of blocked requests
  * [ ] Alert on bypass attempts
  * [ ] Script: `Get-FilteringReport.ps1`

**Scripts to Create:**
* `Set-SafeDNS.ps1` - Configure DNS servers on all adapters
* `Install-AdGuardHome.ps1` - Install and configure AdGuard Home
* `Import-Blocklists.ps1` - Add comprehensive blocklists
* `Configure-SafeSearch.ps1` - Lock SafeSearch in browsers
* `Enable-FamilySafety.ps1` - Configure Windows Family Safety
* `Test-ContentFilter.ps1` - Verify blocking is working
* `Get-FilteringReport.ps1` - Generate weekly reports

### 4. Disaster Recovery

* [ ] `AbeOS.iso` (NTLite custom image + drivers)
* [ ] Ventoy USB boot → AbeOS + Hirens + Ubuntu
* [ ] `setup.ps1` → full reinstall automation
* [ ] One-click restore via Macrium or Hasleo
---

## 🧠 PHASE 9 — AUTOMATION & MAINTENANCE

### Core Scripts

* [ ] `Mode-Switcher.ps1` → Creator / Performance toggle
* [ ] `Reset-Audio.ps1` → restart audio stack
* [ ] `Check-StreamingReady.ps1` → verify OBS + VoiceMeeter
* [ ] `New-Symlinks.ps1` → recreate junctions
* [ ] `Health-Report.ps1` → logs status summary

### Scheduled Jobs

* [ ] `Daily-Maintenance.ps1` at 3 AM
* [ ] `Auto-Backup.ps1` nightly
* [ ] OBS launch event triggers Creator Mode

### Logging

* [ ] All scripts write to `/logs/system.log`
* [ ] Daily summary → Toast notification

---
## 🚀 PHASE 10 — CLEANUP & BACKUP
- [ ] Do a full snapshot backup to external SSD 1
- [ ] Do a local file transfer backup to external SSD 2, 3 for production libraries and projects

## 🚀 PHASE 11 — FUTURE EXPANSIONS

* [ ] Build “AbeOS Control Center” GUI (PowerShell or Tauri)
* [ ] Add Auto Mode Detection (OBS/game triggers)
* [ ] Integrate AI LLM command helper in terminal
* [ ] Add system telemetry overlay (Rainmeter + HWiNFO)
* [ ] Publish AbeOS open-source setup scripts
* [ ] Export AbeOS snapshots (version-controlled state)

---

## 🔚 Summary

**AbeOS Philosophy:**

> Modular. Aesthetic. Performant. Reproducible. Secure.

* Overlay, not invasive → easy rollback
* Fully scriptable & automated setup
* Cross-functional: Stream, Code, Create, Game
* Backup-driven design ensures no loss ever
* macOS elegance + Windows power + Linux flexibility

---

**Goal:**
A Windows environment so optimized, it behaves like a **personalized OS layer** — fast, beautiful, and production-grade.

**Next step:**

> Execute `setup.ps1` → install base modules
> Then `Mode-Switcher.ps1 Performance` or `Mode-Switcher.ps1 Creator`
```
