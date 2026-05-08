#!/usr/bin/env bash

set -e

# ------------------------------------------------------------
# Helper
# ------------------------------------------------------------

info() {
    echo -e "\e[38;2;255;158;100m$1\e[0m"
}

warn() {
    echo -e "\e[38;2;224;175;104m$1\e[0m"
}

info "Allowing internal storage access"
if [ ! -d "$HOME/storage" ]; then
    termux-setup-storage
else
    echo "Storage already configured → skipping"
fi


# ------------------------------------------------------------
# Package management
# ------------------------------------------------------------
info "Updating package index"
pkg update -y

info "Installing necessary packages"
pkg install -y \
    openssh tmux git curl wget vim htop procps \
    termux-services ncurses-utils rsync cronie tar gzip unzip starship


# ------------------------------------------------------------
# Paths
# ------------------------------------------------------------
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"


# ------------------------------------------------------------
# tmux config
# ------------------------------------------------------------
TMUX_SRC="$REPO_ROOT/config/tmux/tmux.conf"
TMUX_DIR="$HOME/.config/tmux"
TMUX_DST="$TMUX_DIR/tmux.conf"

info "Installing tmux configuration"

if [ ! -f "$TMUX_SRC" ]; then
    echo "ERROR: tmux config not found: $TMUX_SRC"
    exit 1
fi

mkdir -p "$TMUX_DIR"

if [ -f "$TMUX_DST" ]; then
    BACKUP="$TMUX_DST.bak.$(date +%Y%m%d%H%M%S)"
    cp "$TMUX_DST" "$BACKUP"
    info "Existing tmux config backed up: $BACKUP"
fi

cp "$TMUX_SRC" "$TMUX_DST"
info "tmux config installed to $TMUX_DST"


# ------------------------------------------------------------
# Starship config
# ------------------------------------------------------------
STARSHIP_SRC="$REPO_ROOT/config/starship/starship.toml"
STARSHIP_DIR="$HOME/.config/starship"
STARSHIP_DST="$STARSHIP_DIR/starship.toml"

info "Installing Starship configuration"

if [ ! -f "$STARSHIP_SRC" ]; then
    echo "ERROR: starship config not found: $STARSHIP_SRC"
    exit 1
fi

mkdir -p "$STARSHIP_DIR"

if [ -f "$STARSHIP_DST" ]; then
    BACKUP="$STARSHIP_DST.bak.$(date +%Y%m%d%H%M%S)"
    cp "$STARSHIP_DST" "$BACKUP"
    info "Existing Starship config backed up: $BACKUP"
fi

cp "$STARSHIP_SRC" "$STARSHIP_DST"
info "Starship config installed to $STARSHIP_DST"


# ------------------------------------------------------------
# Bash Starship activation
# ------------------------------------------------------------
BASHRC="$HOME/.bashrc"
touch "$BASHRC"

STARSHIP_CONFIG_LINE='export STARSHIP_CONFIG="$HOME/.config/starship/starship.toml"'
STARSHIP_INIT_LINE='eval "$(starship init bash)"'

if ! grep -Fxq "$STARSHIP_CONFIG_LINE" "$BASHRC"; then
    echo "$STARSHIP_CONFIG_LINE" >> "$BASHRC"
    info "STARSHIP_CONFIG added to bashrc"
fi

if ! grep -Fxq "$STARSHIP_INIT_LINE" "$BASHRC"; then
    echo "$STARSHIP_INIT_LINE" >> "$BASHRC"
    info "Starship initialization added to bashrc"
fi


# ------------------------------------------------------------
# Completion
# ------------------------------------------------------------
info "Termux bootstrap Installation complete!"

echo ""
warn "Next steps:"
warn "  sv-enable sshd"
warn "  pkg upgrade -y"
warn "  source ~/.bashrc"
echo ""