# Phase 1.3 — Developer Environment

Goal: bring the coding + AI tooling layer online after the baseline system is stable.

## Planned Components
- WSL2 (Ubuntu) with required features enabled.
- Node.js (via NVM), npm global packages, and pnpm/yarn if needed.
- Python 3, pipenv, and Poetry.
- Docker Desktop with WSL integration.
- CUDA Toolkit, cuDNN, and PyTorch (GPU acceleration).
- PowerShell/Bash shell customizations (Oh My Posh, autosuggestions).
- VS Code + extensions + Dev Drive provisioning.
- GitHub CLI, SSH keys, and repo bootstrap (Blendtune, ProScan, ABE-Stack, ...).

## Suggested Script Layout
- `Install-WSL.ps1`
- `Install-DevTools.ps1`
- `Configure-Terminal.ps1`
- `Setup-Git.ps1`

When each script is validated on bare metal, register it in `configs/manifest/phases.json` under `phase1-dev`.
