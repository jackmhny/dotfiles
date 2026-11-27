#!/usr/bin/env bash
set -euo pipefail

# Backup and restore Antigravity (Desktop + agy CLI) conversations via Heavy.
#
# Usage on Omarchy (pull & restore latest backup into $HOME):
#   ~/dotfiles/omarchy/restore-antigravity-chats.sh [--stop] [--yes]
#
# Usage before switching OS (snapshot live SQLite DBs & push to Heavy):
#   ~/dotfiles/omarchy/restore-antigravity-chats.sh --backup
#
# Verify archive & SQLite integrity into an isolated directory:
#   ~/dotfiles/omarchy/restore-antigravity-chats.sh --dry-run-restore /tmp/agy-test
#
# Environment overrides:
#   AGY_BACKUP_REMOTE   (default: mesh-heavy, falls back to heavy / jackmhny@209.145.51.192)
#   AGY_BACKUP_DIR      (default: Backups/omarchy-antigravity)

MODE="restore"
STOP_RUNNING=false
ASSUME_YES=false
DRY_RUN_DIR=""

while (($#)); do
  case "$1" in
    --backup|--push)
      MODE="backup"
      shift
      ;;
    --restore|--pull)
      MODE="restore"
      shift
      ;;
    --dry-run-restore)
      MODE="dry-run-restore"
      DRY_RUN_DIR="${2:?--dry-run-restore requires a target directory}"
      shift 2
      ;;
    --stop)
      STOP_RUNNING=true
      shift
      ;;
    -y|--yes)
      ASSUME_YES=true
      shift
      ;;
    -h|--help)
      sed -n '3,16p' "$0"
      exit 0
      ;;
    *)
      echo "Unknown option: $1" >&2
      exit 1
      ;;
  esac
done

log() { printf '\n==> %s\n' "$*"; }

TMP_ROOT=""
cleanup_tmp() {
  [[ -n "$TMP_ROOT" && -d "$TMP_ROOT" ]] && rm -rf "$TMP_ROOT"
}
trap cleanup_tmp EXIT

resolve_remote() {
  if [[ -n "${AGY_BACKUP_REMOTE:-}" ]]; then
    echo "$AGY_BACKUP_REMOTE"
    return
  fi
  if ssh -G mesh-heavy 2>/dev/null | grep -q '^hostname 100\.64\.0\.1$' && ssh -o BatchMode=yes -o ConnectTimeout=3 mesh-heavy true 2>/dev/null; then
    echo "mesh-heavy"
  elif ssh -G heavy 2>/dev/null | grep -q '^hostname 209\.145\.51\.192$'; then
    echo "heavy"
  else
    echo "jackmhny@209.145.51.192"
  fi
}

SSH_OPTS=(-o BatchMode=yes -o ConnectTimeout=10)
REMOTE_HOST="$(resolve_remote)"
if [[ "$REMOTE_HOST" == "jackmhny@209.145.51.192" && -f "$HOME/.ssh/mykey" ]]; then
  SSH_OPTS+=(-i "$HOME/.ssh/mykey")
fi
REMOTE_DIR="${AGY_BACKUP_DIR:-Backups/omarchy-antigravity}"

ensure_tools() {
  for cmd in python3 tar zstd sha256sum ssh; do
    if ! command -v "$cmd" >/dev/null 2>&1; then
      echo "Missing required tool: $cmd" >&2
      exit 1
    fi
  done
}

