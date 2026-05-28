#!/usr/bin/env python3
"""
jackmhny/dotfiles Debian 13 installer.

This is intentionally closer to archinstall's guided profile flow than to a
one-shot curl pipe. It assumes Debian is already installed, then installs Debian
packages, links this repo's dotfiles, and applies Debian-specific fixups.
"""
from __future__ import annotations

import argparse
import getpass
import os
import pwd
import shlex
import shutil
import subprocess
import sys
import textwrap
import time
from dataclasses import dataclass
from pathlib import Path
from typing import Iterable, Sequence

REPO_ROOT = Path(__file__).resolve().parent
INSTALL_DIR = REPO_ROOT / "install"
PACKAGE_DIR = INSTALL_DIR / "packages"
TIMESTAMP = time.strftime("%Y%m%d-%H%M%S")

PROFILE_GROUPS: dict[str, list[str]] = {
    "minimal": ["base"],
    "desktop-i3": ["base", "desktop-i3"],
    "dev": ["base", "dev"],
    "ai-cli": ["base", "dev", "ai-cli"],
    "media": ["base", "media"],
    "full": ["base", "desktop-i3", "dev", "ai-cli", "media"],
}

PROFILE_DESCRIPTIONS: dict[str, str] = {
    "minimal": "shell, editor, git, tmux, zsh, core CLI tools",
    "desktop-i3": "minimal plus Xorg/i3/i3status/kitty/rofi/dunst/qutebrowser",
    "dev": "minimal plus compilers, containers, language tooling",
    "ai-cli": "dev plus CLI AI/runtime helpers; vendor tools are optional",
    "media": "minimal plus mpv/ffmpeg/gallery-dl/yt-dlp style media tools",
    "full": "everything in the Debian workstation profile",
}

# User-level links. The source paths are relative to the repo root.
DOTLINKS: list[tuple[str, str]] = [
    ("feh", ".config/feh"),
    ("gtk-3.0", ".config/gtk-3.0"),
    ("gtk-4.0", ".config/gtk-4.0"),
    ("i3", ".config/i3"),
    ("i3status", ".config/i3status"),
    ("kitty", ".config/kitty"),
    ("mpv", ".config/mpv"),
    ("nvim", ".config/nvim"),
    ("opencode", ".config/opencode"),
    ("qutebrowser", ".config/qutebrowser"),
    ("rofi", ".config/rofi"),
    ("starship", ".config/starship"),
    ("tmux", ".config/tmux"),
    ("zsh", ".config/zsh"),
    ("applications/helium-laptop-audio.desktop", ".local/share/applications/helium-laptop-audio.desktop"),
    ("chrome-flags.conf", ".config/chrome-flags.conf"),
    ("dunst", ".config/dunst"),
    ("sunshine/apps.json", ".config/sunshine/apps.json"),
    ("sunshine/sunshine.conf", ".config/sunshine/sunshine.conf"),
    (
        "systemd/app-dev.lizardbyte.app.Sunshine.service.d/ipad-display.conf",
        ".config/systemd/user/app-dev.lizardbyte.app.Sunshine.service.d/ipad-display.conf",
    ),
]

# These are intentionally opt-in because they contain personal hosts, identity,
# or Arch/AUR-specific remnants that are not ideal for a clean Debian target.
PRIVATE_DOTLINKS: list[tuple[str, str]] = [
    ("ssh/config", ".ssh/config"),
    ("git/config", ".config/git/config"),
]

USER_SYSTEMD_UNITS = [
    "codex-usagebar.service",
    "codex-usagebar.timer",
    "ipad-display-watch.service",
    "laptop-audio-receiver.service",
]

USER_SYSTEMD_TIMERS = [
    "codex-usagebar.timer",
]

USER_SYSTEMD_SERVICES = [
    "ipad-display-watch.service",
    "laptop-audio-receiver.service",
]

DESKTOP_SYSTEM_CONFIGS = [
    ("xorg/40-libinput.conf", "/etc/X11/xorg.conf.d/40-libinput.conf", "0644"),
]

APT_SOURCES = """\
Types: deb
URIs: http://deb.debian.org/debian
Suites: trixie trixie-updates
Components: main contrib non-free non-free-firmware
Signed-By: /usr/share/keyrings/debian-archive-keyring.gpg

Types: deb
URIs: http://security.debian.org/debian-security
Suites: trixie-security
Components: main contrib non-free non-free-firmware
Signed-By: /usr/share/keyrings/debian-archive-keyring.gpg
"""

