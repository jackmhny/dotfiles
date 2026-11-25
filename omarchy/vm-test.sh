#!/usr/bin/env bash
set -euo pipefail

# Spin up an Omarchy v4.5.0 QEMU/KVM + OVMF test VM before touching nvme1n1.
# Inspired by the QEMU + Omarchy ISO dry-run workflow: test install, bindings.lua,
# and bootstrap.sh safely with SSH forwarding on localhost:2222 and QMP control.
#
# Usage:
#   ./vm-test.sh download   # Download + SHA256-verify latest Omarchy ISO
#   ./vm-test.sh install    # Boot VM from ISO to install onto qcow2 disk
#   ./vm-test.sh boot       # Boot installed Omarchy qcow2 disk (no ISO)
#   ./vm-test.sh ssh        # SSH into running VM (port 2222)
#   ./vm-test.sh reset      # Delete VM qcow2 disk + OVMF vars (keeps cached ISO)

VM_DIR="${OMARCHY_VM_DIR:-$HOME/Documents/OmarchyMigration/vm}"
DISK="$VM_DIR/omarchy-test.qcow2"
OVMF_CODE="/usr/share/OVMF/OVMF_CODE_4M.fd"
OVMF_VARS_TMPL="/usr/share/OVMF/OVMF_VARS_4M.fd"
OVMF_VARS="$VM_DIR/OVMF_VARS_4M.fd"
QMP_SOCK="$VM_DIR/qmp.sock"
SSH_PORT="${OMARCHY_VM_SSH_PORT:-2222}"
RAM="${OMARCHY_VM_RAM:-8G}"
CPUS="${OMARCHY_VM_CPUS:-4}"
DISK_SIZE="${OMARCHY_VM_DISK_SIZE:-32G}"

mkdir -p "$VM_DIR"

find_iso() {
  local iso
  iso="$(ls -t "$VM_DIR"/omarchy-*-x86.iso 2>/dev/null | head -n1 || true)"
  if [[ -z "$iso" ]]; then
    echo "No Omarchy ISO found in $VM_DIR. Run: $0 download" >&2
    exit 1
  fi
  echo "$iso"
}

cmd_download() {
  local version iso
  version="$(curl -fsSL https://api.github.com/repos/omacom/omarchy/releases/latest | python3 -c 'import sys,json; print(json.load(sys.stdin)["tag_name"].lstrip("v"))')"
  iso="omarchy-${version}-x86.iso"
  echo "==> Fetching $iso into $VM_DIR"
  (
    cd "$VM_DIR"
    curl -fLC - -o "$iso" "https://iso.omarchy.org/$iso"
    curl -fsSLO "https://iso.omarchy.org/$iso.sha256"
    sha256sum -c "$iso.sha256"
  )
  echo "==> Verified: $VM_DIR/$iso"
}

ensure_vm_files() {
  if [[ ! -f "$DISK" ]]; then
    echo "==> Creating sparse $DISK_SIZE disk at $DISK"
    qemu-img create -f qcow2 "$DISK" "$DISK_SIZE"
  fi
  if [[ ! -f "$OVMF_VARS" ]]; then
    cp "$OVMF_VARS_TMPL" "$OVMF_VARS"
  fi
}

run_qemu() {
  local extra_args=("$@")
  ensure_vm_files
  rm -f "$QMP_SOCK"
  echo "==> Launching QEMU/KVM ($CPUS vCPUs, $RAM RAM, SSH fwd -> 127.0.0.1:$SSH_PORT, QMP -> $QMP_SOCK)"
  exec qemu-system-x86_64 \
    -enable-kvm \
    -machine q35,accel=kvm \
    -cpu host \
    -smp "$CPUS" \
    -m "$RAM" \
    -drive "if=pflash,format=raw,readonly=on,file=$OVMF_CODE" \
    -drive "if=pflash,format=raw,file=$OVMF_VARS" \
    -drive "file=$DISK,if=virtio,format=qcow2,cache=writeback" \
    -device virtio-vga,xres=1920,yres=1080 \
    -display gtk,zoom-to-fit=on \
    -device virtio-rng-pci \
    -serial "file:$VM_DIR/serial.log" \
    -nic "user,model=virtio-net-pci,hostfwd=tcp:127.0.0.1:${SSH_PORT}-:22" \
    -qmp "unix:$QMP_SOCK,server=on,wait=off" \
    -device qemu-xhci \
    -device usb-tablet \
    "${extra_args[@]}"
}

case "${1:-}" in
  download)
    cmd_download
    ;;
  install)
    ISO="$(find_iso)"
    run_qemu -cdrom "$ISO" -boot order=d
    ;;
  boot)
    run_qemu -boot order=c
    ;;
  ssh)
    exec ssh -p "$SSH_PORT" -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null "${2:-jackmhny}@127.0.0.1"
    ;;
  reset)
    rm -f "$DISK" "$OVMF_VARS" "$QMP_SOCK"
    echo "==> Reset VM disk and UEFI vars (ISO kept in $VM_DIR)"
    ;;
  *)
    echo "Usage: $0 {download|install|boot|ssh [user]|reset}" >&2
    exit 1
    ;;
esac
