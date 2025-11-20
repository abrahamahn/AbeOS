#Requires -RunAsAdministrator
param([switch]$SkipWSL)

$abe = "C:\AbeOS"
$term = "$abe\configs\core\terminal"

# PowerShell
Copy-Item "$term\abeos.pwsh.profile.ps1" $PROFILE -Force

# WSL bash
if (!$SkipWSL) {
  wsl bash -c "mkdir -p ~/ && cp '$term/bashrc.stub' ~/.bashrc"
  wsl bash -c "cp '$term/bashrc.core' ~/.abeos_bashrc" 2>$null
}

Write-Host "Shell profiles synced! Restart pwsh and WSL bash." -ForegroundColor Green
