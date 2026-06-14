# ------------------------------------------------------------
# Starship
# ------------------------------------------------------------

set -gx STARSHIP_CONFIG ~/.config/starship/starship.toml

starship init fish | source

# ------------------------------------------------------------
# Direnv
# ------------------------------------------------------------

if type -q direnv
    direnv hook fish | source
end

# ------------------------------------------------------------
# zoxide
# ------------------------------------------------------------

if type -q zoxide
    zoxide init fish | source
end

# ------------------------------------------------------------
# Aliases
# ------------------------------------------------------------

if type -q eza
    alias ls="eza"
    alias ll="eza -la"
    alias lt="eza --tree"
end

if type -q bat
    alias cat="bat"
end