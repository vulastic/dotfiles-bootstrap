# dotfile-bootstrap

Cross-platform bootstrap project for quickly setting up terminal environments on Linux, Windows, and Termux.

This project installs shells, themes, configs, and developer tools with automatic detection and guided setup.

---

# Features

- Linux / Windows / Termux support
- Auto detect:
  - OS
  - Linux distro
  - Package manager
  - Current shell
- Linux install profiles:
  - Minimal
  - Full
- Shell support:
  - bash
  - zsh
  - fish
  - PowerShell
- Re-runnable installer
- Modular structure
- Easy theme customization

---

# Install

## Linux / Termux

    curl -fsSL https://raw.githubusercontent.com/vulastic/dotfiles-bootstrap/refs/heads/main/install.sh | bash

## Windows PowerShell

    irm https://raw.githubusercontent.com/vulastic/dotfiles-bootstrap/refs/heads/main/install.ps1 | iex

---

# Linux Install Flow

Installer detects your environment automatically.

Example:

    Detected OS      : Linux
    Detected Distro  : Ubuntu
    Package Manager  : apt
    Detected Shell   : zsh

Then asks:

    Choose Profile:
    1) Minimal
    2) Full

Shell setup:

    1) Use detected shell (zsh)
    2) bash
    3) zsh
    4) fish

---

# Profiles

## Minimal

Fast lightweight setup.

Includes:

- git
- curl
- wget
- tmux
- fzf
- ripgrep

## Full

Developer workstation setup.

Includes Minimal plus:

- build tools
- neovim
- python
- nodejs
- fd
- btop
- extra utilities

---

# Project Structure

    dotfile-bootstrap/
    ├── README.md
    ├── LICENSE
    │
    ├── install.sh
    ├── install.ps1
    │
    ├── install/
    │   ├── common.sh
    │   ├── linux.sh
    │   ├── linux-minimal.sh
    │   ├── linux-full.sh
    │   ├── termux.sh
    │   └── windows.ps1
    │
    ├── shell/
    │   ├── bash/
    │   │   ├── bashrc
    │   │   └── themes/
    │   │
    │   ├── zsh/
    │   │   ├── zshrc
    │   │   └── themes/
    │   │
    │   ├── fish/
    │   │   ├── config.fish
    │   │   ├── functions/
    │   │   ├── themes/
    │   │   └── completions/
    │   │
    │   └── powershell/
    │       ├── Microsoft.PowerShell_profile.ps1
    │       └── themes/
    │
    ├── config/
    │   ├── git/
    │   ├── tmux/
    │   ├── nvim/
    │   ├── starship/
    │   ├── btop/
    │   └── other-apps/
    │
    ├── assets/
    │   ├── fonts/
    │   └── screenshots/
    │
    └── backup/

---

# Theme Structure

Themes are separated by purpose.

## Shell Themes

Shell prompt themes belong inside shell folders.

Examples:

    shell/bash/themes/
    shell/zsh/themes/
    shell/fish/themes/
    shell/powershell/themes/

## App Themes

Application themes belong inside config folders.

Examples:

    config/tmux/
    config/nvim/
    config/btop/
    config/starship/

---

# Shell Notes

## bash

Uses:

    ~/.bashrc

Theme loaded with:

    source ~/.dotfiles/shell/bash/themes/tokyo-night.sh

## zsh

Uses:

    ~/.zshrc

## fish

Uses structured config:

    ~/.config/fish/

Includes:

- config.fish
- functions/
- themes/
- completions/

## PowerShell

Uses:

    Microsoft.PowerShell_profile.ps1

---

# Design Philosophy

Keep it simple.

Main folders:

- install/
- shell/
- config/
- assets/

Easy to extend later without clutter.

---

# Future Ideas

- WSL detection
- macOS support
- Interactive installer UI
- Theme selector
- Backup restore
- Desktop environment setup

---

# License

MIT