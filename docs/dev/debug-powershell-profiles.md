🛠️ AbeOS PowerShell Profile Unification Plan
Fixing PATH, fixing Claude CLI visibility, and unifying all profile sources

Author: ChatGPT
Target Executor: Claude Code / Automation Agent
Status: Ready to run
System: Windows 11 + PowerShell 7 + AbeOS terminal configs
Goal: Make claude work universally across all terminals

1. 🎯 Primary Objective

Unify all PowerShell profile files so that:

Windows Terminal

VS Code Terminal

PowerShell 7 (pwsh.exe)

Administrator PowerShell

AbeOS scripts

all load the same shell configuration, stored at:

C:\AbeOS\configs\core\terminal\pwsh.core.profile.ps1

Also ensure that Claude CLI is available globally by restoring missing PATH entry:

C:\Users\abe\.local\bin

2. 🧩 Root Cause Summary

Based on system analysis:

VS Code’s PowerShell host loads this profile:

C:\Users\abe\OneDrive\Documents\PowerShell\Microsoft.VSCode_profile.ps1

but previously this file didn’t exist → no AbeOS profile loaded

Windows Terminal loads:

C:\Users\abe\OneDrive\Documents\PowerShell\profile.ps1

Admin PowerShell loads AllUsers profiles:

C:\Program Files\PowerShell\7\profile.ps1

which did not override PATH → Claude CLI worked

PATH in user environment was missing:

C:\Users\abe\.local\bin

→ system could not see claude.exe

Therefore:
PowerShell profile fragmentation + missing PATH entry caused the issue.

3. 🔧 Action Plan — Steps for Agent

Below are atomic steps, safe to execute sequentially.

Step 1 — Ensure Claude directory exists
$claudePath = "C:\Users\abe\.local\bin\claude.exe"
if (-Not (Test-Path $claudePath)) {
Write-Error "Claude CLI not found. Reinstall needed."
}

Step 2 — Add Claude path to USER PATH if missing
$required = "C:\Users\abe\.local\bin"
$userPath = [Environment]::GetEnvironmentVariable("Path", "User")

if ($userPath -notlike "*$required\*") {
$newPath = $userPath + ";" + $required
[Environment]::SetEnvironmentVariable("Path", $newPath, "User")
}

⚠️ After this step, agent must restart terminal sessions.

Step 3 — Create missing VS Code profile
$vsProfile = "C:\Users\abe\OneDrive\Documents\PowerShell\Microsoft.VSCode_profile.ps1"
if (-Not (Test-Path $vsProfile)) {
New-Item -ItemType File -Path $vsProfile -Force | Out-Null
}

Step 4 — Create missing User profile
$userProfile = "C:\Users\abe\OneDrive\Documents\PowerShell\profile.ps1"
if (-Not (Test-Path $userProfile)) {
New-Item -ItemType File -Path $userProfile -Force | Out-Null
}

Step 5 — Create/Update AllUsers profiles

(These must be created with elevated permissions)

$globalProfile1 = "C:\Program Files\PowerShell\7\profile.ps1"
$globalProfile2 = "C:\Program Files\PowerShell\7\Microsoft.VSCode_profile.ps1"

foreach ($gp in @($globalProfile1, $globalProfile2)) {
if (-Not (Test-Path $gp)) {
New-Item -ItemType File -Path $gp -Force | Out-Null
}
}

Step 6 — Inject unified loader into all profiles

Unified loader content:

. "C:\AbeOS\configs\core\terminal\pwsh.core.profile.ps1"

Agent performs:

$loader = '. "C:\AbeOS\configs\core\terminal\pwsh.core.profile.ps1"'

$profiles = @(
"C:\Users\abe\OneDrive\Documents\PowerShell\Microsoft.VSCode_profile.ps1",
"C:\Users\abe\OneDrive\Documents\PowerShell\profile.ps1",
"C:\Program Files\PowerShell\7\profile.ps1",
"C:\Program Files\PowerShell\7\Microsoft.VSCode_profile.ps1"
)

foreach ($p in $profiles) {
Set-Content -Path $p -Value $loader -Force
}

Step 7 — After everything, reload environment PATH
$env:PATH = [System.Environment]::GetEnvironmentVariable("Path","User") + ";" +
[System.Environment]::GetEnvironmentVariable("Path","Machine")

Step 8 — Validate
Validate PATH contains Claude folder
$env:PATH -split ";" | Select-String "\.local\\bin"

Expected:

C:\Users\abe\.local\bin

Validate Claude CLI
claude --help

4. 📦 Optional: Backup Before Changes

Agent backups modified files:

foreach ($p in $profiles) {
    if (Test-Path $p) {
        Copy-Item $p "$p.bak\_$(Get-Date -Format yyyyMMddHHmmss)"
}
}

5. ✨ Result After Fix

All PowerShell hosts load the same AbeOS profile

No more PATH fragmentation

Claude CLI available everywhere (claude --help)

VS Code, Terminal, and pwsh.exe behave identically

AbeOS environment becomes stable and deterministic

6. 📜 File to Deliver as .md

This entire message is the file.
You can save it as:

AbeOS-PowerShell-Unification-Plan.md

and pass it directly to Claude Code or any automation agent.
