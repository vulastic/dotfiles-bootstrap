Set-Alias -Name vim -Value nvim -Option AllScope
Set-Alias -Name vi -Value nvim -Option AllScope

function ll {
    eza --icons=auto --long --git @Args
}

function la {
    eza --icons=auto --long --all --git @Args
}

function which {
    Get-Command @Args
}

if (Get-Command zoxide -ErrorAction SilentlyContinue) {
    Invoke-Expression (& { (zoxide init powershell | Out-String) })
}

$env:GHQ_ROOT = if ($env:GHQ_ROOT) { $env:GHQ_ROOT } else { Join-Path $HOME 'src' }
