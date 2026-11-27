#!/usr/bin/env bash
set -euo pipefail

# Post-install bootstrap for saxtonhale on Omarchy (Arch + Hyprland v4.5.0+)
# Usage:
#   ./bootstrap.sh [--secrets /path/to/saxtonhale-secrets.tar.gz.gpg] [--skip-packages]

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SECRETS_ARCHIVE=""
SKIP_PACKAGES=false

while (($#)); do
  case "$1" in
    --secrets)
      SECRETS_ARCHIVE="${2:?--secrets requires a path}"
      shift 2
      ;;
    --skip-packages)
      SKIP_PACKAGES=true
      shift
      ;;
    -h|--help)
      sed -n '3,6p' "$0"
      exit 0
      ;;
    *)
      echo "Unknown flag: $1" >&2
      exit 1
      ;;
  esac
done

log() { printf '\n==> %s\n' "$*"; }

# Auto-detect the staged encrypted secrets bundle on the Omarchy ESP (/boot).
if [[ -z "$SECRETS_ARCHIVE" && -f /boot/saxtonhale-secrets.tar.gz.gpg ]]; then
  SECRETS_ARCHIVE="/boot/saxtonhale-secrets.tar.gz.gpg"
  echo "Found staged secrets bundle: $SECRETS_ARCHIVE (you'll be asked for its GPG passphrase from 1Password)"
fi

link_with_backup() {
  local src="$1" dst="$2"
  mkdir -p "$(dirname "$dst")"
  if [[ -L "$dst" ]]; then
    rm -f "$dst"
  elif [[ -e "$dst" ]]; then
    mv "$dst" "${dst}.omarchy-bak.$(date +%Y%m%d-%H%M%S)"
  fi
  ln -s "$src" "$dst"
  echo "  linked $dst -> $src"
}

# 1. Core packages (keep minimal; Omarchy already ships Hyprland, ghostty/alacritty,
#    1Password, Neovim, mise, lazygit, fzf, ripgrep, fd, bat, docker, etc.)
if [[ "$SKIP_PACKAGES" == "false" ]]; then
  log "Installing core packages"
  AUR_HELPER=""
  if command -v yay >/dev/null 2>&1; then
    AUR_HELPER="yay"
  elif command -v paru >/dev/null 2>&1; then
    AUR_HELPER="paru"
  fi

  sudo pacman -S --needed --noconfirm tailscale nftables github-cli git-delta git-crypt uv yt-dlp \
    discord openconnect ncdu tree tig openssh rsync python-websockets

  # Carryover extras: installed one at a time so a missing package never blocks the rest
  for pkg in deskflow virt-manager qemu-desktop libvirt dnsmasq edk2-ovmf \
      cmake gdb ninja shellcheck strace lsof wget bind nmap jdk-openjdk pandoc-cli \
      texlive-basic texlive-latex texlive-latexrecommended texlive-latexextra \
      qbittorrent torbrowser-launcher prismlauncher; do
    sudo pacman -S --needed --noconfirm "$pkg" || echo "  [warn] pacman install failed for $pkg"
  done
  sudo systemctl enable --now libvirtd.service || true
  sudo usermod -aG libvirt "$USER" || true

  if [[ -n "$AUR_HELPER" ]]; then
    # Install each AUR package separately so one hiccup never blocks the rest.
    for pkg in google-chrome mullvad-vpn-bin antigravity antigravity-cli zoom; do
      "$AUR_HELPER" -S --needed --noconfirm "$pkg" \
        || echo "  [warn] AUR install failed for $pkg (retry later: $AUR_HELPER -S $pkg)"
    done
  else
    echo "  [note] No AUR helper (yay/paru) found; install: google-chrome mullvad-vpn-bin antigravity antigravity-cli zoom"
  fi

  # Codex CLI (via npm/mise if node is present)
  if command -v npm >/dev/null 2>&1 && ! command -v codex >/dev/null 2>&1; then
    npm install -g @openai/codex
  fi

  # Enable Tailscale
  sudo systemctl enable --now tailscaled.service

  # Tailnet SSH mesh: sshd + allow port 22 only on tailscale0 through Omarchy's default-deny ufw
  sudo systemctl enable --now sshd.service || true
  if command -v ufw >/dev/null 2>&1; then
    sudo ufw allow in on tailscale0 to any port 22 proto tcp comment 'tailnet-ssh' || true
  fi

  # Set Google Chrome as default browser (Omarchy-aware)
  if command -v omarchy-default-browser >/dev/null 2>&1; then
    omarchy-default-browser google-chrome || true
  elif command -v xdg-settings >/dev/null 2>&1; then
    xdg-settings set default-web-browser google-chrome.desktop || true
  fi

  # Register Codex with Omarchy's native agent launcher (Super+Shift+Ctrl+A)
  if command -v omarchy >/dev/null 2>&1 && command -v codex >/dev/null 2>&1; then
    omarchy default agent codex || true
  fi
