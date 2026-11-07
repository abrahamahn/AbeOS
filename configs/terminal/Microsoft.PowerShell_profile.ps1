# AbeOS PowerShell Profile — works in both PS 5.x and pwsh 7+
$ErrorActionPreference = "Stop"
$isPwsh7 = $PSVersionTable.PSVersion.Major -ge 7

# === OH-MY-POSH FIRST (fixes first-line prompt bug) ===
oh-my-posh init pwsh --config "C:\AbeOS\configs\terminal\abe.omp.json" | Invoke-Expression

# === UTF-8 ===
[Console]::OutputEncoding = [Console]::InputEncoding = $OutputEncoding = [System.Text.UTF8Encoding]::new()

# === PSReadLine ===
Import-Module PSReadLine
if ($isPwsh7) {
    Set-PSReadLineOption -PredictionSource History -PredictionViewStyle Inline
}
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
Set-Alias python python3

# === MATRIX BANNER (once per session) ===
if (-not $env:ABEOS_BANNER) {
    $env:ABEOS_BANNER = "1"
    $e = [char]27
    $g = "${e}[38;2;0;175;255m"
    $d = "${e}[38;2;0;62;92m"
    $m = "${e}[38;2;0;117;171m"
    $c = "${e}[38;2;0;202;255m"
    $r = "${e}[0m"
    $build = [Environment]::OSVersion.Version.Build
    $b = [char]0x2588

    if ($isPwsh7) {
        $psVer = "$($PSVersionTable.PSVersion.Major).$($PSVersionTable.PSVersion.Minor).$($PSVersionTable.PSVersion.Patch)"
    } else {
        $psVer = "$($PSVersionTable.PSVersion.Major).$($PSVersionTable.PSVersion.Minor).$($PSVersionTable.PSVersion.Revision)"
    }
    $shellName = if ($isPwsh7) { "pwsh" } else { "powershell" }
    $ts = Get-Date -Format "yyyy-MM-dd HH:mm:ss"

    # Build WELCOME NEO from # pattern (same as bash)
    $lines = @(
        "#   # ##### #     ####  ##### #   # #####   #   # ##### #####"
        "#   # #     #     #     #   # ## ## #       ##  # #     #   #"
        "# # # ####  #     #     #   # # # # ####    # # # ####  #   #"
        "## ## #     #     #     #   # #   # #       #  ## #     #   #"
        "#   # ##### ##### ####  ##### #   # #####   #   # ##### #####"
    )

    Write-Host ""
    foreach ($line in $lines) {
        $rendered = $line.Replace("#", $b)
        Write-Host "  ${g}${rendered}${r}"
    }
    Write-Host ""
    Write-Host "   ${d}$([string]::new([char]0x2500, 16)) ${m}SYSTEM ONLINE ${d}$([string]::new([char]0x2500, 14))${r}"
    Write-Host ""
    Write-Host "    ${d}$([char]0x25B8) SYS     ${c}Windows Build ${build}${r}"
    Write-Host "    ${d}$([char]0x25B8) SHELL   ${c}${shellName} ${psVer}${r}"
    Write-Host "    ${d}$([char]0x25B8) TIME    ${c}${ts}${r}"
    Write-Host "    ${d}$([char]0x25B8) STATUS  ${g}$([char]0x25CF) ONLINE${r}"
    Write-Host ""
}
