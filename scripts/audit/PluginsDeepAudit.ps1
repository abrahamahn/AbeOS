<#
    AbeOS-PluginScanner.ps1

    Full-aggressive audio plugin scanner for:
      - VST2 (.dll)
      - VST3 (.vst3)
      - AAX (.aaxplugin)
      - CLAP (.clap)

    Also scans registry for plugin-related paths.

    Output:
      C:\AbeOS\logs\plugin-audit-YYYYMMDD-HHMMSS\
        - VST2_Plugins.csv
        - VST3_Plugins.csv
        - AAX_Plugins.csv
        - CLAP_Plugins.csv
        - DuplicatePlugins.csv
        - RegistryPluginReferences.csv
        - Plugins.db.json
#>

# =========================
# 0. Setup log directory
# =========================

$timestamp  = Get-Date -Format "yyyyMMdd-HHmmss"
$baseLogDir = "C:\AbeOS\logs"
if (-not (Test-Path $baseLogDir)) {
    New-Item -ItemType Directory -Path $baseLogDir -Force | Out-Null
}
$logDir = Join-Path $baseLogDir "plugin-audit-$timestamp"
New-Item -ItemType Directory -Path $logDir -Force | Out-Null

Write-Host "[-] AbeOS Plugin Scanner" -ForegroundColor Cyan
Write-Host "    Log directory: $logDir"
Write-Host ""

# =========================
# 1. Config: roots & filters
# =========================

# Scan roots (full aggressive, but skip core Windows)
$scanRoots = @(
    "C:\Program Files",
    "C:\Program Files (x86)",
    "C:\ProgramData",
    "C:\Users\abe",
    "C:\VSTPlugins",
    "C:\Plugins",
    "C:\Audio",
    "C:\Production"          # in case you're already consolidating
) | Where-Object { Test-Path $_ }

$excludeRoots = @(
    "C:\Windows",
    "C:\$Recycle.Bin",
    "C:\System Volume Information",
    "C:\Recovery"
)

# Vendor / audio-related tokens for heuristic matching
$audioVendors = @(
    "aberrant","ableton","acustica","air","arturia","audio thing","audiothing",
    "babyaudio","black rooster","boz","cableguys","caelum","camel","cherry audio",
    "chowdhury","d16","dada life","devious","discodsp","east west","eventide",
    "fabfilter","fielding","flux","frozenplain","future audio","hofa","ignite",
    "image-line","initial audio","izotope","kilohearts","klanghelm","klevgrand",
    "korg","kv331","lennar digital","melda","minimal audio","mixed in key",
    "native instruments","oculus","oeksound","ohm force","output","oz soft",
    "plugin alliance","plugin boutique","polyverse","presonus","quiet music",
    "reaper","reason","refx","reveal sound","sennheiser","serato","shattered glass",
    "slate","softube","sonarworks","sonible","sonnox","soundtheory","soundtoys",
    "spectrasonics","streaky","tal","tokyo dawn","u-he","ujam","united plugins",
    "valhalla","vengeance","vital","voxengo","wavesfactory","waves ","xfer","xln",
    "zynaptiq","metric halo","baby audio","quiet music","youlean","united plugins"
) | Sort-Object -Unique

# Extensions
$extVst2  = ".dll"
$extVst3  = ".vst3"
$extClap  = ".clap"
$extAax   = ".aaxplugin"

# Max bytes to scan for quick binary sniff
$binaryScanBytes = 65536  # 64KB

# =========================
# 2. Helper functions
# =========================

function Test-IsPathExcluded {
    param([string]$Path)
    $full = [System.IO.Path]::GetFullPath($Path)
    foreach ($ex in $excludeRoots) {
        if ($full.StartsWith($ex, [System.StringComparison]::OrdinalIgnoreCase)) {
            return $true
        }
    }
    return $false
}

function Get-PublisherGuessFromPath {
    param(
        [string]$Path,
        [string[]]$VendorTokens
    )
    $lower = $Path.ToLowerInvariant()
    foreach ($v in $VendorTokens) {
        $token = $v.ToLowerInvariant()
        if ($lower -like "*$token*") {
            return $v
        }
    }
    return $null
}