@dataclass
class Context:
    repo: Path
    user: str
    home: Path
    dry_run: bool
    yes: bool
    force: bool
    skip_apt: bool
    link_private: bool
    configure_apt_sources: bool
    external: bool
    chsh: bool

    @property
    def local_bin(self) -> Path:
        return self.home / ".local" / "bin"


def note(message: str) -> None:
    print(f":: {message}")


def warn(message: str) -> None:
    print(f"!! {message}")


def die(message: str, code: int = 1) -> None:
    print(f"error: {message}", file=sys.stderr)
    raise SystemExit(code)


def shell_join(cmd: Sequence[str]) -> str:
    return " ".join(shlex.quote(str(x)) for x in cmd)


def run(
    ctx: Context,
    cmd: Sequence[str],
    *,
    sudo: bool = False,
    check: bool = True,
    capture: bool = False,
    input_text: str | None = None,
) -> subprocess.CompletedProcess[str]:
    full = list(map(str, cmd))
    if sudo and os.geteuid() != 0:
        full = ["sudo", *full]
    prefix = "DRY " if ctx.dry_run else ""
    note(prefix + shell_join(full))
    if ctx.dry_run:
        return subprocess.CompletedProcess(full, 0, "", "")
    return subprocess.run(
        full,
        check=check,
        text=True,
        input=input_text,
        stdout=subprocess.PIPE if capture else None,
        stderr=subprocess.PIPE if capture else None,
    )


def command_exists(name: str) -> bool:
    return shutil.which(name) is not None


def parse_os_release() -> dict[str, str]:
    data: dict[str, str] = {}
    path = Path("/etc/os-release")
    if not path.exists():
        return data
    for raw in path.read_text(encoding="utf-8").splitlines():
        if not raw or raw.startswith("#") or "=" not in raw:
            continue
        key, value = raw.split("=", 1)
        data[key] = value.strip().strip('"')
    return data


def require_debian_13(ctx: Context) -> None:
    data = parse_os_release()
    distro = data.get("ID", "")
    codename = data.get("VERSION_CODENAME", "")
    version = data.get("VERSION_ID", "")
    if distro == "debian" and (codename == "trixie" or version.startswith("13")):
        note("target check passed: Debian 13/trixie")
        return
    msg = f"expected Debian 13/trixie, found ID={distro!r} VERSION_ID={version!r} VERSION_CODENAME={codename!r}"
    if ctx.force:
        warn(msg + "; continuing because --force was set")
    else:
        die(msg + "; rerun with --force only if you know this host is compatible")


def detect_target_user(explicit_user: str | None = None) -> tuple[str, Path]:
    if explicit_user:
        user = explicit_user
    elif os.geteuid() == 0:
        user = os.environ.get("SUDO_USER") or os.environ.get("USER")
        if not user or user == "root":
            die("run as your normal user, use sudo preserving SUDO_USER, or pass --target-user USER")
    else:
        user = getpass.getuser()

    if os.geteuid() != 0 and user != getpass.getuser():
        die("--target-user requires root/sudo when targeting a different account")

    entry = pwd.getpwnam(user)
    return user, Path(entry.pw_dir)


def ask_yes_no(prompt: str, *, default: bool = False, ctx: Context) -> bool:
    if ctx.yes:
        return True
    suffix = "Y/n" if default else "y/N"
    raw = input(f"{prompt} [{suffix}] ").strip().lower()
    if not raw:
        return default
    return raw in {"y", "yes"}


def choose_profiles() -> list[str]:
    print("\nProfiles:")
    names = list(PROFILE_GROUPS)
    for i, name in enumerate(names, start=1):
        print(f"  {i}. {name:<10} {PROFILE_DESCRIPTIONS[name]}")
    raw = input("\nSelect profiles by number/name, comma-separated [full]: ").strip()
    if not raw:
        return ["full"]
    chosen: list[str] = []
    for item in [x.strip() for x in raw.split(",") if x.strip()]:
        if item.isdigit():
            idx = int(item) - 1
            if idx < 0 or idx >= len(names):
                die(f"profile index out of range: {item}")
            chosen.append(names[idx])
        elif item in PROFILE_GROUPS:
            chosen.append(item)
        else:
            die(f"unknown profile: {item}")
    return dedupe(chosen)


def dedupe(items: Iterable[str]) -> list[str]:
    seen: set[str] = set()
    out: list[str] = []
    for item in items:
        if item not in seen:
            seen.add(item)
            out.append(item)
    return out


