# Omarchy Migration Kit (`saxtonhale`)

Omarchy v4.5.0 on `nvme1n1` (Samsung 238.5 GB); Debian on `nvme0n1` stays as fallback (UEFI `Boot0001`).
UEFI `BootOrder` is already `0004,0001`, so a normal reboot lands in Omarchy.

## One command after first boot into Omarchy
```bash
curl -fsSL https://raw.githubusercontent.com/jackmhny/dotfiles/main/omarchy/go | bash
```
This clones `~/dotfiles` and runs `bootstrap.sh`, which:
- installs Tailscale, Chrome, Mullvad, Codex, Antigravity (`antigravity`, `antigravity-cli` = `agy`), Hex (`hex-bin`) and extras (`git-crypt uv yt-dlp discord openconnect ncdu tree tig openssh python-websockets`)
- installs carryover apps: deskflow, virt-manager/QEMU, LaTeX + Pandoc, OpenJDK, C/script dev tools (cmake gdb ninja shellcheck nmap...), Zoom, qBittorrent, Zathura, Tor Browser, Prism Launcher, Steam
- links `omarchy/screen/` (jm-screen, mercury-screen) into ~/.local/bin, applications and user systemd
- links `hypr/bindings.lua`, the LazyVim config and `AGENTS.md` (`~/AGENTS.md`, `~/.gemini/config`, `~/.codex`; uses `pkexec --disable-internal-agent`), and sources `bash/aliases.sh`
- enables `sshd` and opens port 22 on `tailscale0` through Omarchy's default-deny `ufw` (SSH mesh)
- installs the Mullvad+Tailscale nftables bypass
- fixes the Arch `1password-mcp` setgid bug (`after-install.sh`), registers the 1Password MCP in Antigravity and Codex, and moves aside a legacy `~/.config/op/config`
- configures git for 1Password SSH signing
- auto-detects `/boot/saxtonhale-secrets.tar.gz.gpg` (AES-256, passphrase in 1Password) and restores Wi-Fi profiles, SSH keys/config and Hex settings, then deletes the staged copy

## 1Password auth gotchas
- Settings -> Developer: enable SSH Agent, CLI integration, MCP integration and SDK integration.
- `op` stuck on "account is not signed in": move `~/.config/op/config` aside, `rm -f /run/user/$UID/op-daemon.*`, restart 1Password.
- On Arch, `/opt/1Password/1password-mcp` must be setgid `onepassword-mcp` (bootstrap handles it).

## Files
- `AGENTS.md` - global agent rules (pkexec, 1Password)
- `bash/aliases.sh` - personal aliases (keeps Omarchy's eza/zoxide defaults)
- `hypr/bindings.lua` - minimal Omarchy v4.5.0 override (Vim focus/swap, re-parked defaults, Antigravity/Codex binds)
- `ssh/config` - unified SSH config
- `mullvad/mullvad-tailscale-nft.service` - nftables bypass for 100.64.0.0/10
- `bootstrap.sh` / `go` - post-install scripts
- `vm-test.sh` - QEMU/KVM dry-run harness

## Boot entry
```bash
sudo efibootmgr -o 0001,0004   # revert to Debian default if needed
```

## Handoff prompt for a new Antigravity session on Omarchy
```text
I just migrated saxtonhale to Omarchy v4.5.0 on nvme1n1 and ran ~/dotfiles/omarchy/bootstrap.sh. Please verify Hyprland bindings, fingerprint auth via omarchy-setup-security-fingerprint (Goodix 27c6:6a94, pkexec), 1Password (MCP setgid + Antigravity/Codex registration, op whoami, SSH Git signing), Tailscale on https://headscale.jackmhny.xyz with ufw tailnet SSH and the Mullvad nftables bypass, Hex (Alt+Space), Chrome, and that /boot/saxtonhale-secrets.tar.gz.gpg is deleted. Then help me add Debian to Limine.
```
