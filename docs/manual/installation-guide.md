# AbeOS Installation Guide

## 🎯 Prerequisites

Before installing AbeOS, ensure you have:

1. **Windows 11 Pro** (clean install recommended)
2. **Administrator access** to your system
3. **PowerShell 7.0+** installed
4. **Stable internet connection** (for future installations)
5. **30-60 minutes** of available time (for full Phase 1 completion)

## 📦 Phase 1.1 Installation (Core System Optimization)

### Step 1: Prepare Your System

1. **Create a system restore point** (optional but recommended):
   ```powershell
   Enable-ComputerRestore -Drive "C:\"
   Checkpoint-Computer -Description "Pre-AbeOS" -RestorePointType "MODIFY_SETTINGS"
   ```

2. **Close all running applications** to avoid conflicts

3. **Disable antivirus temporarily** if it blocks PowerShell scripts

### Step 2: Clone or Download AbeOS

**Option A: Using Git**
```powershell
git clone https://github.com/yourusername/AbeOS.git C:\AbeOS
```

**Option B: Manual Download**
1. Download the ZIP file from GitHub
2. Extract to `C:\AbeOS`
3. Ensure the folder structure is correct

### Step 3: Verify Folder Structure

Your `C:\AbeOS` directory should look like this:
```
C:\AbeOS\
├── setup.ps1
├── README.md
├── TODO.md
├── configs/
├── stages/
├── modules/
├── assets/
├── installations/
└── logs/
```

### Step 4: Run the Master Setup Script

1. **Open PowerShell as Administrator**:
   - Press `Win + X`
   - Select "Windows PowerShell (Admin)" or "Terminal (Admin)"

2. **Navigate to AbeOS directory**:
   ```powershell
   cd C:\AbeOS
   ```

3. **Check execution policy** (if needed):
   ```powershell
   Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
   ```

4. **Run the setup script**:
   ```powershell
   .\setup.ps1
   ```

5. **Follow the prompts**:
   - Review the installation summary
   - Type `yes` to confirm
   - Wait for completion (5-10 minutes)
   - Choose whether to reboot immediately

### Step 5: Verify Installation

After rebooting, verify the changes:

1. **Check power plan**:
   ```powershell
   powercfg /list
   ```
   You should see "AbeOS - Balanced Ultimate" with an asterisk (*)

2. **Verify hibernation is off**:
   ```powershell
   powercfg /a
   ```
   Should show "Hibernation has not been enabled"

3. **Check logs for any errors**:
   ```powershell
   Get-ChildItem C:\AbeOS\logs\ | Sort-Object LastWriteTime -Descending | Select-Object -First 5
   ```

4. **Verify services**:
   ```powershell
   Get-Service -Name "SysMain" | Select-Object Status, StartType
   ```
   Should show: Status=Stopped, StartType=Disabled

## 🔧 Advanced Options

### Run Without Automatic Reboot
```powershell
.\setup.ps1 -SkipReboot
```

### Run Without Registry Backup (Not Recommended)
```powershell
.\setup.ps1 -SkipBackup
```

### Run Individual Scripts

If you want to run only specific optimizations:

```powershell
# System optimization only
.\stages\01_baseline\01_core_optimization\System-Optimization.ps1

# Explorer and indexing only
.\stages\01_baseline\01_core_optimization\Explorer-Indexing.ps1

# Privacy and UI cleanup only
.\stages\01_baseline\01_core_optimization\Privacy-UI.ps1
```

### Run Specific Phases or Steps

`setup.ps1` now reads from `configs\manifest\phases.json`, which tracks every roadmap step and whether it is `stable`, `experimental`, or `planned`. You can target slices of the manifest:

```powershell
# Resume from Explorer tuning and stop at Privacy clean-up
.\setup.ps1 -Phase phase1-core -StartAtStep explorer-indexing -StopAfterStep privacy-ui

# Include future experimental steps once they are marked ready
.\setup.ps1 -Phase all -MaxStatus experimental
```

Step identifiers match the `id` field inside the manifest file, making it easy to line up runs with TODO.md.

