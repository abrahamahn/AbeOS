#Requires -RunAsAdministrator
<#
.SYNOPSIS
    Removes bloated packages that are not needed for AbeOS developer environment.
.DESCRIPTION
    Uninstalls packages that were installed but are not part of the core AbeOS setup.
    This includes redundant tools, duplicate package managers, and unused frameworks.

    Based on DEBUG.md cleanup requirements for Zephyrus G14.
.EXAMPLE
    .\Remove-BloatPackages.ps1
.EXAMPLE
    .\Remove-BloatPackages.ps1 -WhatIf
.NOTES
    File: Remove-BloatPackages.ps1
    Phase: 1.3 - Developer Environment Cleanup
    System: Windows 11 (Zephyrus G14)
#>

[CmdletBinding(SupportsShouldProcess)]
param(
    [switch]$WhatIf
)

$ErrorActionPreference = "Continue"

# Import AbeOS core module for logging
$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot "..\..\..")).ProviderPath
Import-Module (Join-Path $repoRoot "modules\lib\AbeOS.Core.psm1") -Force

Write-AbeLog "Starting bloat package removal..." -Level Info

# List of packages to remove (from DEBUG.md)
$packagesToRemove = @(
    "notepadplusplus.notepadplusplus",  # notepad++
    "Playnite.Playnite",                # playnite
    "JetBrains.Toolbox",                # jetbrains toolbox
    "LLVM.LLVM",                        # llvm
    "Ninja-build.Ninja",                # ninja
    "Kitware.CMake",                    # cmake (if not needed)
    "Microsoft.VisualStudio.2022.BuildTools",  # visual studio build tools
    "Microsoft.VisualStudio.Installer", # microsoft visual studio installer
    "7zip.7zip",                        # 7-zip
    "Microsoft.PowerToys",              # powertoys
    "Postman.Postman",                  # postman
    "EclipseAdoptium.Temurin.*",        # eclipse temurin
    "express-generator",                # npm: express generator
    "create-vite",                      # npm: create-vite
    "create-next-app",                  # npm: create-next-app
    "vcpkg",                            # vcpkg
    "Conan.Conan",                      # conan
    "Gradle.Gradle",                    # gradle
    "Apache.Maven",                     # maven
    "Oven-sh.Bun",                      # bun
    "Vercel.Vercel",                    # vercel (turbo)
    "zoxide",                           # zoxide (duplicate with AbeOS config)
    "fzf",                              # fzf (duplicate)
    "BurntSushi.ripgrep.MSVC",          # ripgrep (duplicate)
    "Starship.Starship",                # starship (using Oh My Posh instead)
    "tmux"                              # tmux (not needed on Windows)
)

# NPM global packages to remove
$npmPackagesToRemove = @(
    "express-generator",
    "create-vite",
    "create-next-app"
)

# Python packages to remove
$pythonPackagesToRemove = @(
    "seaborn"  # seaborn (if not needed for data science)
)

Write-AbeLog "Checking for winget packages to remove..." -Level Info

foreach ($package in $packagesToRemove) {
    try {
        # Check if package is installed
        $installed = winget list --id $package 2>$null
        if ($LASTEXITCODE -eq 0 -and $installed) {
            Write-AbeLog "Found: $package" -Level Info

            if ($PSCmdlet.ShouldProcess($package, "Uninstall")) {
                Write-AbeLog "Uninstalling: $package" -Level Warning
                winget uninstall --id $package --silent --force

                if ($LASTEXITCODE -eq 0) {
                    Write-AbeLog "✓ Removed: $package" -Level Success
                } else {
                    Write-AbeLog "Failed to remove: $package" -Level Error
                }
            }
        }
    } catch {
        Write-AbeLog "Error checking $package : $_" -Level Error
    }
}

Write-AbeLog "`nChecking for npm global packages to remove..." -Level Info

# Remove npm global packages
if (Get-Command npm -ErrorAction SilentlyContinue) {
    foreach ($npmPkg in $npmPackagesToRemove) {
        try {
            $installed = npm list -g $npmPkg --depth=0 2>$null
            if ($LASTEXITCODE -eq 0) {
                Write-AbeLog "Found npm package: $npmPkg" -Level Info

                if ($PSCmdlet.ShouldProcess($npmPkg, "npm uninstall -g")) {
                    npm uninstall -g $npmPkg
                    if ($LASTEXITCODE -eq 0) {
                        Write-AbeLog "✓ Removed npm package: $npmPkg" -Level Success
                    }
                }
            }
        } catch {
            Write-AbeLog "Error checking npm package $npmPkg : $_" -Level Error
        }
    }
} else {
    Write-AbeLog "npm not found, skipping npm package removal" -Level Warning
}

Write-AbeLog "`nChecking for Python packages to remove..." -Level Info

# Remove Python packages (pipx)
if (Get-Command pipx -ErrorAction SilentlyContinue) {
    # Remove pipx itself as it's in the bloat list
    Write-AbeLog "Removing pipx and its packages..." -Level Warning
    if ($PSCmdlet.ShouldProcess("pipx", "Uninstall")) {
        python -m pip uninstall pipx -y 2>$null
    }
}

# Remove Python packages via pip
if (Get-Command python -ErrorAction SilentlyContinue) {
    foreach ($pyPkg in $pythonPackagesToRemove) {
        try {
            $installed = python -m pip show $pyPkg 2>$null
            if ($LASTEXITCODE -eq 0) {
                Write-AbeLog "Found Python package: $pyPkg" -Level Info

                if ($PSCmdlet.ShouldProcess($pyPkg, "pip uninstall")) {
                    python -m pip uninstall $pyPkg -y
                    if ($LASTEXITCODE -eq 0) {
                        Write-AbeLog "✓ Removed Python package: $pyPkg" -Level Success
                    }
                }
            }
        } catch {
            Write-AbeLog "Error checking Python package $pyPkg : $_" -Level Error
        }
    }
}

# Clean up Poetry if not needed (it's mentioned as "poetryzoxide" which seems like a typo)
if (Get-Command poetry -ErrorAction SilentlyContinue) {
    Write-AbeLog "`nPoetry is installed. Remove manually if not needed: pip uninstall poetry" -Level Warning
}

Write-AbeLog "`nBloat removal complete!" -Level Success
Write-AbeLog "You may need to restart your terminal for changes to take effect." -Level Info
Write-AbeLog "`nNext steps:" -Level Info
Write-AbeLog "  1. Run .\Install-WSL.ps1 to set up WSL2 properly" -Level Info
Write-AbeLog "  2. Run .\Install-DevTools.ps1 to install core development tools" -Level Info
Write-AbeLog "  3. Run .\Configure-PowerShellProfiles.ps1 to unify shell configuration" -Level Info
