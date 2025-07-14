# base 16 shell
BASE16_SHELL="$HOME/.config/base16-shell/"
[ -n "$PS1" ] && \
    [ -s "$BASE16_SHELL/profile_helper.sh" ] && \
        source "$BASE16_SHELL/profile_helper.sh"
        
base16_tomorrow-night
#
# ZSH Configuration
#

# Basic ZSH Options
setopt autocd

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
fpath=($ZDOTDIR/completions $fpath)
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

# Custom vi-yank for xclip
function vi-yank-x {
    zle vi-yank
    echo "$CUTBUFFER" | xclip -selection clipboard
}
zle -N vi-yank-x
bindkey -M vicmd 'y' vi-yank-x

bindkey -M vicmd v edit-command-line

# Environment Variables
export EDITOR=nvim
export PATH=$PATH:/usr/local/go/bin:$HOME/go/bin
export PATH=$PATH:$HOME/.local/share/bob/nvim-bin
export PATH=$PATH:$HOME/.cargo/bin
export PATH=$PATH:$HOME/.local/bin
export PATH=$PATH:$HOME/.nimble/bin

# Source External Configurations
eval "$(starship init zsh)"
. "$HOME/.cargo/env" 2>/dev/null || true
[[ -f ~/.env ]] && source ~/.env



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

# Fuzzy directory navigation
fcd() {
    local dir
    dir=$(find ${1:-.} -type d -not -path '*/\.*' 2> /dev/null | fzf +m) && cd "$dir"
}



export XDG_DATA_DIRS="$XDG_DATA_DIRS:/var/lib/flatpak/exports/share:/home/jm/.local/share/flatpak/exports/share"




hash -d mods="/home/jm/.local/share/Steam/steamapps/compatdata/2379780/pfx/drive_c/users/steamuser/AppData/Roaming/Balatro/Mods"
hash -d mods_disabled="/home/jm/.disabled_mods"


# The next line updates PATH for the Google Cloud SDK.
if [ -f '/home/jm/google-cloud-sdk/path.zsh.inc' ]; then . '/home/jm/google-cloud-sdk/path.zsh.inc'; fi

# The next line enables shell command completion for gcloud.
if [ -f '/home/jm/google-cloud-sdk/completion.zsh.inc' ]; then . '/home/jm/google-cloud-sdk/completion.zsh.inc'; fi



setopt interactivecomments

0x0() {
    curl -F "file=@${1:--}" https://0x0.st
}

eval "$(fnm env --use-on-cd --shell zsh)"

[ -f $ZDOTDIR/.aliases ] && source $ZDOTDIR/.aliases

function y() {
    local tmp="$(mktemp -t "yazi-cwd.XXXXXX")" cwd
    yazi "$@" --cwd-file="$tmp"
    IFS= read -r -d '' cwd < "$tmp"
    [ -n "$cwd" ] && [ "$cwd" != "$PWD" ] && builtin cd -- "$cwd"
    rm -f -- "$tmp"
}

# Add your SSH key (silently)
if [ -z "$SSH_AUTH_SOCK" ]; then
    eval "$(ssh-agent -s)" > /dev/null
fi
ssh-add ~/.ssh/mykey 2>/dev/null
