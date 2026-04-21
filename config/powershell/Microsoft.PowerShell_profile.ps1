if (Get-Module -ListAvailable -Name PSReadLine) {
    Import-Module PSReadLine
    Set-PSReadLineOption -EditMode Windows

    if ($PSVersionTable.PSEdition -eq 'Core') {
        Set-PSReadLineOption -PredictionSource History
        Set-PSReadLineOption -PredictionViewStyle ListView
    }
}

if (Get-Module -ListAvailable -Name Terminal-Icons) {
    Import-Module Terminal-Icons
}

if ((Get-Command fzf -ErrorAction SilentlyContinue) -and (Get-Module -ListAvailable -Name PSFzf)) {
    Import-Module PSFzf
    Set-PsFzfOption -PSReadLineChordProvider 'Ctrl+t' -PSReadLineChordReverseHistory 'Ctrl+r'
}

$env:EDITOR = 'nvim'
$env:VISUAL = 'nvim'
$env:GHQ_ROOT = if ($env:GHQ_ROOT) { $env:GHQ_ROOT } else { Join-Path $HOME 'src' }

$aliasesPath = Join-Path $HOME '.config\powershell\aliases.ps1'
if (Test-Path $aliasesPath) {
    . $aliasesPath
}

if (Get-Command starship -ErrorAction SilentlyContinue) {
    Invoke-Expression (& starship init powershell)
}

# Auto-start Zellij if not already inside a session
if (-not $env:ZELLIJ) {
    if (Get-Command zellij -ErrorAction SilentlyContinue) {
        zellij
    }
}
