# ~/.config/zsh/command-not-found.zsh

if (( $+commands[pacman] )); then

  function command_not_found_handler() {
    local cmd=$1
    local pkgline raw_pkg pkgname

    # 1) Official repos via pacman -F
    if pkgline=$(pacman -F "/usr/bin/${cmd}" 2>/dev/null | head -n1) \
      && raw_pkg=$(echo "$pkgline" \
                    | sed -n 's/.*owned by \([^ ]*\).*/\1/p') \
      && [[ -n $raw_pkg ]]; then
      pkgname=${raw_pkg#*/}    # strip "extra/" → "alsa-utils"
      echo "zsh: command not found: $cmd"
      echo "It’s in the official package '$pkgname'. Install with:"
      echo "  sudo pacman -S $pkgname"
      return 127
    fi

    # 2) AUR via yay
    if (( $+commands[yay] )); then
      pkgline=$(yay -Ss --color never "$cmd" \
                 | grep "^aur/${cmd}[[:space:]]" \
                 | head -n1)
      if [[ -n $pkgline ]]; then
        raw_pkg=${pkgline%% *}    # e.g. "aur/mcrcon"
        pkgname=${raw_pkg#*/}     # → "mcrcon"
        echo "zsh: command not found: $cmd"
        echo "It’s in the AUR package '$pkgname'. Install with:"
        echo "  yay -S $pkgname"
        return 127
      fi
    fi

    # 3) Fallback
    echo "zsh: command not found: $cmd"
    return 127
  }

fi

