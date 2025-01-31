#
# ZSH Configuration
#

# Basic ZSH Options
setopt autocd extendedglob

export CLICOLOR=1

eval "$(dircolors -b)"

# Completion System
fpath=(~/.zsh/completions ~/.zsh/zsh-completions/src $fpath)
autoload -Uz compinit && compinit

zstyle ':completion:*' completer _expand _complete _ignored
zstyle ':completion:*' matcher-list 'm:{[:lower:][:upper:]}={[:upper:][:lower:]}'
zstyle ':completion:*' list-colors ${(s.:.)LS_COLORS}
zstyle ':completion:*' menu select


# Vi Mode Configuration
set -o vi

autoload -Uz edit-command-line
zle -N edit-command-line

bindkey -M vicmd v edit-command-line

# Environment Variables
export EDITOR=nvim
export PATH=$PATH:/usr/local/go/bin:$HOME/go/bin

# Source External Configurations
eval "$(starship init zsh)"
. "$HOME/.local/bin/env"
. "$HOME/.cargo/env"
[[ -f ~/.env ]] && source ~/.env

# Aliases
alias ls='ls --color=auto'
alias ll='ls -alF'
alias la='ls -A'
alias l='ls -CF'
alias lh='ls -lh'
alias lt='ls -ltr'
alias lS='ls -lSr'

# Shell-GPT Integration
_sgpt_zsh() {
    if [[ -n "$BUFFER" ]]; then
        _sgpt_prev_cmd=$BUFFER
        BUFFER+=" ⌛"
        zle -I && zle redisplay
        BUFFER=$(sgpt --shell "$_sgpt_prev_cmd" --no-interaction)
        zle end-of-line
    fi
}
zle -N _sgpt_zsh
bindkey '^[l' _sgpt_zsh  # Alt+L to trigger shell-gpt suggestions

# Command Not Found Handler
if [[ -x /usr/lib/command-not-found ]]; then
    command_not_found_handler() {
        /usr/lib/command-not-found -- "$1"
        return $?
    }
fi

