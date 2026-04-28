# Dotfiles Bootstrap Installer for Windows
$ErrorActionPreference = 'Stop'

# 1. Downloads the latest version of the dotfiles-bootstrap repository from GitHub.
# 2. Extracts the downloaded ZIP file to a temporary directory.
# 3. Runs the Windows installer script located in the extracted files.
# 4. Cleans up the temporary files after installation is complete.

Write-Host "Downloading latest dotfiles-bootstrap from GitHub..." -ForegroundColor Cyan

# Create temporary directory
$tempDir = Join-Path $env:TEMP "dotfiles-bootstrap-$(Get-Random)"
if (Test-Path $tempDir) { Remove-Item -Path $tempDir -Recurse -Force }
New-Item -ItemType Directory -Path $tempDir | Out-Null

try {
    # Download and extract the repository
    $zipPath = Join-Path $tempDir "dotfiles-bootstrap.zip"
    Invoke-WebRequest -Uri "https://github.com/vulastic/dotfiles-bootstrap/archive/refs/heads/main.zip" -OutFile $zipPath -UseBasicParsing
    
    Expand-Archive -Path $zipPath -DestinationPath $tempDir -Force
    
    # Determine the extracted folder name
    $extractedDir = Get-ChildItem -Path $tempDir -Directory | Where-Object { $_.Name -like "dotfiles-bootstrap-*" } | Select-Object -First 1
    
    if (-not $extractedDir) {
        throw "Failed to extract repository: Could not find the extracted folder."
    }
    
    # Run the Windows installer from the extracted files
    $installerPath = Join-Path $extractedDir.FullName "install\windows.ps1"
    if (Test-Path $installerPath) {
        & $installerPath
    } else {
        throw "Installer not found at $installerPath"
    }
} 
catch {
    # Print error message
    Write-Error $_.Exception.Message
}
finally {
    Write-Host "Cleaning up temporary files..." -ForegroundColor Cyan
    Remove-Item -Path $tempDir -Recurse -Force -ErrorAction SilentlyContinue
}

Write-Host "Bootstrap complete!" -ForegroundColor Green