function Test-IsLikelyAudioDll {
    param(
        [System.IO.FileInfo]$File,
        [string[]]$VendorTokens
    )

    $pathLower = $File.FullName.ToLowerInvariant()
    $nameLower = $File.Name.ToLowerInvariant()

    # Hard filters: skip obviously non-plugin DLLs by path
    if ($pathLower -like "*\microsoft*") { return $false }
    if ($pathLower -like "*\windows*")   { return $false }
    if ($pathLower -like "*\system32*")  { return $false }
    if ($File.Length -lt 65536)          { return $false } # tiny dlls unlikely to be full plugins

    # Quick path-based hints
    if ($pathLower -like "*\vstplugins\*" -or
        $pathLower -like "*\vst2\*" -or
        $pathLower -like "*\plugins\*" -or
        $pathLower -like "*\steinberg\*") {
        return $true
    }

    # Vendor-based hint
    $pubGuess = Get-PublisherGuessFromPath -Path $File.FullName -VendorTokens $VendorTokens
    if ($pubGuess) { return $true }

    # Name-based hint
    if ($nameLower -like "*vst*" -or
        $nameLower -like "*synth*" -or
        $nameLower -like "*reverb*" -or
        $nameLower -like "*compressor*" -or
        $nameLower -like "*eq*" -or
        $nameLower -like "*delay*" -or
        $nameLower -like "*filter*" -or
        $nameLower -like "*distortion*" -or
        $nameLower -like "*chorus*" -or
        $nameLower -like "*flanger*" -or
        $nameLower -like "*phaser*") {
        return $true
    }

    # Optional lightweight binary sniff for "vst"
    try {
        $fs   = [System.IO.File]::Open($File.FullName, [System.IO.FileMode]::Open, [System.IO.FileAccess]::Read, [System.IO.FileShare]::ReadWrite)
        $buf  = New-Object byte[] ($binaryScanBytes)
        $read = $fs.Read($buf, 0, $buf.Length)
        $fs.Close()
        if ($read -gt 0) {
            $text = [System.Text.Encoding]::ASCII.GetString($buf, 0, $read)
            if ($text.ToLowerInvariant().Contains("vstplugin") -or
                $text.ToLowerInvariant().Contains("vst plug-in") -or
                $text.ToLowerInvariant().Contains("vst plugIn".ToLowerInvariant())) {
                return $true
            }
        }
    } catch {
        # ignore scan failure
    }

    return $false
}

function New-PluginRecord {
    param(
        [string]$Format,
        [System.IO.FileInfo]$File,
        [string[]]$VendorTokens
    )

    $pubGuess = Get-PublisherGuessFromPath -Path $File.FullName -VendorTokens $VendorTokens
    $pluginName = [System.IO.Path]::GetFileNameWithoutExtension($File.Name)

    [PSCustomObject]@{
        Format       = $Format
        FileName     = $File.Name
        PluginName   = $pluginName
        Publisher    = $pubGuess
        FullPath     = $File.FullName
        Directory    = $File.DirectoryName
        SizeBytes    = $File.Length
        LastWrite    = $File.LastWriteTime
    }
}

# =========================
# 3. Scan filesystem
# =========================

Write-Host "[1] Scanning filesystem for plugins (this may take a while)..." -ForegroundColor Yellow

$allPlugins = New-Object System.Collections.Generic.List[object]

foreach ($root in $scanRoots) {
    if (-not (Test-Path $root)) { continue }
    if (Test-IsPathExcluded $root) { continue }

    Write-Host "    -> Scanning $root"

    try {
        # VST3 and CLAP files
        Get-ChildItem $root -Recurse -File -Include *.vst3, *.clap -ErrorAction SilentlyContinue | ForEach-Object {
            $ext = $_.Extension.ToLowerInvariant()
            if ($ext -eq $extVst3) {
                $allPlugins.Add( (New-PluginRecord -Format "VST3" -File $_ -VendorTokens $audioVendors) )
            } elseif ($ext -eq $extClap) {
                $allPlugins.Add( (New-PluginRecord -Format "CLAP" -File $_ -VendorTokens $audioVendors) )
            }
        }

        # VST2 candidates (.dll)
        Get-ChildItem $root -Recurse -File -Filter *.dll -ErrorAction SilentlyContinue | ForEach-Object {
            if (Test-IsPathExcluded $_.FullName) { return }
            if (Test-IsLikelyAudioDll -File $_ -VendorTokens $audioVendors) {
                $allPlugins.Add( (New-PluginRecord -Format "VST2" -File $_ -VendorTokens $audioVendors) )
            }
        }

        # AAX bundles (.aaxplugin) are directories
        Get-ChildItem $root -Recurse -Directory -Filter *.aaxplugin -ErrorAction SilentlyContinue | ForEach-Object {
            # For AAX we treat the directory as the "file"
            $fakeFile = New-Object System.IO.FileInfo($_.FullName)
            $allPlugins.Add( (New-PluginRecord -Format "AAX" -File $fakeFile -VendorTokens $audioVendors) )
        }

    } catch {
        Write-Host "      (error scanning $root: $_)" -ForegroundColor DarkRed
    }
}

Write-Host "    -> Found $($allPlugins.Count) plugin-like entries (before de-dupe)."

# =========================
# 4. Deduplicate & export per format
# =========================

$plugins = $allPlugins | Sort-Object Format, FullPath -Unique

$byFormat = $plugins | Group-Object Format

foreach ($group in $byFormat) {
    $fmt = $group.Name
    $csv = Join-Path $logDir ("{0}_Plugins.csv" -f $fmt)
    $group.Group | Sort-Object Publisher, PluginName, FileName |
        Export-Csv -NoTypeInformation -Encoding UTF8 -Path $csv
    Write-Host "    -> $fmt plugins written to $csv"
}

