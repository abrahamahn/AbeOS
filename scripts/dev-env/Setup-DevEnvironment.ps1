# =============================================================================
# Setup-DevEnvironment.ps1
# Master Developer Environment Orchestrator (Windows + WSL2)
# =============================================================================
#
# This script orchestrates the complete developer environment setup across
# Windows and WSL2, handling restarts and state management.
#
# Usage:
#   .\Setup-DevEnvironment.ps1 [-SkipWindowsTools] [-SkipWSLConfig] [-Resume]
#
# =============================================================================

[CmdletBinding()]
param(
    [switch]$SkipWindowsTools,
    [switch]$SkipWSLConfig,
    [switch]$Resume,
    [switch]$Force
)

$ErrorActionPreference = "Stop"

# =============================================================================
# Configuration
# =============================================================================

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$ProjectRoot = Split-Path -Parent (Split-Path -Parent $ScriptDir)
$StateFile = Join-Path $env:TEMP "AbeOS-DevEnv-State.json"
$LogFile = Join-Path $env:TEMP "AbeOS-DevEnv-Setup.log"

# Color output functions
function Write-ColorOutput {
    param([string]$Message, [string]$Color = "White")
    Write-Host $Message -ForegroundColor $Color
}

function Write-Info { param([string]$Message) Write-ColorOutput "[INFO] $Message" "Cyan" }
function Write-Success { param([string]$Message) Write-ColorOutput "[SUCCESS] $Message" "Green" }
function Write-Warning { param([string]$Message) Write-ColorOutput "[WARNING] $Message" "Yellow" }
function Write-Error-Custom { param([string]$Message) Write-ColorOutput "[ERROR] $Message" "Red" }
function Write-Section {
    param([string]$Message)
    Write-Host ""
    Write-ColorOutput "========================================" "Magenta"
    Write-ColorOutput $Message "Magenta"
    Write-ColorOutput "========================================" "Magenta"
    Write-Host ""
}

# =============================================================================
# State Management
# =============================================================================

function Get-SetupState {
    if (Test-Path $StateFile) {
        return Get-Content $StateFile -Raw | ConvertFrom-Json
    }
    return @{
        CurrentStep = 0
        Steps = @(
            "windows-tools",
            "wsl-config",
            "wsl-shutdown",
            "wsl-devtools",
            "bash-profile",
            "powershell-profile",
            "complete"
        )
        StartTime = (Get-Date).ToString("o")
        Completed = @()
    }
}

function Save-SetupState {
    param($State)
    $State | ConvertTo-Json -Depth 10 | Set-Content $StateFile -Force
}

function Clear-SetupState {
    if (Test-Path $StateFile) {
        Remove-Item $StateFile -Force
    }
}

function Write-Log {
    param([string]$Message)
    $Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    "$Timestamp - $Message" | Add-Content $LogFile
}

# =============================================================================
# Restart Management
# =============================================================================

function Test-RestartRequired {
    # Check if Docker Desktop was just installed (common restart trigger)
    $DockerInstalled = Get-Command docker -ErrorAction SilentlyContinue
    if ($DockerInstalled) {
        try {
            docker ps 2>&1 | Out-Null
            return $false  # Docker running, no restart needed
        } catch {
            return $true   # Docker installed but not running, restart needed
        }
    }
    return $false
}

