function _tide_item__on_git_
    if command git rev-parse --is-inside-work-tree >/dev/null 2>&1
        set_color $tide__on_git__color
        echo -ns $tide_right_prompt_separator_diff_color "on"
    end
end