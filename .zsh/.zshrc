#
# ZSH Configuration
#

# Basic ZSH Options
setopt autocd extendedglob

# History Configuration
HISTFILE=~/.zsh_history
HISTSIZE=10000
SAVEHIST=10000
setopt appendhistory
setopt INC_APPEND_HISTORY        # Write to the history file immediately, not when the shell exits
setopt SHARE_HISTORY            # Share history between all sessions
setopt HIST_EXPIRE_DUPS_FIRST    # Expire duplicate entries first when trimming history
setopt HIST_IGNORE_DUPS          # Don't record an entry that was just recorded again
setopt HIST_IGNORE_ALL_DUPS      # Delete old recorded entry if new entry is a duplicate
setopt HIST_FIND_NO_DUPS         # Do not display a line previously found
setopt HIST_SAVE_NO_DUPS         # Don't write duplicate entries in the history file
setopt HIST_REDUCE_BLANKS        # Remove superfluous blanks before recording entry

export CLICOLOR=1

eval "$(dircolors -b)"

# Completion System
# fpath=(~/.zsh/completions $fpath)
autoload -Uz compinit && compinit

# load compinit and rebind ^I (tab) to expand-or-complete, then compile
# completions as bytecode if needed.
lazyload-compinit() {
  autoload -Uz compinit
  # compinit will automatically cache completions to ~/.zcompdump
  compinit
  bindkey "^I" expand-or-complete
  {
    zcompdump="${ZDOTDIR:-$HOME}/.zcompdump"
    # if zcompdump file exists, and we don't have a compiled version or the
    # dump file is newer than the compiled file, update the bytecode.
    if [[ -s "$zcompdump" && (! -s "${zcompdump}.zwc" || "$zcompdump" -nt "${zcompdump}.zwc") ]]; then
      zcompile "$zcompdump"
    fi
  } &!
  # pretend we called this directly, instead of the lazy loader
  zle expand-or-complete
}
# mark the function as a zle widget
zle -N lazyload-compinit
bindkey "^I" lazyload-compinit


zstyle ':completion:*' completer _expand _complete _ignored
zstyle ':completion:*' matcher-list 'm:{[:lower:][:upper:]}={[:upper:][:lower:]}'
zstyle ':completion:*' list-colors ${(s.:.)LS_COLORS}
zstyle ':completion:*' menu select


# Vi Mode Configuration
set -o vi
KEYTIMEOUT=1

autoload -Uz edit-command-line
zle -N edit-command-line

# Custom vi-yank that also copies to Wayland clipboard
function vi-yank-wl {
    zle vi-yank
    echo "$CUTBUFFER" | wl-copy
}
zle -N vi-yank-wl
bindkey -M vicmd 'y' vi-yank-wl

bindkey -M vicmd v edit-command-line

# Environment Variables
export EDITOR=nvim
export PATH=$PATH:/usr/local/go/bin:$HOME/go/bin
export PATH=$PATH:$HOME/.local/share/bob/nvim-bin
export PATH=$PATH:$HOME/.local/bin

# Source External Configurations
eval "$(starship init zsh)"
. "$HOME/.cargo/env" 2>/dev/null || true
[[ -f ~/.env ]] && source ~/.env

# Aliases
alias ls='ls --color=auto'
alias ll='ls -alF'
alias la='ls -A'
alias l='ls -CF'
alias lh='ls -lh'
alias lt='ls -ltr'
alias lS='ls -lSr'

# Vim aliases
alias vi='nvim'
alias vim='nvim'

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
bindkey '^[o' _sgpt_zsh  # Alt+L to trigger shell-gpt suggestions

# Command Not Found Handler
if [[ -x /usr/lib/command-not-found ]]; then
    command_not_found_handler() {
        /usr/lib/command-not-found -- "$1"
        return $?
    }
fi

# aichat alias
alias ai='aichat --session temp'

# aider alias
alias aider1='aider --architect --model r1 --editor-model sonnet'

alias lg="lazygit"

alias fzvim='fzf \
    --preview "command -v bat >/dev/null 2>&1 \
        && bat --color=always -n {} \
        || cat {}" \
    --bind "enter:execute(nvim {})"'

# Fuzzy directory navigation
fcd() {
    local dir
    dir=$(find ${1:-.} -type d -not -path '*/\.*' 2> /dev/null | fzf +m) && cd "$dir"
}

# Create wrappers around common nvm consumers.
# nvm, node, yarn and npm will load nvm.sh on their first invocation,
# posing no start up time penalty for the shells that aren't going to use them at all.
# There is only single time penalty for one shell.

typeset -ga __lazyLoadLabels=(nvm node npm npx pnpm yarn pnpx bun bunx)

__load-nvm() {
    export NVM_DIR="${NVM_DIR:-$HOME/.nvm}"

    [ -s "$NVM_DIR/nvm.sh" ] && source "$NVM_DIR/nvm.sh"
    [ -s "$NVM_DIR/bash_completion" ] && source "$NVM_DIR/bash_completion"
}

__work() {
    for label in "${__lazyLoadLabels[@]}"; do
        unset -f $label
    done
    unset -v __lazyLoadLabels

    __load-nvm
    unset -f __load-nvm __work
}

for label in "${__lazyLoadLabels[@]}"; do
    eval "$label() { __work; $label \$@; }"
done

# end nvm lazy load

# eval "$(uv generate-shell-completion zsh)"
# eval "$(uvx --generate-shell-completion zsh)"
