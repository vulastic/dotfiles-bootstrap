#!/usr/bin/env bash

# ------------------------------------------------------------
# Colors
# ------------------------------------------------------------

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m'

# ------------------------------------------------------------
# Logging
# ------------------------------------------------------------

info() {
    echo -e "\e[38;2;122;162;247m$1\e[0m"
}

success() {
    echo -e "\e[38;2;158;206;106m$1\e[0m"
}

warn() {
    echo -e "\e[38;2;224;175;104m$1\e[0m"
}

error() {
    echo -e "\e[38;2;247;118;142m$1\e[0m"
}

section() {
    echo
    echo -e "\e[38;2;187;154;247m== $1 ==\e[0m"
}

# ------------------------------------------------------------
# Exit helpers
# ------------------------------------------------------------

die() {
    error "$1"
    exit 1
}

# ------------------------------------------------------------
# Command helpers
# ------------------------------------------------------------

has() {
    command -v "$1" >/dev/null 2>&1
}

require_command() {
    has "$1" || die "Required command not found: $1"
}

# ------------------------------------------------------------
# Sudo
# ------------------------------------------------------------

require_sudo() {
    if ! has sudo; then
        die "sudo is not installed"
    fi

    sudo -v
}

# ------------------------------------------------------------
# Retry helper
# ------------------------------------------------------------

retry() {
    local retries=3
    local count=0

    until "$@"; do
        exit_code=$?

        count=$((count + 1))

        if [[ $count -ge $retries ]]; then
            error "Command failed after ${retries} attempts"
            return "$exit_code"
        fi

        warn "Retry ${count}/${retries}..."
        sleep 2
    done
}

# ------------------------------------------------------------
# Download helper
# ------------------------------------------------------------

download() {
    local url="$1"
    local output="$2"

    if has curl; then
        curl -fsSL "$url" -o "$output"
    elif has wget; then
        wget -q "$url" -O "$output"
    else
        die "Neither curl nor wget found"
    fi
}

# ------------------------------------------------------------
# Detect OS
# ------------------------------------------------------------

detect_os() {
    case "$(uname -s)" in
        Linux)
            echo "linux"
            ;;
        Darwin)
            echo "macos"
            ;;
        *)
            echo "unknown"
            ;;
    esac
}

# ------------------------------------------------------------
# Detect package manager
# ------------------------------------------------------------

detect_package_manager() {
    if has apt; then
        echo "apt"
    elif has pacman; then
        echo "pacman"
    elif has dnf; then
        echo "dnf"
    elif has zypper; then
        echo "zypper"
    else
        echo "unknown"
    fi
}

# ------------------------------------------------------------
# Append if missing
# ------------------------------------------------------------

append_if_missing() {
    local text="$1"
    local file="$2"

    touch "$file"

    if ! grep -Fq "$text" "$file"; then
        printf '\n%s\n' "$text" >> "$file"
    fi
}

# ------------------------------------------------------------
# Change shell
# ------------------------------------------------------------

set_default_shell() {
    local shell_path

    shell_path="$(command -v zsh)"

    if [[ "$SHELL" != *"zsh" ]]; then
        chsh -s "$shell_path"
        success "Default shell changed to zsh"
    fi
}

# ------------------------------------------------------------
# Install config file
# ------------------------------------------------------------

install_config() {
    local src="$1"
    local dst="$2"

    if [[ ! -f "$src" ]]; then
        die "Config file not found: $src"
    fi

    mkdir -p "$(dirname "$dst")"

    if [[ -f "$dst" ]]; then
        local backup="${dst}.bak.$(date +%Y%m%d%H%M%S)"
        cp "$dst" "$backup"

        info "Existing config backed up:"
        info "  $backup"
    fi

    cp "$src" "$dst"

    success "Installed:"
    success "  $dst"
}