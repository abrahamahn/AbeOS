# =============================================================================
# Invoke-AbeOSProtectionSystem.ps1
# Automates pre/post update safety tasks for AbeOS customizations
# =============================================================================

#Requires -RunAsAdministrator
[CmdletBinding()]
param(
    [ValidateSet("PrepareForUpdate", "PostUpdateRestore", "HealthCheck")]
    [string]$Action = "PrepareForUpdate",

    [string]$ConfigPath = "",

    [switch]$SkipRestorePoint,
    [switch]$SkipRegistryBackup,
    [switch]$Force
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

# Resolve repo root and default paths
$RepoRoot = (Resolve-Path "$PSScriptRoot\..\..\..").Path
if (-not $ConfigPath) {
    $ConfigPath = Join-Path $RepoRoot "configs\protection\protection-profile.json"
}

$LogDirectory = Join-Path $RepoRoot "logs\protection"
$SessionStateFile = Join-Path $LogDirectory "latest-session.json"
$TranscriptFile = Join-Path $LogDirectory ("protection-{0:yyyyMMdd-HHmmss}.log" -f (Get-Date))

New-Item -ItemType Directory -Path $LogDirectory -Force | Out-Null

$transcriptStarted = $false
try {
    Start-Transcript -Path $TranscriptFile -ErrorAction Stop | Out-Null
    $transcriptStarted = $true
} catch {
    Write-Warning "Unable to start transcript logging: $_"
}

function Write-Section {
    param([string]$Message)
    Write-Host "";
    Write-Host "==============================================" -ForegroundColor Magenta
    Write-Host $Message -ForegroundColor Magenta
    Write-Host "==============================================" -ForegroundColor Magenta
}

function Write-Info { param([string]$Message) Write-Host "[INFO] $Message" -ForegroundColor Cyan }
function Write-Success { param([string]$Message) Write-Host "[✓] $Message" -ForegroundColor Green }
function Write-WarningMessage { param([string]$Message) Write-Host "[WARN] $Message" -ForegroundColor Yellow }
function Write-ErrorMessage { param([string]$Message) Write-Host "[ERROR] $Message" -ForegroundColor Red }

function Import-ProtectionConfig {
    param([string]$Path)

    if (-not (Test-Path $Path)) {
        throw "Protection profile not found at $Path"
    }

    $raw = Get-Content -Path $Path -Raw -ErrorAction Stop
    return $raw | ConvertFrom-Json -Depth 6
}

function Test-WindowsChannel {
    param(
        [int]$UnsupportedBuildFloor = 26000
    )

    $result = [ordered]@{
        IsSupported = $true
        CurrentBuild = $null
        FlightRing = "Retail"
        Messages = @()
    }

    try {
        $nt = Get-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion" -ErrorAction Stop
        $result.CurrentBuild = [int]$nt.CurrentBuild
        if ($result.CurrentBuild -ge $UnsupportedBuildFloor) {
            $result.IsSupported = $false
            $result.Messages += "Build $($result.CurrentBuild) is part of the experimental 26xxx series."
        }
    } catch {
        $result.Messages += "Unable to read CurrentVersion key: $_"
    }

    try {
        $selection = Get-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\WindowsSelfHost\UI\Selection" -ErrorAction Stop
        if ($selection.FlightRing -and ($selection.FlightRing -notin @('Retail', 'ReleasePreview', 'Disabled'))) {
            $result.IsSupported = $false
            $result.FlightRing = $selection.FlightRing
            $result.Messages += "Device enrolled in $($selection.FlightRing) ring."
        }
    } catch {
        $result.Messages += "No Windows Insider enrollment detected."
    }

    return $result
}

function Ensure-CriticalServices {
    param([string[]]$ServiceNames)

    $summary = @()

    foreach ($svcName in ($ServiceNames | Where-Object { $_ -and $_.Trim() -ne "" })) {
        try {
            $svc = Get-Service -Name $svcName -ErrorAction Stop
            $svcSummary = [ordered]@{
                Name = $svcName
                PreviousStatus = $svc.Status
                PreviousStartType = $svc.StartType
                Actions = @()
            }

            if ($svc.StartType -eq "Disabled") {
                Set-Service -Name $svcName -StartupType Manual -ErrorAction Stop
                $svcSummary.Actions += "StartupType → Manual"
            }

            if ($svc.Status -ne "Running") {
                Start-Service -Name $svcName -ErrorAction Stop
                $svcSummary.Actions += "Started"
            }

            $summary += $svcSummary
            Write-Success "Service $svcName is healthy"
        } catch {
            Write-WarningMessage "Unable to validate service $svcName : $_"
        }
    }

    return $summary
}

function Invoke-RegistryBackup {
    param(
        [string]$OutputDirectory,
        [string[]]$Hives
    )

    if (-not $OutputDirectory) {
        Write-WarningMessage "Registry backup skipped: no output directory"
        return
    }

    New-Item -ItemType Directory -Path $OutputDirectory -Force | Out-Null
    $timestamp = Get-Date -Format "yyyyMMdd-HHmmss"

    foreach ($hive in $Hives) {
        $safeHive = $hive.Trim()
        if (-not $safeHive) { continue }
        $target = Join-Path $OutputDirectory "$safeHive-$timestamp.reg"
        try {
            & reg.exe export $safeHive $target /y | Out-Null
            Write-Success "Exported $safeHive → $target"
        } catch {
            Write-WarningMessage "Failed to export $safeHive : $_"
        }
    }
}

function Invoke-SystemRestorePoint {
    param([string]$Description)

    try {
        Checkpoint-Computer -Description $Description -RestorePointType "MODIFY_SETTINGS" -ErrorAction Stop
        Write-Success "Created system restore point: $Description"
    } catch {
        Write-WarningMessage "Restore point creation failed: $_"
    }
}

function Disable-Customizations {
    param($Modules)

    $state = @()

    foreach ($module in $Modules) {
        Write-Section "Disabling $($module.Name)"
        $moduleState = [ordered]@{
            Name = $module.Name
            ProcessesStopped = @()
            ServicesState = @()
            EnableCommands = $module.EnableCommands
        }

        foreach ($procName in ($module.Processes | Where-Object { $_ -and $_.Trim() -ne "" })) {
            $processes = Get-Process -Name $procName -ErrorAction SilentlyContinue
            if ($processes) {
                try {
                    Stop-Process -InputObject $processes -Force -ErrorAction Stop
                    $moduleState.ProcessesStopped += $procName
                    Write-Info "Stopped process $procName"
                } catch {
                    Write-WarningMessage "Unable to stop $procName : $_"
                }
            }
        }

        foreach ($svcName in ($module.Services | Where-Object { $_ -and $_.Trim() -ne "" })) {
            $svc = Get-Service -Name $svcName -ErrorAction SilentlyContinue
            if (-not $svc) {
                Write-WarningMessage "Service $svcName not found"
                continue
            }

            $moduleState.ServicesState += [ordered]@{
                Name = $svcName
                PreviousStatus = $svc.Status
                PreviousStartType = $svc.StartType
            }

            try {
                if ($svc.Status -ne "Stopped") {
                    Stop-Service -Name $svcName -Force -ErrorAction Stop
                }
                if ($svc.StartType -ne "Disabled") {
                    Set-Service -Name $svcName -StartupType Manual -ErrorAction Stop
                }
                Write-Info "Service $svcName paused"
            } catch {
                Write-WarningMessage "Unable to pause service $svcName : $_"
            }
        }

        foreach ($command in ($module.DisableCommands | Where-Object { $_ -and $_.Trim() -ne "" })) {
            try {
                Write-Info "Executing disable command: $command"
                Invoke-Expression $command
            } catch {
                Write-WarningMessage "Disable command failed: $command | $_"
            }
        }

        if ($moduleState.ProcessesStopped.Count -gt 0 -or
            $moduleState.ServicesState.Count -gt 0 -or
            ($module.DisableCommands -and $module.DisableCommands.Count -gt 0)) {
            $state += $moduleState
        }
    }

    return $state
}

function Restore-Customizations {
    param(
        $SessionState,
        $ModulesFromConfig
    )

    if (-not $SessionState -or -not $SessionState.Modules) {
        Write-Info "No previous session state detected."
        return
    }

    foreach ($moduleState in $SessionState.Modules) {
        Write-Section "Restoring $($moduleState.Name)"
        $moduleConfig = $ModulesFromConfig | Where-Object { $_.Name -eq $moduleState.Name }
        $enableCommands = @()
        if ($moduleState.EnableCommands) {
            $enableCommands = $moduleState.EnableCommands
        } elseif ($moduleConfig -and $moduleConfig.EnableCommands) {
            $enableCommands = $moduleConfig.EnableCommands
        }

        foreach ($svcState in ($moduleState.ServicesState | Where-Object { $_ })) {
            try {
                if ($svcState.PreviousStartType) {
                    Set-Service -Name $svcState.Name -StartupType $svcState.PreviousStartType -ErrorAction Stop
                }
                if ($svcState.PreviousStatus -eq "Running") {
                    Start-Service -Name $svcState.Name -ErrorAction Stop
                }
                Write-Info "Restored service $($svcState.Name)"
            } catch {
                Write-WarningMessage "Failed to restore service $($svcState.Name): $_"
            }
        }

        foreach ($command in ($enableCommands | Where-Object { $_ -and $_.Trim() -ne "" })) {
            try {
                Write-Info "Executing enable command: $command"
                Invoke-Expression $command
            } catch {
                Write-WarningMessage "Enable command failed: $command | $_"
            }
        }
    }
}

function Save-SessionState {
    param($State)
    $State | ConvertTo-Json -Depth 6 | Set-Content -Path $SessionStateFile -Encoding UTF8
}

function Load-SessionState {
    if (-not (Test-Path $SessionStateFile)) { return $null }
    try {
        $raw = Get-Content -Path $SessionStateFile -Raw -ErrorAction Stop
        return $raw | ConvertFrom-Json -Depth 6
    } catch {
        Write-WarningMessage "Unable to parse session state: $_"
        return $null
    }
}

function Invoke-PrepareForUpdate {
    param($Config)

    Write-Section "Validating Windows Channel"
    $channel = Test-WindowsChannel
    foreach ($msg in $channel.Messages) { Write-Info $msg }

    if (-not $channel.IsSupported -and -not $Force) {
        Write-ErrorMessage "Unsupported build or Insider ring detected. Rerun with -Force to override."
        return
    }

    Write-Section "Checking Critical Services"
    Ensure-CriticalServices -ServiceNames $Config.CriticalServices | Out-Null

    if ($Config.Modules) {
        Write-Section "Disabling Customizations"
        $moduleState = Disable-Customizations -Modules $Config.Modules
        $session = [ordered]@{
            Timestamp = (Get-Date).ToString("o")
            Modules = $moduleState
        }
        Save-SessionState -State $session
        Write-Success "Customization state saved to $SessionStateFile"
    }

    if (-not $SkipRegistryBackup -and $Config.RegistryBackup) {
        Write-Section "Registry Backup"
        Invoke-RegistryBackup -OutputDirectory $Config.RegistryBackup.OutputDirectory -Hives $Config.RegistryBackup.Hives
    } else {
        Write-WarningMessage "Registry backup skipped by parameter"
    }

    if (-not $SkipRestorePoint) {
        Write-Section "System Restore Point"
        Invoke-SystemRestorePoint -Description "AbeOS Protection - Pre Update"
    } else {
        Write-WarningMessage "Restore point creation skipped by parameter"
    }

    Write-Success "Pre-update safety tasks completed. Safe to run Windows Update."
}

function Invoke-PostUpdateRestore {
    param($Config)

    Write-Section "Loading Previous Session"
    $session = Load-SessionState
    if (-not $session) {
        Write-WarningMessage "No previous session was found. Nothing to restore."
    } else {
        Restore-Customizations -SessionState $session -ModulesFromConfig $Config.Modules
        Write-Success "Customization state restored."
    }

    Write-Section "Service Health"
    Ensure-CriticalServices -ServiceNames $Config.CriticalServices | Out-Null
}

function Invoke-HealthCheck {
    param($Config)

    Write-Section "Channel & Service Health"
    $channel = Test-WindowsChannel
    foreach ($msg in $channel.Messages) { Write-Info $msg }
    if (-not $channel.IsSupported) {
        Write-WarningMessage "Channel validation failed."
    }

    Ensure-CriticalServices -ServiceNames $Config.CriticalServices | Out-Null

    if ($Config.Modules) {
        Write-Section "Customization Overview"
        foreach ($module in $Config.Modules) {
            Write-Info "Tracked module: $($module.Name)"
        }
    }
}

try {
    $config = Import-ProtectionConfig -Path $ConfigPath
    switch ($Action) {
        "PrepareForUpdate" { Invoke-PrepareForUpdate -Config $config }
        "PostUpdateRestore" { Invoke-PostUpdateRestore -Config $config }
        "HealthCheck" { Invoke-HealthCheck -Config $config }
    }
} catch {
    Write-ErrorMessage $_
    throw
} finally {
    if ($transcriptStarted) {
        try { Stop-Transcript | Out-Null } catch {}
    }
}
