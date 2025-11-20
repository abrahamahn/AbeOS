# AbeOS Protection System

> Automated safety harness that freezes shell mods, captures backups, and verifies Windows health before and after every update.

## Why it exists

Windows shell mods (MyDockFinder, Windhawk, TranslucentTB, etc.) hook Explorer and registry values that are routinely overwritten by Windows Update. Running updates while these tools are active is what usually causes the blank desktop, corrupt AppX database, and broken services that forced reinstalls before. The protection system turns those lessons into a single orchestrator so you can:

- 🚫 Block risky Insider/Canary builds before they land
- ⏹️ Suspend every UI mod and hook with one command
- 🧾 Capture registry exports and transcript logs automatically
- ♻️ Create a Windows restore point every time
- 🔄 Rehydrate the mods + services once the update finishes

Everything lives next to the other automation stages under `stages/08_automation/02_protection`.

## Usage

```powershell
# 1. Freeze the system before Windows Update
cd C:\AbeOS\stages\08_automation\02_protection
./Invoke-AbeOSProtectionSystem.ps1 -Action PrepareForUpdate

# 2. Install Windows patches / reboot

# 3. Restore every tweak
./Invoke-AbeOSProtectionSystem.ps1 -Action PostUpdateRestore

# 4. (Optional) Validate health without touching anything
./Invoke-AbeOSProtectionSystem.ps1 -Action HealthCheck
```

### Parameters

| Parameter | Default | Notes |
|-----------|---------|-------|
| `-ConfigPath` | `C:\AbeOS\configs\protection\protection-profile.json` | Point at a different profile if you have multiple laptops. |
| `-SkipRestorePoint` | `false` | Skip the restore point if you already have a fresh Macrium snapshot. |
| `-SkipRegistryBackup` | `false` | Useful when running from WinPE/limited storage. |
| `-Force` | `false` | Override the Insider-build block (not recommended). |

All actions are logged under `C:\AbeOS\logs\protection` via PowerShell transcripts and JSON session state files.

## What the script does

### PrepareForUpdate

1. **Channel validation** – Reads `HKLM\SOFTWARE\Microsoft\WindowsSelfHost` to make sure you are on Retail/Release Preview and aborts on 26xxx builds unless `-Force` is used.
2. **Critical services** – Verifies and starts: `AppXSvc`, `ClipSVC`, `StateRepository`, `ShellHWDetection`, `TokenBroker`, `UserManager`, `WpnService`, `DcomLaunch`, and `Wuauserv`.
3. **Customization freeze** – Runs the disable commands listed in the protection profile (Windhawk, MyDockFinder, RoundedTB, etc.), stops their processes, and records the state to `latest-session.json` so they can be restored.
4. **Registry backup** – Uses `reg.exe export` for every hive listed in the profile (`HKCU`, `HKLM` by default) and drops the `.reg` exports inside `C:\AbeOS\backups\registry`.
5. **System Restore** – Calls `Checkpoint-Computer` with the description `"AbeOS Protection - Pre Update"` so you can undo the entire patch in Windows Recovery if needed.

### PostUpdateRestore

1. Reads the saved session (`latest-session.json`).
2. Restores each service to its previous start mode/status.
3. Executes every `EnableCommands` entry from the profile so dock/taskbar utilities come back online in the correct order.
4. Revalidates the critical services to ensure the update did not disable anything.

### HealthCheck

Performs steps 1 and 2 (channel + services) and prints the list of tracked modules without touching them.

## Customizing `protection-profile.json`

Located at `configs/protection/protection-profile.json`:

```json
{
  "RegistryBackup": {
    "OutputDirectory": "C:\\AbeOS\\backups\\registry",
    "Hives": ["HKCU", "HKLM"]
  },
  "CriticalServices": ["AppXSvc", "ClipSVC", "StateRepository"],
    "Modules": [
      {
        "Name": "MyDockFinder",
        "Processes": ["MyDockFinder"],
        "DisableCommands": [
          "Stop-Process -Name MyDockFinder -Force -ErrorAction SilentlyContinue"
        ],
        "EnableCommands": [
          "Start-Process \"C:\\Program Files\\MyDockFinder\\MyDockFinder.exe\" -ErrorAction SilentlyContinue"
        ]
      }
    ]
}
```

- **Modules.Processes** – List of executable names that should be stopped automatically.
- **Modules.Services** – Optional Windows service names (e.g., `StartAllBack`) that need to be paused.
- **DisableCommands / EnableCommands** – Raw PowerShell snippets that run after the processes/services are touched. Use them to flip Windhawk modules, toggle Explorer patches, or launch helper apps in the right order.
- **RegistryBackup.Hives** – Any hive that `reg.exe export` understands (`HKCU`, `HKLM`, `HKCR`, etc.).

Keep multiple versions of the JSON (e.g., `protection-profile-streaming.json`) and use `-ConfigPath` when you need a different combo of mods.

## Log files & restoration

- `C:\AbeOS\logs\protection\protection-*.log` – Transcript of every action + errors.
- `C:\AbeOS\logs\protection\latest-session.json` – Snapshot of what was disabled; deleting it prevents the script from trying to re-enable anything.
- `C:\AbeOS\backups\registry` – Raw `.reg` exports for HKCU/HKLM. Double-click to restore, or import from Recovery Environment.

## Operational Checklist

1. Run **PrepareForUpdate**.
2. Confirm transcript reports all mods/services paused.
3. Apply Windows updates / reboot.
4. Run **PostUpdateRestore** to bring the overlay back.
5. Optionally run **HealthCheck** and `Verify-Installation.sh` to validate developer stacks.

Follow that cadence and you avoid corrupting the Windows shell ever again.
