#!/usr/bin/env bash

set -euo pipefail

# 경로 설정
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CONFIG_DIR="$ROOT_DIR/config"

# 로그 출력 함수
log() {
  printf '\n[%s] %s\n' "$1" "$2"
}

# 디렉토리 생성 및 파일 백업/복사 유틸리티
ensure_dir() { mkdir -p "$@"; }
backup_file() {
  local target="$1"
  [ -f "$target" ] || [ -L "$target" ] && cp -f "$target" "$target.bak"
}
copy_config() {
  local source="$1" target="$2"
  ensure_dir "$(dirname "$target")"
  backup_file "$target"
  cp -f "$source" "$target"
}

# 파일에 중복 없이 라인 추가
append_once() {
  local line="$1" file="$2"
  ensure_dir "$(dirname "$file")"
  touch "$file"
  grep -Fq "$line" "$file" || printf '%s\n' "$line" >> "$file"
}

# Zellij 설치 및 설정
install_zellij() {
  command -v zellij >/dev/null 2>&1 && { log INFO "Zellij already installed"; return; }
  log INFO "Installing Zellij..."
  curl -sS https://zellij.org/install.sh | bash
}
configure_zellij() {
  local dir="${XDG_CONFIG_HOME:-$HOME/.config}/zellij"
  ensure_dir "$dir"
  copy_config "$CONFIG_DIR/zellij/config.kdl" "$dir/config.kdl"
}

# Neovim (LazyVim) 설치 및 설정
install_lazyvim() {
  local home="${XDG_CONFIG_HOME:-$HOME/.config}"
  [ -d "$home/nvim" ] && { log INFO "Neovim config exists, skipping bootstrap"; return; }
  
  git clone https://github.com/LazyVim/starter "$home/nvim"
  rm -rf "$home/nvim/.git" "$home/nvim/lua/plugins/example.lua"
  ensure_dir "${XDG_DATA_HOME:-$HOME/.local/share}" "${XDG_STATE_HOME:-$HOME/.local/state}" "${XDG_CACHE_HOME:-$HOME/.cache}"
}
configure_nvim() {
  local home="${XDG_CONFIG_HOME:-$HOME/.config}"
  [ ! -d "$home/nvim" ] && return
  ensure_dir "$home/nvim/lua/plugins"
  copy_config "$CONFIG_DIR/nvim/lua/plugins/theme.lua" "$home/nvim/lua/plugins/theme.lua"
}

# 기타 도구 설정
configure_git() { copy_config "$CONFIG_DIR/git/gitconfig" "$HOME/.gitconfig"; }
configure_starship() {
  ensure_dir "${XDG_CONFIG_HOME:-$HOME/.config}"
  copy_config "$CONFIG_DIR/starship/starship.toml" "${XDG_CONFIG_HOME:-$HOME/.config}/starship.toml"
}
install_starship() {
  command -v starship >/dev/null 2>&1 && { log INFO "Starship already installed"; return; }
  log INFO "Installing Starship..."
  curl -sS https://starship.rs/install.sh | sh -s -- -y
}
configure_shell_aliases() {
  local rc="$1"
  append_once '[ -f "$HOME/.config/shell/aliases.sh" ] && . "$HOME/.config/shell/aliases.sh"' "$rc"
  ensure_dir "$HOME/.config/shell"
  copy_config "$CONFIG_DIR/shell/aliases.sh" "$HOME/.config/shell/aliases.sh"
}
configure_fonts_notice() {
  log INFO "Please install fonts manually: IosevkaTerm Nerd Font, Sarasa Mono K"
}
