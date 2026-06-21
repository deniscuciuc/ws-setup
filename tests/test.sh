#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/.."

# Ensure locally installed tools (e.g. chezmoi) are on PATH for validation.
export PATH="$HOME/.local/bin:$PATH"

# The Dockerfile already installs ansible, but bootstrap.sh should also handle a clean system.
# Here we run the playbook directly to test the ansible logic.
# Snap installs and desktop packages are skipped inside Docker because snapd
# and a full desktop environment are not available/needed in a container.
ansible-playbook -i inventory/localhost.yml playbook.yml \
  -e run_snap_installs=false \
  -e install_desktop_packages=false

# Validate
./scripts/validate.sh
