# windows.ps1
# ------------------------------------------------------------
# dotfiles-bootstrap Windows Installer
# Uses:
# - winget
# - GitHub direct font install
# - Windows Terminal config
# - PowerShell profile theme
# ------------------------------------------------------------

$ErrorActionPreference = "Stop"

$RepoRoot = Split-Path -Parent $PSScriptRoot
$ThemeSrc = Join-Path $RepoRoot "shell\powershell\tokyonight.ps1"
$TempDir  = Join-Path $env:TEMP "dotfiles-bootstrap-fonts"

Write-Host ""
Write-Host "dotfiles-bootstrap Windows Installer" -ForegroundColor Cyan
Write-Host ""

# ------------------------------------------------------------
# Helpers
# ------------------------------------------------------------

function Install-FontFile {
    param([string]$FilePath)

    $Shell = New-Object -ComObject Shell.Application
    $Fonts = $Shell.Namespace(0x14)
    $Fonts.CopyHere($FilePath)
}

function Ensure-WingetPackage {
    param(
        [string]$Command,
        [string]$WingetId,
        [string]$Name
    )

    if (Get-Command $Command -ErrorAction SilentlyContinue) {
        Write-Host "$Name already installed." -ForegroundColor Green
    }
    else {
        Write-Host "Installing $Name..." -ForegroundColor Yellow

        winget install --id $WingetId -e `
            --accept-package-agreements `
            --accept-source-agreements
    }
}

function Ensure-Profile {
    param(
        [string]$Dir,
        [string]$ProfilePath,
        [string]$ThemeDest
    )

    New-Item -ItemType Directory -Path $Dir -Force | Out-Null

    if (-not (Test-Path $ProfilePath)) {
        New-Item -ItemType File -Path $ProfilePath -Force | Out-Null
    }

    Copy-Item $ThemeSrc $ThemeDest -Force

    $content = Get-Content $ProfilePath -Raw -ErrorAction SilentlyContinue
    $line = ". `"$ThemeDest`""

    if ($content -notmatch [regex]::Escape($ThemeDest)) {
        Add-Content $ProfilePath ""
        Add-Content $ProfilePath "# dotfiles-bootstrap"
        Add-Content $ProfilePath $line
    }
}

# ------------------------------------------------------------
# 1. PowerShell 7
# ------------------------------------------------------------

Ensure-WingetPackage `
    -Command "pwsh" `
    -WingetId "Microsoft.PowerShell" `
    -Name "PowerShell 7"

# ------------------------------------------------------------
# 2. Git
# ------------------------------------------------------------

Ensure-WingetPackage `
    -Command "git" `
    -WingetId "Git.Git" `
    -Name "Git"

# ------------------------------------------------------------
# 3. Fonts
# ------------------------------------------------------------

if (Test-Path $TempDir) {
    Remove-Item $TempDir -Recurse -Force -ErrorAction SilentlyContinue
}

New-Item -ItemType Directory -Path $TempDir -Force | Out-Null

$fonts = Get-ChildItem "$env:WINDIR\Fonts" |
    Select-Object -ExpandProperty Name

# ------------------------------------------------------------
# IosevkaTerm Nerd Font
# ------------------------------------------------------------

if ($fonts -match "IosevkaTerm") {
    Write-Host "IosevkaTerm Nerd Font already installed." -ForegroundColor Green
}
else {
    Write-Host "Installing IosevkaTerm Nerd Font..." -ForegroundColor Yellow

    $zip = Join-Path $TempDir "iosevka-term.zip"

    Invoke-WebRequest `
        -Uri "https://github.com/ryanoasis/nerd-fonts/releases/latest/download/IosevkaTerm.zip" `
        -OutFile $zip

    Expand-Archive $zip `
        -DestinationPath "$TempDir\iosevka-term" `
        -Force

    Get-ChildItem "$TempDir\iosevka-term\*.ttf" |
        Where-Object {
            $_.Name -match '^IosevkaTermNerdFont-(Regular|Italic|Bold|BoldItalic)\.ttf$'
        } |
        ForEach-Object {
            Install-FontFile $_.FullName
        }
}

# ------------------------------------------------------------
# Iosevka Nerd Font Mono
# ------------------------------------------------------------

if ($fonts -match "Iosevka Nerd Font Mono") {
    Write-Host "Iosevka Nerd Font Mono already installed." -ForegroundColor Green
}
else {
    Write-Host "Installing Iosevka Nerd Font Mono..." -ForegroundColor Yellow

    $zip = Join-Path $TempDir "iosevka.zip"

    Invoke-WebRequest `
        -Uri "https://github.com/ryanoasis/nerd-fonts/releases/latest/download/Iosevka.zip" `
        -OutFile $zip

    Expand-Archive $zip `
        -DestinationPath "$TempDir\iosevka" `
        -Force

    Get-ChildItem "$TempDir\iosevka\*.ttf" |
        Where-Object {
            $_.Name -match '^IosevkaNerdFontMono-(Regular|Italic|Bold|BoldItalic)\.ttf$'
        } |
        ForEach-Object {
            Install-FontFile $_.FullName
        }
}

# ------------------------------------------------------------
# Sarasa Mono K
# ------------------------------------------------------------

if ($fonts -match "Sarasa") {
    Write-Host "Sarasa Mono K already installed." -ForegroundColor Green
}
else {
    Write-Host "Installing Sarasa Mono K..." -ForegroundColor Yellow

    Ensure-WingetPackage `
        -Command "7z" `
        -WingetId "7zip.7zip" `
        -Name "7-Zip"

    $archive = Join-Path $TempDir "sarasa.7z"

    Invoke-WebRequest `
        -Uri "https://github.com/be5invis/Sarasa-Gothic/releases/download/v1.0.37/SarasaMono-TTF-1.0.37.7z" `
        -OutFile $archive

    & 7z x $archive "-o$TempDir\sarasa" -y | Out-Null

    Get-ChildItem "$TempDir\sarasa" -Recurse |
        Where-Object {
            $_.Name -match '^SarasaMonoK-(Regular|Italic|Bold|BoldItalic)\.ttf$'
        } |
        ForEach-Object {
            Install-FontFile $_.FullName
        }
}

