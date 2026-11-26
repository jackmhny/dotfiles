# Machine Context

- This is Jack's personal Omarchy (Arch Linux + Hyprland/Wayland) workstation, `saxtonhale`.
- Dotfiles live in `/home/jackmhny/dotfiles`.
- Development workspaces live in `/home/jackmhny/dev`.
- User systemd units live in `/home/jackmhny/.config/systemd/user`.

## Elevated Commands On This Machine

Use `pkexec --disable-internal-agent` for narrow admin actions so the desktop Polkit GUI dialog pops up for fingerprint or password approval (instead of `sudo`, which hangs on a hidden TTY password prompt if fingerprint auth times out).

```sh
pkexec --disable-internal-agent <command>
```

For multi-step elevated actions, group them into a single `pkexec --disable-internal-agent sh -c '<commands>'` call so Jack only has to approve once. If the prompt is canceled or times out, report that and wait until Jack is ready to retry.

## 1Password And Secrets

- Prefer the `1password` MCP server (`/opt/1Password/1password-mcp`) or the desktop-integrated `op` CLI (`op run`, `op read`) over hardcoded secrets or standalone `op signin`.
- Never echo revealed secrets into transcripts, logs, or files.
- If `op` says "account is not signed in": confirm Settings -> Developer has CLI, MCP, and SDK integration enabled, move any legacy `~/.config/op/config` aside, clear `/run/user/$UID/op-daemon.*`, and restart 1Password.
