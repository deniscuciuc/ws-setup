#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

install_apt_packages() {
  echo "==> Updating apt cache"
  sudo apt-get update

  echo "==> Installing Docker apt repository prerequisites"
  sudo apt-get install -y ca-certificates curl gnupg

  echo "==> Adding Docker official GPG key and repository"
  sudo install -m 0755 -d /etc/apt/keyrings
  curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
  sudo chmod a+r /etc/apt/keyrings/docker.gpg
  echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | sudo tee /etc/apt/sources.list.d/docker.list >/dev/null

  echo "==> Updating apt cache after adding Docker repository"
  sudo apt-get update

  echo "==> Installing apt packages"
  grep -v '^#' "$REPO_ROOT/packages/apt.txt" | grep -v '^$' | while read -r pkg; do
    if [ "${WS_SETUP_SKIP_DESKTOP:-}" = "1" ] && \
       { [ "$pkg" = "ubuntu-desktop" ] || [ "$pkg" = "ubuntu-desktop-minimal" ] || [ "$pkg" = "ubuntu-restricted-addons" ] || [ "$pkg" = "libreoffice-help-en-us" ] || [ "$pkg" = "libreoffice-l10n-en-us" ] || [ "$pkg" = "thunderbird-locale-en-us" ]; }; then
      echo "  -> skipping $pkg (desktop package skipped in container)"
      continue
    fi

    echo "  -> $pkg"
    sudo apt-get install -y "$pkg" || echo "    WARNING: failed to install $pkg"
  done

  echo "==> apt packages installed"
}

configure_docker_group() {
  echo "==> Adding user to the docker group"
  local current_user
  current_user="$(whoami)"

  if getent group docker >/dev/null 2>&1; then
    if getent group docker | cut -d: -f4 | tr ',' '\n' | grep -qx "$current_user"; then
      echo "  -> user already in docker group"
    else
      sudo usermod -aG docker "$current_user"
      echo "  -> added $current_user to docker group (log out and back in for it to take effect)"
    fi
  else
    echo "  -> WARNING: docker group not found, skipping"
  fi
}
