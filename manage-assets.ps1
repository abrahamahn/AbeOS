# Asset Installation Manager
# PowerShell utility for managing plugin and asset installations

param(
    [string]$Action = "menu",
    [string]$Category = "",
    [switch]$DryRun = $false
)

$Script:AssetBasePath = ".\assets"
$Script:LogFile = ".\installation-log.txt"

function Write-Log {
    param([string]$Message, [string]$Level = "INFO")
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logEntry = "[$timestamp] [$Level] $Message"
    Write-Host $logEntry
    Add-Content -Path $Script:LogFile -Value $logEntry
}

function Show-Menu {
    Clear-Host
    Write-Host "================================" -ForegroundColor Cyan
    Write-Host "  Asset Installation Manager" -ForegroundColor Cyan
    Write-Host "================================" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "1. List all plugin installers" -ForegroundColor Yellow
    Write-Host "2. List plugin managers only" -ForegroundColor Yellow
    Write-Host "3. List synthesizers" -ForegroundColor Yellow
    Write-Host "4. List effects plugins" -ForegroundColor Yellow
    Write-Host "5. List free plugins" -ForegroundColor Yellow
    Write-Host "6. List utilities" -ForegroundColor Yellow
    Write-Host "7. List fonts" -ForegroundColor Yellow
    Write-Host "8. List cursor themes" -ForegroundColor Yellow
    Write-Host "9. Verify file integrity" -ForegroundColor Yellow
    Write-Host "10. Export installation manifest" -ForegroundColor Yellow
    Write-Host "11. Generate installation order script" -ForegroundColor Yellow
    Write-Host "Q. Quit" -ForegroundColor Red
    Write-Host ""
}

function Get-PluginInstallers {
    param([string]$Filter = "*")
    
    $pluginPath = Join-Path $Script:AssetBasePath "installations\plugins\Windows"
    
    if (-not (Test-Path $pluginPath)) {
        Write-Log "Plugin path not found: $pluginPath" "ERROR"
        return @()
    }
    
    $installers = Get-ChildItem -Path $pluginPath -File -Filter $Filter | 
        Where-Object { $_.Extension -in @('.exe', '.msi', '.dll', '.vst3') } |
        Sort-Object Name
    
    return $installers
}

function Show-PluginList {
    param([string]$Filter = "*", [string]$Title = "All Plugin Installers")
    
    Write-Host "`n$Title" -ForegroundColor Green
    Write-Host ("=" * $Title.Length) -ForegroundColor Green
    
    $installers = Get-PluginInstallers -Filter $Filter
    
    if ($installers.Count -eq 0) {
        Write-Host "No installers found." -ForegroundColor Yellow
        return
    }
    
    $index = 1
    foreach ($installer in $installers) {
        $size = "{0:N2} MB" -f ($installer.Length / 1MB)
        Write-Host ("{0,3}. {1,-60} [{2}]" -f $index, $installer.Name, $size)
        $index++
    }
    
    Write-Host "`nTotal: $($installers.Count) files" -ForegroundColor Cyan
}

function Show-PluginManagers {
    $managers = @(
        "Waves Central",
        "Arturia_Software_Center",
        "iZotope_Product_Portal",
        "reFX_Cloud",
        "Softube Central",
        "MPluginManager",
        "PA-InstallationManager",
        "inMusic Software Center",
        "Kilohearts Installer",
        "UnitedPluginsManager",
        "HOFA-Plugins_Manager",
        "V-Manager",
        "XLN Online Installer",
        "Klevgrand Helper",
        "KORG Software Pass"
    )
    
    Write-Host "`nPlugin Managers (Install These First)" -ForegroundColor Green
    Write-Host "======================================" -ForegroundColor Green
    
    $pluginPath = Join-Path $Script:AssetBasePath "installations\plugins\Windows"
    $found = @()
    
    foreach ($manager in $managers) {
        $files = Get-ChildItem -Path $pluginPath -File -Filter "*$manager*" -ErrorAction SilentlyContinue
        if ($files) {
            foreach ($file in $files) {
                $found += $file
                $size = "{0:N2} MB" -f ($file.Length / 1MB)
                Write-Host ("{0,-60} [{1}]" -f $file.Name, $size) -ForegroundColor Yellow
            }
        }
    }
    
    Write-Host "`nTotal: $($found.Count) plugin managers" -ForegroundColor Cyan
}