fi

# 2. Link Omarchy Hyprland bindings override & LazyVim Neovim config
log "Linking Hyprland bindings.lua and LazyVim config"
link_with_backup "$DOTFILES_DIR/omarchy/hypr/bindings.lua" "$HOME/.config/hypr/bindings.lua"
link_with_backup "$DOTFILES_DIR/nvim" "$HOME/.config/nvim"
hyprctl reload >/dev/null 2>&1 || true

# 2b. Global AGENTS.md (pkexec rule) + personal bash aliases
log "Linking AGENTS.md and bash aliases"
mkdir -p "$HOME/.gemini/config" "$HOME/.codex"
link_with_backup "$DOTFILES_DIR/omarchy/AGENTS.md" "$HOME/AGENTS.md"
link_with_backup "$DOTFILES_DIR/omarchy/AGENTS.md" "$HOME/.gemini/config/AGENTS.md"
link_with_backup "$DOTFILES_DIR/omarchy/AGENTS.md" "$HOME/.codex/AGENTS.md"
if ! grep -Fq "omarchy/bash/aliases.sh" "$HOME/.bashrc" 2>/dev/null; then
  printf '\n# Jack personal aliases\n[ -f "%s/omarchy/bash/aliases.sh" ] && source "%s/omarchy/bash/aliases.sh"\n' \
    "$DOTFILES_DIR" "$DOTFILES_DIR" >> "$HOME/.bashrc"
fi

# 2d. jm-screen / mercury-screen
log "Linking jm-screen and mercury-screen"
SCR="$DOTFILES_DIR/omarchy/screen"
link_with_backup "$SCR/bin/jm-screen" "$HOME/.local/bin/jm-screen"
link_with_backup "$SCR/bin/mercury-screen" "$HOME/.local/bin/mercury-screen"
link_with_backup "$SCR/applications/jm-screen.desktop" "$HOME/.local/share/applications/jm-screen.desktop"
link_with_backup "$SCR/applications/mercury-screen.desktop" "$HOME/.local/share/applications/mercury-screen.desktop"
link_with_backup "$SCR/systemd/mercury-screen.service" "$HOME/.config/systemd/user/mercury-screen.service"
link_with_backup "$SCR/systemd/mercury-screen.socket" "$HOME/.config/systemd/user/mercury-screen.socket"
link_with_backup "$SCR/config/connection.ini" "$HOME/.config/mercury-screen/connection.ini"
systemctl --user daemon-reload >/dev/null 2>&1 || true

# 2c. 1Password MCP + CLI smoothing
log "Configuring 1Password MCP & CLI integration"
MCP_BIN=/opt/1Password/1password-mcp
if [[ -x "$MCP_BIN" && ! -g "$MCP_BIN" ]]; then
  # Arch AUR 1password packages can miss the setgid bit ("Linux peer effective GID check failed")
  if [[ -x /opt/1Password/after-install.sh ]]; then
    sudo /opt/1Password/after-install.sh || true
  else
    sudo groupadd -f onepassword-mcp && sudo chgrp onepassword-mcp "$MCP_BIN" && sudo chmod 2755 "$MCP_BIN" || true
  fi
