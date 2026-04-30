#!/usr/bin/env bash

set -euo pipefail

# ------------------------------------------------------------
# Helper
# ------------------------------------------------------------
info() {
    echo -e "\e[38;2;255;158;100m$1\e[0m"
}

info "Starting bootstrap installer..."

# ------------------------------------------------------------
# Temp workspace
# ------------------------------------------------------------
TEMP_DIR="$(mktemp -d)"
REPO_URL="https://github.com/vulastic/dotfiles-bootstrap/archive/refs/heads/main.tar.gz"

cleanup() {
    rm -rf "$TEMP_DIR"
}
trap cleanup EXIT

# ------------------------------------------------------------
# Download repo
# ------------------------------------------------------------
info "Downloading repository..."

curl -fsSL "$REPO_URL" | tar -xz -C "$TEMP_DIR"

EXTRACTED_DIR=$(find "$TEMP_DIR" -maxdepth 1 -type d -name "dotfiles-bootstrap-*" | head -n 1)

if [ ! -d "$EXTRACTED_DIR" ]; then
    echo "ERROR: extraction failed"
    exit 1
fi

EXTRACTED_DIR=$(find "$TEMP_DIR" -maxdepth 1 -type d -name "dotfiles-bootstrap-*")

if [ ! -d "$EXTRACTED_DIR" ]; then
    echo "ERROR: extraction failed"
    exit 1
fi

INSTALL_DIR="$EXTRACTED_DIR/install"

# ------------------------------------------------------------
# OS detection
# ------------------------------------------------------------
IS_TERMUX=false

if [ -n "${TERMUX_VERSION:-}" ] || [ -d "/data/data/com.termux/files/usr" ]; then
    IS_TERMUX=true
fi

# ------------------------------------------------------------
# Environment selection (Linux only)
# ------------------------------------------------------------

if [ "$IS_TERMUX" = true ]; then
    info "Detected Termux → running automated install"
    bash "$INSTALL_DIR/termux.sh"
else
    echo ""
    echo "Select environment:"
    echo "1) Server (default)"
    echo "2) Development"
    echo ""

    read -rp "Enter choice [1/2]: " ENV_CHOICE
    ENV_CHOICE="${ENV_CHOICE:-1}"

    case "$ENV_CHOICE" in
      2)
          info "Selected: Development environment"
          bash "$INSTALL_DIR/linux_development.sh"
          ;;
      *)
          info "Selected: Server environment"
          bash "$INSTALL_DIR/linux_server.sh"
          ;;
    esac
fi

info "Installation complete!"