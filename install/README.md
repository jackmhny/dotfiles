# Debian 13 installer for jackmhny/dotfiles

This adds a Debian 13/trixie-focused install layer to the repo. It is not a disk installer. It assumes Debian is already installed, then handles packages, symlinks, and Debian-specific compatibility shims.

## First run

```bash
cd ~/dotfiles
./install.py --dry-run
./install.py --profile full
```

For a noninteractive install:

```bash
./install.py --profile full --yes
```

Useful variants:

```bash
./install.py --profile minimal --yes
./install.py --profile desktop-i3 --yes
./install.py --profile dev --profile ai-cli --yes
./install.py --profile full --yes --configure-apt-sources
```

## What the installer does

- Checks `/etc/os-release` for Debian 13/trixie unless `--force` is used.
- Installs Debian packages from `install/packages/debian13-*.txt` using `apt-get`.
- Filters unavailable package names with `apt-cache show`, so packages that are absent from your enabled repositories do not break the whole run.
- For the `desktop-i3` profile, installs the Xorg/libinput touchpad config into `/etc/X11/xorg.conf.d/40-libinput.conf`, backing up any existing file first. This enables natural scrolling and tap-to-click.
- Links dotfiles into XDG locations, backing up pre-existing files as `*.backup-YYYYMMDD-HHMMSS`.
- Links all files in `scripts/` into `~/.local/bin`.
- Links user systemd units into `~/.config/systemd/user`, reloads the user manager, enables `codex-usagebar.timer`, and runs `codex-usagebar.service` once to populate the i3status cache.
- Creates Debian command-name shims where needed, especially `fd -> fdfind` and `bat -> batcat`.
- Creates `~/.config/i3/config.local`, because the i3 config includes that path.

## Profiles

- `minimal`: shell/editor/git/tmux/zsh/core CLI tools.
- `desktop-i3`: Xorg, i3, i3status, kitty, rofi, dunst, qutebrowser, screenshots, fonts.
- `dev`: compilers, containers, language tooling, git helpers.
- `ai-cli`: Python/Node/CLI support for agent tooling. Vendor-specific installs are intentionally not default.
- `media`: mpv, ffmpeg, gallery-dl, yt-dlp, ImageMagick.
- `full`: all of the above.

## Debian 13 notes

The current dotfiles still contain a few Arch-flavored assumptions. This install layer handles the main ones without rewriting the repo:

- Debian's `fd-find` package installs `fdfind`; the installer creates `~/.local/bin/fd`.
- Debian's `bat` package may install `batcat`; the installer creates `~/.local/bin/bat`.
- Deskflow `1.22.x` on a Debian/X11 server can send horizontal touchpad scroll as back/forward button events on newer X11 clients. `scripts/fix-deskflow-buttons` remaps the client's XTEST button map from `8/9` to `6/7`. Pass `--deskflow-fix` to link the autostart file on affected client machines only. Override the target pointer with `DESKFLOW_XTEST_POINTER` if needed.
- `ssh/config` and `git/config` are opt-in via `--link-private` because they contain host-specific data, personal identity, or non-Debian remnants.
- AUR-specific package resolution is intentionally not attempted. Package files use Debian package names, and unavailable entries are skipped.

## External tools

`--external` can run non-Debian user-level installers for things that are not reliably in Debian main or that you may prefer to keep self-updating:

- Astral `uv` install script
- `cargo install fnm`
- Terminus/Terminess Nerd Font download from Nerd Fonts

Leave `--external` off for a fully Debian-repository-first install.
