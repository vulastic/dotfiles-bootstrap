$ErrorActionPreference = 'Stop'

$RootDir = Split-Path -Parent $PSScriptRoot
$ConfigDir = Join-Path $RootDir 'config'
$DesignDir = Join-Path $RootDir 'design\tokyo-night'

function Write-Step {
    param([string]$Message)
    Write-Host "[INFO] $Message" -ForegroundColor Cyan
}

function Ensure-Directory {
    param([string]$Path)
    if (-not (Test-Path $Path)) {
        New-Item -ItemType Directory -Path $Path -Force | Out-Null
    }
}

function Backup-File {
    param([string]$Path)
    if (Test-Path $Path) {
        Copy-Item $Path "$Path.bak" -Force
    }
}

function Copy-Config {
    param(
        [string]$Source,
        [string]$Target
    )

    Ensure-Directory -Path (Split-Path -Parent $Target)
    Backup-File -Path $Target
    Copy-Item $Source $Target -Force
}

function Ensure-Scoop {
    if (-not (Get-Command scoop -ErrorAction SilentlyContinue)) {
        Write-Step 'Installing Scoop'
        Set-ExecutionPolicy RemoteSigned -Scope CurrentUser -Force
        Invoke-RestMethod -Uri 'https://get.scoop.sh' | Invoke-Expression
    }
}

function Ensure-ScoopBucket {
    param([string]$Name)

    $bucketLines = scoop bucket list 2>$null
    $pattern = '^(\s*)' + [regex]::Escape($Name) + '(\s+)'
    if (-not ($bucketLines | Select-String -Pattern $pattern)) {
        scoop bucket add $Name | Out-Null
    }
}

function Test-ScoopInstalled {
    param([string]$Name)

    try {
        $prefix = scoop prefix $Name 2>$null
        return [bool]$prefix
    }
    catch {
        return $false
    }
}

function Ensure-WingetPackage {
    param(
        [string]$CommandName,
        [string]$PackageId
    )

    if (Get-Command $CommandName -ErrorAction SilentlyContinue) {
        Write-Step "$CommandName already available"
        return
    }

    if (-not (Get-Command winget -ErrorAction SilentlyContinue)) {
        Write-Step "winget not available, skipping $PackageId"
        return
    }

    Write-Step "Installing $PackageId via winget"
    winget install --id $PackageId --exact --accept-package-agreements --accept-source-agreements --silent
}

function Ensure-ScoopApp {
    param([string]$Name)

    if (-not (Test-ScoopInstalled -Name $Name)) {
        Write-Step "Installing $Name"
        scoop install $Name
    }
    else {
        Write-Step "$Name already installed"
    }
}

function Ensure-PSModule {
    param([string]$Name)
    if (-not (Get-Module -ListAvailable -Name $Name)) {
        Write-Step "Installing PowerShell module $Name"
        Install-Module -Name $Name -Scope CurrentUser -Force -SkipPublisherCheck -AllowClobber
    }
    else {
        Write-Step "$Name module already installed"
    }
}

function Ensure-NuGet {
    if (-not (Get-PackageProvider -Name NuGet -ErrorAction SilentlyContinue)) {
        Install-PackageProvider -Name NuGet -MinimumVersion 2.8.5.201 -Force | Out-Null
    }
}

function Test-FontInstalledWindows {
    param([string]$FontName)

    $hkcuFonts = Get-ItemProperty -Path 'HKCU:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Fonts' -ErrorAction SilentlyContinue
    $fontDir = Join-Path $env:LOCALAPPDATA 'Microsoft\Windows\Fonts'

    $fontPatterns = @(
        $FontName,
        $FontName.Replace(' ', ''),
        $FontName.Replace('Mono K', 'MonoK'),
        $FontName.Replace('Nerd Font Mono', 'NerdFontMono')
    )

    foreach ($pattern in $fontPatterns) {
        $regValues = $hkcuFonts.PSObject.Properties | Where-Object { $_.Name -like "*$pattern*" }
        if ($regValues) {
            return $true
        }

        if (Test-Path $fontDir) {
            $fontFiles = Get-ChildItem -Path $fontDir -Filter "*.ttf" -ErrorAction SilentlyContinue
            if ($fontFiles | Where-Object { $_.BaseName -like "*$pattern*" }) {
                return $true
            }
        }
    }
    return $false
}

