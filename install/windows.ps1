# windows.ps1
# ------------------------------------------------------------
# dotfile-bootstrap Windows Installer
# Safe install:
# - Check first
# - Skip if already installed
# ------------------------------------------------------------

$ErrorActionPreference = "Stop"

$RepoRoot = Split-Path -Parent $PSScriptRoot
$ThemeSrc = Join-Path $RepoRoot "shell\powershell\tokyonight.ps1"

Write-Host ""
Write-Host "dotfile-bootstrap Windows Installer" -ForegroundColor Cyan
Write-Host ""

# ------------------------------------------------------------
# 1. PowerShell 7.x
# ------------------------------------------------------------

if (Get-Command pwsh -ErrorAction SilentlyContinue) {
    Write-Host "PowerShell 7 already installed." -ForegroundColor Green
}
else {
    Write-Host "Installing PowerShell 7..." -ForegroundColor Yellow
    winget install --id Microsoft.PowerShell --source winget `
        --accept-package-agreements `
        --accept-source-agreements
}

# ------------------------------------------------------------
# 2. Scoop
# ------------------------------------------------------------

if (Get-Command scoop -ErrorAction SilentlyContinue) {
    Write-Host "Scoop already installed." -ForegroundColor Green
}
else {
    Write-Host "Installing Scoop..." -ForegroundColor Yellow
    Set-ExecutionPolicy RemoteSigned -Scope CurrentUser -Force
    Invoke-RestMethod get.scoop.sh | Invoke-Expression
}

# ------------------------------------------------------------
# 3. Git
# ------------------------------------------------------------

if (Get-Command git -ErrorAction SilentlyContinue) {
    Write-Host "Git already installed." -ForegroundColor Green
}
else {
    Write-Host "Installing Git..." -ForegroundColor Yellow
    scoop install git
}

# ------------------------------------------------------------
# 4. Fonts
# ------------------------------------------------------------

scoop bucket add nerd-fonts 2>$null

$fonts = Get-ChildItem "$env:WINDIR\Fonts" |
    Select-Object -ExpandProperty Name

# IosevkaTerm Nerd Font
if ($fonts -match "IosevkaTerm") {
    Write-Host "IosevkaTerm Nerd Font already installed." -ForegroundColor Green
}
else {
    Write-Host "Installing IosevkaTerm Nerd Font..." -ForegroundColor Yellow
    scoop install nerd-fonts/IosevkaTerm-NF-Mono
}

# Iosevka Nerd Font
if ($fonts -match "Iosevka" -and $fonts -notmatch "IosevkaTerm") {
    Write-Host "Iosevka Nerd Font already installed." -ForegroundColor Green
}
else {
    Write-Host "Installing Iosevka Nerd Font..." -ForegroundColor Yellow
    scoop install nerd-fonts/Iosevka-NF
}

# Sarasa Mono K
if ($fonts -match "Sarasa") {
    Write-Host "Sarasa Mono K already installed." -ForegroundColor Green
}
else {
    Write-Host "Installing Sarasa Mono K..." -ForegroundColor Yellow
    scoop install nerd-fonts/SarasaGothic-K
}

# ------------------------------------------------------------
# 5. Remove Scoop Font Packages
# ------------------------------------------------------------

scoop uninstall nerd-fonts/IosevkaTerm-NF-Mono 2>$null
scoop uninstall nerd-fonts/Iosevka-NF 2>$null
scoop uninstall nerd-fonts/SarasaGothic-K 2>$null

# ------------------------------------------------------------
# 6. Windows Terminal settings.json
# ------------------------------------------------------------

