function _tide_pwd
    # Colors
    set_color -o $tide_pwd_color_anchors | read -l color_anchors
    set_color $tide_pwd_color_truncated_dirs | read -l color_truncated
    set -l reset_to_color_dirs (set_color normal -b $tide_pwd_bg_color; set_color $tide_pwd_color_dirs)

    # Icons
    set -l unwritable_icon $tide_pwd_icon_unwritable' '
    set -l home_icon $tide_pwd_icon_home' '
    set -l pwd_icon $tide_pwd_icon' '

    # Truncate symbol
    set -l trunc '…'

    # Current path
    set -l path $PWD

    # Root
    if test "$path" != /
        # Git parent => …
        set -l git_root (command git rev-parse --show-toplevel 2>/dev/null)

        if test -n "$git_root"
            set path (string replace -r "^"(dirname "$git_root") "$trunc" "$path")
        else
            # Home => ~
            set path (string replace -r "^$HOME" "~" "$path")
        end

        # Keep last 3 dirs when depth >= 4
        set -l parts (string split "/" "$path" | string match -rv '^$')

        if test (count $parts) -ge 4
            if test "$parts[1]" = "~" -o "$parts[1]" = "$trunc"
                set path "$parts[1]/"(string join "/" $parts[-3..-1])
            else
                set path "$trunc/"(string join "/" $parts[-3..-1])
            end
        end
    end

    # Render
    if set -l split_pwd (string split / -- $path)

        test -w . \
            && set -f split_output "$pwd_icon$split_pwd[1]" $split_pwd[2..] \
            || set -f split_output "$unwritable_icon$split_pwd[1]" $split_pwd[2..]

        set split_output[-1] "$color_anchors$split_output[-1]$reset_to_color_dirs"

    else
        set -f split_output "$home_icon$color_anchors~"
    end

    # Width for Tide
    string join / -- $split_output | string length -V | read -g _tide_pwd_len

    # Output
    string join -- / "$reset_to_color_dirs$split_output[1]" $split_output[2..]
end