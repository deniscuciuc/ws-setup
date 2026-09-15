#!/usr/bin/env bash
set -Eeuo pipefail
[[ $(uname -s) == Linux && -r /etc/os-release ]] || {
  echo 'Ubuntu 26.04 required' >&2
  exit 1
}
# shellcheck source=/dev/null
source /etc/os-release
[[ $ID == ubuntu && $VERSION_ID == 26.04 && $(uname -m) == x86_64 && $EUID != 0 ]] || {
  echo 'Run as a normal user on Ubuntu 26.04 x86_64.' >&2
  exit 1
}
TARGET_DIR=${WS_SETUP_DIR:-$HOME/.local/share/ws-setup}
REPO_URL=https://github.com/deniscuciuc/ws-setup.git
REF=${WS_SETUP_REF:-main}
# Preview/diagnostics must never install dependencies or fetch Git repositories.
if [[ ${1:-} == plan || ${1:-} == doctor ]]; then
  [[ -f $TARGET_DIR/setup.sh ]] || {
    echo 'Clone the repository first for read-only commands.' >&2
    exit 1
  }
  exec bash "$TARGET_DIR/setup.sh" "$@"
fi
sudo -v
sudo apt-get update
sudo apt-get --yes --no-remove install git curl ca-certificates
if [[ -d $TARGET_DIR/.git ]]; then
  [[ -z $(git -C "$TARGET_DIR" status --porcelain) ]] || {
    echo 'Setup checkout has local changes; use ./setup.sh directly.' >&2
    exit 1
  }
  [[ $(git -C "$TARGET_DIR" remote get-url origin) == "$REPO_URL" ]] || {
    echo 'Unexpected setup origin; use the local checkout directly.' >&2
    exit 1
  }
  [[ $(git -C "$TARGET_DIR" branch --show-current) == "$REF" ]] || {
    echo 'Checkout is on a different ref; refusing to switch it.' >&2
    exit 1
  }
  git -C "$TARGET_DIR" pull --ff-only origin "$REF"
elif [[ -e $TARGET_DIR ]]; then
  echo "Destination already exists: $TARGET_DIR" >&2
  exit 1
else
  mkdir -p "$(dirname "$TARGET_DIR")"
  git clone --branch "$REF" "$REPO_URL" "$TARGET_DIR"
fi
exec bash "$TARGET_DIR/setup.sh" "$@"
