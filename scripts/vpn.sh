#!/usr/bin/env zsh

if ! op whoami >/dev/null 2>&1; then
  eval "$(op signin)"
fi

CSUS_PASS=$(op item get "Csus" --field password --reveal)

echo "$CSUS_PASS" | sudo openconnect \
  --protocol=gp \
  --user=jackmahoney \
  --passwd-on-stdin \
  vpn.csus.edu
