#!/bin/bash
UPDATES=$(checkupdates | wc -l)
mkdir -p "$HOME/.cache/i3status"
printf '󱧘: %s\n' "$UPDATES" > "$HOME/.cache/i3status/updates"
