# ------------------------------------------------------------
# dotfiles-bootstrap Windows Installer
# ------------------------------------------------------------

# Step 1. Install PowerShell 7 via Winget
# Step 2. Install Scoop
# Step 3. Install Packages (git, Starship)
# Step 4. Download Nerd Fonts via Scoop, extract, and selective install to Windows Fonts (remove after installation)
# Step 5. Configuration Windows Terminal
# Step 6. Setup PowerShell Profile using starship
# Note: When the progress meets an error, clean up the temp directory and exit with error code


# ------------------------------------------------------------
# Helpers
# ------------------------------------------------------------
function Write-Info($msg)   { Write-Host "[INFO] $msg" -ForegroundColor Blue }
function Write-Ok($msg)     { Write-Host "[OK] $msg" -ForegroundColor Green }
function Write-Warn($msg)   { Write-Host "[WARN] $msg" -ForegroundColor Yellow }
function Write-Err($msg)    { Write-Host "[ERROR] $msg" -ForegroundColor Red }
function Write-Header($msg) { Write-Host "=== $msg ===" -ForegroundColor Magenta }
function Write-Step($msg)   { Write-Host "==> $msg" -ForegroundColor Cyan }

function Test-Command($name) {
    return [bool](Get-Command $name -ErrorAction SilentlyContinue)
}

function Ensure-Directory($path) {
    if (-not (Test-Path $path)) {
        New-Item -ItemType Directory -Path $path -Force | Out-Null
    }
}


# ------------------------------------------------------------

$ErrorActionPreference = "Stop"

Write-Header "Starting dotfiles-bootstrap Windows Installer..."

$RepoRoot   = Split-Path -Parent $PSScriptRoot

# ------------------------------------------------------------
# 1. Install PowerShell 7 via Winget
# ------------------------------------------------------------

Write-Step "Checking PowerShell 7..."

if (Test-Command pwsh) {

    Write-Ok "PowerShell 7 already installed."
}
else {

    Write-Info "Installing PowerShell 7..."

    winget install --id Microsoft.PowerShell -e --accept-package-agreements --accept-source-agreements | Out-Null

    if (-not (Test-Command pwsh)) {
        Write-Err "PowerShell 7 installation failed."
        exit 1
    }

    Write-Ok "PowerShell 7 installed."
}


# ------------------------------------------------------------
# 2. Install Scoop
# ------------------------------------------------------------

Write-Step "Checking Scoop..."

if (Test-Command scoop) {
    Write-Ok "Scoop already installed."
}
else {
    Write-Info "Installing Scoop..."

    Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser -Force

    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

    Invoke-Expression (
        Invoke-WebRequest -UseBasicParsing -Uri "https://get.scoop.sh").Content

    
    if (-not (Test-Command scoop)) {
        Write-Err "Scoop installation failed."
        exit 1
    }

    Write-Ok "Scoop installed."
}

# Add Scoop buckets
Write-Step "Adding Scoop buckets..."
scoop bucket add main  *> $null
scoop bucket add extras *> $null
scoop bucket add nerd-fonts *> $null

Write-Ok "Scoop Buckets ready."


# ------------------------------------------------------------
# 3. Install Packages (git, Starship)   
# ------------------------------------------------------------

Write-Step "Installing packages (git, Starship)..."

$Packages = @(
    "git",
    "starship"
)

foreach ($pkg in $Packages) {
    Write-Info "Installing $pkg ..."
    
    if (-not (scoop list | Select-String "^$pkg ")) {
        scoop install $pkg
        Write-Ok "$pkg installed."
    }
    else {
        Write-Info "$pkg already installed."
    }
}


# ------------------------------------------------------------
# 4. Download Nerd Fonts via Scoop, extract, and selective install to Windows Fonts (remove after installation)
# ------------------------------------------------------------

Write-Step "Installing Nerd Fonts (Iosevka Nerd Term, Iosevka Nerd Mono, Sarasa Mono K)"

$FontPackages = @(
    "Iosevka-NF",
    "IosevkaTerm-NF-Mono",
    "SarasaGothic-K"
)

$Pattern = '^(IosevkaTermNerdFont|IosevkaNerdFontMono|SarasaMonoK)-(Regular|Italic|Bold|BoldItalic)$'

$TempRoot = Join-Path $env:TEMP "font-install-temp"
$CacheDir = Join-Path $env:USERPROFILE "scoop\cache"

Ensure-Directory $TempRoot