Remove-Item $TempDir -Recurse -Force -ErrorAction SilentlyContinue

# ------------------------------------------------------------
# 4. Windows Terminal
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

    foreach ($scheme in $json.schemes) {
        if ($scheme.name -eq "tokyonight") {
            $exists = $true
        }
    }

    if (-not $exists) {

        $json.schemes += [PSCustomObject]@{
            name                = "tokyonight"
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

    if (-not $json.profiles.defaults.colorScheme) {
        $json.profiles.defaults.colorScheme = "tokyonight"
    }

    if (-not $json.profiles.defaults.font) {
        $json.profiles.defaults | Add-Member `
            -MemberType NoteProperty `
            -Name font `
            -Value ([PSCustomObject]@{})
    }

    $json.profiles.defaults.font.face =
        "IosevkaTerm Nerd Font, Sarasa Mono K"

    $json | ConvertTo-Json -Depth 20 |
        Set-Content $settings -Encoding UTF8

    Write-Host "Windows Terminal configured." -ForegroundColor Green
}

# ------------------------------------------------------------
# 5. PowerShell Theme
# ------------------------------------------------------------

if (Test-Path $ThemeSrc) {

    # PowerShell 5.x
    $ps5Dir = Join-Path `
        ([Environment]::GetFolderPath("MyDocuments")) `
        "WindowsPowerShell"

    $ps5Profile = Join-Path `
        $ps5Dir `
        "Microsoft.PowerShell_profile.ps1"

    $ps5Theme = Join-Path `
        $ps5Dir `
        "tokyonight.ps1"

    Ensure-Profile `
        -Dir $ps5Dir `
        -ProfilePath $ps5Profile `
        -ThemeDest $ps5Theme

    # PowerShell 7.x
    $ps7Dir = Join-Path `
        ([Environment]::GetFolderPath("MyDocuments")) `
        "PowerShell"

    $ps7Profile = Join-Path `
        $ps7Dir `
        "Microsoft.PowerShell_profile.ps1"

    $ps7Theme = Join-Path `
        $ps7Dir `
        "tokyonight.ps1"

    Ensure-Profile `
        -Dir $ps7Dir `
        -ProfilePath $ps7Profile `
        -ThemeDest $ps7Theme

    Write-Host "PowerShell theme configured." -ForegroundColor Green
}

Write-Host ""
Write-Host "Installation complete." -ForegroundColor Green
Write-Host "Restart PowerShell / Windows Terminal." -ForegroundColor Cyan