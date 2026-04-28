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
  if [ -f "$target" ] || [ -L "$target" ]; then
    cp -f "$target" "$target.bak" || log ERROR "Failed to backup $target"
  fi
}
copy_config() {
  local source="$1" target="$2"
  ensure_dir "$(dirname "$target")"
  backup_file "$target"
  cp -f "$source" "$target" || { log ERROR "Failed to copy $source to $target"; return 1; }
}

# Fisher 설치 함수 (도구 설치 단계로 이동)
install_fisher() {
  log INFO "Installing fisher..."
  ensure_dir "$HOME/.config/fish/functions"
  if ! fish -c 'functions -q fisher' >/dev/null 2>&1; then
    curl -fsSL https://raw.githubusercontent.com/jorgebucaran/fisher/main/functions/fisher.fish -o "$HOME/.config/fish/functions/fisher.fish"
    fish -c "source '$HOME/.config/fish/functions/fisher.fish'; fisher install jorgebucaran/fisher"
  else
    log INFO "Fisher already installed."
  fi
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
  
  local arch=$(uname -m)
  local arch_name=""
  case $arch in
    x86_64) arch_name="x86_64-unknown-linux-musl" ;;
    aarch64) arch_name="aarch64-unknown-linux-musl" ;;
    *) log ERROR "Unsupported architecture: $arch. Skipping Zellij installation."; return ;;
  esac

  local ver=$(curl -fsSL https://api.github.com/repos/zellij-org/zellij/releases/latest | grep '"tag_name"' | sed 's/.*"v\([^"]*\)".*/\1/')
  local tmp=$(mktemp)
  local tmpdir=$(mktemp -d)
  
  curl -fsSL -o "$tmp" "https://github.com/zellij-org/zellij/releases/download/v${ver}/zellij-${arch_name}.tar.gz"
  tar -xzf "$tmp" -C "$tmpdir"
  
  if [ -n "${PREFIX:-}" ]; then
    # Termux environment
    mkdir -p "$HOME/bin"
    cp "$tmpdir/zellij" "$HOME/bin/zellij"
    chmod +x "$HOME/bin/zellij"
    append_once 'export PATH="$HOME/bin:$PATH"' "$HOME/.profile"
    append_once 'export PATH="$HOME/bin:$PATH"' "$HOME/.config/fish/config.fish"
  else
    # Linux environment
    sudo install -Dm755 "$tmpdir/zellij" /usr/local/bin/zellij
  fi
  
  rm -f "$tmp"
  rm -rf "$tmpdir"
}
configure_zellij() {
  log INFO "Configuring Zellij..."
  local dir="${XDG_CONFIG_HOME:-$HOME/.config}/zellij"
  local target="$dir/config.kdl"
  
  # OS별 default_shell 결정
  local shell_val="pwsh.exe"
  if [[ "$OSTYPE" == "linux-gnu"* ]]; then
    shell_val="fish"
  elif [[ "$OSTYPE" == "darwin"* ]]; then
    shell_val="zsh"
  fi

  if [ -f "$target" ]; then
    log INFO "Zellij config already exists. Updating default_shell..."
    # 기존 파일에서 default_shell 라인을 찾아 교체하거나, 없으면 추가 (단순화를 위해 sed 사용)
    if grep -q 'default_shell' "$target"; then
      sed -i "s/default_shell \".*\"/default_shell \"$shell_val\"/" "$target"
    else
      # 파일 끝에 추가하는 것은 위험할 수 있으므로, 여기서는 파일을 새로 복사한 후 sed를 적용하는 방식이 안전함
      ensure_dir "$dir"
      copy_config "$CONFIG_DIR/zellij/config.kdl" "$target"
      sed -i "s/default_shell \".*\"/default_shell \"$shell_val\"/" "$target"
    fi
    return
  fi

  ensure_dir "$dir"
  copy_config "$CONFIG_DIR/zellij/config.kdl" "$target"
  # 복사 후 shell 값 교체
  sed -i "s/default_shell \".*\"/default_shell \"$shell_val\"/" "$target"
}