def package_groups_for_profiles(profiles: Iterable[str]) -> list[str]:
    groups: list[str] = []
    for profile in profiles:
        if profile not in PROFILE_GROUPS:
            die(f"unknown profile: {profile}")
        groups.extend(PROFILE_GROUPS[profile])
    return dedupe(groups)


def load_packages(group: str) -> list[str]:
    path = PACKAGE_DIR / f"debian13-{group}.txt"
    if not path.exists():
        warn(f"package group file missing: {path}")
        return []
    packages: list[str] = []
    for raw in path.read_text(encoding="utf-8").splitlines():
        line = raw.split("#", 1)[0].strip()
        if line:
            packages.extend(line.split())
    return packages


def apt_package_available(ctx: Context, package: str) -> bool:
    result = run(ctx, ["apt-cache", "show", package], check=False, capture=True)
    return result.returncode == 0 and bool(result.stdout.strip())


def install_apt_packages(ctx: Context, groups: list[str]) -> None:
    if ctx.skip_apt:
        warn("skipping apt package install because --skip-apt was set")
        return
    if not command_exists("apt-get"):
        die("apt-get not found")

    packages: list[str] = []
    for group in groups:
        group_packages = load_packages(group)
        note(f"package group {group}: {len(group_packages)} package names")
        packages.extend(group_packages)
    packages = dedupe(packages)
    if not packages:
        warn("no apt packages selected")
        return

    if ctx.configure_apt_sources:
        configure_debian_sources(ctx)

    run(ctx, ["apt-get", "update"], sudo=True)

    missing: list[str] = []
    available: list[str] = []
    for package in packages:
        if ctx.dry_run or apt_package_available(ctx, package):
            available.append(package)
        else:
            missing.append(package)

    if missing:
        warn("not in enabled Debian repositories, skipping: " + ", ".join(missing))

    if available:
        run(ctx, ["apt-get", "install", "-y", *available], sudo=True)


def install_system_configs(ctx: Context, groups: list[str]) -> None:
    if "desktop-i3" not in groups:
        return

    note("installing desktop system configs")
    for src_rel, dest_abs, mode in DESKTOP_SYSTEM_CONFIGS:
        src = ctx.repo / src_rel
        if not src.exists():
            warn(f"missing system config source: {src_rel}")
            continue

        dest = Path(dest_abs)
        if lexists(dest):
            run(ctx, ["cp", "-a", str(dest), f"{dest}.backup-{TIMESTAMP}"], sudo=True)
        run(ctx, ["install", "-D", "-m", mode, str(src), str(dest)], sudo=True)


def configure_debian_sources(ctx: Context) -> None:
    note("installing Debian 13/trixie deb822 apt sources with contrib/non-free/non-free-firmware")
    tmp = Path("/tmp/dotfiles-debian.sources")
    if ctx.dry_run:
        note("would write /etc/apt/sources.list.d/debian.sources")
        return
    tmp.write_text(APT_SOURCES, encoding="utf-8")
    run(ctx, ["install", "-m", "0644", str(tmp), "/etc/apt/sources.list.d/debian.sources"], sudo=True)


def ensure_parent(path: Path) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)


def lexists(path: Path) -> bool:
    return os.path.lexists(path)


def backup_existing(ctx: Context, dest: Path) -> None:
    backup = dest.with_name(dest.name + f".backup-{TIMESTAMP}")
    warn(f"backing up existing {dest} -> {backup}")
    if ctx.dry_run:
        return
    ensure_parent(backup)
    dest.rename(backup)


def link_one(ctx: Context, src_rel: str, dest_rel: str) -> None:
    src = (ctx.repo / src_rel).resolve()
    dest = ctx.home / dest_rel
    if not src.exists():
        warn(f"missing repo path, not linking: {src_rel}")
        return
    if not ctx.dry_run:
        ensure_parent(dest)
    if dest.is_symlink():
        try:
            if dest.resolve() == src:
                note(f"already linked: {dest_rel}")
                return
        except FileNotFoundError:
            pass
    if lexists(dest):
        backup_existing(ctx, dest)
    note(f"link {dest} -> {src}")
    if not ctx.dry_run:
        os.symlink(src, dest, target_is_directory=src.is_dir())


def link_dotfiles(ctx: Context) -> None:
    note("linking public dotfiles")
    for src_rel, dest_rel in DOTLINKS:
        link_one(ctx, src_rel, dest_rel)

    if ctx.link_private:
        note("linking private/host-specific dotfiles")
        for src_rel, dest_rel in PRIVATE_DOTLINKS:
            link_one(ctx, src_rel, dest_rel)
    else:
        warn("skipping ssh/config and git/config; pass --link-private to link personal/host-specific files")

    link_scripts(ctx)
    setup_user_systemd(ctx)


