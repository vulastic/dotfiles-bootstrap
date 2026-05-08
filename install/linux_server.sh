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
# Install Starship
# ------------------------------------------------------------
info "Installing Starship"

if ! command -v starship >/dev/null; then
    curl -sS https://starship.rs/install.sh | sh -s -- -y
else
    info "Starship already installed → skipping"
fi


# ------------------------------------------------------------
# Enable SSH service
# ------------------------------------------------------------
info "Enabling SSH service"

if command -v systemctl >/dev/null; then
    if systemctl list-unit-files | grep -q "^sshd.service"; then
        sudo systemctl enable sshd
        sudo systemctl start sshd
    elif systemctl list-unit-files | grep -q "^ssh.service"; then
        sudo systemctl enable ssh
        sudo systemctl start ssh
    fi
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
# Starship config install
# ------------------------------------------------------------
info "Installing Starship configuration"

STARSHIP_SRC="$REPO_ROOT/config/starship/starship.toml"
STARSHIP_DIR="$HOME/.config/starship"
STARSHIP_DST="$STARSHIP_DIR/starship.toml"

if [ ! -f "$STARSHIP_SRC" ]; then
    echo "ERROR: starship config not found: $STARSHIP_SRC"
    exit 1
fi

mkdir -p "$STARSHIP_DIR"

if [ -f "$STARSHIP_DST" ]; then
    BACKUP="$STARSHIP_DST.bak.$(date +%Y%m%d%H%M%S)"
    cp "$STARSHIP_DST" "$BACKUP"
    info "Backed up existing Starship config"
fi

cp "$STARSHIP_SRC" "$STARSHIP_DST"
info "Starship config installed"


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
info "Linux bootstrap installation complete!"

echo ""
info "Reload shell configuration with:"
echo "source ~/.bashrc"
echo ""