# AbeOS Post-Install Profiles

`Invoke-AbeOSPostInstall.ps1` is a thin orchestration layer that stitches together the
existing manifest + dev-environment scripts so clean Windows installs can be hardened
with one command.

## Profiles

| Profile  | Steps                                                                                                      |
|----------|------------------------------------------------------------------------------------------------------------|
| Minimal  | Runs `setup.ps1 -Phase phase1-core -MaxStatus stable -SkipReboot`, which now includes the OneDrive lock.   |
| Standard | Minimal + `scripts/dev-environment/Setup-DevEnvironment.ps1 -Force` and the Workspace scaffolding script.  |
| Full     | Standard + `stages/01_baseline/02_drivers_bios/Install-Drivers.ps1` and `scripts/utilities/safeDisable.ps1`.|

> Use `-DryRun` to preview steps and `-SkipDrivers` if OEM installers are missing.

## Usage

```powershell
cd C:\AbeOS\scripts\post-install
.\Invoke-AbeOSPostInstall.ps1 -Profile Standard
```

## Why this script?

- Avoids duplicating logic from `setup.ps1` or dev scripts — it simply chains them.
- Guarantees the OneDrive folder redirection lockdown happens before developer tooling.
- Central place to add/remove post-install profiles without editing the master manifest.
