#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/common.sh"

# 필수 명령어 확인
require_cmd() {
  command -v "$1" >/dev/null 2>&1 || { log ERROR "Missing required command: $1"; exit 1; }
}

# APT 패키지 설치
apt_install() {
  sudo apt-get update && sudo apt-get install -y "$@"
}

# eza 설치 (외부 저장소 추가)
install_eza() {
  command -v eza >/dev/null 2>&1 && { log INFO "eza already installed"; return; }
  log INFO "Installing eza..."
  sudo mkdir -p /etc/apt/keyrings
  curl -fsSL https://raw.githubusercontent.com/eza-community/eza/main/deb.asc | sudo gpg --dearmor -o /etc/apt/keyrings/gierens.gpg
  echo "deb [signed-by=/etc/apt/keyrings/gierens.gpg] http://deb.gierens.de stable main" | sudo tee /etc/apt/sources.list.d/gierens.list >/dev/null
  sudo chmod 644 /etc/apt/keyrings/gierens.gpg /etc/apt/sources.list.d/gierens.list
  sudo apt-get update && sudo apt-get install -y eza
}

# ghq 설치
install_ghq() {
  command -v ghq >/dev/null 2>&1 && { log INFO "ghq already installed"; return; }
  log INFO "Installing ghq..."
  local arch=$(dpkg --print-architecture)
  case $arch in
    amd64) pkg="ghq_linux_amd64.zip" ;;
    arm64) pkg="ghq_linux_arm64.zip" ;;
    *) echo "Unsupported architecture: $arch. Skipping ghq installation."; return ;;
  esac
  
  local tmp=$(mktemp)
  local tmpdir=$(mktemp -d)
  curl -fsSL -o "$tmp" "https://github.com/x-motemen/ghq/releases/download/v1.6.2/$pkg"
  unzip -o "$tmp" -d "$tmpdir"
  sudo install -Dm755 "$tmpdir/ghq" /usr/local/bin/ghq
  rm -f "$tmp"
  rm -rf "$tmpdir"
}

# 폰트 설치 (Sarasa, Iosevka)
install_fonts() {
  log INFO "Installing fonts..."
  # Sarasa Mono K
  if ! fc-list | grep -iq "Sarasa Mono K"; then
    local ver=$(curl -fsSL https://api.github.com/repos/be5invis/Sarasa-Gothic/releases/latest | grep '"tag_name"' | sed 's/.*"v\([^"]*\)".*/\1/')
    local tmp=$(mktemp -d)
    curl -fsSL -o "$tmp/font.7z" "https://github.com/be5invis/Sarasa-Gothic/releases/download/v${ver}/SarasaMonoK-TTF-${ver}.7z"
    mkdir -p "$HOME/.local/share/fonts/SarasaMonoK"
    7z x -y -o"$HOME/.local/share/fonts/SarasaMonoK" "$tmp/font.7z" >/dev/null 2>&1
    rm -rf "$tmp"
  fi
  # IosevkaTerm Nerd Font
  if ! fc-list | grep -iq "IosevkaTerm Nerd Font"; then
    local ver=$(curl -fsSL https://api.github.com/repos/ryanoasis/nerd-fonts/releases/latest | grep '"tag_name"' | sed 's/.*"v\([^"]*\)".*/\1/')
    local tmp=$(mktemp -d)
    curl -fsSL -o "$tmp/font.zip" "https://github.com/ryanoasis/nerd-fonts/releases/download/v${ver}/IosevkaTerm.zip"
    mkdir -p "$HOME/.local/share/fonts/IosevkaTermNerdFont"
    unzip -o -q -d "$HOME/.local/share/fonts/IosevkaTermNerdFont" "$tmp/font.zip"
    rm -rf "$tmp"
  fi
  fc-cache -f "$HOME/.local/share/fonts" 2>/dev/null || true
}

main() {
  require_cmd sudo; require_cmd curl; require_cmd git

  log INFO "Installing Ubuntu shell stack"
  apt_install fish neovim fzf gh jq unzip ripgrep fd-find bat git gnupg p7zip-full
  install_eza

  # zoxide 설치
  command -v zoxide >/dev/null 2>&1 || curl -fsSL https://raw.githubusercontent.com/ajeetdsouza/zoxide/main/install.sh | bash

  install_ghq
  install_starship
  configure_starship
  configure_fish
  install_zellij
  configure_zellij
  configure_git
  configure_shell_aliases "$HOME/.bashrc"
  install_lazyvim
  configure_nvim
  install_fonts

  log INFO "Ubuntu bootstrap complete"
}

main "$@"