# Duplicates (same format + plugin name)
$dupCsv = Join-Path $logDir "DuplicatePlugins.csv"
$dups = $plugins |
    Group-Object Format, PluginName |
    Where-Object { $_.Count -gt 1 } |
    ForEach-Object {
        $_.Group
    }

if ($dups.Count -gt 0) {
    $dups | Sort-Object Format, PluginName, FullPath |
        Export-Csv -NoTypeInformation -Encoding UTF8 -Path $dupCsv
    Write-Host "    -> Duplicate plugins written to $dupCsv"
} else {
    Write-Host "    -> No duplicates detected (by Format+PluginName)."
}

# =========================
# 5. Registry scan for plugin-related paths
# =========================

Write-Host ""
Write-Host "[2] Scanning registry for plugin-related paths..." -ForegroundColor Yellow

$regRoots = @(
    "HKLM:\SOFTWARE",
    "HKLM:\SOFTWARE\WOW6432Node",
    "HKCU:\SOFTWARE"
)

$registryHits = New-Object System.Collections.Generic.List[object]

# Simple regex for path-likes and plugin terms
$pathRegex = [regex]'[A-Za-z]:\\[^*?"<>|]+'
$pluginTermRegex = [regex]'vst|vst2|vst3|aax|clap|plugin|plug-in|steinberg|waves|native instruments|u-he|melda|spectrasonics|izotope|arturia|korg|fabfilter'

foreach ($root in $regRoots) {
    if (-not (Test-Path $root)) { continue }
    Write-Host "    -> $root"

    try {
        Get-ChildItem $root -Recurse -ErrorAction SilentlyContinue | ForEach-Object {
            $keyPath = $_.PSPath
            try {
                $props = Get-ItemProperty -LiteralPath $keyPath -ErrorAction SilentlyContinue
            } catch {
                return
            }

            foreach ($pName in $props.PSObject.Properties.Name) {
                if ($pName -eq "PSPath" -or $pName -eq "PSParentPath" -or
                    $pName -eq "PSChildName" -or $pName -eq "PSDrive" -or
                    $pName -eq "PSProvider") {
                    continue
                }

                $val = $props.$pName
                if (-not $val) { continue }
                if (-not ($val -is [string])) { continue }

                $valStr = [string]$val
                if (-not ($pluginTermRegex.IsMatch($valStr) -or $pathRegex.IsMatch($valStr))) {
                    continue
                }

                # try to extract file-ish paths inside the value
                $paths = $pathRegex.Matches($valStr) | ForEach-Object { $_.Value } | Select-Object -Unique
                if (-not $paths) {
                    $paths = @("")
                }

                foreach ($p in $paths) {
                    $exists = $false
                    if ($p -and (Test-Path -LiteralPath $p)) { $exists = $true }

                    $registryHits.Add([PSCustomObject]@{
                        RootHive    = $root
                        KeyPath     = $keyPath
                        ValueName   = $pName
                        RawValue    = $valStr
                        ExtractedPath = $p
                        PathExists  = $exists
                    })
                }
            }
        }
    } catch {
        Write-Host "      (error scanning $root: $_)" -ForegroundColor DarkRed
    }
}

$regCsv = Join-Path $logDir "RegistryPluginReferences.csv"
$registryHits |
    Sort-Object PathExists, RootHive, KeyPath, ValueName |
    Export-Csv -NoTypeInformation -Encoding UTF8 -Path $regCsv

Write-Host "    -> Registry plugin references written to $regCsv"

# =========================
# 6. Combined JSON DB
# =========================

Write-Host ""
Write-Host "[3] Building Plugins.db.json..." -ForegroundColor Yellow

$db = [PSCustomObject]@{
    GeneratedAtUtc = (Get-Date).ToUniversalTime().ToString("o")
    MachineName    = $env:COMPUTERNAME
    User           = $env:USERNAME
    ScanRoots      = $scanRoots
    ExcludeRoots   = $excludeRoots
    PluginCount    = $plugins.Count
    Plugins        = $plugins
    RegistryHits   = $registryHits
}

$jsonPath = Join-Path $logDir "Plugins.db.json"
$db | ConvertTo-Json -Depth 6 | Out-File -FilePath $jsonPath -Encoding UTF8

Write-Host "    -> JSON DB written to $jsonPath"

# =========================
# 7. Summary
# =========================

Write-Host ""
Write-Host "==== ABEOS PLUGIN SCAN COMPLETE ====" -ForegroundColor Cyan
Write-Host "Log directory:"
Write-Host "  $logDir" -ForegroundColor Green
Write-Host ""
Write-Host "Next steps suggestion:"
Write-Host "  - Use VST2_Plugins.csv to plan moves into C:\Production\Library\VST2"
Write-Host "  - Keep VST3 in C:\Program Files\Common Files\VST3"
Write-Host "  - Use RegistryPluginReferences.csv to locate DAW/plugin config paths"
Write-Host "  - Use Plugins.db.json for any future AbeOS tooling/UIs"
