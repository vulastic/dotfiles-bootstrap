# ------------------------------------------------------------
# dotfiles-bootstrap Windows Installer
# ------------------------------------------------------------

$ErrorActionPreference = "Stop"

# ------------------------------------------------------------
# Paths
# ------------------------------------------------------------

$RepoRoot   = Split-Path -Parent $PSScriptRoot
$ConfigRoot = Join-Path $RepoRoot "config"

$ThemeFile = "tokyonight.ps1"
$ThemeSrc  = Join-Path $ConfigRoot "powershell\theme\$ThemeFile"
$WtSource  = Join-Path $ConfigRoot "windows-terminal\settings.json"

$TempDir = Join-Path $env:TEMP "dotfiles-bootstrap"

$GitRoot = Join-Path $env:LOCALAPPDATA "mingit"
$GitCmd  = Join-Path $GitRoot "cmd"

$SevenZipExe = Join-Path $TempDir "7zr.exe"

# ------------------------------------------------------------
# Download URLs
# ------------------------------------------------------------

$mingitApiUrl = "https://api.github.com/repos/git-for-windows/git/releases/latest"
$7zipUrl = "https://github.com/ip7z/7zip/releases/download/26.01/7zr.exe"

$iosevkaTermUrl = "https://github.com/ryanoasis/nerd-fonts/releases/download/v3.4.0/IosevkaTerm.zip"
$iosevkaUrl = "https://github.com/ryanoasis/nerd-fonts/releases/download/v3.4.0/Iosevka.zip"
$sarasaUrl = "https://github.com/be5invis/Sarasa-Gothic/releases/download/v1.0.37/SarasaMono-TTF-Unhinted-1.0.37.7z"

# ------------------------------------------------------------
# Helpers
# ------------------------------------------------------------

function Write-Step {
    param([string]$Text)

    Write-Host ""
    Write-Host $Text -ForegroundColor Yellow
}

function Ensure-Directory {
    param([string]$Path)

    if (-not (Test-Path $Path)) {
        New-Item -ItemType Directory -Path $Path -Force | Out-Null
    }
}

function Download-File {
    param(
        [string]$Url,
        [string]$OutFile
    )

    if (Test-Path $OutFile) {
        Remove-Item $OutFile -Force -ErrorAction SilentlyContinue
    }

    Invoke-WebRequest `
        -Uri $Url `
        -OutFile $OutFile

    Write-Host "Downloaded: $(Split-Path $OutFile -Leaf)" -ForegroundColor Green
}

function Install-FontFile {
    param([string]$FontPath)

    Write-Host "Installing font: $(Split-Path $FontPath -Leaf)"

    $Shell = New-Object -ComObject Shell.Application
    $Fonts = $Shell.Namespace(0x14)
    $Fonts.CopyHere($FontPath)
}

# ------------------------------------------------------------
# Start
# ------------------------------------------------------------

Write-Host ""
Write-Host "dotfiles-bootstrap Windows Installer" -ForegroundColor Cyan

Ensure-Directory $TempDir

