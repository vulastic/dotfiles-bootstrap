#!/usr/bin/env bash

set -e

# ------------------------------------------------------------
# Helper
# ------------------------------------------------------------
info() {
    echo -e "\e[38;2;255;158;100m$1\e[0m"
}

# ------------------------------------------------------------
# System update
# ------------------------------------------------------------
info "Updating system packages"

if command -v apt >/dev/null; then
    sudo apt update -y && sudo apt upgrade -y
elif command -v dnf >/dev/null; then
    sudo dnf upgrade -y
elif command -v pacman >/dev/null; then
    sudo pacman -Syu --noconfirm
fi

# ------------------------------------------------------------
# Install packages
# ------------------------------------------------------------
info "Installing necessary packages"

if command -v apt >/dev/null; then
    sudo apt install -y \
        openssh-server tmux git curl wget vim htop procps \
        rsync cron tar gzip unzip
elif command -v dnf >/dev/null; then
    sudo dnf install -y \
        openssh-server tmux git curl wget vim htop procps-ng \
        rsync cronie tar gzip unzip
elif command -v pacman >/dev/null; then
    sudo pacman -S --noconfirm \
        openssh tmux git curl wget vim htop procps-ng \
        rsync cronie tar gzip unzip
fi

# ------------------------------------------------------------
# Enable SSH service (systemd)
# ------------------------------------------------------------
info "Enabling SSH service"

if command -v systemctl >/dev/null; then
    sudo systemctl enable ssh || sudo systemctl enable sshd
    sudo systemctl start ssh || sudo systemctl start sshd
fi

# ------------------------------------------------------------
# Paths
# ------------------------------------------------------------
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

# ------------------------------------------------------------
# tmux config install
# ------------------------------------------------------------
info "Installing tmux configuration"

TMUX_SRC="$REPO_ROOT/config/tmux/tmux.conf"
TMUX_DIR="$HOME/.config/tmux"
TMUX_DST="$TMUX_DIR/tmux.conf"

if [ ! -f "$TMUX_SRC" ]; then
    echo "ERROR: tmux config not found: $TMUX_SRC"
    exit 1
fi

mkdir -p "$TMUX_DIR"

if [ -f "$TMUX_DST" ]; then
    BACKUP="$TMUX_DST.bak.$(date +%Y%m%d%H%M%S)"
    cp "$TMUX_DST" "$BACKUP"
    info "Backed up existing tmux config"
fi

cp "$TMUX_SRC" "$TMUX_DST"
info "tmux config installed"

# ------------------------------------------------------------
# theme install
# ------------------------------------------------------------
info "Installing tokyonight theme"

THEME_SRC="$REPO_ROOT/config/bash/theme/tokyonight.sh"
THEME_DIR="$HOME/.config/themes"
THEME_DST="$THEME_DIR/tokyonight.sh"

if [ ! -f "$THEME_SRC" ]; then
    echo "ERROR: theme not found: $THEME_SRC"
    exit 1
fi

mkdir -p "$THEME_DIR"

if [ -f "$THEME_DST" ]; then
    BACKUP="$THEME_DST.bak.$(date +%Y%m%d%H%M%S)"
    cp "$THEME_DST" "$BACKUP"
    info "Backed up existing theme"
fi

cp "$THEME_SRC" "$THEME_DST"
info "Theme installed"

# ------------------------------------------------------------
# Completion
# ------------------------------------------------------------
info "Linux bootstrap installation complete!"