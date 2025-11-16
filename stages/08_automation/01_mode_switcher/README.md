# Phase 8.1 — Automation & Mode Switching

Focus: consolidate the automation layer (mode toggles, maintenance, backups) so they can be run or scheduled independently.

## Planned Scripts
- `Mode-Switcher.ps1` — orchestrate Creator/Performance profiles (power plans, GHelper, VoiceMeeter, OBS, etc.).
- `Reset-Audio.ps1` — restart audio stack and routing endpoints.
- `Check-StreamingReady.ps1` — validate OBS + VoiceMeeter configuration before going live.
- `Daily-Maintenance.ps1` — winget upgrades, temp cleanup, registry snapshots.
- `Auto-Backup.ps1` — mirror production folders to secondary drives/cloud.

## Scheduling Targets
- Logon → Mode-Switcher (Performance)
- OBS launch → Set Creator mode
- 3 AM → Daily maintenance + health report

As these automations become reliable, register them under a future `phase8-automation` manifest entry for hands-free operations.
