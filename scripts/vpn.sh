#!/usr/bin/env zsh

eval $(op signin)

CSUS_PASS=$(op item get "Csus" --field password --reveal)

echo "$CSUS_PASS" | sudo openconnect \
  --protocol=gp \
  --user=jackmahoney \
  --passwd-on-stdin \
  vpn.csus.edu
