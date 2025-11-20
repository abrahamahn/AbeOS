#Requires -RunAsAdministrator
wsl --install -d Ubuntu
wsl --set-default-version 2
Write-Host "WSL2 + Ubuntu installed. Reboot may be required." -ForegroundColor Green
