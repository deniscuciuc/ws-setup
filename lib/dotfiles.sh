#!/usr/bin/env bash
set -euo pipefail

DOTFILES_REPO="deniscuciuc"
CHEZMOI_BIN_DIR="$HOME/.local/bin"

apply_dotfiles() {
  echo "==> Installing chezmoi"
  mkdir -p "$CHEZMOI_BIN_DIR"

  if ! command -v chezmoi >/dev/null 2>&1; then
    sh -c "$(curl -fsLS https://get.chezmoi.io)" -- -b "$CHEZMOI_BIN_DIR"
  fi

  echo "==> Applying dotfiles from $DOTFILES_REPO"
  if [ -d "$HOME/.local/share/chezmoi/.git" ]; then
    "$CHEZMOI_BIN_DIR/chezmoi" update --apply
  else
    "$CHEZMOI_BIN_DIR/chezmoi" init --apply "$DOTFILES_REPO"
  fi

  echo "==> Dotfiles applied"
}