function Show-Synthesizers {
    $synthPatterns = @(
        "*Serum*", "*Spire*", "*Diva*", "*Hive*", "*Vital*", 
        "*Avenger*", "*TAL-U-NO*", "*TAL-Noise*", "*SynthMaster*",
        "*Synplant*", "*Obxd*", "*MG-1*", "*Zebra*"
    )
    
    Write-Host "`nSynthesizer Plugins" -ForegroundColor Green
    Write-Host "===================" -ForegroundColor Green
    
    $pluginPath = Join-Path $Script:AssetBasePath "installations\plugins\Windows"
    $found = @()
    
    foreach ($pattern in $synthPatterns) {
        $files = Get-ChildItem -Path $pluginPath -File -Filter $pattern -ErrorAction SilentlyContinue
        $found += $files
    }
    
    $found = $found | Sort-Object Name -Unique
    
    foreach ($file in $found) {
        if ($file.Extension -in @('.exe', '.msi')) {
            $size = "{0:N2} MB" -f ($file.Length / 1MB)
            Write-Host ("{0,-60} [{1}]" -f $file.Name, $size)
        }
    }
    
    Write-Host "`nTotal: $($found.Count) synthesizer installers" -ForegroundColor Cyan
}

function Show-FreePlugins {
    $freePatterns = @(
        "*TDR*", "*Voxengo*", "*Chow*", "*Klanghelm*", "*TAL-*",
        "*Wider*", "*OTT*", "*CamelCrusher*", "*Youlean*"
    )
    
    Write-Host "`nFree Plugins" -ForegroundColor Green
    Write-Host "============" -ForegroundColor Green
    
    $pluginPath = Join-Path $Script:AssetBasePath "installations\plugins\Windows"
    $found = @()
    
    foreach ($pattern in $freePatterns) {
        $files = Get-ChildItem -Path $pluginPath -File -Filter $pattern -ErrorAction SilentlyContinue
        $found += $files
    }
    
    $found = $found | Sort-Object Name -Unique | Where-Object { $_.Extension -in @('.exe', '.msi') }
    
    foreach ($file in $found) {
        $size = "{0:N2} MB" -f ($file.Length / 1MB)
        Write-Host ("{0,-60} [{1}]" -f $file.Name, $size)
    }
    
    Write-Host "`nTotal: $($found.Count) free plugin installers" -ForegroundColor Cyan
}

function Show-Utilities {
    Write-Host "`nSystem Utilities" -ForegroundColor Green
    Write-Host "================" -ForegroundColor Green
    
    $utilPath = Join-Path $Script:AssetBasePath "utilities"
    
    if (Test-Path $utilPath) {
        $utils = Get-ChildItem -Path $utilPath -File | Sort-Object Name
        
        foreach ($util in $utils) {
            $size = "{0:N2} MB" -f ($util.Length / 1MB)
            Write-Host ("{0,-60} [{1}]" -f $util.Name, $size)
        }
        
        Write-Host "`nTotal: $($utils.Count) utilities" -ForegroundColor Cyan
    } else {
        Write-Host "Utilities folder not found." -ForegroundColor Yellow
    }
}

function Show-Fonts {
    Write-Host "`nInstalled Fonts" -ForegroundColor Green
    Write-Host "===============" -ForegroundColor Green
    
    $fontPath = Join-Path $Script:AssetBasePath "fonts\CascadiaCode"
    
    if (Test-Path $fontPath) {
        $fonts = Get-ChildItem -Path $fontPath -Filter "*.ttf" | Sort-Object Name
        
        foreach ($font in $fonts) {
            $size = "{0:N2} KB" -f ($font.Length / 1KB)
            Write-Host ("{0,-60} [{1}]" -f $font.Name, $size)
        }
        
        Write-Host "`nTotal: $($fonts.Count) font files" -ForegroundColor Cyan
    } else {
        Write-Host "Fonts folder not found." -ForegroundColor Yellow
    }
}

