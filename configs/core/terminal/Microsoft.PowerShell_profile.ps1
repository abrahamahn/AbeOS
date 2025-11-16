# === Disable startup banner & default prompt ===
$env:__SuppressBanner = "true"

function Prompt { "" }

### === ABEOS MASTER PWSH PROFILE === ###

# === UTF-8 ===
[Console]::OutputEncoding = [System.Text.UTF8Encoding]::new()
[Console]::InputEncoding  = [System.Text.UTF8Encoding]::new()
$OutputEncoding           = [System.Text.UTF8Encoding]::new()

# === PSReadLine Tweaks ===
Import-Module PSReadLine
Set-PSReadLineOption -PredictionSource History
Set-PSReadLineOption -PredictionViewStyle InlineView
Set-PSReadLineOption -ContinuationPrompt ""
Set-PSReadLineOption -Colors @{
  ListPrediction   = '#7dcfff'
  Emphasis         = '#bb9af7'
  InlinePrediction = '#a9b1d6'
}

# Disable posh-wsl
$env:POSH_DISABLE_WSL = "1"

# === AbeOS Commands ===
function Merge-Claude {
    git fetch origin
    git switch dev
    git merge origin/claude-latest --no-edit 2>$null
    if ($LASTEXITCODE -eq 0) {
        git push
        Write-Host "dev auto-merged claude-latest & pushed!" -ForegroundColor Green
    } else {
        Write-Host "Conflicts! Resolve manually." -ForegroundColor Yellow
        code .
    }
    git pull origin dev
    Write-Host "Local dev is synced!" -ForegroundColor Cyan
}
Set-Alias mcl Merge-Claude

# === OH-MY-POSH ===
$env:OMP_CONFIG = "C:\AbeOS\configs\core\terminal\abe.omp.json"
oh-my-posh init pwsh --config $env:OMP_CONFIG --strict | Invoke-Expression

# === FINAL PROMPT ===
function global:prompt {
    oh-my-posh prompt
}
