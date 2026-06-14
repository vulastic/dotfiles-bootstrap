#!/usr/bin/env bash

set -euo pipefail

# ------------------------------------------------------------
# Paths
# ------------------------------------------------------------

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

# ------------------------------------------------------------
# Common
# ------------------------------------------------------------

source "${SCRIPT_DIR}/common.sh"

section "Linux Server Environment Setup"

PKG_MANAGER="$(detect_package_manager)"

info "Detected package manager: ${PKG_MANAGER}"

# ------------------------------------------------------------
# System update
# ------------------------------------------------------------

section "Updating system packages"

case "$PKG_MANAGER" in
    apt)
        sudo apt update -y
        sudo apt upgrade -y
        ;;
    dnf)
        sudo dnf upgrade -y
        ;;
    pacman)
        sudo pacman -Syu --noconfirm
        ;;
    *)
        die "Unsupported package manager"
        ;;
esac

success "System packages updated"

# ------------------------------------------------------------
# Install packages
# ------------------------------------------------------------

section "Installing packages"

case "$PKG_MANAGER" in
    apt)
        sudo apt install -y \
            openssh-server \
            tmux \
            git \
            curl \
            wget \
            vim \
            htop \
            procps \
            rsync \
            cron \
            tar \
            gzip \
            unzip
        ;;
    dnf)
        sudo dnf install -y \
            openssh-server \
            tmux \
            git \
            curl \
            wget \
            vim \
            htop \
            procps-ng \
            rsync \
            cronie \
            tar \
            gzip \
            unzip
        ;;
    pacman)
        sudo pacman -S --noconfirm \
            openssh \
            tmux \
            git \
            curl \
            wget \
            vim \
            htop \
            procps-ng \
            rsync \
            cronie \
            tar \
            gzip \
            unzip
        ;;
esac

success "Packages installed"

# ------------------------------------------------------------
# Install Starship
# ------------------------------------------------------------

section "Installing Starship"

if ! has starship; then
    curl -sS https://starship.rs/install.sh | sh -s -- -y
    success "Starship installed"
else
    info "Starship already installed → skipping"
fi

# ------------------------------------------------------------
# Enable SSH service
# ------------------------------------------------------------

section "Enabling SSH service"

if has systemctl; then
    if systemctl list-unit-files | grep -q "^sshd.service"; then
        sudo systemctl enable sshd
        sudo systemctl start sshd

    elif systemctl list-unit-files | grep -q "^ssh.service"; then
        sudo systemctl enable ssh
        sudo systemctl start ssh
    fi
fi

success "SSH service configured"

# ------------------------------------------------------------
# Install tmux config
# ------------------------------------------------------------

section "Installing tmux configuration"

install_config \
    "$REPO_ROOT/config/tmux/tmux.conf" \
    "$HOME/.config/tmux/tmux.conf"

# ------------------------------------------------------------
# Install Starship config
# ------------------------------------------------------------

section "Installing Starship configuration"

install_config \
    "$REPO_ROOT/config/starship/starship.toml" \
    "$HOME/.config/starship/starship.toml"

# ------------------------------------------------------------
# Configure bash
# ------------------------------------------------------------

section "Configuring bash"

append_if_missing \
'export STARSHIP_CONFIG="$HOME/.config/starship/starship.toml"
eval "$(starship init bash)"' \
"$HOME/.bashrc"

success "Bash configuration updated"

# ------------------------------------------------------------
# Completion
# ------------------------------------------------------------

section "Installation complete"

info "Reload shell configuration with:"
info "  source ~/.bashrc"