function Show-CursorThemes {
    Write-Host "`nCursor Themes" -ForegroundColor Green
    Write-Host "=============" -ForegroundColor Green
    
    $cursorBase = Join-Path $Script:AssetBasePath "cursors\macOS-cursors-for-Windows-main"
    
    if (Test-Path $cursorBase) {
        $themes = Get-ChildItem -Path $cursorBase -Recurse -Filter "Install.inf" | 
            ForEach-Object { $_.DirectoryName -replace [regex]::Escape($cursorBase), "" }
        
        $index = 1
        foreach ($theme in $themes) {
            Write-Host ("{0,2}. {1}" -f $index, $theme.TrimStart('\'))
            $index++
        }
        
        Write-Host "`nTotal: $($themes.Count) cursor themes" -ForegroundColor Cyan
    } else {
        Write-Host "Cursor themes folder not found." -ForegroundColor Yellow
    }
}

function Verify-FileIntegrity {
    Write-Host "`nVerifying File Integrity..." -ForegroundColor Green
    Write-Host "============================" -ForegroundColor Green
    
    $categories = @{
        "Plugins" = "installations\plugins\Windows"
        "Utilities" = "utilities"
        "Fonts" = "fonts"
        "Cursors" = "cursors"
    }
    
    foreach ($category in $categories.Keys) {
        $path = Join-Path $Script:AssetBasePath $categories[$category]
        
        if (Test-Path $path) {
            $fileCount = (Get-ChildItem -Path $path -Recurse -File).Count
            Write-Host ("{0,-15}: {1,5} files" -f $category, $fileCount) -ForegroundColor Cyan
        } else {
            Write-Host ("{0,-15}: NOT FOUND" -f $category) -ForegroundColor Red
        }
    }
}

function Export-Manifest {
    Write-Host "`nExporting Installation Manifest..." -ForegroundColor Green
    
    $manifest = @{
        ExportDate = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        Categories = @{}
    }
    
    # Plugins
    $pluginPath = Join-Path $Script:AssetBasePath "installations\plugins\Windows"
    if (Test-Path $pluginPath) {
        $manifest.Categories.Plugins = @(Get-ChildItem -Path $pluginPath -File | 
            Select-Object Name, Length, Extension, LastWriteTime)
    }
    
    # Utilities
    $utilPath = Join-Path $Script:AssetBasePath "utilities"
    if (Test-Path $utilPath) {
        $manifest.Categories.Utilities = @(Get-ChildItem -Path $utilPath -File | 
            Select-Object Name, Length, Extension, LastWriteTime)
    }
    
    # Fonts
    $fontPath = Join-Path $Script:AssetBasePath "fonts"
    if (Test-Path $fontPath) {
        $manifest.Categories.Fonts = @(Get-ChildItem -Path $fontPath -Recurse -Filter "*.ttf" | 
            Select-Object Name, Length, LastWriteTime)
    }
    
    $outputFile = ".\installation-manifest-$(Get-Date -Format 'yyyyMMdd-HHmmss').json"
    $manifest | ConvertTo-Json -Depth 5 | Out-File $outputFile
    
    Write-Host "Manifest exported to: $outputFile" -ForegroundColor Green
}

# Main execution
if ($Action -eq "menu") {
    do {
        Show-Menu
        $choice = Read-Host "Select an option"
        
        switch ($choice) {
            "1" { Show-PluginList -Title "All Plugin Installers" }
            "2" { Show-PluginManagers }
            "3" { Show-Synthesizers }
            "4" { Show-PluginList -Filter "*" -Title "Effects Plugins" }
            "5" { Show-FreePlugins }
            "6" { Show-Utilities }
            "7" { Show-Fonts }
            "8" { Show-CursorThemes }
            "9" { Verify-FileIntegrity }
            "10" { Export-Manifest }
            "Q" { Write-Host "Exiting..." -ForegroundColor Yellow; break }
            default { Write-Host "Invalid choice. Please try again." -ForegroundColor Red }
        }
        
        if ($choice -ne "Q") {
            Write-Host "`nPress any key to continue..." -ForegroundColor Gray
            $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
        }
    } while ($choice -ne "Q")
}

Write-Host "`nScript complete." -ForegroundColor Green