function Ensure-FontScoop {
    param(
        [string]$FontName,
        [string]$ScoopPackage
    )

    if (Test-FontInstalledWindows -FontName $FontName) {
        Write-Step "$FontName already installed, skipping"
        return
    }

    if (Test-ScoopInstalled -Name $ScoopPackage) {
        Write-Step "$FontName via Scoop already installed"
    }
    else {
        Write-Step "Installing $FontName via Scoop"
        scoop install $ScoopPackage
        Write-Step "Removing Scoop package (fonts remain in system)"
        scoop uninstall $ScoopPackage
    }
}

function Ensure-LazyVim {
    $configHome = Join-Path $HOME '.config'
    $nvimDir = Join-Path $configHome 'nvim'

    if (Test-Path $nvimDir) {
        Write-Step 'Neovim config already exists, skipping LazyVim bootstrap'
        return
    }

    git clone https://github.com/LazyVim/starter $nvimDir
    Remove-Item -Path (Join-Path $nvimDir '.git') -Recurse -Force
    $examplePlugin = Join-Path $nvimDir 'lua\plugins\example.lua'
    if (Test-Path $examplePlugin) {
        Remove-Item $examplePlugin -Force
    }
}

function Configure-Nvim {
    $configHome = Join-Path $HOME '.config'
    $nvimDir = Join-Path $configHome 'nvim'

    if (-not (Test-Path $nvimDir)) {
        return
    }

    Ensure-Directory -Path (Join-Path $nvimDir 'lua\plugins')
    Copy-Config -Source (Join-Path $ConfigDir 'nvim\lua\plugins\theme.lua') -Target (Join-Path $nvimDir 'lua\plugins\theme.lua')
}

function Configure-PowerShellProfile {
    $profilePath = Join-Path $HOME 'Documents\PowerShell\Microsoft.PowerShell_profile.ps1'
    Copy-Config -Source (Join-Path $ConfigDir 'powershell\Microsoft.PowerShell_profile.ps1') -Target $profilePath
}

function Configure-WindowsTerminalNotice {
    Write-Step 'IosevkaTerm Nerd (priority) and Sarasa Monk K configured in starship.toml'
}

Write-Step 'Bootstrapping Windows shell environment'
Ensure-Scoop
'main','extras','versions','nerd-fonts' | ForEach-Object { Ensure-ScoopBucket -Name $_ }

'git','pwsh','starship','fzf','zoxide','neovim','eza','bat','fd','ripgrep','ghq','gh','7zip' |
    ForEach-Object { Ensure-ScoopApp -Name $_ }

Ensure-ScoopApp -Name 'zellij'

Ensure-NuGet
'Terminal-Icons','PSReadLine','PSFzf' | ForEach-Object { Ensure-PSModule -Name $_ }

Ensure-FontScoop -FontName 'Sarasa Mono K' -ScoopPackage 'SarasaGothic-K'
Ensure-FontScoop -FontName 'Iosevka Nerd Font Mono' -ScoopPackage 'Iosevka-NF-Mono'

Copy-Config -Source (Join-Path $ConfigDir 'starship\starship.toml') -Target (Join-Path $HOME '.config\starship.toml')
    Copy-Config -Source (Join-Path $ConfigDir 'git\gitconfig') -Target (Join-Path $HOME '.gitconfig')
    $zellijBaseDir = Join-Path $env:APPDATA 'Zellij'
    $zellijConfigDir = Join-Path $zellijBaseDir 'config'
    Ensure-Directory -Path $zellijConfigDir
    Copy-Config -Source (Join-Path $ConfigDir 'zellij\config.kdl') -Target (Join-Path $zellijConfigDir 'config.kdl')
    
    Copy-Config -Source (Join-Path $ConfigDir 'shell\aliases.ps1') -Target (Join-Path $HOME '.config\powershell\aliases.ps1')
    Configure-PowerShellProfile
    Ensure-LazyVim
    Configure-Nvim
    Configure-WindowsTerminalNotice

    Write-Step 'Windows bootstrap complete'