fi
mkdir -p "$HOME/.gemini/config"
python3 - <<'PY'
import json, pathlib
p = pathlib.Path.home() / ".gemini/config/mcp_config.json"
try:
    d = json.loads(p.read_text())
except Exception:
    d = {}
d.setdefault("mcpServers", {})["1password"] = {"command": "/opt/1Password/1password-mcp", "args": []}
p.write_text(json.dumps(d, indent=2) + "\n")
PY
touch "$HOME/.codex/config.toml"
if ! grep -Fq "[mcp_servers.1password]" "$HOME/.codex/config.toml"; then
  printf '\n[mcp_servers.1password]\ncommand = "/opt/1Password/1password-mcp"\nargs = []\n' >> "$HOME/.codex/config.toml"
fi

# 3. Install Mullvad + Tailscale nftables bypass rule
log "Installing Mullvad + Tailscale nftables bypass"
sudo install -Dm644 "$DOTFILES_DIR/mullvad_tailscale.conf" /etc/nftables.d/mullvad-tailscale.nft
sudo install -Dm644 "$DOTFILES_DIR/omarchy/mullvad/mullvad-tailscale-nft.service" /etc/systemd/system/mullvad-tailscale-nft.service
sudo systemctl daemon-reload
sudo systemctl enable --now mullvad-tailscale-nft.service || true

# 4. Configure Git with 1Password SSH commit signing + gh credentials + delta
log "Configuring Git (1Password SSH signing)"
mkdir -p "$HOME/.config/git"
cat > "$HOME/.config/git/config" <<'EOF'
[core]
    pager = delta
    excludesFile = ~/.gitignore_global
[user]
    name = Jack Mahoney
    email = jacksmahoney@gmail.com
    # Set signingkey to your 1Password SSH public key once 1Password SSH Agent is enabled:
    # signingkey = ssh-ed25519 AAAA...
[gpg]
    format = ssh
[gpg "ssh"]
    program = /opt/1Password/op-ssh-sign
[commit]
    gpgsign = true
[credential "https://github.com"]
    helper =
    helper = !/usr/bin/gh auth git-credential
[credential "https://gist.github.com"]
    helper =
    helper = !/usr/bin/gh auth git-credential
[diff]
    tool = nvimdiff
[difftool "nvimdiff"]
    path = nvim
[difftool]
    prompt = false
[init]
    defaultBranch = main
[delta]
    keep-plus-minus-markers = true
[url "ssh://aur@aur.archlinux.org/"]
    insteadOf = https://aur.archlinux.org/
[url "https://aur.archlinux.org/"]
    insteadOf = aur@aur.archlinux.org:
EOF

