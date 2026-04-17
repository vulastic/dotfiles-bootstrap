#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=install/common.sh
source "$SCRIPT_DIR/common.sh"

pkg_install() {
  pkg update -y
  pkg install -y "$@"
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
  fish -c 'set -U tide_color_time 565f89'
}

install_termux_font_notice() {
  if command -v fc-list >/dev/null 2>&1 && fc-list | grep -iq "Sarasa Mono K"; then
    log INFO "Sarasa Mono K already available"
  elif command -v fc-list >/dev/null 2>&1 && fc-list | grep -iq "Iosevka"; then
    log INFO "Iosevka already available"
  else
    log INFO "Set Sarasa Mono K or Iosevka Nerd Font Mono in the terminal app profile manually"
  fi
}

main() {
  pkg_install fish tmux neovim fzf git gh curl unzip tar ripgrep fd bat eza

  if ! command -v zoxide >/dev/null 2>&1; then
    curl -fsSL https://raw.githubusercontent.com/ajeetdsouza/zoxide/main/install.sh | bash
  fi

  if ! command -v ghq >/dev/null 2>&1; then
    pkg install -y golang
    GO111MODULE=on go install github.com/x-motemen/ghq@latest
    append_once 'export PATH="$HOME/go/bin:$PATH"' "$HOME/.profile"
    append_once 'export PATH="$HOME/go/bin:$PATH"' "$HOME/.config/fish/config.fish"
    export PATH="$HOME/go/bin:$PATH"
  fi

  install_starship
  install_fisher
  configure_starship
  configure_fish
  configure_tmux
  configure_git
  configure_shell_aliases "$HOME/.profile"
  install_lazyvim
  configure_nvim
  install_termux_font_notice

  log INFO "Termux bootstrap complete"
}

main "$@"
