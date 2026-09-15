#!/usr/bin/env bash
# Focused package integration test; the complete apps module also needs Snap.
set -Eeuo pipefail
[[ ${WS_DISPOSABLE_TEST:-} == 1 ]] || {
  echo 'Use a disposable Ubuntu test environment.' >&2
  exit 1
}
REPO_ROOT=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
export ACTION=install
STATE_DIR="$HOME/.local/state/ws-setup"
CACHE_DIR="$HOME/.cache/ws-setup"
export RUN_ID=extra-gui-test
for component in common assets repositories; do
  # shellcheck source=/dev/null
  source "$REPO_ROOT/lib/$component.sh"
done
mkdir -p "$STATE_DIR/reports" "$CACHE_DIR"
add_repository onlyoffice https://download.onlyoffice.com/repo/debian squeeze main
sudo apt-get update
apt_packages onlyoffice-desktopeditors gnome-disk-utility baobab xvfb x11-utils
install_asset gitkraken
install_asset discord
