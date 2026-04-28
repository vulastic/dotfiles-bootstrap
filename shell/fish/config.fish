if status is-interactive
end


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

# fzf 미리보기를 위한 bat 별칭 설정
if type -q bat
    alias bat 'bat'
else if type -q batcat
    alias bat 'batcat'
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

# Enable fzf key bindings (Alt+r, Alt+t, etc.)
if type -q fzf
    fzf --fish | source
    if type -q fzf_configure_bindings
        fzf_configure_bindings --history=\ar --directory=\at
    end
end

# Load aliases from aliases.fish
if test -f "$HOME/.config/shell/aliases.fish"
    source "$HOME/.config/shell/aliases.fish"
end


