# ==========================================
# Tokyo Night Bash Prompt (Ported from Zsh)
# ==========================================

# Colors (Bash format: \[ \] is required for correct line wrapping)
TN_BLUE='\[\e[38;2;122;162;247m\]'   # #7aa2f7
TN_CYAN='\[\e[38;2;125;207;255m\]'   # #7dcfff
TN_GREEN='\[\e[38;2;158;206;106m\]'  # #9ece6a
TN_RED='\[\e[38;2;247;118;142m\]'    # #f7768e
TN_GRAY='\[\e[38;2;86;95;137m\]'     # #565f89
TN_WHITE='\[\e[38;2;169;175;246m\]'  # #a9aff6
TN_RESET='\[\e[0m\]'
TN_ARROW="›"

# OS Detection
if [[ -z "$TN_OS" ]]; then
    case "$(uname -s 2>/dev/null)" in
        MINGW*|MSYS*|CYGWIN*) TN_OS="󰍲 " ;;
        Darwin*) TN_OS="󰀷 " ;;
        *)
            if [[ -r /etc/os-release ]]; then
                os_id=$(grep -w "^ID" /etc/os-release | cut -d= -f2 | tr -d '"')
                case "$os_id" in
                    ubuntu)  TN_OS=" " ;;
                    debian)  TN_OS=" " ;;
                    arch)    TN_OS=" " ;;
                    manjaro) TN_OS=" " ;;
                    fedora)  TN_OS=" " ;;
                    nixos)   TN_OS=" " ;;
                    *)       TN_OS=" " ;;
                esac
            else
                TN_OS=" "
            fi
        ;;
    esac
fi

# Path Shortener (Bash logic)
__tn_path() {
    local p="${PWD/#$HOME/~}"
    if [[ "$p" == "/" ]]; then
        echo "/"
    else
        # 슬래시 기준 분리 및 마지막 3개 추출
        IFS='/' read -ra ADDR <<< "$p"
        if [[ ${#ADDR[@]} -gt 3 ]]; then
            echo "…/${ADDR[-3]}/${ADDR[-2]}/${ADDR[-1]}"
        else
            echo "$p"
        fi
    fi
}

# Git Branch Info
__tn_git() {
    if git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
        local branch=$(git branch --show-current 2>/dev/null)
        [[ -n "$branch" ]] && echo " $branch"
    fi
}

# Prompt Engine
__tn_prompt_command() {
    local exit_status=$?
    local git_info=$(__tn_git)
    local path_str=$(__tn_path)
    local time_str=$(date "+%H:%M:%S")

    # 1. Left Part (Visible text only for length calculation)
    # Bash의 \u, \h 등 치환
    local user_host_path="${USER} at ${HOSTNAME} in ${path_str}"
    local plain_left="${TN_OS} ${user_host_path}"
    [[ -n "$git_info" ]] && plain_left+=" on${git_info}"

    # 2. Width Calculation (Virtual width with XX replacement)
    local virtual_left=$(echo -n "$plain_left" | sed 's/[󱄛]/XX/g')
    local left_len=${#virtual_left}
    
    # Right Alignment Logic
    local cols=$(tput cols)
    local fine_tune=1
    local fill=$(( cols - left_len - ${#time_str} + fine_tune ))
    
    [[ $fill -lt 1 ]] && fill=1
    local spacing=$(printf '%*s' $fill "")

    # 3. Assemble PS1
    local left_part="${TN_CYAN}${TN_OS} ${TN_PURPLE}${USER} ${TN_WHITE}at ${TN_BLUE}${HOSTNAME} ${TN_WHITE}in ${TN_CYAN}${path_str}"
    [[ -n "$git_info" ]] && left_part+=" ${TN_WHITE}on ${TN_PURPLE}${git_info}"
    
    # Second line arrow color
    local arrow_color="${TN_GREEN}"
    [[ $exit_status -ne 0 ]] && arrow_color="${TN_RED}"

    PS1="${left_part}${spacing}${TN_GRAY}${time_str}${TN_RESET}\n${arrow_color}${TN_ARROW} ${TN_RESET}"
}

# Register PROMPT_COMMAND
PROMPT_COMMAND=__tn_prompt_command