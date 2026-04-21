#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/common.sh"

# Termux 패키지 설치
pkg_install() {
  pkg update -y && pkg install -y "$@"
}

# Zellij 설치 (공식 스크립트)
install_zellij() {
  command -v zellij >/dev/null 2>&1 && { log INFO "Zellij already installed"; return; }
  log INFO "Installing Zellij..."
  curl -sS https://zellij.org/install.sh | bash
}

# Fish 설정 및 플러그인 설치
configure_fish() {
  ensure_dir "$HOME/.config/fish/functions"
  copy_config "$CONFIG_DIR/fish/config.fish" "$HOME/.config/fish/config.fish"
  # fisher 설치 및 필수 플러그인 추가
  if ! fish -c 'functions -q fisher' >/dev/null 2>&1; then
    curl -fsSL https://raw.githubusercontent.com/jorgebucaran/fisher/main/functions/fisher.fish | fish -c 'source; fisher install jorgebucaran/fisher'
  fi
  fish -c 'fisher install jorgebucaran/autopair.fish PatrickF1/fzf.fish'
}

install_termux_font_notice() {
  log INFO "Set Sarasa Mono K or IosevkaTerm Nerd Font in the terminal app profile manually"
}

main() {
  log INFO "Installing Termux shell stack"
  pkg_install fish neovim fzf git gh curl unzip tar ripgrep fd bat eza

  # zoxide 설치
  command -v zoxide >/dev/null 2>&1 || curl -fsSL https://raw.githubusercontent.com/ajeetdsouza/zoxide/main/install.sh | bash

  # ghq 설치 (aarch64 및 amd64만 지원)
  local arch=$(uname -m)
  case $arch in
    aarch64) arch="arm64" ;;
    amd64) arch="amd64" ;;
    *)
      log INFO "Unsupported architecture: $arch. Skipping ghq installation."
      ;;
  esac

  if [ "$arch" != "" ]; then
    log INFO "Installing ghq..."
    local pkg="ghq_linux_${arch}.zip"
    local tmp=$(mktemp)
    local tmpdir=$(mktemp -d)
    curl -fsSL -o "$tmp" "https://github.com/x-motemen/ghq/releases/download/v1.6.2/$pkg"
    unzip -o "$tmp" -d "$tmpdir"
    # Termux는 /usr/local/bin 대신 $PREFIX/bin 사용 권장되나, 
    # 여기서는 단순화를 위해 바이너리만 추출하여 PATH에 추가하거나 
    # 기존 방식대로 설치 시도 (Termux 환경에 맞춰 바이너리 위치 조정 필요할 수 있음)
    # 일단은 바이너리 추출 후 $HOME/bin 등에 배치하는 것이 안전함
    mkdir -p "$HOME/bin"
    cp "$tmpdir/ghq_linux_${arch}/ghq" "$HOME/bin/ghq"
    chmod +x "$HOME/bin/ghq"
    append_once 'export PATH="$HOME/bin:$PATH"' "$HOME/.profile"
    append_once 'export PATH="$HOME/go/bin:$PATH"' "$HOME/.config/fish/config.fish"
    rm -f "$tmp"
    rm -rf "$tmpdir"
  fi

  install_starship
  configure_starship
  install_zellij
  configure_zellij
  configure_fish
  configure_git
  configure_shell_aliases "$HOME/.profile"
  install_lazyvim
  configure_nvim
  install_termux_font_notice

  log INFO "Termux bootstrap complete"
}

main "$@"
