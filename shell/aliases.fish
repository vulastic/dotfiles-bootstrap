alias vim='nvim'
alias vi='nvim'

if type -q bat
    alias cat='bat'
else if type -q batcat
    alias cat='batcat'
end

alias grep='rg'

if type -q fd
    alias find='fd'
else if type -q fdfind
    alias find='fdfind'
end

if type -q eza
    alias ls='eza --icons=auto'
    alias ll='eza --icons=auto --long --git'
    alias la='eza --icons=auto --long --all --git'
end

if type -q zoxide
    zoxide init fish | source
end

if not set -q GHQ_ROOT
    set -gx GHQ_ROOT "$HOME/src"
end

set -gx STARSHIP_CONFIG "$HOME/.config/starship/starship.toml"
