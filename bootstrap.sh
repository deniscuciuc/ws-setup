#!/usr/bin/env bash
set -euo pipefail

REPO_URL="https://github.com/deniscuciuc/ws-setup.git"
TARGET_DIR="${HOME}/.local/share/ws-setup"

ensure_sudo() {
  # Check if sudo credentials are already cached
  if sudo -n true 2>/dev/null; then
    return 0
  fi

  echo "==> sudo password required" >&2

  if [ ! -r /dev/tty ] || [ ! -w /dev/tty ]; then
    echo "ERROR: No TTY available to read sudo password." >&2
    echo "Please run 'sudo -v' first to cache credentials, then re-run this script." >&2
    exit 1
  fi

  # Read password without echo, even when stdin is a pipe
  local password
  stty -echo </dev/tty
  printf "Password: " >/dev/tty
  read -r password </dev/tty
  stty echo </dev/tty
  echo >/dev/tty

  echo "$password" | sudo -S -v
}

ensure_dependency() {
  local cmd="$1"
  local pkg="${2:-$1}"
  if ! command -v "$cmd" >/dev/null 2>&1; then
    echo "Installing $pkg..."
    sudo apt-get install -y "$pkg"
  fi
}

echo "==> Bootstrapping workstation setup"

# Cache sudo credentials first so subsequent sudo calls and Ansible don't prompt
ensure_sudo

# Update apt cache once before checking for dependencies
if ! command -v ansible >/dev/null 2>&1 || ! command -v git >/dev/null 2>&1 || ! command -v curl >/dev/null 2>&1 || ! command -v python3 >/dev/null 2>&1; then
  sudo apt-get update
fi

ensure_dependency git git
ensure_dependency curl curl
ensure_dependency python3 python3
ensure_dependency ansible ansible
ensure_dependency add-apt-repository software-properties-common

if [ -d "$TARGET_DIR/.git" ]; then
  echo "==> Updating existing ws-setup repo"
  git -C "$TARGET_DIR" pull --ff-only
else
  echo "==> Cloning ws-setup repo"
  mkdir -p "$(dirname "$TARGET_DIR")"
  git clone "$REPO_URL" "$TARGET_DIR"
fi

cd "$TARGET_DIR"
echo "==> Running Ansible playbook"
ansible-playbook -i inventory/localhost.yml playbook.yml

echo "==> Done"
