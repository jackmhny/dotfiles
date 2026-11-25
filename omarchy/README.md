# Omarchy Migration Kit (`saxtonhale`)

Clean, minimal Omarchy v4.5.0+ setup for `saxtonhale` (LG Gram `14ZB90Q-G.AAC6U1`), installing onto `nvme1n1` (238.5 GB) while keeping Debian on `nvme0n1` intact as a fallback.

## What's Here
- [hypr/bindings.lua](hypr/bindings.lua) — Minimal ~20-line Omarchy v4.5.0 Lua override:
  - `Super + h/j/k/l` focus & `Super + Shift + h/j/k/l` window swap
  - Displaced defaults re-parked cleanly: `Super + Ctrl + /` (Keybindings menu), `Super + Ctrl + J` (Toggle split), `Super + \` / `Super + Alt + \` (Cycle layout)
  - AI plane: `Super + Shift + A` (Antigravity), `Super + Shift + Alt + A` (Codex), keeping stock `Super + Shift + Ctrl + A` (`omarchy-agent --pick`)
  - Everything else stays stock Omarchy (`Super + W` close, `Super + Space` menu, `Super + T` float, `Super + C/V` copy/paste, `Super + Ctrl + V` clipboard history, `Print` / `Super + Ctrl + C` / `Super + Ctrl + Print` capture & OCR).
- [ssh/config](ssh/config) — Unified SSH config (`Include ~/.ssh/config_tailnet_mesh` + `scout`/`lg`, `heavy`, `soldier`, `coding2`, `rsync`, `contabo`, `NZXT`, `rpi3b`, `rpi5`).
- [mullvad/mullvad-tailscale-nft.service](mullvad/mullvad-tailscale-nft.service) — Loads `../mullvad_tailscale.conf` on boot so `100.64.0.0/10` bypasses Mullvad.
- [bootstrap.sh](bootstrap.sh) — Idempotent post-install script (packages, symlinks, Mullvad+Tailscale nftables, 1Password SSH Git signing, optional `--secrets` bundle restore).
- [vm-test.sh](vm-test.sh) — QEMU/KVM + OVMF dry-run harness to test-drive Omarchy v4.5.0 before touching `nvme1n1`.

## 1. Dry-Run in QEMU/KVM (Optional, Recommended)
```bash
~/dotfiles/omarchy/vm-test.sh download
~/dotfiles/omarchy/vm-test.sh install   # install Omarchy onto the 32G qcow2
~/dotfiles/omarchy/vm-test.sh boot      # boot installed VM
```
Inside the VM:
```bash
git clone https://github.com/jackmhny/dotfiles ~/dotfiles
~/dotfiles/omarchy/bootstrap.sh --skip-packages   # or full bootstrap.sh
```

## 2. Bare-Metal Install on `nvme1n1`
1. Flash `~/Documents/OmarchyMigration/vm/omarchy-*-x86.iso` to a USB drive and boot it.
2. Select **`nvme1n1` (238.5 GB Samsung)** as the target drive — leave `nvme0n1` (512 GB Debian) untouched.
3. After first boot into Omarchy:
```bash
git clone https://github.com/jackmhny/dotfiles ~/dotfiles
~/dotfiles/omarchy/bootstrap.sh --secrets /path/to/saxtonhale-secrets.tar.gz.gpg
```
(Pull the encrypted bundle from `scout:/mnt/storage/downloads/saxtonhale-secrets.tar.gz.gpg` or a USB stick.)
