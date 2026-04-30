# ==========================================
# PowerShell Prompt
# PS5 Fully Compatible / Stable / Fast
# Tokyo Night Theme
# ==========================================

# UTF-8
chcp 65001 > $null

function prompt {

    # ----------------------------
    # Previous command status
    # ----------------------------
    $ok = $?

    # ----------------------------
    # ANSI Colors
    # ----------------------------
    $esc = [char]27

    $blue   = "${esc}[38;2;122;162;247m"
    $cyan   = "${esc}[38;2;125;207;255m"
    $green  = "${esc}[38;2;158;206;106m"
    $red    = "${esc}[38;2;247;118;142m"
    $purple = "${esc}[38;2;157;124;216m"
    $gray   = "${esc}[38;2;86;95;137m"
    $white  = "${esc}[38;2;192;202;245m"
    $orange = "${esc}[38;2;255;158;100m"
    $reset  = "${esc}[0m"

    # ----------------------------
    # Icons (fallback safe)
    # ----------------------------
    $osIcon    = "PS"
    $adminIcon = "!"
    $arrow     = ">"

    try {
        $osIcon    = [char]0xf17a
        $adminIcon = [char]0xf0e7
        $arrow     = [char]0x203A
    } catch {}

    # ----------------------------
    # User / Host
    # ----------------------------
    $user  = $env:USERNAME
    $hostn = $env:COMPUTERNAME.ToLower()

    # ----------------------------
    # Current Path
    # ----------------------------
    $ellipsis = "..."
    $path = $pwd.Path
    $repoRoot = $null

    # home -> ~
    if ($HOME -and $path.StartsWith($HOME, [System.StringComparison]::OrdinalIgnoreCase)) {
        $path = "~" + $path.Substring($HOME.Length)
    }

    # git repo 감지
    try {
        $repoRoot = git rev-parse --show-toplevel 2>$null
    } catch {}

    if ($repoRoot) {

        $repoName = Split-Path $repoRoot -Leaf
        $relative = $pwd.Path.Substring($repoRoot.Length).TrimStart('\')

        if ($relative) {
            $parts = @($repoName) + ($relative -split '\\')
        } else {
            $parts = @($repoName)
        }

    } else {

        $parts = $path -split '[\\/]'
        $parts = $parts | Where-Object { $_ -ne "" }
    }

    # 최종 3개만 표시
    if ($parts.Count -gt 3) {
        $parts = $parts[-3..-1]
        $path = $ellipsis + "\" + ($parts -join "\")
    }
    else {
        if ($repoRoot) {
            $path = $ellipsis + "\" + ($parts -join "\")
        } else {
            $path = $parts -join "\"
        }
    }

    # ----------------------------
    # Admin check
    # ----------------------------
    $isAdmin = $false

    try {
        $identity  = [Security.Principal.WindowsIdentity]::GetCurrent()
        $principal = New-Object Security.Principal.WindowsPrincipal($identity)
        $isAdmin   = $principal.IsInRole(
            [Security.Principal.WindowsBuiltInRole]::Administrator
        )
    } catch {}

    # ----------------------------
    # Git branch (safe + fast)
    # ----------------------------
    $git = ""

    try {
        $branch = git branch --show-current 2>$null

        if (-not [string]::IsNullOrWhiteSpace($branch)) {
            $branch = $branch.Trim()
            $gitIcon = [char]0xF418
            $git = "$gitIcon $branch"
        }
    }
    catch {}

    # ----------------------------
    # Clock
    # ----------------------------
    $time = Get-Date -Format "HH:mm:ss"

    # ----------------------------
    # Width calc
    # ----------------------------
    $width = 80

    try {
        $width = $Host.UI.RawUI.WindowSize.Width
    } catch {}

    $left = "$osIcon  $user at $hostn in $path"     # 아이콘 2칸 + 공백 1칸 = 3
    $fill = $width - $left.Length - $time.Length

    if ($git) {
        $fill -= " on $git".Length
    }

    if ($fill -lt 1) { $fill = 1 }

    $spaces = " " * $fill

    # ----------------------------
    # First Line
    # ----------------------------
    Write-Host "${blue}${osIcon} ${reset} " -NoNewline
    Write-Host "${purple}${user} " -NoNewline
    Write-Host "${white}at " -NoNewline
    Write-Host "${blue}${hostn} " -NoNewline
    Write-Host "${white}in " -NoNewline
    Write-Host "${cyan}${path}" -NoNewline

    if ($git) {
        Write-Host " ${white}on " -NoNewline
        Write-Host "${purple}${git}" -NoNewline
    }

    if ($isAdmin) {
        Write-Host " ${red}${adminIcon}" -NoNewline
    }

    Write-Host "${spaces}" -NoNewline
    Write-Host "${gray}${time}"

    # ----------------------------
    # Second Line
    # ----------------------------
    if ($ok) {
        Write-Host "${green}${arrow}" -NoNewline
    }
    else {
        Write-Host "${red}${arrow}" -NoNewline
    }

    return " "
}