# ==========================================
# Tokyo Night Zsh Prompt (Final Stable)
# ==========================================

# --------------------------
# Colors (Zsh format)
# --------------------------
TN_BLUE='%F{#7aa2f7}'
TN_CYAN='%F{#7dcfff}'
TN_GREEN='%F{#9ece6a}'
TN_RED='%F{#f7768e}'
TN_PURPLE='%F{#bb9af7}'
TN_GRAY='%F{#565f89}'
TN_WHITE='%F{#a9aff6}'
TN_RESET='%f'

TN_ARROW="›"

# ==========================================
# OS DETECT (Cached)
# ==========================================
if [[ -z "$TN_OS" ]]; then
    case "$(uname -s 2>/dev/null)" in
        MINGW*|MSYS*|CYGWIN*) TN_OS="󰍲 " ;;
        Darwin*) TN_OS="󰀷 " ;;
        *)
            if [[ -r /etc/os-release ]]; then
                local os_id=$(command grep -w "^ID" /etc/os-release | command cut -d= -f2 | tr -d '"')
                case "$os_id" in
                    ubuntu)        TN_OS=" " ;;
                    debian)        TN_OS=" " ;;
                    arch)          TN_OS=" " ;;
                    manjaro)       TN_OS=" " ;;
                    fedora)        TN_OS=" " ;;
                    centos)        TN_OS=" " ;;
                    alpine)        TN_OS=" " ;;
                    gentoo)        TN_OS=" " ;;
                    nixos)         TN_OS=" " ;;
                    opensuse*|suse) TN_OS=" " ;;
                    pop)           TN_OS=" " ;;
                    raspbian)      TN_OS=" " ;;
                    kali)          TN_OS=" " ;;
                    mint|linuxmint) TN_OS=" " ;;
                    rocky)         TN_OS=" " ;;
                    almalinux)     TN_OS=" " ;;
                    void)          TN_OS=" " ;;
                    redhat|rhel)   TN_OS="󱄛 " ;;
                    *)             TN_OS=" " ;;
                esac
            else
                TN_OS=" "
            fi
        ;;
    esac
fi

# ==========================================
# UTILS
# ==========================================
__tn_path() {
    local p="${(%):-%~}"
    [[ "$p" == "/" ]] && { echo "/"; return }
    local arr=(${(s:/:)p})
    [[ ${#arr} -gt 3 ]] && echo "…/${arr[-3]}/${arr[-2]}/${arr[-1]}" || echo "$p"
}

__tn_git() {
    command git rev-parse --is-inside-work-tree >/dev/null 2>&1 || return
    local branch=$(command git branch --show-current 2>/dev/null)
    # 아이콘 뒤에 공백 하나를 포함하여 반환 (렌더링 안정성)
    [[ -n "$branch" ]] && echo " $branch"
}

# ==========================================
# PROMPT ENGINE
# ==========================================
__tn_prompt_precmd() {
    local exit_status=$?
    RPROMPT="" 

    # 1. 정보 수집
    local git_info=$(__tn_git)
    local path_str=$(__tn_path)
    local time_str=$(date "+%H:%M:%S")

    # 2. 왼쪽 파트 조립
    local left_part="${TN_CYAN}${TN_OS} ${TN_PURPLE}%n ${TN_WHITE}at ${TN_BLUE}%m ${TN_WHITE}in ${TN_CYAN}${path_str}"
    [[ -n "$git_info" ]] && left_part+=" ${TN_WHITE}on ${TN_PURPLE}${git_info}"
    left_part+="${TN_RESET}"

    # 3. [핵심] 너비 계산 (1칸 오차 해결)
    # %n, %m 등을 실제 텍스트로 변환
    local expanded_left="${(%):-${TN_OS} %n at %m in ${path_str}}"
    [[ -n "$git_info" ]] && expanded_left+=" on${git_info}"
    
    # [수정 포인트] Nerd Font 아이콘을 2글자 너비의 더미 문자로 치환하여 길이를 잽니다.
    # 이렇게 하면 폰트 렌더링 시 발생하는 1칸 오차를 원천적으로 차단합니다.
    local virtual_left=$(echo -n "$expanded_left" | sed 's//XX/g; s//XX/g; s//XX/g; s//XX/g; s//XX/g; s//XX/g; s//XX/g; s//XX/g; s//XX/g; s//XX/g; s//XX/g; s//XX/g; s//XX/g; s//XX/g; s//XX/g; s//XX/g; s//XX/g; s/󱄛/XX/g; s//XX/g')
    
    # Zsh 자체 문자열 길이 계산 (가상 너비 기준)
    local left_len=${#virtual_left}
    
    # 전체 너비 - (가상 왼쪽 너비) - (시계 너비)
    local fill=$(( COLUMNS - left_len - ${#time_str} ))
    
    # Iosevka 폰트 특성상 공백 한 칸이 더 필요할 수 있음 (미세 조정용)
    # 만약 시계가 1칸 왼쪽으로 치우치면 아래 숫자를 0으로, 
    # 오른쪽으로 삐져나가면 2로 조절하세요.
    local fine_tune=1 
    fill=$(( fill + fine_tune ))

    [[ $fill -lt 1 ]] && fill=1
    local spacing=$(printf '%*s' $fill "")

    # 4. 최종 출력
    PROMPT="${left_part}${spacing}${TN_GRAY}${time_str}${TN_RESET}
"
    if [[ $exit_status -eq 0 ]]; then
        PROMPT+="${TN_GREEN}${TN_ARROW} ${TN_RESET}"
    else
        PROMPT+="${TN_RED}${TN_ARROW} ${TN_RESET}"
    fi
}

autoload -Uz add-zsh-hook
add-zsh-hook precmd __tn_prompt_precmd