#!/bin/bash
UPDATES=$(checkupdates | wc -l)
echo "󱧘: $UPDATES" > /tmp/pacman-updates
