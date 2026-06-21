#!/usr/bin/env bash
set -euo pipefail

install_nvm() {
  echo "==> Installing nvm"
  if [ -f "$HOME/.nvm/nvm.sh" ]; then
    echo "  -> nvm already installed"
    return 0
  fi

  curl -fsSL https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.3/install.sh | bash

  # Run nvm/node setup in a subshell because nvm scripts reference
  # optional/unbound variables that would fail under 'set -u'.
  (
    set +u
    export NVM_DIR="$HOME/.nvm"
    # shellcheck source=/dev/null
    [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
    nvm install --lts
    nvm use --lts
    nvm alias default lts/*
  )

  echo "==> nvm installed"
}

install_pyenv() {
  echo "==> Installing pyenv"
  if command -v pyenv >/dev/null 2>&1; then
    echo "  -> pyenv already installed"
    return 0
  fi

  curl -fsSL https://pyenv.run | bash
  echo "==> pyenv installed"
}

install_dotnet() {
  echo "==> Installing .NET SDK"
  if command -v dotnet >/dev/null 2>&1; then
    echo "  -> dotnet already installed"
    return 0
  fi

  mkdir -p "$HOME/.dotnet"
  curl -fsSL https://dot.net/v1/dotnet-install.sh | bash /dev/stdin --channel 10.0 --install-dir "$HOME/.dotnet"
  echo "==> .NET SDK installed"
}

install_devtools() {
  install_nvm
  install_pyenv
  install_dotnet
}