def link_scripts(ctx: Context) -> None:
    scripts = ctx.repo / "scripts"
    if not scripts.exists():
        warn("no scripts/ directory found")
        return
    if not ctx.dry_run:
        ctx.local_bin.mkdir(parents=True, exist_ok=True)
    for path in sorted(scripts.iterdir()):
        if not path.is_file():
            continue
        dest = ctx.local_bin / path.name
        link_one(ctx, str(path.relative_to(ctx.repo)), str(dest.relative_to(ctx.home)))
        if not ctx.dry_run and dest.exists():
            try:
                dest.chmod(dest.stat().st_mode | 0o111)
            except OSError:
                pass


def setup_user_systemd(ctx: Context) -> None:
    note("linking user systemd units")
    for unit in USER_SYSTEMD_UNITS:
        link_one(ctx, f"systemd/{unit}", f".config/systemd/user/{unit}")

    if not command_exists("systemctl"):
        warn("systemctl not found; skipping user timer enablement")
        return

    run(ctx, ["systemctl", "--user", "daemon-reload"], check=False)
    for timer in USER_SYSTEMD_TIMERS:
        run(ctx, ["systemctl", "--user", "enable", "--now", timer], check=False)
    for service in USER_SYSTEMD_SERVICES:
        run(ctx, ["systemctl", "--user", "enable", "--now", service], check=False)

    # Populate read_file caches immediately instead of waiting for the first timer tick.
    run(ctx, ["systemctl", "--user", "start", "codex-usagebar.service"], check=False)


def write_file_if_missing(ctx: Context, path: Path, content: str, mode: int = 0o644) -> None:
    if path.exists():
        note(f"exists: {path}")
        return
    note(f"write {path}")
    if ctx.dry_run:
        return
    ensure_parent(path)
    path.write_text(content, encoding="utf-8")
    path.chmod(mode)


def debian_fixups(ctx: Context, selected_groups: list[str]) -> None:
    note("applying Debian-specific user fixups")
    for rel in [
        ".local/bin",
        ".cache",
        ".config/i3",
        "Pictures/Screenshots",
        "Pictures/wallpapers",
    ]:
        path = ctx.home / rel
        note(f"mkdir -p {path}")
        if not ctx.dry_run:
            path.mkdir(parents=True, exist_ok=True)

    # Debian command name shims for configs/aliases that expect Arch-style binary names.
    create_command_shim(ctx, "fdfind", "fd")
    create_command_shim(ctx, "batcat", "bat")

    # i3 has an unconditional include for config.local; make it safe on fresh machines.
    write_file_if_missing(
        ctx,
        ctx.home / ".config/i3/config.local",
        "# Host-specific i3 overrides. This file is intentionally untracked.\n",
    )

    if ctx.chsh:
        set_zsh_shell(ctx)

    if ctx.external:
        install_external_user_tools(ctx)


def create_command_shim(ctx: Context, real_name: str, shim_name: str) -> None:
    real = shutil.which(real_name)
    shim = ctx.local_bin / shim_name
    if not real:
        warn(f"cannot create shim {shim_name}; {real_name} not found")
        return
    if lexists(shim):
        note(f"shim exists: {shim}")
        return
    note(f"shim {shim} -> {real}")
    if not ctx.dry_run:
        ctx.local_bin.mkdir(parents=True, exist_ok=True)
        os.symlink(real, shim)


def set_zsh_shell(ctx: Context) -> None:
    zsh = shutil.which("zsh")
    if not zsh:
        warn("zsh not found; cannot change login shell")
        return
    current_shell = pwd.getpwnam(ctx.user).pw_shell
    if current_shell == zsh:
        note("login shell already zsh")
        return
    run(ctx, ["chsh", "-s", zsh, ctx.user], sudo=True, check=False)


def install_external_user_tools(ctx: Context) -> None:
    warn("running optional external installers; these are intentionally not default")
    if not command_exists("uv") and command_exists("curl"):
        run(ctx, ["sh", "-c", "curl -LsSf https://astral.sh/uv/install.sh | sh"], check=False)
    if not command_exists("fnm") and command_exists("cargo"):
        run(ctx, ["cargo", "install", "fnm"], check=False)
    install_terminus_nerd_font(ctx)