### Batch Install Drivers (Phase 1.2)
1. Copy your vendor driver `.exe` files to `C:\AbeOS\installations\drivers\`.
2. Edit `configs\installers\drivers.json`, populate the `installer` filename, silent `arguments`, and set `enabled` to `true` for each driver you want to install.
3. Run a dry run to confirm the metadata:
   ```powershell
   .\stages\01_baseline\02_drivers_bios\Install-Drivers.ps1 -WhatIf
   ```
4. Execute for real (requires Administrator):
   ```powershell
   .\stages\01_baseline\02_drivers_bios\Install-Drivers.ps1
   ```
5. Alternatively, add the driver phase to the manifest runner:
   ```powershell
   .\setup.ps1 -Phase phase1-drivers -MaxStatus experimental
   ```

## 🔄 Post-Installation Tasks

### 1. Run Privacy.sexy Script (Manual Step)

The comprehensive telemetry disabling requires a separate tool:

1. Navigate to `utilities\` or download from [privacy.sexy](https://privacy.sexy/)
2. Run the generated script
3. Follow the tool's instructions

### 2. Configure PowerShell Profile

Your Oh My Posh theme is ready:

```powershell
# View your profile
code $PROFILE

# If not created yet, copy the AbeOS profile
Copy-Item "C:\AbeOS\configs\core\terminal\Microsoft.PowerShell_profile.ps1" $PROFILE -Force

# Or run the helper to sync both PowerShell and WSL profiles
.\stages\01_baseline\03_developer_environment\Sync-ShellProfiles.ps1

# Install Oh My Posh if not already installed
winget install JanDeDobbeleer.OhMyPosh -s winget

# Install Cascadia Code Nerd Font
# Follow instructions at: https://www.nerdfonts.com/
```

### 2b. Configure Bash Profile (WSL)

```bash
cp /mnt/c/AbeOS/configs/core/terminal/bashrc ~/.bashrc
source ~/.bashrc
```

### 3. Set Up BitLocker (If Not Already Done)

```powershell
# Check BitLocker status
Get-BitLockerVolume

# Enable if needed (follow Windows prompts)
Enable-BitLocker -MountPoint "C:" -EncryptionMethod XtsAes256 -UsedSpaceOnly
```

## ❌ Troubleshooting

### "Running scripts is disabled on this system"

**Solution**: Change execution policy
```powershell
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
```

### "Access denied" errors

**Solution**: Ensure you're running PowerShell as Administrator

### Scripts fail with registry errors

**Solution**: Check if you have Windows 11 Pro (not Home)
- Some registry keys require Pro/Enterprise edition

### Power plan not created

**Solution**: Run the system optimization script manually:
```powershell
.\stages\01_baseline\01_core_optimization\System-Optimization.ps1
```

### Need to rollback changes

**Solution**: Use registry backups
1. Go to `C:\AbeOS\configs\core\backup\registry\`
2. Find the backup with the timestamp before installation
3. Right-click each `.reg` file → Merge
4. Reboot

## 🔒 Safety & Recovery

### Registry Backups

All backups are stored in:
```
C:\AbeOS\configs\core\backup\registry\
```

Each backup includes:
- Timestamp in filename
- MANIFEST.txt with details
- Individual .reg files for each modified key

### Restore Process

1. Navigate to backup folder
2. Find the backup you want to restore (check MANIFEST.txt)
3. Double-click the `.reg` file
4. Click "Yes" when prompted
5. Reboot

### Full System Restore

If you created a system restore point:
```powershell
# List available restore points
Get-ComputerRestorePoint

# Restore (use the restore point number)
Restore-Computer -RestorePoint 1
```

## 📊 Logs

All operations are logged to:
```
C:\AbeOS\logs\
```

Log files include:
- Timestamps
- Success/failure status
- Error messages and stack traces
- Operation details

View recent logs:
```powershell
Get-Content "C:\AbeOS\logs\System-Optimization-*.log" -Tail 50
```

## ✅ Next Steps

After Phase 1.1 is complete:

1. ✅ Review TODO.md for upcoming phases
2. ✅ Test system stability (run benchmarks, games, DAW)
3. ✅ Proceed to Phase 1.2 (Hardware & Drivers) when ready
4. ✅ Join the community / open issues on GitHub

## 🤝 Getting Help

If you encounter issues:

1. **Check the logs** in `C:\AbeOS\logs\`
2. **Review common issues** in this guide
3. **Search GitHub issues**
4. **Open a new issue** with:
   - Log files
   - Windows version
   - Hardware specs
   - Steps to reproduce

---

**Congratulations!** You're now running AbeOS Phase 1.1. Enjoy your optimized system! 🚀