# 5. Optional: decrypt & restore secrets bundle (SSH keys/config, Wi-Fi profiles, Hex settings)
if [[ -n "$SECRETS_ARCHIVE" ]]; then
  log "Decrypting and restoring secrets from $SECRETS_ARCHIVE"
  TMP_DIR="$(mktemp -d)"
  trap 'rm -rf "$TMP_DIR"' EXIT

  if ! gpg --decrypt "$SECRETS_ARCHIVE" | tar -xz -C "$TMP_DIR"; then
    echo "  [warn] Could not decrypt secrets bundle; skipping restore (rerun: $0 --secrets $SECRETS_ARCHIVE)"
    SECRETS_ARCHIVE=""
  fi
  STAGE="$TMP_DIR/saxtonhale-secrets"

  # SSH
  if [[ -d "$STAGE/ssh" ]]; then
    mkdir -p "$HOME/.ssh"
    chmod 700 "$HOME/.ssh"
    cp -a "$STAGE/ssh/." "$HOME/.ssh/"
    ln -sfn "$HOME/.ssh/mykey" "$HOME/.ssh/id_ed25519"
    chmod 600 "$HOME/.ssh/mykey" "$HOME/.ssh/id_ed25519_tailnet_mesh" \
      "$HOME/.ssh/config" "$HOME/.ssh/config_tailnet_mesh" \
      "$HOME/.ssh/authorized_keys" 2>/dev/null || true
    chmod 644 "$HOME/.ssh/"*.pub 2>/dev/null || true
    echo "  restored ~/.ssh"
  fi

  # NetworkManager Wi-Fi profiles
  if [[ -d "$STAGE/nm-connections" ]]; then
    sudo install -d -m 700 /etc/NetworkManager/system-connections
    for f in "$STAGE/nm-connections/"*; do
      [[ -f "$f" ]] || continue
      base="$(basename "$f")"
      [[ "$base" == *.nmconnection ]] || base="${base}.nmconnection"
      sudo install -m 600 -o root -g root "$f" "/etc/NetworkManager/system-connections/$base"
    done
    sudo nmcli connection reload || true
    echo "  imported NetworkManager Wi-Fi profiles"
  fi

  # Tailscale machine identity (keeps saxtonhale at 100.64.0.9 on Headscale)
  if [[ -f "$STAGE/tailscale/tailscaled.state" ]]; then
    sudo systemctl stop tailscaled.service 2>/dev/null || true
    sudo install -d -m 700 -o root -g root /var/lib/tailscale
    sudo install -m 600 -o root -g root "$STAGE/tailscale/tailscaled.state" /var/lib/tailscale/tailscaled.state
    sudo systemctl enable --now tailscaled.service || true
    echo "  restored /var/lib/tailscale/tailscaled.state"
  fi

  # SSH host keys (keeps pinned mesh-saxtonhale fingerprint across Heavy/JM/Mercury)
  if [[ -d "$STAGE/ssh-host" ]]; then
    sudo systemctl stop sshd.service 2>/dev/null || true
    sudo install -d -m 755 -o root -g root /etc/ssh
    for f in "$STAGE/ssh-host/"ssh_host_*_key; do
      [[ -f "$f" ]] || continue
      sudo install -m 600 -o root -g root "$f" "/etc/ssh/$(basename "$f")"
    done
    for f in "$STAGE/ssh-host/"ssh_host_*_key.pub; do
      [[ -f "$f" ]] || continue
      sudo install -m 644 -o root -g root "$f" "/etc/ssh/$(basename "$f")"
    done
    sudo systemctl enable --now sshd.service || true
    echo "  restored /etc/ssh/ssh_host_* keys"
  fi

  # Remove the staged copies from the ESP once restored.
  if [[ "$SECRETS_ARCHIVE" == /boot/* && -d "$STAGE" ]]; then
    sudo rm -f /boot/saxtonhale-secrets.tar.gz.gpg /boot/saxtonhale-secrets.tar.gz.gpg.sha256
    echo "  removed staged secrets bundle from /boot"
  fi
fi

log "Bootstrap complete!"
cat <<'NEXT'
Remaining interactive steps:
  1. Run: omarchy-setup-security-fingerprint  (Goodix -> sudo, polkit/pkexec, hyprlock)
  2. Sign into 1Password (Super+Shift+/) -> Settings -> Developer -> enable:
       SSH Agent (+ Git commit signing; paste pubkey into ~/.config/git/config signingkey),
       Integrate with 1Password CLI, MCP integration, SDK integration.
  3. Verify Tailscale auto-reconnected as 100.64.0.9: tailscale status
     (fallback only if not connected: sudo tailscale up --login-server=https://headscale.jackmhny.xyz)
  4. Run: gh auth login
  5. Restore prior Antigravity chats from Heavy:
       ~/dotfiles/omarchy/restore-antigravity-chats.sh --stop
     Then launch Antigravity (Super+Shift+A / antigravity / agy), sign in, reinstall + sign into
     the Google Workspace and Notion plugins (optionally Chrome DevTools), paste the handoff prompt.
  6. Sign into Chrome (Super+Shift+B). Test binds: Super+H/J/K/L, Super+Ctrl+/, Super+Shift+A.
  7. Add Debian to Limine: sudo limine-scan (or add the chainload block to /boot/limine.conf).
     Promote Omarchy to default when ready: sudo efibootmgr -o 0001,0000
NEXT
