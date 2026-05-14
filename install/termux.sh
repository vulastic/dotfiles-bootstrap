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

section "Termux Development Environment Setup"

# ------------------------------------------------------------
# Storage access
# ------------------------------------------------------------

info "Allowing internal storage access"

if [[ ! -d "$HOME/storage" ]]; then
    termux-setup-storage
else
    info "Storage already configured → skipping"
fi

# ------------------------------------------------------------
# Package management
# ------------------------------------------------------------

section "Installing packages"

pkg update -y

pkg install -y \
    openssh \
    tmux \
    git \
    curl \
    wget \
    vim \
    htop \
    procps \
    termux-services \
    ncurses-utils \
    rsync \
    cronie \
    tar \
    gzip \
    unzip \
    starship

success "Packages installed"

# ------------------------------------------------------------
# tmux config
# ------------------------------------------------------------

section "Installing tmux configuration"

install_config \
    "$REPO_ROOT/config/tmux/tmux.conf" \
    "$HOME/.config/tmux/tmux.conf"

# ------------------------------------------------------------
# Starship config
# ------------------------------------------------------------

section "Installing Starship configuration"

install_config \
    "$REPO_ROOT/config/starship/starship.toml" \
    "$HOME/.config/starship/starship.toml"

# ------------------------------------------------------------
# Bash configuration
# ------------------------------------------------------------

section "Configuring bash"

append_if_missing \
'export STARSHIP_CONFIG="$HOME/.config/starship/starship.toml"
eval "$(starship init bash --print-full-init)"' \
"$HOME/.bashrc"

success "Bash configuration updated"

# ------------------------------------------------------------
# Completion
# ------------------------------------------------------------

section "Installation complete"

warn "Next steps:"
warn "  Close and reopen the Termux session"
warn "  sv-enable sshd"