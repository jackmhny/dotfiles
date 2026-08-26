# Per-machine i3status profile

Create `~/.config/i3status/machine-role` with one value:

- `laptop` shows Wi-Fi and battery.
- `desktop` shows Ethernet and no battery.

The file is ignored by Git so each dotfiles checkout can select its own role.
For a one-off override, set `I3STATUS_MACHINE_ROLE=laptop` or
`I3STATUS_MACHINE_ROLE=desktop` when starting `t3-i3status`.
