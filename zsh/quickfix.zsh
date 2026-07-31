# quickfix: Alt+O turns the current buffer into an editable command.

_quickfix_alt_o() {
    local original=$BUFFER generated error_file status message

    [[ $original == *[^[:space:]]* ]] || return
    error_file=$(mktemp -t quickfix.XXXXXX) || return

    BUFFER="$original …"
    CURSOR=${#BUFFER}
    zle -I
    zle redisplay

    generated=$(QUICKFIX_SHELL=zsh quickfix "$original" 2>"$error_file")
    status=$?
    BUFFER=$original

    if (( status == 0 )) && [[ -n $generated ]]; then
        BUFFER=$generated
    else
        message=$(tail -n 1 -- "$error_file")
        zle -M "${message:-quickfix failed}"
    fi

    CURSOR=${#BUFFER}
    rm -f -- "$error_file"
    zle reset-prompt
}

zle -N _quickfix_alt_o
bindkey -M emacs '^[o' _quickfix_alt_o
bindkey -M viins '^[o' _quickfix_alt_o