def install_terminus_nerd_font(ctx: Context) -> None:
    if not command_exists("curl") or not command_exists("unzip"):
        warn("curl/unzip missing; cannot install Terminus Nerd Font")
        return
    font_dir = ctx.home / ".local/share/fonts/TerminessNerdFont"
    if font_dir.exists():
        note("Terminess Nerd Font directory already exists")
        return
    cmd = (
        "set -euo pipefail; "
        "tmp=$(mktemp -d); "
        "curl -L -o \"$tmp/Terminus.zip\" "
        "https://github.com/ryanoasis/nerd-fonts/releases/latest/download/Terminus.zip; "
        f"mkdir -p {shlex.quote(str(font_dir))}; "
        f"unzip -q \"$tmp/Terminus.zip\" -d {shlex.quote(str(font_dir))}; "
        "fc-cache -f"
    )
    run(ctx, ["bash", "-lc", cmd], check=False)


def print_summary(profiles: list[str], groups: list[str], ctx: Context) -> None:
    packages = dedupe(pkg for group in groups for pkg in load_packages(group))
    print("\nInstall summary")
    print("---------------")
    print(f"repo:        {ctx.repo}")
    print(f"target user: {ctx.user} ({ctx.home})")
    print(f"profiles:    {', '.join(profiles)}")
    print(f"pkg groups:  {', '.join(groups)}")
    print(f"apt pkgs:    {len(packages)} names before availability filtering")
    print(f"dotfiles:    public links + {'private links' if ctx.link_private else 'no private links'}")
    print(f"system cfgs: {'desktop Xorg/libinput config' if 'desktop-i3' in groups else 'none'}")
    print("user timers: codex-usagebar.timer")
    print(f"apt source:  {'write Debian trixie sources' if ctx.configure_apt_sources else 'leave existing apt sources alone'}")
    print(f"external:    {'enabled' if ctx.external else 'disabled'}")
    print(f"dry-run:     {ctx.dry_run}")


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(
        description="Guided Debian 13 installer for jackmhny/dotfiles",
        formatter_class=argparse.ArgumentDefaultsHelpFormatter,
    )
    parser.add_argument("--profile", action="append", choices=sorted(PROFILE_GROUPS), help="profile to install; repeatable")
    parser.add_argument("--list-profiles", action="store_true", help="show profiles and exit")
    parser.add_argument("--dry-run", action="store_true", help="print actions without changing the host")
    parser.add_argument("-y", "--yes", action="store_true", help="do not prompt before applying")
    parser.add_argument("--force", action="store_true", help="run even if /etc/os-release is not Debian 13/trixie")
    parser.add_argument("--target-user", help="target account when running as root/sudo")
    parser.add_argument("--skip-apt", action="store_true", help="do not install apt packages")
    parser.add_argument("--no-link", action="store_true", help="do not symlink dotfiles")
    parser.add_argument("--link-private", action="store_true", help="also link ssh/config and git/config")
    parser.add_argument("--configure-apt-sources", action="store_true", help="write a Debian 13 deb822 sources file")
    parser.add_argument("--external", action="store_true", help="run optional curl/cargo based installers")
    parser.add_argument("--no-chsh", action="store_true", help="do not change login shell to zsh")
    return parser


def main(argv: Sequence[str] | None = None) -> int:
    parser = build_parser()
    args = parser.parse_args(argv)

    if args.list_profiles:
        for name, groups in PROFILE_GROUPS.items():
            print(f"{name:<10} {','.join(groups):<30} {PROFILE_DESCRIPTIONS[name]}")
        return 0

    user, home = detect_target_user(args.target_user)
    ctx = Context(
        repo=REPO_ROOT,
        user=user,
        home=home,
        dry_run=args.dry_run,
        yes=args.yes,
        force=args.force,
        skip_apt=args.skip_apt,
        link_private=args.link_private,
        configure_apt_sources=args.configure_apt_sources,
        external=args.external,
        chsh=not args.no_chsh,
    )

    require_debian_13(ctx)

    profiles = dedupe(args.profile) if args.profile else choose_profiles()
    groups = package_groups_for_profiles(profiles)

    print_summary(profiles, groups, ctx)
    if not ctx.yes and not ask_yes_no("Apply these changes?", default=False, ctx=ctx):
        warn("aborted")
        return 1

    install_apt_packages(ctx, groups)
    install_system_configs(ctx, groups)
    if not args.no_link:
        link_dotfiles(ctx)
    debian_fixups(ctx, groups)

    note("done")
    print("\nNext commands:")
    print("  exec zsh")
    print("  i3-msg reload   # if already inside i3")
    print("  systemctl --user list-timers | grep codex-usagebar || true")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
