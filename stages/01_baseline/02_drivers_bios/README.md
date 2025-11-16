# Phase 1.2 — Hardware Drivers & BIOS

This stage covers firmware updates and vendor-specific drivers before moving into dev or creator stacks.

## Tasks to Implement
- Install latest ASUS BIOS and verify applied version.
- Deploy NVIDIA, AMD, chipset, audio, and USB drivers (prefer offline installers in `installations/drivers/`).
- Toggle SmartShift / Hybrid GPU mode in BIOS and document the profile JSONs for GHelper.
- Apply GPU undervolt and fan curve via MSI Afterburner, saving performance/quiet profiles.
- Export calibrated fan/power profiles to `configs/apps/ghelper/` for later automation.

## Scripts
- `Install-Drivers.ps1` *(added)* — reads `configs/installers/drivers.json` and runs each enabled `.exe` inside `installations/drivers/` with the supplied silent arguments (supports `-WhatIf`).
- `Update-BIOS.ps1` — orchestrate BIOS installer checksums + runbook. *(todo)*
- `Export-GPUProfiles.ps1` — query Afterburner/GHelper configs and store JSONs in repo. *(todo)*

> Once a script reaches “stable”, add it to `configs/manifest/phases.json` under `phase1-drivers` so `setup.ps1 -Phase phase1-drivers` can execute it.
