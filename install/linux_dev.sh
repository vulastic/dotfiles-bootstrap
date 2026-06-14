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

section "Linux Development Environment Setup"

require_sudo

PKG_MANAGER="$(detect_package_manager)"

info "Detected package manager: ${PKG_MANAGER}"

# ------------------------------------------------------------
# System Update
# ------------------------------------------------------------

section "Updating system"

case "$PKG_MANAGER" in

    apt)
        sudo apt update
        sudo apt upgrade -y
        ;;

    dnf)
        sudo dnf upgrade -y
        ;;

    pacman)
        sudo pacman -Syu --noconfirm
        ;;

    zypper)
        sudo zypper refresh
        sudo zypper update -y
        ;;

    *)
        die "Unsupported package manager"
        ;;
esac

success "System updated"

# ------------------------------------------------------------
# Minimal Packages
# ------------------------------------------------------------

section "Installing minimal packages"

case "$PKG_MANAGER" in

    apt)
        sudo apt install -y \
            git \
            curl \
            wget \
            fish \
            xz-utils \
            ca-certificates \
            openssh-server
        ;;

    dnf)
        sudo dnf install -y \
            git \
            curl \
            wget \
            fish \
            xz \
            ca-certificates \
            openssh-server
        ;;

    pacman)
        sudo pacman -S --noconfirm \
            git \
            curl \
            wget \
            fish \
            xz \
            ca-certificates \
            openssh
        ;;

    zypper)
        sudo zypper install -y \
            git \
            curl \
            wget \
            fish \
            xz \
            ca-certificates \
            openssh
        ;;

    *)
        die "Unsupported package manager"
        ;;
esac

success "Minimal packages installed"

# ------------------------------------------------------------
# Install Nix
# ------------------------------------------------------------

section "Installing Nix"

if ! has nix; then

    sh <(
        curl -L https://nixos.org/nix/install
    ) --daemon

    success "Nix installed"

else

    info "Nix already installed"

fi

# ------------------------------------------------------------
# Load Nix
# ------------------------------------------------------------

if [[ -f /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh ]]; then
    source /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh
fi

# ------------------------------------------------------------
# Install Nix Packages
# ------------------------------------------------------------

section "Installing Nix profile packages"

while read -r package; do

    [[ -z "$package" ]] && continue
    [[ "$package" =~ ^# ]] && continue

    info "Installing ${package}"

    nix profile install "nixpkgs#${package}"

done < "$REPO_ROOT/packages/nix-profile.txt"

success "Nix packages installed"

# ------------------------------------------------------------
# Install LazyVim
# ------------------------------------------------------------

section "Installing LazyVim"

if [[ ! -d "$HOME/.config/nvim" ]]; then

    git clone \
        https://github.com/LazyVim/starter \
        "$HOME/.config/nvim"

    rm -rf "$HOME/.config/nvim/.git"

    success "LazyVim installed"

else

    info "LazyVim already exists"

fi

# ------------------------------------------------------------
# TokyoNight
# ------------------------------------------------------------

section "Installing Nvim theme"

mkdir -p "$HOME/.config/nvim/lua/plugins"

install_directory \
    "$REPO_ROOT/config/nvim" \
    "$HOME/.config/nvim"

# ------------------------------------------------------------
# Fish
# ------------------------------------------------------------

section "Installing Fish configuration"

install_config \
    "$REPO_ROOT/config/fish/config.fish" \
    "$HOME/.config/fish/config.fish"

# ------------------------------------------------------------
# Starship
# ------------------------------------------------------------

section "Installing Starship configuration"

install_config \
    "$REPO_ROOT/config/starship/starship.toml" \
    "$HOME/.config/starship/starship.toml"

# ------------------------------------------------------------
# tmux
# ------------------------------------------------------------

section "Installing tmux configuration"

install_config \
    "$REPO_ROOT/config/tmux/tmux.conf" \
    "$HOME/.config/tmux/tmux.conf"

# ------------------------------------------------------------
# SSH
# ------------------------------------------------------------

section "Configuring SSH"

if has systemctl; then

    if systemctl list-unit-files | grep -q "^sshd.service"; then

        sudo systemctl enable sshd
        sudo systemctl start sshd

    elif systemctl list-unit-files | grep -q "^ssh.service"; then

        sudo systemctl enable ssh
        sudo systemctl start ssh

    fi

fi

success "SSH configured"

# ------------------------------------------------------------
# Default Shell
# ------------------------------------------------------------

section "Changing default shell"

FISH_PATH="$(command -v fish)"

if [[ "$SHELL" != "$FISH_PATH" ]]; then

    chsh -s "$FISH_PATH"

fi

success "Default shell set to Fish"

# ------------------------------------------------------------
# Complete
# ------------------------------------------------------------

section "Installation Complete"

info "Restart terminal or run:"
info "  exec fish"

success "Development environment ready"