try {
    # Download font packages vis scoop to cache directory
    foreach ($pkg in $FontPackages) {
        Write-Info "Downloading $pkg via Scoop..."
        scoop download $pkg
    }

    # Find archives in scoop cache
    $Archives = Get-ChildItem $CacheDir -File | Where-Object {
        $_.Name -match 'Iosevka.*\.zip|Sarasa.*\.7z'
    }

    $Shell = New-Object -ComObject Shell.Application
    $FontFolder = $Shell.Namespace(0x14)

# Ensure 7z if needed
$Has7z = @($Archives | Where-Object { $_.Extension -eq ".7z" })

if ($Has7z.Count -gt 0) {

    if (-not (Test-Command 7z)) {
        Write-Info "Installing 7zip..."
        scoop install 7zip
    }

    $cmd = Get-Command 7z -ErrorAction SilentlyContinue

    if (-not $cmd) {
        throw "7z installation failed or not found in PATH."
    }

    $SevenZipExe = $cmd.Source
}

    foreach ($a in $Archives) {
        $ExtractDir = Join-Path $TempRoot $a.BaseName
        Ensure-Directory $ExtractDir

        Write-Info "Extracting $($a.Name) to $ExtractDir..."

	if ($a.Extension -eq ".zip") {

		Expand-Archive `
			-Path $a.FullName `
			-DestinationPath $ExtractDir `
			-Force
	}

	elseif ($a.Extension -eq ".7z") {
		
        	& $SevenZipExe x $a.FullName "-o$ExtractDir" -y | Out-Null
	}
	else {
		Write-Warn "Unknown archive format: $($a.Name)"
	}

        # Install selected fonts only
        $FontFiles = Get-ChildItem $ExtractDir -Recurse -Filter *.ttf

        foreach ($f in $FontFiles) {

            if ($f.BaseName -match $Pattern) {

                $targetPath = Join-Path "C:\Windows\Fonts" $f.Name

                if (-not (Test-Path $targetPath)) {
                    Write-Info "Installing font: $($f.Name)..."
                    $FontFolder.CopyHere($f.FullName, 0x10)
                }
                else {
                    Write-Info "Skipping already installed font: $($f.Name)"
                }
            }
        }
    }

    # Remove downloaded scoop font packages from cache
    foreach ($pkg in $FontPackages) {
        Write-Info "Cleaning up Scoop cache for $pkg..."
        scoop cache rm $pkg
    }

    Write-Ok "Nerd Fonts installed."
}
finally {
    # Clean up temp directory
    if (Test-Path $TempRoot) {
        Write-Info "Cleaning up temporary files..."
        Remove-Item $TempRoot -Recurse -Force -ErrorAction SilentlyContinue
    }
}


# ------------------------------------------------------------
# 5. Configuration Windows Terminal
# ------------------------------------------------------------

Write-Step "Configuring Windows Terminal..."

$wtSource  = Join-Path $RepoRoot "config\windows-terminal\settings.json"

$wtDest = Join-Path `
$env:LOCALAPPDATA `
"Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState\settings.json"

if (Test-Path (Split-Path $wtDest)) {
    Copy-Item $wtSource $wtDest -Force
    Write-Ok "Windows Terminal configured."
}
else {
    Write-Warn "Windows Terminal not found. Skipping config."
}

# ------------------------------------------------------------
# 6. Setup PowerShell Profile using starship
# ------------------------------------------------------------

Write-Step "Setting up PowerShell profile with Starship..."

$doc = Join-Path $HOME "Documents"

$ps5Profile = Join-Path $doc "WindowsPowerShell\Microsoft.PowerShell_profile.ps1"
$ps7Profile = Join-Path $doc "PowerShell\Microsoft.PowerShell_profile.ps1"

$ps5Dir = Split-Path $ps5Profile -Parent
$ps7Dir = Split-Path $ps7Profile -Parent

# Starship config
$starshipSrc = Join-Path $RepoRoot "config\starship\starship.toml"
$starshipDir = Join-Path $HOME ".config\starship"
$starshipDest = Join-Path $starshipDir "starship.toml"

# profile lines
$envLine  = '$env:STARSHIP_CONFIG = "$HOME\.config\starship\starship.toml"'
$initLine = 'Invoke-Expression (& starship init powershell)'

Ensure-Directory $ps5Dir
Ensure-Directory $ps7Dir
Ensure-Directory $starshipDir

# copy config
if (Test-Path $starshipSrc) {
    Copy-Item $starshipSrc $starshipDest -Force
}

foreach ($profileFile in @($ps5Profile, $ps7Profile)) {

    if (-not (Test-Path $profileFile)) {
        New-Item -ItemType File -Path $profileFile -Force | Out-Null
    }

    $exists = Select-String `
        -Path $profileFile `
        -SimpleMatch `
        -Pattern $initLine `
        -Quiet `
        -ErrorAction SilentlyContinue

    if (-not $exists) {
        Add-Content $profileFile ""
        Add-Content $profileFile "# dotfiles-bootstrap (starship)"
        Add-Content $profileFile $envLine
        Add-Content $profileFile $initLine
    }
}

Write-Ok "PowerShell profiles configured with Starship."

# ------------------------------------------

Write-Header "Complete windows configuration. You may need to restart Windows Terminal or PowerShell to see the changes."