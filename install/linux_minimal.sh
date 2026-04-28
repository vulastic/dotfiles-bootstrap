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

# Neovim 최신 버전 설치 (PPA 사용)
install_neovim() {
  log INFO "Installing latest Neovim via PPA..."
  # add-apt-repository 명령어를 위해 software-properties-common 설치
  sudo apt-get install -y software-properties-common
  
  # 최신 버전을 위해 unstable PPA 추가 (LazyVim 요구사항 충족)
  sudo add-apt-repository -y ppa:neovim-ppa/unstable
  sudo apt-get update
  sudo apt-get install -y neovim
  log INFO "Neovim installed via PPA"
}

# Fish 쉘 최신 버전 설치 (PPA 사용)
install_fish() {
  log INFO "Installing latest Fish via PPA..."
  sudo apt-get install -y software-properties-common
  sudo add-apt-repository -y ppa:fish-shell/release-3
  sudo apt-get update
  sudo apt-get install -y fish
  log INFO "Fish installed via PPA"
}

# fzf 최신 버전 설치 (GitHub 직접 설치)
install_fzf() {
  log INFO "Installing/Updating latest fzf from GitHub..."
  local tmp=$(mktemp -d)
  # 최신 버전 태그 가져오기
  local ver=$(curl -fsSL https://api.github.com/repos/junegunn/fzf/releases/latest | grep '"tag_name"' | sed 's/.*"v\([^"]*\)".*/\1/')
  
  if [ -z "$ver" ]; then
    log ERROR "Failed to fetch latest fzf version"
    return 1
  fi

  log INFO "Latest fzf version found: v$ver"
  
  # 아키텍처 확인 (amd64 기준, 필요시 확장 가능)
  local arch="linux_amd64"
  if uname -m | grep -q "aarch64"; then
    arch="linux_arm64"
  fi

  curl -fsSL "https://github.com/junegunn/fzf/releases/download/v${ver}/fzf-${ver}-${arch}.tar.gz" -o "$tmp/fzf.tar.gz"
  tar -xzf "$tmp/fzf.tar.gz" -C "$tmp"
  # 와일드카드 확장 문제를 피하기 위해 find를 사용하여 바이너리 경로를 찾습니다.
  local fzf_bin=$(find "$tmp" -name fzf -type f | head -n 1)
  if [ -n "$fzf_bin" ]; then
    sudo install "$fzf_bin" /usr/local/bin/fzf
  else
    log ERROR "Could not find fzf binary in extracted files"
    rm -rf "$tmp"
    return 1
  fi
  rm -rf "$tmp"
  log INFO "fzf v$ver installed/updated"
}

# zoxide 설치
install_zoxide() {
  if ! command -v zoxide >/dev/null 2>&1; then
    log INFO "Installing zoxide..."
    sudo apt-get install -y zoxide || curl -fsSL https://raw.githubusercontent.com/ajeetdsouza/zoxide/main/install.sh | bash
  else
    log INFO "zoxide already installed"
  fi
}

# 기본 쉘 설정 (fish)
configure_default_shell() {
  log INFO "Setting fish as default shell..."
  if command -v fish >/dev/null 2>&1; then
    sudo chsh -s "$(which fish)" "$USER" || log WARN "Failed to change default shell automatically. Please run 'chsh -s $(which fish)' manually."
  fi
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
  sudo install -Dm755 "$tmpdir/ghq_linux_${arch}/ghq" /usr/local/bin/ghq
  rm -f "$tmp"
  rm -rf "$tmpdir"
}

install_yazi() {
  command -v yazi >/dev/null 2>&1 && { log INFO "yazi already installed"; return; }
  log INFO "Installing yazi..."
  local arch=$(dpkg --print-architecture)
  local arch_name=""
  case $arch in
    amd64) arch_name="x86_64-unknown-linux-musl" ;;
    arm64) arch_name="aarch64-unknown-linux-musl" ;;
    *) log ERROR "Unsupported architecture: $arch. Skipping yazi installation."; return ;;
  esac

  local ver=$(curl -fsSL https://api.github.com/repos/sxyazi/yazi/releases/latest | grep '"tag_name"' | sed 's/.*"v\([^"]*\)".*/\1/')
  local tmp=$(mktemp)
  local tmpdir=$(mktemp -d)
  
  curl -fsSL -o "$tmp" "https://github.com/sxyazi/yazi/releases/download/v${ver}/yazi-${arch_name}.tar.gz"
  tar -xzf "$tmp" -C "$tmpdir"
  
  sudo install -Dm755 "$tmpdir/yazi" /usr/local/bin/yazi
  sudo install -Dm755 "$tmpdir/yaazi" /usr/local/bin/yaazi 2>/dev/null || true
  
  rm -f "$tmp"
  rm -rf "$tmpdir"
  log INFO "yazi v$ver installed"
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

main() {
  require_cmd sudo; require_cmd curl; require_cmd git

  log INFO "Installing Ubuntu shell stack"
  
  # 1. 설치 단계 (Installation Phase)
  apt_install gh jq unzip ripgrep fd-find bat git gnupg p7zip-full build-essential ffmpegthumbnailer poppler-utils imagemagick
  install_fish
  install_fisher
  install_fzf
  install_neovim
  install_eza
  install_zoxide
  install_ghq
  install_yazi
  install_starship
  install_zellij
  install_lazyvim
  install_fonts

  # 2. 설정 단계 (Configuration Phase)
  log INFO "Starting configuration phase..."
  configure_starship
  configure_fish
  configure_zellij
  configure_git
  configure_shell_aliases "$HOME/.bashrc"
  configure_default_shell
  configure_nvim

  log INFO "Ubuntu bootstrap complete"
}

main "$@"
