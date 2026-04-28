#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/common.sh"

# Termux 환경을 위해 PREFIX 설정 (common.sh의 install_zellij 등에서 활용)
export PREFIX=true

# 필수 명령어 확인
require_cmd() {
  command -v "$1" >/dev/null 2>&1 || { log ERROR "Missing required command: $1"; exit 1; }
}

# Termux 패키지 설치
pkg_install() {
  pkg update -y && pkg install -y "$@"
}

# Neovim 설치
install_neovim() {
  log INFO "Installing Neovim..."
  pkg install -y neovim
}

# Fish 쉘 설치
install_fish() {
  log INFO "Installing Fish..."
  pkg install -y fish
}

# fzf 설치
install_fzf() {
  log INFO "Installing fzf..."
  pkg install -y fzf
}

# zoxide 설치
install_zoxide() {
  log INFO "Installing zoxide..."
  pkg install -y zoxide
}

# 기본 쉘 설정 (fish)
configure_default_shell() {
  log INFO "Setting fish as default shell..."
  if command -v fish >/dev/null 2>&1; then
    # Termux에서는 chsh가 제한적일 수 있으므로 경고만 출력
    log WARN "Termux default shell change might require manual intervention (e.g., via termux-setup-storage or manual config)."
  fi
}

# eza 설치
install_eza() {
  log INFO "Installing eza..."
  pkg install -y eza
}

# ghq 설치
install_ghq() {
  log INFO "Installing ghq..."
  pkg install -y ghq
}

# 폰트 설치 (Sarasa, Iosevka)
install_fonts() {
  log INFO "Installing fonts..."
  # Sarasa Mono K
  local sarasa_dir="$HOME/.local/share/fonts/SarasaMonoK"
  if [ ! -d "$sarasa_dir" ] || ! fc-list | grep -iq "Sarasa Mono K"; then
    log INFO "Installing Sarasa Mono K..."
    local ver=$(curl -fsSL https://api.github.com/repos/be5invis/Sarasa-Gothic/releases/latest | grep '"tag_name"' | sed 's/.*"v\([^"]*\)".*/\1/')
    local tmp=$(mktemp -d)
    curl -fsSL -o "$tmp/font.7z" "https://github.com/be5invis/Sarasa-Gothic/releases/download/v${ver}/SarasaMonoK-TTF-${ver}.7z"
    mkdir -p "$sarasa_dir"
    7z x -y -o"$sarasa_dir" "$tmp/font.7z" >/dev/null 2>&1
    rm -rf "$tmp"
    fc-cache -f "$HOME/.local/share/fonts" 2>/dev/null || true
  fi

  # IosevkaTerm Nerd Font
  local iosevka_dir="$HOME/.local/share/fonts/IosevkaTermNerdFont"
  if [ ! -d "$iosevka_dir" ] || ! fc-list | grep -iq "IosevkaTerm Nerd Font"; then
    log INFO "Installing IosevkaTerm Nerd Font..."
    local ver=$(curl -fsSL https://api.github.com/repos/ryanoasis/nerd-fonts/releases/latest | grep '"tag_name"' | sed 's/.*"v\([^"]*\)".*/\1/')
    local tmp=$(mktemp -d)
    curl -fsSL -o "$tmp/font.zip" "https://github.com/ryanoasis/nerd-fonts/releases/download/v${ver}/IosevkaTerm.zip"
    mkdir -p "$iosevka_dir"
    unzip -o -q -d "$iosevka_dir" "$tmp/font.zip"
    rm -rf "$tmp"
    fc-cache -f "$HOME/.local/share/fonts" 2>/dev/null || true
  fi
}

# Bash 프롬프트 설정 (Starship 사용)
configure_bash_starship() {
  log INFO "Configuring Starship for Bash..."
  local bashrc="$HOME/.bashrc"
  append_once 'eval "$(starship init bash)"' "$bashrc"
}

main() {
  require_cmd pkg; require_cmd curl; require_cmd git

  log INFO "Installing Termux shell stack"
  
  # 1. 설치 단계 (Installation Phase)
  pkg_install git curl wget ripgrep fd neovim fish fzf zoxide eza ghq starship zellij
  
  # 2. 설정 단계 (Configuration Phase)
  log INFO "Starting configuration phase..."
  configure_bash_starship
  configure_starship
  configure_fish
  configure_zellij
  configure_git
  configure_shell_aliases "$HOME/.bashrc"
  configure_default_shell
  configure_nvim

  log INFO "Termux bootstrap complete"
}

main "$@"