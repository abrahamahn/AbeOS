# Phase 2.1 — DAW + Plugins

This folder will eventually contain automation for installing and organizing the full music production stack.

## Scope
- Install FL Studio + Ableton Live.
- Normalize VST2/VST3 paths (`C:\Production\VST2`, `C:\Production\VST3`) and repair registry entries.
- Drive plugin manager installs (Arturia, Waves, Native Instruments, iLok, etc.) and capture license health.
- Organize plugins by category (Instruments, FX, Dynamics, Reverbs, Utilities) and sync `Vst-Registry.psm1`.
- Track license backups under `licenses/STATUS.md`.

## Future Script Ideas
- `Install-DAWs.ps1`
- `Sync-VSTRegistry.ps1`
- `Validate-PluginLicenses.ps1`
- `Prepare-SampleLibraries.ps1`

> Once each automation path is validated, flag the script as `experimental` or `stable` in the manifest so `setup.ps1 -Phase phase2-music` can orchestrate it automatically.