# Neovim (LazyVim) 설치 및 설정
install_lazyvim() {
  local home="${XDG_CONFIG_HOME:-$HOME/.config}"
  if [ -d "$home/nvim" ]; then
    log INFO "Neovim config exists, skipping bootstrap"
    return
  fi
  
  log INFO "Installing LazyVim..."
  git clone https://github.com/LazyVim/starter "$home/nvim"
  rm -rf "$home/nvim/.git" "$home/nvim/lua/plugins/example.lua"
  ensure_dir "${XDG_DATA_HOME:-$HOME/.local/share}" "${XDG_STATE_HOME:-$HOME/.local/state}" "${XDG_CACHE_HOME:-$HOME/.cache}"
}
configure_nvim() {
  log INFO "Configuring Neovim..."
  local home="${XDG_CONFIG_HOME:-$HOME/.config}"
  [ ! -d "$home/nvim" ] && return
  local target="$home/nvim/lua/plugins/theme.lua"
  if [ -f "$target" ]; then
    log INFO "Neovim theme config already exists. Skipping..."
    return
  fi
  ensure_dir "$home/nvim/lua/plugins"
  copy_config "$CONFIG_DIR/nvim/lua/plugins/theme.lua" "$target"
}

# 기타 도구 설정
configure_git() { 
  log INFO "Configuring Git..."
  if [ -f "$HOME/.gitconfig" ]; then
    log INFO "Git config already exists. Skipping..."
    return
  fi
  copy_config "$CONFIG_DIR/git/gitconfig" "$HOME/.gitconfig" 
}
configure_starship() {
  log INFO "Configuring Starship..."
  local target="${XDG_CONFIG_HOME:-$HOME/.config}/starship/starship.toml"
  ensure_dir "$(dirname "$target")"
  # Always copy to ensure the bootstrap configuration is applied
  copy_config "$CONFIG_DIR/starship/starship.toml" "$target"
}
install_starship() {
  command -v starship >/dev/null 2>&1 && { log INFO "Starship already installed"; return; }
  log INFO "Installing Starship..."
  curl -sS https://starship.rs/install.sh | sh -s -- -y
}
configure_shell_aliases() {
  log INFO "Configuring shell aliases..."
  local rc="$1"
  append_once '[ -f "$HOME/.config/shell/aliases.sh" ] && . "$HOME/.config/shell/aliases.sh"' "$rc"
  local target="$HOME/.config/shell/aliases.sh"
  if [ -f "$target" ]; then
    log INFO "Shell aliases already configured. Skipping..."
    return
  fi
  ensure_dir "$(dirname "$target")"
  copy_config "$CONFIG_DIR/shell/aliases.sh" "$target"
}

configure_fish() {
  local dir="${XDG_CONFIG_HOME:-$HOME/.config}/fish"
  local target="$dir/config.fish"
  
  if [ ! -f "$target" ]; then
    log INFO "Configuring fish..."
    ensure_dir "$dir/functions"
    copy_config "$CONFIG_DIR/fish/config.fish" "$target"
  else
    log INFO "Fish config already exists. Skipping..."
  fi
  
  # Fisher 설치 확인 및 설치
  if ! fish -c 'functions -q fisher' >/dev/null 2>&1; then
    log INFO "Installing fisher..."
    curl -fsSL https://raw.githubusercontent.com/jorgebucaran/fisher/main/functions/fisher.fish -o "$dir/functions/fisher.fish"
    fish -c "source '$dir/functions/fisher.fish'; fisher install jorgebucaran/autopair.fish PatrickF1/fzf.fish"
  else
    log INFO "Fisher already installed. Checking plugins..."
    # 플러그인이 이미 설치되어 있는지 확인하며 설치 시도 (fisher 자체의 멱등성 활용)
    fish -c "fisher install jorgebucaran/autopair.fish PatrickF1/fzf.fish"
  fi
}

configure_fonts_notice() {
  log INFO "Please install fonts manually: IosevkaTerm Nerd Font, Sarasa Mono K"
}