function Register-ResumeTask {
    Write-Info "Registering resume task for post-restart continuation..."

    $TaskName = "AbeOS-DevEnv-Resume"
    $TaskExists = Get-ScheduledTask -TaskName $TaskName -ErrorAction SilentlyContinue

    if ($TaskExists) {
        Unregister-ScheduledTask -TaskName $TaskName -Confirm:$false
    }

    $Action = New-ScheduledTaskAction -Execute "powershell.exe" -Argument "-ExecutionPolicy Bypass -File `"$($MyInvocation.MyCommand.Path)`" -Resume"
    $Trigger = New-ScheduledTaskTrigger -AtLogOn -User $env:USERNAME
    $Principal = New-ScheduledTaskPrincipal -UserId $env:USERNAME -LogonType Interactive -RunLevel Highest
    $Settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -StartWhenAvailable

    Register-ScheduledTask -TaskName $TaskName -Action $Action -Trigger $Trigger -Principal $Principal -Settings $Settings | Out-Null

    Write-Success "Resume task registered. Setup will continue automatically after restart."
}

function Unregister-ResumeTask {
    $TaskName = "AbeOS-DevEnv-Resume"
    $TaskExists = Get-ScheduledTask -TaskName $TaskName -ErrorAction SilentlyContinue

    if ($TaskExists) {
        Unregister-ScheduledTask -TaskName $TaskName -Confirm:$false
        Write-Info "Resume task unregistered."
    }
}

# =============================================================================
# Installation Steps
# =============================================================================

function Step-WindowsTools {
    Write-Section "Step 1: Installing Windows Development Tools"

    $Script = Join-Path $ScriptDir "Install-Windows-DevTools.ps1"

    if (-not (Test-Path $Script)) {
        Write-Error-Custom "Script not found: $Script"
        return $false
    }

    Write-Info "Running: Install-Windows-DevTools.ps1"
    Write-Log "Starting Windows tools installation"

    try {
        & $Script -SkipReboot
        Write-Success "Windows development tools installed successfully"
        Write-Log "Windows tools installation completed"
        return $true
    } catch {
        Write-Error-Custom "Windows tools installation failed: $_"
        Write-Log "ERROR: Windows tools installation failed: $_"
        return $false
    }
}

function Step-WSLConfig {
    Write-Section "Step 2: Configuring WSL2"

    # Check if WSL is installed
    $WSLInstalled = Get-Command wsl -ErrorAction SilentlyContinue
    if (-not $WSLInstalled) {
        Write-Warning "WSL not installed. Installing WSL2..."
        wsl --install -d Ubuntu-22.04
        Write-Warning "WSL installation initiated. Please restart your computer and run this script again with -Resume"
        return $false
    }

    # Check if WSL distribution is installed
    $WSLDistros = wsl --list --quiet
    if ($WSLDistros.Count -eq 0) {
        Write-Warning "No WSL distributions installed. Installing Ubuntu 22.04..."
        wsl --install -d Ubuntu-22.04
        Write-Warning "Please complete the Ubuntu setup and run this script again with -Resume"
        return $false
    }

    Write-Info "WSL2 detected. Configuring..."

    $ConfigScript = Join-Path $ScriptDir "Configure-WSL.sh"

    if (-not (Test-Path $ConfigScript)) {
        Write-Error-Custom "Script not found: $ConfigScript"
        return $false
    }

    # Copy script to WSL and execute
    Write-Info "Copying Configure-WSL.sh to WSL..."
    wsl cp $ConfigScript /tmp/Configure-WSL.sh

    Write-Info "Setting execute permissions..."
    wsl chmod +x /tmp/Configure-WSL.sh

    Write-Info "Running WSL configuration script..."
    Write-Log "Starting WSL configuration"

    try {
        wsl bash /tmp/Configure-WSL.sh
        Write-Success "WSL configuration completed"
        Write-Log "WSL configuration completed"
        return $true
    } catch {
        Write-Error-Custom "WSL configuration failed: $_"
        Write-Log "ERROR: WSL configuration failed: $_"
        return $false
    }
}

function Step-WSLShutdown {
    Write-Section "Step 3: Restarting WSL2"

    Write-Warning "Shutting down WSL to apply configuration changes..."
    wsl --shutdown

    Write-Info "Waiting 5 seconds for WSL to fully terminate..."
    Start-Sleep -Seconds 5

    Write-Info "Restarting WSL..."
    wsl echo "WSL restarted successfully" | Out-Null

    Write-Success "WSL configuration applied and restarted"
    return $true
}

function Step-WSLDevTools {
    Write-Section "Step 4: Installing WSL Development Tools"

    $InstallScript = Join-Path $ScriptDir "Install-All-DevTools.sh"

    if (-not (Test-Path $InstallScript)) {
        Write-Error-Custom "Script not found: $InstallScript"
        return $false
    }

    # Copy script to WSL home directory
    Write-Info "Copying Install-All-DevTools.sh to WSL..."
    wsl cp $InstallScript ~/Install-All-DevTools.sh

    Write-Info "Setting execute permissions..."
    wsl chmod +x ~/Install-All-DevTools.sh

    Write-Info "Running comprehensive development tools installation..."
    Write-Info "This may take 15-30 minutes depending on your internet speed."
    Write-Log "Starting WSL development tools installation"

    try {
        # Run in interactive mode so user can confirm
        wsl bash ~/Install-All-DevTools.sh

        Write-Success "WSL development tools installed successfully"
        Write-Log "WSL development tools installation completed"
        return $true
    } catch {
        Write-Error-Custom "WSL development tools installation failed: $_"
        Write-Log "ERROR: WSL development tools installation failed: $_"
        return $false
    }
}

function Step-BashProfile {
    Write-Section "Step 5: Setting Up Bash Profile"

    $ProfileScript = Join-Path $ScriptDir "Setup-Bash-Profile.sh"

    if (-not (Test-Path $ProfileScript)) {
        Write-Warning "Setup-Bash-Profile.sh not found, skipping..."
        return $true
    }

    Write-Info "Copying Setup-Bash-Profile.sh to WSL..."
    wsl cp $ProfileScript ~/Setup-Bash-Profile.sh

    Write-Info "Setting execute permissions..."
    wsl chmod +x ~/Setup-Bash-Profile.sh

    Write-Info "Running bash profile setup..."
    Write-Log "Starting bash profile setup"

    try {
        wsl bash ~/Setup-Bash-Profile.sh
        Write-Success "Bash profile configured successfully"
        Write-Log "Bash profile setup completed"
        return $true
    } catch {
        Write-Error-Custom "Bash profile setup failed: $_"
        Write-Log "ERROR: Bash profile setup failed: $_"
        return $false
    }
}

function Step-PowerShellProfile {
    Write-Section "Step 6: Setting Up PowerShell Profile"

    $ProfileScript = Join-Path $ScriptDir "Setup-PowerShell-Profile.ps1"

    if (-not (Test-Path $ProfileScript)) {
        Write-Warning "Setup-PowerShell-Profile.ps1 not found, skipping..."
        return $true
    }

    Write-Info "Running PowerShell profile setup..."
    Write-Log "Starting PowerShell profile setup"

    try {
        & $ProfileScript
        Write-Success "PowerShell profile configured successfully"
        Write-Log "PowerShell profile setup completed"
        return $true
    } catch {
        Write-Error-Custom "PowerShell profile setup failed: $_"
        Write-Log "ERROR: PowerShell profile setup failed: $_"
        return $false
    }
}

# =============================================================================
# Main Orchestration
# =============================================================================

function Main {
    # Display banner
    Clear-Host
    Write-ColorOutput @"
   _____ _              ____   _____
  / ____| |            / __ \ / ____|
 | (___ | |_ __ _  ___| |  | | (___
  \___ \| __/ _` |/ _ \ |  | |\___ \
  ____) | || (_| |  __/ |__| |____) |
 |_____/ \__\__,_|\___|\____/|_____/

 AbeOS Developer Environment Setup
 Master Orchestrator (Windows + WSL2)