do_backup() {
  ensure_tools
  local ts archive_name stage_home archive_path sha_path
  ts="$(date +%Y%m%d-%H%M%S)"
  archive_name="antigravity-chats-${ts}.tar.zst"
  TMP_ROOT="$(mktemp -d)"
  stage_home="$TMP_ROOT/home"
  mkdir -p "$stage_home"

  log "Snapshotting live Antigravity SQLite databases and chat artifacts"
  STAGE_HOME="$stage_home" python3 - <<'PY'
import json
import os
import pathlib
import shutil
import sqlite3
import stat

home = pathlib.Path.home()
stage = pathlib.Path(os.environ["STAGE_HOME"])

sqlite_rel_globs = [
    ".gemini/antigravity/conversation_summaries.db",
    ".gemini/antigravity/conversations/*.db",
    ".gemini/antigravity-cli/conversation_summaries.db",
    ".gemini/antigravity-cli/conversations/*.db",
]

db_count = 0
for pattern in sqlite_rel_globs:
    for src_db in sorted(home.glob(pattern)):
        if not src_db.is_file():
            continue
        rel = src_db.relative_to(home)
        dst_db = stage / rel
        dst_db.parent.mkdir(parents=True, exist_ok=True)
        src_con = sqlite3.connect(str(src_db), timeout=30.0)
        dst_con = sqlite3.connect(str(dst_db))
        with dst_con:
            src_con.backup(dst_con)
        src_con.close()
        dst_con.execute("PRAGMA journal_mode=DELETE;")
        chk = dst_con.execute("PRAGMA quick_check;").fetchone()[0]
        dst_con.close()
        if chk != "ok":
            raise RuntimeError(f"SQLite quick_check failed for {rel}: {chk}")
        shutil.copymode(src_db, dst_db)
        db_count += 1

def ignore_special(dirpath, names):
    ignored = []
    p = pathlib.Path(dirpath)
    for n in names:
        fp = p / n
        try:
            st = fp.lstat()
        except OSError:
            ignored.append(n)
            continue
        # Skip sockets, FIFOs, and transient browser upload sandboxes
        if stat.S_ISSOCK(st.st_mode) or stat.S_ISFIFO(st.st_mode):
            ignored.append(n)
        elif n.endswith((".db-wal", ".db-shm")):
            ignored.append(n)
    return ignored

copy_paths = [
    ".gemini/antigravity/annotations",
    ".gemini/antigravity/agyhub_summaries_proto.pb",
    ".gemini/antigravity/antigravity_state.pbtxt",
    ".gemini/antigravity/brain",
    ".gemini/antigravity/sidecar_data",
    ".gemini/antigravity/voice_chats",
    ".gemini/antigravity-cli/annotations",
    ".gemini/antigravity-cli/brain",
    ".gemini/antigravity-cli/implicit",
    ".gemini/antigravity-cli/history.jsonl",
    ".gemini/antigravity-cli/jetbox_summaries_proto.pb",
    ".gemini/antigravity-cli/jetski_state.pbtxt",
    ".gemini/antigravity-cli/settings.json",
    ".gemini/config/projects",
    ".gemini/config/config.json",
    ".config/Antigravity/app_storage.json",
]

copied_items = []
for rel_str in copy_paths:
    src = home / rel_str
    if not src.exists():
        continue
    dst = stage / rel_str
    dst.parent.mkdir(parents=True, exist_ok=True)
    if src.is_dir():
        shutil.copytree(src, dst, symlinks=True, ignore=ignore_special, dirs_exist_ok=True)
    else:
        shutil.copy2(src, dst)
    copied_items.append(rel_str)

manifest = {
    "hostname": os.uname().nodename,
    "sqliteDatabasesSnapshotted": db_count,
    "copiedPaths": copied_items,
}
(stage / ".antigravity-backup-manifest.json").write_text(json.dumps(manifest, indent=2) + "\n")
print(f"  Snapshotted {db_count} SQLite databases and {len(copied_items)} paths")
PY

  archive_path="$TMP_ROOT/$archive_name"
  sha_path="${archive_path}.sha256"

  log "Compressing archive ($archive_name)"
  tar -C "$stage_home" -cf - . | zstd -T0 -6 -q -o "$archive_path"
  (cd "$TMP_ROOT" && sha256sum "$archive_name" > "$sha_path")
  ls -lh "$archive_path"
  cat "$sha_path"

  log "Uploading to ${REMOTE_HOST}:~/${REMOTE_DIR}/"
  ssh "${SSH_OPTS[@]}" "$REMOTE_HOST" "mkdir -p ~/${REMOTE_DIR} && chmod 700 ~/${REMOTE_DIR}"
  if command -v rsync >/dev/null 2>&1; then
    rsync -av --progress -e "ssh ${SSH_OPTS[*]}" \
      "$archive_path" "$sha_path" "${REMOTE_HOST}:${REMOTE_DIR}/"
  else
    scp "${SSH_OPTS[@]}" "$archive_path" "$sha_path" "${REMOTE_HOST}:${REMOTE_DIR}/"
  fi

  ssh "${SSH_OPTS[@]}" "$REMOTE_HOST" "
    set -euo pipefail
    cd ~/${REMOTE_DIR}
    sha256sum -c '${archive_name}.sha256'
    ln -sfn '${archive_name}' antigravity-chats-latest.tar.zst
    cp -f '${archive_name}.sha256' antigravity-chats-latest.tar.zst.sha256
    sed -i 's|${archive_name}|antigravity-chats-latest.tar.zst|' antigravity-chats-latest.tar.zst.sha256
    sha256sum -c antigravity-chats-latest.tar.zst.sha256
  "
  log "Backup verified on ${REMOTE_HOST}:~/${REMOTE_DIR}/${archive_name} (and linked as antigravity-chats-latest.tar.zst)"
}

