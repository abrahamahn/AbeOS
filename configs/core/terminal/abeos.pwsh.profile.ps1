# === AbeOS Master Profile ===

# UTF-8 (safe for VS Code and Terminal)
[Console]::OutputEncoding = [System.Text.UTF8Encoding]::new()
[Console]::InputEncoding  = [System.Text.UTF8Encoding]::new()
$OutputEncoding           = [System.Text.UTF8Encoding]::new()

# PSReadLine
Import-Module PSReadLine
Set-PSReadLineOption -PredictionSource History
Set-PSReadLineOption -PredictionViewStyle InlineView
Set-PSReadLineOption -ContinuationPrompt ""

# oh-my-posh
$env:OMP_CONFIG = "C:\AbeOS\configs\core\terminal\abe.omp.json"
oh-my-posh init pwsh --config $env:OMP_CONFIG | Invoke-Expression
