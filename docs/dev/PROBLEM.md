# AbeOS Development: Comprehensive Problem Log & Root-Cause Analysis

This document summarizes **all major issues, system conflicts, regressions, and repeated failure modes** encountered while building AbeOS on the ROG Zephyrus G14 (Windows 11 25H2 + WSL2 + heavy customization). It also documents **root causes, symptoms, and long‑term solutions** so future iterations of AbeOS can avoid these pitfalls.

---

# 🧱 1. Privacy-Sexy / Hardening Scripts Breaking Core OS Features

## **Symptoms**

* Webcam not detected
* Microphone blocked in all apps
* Windows Hello malfunctioning
* Microsoft Store apps failing
* Snipping Tool broken
* Notifications disabled
* Skype/Slack/Zoom calls failing

## **Root Cause**

Privacy-Sexy applied irreversible registry policies:

* `CapabilityAccessManager → Deny` for mic/cam
* `AppPrivacy → LetAppsAccessX = ForceDeny`
* Disabled critical services: `FrameServer`, `WSearch`, `WbioSrvc`, etc.
* Broke WinRT/UWP runtime permissions

## **Fix**

* Manually reset all CapabilityAccessManager entries
* Re-enabled system services via PowerShell
* Repaired AppPrivacy policy keys
* Avoid all “privacy” automation scripts moving forward

---

# ⚠️ 2. Multiple Temporary User Accounts Creating SID Conflicts

## **Symptoms**

* WSL access issues
* Node.js global installs failing
* Python lockfile errors
* Git identity mismatches
* Broken VS Code profiles
* MSI installer freezing

## **Root Cause**

During troubleshooting, several temporary accounts were created (`newadmin`, `abe.zephyrusg14`, `temp`, etc.). Windows left behind:

* Extra SIDs
* Ghost `C:\Users` folders
* Duplicate permission entries
* MSI Installer entries per SID

## **Fix**

* Removed all non-essential users
* Purged ProfileList registry hives
* Cleaned Installer/UserData trees
* Reset permissions on Abe folders

---

# 🧨 3. MSI Installer Corruption, SATMO Cleanups & Failed Uninstalls

## **Symptoms**

* "Another installation is running"
* Apps half-installed
* Plugins failing to register
* Slow Windows boot
* Massive SATMO logs

## **Root Cause**

Years of accumulated:

* Broken MSI components
* Orphaned GUID folders
* Invalid WindowsInstaller pointers
* Multiple account SIDs → multiple UserData trees

## **Fix**

* Ran SATMO to purge thousands of orphaned components
* Cleaned dead SIDs from `Installer\UserData`
* Repaired Windows Installer service state

---

# 🐧 4. WSL2 Pathing, Node, and Dev Toolchain Conflicts

## **Symptoms**

* `node: not found`
* WSL unable to access Windows paths
* Duplicate Node installations
* Codex/Claude CLI broken
* Git credential errors

## **Root Cause**

* Incorrect PATH precedence between Windows and WSL
* Old Node versions in `/usr/local/bin`
* Corrupted nvm installs
* Duplicate distros in WSL

## **Fix**

* Fully cleaned `/usr/local/bin` of stale binaries
* Reinstalled NVM properly
* Cleaned Windows PATH entries
* Unified AbeOS Shell Config (PowerShell + Bash)

---

# 💻 5. VS Code Shell Fragmentation & Terminal Issues

## **Symptoms**

* Two shells launching at startup
* Warnings from PowerShell modules
* VS Code not respecting default shell
* Missing fonts / broken themes

## **Root Cause**

* Multiple VS Code profiles in AppData
* PowerShell profiles duplicated (`Microsoft.PowerShell_profile.ps1`)
* Oh-My-Posh misconfiguration
* Conflicting environment.json overrides

## **Fix**

* Rebuilt VS Code settings
* Standardized PowerShell & WSL configs
* Removed old VS Code user folders
* Unified fonts + terminal rendering

---

# 🔥 6. Registry Damage From System Tweaks (Explorer, Taskbar, UI Mods)

## **Symptoms**

* Taskbar padding breaking
* Transparent backgrounds stuck
* Explorer customizations not applying
* Icon cache becoming corrupt

## **Root Cause**

* UltraUXThemePatcher
* Windhawk taskbar mods
* Manual ExplorerFrame edits

## **Fix**

* Reverted all Explorer reg tweaks
* Rebuilt icon + Explorer cache
* Reapplied only tested, safe mods

---

# 🧭 7. OneDrive Removal Causing Broken System Paths

## **Symptoms**

