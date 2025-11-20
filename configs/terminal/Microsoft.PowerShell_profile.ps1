# AbeOS PowerShell 7+ Profile — single source of truth
$ErrorActionPreference = "Stop"

# === OH-MY-POSH FIRST (fixes first-line prompt bug) ===
oh-my-posh init pwsh --config "C:\AbeOS\configs\terminal\abe.omp.json" | Invoke-Expression

# === UTF-8 ===
[Console]::OutputEncoding = [Console]::InputEncoding = $OutputEncoding = [System.Text.UTF8Encoding]::new()

# === PSReadLine ===
Import-Module PSReadLine
Set-PSReadLineOption -PredictionSource History -PredictionViewStyle Inline
Set-PSReadLineOption -ContinuationPrompt ""

# === NVM-Windows (if you ever use Node directly in pwsh) ===
if (Test-Path "$env:APPDATA\nvm") {
    $env:NVM_SYMLINK = "C:\nodejs"
    . "$env:APPDATA\nvm\nvm.ps1"
}

# === Aliases & Functions ===
Set-Alias ll ls
function which($cmd) { (Get-Command $cmd).Path }
function proj { Set-Location C:\projects }

# === AI CLIs ===
# gemini-cli, claude, copilot — just install via npm/pip once
