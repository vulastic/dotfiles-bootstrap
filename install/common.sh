#!/usr/bin/env bash

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CONFIG_DIR="$ROOT_DIR/config"
DESIGN_DIR="$ROOT_DIR/design/tokyo-night"

log() {
  printf '\n[%s] %s\n' "$1" "$2"
}

ensure_dir() {
  mkdir -p "$@"
}

backup_file() {
  local target="$1"
  if [ -f "$target" ] || [ -L "$target" ]; then
    cp -f "$target" "$target.bak"
  fi
}

copy_config() {
  local source="$1"
  local target="$2"
  ensure_dir "$(dirname "$target")"
  backup_file "$target"
  cp -f "$source" "$target"
}

append_once() {
  local line="$1"
  local file="$2"
  ensure_dir "$(dirname "$file")"
  touch "$file"
  if ! grep -Fq "$line" "$file"; then
    printf '%s\n' "$line" >> "$file"
  fi
}

install_starship() {
  if command -v starship >/dev/null 2>&1; then
    log INFO "starship already installed"
    return
  fi

  if command -v cargo >/dev/null 2>&1; then
    cargo install starship --locked
    return
  fi

  curl -fsSL https://starship.rs/install.sh | sh -s -- -y
}

install_lazyvim() {
  local config_home="${XDG_CONFIG_HOME:-$HOME/.config}"
  local data_home="${XDG_DATA_HOME:-$HOME/.local/share}"
  local state_home="${XDG_STATE_HOME:-$HOME/.local/state}"
  local cache_home="${XDG_CACHE_HOME:-$HOME/.cache}"

  if [ -d "$config_home/nvim" ]; then
    log INFO "nvim config already exists, skipping LazyVim bootstrap"
    return
  fi

  git clone https://github.com/LazyVim/starter "$config_home/nvim"
  rm -rf "$config_home/nvim/.git"
  rm -f "$config_home/nvim/lua/plugins/example.lua"
  ensure_dir "$data_home" "$state_home" "$cache_home"
}

configure_nvim() {
  local config_home="${XDG_CONFIG_HOME:-$HOME/.config}"
  if [ ! -d "$config_home/nvim" ]; then
    return
  fi

  ensure_dir "$config_home/nvim/lua/plugins"
  copy_config "$CONFIG_DIR/nvim/lua/plugins/theme.lua" "$config_home/nvim/lua/plugins/theme.lua"
}

configure_tmux() {
  copy_config "$CONFIG_DIR/tmux/tmux.conf" "$HOME/.tmux.conf"
}

configure_starship() {
  ensure_dir "${XDG_CONFIG_HOME:-$HOME/.config}"
  copy_config "$CONFIG_DIR/starship/starship.toml" "${XDG_CONFIG_HOME:-$HOME/.config}/starship.toml"
}

configure_git() {
  copy_config "$CONFIG_DIR/git/gitconfig" "$HOME/.gitconfig"
}

configure_shell_aliases() {
  local shell_rc="$1"
  append_once '[ -f "$HOME/.config/shell/aliases.sh" ] && . "$HOME/.config/shell/aliases.sh"' "$shell_rc"
  ensure_dir "$HOME/.config/shell"
  copy_config "$CONFIG_DIR/shell/aliases.sh" "$HOME/.config/shell/aliases.sh"
}

configure_fonts_notice() {
  log INFO "Install fonts manually if package manager support is unavailable: Sarasa Mono K, Iosevka Nerd Font Mono"
}