check_running_antigravity() {
  local pattern pids
  pattern='([/]opt/Antigravity|[/]usr/lib/antigravity|[/]usr/share/antigravity|antigravity/bin/language_server|[/]Antigravity/antigravity)'
  pids="$(pgrep -f "$pattern" 2>/dev/null || true)"
  if [[ -z "$pids" ]]; then
    return 0
  fi

  if [[ "$STOP_RUNNING" == "true" ]]; then
    log "Stopping running Antigravity processes before restoring SQLite databases"
    pkill -TERM -f "$pattern" 2>/dev/null || true
    sleep 2
    return 0
  fi

  echo "Antigravity appears to be running right now:" >&2
  # shellcheck disable=SC2086
  ps -fp $pids >&2 || true
  if [[ "$ASSUME_YES" == "false" && -t 0 ]]; then
    read -r -p "Close Antigravity now so SQLite chat databases restore cleanly? [y/N] " ans
    if [[ "$ans" =~ ^[Yy]$ ]]; then
      pkill -TERM -f "$pattern" 2>/dev/null || true
      sleep 2
      return 0
    fi
  fi
  echo "Aborted: close Antigravity first or rerun with --stop." >&2
  exit 1
}

do_restore() {
  ensure_tools
  local target_home="$1"
  local is_dry_run="$2"

  if [[ "$is_dry_run" == "false" ]]; then
    check_running_antigravity
  fi

  local archive_path sha_path unpack_dir pre_backup
  TMP_ROOT="$(mktemp -d)"
  archive_path="$TMP_ROOT/antigravity-chats-latest.tar.zst"
  sha_path="$TMP_ROOT/antigravity-chats-latest.tar.zst.sha256"
  unpack_dir="$TMP_ROOT/unpacked"
  mkdir -p "$unpack_dir" "$target_home"

  log "Pulling latest Antigravity chat backup from ${REMOTE_HOST}:~/${REMOTE_DIR}/"
  if command -v rsync >/dev/null 2>&1; then
    rsync -avL --progress -e "ssh ${SSH_OPTS[*]}" \
      "${REMOTE_HOST}:${REMOTE_DIR}/antigravity-chats-latest.tar.zst" \
      "${REMOTE_HOST}:${REMOTE_DIR}/antigravity-chats-latest.tar.zst.sha256" \
      "$TMP_ROOT/"
  else
    scp "${SSH_OPTS[@]}" \
      "${REMOTE_HOST}:${REMOTE_DIR}/antigravity-chats-latest.tar.zst" \
      "${REMOTE_HOST}:${REMOTE_DIR}/antigravity-chats-latest.tar.zst.sha256" \
      "$TMP_ROOT/"
  fi

  log "Verifying SHA-256 checksum"
  (cd "$TMP_ROOT" && sha256sum -c "antigravity-chats-latest.tar.zst.sha256")

  log "Extracting archive to staging directory"
  zstd -dc "$archive_path" | tar -C "$unpack_dir" -xf -

  pre_backup=""
  if [[ "$is_dry_run" == "false" ]]; then
    local ts
    ts="$(date +%Y%m%d-%H%M%S)"
    if [[ -f "$target_home/.gemini/antigravity/conversation_summaries.db" || -f "$target_home/.config/Antigravity/app_storage.json" ]]; then
      pre_backup="$target_home/.gemini/antigravity-pre-restore-${ts}"
      mkdir -p "$pre_backup"
      for rel in \
        ".gemini/antigravity/conversation_summaries.db" \
        ".gemini/antigravity-cli/conversation_summaries.db" \
        ".gemini/config/config.json" \
        ".config/Antigravity/app_storage.json"; do
        if [[ -f "$target_home/$rel" ]]; then
          mkdir -p "$pre_backup/$(dirname "$rel")"
          cp -a "$target_home/$rel" "$pre_backup/$rel"
        fi
      done
      echo "  Saved pre-existing local index/config files to $pre_backup"
    fi

    # Clear stale SQLite WAL/SHM files so restored single-file snapshots open cleanly
    rm -f \
      "$target_home/.gemini/antigravity/conversation_summaries.db-wal" \
      "$target_home/.gemini/antigravity/conversation_summaries.db-shm" \
      "$target_home/.gemini/antigravity/conversations/"*.db-wal \
      "$target_home/.gemini/antigravity/conversations/"*.db-shm \
      "$target_home/.gemini/antigravity-cli/conversation_summaries.db-wal" \
      "$target_home/.gemini/antigravity-cli/conversation_summaries.db-shm" \
      "$target_home/.gemini/antigravity-cli/conversations/"*.db-wal \
      "$target_home/.gemini/antigravity-cli/conversations/"*.db-shm 2>/dev/null || true
  fi

  log "Installing conversations into $target_home"
  rm -f "$unpack_dir/.antigravity-backup-manifest.json"
  cp -a "$unpack_dir/." "$target_home/"

  log "Merging any pre-existing local state and verifying SQLite integrity"
  TARGET_HOME="$target_home" PRE_BACKUP="$pre_backup" python3 - <<'PY'
import json
import os
import pathlib
import sqlite3

target = pathlib.Path(os.environ["TARGET_HOME"])
pre_str = os.environ.get("PRE_BACKUP", "")
pre = pathlib.Path(pre_str) if pre_str else None

# If Omarchy already had local conversations before restore, preserve their summary rows too.
if pre and pre.exists():
    for rel in [
        ".gemini/antigravity/conversation_summaries.db",
        ".gemini/antigravity-cli/conversation_summaries.db",
    ]:
        prev_db = pre / rel
        curr_db = target / rel
        if prev_db.is_file() and curr_db.is_file():
            con = sqlite3.connect(str(curr_db))
            con.execute("ATTACH DATABASE ? AS prev", (str(prev_db),))
            with con:
                con.execute(
                    "INSERT OR IGNORE INTO main.conversation_summaries SELECT * FROM prev.conversation_summaries"
                )
                con.execute(
                    "INSERT OR IGNORE INTO main.conversation_parents SELECT * FROM prev.conversation_parents"
                )
            con.execute("DETACH DATABASE prev")
            con.close()

    # Merge app_storage.json so fresh Omarchy onboarding/window keys remain while conversation layouts return.
    prev_app = pre / ".config/Antigravity/app_storage.json"
    curr_app = target / ".config/Antigravity/app_storage.json"
    if prev_app.is_file() and curr_app.is_file():
        try:
            restored_data = json.loads(curr_app.read_text())
            local_data = json.loads(prev_app.read_text())
            merged = {**restored_data, **local_data}
            for k, v in restored_data.items():
                if k.startswith("antigravity-multi-conversation-layout-") or k in ("projectsOrder", "comments"):
                    merged[k] = v
            curr_app.write_text(json.dumps(merged, indent=2) + "\n")
        except Exception as exc:
            print(f"  [warn] Could not merge app_storage.json: {exc}")

checked = 0
for pattern in [
    ".gemini/antigravity/conversation_summaries.db",
    ".gemini/antigravity/conversations/*.db",
    ".gemini/antigravity-cli/conversation_summaries.db",
    ".gemini/antigravity-cli/conversations/*.db",
]:
    for db_file in sorted(target.glob(pattern)):
        con = sqlite3.connect(f"file:{db_file}?mode=ro", uri=True)
        chk = con.execute("PRAGMA quick_check;").fetchone()[0]
        con.close()
        if chk != "ok":
            raise RuntimeError(f"Corrupt DB after restore: {db_file}: {chk}")
        checked += 1

gui_cnt = len(list((target / ".gemini/antigravity/conversations").glob("*.db")))
cli_cnt = len(list((target / ".gemini/antigravity-cli/conversations").glob("*.db")))
print(f"  Verified {checked} SQLite files OK ({gui_cnt} Desktop chats, {cli_cnt} CLI chats).")
PY

  log "Restore complete!"
}

case "$MODE" in
  backup)
    do_backup
    ;;
  restore)
    do_restore "$HOME" "false"
    ;;
  dry-run-restore)
    do_restore "$DRY_RUN_DIR" "true"
    ;;
esac
