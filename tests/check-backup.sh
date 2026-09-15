#!/usr/bin/env bash
# Run inside a disposable privileged test environment (uses tmpfs as external disk).
set -euo pipefail
[[ $EUID != 0 ]] || {
  echo 'Run as a normal test user with sudo.' >&2
  exit 2
}
root=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
source_dir=${DOTFILES_SOURCE:-/dotfiles}
work=$(mktemp -d /tmp/ws-backup-smoke.XXXXXX)
cleanup() {
  local code=$?
  trap - EXIT
  if mountpoint -q "$work/disk"; then sudo umount "$work/disk"; fi
  [[ $work == /tmp/ws-backup-smoke.* ]] && rm -rf -- "$work"
  exit "$code"
}
trap cleanup EXIT
mkdir "$work/disk" "$work/data"
sudo mount -t tmpfs -o "size=64m,uid=$(id -u),gid=$(id -g),mode=700" tmpfs "$work/disk"
printf 'restore-me\n' >"$work/data/proof"
printf 'smoke-test-only-password\n' >"$work/password"
printf '%s\n' "$work/data" >"$work/targets"
touch "$work/excludes"
cat >"$work/backup.conf" <<EOF
BACKUP_MOUNT='$work/disk'
RESTIC_REPOSITORY='$work/disk/repository'
RESTIC_PASSWORD_FILE='$work/password'
BACKUP_TARGETS_FILE='$work/targets'
BACKUP_EXCLUDES_FILE='$work/excludes'
EOF
export WS_BACKUP_CONFIG="$work/backup.conf"
tool="$source_dir/dot_local/bin/executable_ws-backup"
bash "$tool" init
(
  cd /
  bash "$tool" backup
)
bash "$tool" check
bash "$tool" restore latest "$work/restored"
cmp "$work/data/proof" "$work/restored$work/data/proof"
sudo umount "$work/disk"
if bash "$tool" backup; then
  echo 'Unmounted backup unexpectedly succeeded.' >&2
  exit 1
fi
printf 'Encrypted backup, integrity check, restore and missing-disk protection passed (%s).\n' "$root"