"@ "Cyan"

    Write-Host ""

    # Load or create state
    $State = Get-SetupState

    # Determine starting step
    $StartStep = 0
    if ($Resume) {
        Write-Info "Resuming setup from previous session..."
        $StartStep = $State.CurrentStep
        Unregister-ResumeTask
    } else {
        if ((Test-Path $StateFile) -and -not $Force) {
            Write-Warning "Previous setup detected. Use -Resume to continue or -Force to start fresh."
            $Response = Read-Host "Continue from previous session? (Y/n)"
            if ($Response -eq "" -or $Response -match "^[Yy]") {
                $StartStep = $State.CurrentStep
            } else {
                Clear-SetupState
                $State = Get-SetupState
            }
        }
    }

    Write-Info "Starting developer environment setup..."
    Write-Info "Log file: $LogFile"
    Write-Info "State file: $StateFile"
    Write-Host ""

    # Execute steps
    $Steps = @(
        @{ Name = "windows-tools"; Function = ${function:Step-WindowsTools}; Skip = $SkipWindowsTools },
        @{ Name = "wsl-config"; Function = ${function:Step-WSLConfig}; Skip = $SkipWSLConfig },
        @{ Name = "wsl-shutdown"; Function = ${function:Step-WSLShutdown}; Skip = $SkipWSLConfig },
        @{ Name = "wsl-devtools"; Function = ${function:Step-WSLDevTools}; Skip = $false },
        @{ Name = "bash-profile"; Function = ${function:Step-BashProfile}; Skip = $false },
        @{ Name = "powershell-profile"; Function = ${function:Step-PowerShellProfile}; Skip = $false }
    )

    for ($i = $StartStep; $i -lt $Steps.Count; $i++) {
        $Step = $Steps[$i]

        if ($Step.Skip) {
            Write-Warning "Skipping step: $($Step.Name)"
            continue
        }

        if ($State.Completed -contains $Step.Name) {
            Write-Info "Step already completed: $($Step.Name)"
            continue
        }

        # Execute step
        $Result = & $Step.Function

        if (-not $Result) {
            Write-Error-Custom "Step failed: $($Step.Name)"

            # Check if restart is needed
            if ($Step.Name -eq "windows-tools" -and (Test-RestartRequired)) {
                Write-Warning "System restart required (Docker Desktop installation)"
                $State.CurrentStep = $i + 1
                Save-SetupState $State
                Register-ResumeTask

                Write-Host ""
                Write-Warning "Please restart your computer."
                Write-Warning "Setup will automatically resume after restart."
                Write-Host ""
                Read-Host "Press Enter to restart now (or Ctrl+C to restart manually later)"

                Restart-Computer -Force
                exit 0
            }

            # Save state and exit
            $State.CurrentStep = $i
            Save-SetupState $State
            exit 1
        }

        # Mark step as completed
        $State.Completed += $Step.Name
        $State.CurrentStep = $i + 1
        Save-SetupState $State
    }

    # All steps completed
    Write-Section "Setup Complete!"

    $EndTime = Get-Date
    $StartTime = [DateTime]::Parse($State.StartTime)
    $Duration = $EndTime - $StartTime

    Write-ColorOutput "✓ All development tools installed successfully!" "Green"
    Write-Info "Total time: $($Duration.Hours)h $($Duration.Minutes)m $($Duration.Seconds)s"
    Write-Host ""

    Write-Host "Installed components:" -ForegroundColor Yellow
    Write-Host "  ✓ Windows development tools (Git, VS Code, Docker Desktop, etc.)"
    Write-Host "  ✓ WSL2 configuration (PATH isolation, systemd enabled)"
    Write-Host "  ✓ Node.js/JavaScript ecosystem (NVM, Node 20/24, pnpm, yarn)"
    Write-Host "  ✓ Web development packages (TypeScript, Vite, Next.js, etc.)"
    Write-Host "  ✓ Python/AI/ML toolchain (PyTorch, TensorFlow, Transformers)"
    Write-Host "  ✓ AI CLI tools (Claude, OpenAI, Gemini, Aider)"
    Write-Host "  ✓ Java/JVM stack (SDKMAN!, Java 21/17/11, Gradle, Maven)"
    Write-Host "  ✓ C/C++ development tools (GCC, Clang, debugging tools)"
    Write-Host "  ✓ VS Code extensions (80+ extensions)"
    Write-Host "  ✓ Unified shell profiles (Bash + PowerShell)"
    Write-Host ""

    Write-Host "Next steps:" -ForegroundColor Yellow
    Write-Host "  1. Restart your terminal/VS Code to apply profile changes"
    Write-Host "  2. Verify installation: wsl bash $ScriptDir/Verify-Installation.sh"
    Write-Host "  3. Check logs at: $LogFile"
    Write-Host ""

    # Cleanup
    Clear-SetupState
    Unregister-ResumeTask

    Write-Success "Developer environment setup complete! Happy coding!"
}

# =============================================================================
# Entry Point
# =============================================================================

try {
    Main
} catch {
    Write-Error-Custom "Unexpected error: $_"
    Write-Log "FATAL ERROR: $_"
    exit 1
}
