#!/usr/bin/env bash
set -euo pipefail

ERRORS=0

check_command() {
  if command -v "$1" >/dev/null 2>&1; then
    echo "[OK] $1 found"
  else
    echo "[FAIL] $1 not found"
    ERRORS=$((ERRORS + 1))
  fi
}

check_package() {
  if dpkg-query -W -f='${Status}' "$1" 2>/dev/null | grep -q "install ok installed"; then
    echo "[OK] apt package $1 installed"
  else
    echo "[FAIL] apt package $1 not installed"
    ERRORS=$((ERRORS + 1))
  fi
}

check_snap() {
  if snap list "$1" >/dev/null 2>&1; then
    echo "[OK] snap $1 installed"
  else
    echo "[FAIL] snap $1 not installed"
    ERRORS=$((ERRORS + 1))
  fi
}

check_command zsh
check_command git
check_command chezmoi
check_command nvim
check_command batcat
check_command fdfind
check_command rg
check_command fzf
check_command node
check_command npm
check_command pnpm
check_command dotnet
check_command gh
check_command claude
check_command codex
check_command kimi

check_package zsh
check_package git
check_package neovim
check_package bat

if command -v snap >/dev/null 2>&1; then
  check_snap code
  check_snap firefox
else
  echo "[SKIP] snap not available, skipping snap package checks"
fi

if chezmoi source-path >/dev/null 2>&1; then
  echo "[OK] chezmoi source path resolved"
else
  echo "[FAIL] chezmoi source path not resolved"
  ERRORS=$((ERRORS + 1))
fi

if chezmoi diff >/dev/null 2>&1; then
  echo "[OK] chezmoi diff command succeeded"
else
  echo "[FAIL] chezmoi diff command failed"
  ERRORS=$((ERRORS + 1))
fi

if [ -f "$HOME/.config/kitty/kitty.conf" ]; then
  echo "[OK] kitty config present"
else
  echo "[FAIL] kitty config missing"
  ERRORS=$((ERRORS + 1))
fi

if [ -f "$HOME/.config/nvim/init.lua" ]; then
  echo "[OK] neovim config present"
else
  echo "[FAIL] neovim config missing"
  ERRORS=$((ERRORS + 1))
fi

if [ "$ERRORS" -eq 0 ]; then
  echo "All validation checks passed."
  exit 0
else
  echo "$ERRORS validation check(s) failed."
  exit 1
fi
