# uninstall.ps1
# Removes Scoop, installed tools, PowerShell modules, and profile customizations

Write-Host "=== Starting PowerShell Environment Cleanup ===" -ForegroundColor Yellow
$i = 1

function Uninstall-Tool {
    param (
        [Parameter(Mandatory=$true)]
        [string]$App
    )

    # Remove via Scoop if installed
    if (scoop which $App 2>$null) {
        Write-Host "Removing $App via Scoop..." -ForegroundColor Magenta
        scoop uninstall $App 2>$null
    }
    else {
        Write-Host "$App is not installed via Scoop" -ForegroundColor DarkYellow
    }
}

function Uninstall-PSModule {
    param (
        [Parameter(Mandatory=$true)]
        [string]$Module
    )

    $installed = Get-Module -ListAvailable -Name $Module
    if ($installed) {
        Write-Host "Removing PowerShell module: $Module" -ForegroundColor Magenta
        $installed | ForEach-Object {
            Remove-Item -Path $_.ModuleBase -Recurse -Force
        }
    }
    else {
        Write-Host "$Module module is not installed" -ForegroundColor DarkYellow
    }
}

# 1. Remove PowerShell profile
Write-Host "[$i] Removing PowerShell profile..." -ForegroundColor Magenta
if (Test-Path $PROFILE) {
    Remove-Item $PROFILE -Force
    Write-Host "Profile removed." -ForegroundColor Green
} else {
    Write-Host "Profile does not exist." -ForegroundColor DarkYellow
}
$i++

# 2. Remove PowerShell modules
Write-Host "[$i] Removing PowerShell modules..." -ForegroundColor Magenta
Uninstall-PSModule -Module "PSReadLine"
Uninstall-PSModule -Module "z"
Uninstall-PSModule -Module "PSFzf"
$i++

# 3. Remove Scoop-installed tools
Write-Host "[$i] Removing Scoop tools..." -ForegroundColor Magenta
Uninstall-Tool -App "git"
Uninstall-Tool -App "pwsh"
Uninstall-Tool -App "oh-my-posh"
Uninstall-Tool -App "terminal-icons"
$i++

# 4. Remove Scoop buckets
Write-Host "[$i] Removing Scoop buckets..." -ForegroundColor Magenta
$Buckets = @("main", "extras", "versions", "nerd-fonts")
foreach ($b in $Buckets) {
    if (scoop bucket list | Select-String $b) {
        scoop bucket rm $b 2>$null
    }
}
$i++

# 5. Remove Scoop itself
Write-Host "[$i] Removing Scoop..." -ForegroundColor Magenta
if (Get-Command scoop -ErrorAction SilentlyContinue) {
    scoop uninstall scoop 2>$null
    Remove-Item "$env:USERPROFILE\scoop" -Recurse -Force -ErrorAction SilentlyContinue
    Write-Host "Scoop removed." -ForegroundColor Green
} else {
    Write-Host "Scoop is not installed." -ForegroundColor DarkYellow
}
$i++

Write-Host "=== Cleanup complete! ===" -ForegroundColor Green
