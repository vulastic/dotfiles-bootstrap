# ==========================================================
# Tide Lean + Tokyo Night (Production Grade)
# Starship Full Migration Mapping
# ==========================================================

# ----------------------------------------------------------
# Layout (Starship → Tide)
# ----------------------------------------------------------
set -U tide_left_prompt_items os _username_ _at_host_ _hostname_ _in_pwd_ pwd _on_git_ git newline character
set -U tide_right_prompt_items jobs nix_shell docker kubectl direnv node python rustc status cmd_duration time


# ----------------------------------------------------------
# Lean Mode
# ----------------------------------------------------------
set -U tide_prompt_min_cols 60
set -U tide_prompt_pad_items false
set -U tide_prompt_icon_connection ' '
set -U tide_left_prompt_frame_enabled false
set -U tide_right_prompt_frame_enabled false


# ----------------------------------------------------------
# Separators
# ----------------------------------------------------------
set -U tide_prompt_separator_same_color 414868


# ----------------------------------------------------------
# Prompt Character
# ----------------------------------------------------------
set -U tide_character_icon '›'
set -U tide_character_color bb9af7
set -U tide_character_color_failure f7768e


# ==========================================================
# LEFT SIDE
# ==========================================================

# OS Detect and set icon accordingly
set -l os_id (grep -w "ID" /etc/os-release | cut -d= -f2 | tr -d '"')
switch (string lower $os_id)
    case alpine
        set -U tide_os_icon ' '
    case arch
        set -U tide_os_icon ' '
    case centos
        set -U tide_os_icon ' '
    case debian
        set -U tide_os_icon ' '
    case devuan
        set -U tide_os_icon ' '
    case elementary
        set -U tide_os_icon ' '
    case fedora
        set -U tide_os_icon ' '
    case gentoo
        set -U tide_os_icon ' '
    case mageia
        set -U tide_os_icon ' '
    case manjaro
        set -U tide_os_icon ' '
    case mint linuxmint
        set -U tide_os_icon ' '
    case nixos
        set -U tide_os_icon ' '
    case opensuse-leap opensuse-tumbleweed opensuse-microos
        set -U tide_os_icon ' '
    case raspbian
        set -U tide_os_icon ' '
    case rhel
        set -U tide_os_icon ' '
    case sabayon
        set -U tide_os_icon ' '
    case slackware
        set -U tide_os_icon ' '
    case ubuntu
        set -U tide_os_icon ' '
    case void
        set -U tide_os_icon ' '
    case '*'
        set -U tide_os_icon ' '
end

# OS -> CYAN
set -U tide_os_color 7dcfff

# Username -> MAGENTA / Hostname -> BLUE / others -> WHITE
set -U tide__username__color bb9af7
set -U tide__at_host__color a9b1d6
set -U tide__hostname__color 7aa2f7

# Context (user@host) → MAGENTA
# set -U tide_context_always_display true
# set -U tide_context_hostname_parts 0
# set -U tide_context_color_default bb9af7
# set -U tide_context_color_ssh ff9e64
# set -U tide_context_color_root f7768e

# PWD → CYAN
set -U tide__in_pwd__color a9b1d6
set -U tide_pwd_color_anchors 7aa2f7
set -U tide_pwd_color_dirs 7dcfff
set -U tide_pwd_color_truncated_dirs 565f89

# Git → MAGENTA base
set -U tide__on_git__color a9b1d6
set -U tide_git_icon ''
set -U tide_git_color_branch bb9af7
set -U tide_git_color_conflicted f7768e
set -U tide_git_color_dirty f7768e
set -U tide_git_color_operation 565f89
set -U tide_git_color_staged 9ece6a
set -U tide_git_color_stash 9ece6a
set -U tide_git_color_untracked ff9e64
set -U tide_git_color_upstream 9ece6a


# ==========================================================
# RIGHT SIDE
# ==========================================================

# Jobs → YELLOW
set -U tide_jobs_color e0af68
set -U tide_jobs_number_threshold 2

# Nix Shell → CYAN
set -U tide_nix_shell_color 7dcfff

# Docker → CYAN (runtime infra)
set -U tide_docker_color 7dcfff

# Kubernetes → CYAN (orchestration layer)
set -U tide_kubectl_color 7dcfff

# Direnv → SOFT GRAY (silent helper)
set -U tide_direnv_color 565f89

# Node → GREEN
set -U tide_node_color 9ece6a

# Python → YELLOW
set -U tide_python_color e0af68

# Rust → ORANGE
set -U tide_rustc_color ff9e64

# Status → RED / GREEN
set -U tide_status_icon ''
set -U tide_status_icon_failure ''
set -U tide_status_color 9ece6a
set -U tide_status_color_failure f7768e

# Command Duration → ORANGE (subtle emphasis)
set -U tide_cmd_duration_color ff9e64

# Time → SOFT GRAY
set -U tide_time_color 565f89
set -U tide_time_format '%H:%M:%S '

# ==========================================================
# CLEAN UX TUNING
# ==========================================================

set -U tide_pwd_truncate_margin 3
set -U tide_git_truncation_length 24
