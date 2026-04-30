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
    termux-services ncurses-utils rsync cronie tar gzip unzip


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
# theme
# ------------------------------------------------------------
THEME_SRC="$REPO_ROOT/config/bash/theme/tokyonight.sh"
THEME_DIR="$HOME/.config/themes"
THEME_DST="$THEME_DIR/tokyonight.sh"

info "Installing tokyonight theme"

if [ ! -f "$THEME_SRC" ]; then
    echo "ERROR: theme source not found: $THEME_SRC"
    exit 1
fi

mkdir -p "$THEME_DIR"

if [ -f "$THEME_DST" ]; then
    BACKUP="$THEME_DST.bak.$(date +%Y%m%d%H%M%S)"
    cp "$THEME_DST" "$BACKUP"
    info "Existing theme backed up: $BACKUP"
fi

cp "$THEME_SRC" "$THEME_DST"
info "Theme installed to $THEME_DST"


# ------------------------------------------------------------
# Bash theme activation
# ------------------------------------------------------------
THEME_LINE='[ -f "$HOME/.config/themes/tokyonight.sh" ] && source "$HOME/.config/themes/tokyonight.sh"'

BASHRC="$HOME/.bashrc"
touch "$BASHRC"

if ! grep -Fxq "$THEME_LINE" "$BASHRC"; then
    echo "$THEME_LINE" >> "$BASHRC"
    info "TokyoNight theme added to bashrc"
fi


# ------------------------------------------------------------
# Completion
# ------------------------------------------------------------
info "Termux bootstrap Installation complete!"

echo ""
warn "Next steps:"
warn "  sv-enable sshd"
warn "  sv up sshd"
warn "  sv status sshd"
echo ""