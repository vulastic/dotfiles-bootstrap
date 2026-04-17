#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=install/common.sh
source "$SCRIPT_DIR/common.sh"

require_cmd() {
  if ! command -v "$1" >/dev/null 2>&1; then
    log ERROR "Missing required command: $1"
    exit 1
  fi
}

apt_install() {
  sudo apt-get update
  sudo apt-get install -y "$@"
}

install_eza() {
  if command -v eza >/dev/null 2>&1; then
    log INFO "eza already installed"
    return
  fi

  sudo mkdir -p /etc/apt/keyrings
  curl -fsSL https://raw.githubusercontent.com/eza-community/eza/main/deb.asc | sudo gpg --dearmor -o /etc/apt/keyrings/gierens.gpg
  echo "deb [signed-by=/etc/apt/keyrings/gierens.gpg] http://deb.gierens.de stable main" | sudo tee /etc/apt/sources.list.d/gierens.list >/dev/null
  sudo chmod 644 /etc/apt/keyrings/gierens.gpg /etc/apt/sources.list.d/gierens.list
  sudo apt-get update
  sudo apt-get install -y eza
}

install_fisher() {
  if ! command -v fish >/dev/null 2>&1; then
    log ERROR "fish is required before installing fisher"
    exit 1
  fi

  if fish -c 'functions -q fisher' >/dev/null 2>&1; then
    log INFO "fisher already installed"
    return
  fi

  curl -fsSL https://raw.githubusercontent.com/jorgebucaran/fisher/main/functions/fisher.fish | fish -c 'source; fisher install jorgebucaran/fisher'
}

configure_fish() {
  ensure_dir "$HOME/.config/fish/functions"
  copy_config "$CONFIG_DIR/fish/config.fish" "$HOME/.config/fish/config.fish"
  fish -c 'fisher install IlanCosman/tide@v6 jorgebucaran/autopair.fish PatrickF1/fzf.fish'
  fish -c 'set -U tide_left_prompt_items os pwd git newline character'
  fish -c 'set -U tide_right_prompt_items status cmd_duration time'
  fish -c 'set -U tide_color_os 7aa2f7'
  fish -c 'set -U tide_color_pwd 7dcfff'
  fish -c 'set -U tide_color_git_branch bb9af7'
  fish -c 'set -U tide_color_git_operation e0af68'
  fish -c 'set -U tide_color_git_stash 9ece6a'
  fish -c 'set -U tide_color_status ok'
  fish -c 'set -U tide_color_command_duration e0af68'
  fish -c 'set -U tide_color_time 565f89'
}

install_ghq() {
  if command -v ghq >/dev/null 2>&1; then
    log INFO "ghq already installed"
    return
  fi

  local arch
  local package_name
  local tmp_deb

  arch="$(dpkg --print-architecture)"
  case "$arch" in
    amd64) package_name='ghq_linux_amd64.deb' ;;
    arm64) package_name='ghq_linux_arm64.deb' ;;
    armhf) package_name='ghq_linux_armv6.deb' ;;
    *)
      log INFO "Unsupported ghq package architecture: $arch"
      return
      ;;
  esac

  tmp_deb="$(mktemp --suffix=.deb)"
  curl -fsSL -o "$tmp_deb" "https://github.com/x-motemen/ghq/releases/download/v1.6.2/$package_name"
  sudo dpkg -i "$tmp_deb" || sudo apt-get install -f -y
  rm -f "$tmp_deb"
}

install_fonts() {
  install_font_sarasa
  install_font_iosevka
}

install_font_sarasa() {
  if command -v fc-list >/dev/null 2>&1 && fc-list | grep -iq "Sarasa Mono K"; then
    log INFO "Sarasa Mono K already available"
    return
  fi

  log INFO "Installing Sarasa Mono K from GitHub Releases"
  local version
  version=$(curl -fsSL https://api.github.com/repos/be5invis/Sarasa-Gothic/releases/latest | grep '"tag_name"' | sed 's/.*"v\([^"]*\)".*/\1/')
  if [ -z "$version" ]; then
    log ERROR "Failed to fetch latest Sarasa version"
    return
  fi

  local tmp_dir
  tmp_dir=$(mktemp -d)
  local archive="SarasaMonoK-TTF-${version}.7z"
  local url="https://github.com/be5invis/Sarasa-Gothic/releases/download/v${version}/${archive}"

  log INFO "Downloading $url"
  curl -fsSL -o "${tmp_dir}/${archive}" "$url" || {
    log ERROR "Failed to download Sarasa Mono K"
    rm -rf "$tmp_dir"
    return
  }

  mkdir -p "$HOME/.local/share/fonts/SarasaMonoK"
  7z x -y -o"$HOME/.local/share/fonts/SarasaMonoK" "${tmp_dir}/${archive}" >/dev/null 2>&1 || \
    7z x -y -o"$HOME/.local/share/fonts/SarasaMonoK" "${tmp_dir}/${archive}"

  rm -rf "$tmp_dir"
  fc-cache -f "$HOME/.local/share/fonts" 2>/dev/null || true
  log INFO "Sarasa Mono K installed"
}

install_font_iosevka() {
  if command -v fc-list >/dev/null 2>&1 && fc-list | grep -iq "Iosevka"; then
    log INFO "Iosevka already available"
    return
  fi

  log INFO "Installing Iosevka Nerd Font from GitHub Releases"
  local version
  version=$(curl -fsSL https://api.github.com/repos/be5invis/Iosevka/releases/latest | grep '"tag_name"' | sed 's/.*"v\([^"]*\)".*/\1/')
  if [ -z "$version" ]; then
    log ERROR "Failed to fetch latest Iosevka version"
    return
  fi

  local tmp_dir
  tmp_dir=$(mktemp -d)
  local archive="PkgTTF-Iosevka-${version}.zip"
  local url="https://github.com/be5invis/Iosevka/releases/download/v${version}/${archive}"

  log INFO "Downloading $url"
  curl -fsSL -o "${tmp_dir}/${archive}" "$url" || {
    log ERROR "Failed to download Iosevka"
    rm -rf "$tmp_dir"
    return
  }

  mkdir -p "$HOME/.local/share/fonts/Iosevka"
  unzip -o -q -d "$HOME/.local/share/fonts/Iosevka" "${tmp_dir}/${archive}"

  rm -rf "$tmp_dir"
  fc-cache -f "$HOME/.local/share/fonts" 2>/dev/null || true
  log INFO "Iosevka Nerd Font installed"
}

main() {
  require_cmd sudo
  require_cmd curl
  require_cmd git

  log INFO "Installing Ubuntu shell stack"
  apt_install fish tmux neovim fzf gh jq unzip ripgrep fd-find bat git gnupg p7zip-full
  install_eza

  if ! command -v zoxide >/dev/null 2>&1; then
    curl -fsSL https://raw.githubusercontent.com/ajeetdsouza/zoxide/main/install.sh | bash
  fi

  install_ghq

  install_starship
  install_fisher
  configure_starship
  configure_fish
  configure_tmux
  configure_git
  configure_shell_aliases "$HOME/.bashrc"
  install_lazyvim
  configure_nvim
  install_fonts

  log INFO "Ubuntu bootstrap complete"
}

main "$@"
