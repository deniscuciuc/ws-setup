#!/usr/bin/env bash
# Sourcing this library makes no changes.
log() { printf '[%s] %s\n' "${MODULE:-setup}" "$*"; }
die() {
  printf 'ERROR: %s\n' "$*" >&2
  exit 1
}
lines() { sed 's/[[:space:]]*#.*$//; /^[[:space:]]*$/d' "$1"; }
installed() { dpkg-query -W -f='${Status}' "$1" 2>/dev/null | grep -qx 'install ok installed'; }
user_systemd() { [[ -d /run/systemd/system ]] && systemctl --user show-environment >/dev/null 2>&1; }
desktop_session() { [[ -n ${DISPLAY:-}${WAYLAND_DISPLAY:-} && -n ${DBUS_SESSION_BUS_ADDRESS:-} ]]; }

backup_file() {
  local target=$1 destination
  [[ -e $target || -L $target ]] || return 0
  destination="$STATE_DIR/backups/$RUN_ID/${target#/}"
  [[ ! -e $destination && ! -L $destination ]] || return 0
  mkdir -p "$(dirname "$destination")"
  cp -a -- "$target" "$destination"
}

write_user_file() {
  local target=$1 mode=${2:-644} staged
  mkdir -p "$(dirname "$target")"
  staged=$(mktemp "$(dirname "$target")/.ws-setup.XXXXXX")
  cat >"$staged"
  if [[ -f $target ]] && cmp -s "$target" "$staged"; then
    chmod "$mode" "$target"
    rm -f -- "$staged"
    return 0
  fi
  backup_file "$target"
  chmod "$mode" "$staged"
  mv -f -- "$staged" "$target"
}

write_system_file() {
  local target=$1 mode=${2:-644} staged
  staged=$(mktemp "$CACHE_DIR/system.XXXXXX")
  cat >"$staged"
  if sudo test -f "$target" && sudo cmp -s "$target" "$staged"; then
    rm -f -- "$staged"
    return 0
  fi
  if sudo test -e "$target"; then
    mkdir -p "$STATE_DIR/backups/$RUN_ID/system"
    sudo cp -a -- "$target" "$STATE_DIR/backups/$RUN_ID/system/${target//\//_}"
  fi
  sudo install -D -m "$mode" "$staged" "$target"
  rm -f -- "$staged"
}

download_verified() {
  local url=$1 sha=$2 destination=$3 staged
  [[ $url == https://* && $sha =~ ^[a-f0-9]{64}$ ]] || die 'Invalid locked URL or SHA-256'
  if [[ -f $destination ]] && printf '%s  %s\n' "$sha" "$destination" | sha256sum --check --status; then return 0; fi
  mkdir -p "$(dirname "$destination")"
  staged=$(mktemp "${destination}.XXXXXX")
  log "Downloading ${url##*/} (SHA-256 verified before installation)"
  if ! curl --silent --show-error --proto '=https' --tlsv1.2 --fail --location --retry 3 --connect-timeout 20 --output "$staged" "$url"; then
    rm -f -- "$staged"
    die "Download failed: $url"
  fi
  if ! printf '%s  %s\n' "$sha" "$staged" | sha256sum --check --status; then
    rm -f -- "$staged"
    die "Checksum mismatch: $url"
  fi
  mv -f -- "$staged" "$destination"
}

apt_packages() {
  local requested=() pkg
  for pkg in "$@"; do
    if [[ $ACTION == update ]] && ! installed "$pkg"; then continue; fi
    requested+=("$pkg")
  done
  ((${#requested[@]})) || return 0
  sudo env DEBIAN_FRONTEND=noninteractive apt-get --yes --no-remove install "${requested[@]}"
}

apt_manifest() {
  local packages=()
  mapfile -t packages < <(lines "$REPO_ROOT/packages/$1.txt")
  apt_packages "${packages[@]}"
}

pending() { printf '%s\n' "$*" >>"$STATE_DIR/reports/$RUN_ID.pending"; }
