#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

install_snaps() {
  if ! command -v snap >/dev/null 2>&1; then
    echo "==> snap not available, skipping snap installs"
    return 0
  fi

  echo "==> Waiting for snapd seeding"
  sudo snap wait system seed.loaded || true

  echo "==> Installing snap packages"
  grep -v '^#' "$REPO_ROOT/packages/snap.txt" | grep -v '^$' | while read -r line; do
    name="$(echo "$line" | awk '{print $1}')"
    classic="$(echo "$line" | awk '{print $2}')"

    if [ -z "$name" ]; then
      continue
    fi

    if snap list "$name" >/dev/null 2>&1; then
      echo "  -> $name already installed"
      continue
    fi

    if [ "$classic" = "classic" ]; then
      echo "  -> $name (classic)"
      sudo snap install "$name" --classic || echo "    WARNING: failed to install $name"
    else
      echo "  -> $name"
      sudo snap install "$name" || echo "    WARNING: failed to install $name"
    fi
  done

  echo "==> snap packages installed"
}
