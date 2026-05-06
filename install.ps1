# Dotfiles Bootstrap Installer for Windows
$ErrorActionPreference = 'Stop'

Set-ExecutionPolicy RemoteSigned -Scope CurrentUser -Force

# 1. Downloads the latest version of the dotfiles-bootstrap repository from GitHub.
# 2. Extracts the downloaded ZIP file to a temporary directory.
# 3. Runs the Windows installer script located in the extracted files.
# 4. Cleans up the temporary files after installation is complete.

Write-Host "Downloading latest dotfiles-bootstrap from GitHub..." -ForegroundColor Cyan

# Create temporary directory
$tempDir = Join-Path $env:TEMP "dotfiles-bootstrap"
Remove-Item $tempDir -Recurse -Force -ErrorAction SilentlyContinue
New-Item -ItemType Directory -Path $tempDir | Out-Null

try {
    # Download and extract the repository
    $zipPath = Join-Path $tempDir "repo.zip"

    Invoke-WebRequest `
        -Uri "https://github.com/vulastic/dotfiles-bootstrap/archive/refs/heads/main.zip" `
        -OutFile $zipPath
    
    Expand-Archive -Path $zipPath -DestinationPath $tempDir -Force
    
    # Determine the extracted folder name
    $repoRoot = Get-ChildItem $tempDir -Directory | Where-Object {
        $_.Name -like "dotfiles-bootstrap-main"
    } | Select-Object -First 1
    
    if (-not $repoRoot) {
        throw "Repository folder not found after extraction."
    }
    
    # Run the Windows installer from the extracted files
    $installerPath = Join-Path $repoRoot.FullName "install\windows.ps1"
    if (-not (Test-Path $installerPath)) {
        throw "Installer not found: $installerPath"
    }

    Write-Host "Running installer..." -ForegroundColor Green
    & powershell -ExecutionPolicy Bypass -File $installerPath
    
    Write-Host "Bootstrap complete!" -ForegroundColor Green
}
catch {
    # Print error message
    Write-Error $_.Exception.Message
}
finally {
    Write-Host "Cleaning up temporary files..." -ForegroundColor Cyan
    Remove-Item -Path $tempDir -Recurse -Force -ErrorAction SilentlyContinue
}