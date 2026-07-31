# quickfix: Alt+O turns the current buffer into an editable command.

_quickfix_alt_o() {
    local original=$READLINE_LINE generated output_file error_file status message pid
    local frame=0
    local -a frames=('⠋' '⠙' '⠹' '⠸' '⠼' '⠴' '⠦' '⠧' '⠇' '⠏')

    [[ $original =~ [^[:space:]] ]] || return
    output_file=$(mktemp -t quickfix-out.XXXXXX) || return
    error_file=$(mktemp -t quickfix-err.XXXXXX) || {
        rm -f -- "$output_file"
        return
    }

    printf '\n' >&2
    QUICKFIX_SHELL=bash quickfix "$original" >"$output_file" 2>"$error_file" &
    pid=$!

    while kill -0 "$pid" 2>/dev/null; do
        printf '\rquickfix %s' "${frames[$frame]}" >&2
        sleep 0.08
        frame=$(((frame + 1) % ${#frames[@]}))
    done

    if wait "$pid"; then
        status=0
    else
        status=$?
    fi
    printf '\r                    \r' >&2

    if ((status == 0)) && [[ -s $output_file ]]; then
        generated=$(<"$output_file")
        READLINE_LINE=$generated
        READLINE_POINT=${#READLINE_LINE}
    else
        message=$(tail -n 1 -- "$error_file")
        printf '%s\n' "${message:-quickfix failed}" >&2
    fi

    rm -f -- "$output_file" "$error_file"
}

bind -m emacs-standard -x '"\eo":_quickfix_alt_o'
bind -m vi-insert -x '"\eo":_quickfix_alt_o'
