#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

generate_checklist() {
  echo "==> Generating post-provisioning checklist"

  mkdir -p "$HOME/Desktop"
  cp "$REPO_ROOT/docs/SETUP_CHECKLIST.md" "$HOME/Desktop/SETUP_CHECKLIST.md"

  echo ""
  echo "Provisioning complete."
  echo "Please open ~/Desktop/SETUP_CHECKLIST.md and complete the manual steps."
}