* Pictures/Documents path errors
* Missing folder references
* Snipping Tool failing
* AppData redirection bugs

## **Root Cause**

* Removing OneDrive deleted Known Folder redirection entries
* Tools still referenced old `C:\Users\abe\OneDrive\…` paths

## **Fix**

* Recreated correct libraries (Pictures, Desktop, Documents)
* Cleaned orphan shell folders in registry

---

# 🎮 8. GPU / SmartShift / G-Helper Conflicts

## **Symptoms**

* MSI Afterburner ignored settings
* G-Helper overriding undervolt
* SmartShift not syncing to power plans
* Fans spiking randomly

## **Root Cause**

* Both Afterburner and G-Helper attempt to control GPU P-states
* SmartShift profiles overwritten by BIOS defaults

## **Fix**

* G-Helper controls: fans, power, SmartShift
* MSI Afterburner controls: GPU core/memory
* Locked stable fan/power JSON in AbeOS

---

# 🎧 9. Audio Stack Issues (DAW, Plugins, Virtual Mixers)

## **Symptoms**

* ASIO drivers conflicting
* Plug-ins missing
* DAW scan freezes
* Audio stuttering on reboot

## **Root Cause**

* Too many audio drivers (FlexASIO, Voicemeeter, Realtek, Dolby, ASIO4ALL)
* Plugin paths inconsistent after cleanup
* Missing registry keys

## **Fix**

* Cleaned all unused ASIO components
* Consolidated plug-in directories
* Reindexed DAWs

---

# 🧹 10. System Bloat, OEM Garbage, and Safe Removals

## **Symptoms**

* OEM tasks running
* Ryzen/ASUS telemetry
* Broken uninstallers
* Duplicate Runtimes

## **Root Cause**

* ASUS bloatware & services
* Stale tasks in Task Scheduler
* Old frameworks from temp accounts

## **Fix**

* Removed all safe-to-delete OEM components
* Rebuilt Task Scheduler
* Cleaned runtimes & duplicate components

---

# 🧩 11. Git Conflicts, Corrupt Repos, and Wrong Remotes

## **Symptoms**

* `git push` referencing wrong repo
* Missing .git folder
* Git index locks breaking commits
* Submodule issues

## **Root Cause**

* Moving directories across Windows/WSL
* Repo paths inside OneDrive (before removal)
* Wrong remote origins

## **Fix**

* Repaired .git folders
* Set correct remote origins
* Cleaned `.gitignore`
* Consolidated project structure

---

# 📦 12. Plugin & App Install Issues (PATH + Registry Mismatch)

## **Symptoms**

* Missing DLLs
* Failed installers
* Broken PATH variables
* Old uninstallers lingering

## **Root Cause**

* PATH conflicts from PowerShell + WSL
* Old DLL registry entries
* OneDrive leftovers

## **Fix**

* Rebuilt system PATH
* Cleaned `HKLM\Software\Microsoft\Windows\CurrentVersion\Uninstall`
* Consolidated installation directories

---

# 🛠 13. Windows Terminal Double-Shell Issue

## **Symptoms**

* Two terminals opening: PowerShell + pwsh
* Warning text appearing at startup

## **Root Cause**

* Duplicate profiles
* Old JSON in Windows Terminal
* Corrupt PowerShell modules

## **Fix**

* Cleaned Terminal JSON
* Removed duplicate profiles
* Rebuilt Oh-My-Posh configuration

---

# 🎯 14. General System Instability From Over-Tweaking

## **Symptoms**

* Random explorer.exe crashes
* Taskbar theming glitches
* Power plan corruption

## **Root Cause**

* Too many simultaneous system mods
* Stacking registry tweaks without rollback
* Theme patchers

## **Fix**

* Standardized AbeOS tweaks into reproducible scripts
* Avoided all third-party hardening tools

---

# 🧩 Conclusion: AbeOS Stability Lessons

To maintain a fast, stable, and high-performance AbeOS environment:

### **DO:**

* Use reproducible AbeOS scripts instead of random tweaks
* Maintain a single administrator account + `abe`
* Keep WSL PATH clean and unified
* Maintain a stable audio & GPU configuration
* Avoid privacy scripts that break core components

### **AVOID:**

* Theme patchers that modify system DLLs
* System-wide privacy tools
* Multiple temp user accounts
* Manual MSI component removal
* Overlapping GPU management tools

---

If you'd like, I can generate:

* A **TROUBLESHOOTING.md**
* A **RESTORE-GUIDE.md**
* A **AbeOS v2 System Architecture Document**
