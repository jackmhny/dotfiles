# quickfix: Alt+O turns the current buffer into an editable command.

_quickfix_alt_o() {
    local original=$READLINE_LINE generated error_file status message

    [[ $original =~ [^[:space:]] ]] || return
    error_file=$(mktemp -t quickfix.XXXXXX) || return

    generated=$(QUICKFIX_SHELL=bash quickfix "$original" 2>"$error_file")
    status=$?

    if ((status == 0)) && [[ -n $generated ]]; then
        READLINE_LINE=$generated
        READLINE_POINT=${#READLINE_LINE}
    else
        message=$(tail -n 1 -- "$error_file")
        printf '\n%s\n' "${message:-quickfix failed}" >&2
    fi

    rm -f -- "$error_file"
}

bind -m emacs-standard -x '"\eo":_quickfix_alt_o'
bind -m vi-insert -x '"\eo":_quickfix_alt_o'
