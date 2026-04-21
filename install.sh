#!/usr/bin/env bash

set -euo pipefail

# Determine script directory and create temp directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TEMP_DIR="$(mktemp -d)"
REPO_URL="https://github.com/vulastic/dotfiles-bootstrap/archive/refs/heads/main.tar.gz"

# Cleanup function to remove temp directory on exit
cleanup() {
    rm -rf "$TEMP_DIR"
}
trap cleanup EXIT

# Download and extract the repository
echo "Downloading latest dotfiles-bootstrap from GitHub..."
curl -fsSL "$REPO_URL" | tar -xz -C "$TEMP_DIR"

# Find the extracted directory (should be dotfiles-bootstrap-main)
EXTRACTED_DIR="$TEMP_DIR/dotfiles-bootstrap-main"
if [ ! -d "$EXTRACTED_DIR" ]; then
    # Try alternative naming
    EXTRACTED_DIR=$(find "$TEMP_DIR" -maxdepth 1 -type d -name "dotfiles-bootstrap-*" | head -1)
fi

if [ ! -d "$EXTRACTED_DIR" ]; then
    echo "Error: Failed to extract repository" >&2
    exit 1
fi

# Change to extracted directory and run the appropriate installer
cd "$EXTRACTED_DIR"

if [ -d "/data/data/com.termux/files/usr" ] || [ -n "${TERMUX_VERSION:-}" ]; then
  exec bash "$./install/termux.sh"
else
  exec bash "$./install/linux.sh"
fi

# Remove temp directory (handled by trap on EXIT)
echo "Installation complete!"
rm -rf "$TEMP_DIR"