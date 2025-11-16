# AbeOS shared helper module
# Provides path resolution, logging helpers, and manifest utilities

$script:AbeOSRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)

function Get-AbeOSRoot {
    <#
    .SYNOPSIS
        Returns the resolved AbeOS root directory.
    #>
    param()
    return $script:AbeOSRoot
}

function Get-AbeOSPath {
    <#
    .SYNOPSIS
        Resolves a relative path under the AbeOS root.
    #>
    param(
        [Parameter(Mandatory = $false)]
        [string]$RelativePath
    )

    if ([string]::IsNullOrWhiteSpace($RelativePath)) {
        return Get-AbeOSRoot
    }

    return [System.IO.Path]::GetFullPath((Join-Path (Get-AbeOSRoot) $RelativePath))
}

function Initialize-AbeOSLogging {
    <#
    .SYNOPSIS
        Creates a timestamped log file for the supplied script name.
    #>
    param(
        [Parameter(Mandatory = $true)]
        [string]$ScriptName
    )

    $logDirectory = Get-AbeOSPath "logs"
    if (-not (Test-Path $logDirectory)) {
        New-Item -ItemType Directory -Path $logDirectory -Force | Out-Null
    }

    $logFile = Join-Path $logDirectory "$ScriptName-$((Get-Date).ToString('yyyyMMdd-HHmmss')).log"
    return $logFile
}

function Write-AbeOSLog {
    <#
    .SYNOPSIS
        Writes a log entry to the provided file and mirrors to host output.
    #>
    param(
        [Parameter(Mandatory = $true)]
        [string]$Message,

        [ValidateSet("INFO", "WARNING", "SUCCESS", "ERROR")]
        [string]$Level = "INFO",

        [Parameter(Mandatory = $true)]
        [string]$LogFile
    )

    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logMessage = "[$timestamp] [$Level] $Message"
    Add-Content -Path $LogFile -Value $logMessage

    switch ($Level) {
        "ERROR" { Write-Host $Message -ForegroundColor Red }
        "SUCCESS" { Write-Host $Message -ForegroundColor Green }
        "WARNING" { Write-Host $Message -ForegroundColor Yellow }
        default { Write-Host $Message -ForegroundColor White }
    }
}

function Get-AbeOSManifest {
    <#
    .SYNOPSIS
        Loads the AbeOS phase manifest from disk.
    #>
    param(
        [Parameter(Mandatory = $false)]
        [string]$ManifestPath = $(Get-AbeOSPath "configs/manifest/phases.json")
    )

    if (-not (Test-Path $ManifestPath)) {
        throw "Manifest file not found at $ManifestPath"
    }

    $raw = Get-Content -Path $ManifestPath -Raw -ErrorAction Stop
    return $raw | ConvertFrom-Json
}

function Get-AbeOSStatusRank {
    <#
    .SYNOPSIS
        Returns a numeric representation of the supplied step status for sorting/filtering.
    #>
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$Status
    )

    switch ($Status.ToLowerInvariant()) {
        "stable" { return 1 }
        "experimental" { return 2 }
        "planned" { return 3 }
        default { return 99 }
    }
}

Export-ModuleMember -Function `
    Get-AbeOSRoot, `
    Get-AbeOSPath, `
    Initialize-AbeOSLogging, `
    Write-AbeOSLog, `
    Get-AbeOSManifest, `
    Get-AbeOSStatusRank