try {

# ------------------------------------------------------------
# 1. PowerShell 7
# ------------------------------------------------------------

Write-Step "Checking PowerShell 7..."

$pwshInstalled = winget list --id Microsoft.PowerShell 2>$null

if ($pwshInstalled -match "Microsoft.PowerShell") {

    Write-Host "PowerShell 7 already installed." -ForegroundColor Green
}
else {

    Write-Host "Installing PowerShell 7..."

    winget install `
        --id Microsoft.PowerShell `
        -e `
        --accept-package-agreements `
        --accept-source-agreements | Out-Null
}

# ------------------------------------------------------------
# 2. Git (MinGit)
# ------------------------------------------------------------

Write-Step "Checking Git..."

$gitExists = $false

try {
    git --version | Out-Null
    $gitExists = $true
}
catch {}

if ($gitExists) {

    Write-Host "Git already installed." -ForegroundColor Green
}
else {

    Write-Host "Installing MinGit..."

    $release = Invoke-RestMethod $mingitApiUrl

    $asset = $release.assets |
        Where-Object { $_.name -match "MinGit.*64-bit\.zip" } |
        Select-Object -First 1

    if (-not $asset) {
        throw "MinGit release asset not found."
    }

    $gitZip = Join-Path $TempDir "mingit.zip"

    Download-File `
        -Url $asset.browser_download_url `
        -OutFile $gitZip

    if (Test-Path $GitRoot) {
        Remove-Item $GitRoot -Recurse -Force -ErrorAction SilentlyContinue
    }

    Expand-Archive `
        -Path $gitZip `
        -DestinationPath $GitRoot `
        -Force

    $userPath = [Environment]::GetEnvironmentVariable("Path", "User")

    if ($userPath -notlike "*$GitCmd*") {

        if ([string]::IsNullOrWhiteSpace($userPath)) {
            $newPath = $GitCmd
        }
        else {
            $newPath = "$userPath;$GitCmd"
        }

        [Environment]::SetEnvironmentVariable(
            "Path",
            $newPath,
            "User"
        )
    }

    $env:Path =
        [Environment]::GetEnvironmentVariable("Path","Machine") + ";" +
        [Environment]::GetEnvironmentVariable("Path","User")

    Write-Host "MinGit installed." -ForegroundColor Green
}

# ------------------------------------------------------------
# 3. Fonts
# ------------------------------------------------------------

$fonts = @(
    @{
        Name = "IosevkaTerm Nerd Font"
        Url  = $iosevkaTermUrl
        File = Join-Path $TempDir "iosevka-term.zip"
        Out  = Join-Path $TempDir "iosevka-term"
        Type = "zip"
    },
    @{
        Name = "Iosevka Nerd Font Mono"
        Url  = $iosevkaUrl
        File = Join-Path $TempDir "iosevka.zip"
        Out  = Join-Path $TempDir "iosevka"
        Type = "zip"
    },
    @{
        Name = "Sarasa Mono K"
        Url  = $sarasaUrl
        File = Join-Path $TempDir "sarasa.7z"
        Out  = Join-Path $TempDir "sarasa"
        Type = "7z"
    }
)

Write-Step "Downloading fonts..."

foreach ($f in $fonts) {

    Write-Host "Downloading $($f.Name)..."

    Download-File `
        -Url $f.Url `
        -OutFile $f.File
}

# ------------------------------------------------------------
# 4. Install Fonts
# ------------------------------------------------------------

Write-Step "Installing fonts..."

foreach ($f in $fonts) {

    Ensure-Directory $f.Out

    Write-Host "Extracting $($f.Name)..."

    if ($f.Type -eq "zip") {

        Expand-Archive `
            -Path $f.File `
            -DestinationPath $f.Out `
            -Force
    }
    else {

        if (-not (Test-Path $SevenZipExe)) {

            Write-Step "Downloading portable 7zr.exe..."

            Download-File `
                -Url $7zipUrl `
                -OutFile $SevenZipExe
        }

        & $SevenZipExe x $f.File "-o$($f.Out)" -y | Out-Null
    }

    Get-ChildItem $f.Out -Recurse -Filter *.ttf |
    Where-Object {
        $_.BaseName -match '^(IosevkaTermNerdFont|IosevkaNerdFontMono|SarasaMonoK)-(Regular|Italic|Bold|BoldItalic)$'
    } |
    ForEach-Object {
        Install-FontFile $_.FullName
    }
}

# ------------------------------------------------------------
# 5. Windows Terminal
# ------------------------------------------------------------

Write-Step "Configuring Windows Terminal..."

$wtDest = Join-Path `
$env:LOCALAPPDATA `
"Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState\settings.json"

if (Test-Path $WtSource) {
    Copy-Item $WtSource $wtDest -Force
}

# ------------------------------------------------------------
# 6. PowerShell Profiles
# ------------------------------------------------------------

Write-Step "Configuring PowerShell profiles..."

$doc = Join-Path $HOME "Documents"

$ps5Profile = Join-Path $doc "WindowsPowerShell\Microsoft.PowerShell_profile.ps1"
$ps7Profile = Join-Path $doc "PowerShell\Microsoft.PowerShell_profile.ps1"

$ps5Dir = Split-Path $ps5Profile -Parent
$ps7Dir = Split-Path $ps7Profile -Parent

# theme destination folder
$themeDir  = Join-Path $ps7Dir "theme"
$themeDest = Join-Path $themeDir "tokyonight.ps1"

$line = ". `"$themeDest`""

Ensure-Directory $ps5Dir
Ensure-Directory $ps7Dir
Ensure-Directory $themeDir

Copy-Item $ThemeSrc $themeDest -Force

foreach ($profileFile in @($ps5Profile, $ps7Profile)) {

    if (-not (Test-Path $profileFile)) {
        New-Item -ItemType File -Path $profileFile -Force | Out-Null
    }

    $exists = Select-String `
        -Path $profileFile `
        -SimpleMatch `
        -Pattern $line `
        -Quiet `
        -ErrorAction SilentlyContinue

    if (-not $exists) {
        Add-Content $profileFile ""
        Add-Content $profileFile "# dotfiles-bootstrap"
        Add-Content $profileFile $line
    }
}

Write-Host ""
Write-Host "Setup complete." -ForegroundColor Green
Write-Host "Restart terminal recommended." -ForegroundColor Cyan

}
finally {

    if (Test-Path $TempDir) {

        Write-Step "Cleaning temporary files..."

        Remove-Item `
            $TempDir `
            -Recurse `
            -Force `
            -ErrorAction SilentlyContinue
    }
}