$settings = Join-Path $env:LOCALAPPDATA `
"Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState\settings.json"

if (Test-Path $settings) {

    $json = Get-Content $settings -Raw | ConvertFrom-Json

    if (-not $json.schemes) {
        $json | Add-Member `
            -MemberType NoteProperty `
            -Name schemes `
            -Value @()
    }

    $exists = $false

    foreach ($s in $json.schemes) {
        if ($s.name -eq "tokyonight") {
            $exists = $true
        }
    }

    if (-not $exists) {

        $json.schemes += [PSCustomObject]@{
            background          = "#1A1B26"
            black               = "#15161E"
            blue                = "#7AA2F7"
            brightBlack         = "#414868"
            brightBlue          = "#7AA2F7"
            brightCyan          = "#7DCFFF"
            brightGreen         = "#9ECE6A"
            brightPurple        = "#BB9AF7"
            brightRed           = "#F7768E"
            brightWhite         = "#C0CAF5"
            brightYellow        = "#E0AF68"
            cursorColor         = "#C0CAF5"
            cyan                = "#7DCFFF"
            foreground          = "#C0CAF5"
            green               = "#9ECE6A"
            name                = "tokyonight"
            purple              = "#BB9AF7"
            red                 = "#F7768E"
            selectionBackground = "#33467C"
            white               = "#A9B1D6"
            yellow              = "#E0AF68"
        }

        Write-Host "Tokyo Night scheme added." -ForegroundColor Green
    }

    if (-not $json.profiles.defaults) {
        $json.profiles | Add-Member `
            -MemberType NoteProperty `
            -Name defaults `
            -Value ([PSCustomObject]@{})
    }

    $json.profiles.defaults.colorScheme = "tokyonight"

    if (-not $json.profiles.defaults.font) {
        $json.profiles.defaults | Add-Member `
            -MemberType NoteProperty `
            -Name font `
            -Value ([PSCustomObject]@{})
    }

    $json.profiles.defaults.font.face =
        "IosevkaTerm Nerd Font, Sarasa Mono K"

    $json | ConvertTo-Json -Depth 10 |
        Set-Content $settings -Encoding UTF8

    Write-Host "Windows Terminal configured." -ForegroundColor Green
}

# ------------------------------------------------------------
# 7. PowerShell Theme
# ------------------------------------------------------------

if (Test-Path $ThemeSrc) {

# Windows PowerShell 5.x

$ps5Dir = Join-Path `
    ([Environment]::GetFolderPath("MyDocuments")) `
    "WindowsPowerShell"

$ps5Profile = Join-Path $ps5Dir "Microsoft.PowerShell_profile.ps1"
$ps5Theme   = Join-Path $ps5Dir "tokyonight.ps1"

if (-not (Test-Path $ps5Dir)) {
    New-Item -ItemType Directory -Path $ps5Dir -Force | Out-Null
}

if (-not (Test-Path $ps5Profile)) {
    New-Item -ItemType File -Path $ps5Profile -Force | Out-Null
}

Copy-Item $ThemeSrc $ps5Theme -Force

$ps5Content = Get-Content $ps5Profile -Raw -ErrorAction SilentlyContinue
$ps5Line = ". `"$ps5Theme`""

if ($ps5Content -notmatch [regex]::Escape($ps5Theme)) {
    Add-Content $ps5Profile ""
    Add-Content $ps5Profile "# dotfile-bootstrap"
    Add-Content $ps5Profile $ps5Line
}

Write-Host "Windows PowerShell configured." -ForegroundColor Green


# PowerShell 7.x

$ps7Dir = Join-Path `
    ([Environment]::GetFolderPath("MyDocuments")) `
    "PowerShell"

$ps7Profile = Join-Path $ps7Dir "Microsoft.PowerShell_profile.ps1"
$ps7Theme   = Join-Path $ps7Dir "tokyonight.ps1"

if (-not (Test-Path $ps7Dir)) {
    New-Item -ItemType Directory -Path $ps7Dir -Force | Out-Null
}

if (-not (Test-Path $ps7Profile)) {
    New-Item -ItemType File -Path $ps7Profile -Force | Out-Null
}

Copy-Item $ThemeSrc $ps7Theme -Force

$ps7Content = Get-Content $ps7Profile -Raw -ErrorAction SilentlyContinue
$ps7Line = ". `"$ps7Theme`""

if ($ps7Content -notmatch [regex]::Escape($ps7Theme)) {
    Add-Content $ps7Profile ""
    Add-Content $ps7Profile "# dotfile-bootstrap"
    Add-Content $ps7Profile $ps7Line
}

Write-Host "PowerShell 7 configured." -ForegroundColor Green

}
else {
    Write-Host "Theme file not found." -ForegroundColor Yellow
}

Write-Host ""
Write-Host "Installation complete." -ForegroundColor Green
Write-Host "Restart PowerShell / Windows Terminal." -ForegroundColor Cyan