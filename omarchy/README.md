# Omarchy Migration Kit (`saxtonhale`)

Omarchy v4.5.0 on `nvme1n1` (Samsung 238.5 GB); Debian on `nvme0n1` stays as fallback (UEFI `Boot0001`).

## One command after first boot into Omarchy
```bash
curl -fsSL https://raw.githubusercontent.com/jackmhny/dotfiles/main/omarchy/go | bash
```
This clones `~/dotfiles` and runs `bootstrap.sh`, which:
- installs Tailscale, Chrome, Mullvad, Codex, Antigravity (`antigravity`, `antigravity-cli` = `agy`) and Hex (`hex-bin`)
- links `hypr/bindings.lua` and the LazyVim config, then reloads Hyprland
- installs the Mullvad+Tailscale nftables bypass
- configures git for 1Password SSH signing
- auto-detects `/boot/saxtonhale-secrets.tar.gz.gpg` (AES-256, passphrase in 1Password) and restores Wi-Fi profiles, SSH keys/config and Hex settings, then deletes the staged copy

## Files
- `hypr/bindings.lua` — minimal Omarchy v4.5.0 override (Vim focus/swap, re-parked defaults, Antigravity/Codex binds)
- `ssh/config` — unified SSH config
- `mullvad/mullvad-tailscale-nft.service` — nftables bypass for 100.64.0.0/10
- `bootstrap.sh` / `go` — post-install scripts
- `vm-test.sh` — QEMU/KVM dry-run harness

## Boot entry
```bash
sudo efibootmgr --bootnext 0004 && sudo reboot   # one-shot into Omarchy
sudo efibootmgr -o 0004,0001                      # make Omarchy default once happy
```

## Handoff prompt for a new Antigravity session on Omarchy
```text
I just migrated saxtonhale to Omarchy v4.5.0 on nvme1n1 and ran ~/dotfiles/omarchy/bootstrap.sh. Please verify Hyprland bindings (~/dotfiles/omarchy/hypr/bindings.lua), Tailscale, Mullvad+nftables, 1Password SSH Git signing, Hex (Alt+Space), Chrome, and Goodix fingerprint auth (27c6:6a94), make sure /boot/saxtonhale-secrets.tar.gz.gpg is deleted, and once everything looks good help me run sudo efibootmgr -o 0004,0001 to make Omarchy the default boot entry.
```
