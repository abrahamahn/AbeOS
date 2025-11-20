#Requires -RunAsAdministrator
Set-Location "$PSScriptRoot"

Write-Host "=== ABEOS PHASE 1.3 — FULL DEV ENVIRONMENT ===" -ForegroundColor Magenta

# 1. WSL
wsl --install -d Ubuntu
wsl --set-default-version 2

# 2. Windows tools
winget install --id=Microsoft.VisualStudioCode --id=Git.Git --id=Docker.DockerDesktop --id=Nvidia.CUDA.Toolkit --id=GitHub.cli --id=JanDeDobbeleer.OhMyPosh -e

# 3. WSL tools (runs the big .sh you saw earlier)
wsl bash "/mnt/c/AbeOS/install/phase1.3/30-Install-WSLTools.sh"

# 4. Sync shells
.\40-Sync-ShellProfiles.ps1

Write-Host "`nDONE! Your dev environment is now identical and perfect in both pwsh and WSL bash." -ForegroundColor Green
Write-Host "Open a new terminal → you should see your beautiful prompt immediately." -ForegroundColor Cyan
