# Windows bootstrap script - Downloads and runs latest version from GitHub
$ErrorActionPreference = 'Stop'

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
        Write-Error "Failed to extract repository"
        exit 1
    }
    
    # Run the Windows installer from the extracted files
    $installerPath = Join-Path $extractedDir.FullName "install\windows.ps1"
    if (Test-Path $installerPath) {
        & $installerPath
    } else {
        Write-Error "Installer not found at $installerPath"
        exit 1
    }
} finally {
    # Clean up temporary directory
    Write-Host "Cleaning up temporary files..." -ForegroundColor Cyan
    Remove-Item -Path $tempDir -Recurse -Force -ErrorAction SilentlyContinue
}

Write-Host "Bootstrap complete!" -ForegroundColor Green