#Requires -RunAsAdministrator
winget install -e --id Microsoft.VisualStudioCode --override "/SILENT /MERGETASKS=!runcode"
winget install -e --id Git.Git
winget install -e --id Docker.DockerDesktop
winget install -e --id Nvidia.CUDA.Toolkit
winget install -e --id GitHub.cli
# ... add anything else you want globally on Windows
