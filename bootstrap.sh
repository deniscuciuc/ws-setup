#!/usr/bin/env bash
set -euo pipefail

REPO_URL="https://github.com/deniscuciuc/ws-setup.git"
TARGET_DIR="${HOME}/.local/share/ws-setup"

# Allow password to be supplied via environment for non-interactive use.
# Otherwise, prompt once and use it for both local sudo and Ansible become.
SUDO_PASSWORD="${SUDO_PASSWORD:-}"

read_sudo_password() {
  if [ -n "$SUDO_PASSWORD" ]; then
    return 0
  fi

  if [ ! -r /dev/tty ] || [ ! -w /dev/tty ]; then
    echo "ERROR: No TTY available to read sudo password." >&2
    echo "Set SUDO_PASSWORD in the environment, or run 'sudo -v' first." >&2
    exit 1
  fi

  stty -echo </dev/tty
  printf "sudo password: " >/dev/tty
  read -r SUDO_PASSWORD </dev/tty
  stty echo </dev/tty
  echo >/dev/tty
}

run_sudo() {
  if [ -n "$SUDO_PASSWORD" ]; then
    echo "$SUDO_PASSWORD" | sudo -S "$@"
  else
    sudo "$@"
  fi
}

ensure_dependency() {
  local cmd="$1"
  local pkg="${2:-$1}"
  if ! command -v "$cmd" >/dev/null 2>&1; then
    echo "Installing $pkg..."
    run_sudo apt-get install -y "$pkg"
  fi
}

echo "==> Bootstrapping workstation setup"

# Obtain sudo password up front so Ansible can become root without prompting
read_sudo_password

# Update apt cache once before checking for dependencies
if ! command -v ansible >/dev/null 2>&1 || ! command -v git >/dev/null 2>&1 || ! command -v curl >/dev/null 2>&1 || ! command -v python3 >/dev/null 2>&1; then
  run_sudo apt-get update
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

export ANSIBLE_BECOME_PASS="$SUDO_PASSWORD"
ansible-playbook -i inventory/localhost.yml playbook.yml

echo "==> Done"
