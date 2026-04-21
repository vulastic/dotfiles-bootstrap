set -gx EDITOR nvim
set -gx VISUAL nvim
set -gx GHQ_ROOT "$HOME/src"

if type -q eza
    alias ls 'eza --icons=auto'
    alias ll 'eza --icons=auto --long --git'
    alias la 'eza --icons=auto --long --all --git'
end

if type -q bat
    alias cat 'bat'
else if type -q batcat
    alias cat 'batcat'
end

if type -q rg
    alias grep 'rg'
end

if type -q fd
    alias find 'fd'
else if type -q fdfind
    alias find 'fdfind'
end

alias vim 'nvim'
alias vi 'nvim'

if type -q zoxide
    zoxide init fish | source
end

if type -q starship
    starship init fish | source
end

# Auto-start Zellij if not already inside a session
if not set -q ZELLIJ
    if type -q zellij
        zellij
    end
end

if type -q ghq
    set -gx GHQ_ROOT "$HOME/src"
end
