#!/usr/bin/env bash
set -euo pipefail

# shellcheck source=/dev/null
source "$(dirname "${BASH_SOURCE[0]}")/versions.sh"

install_kitty() {
  echo "==> Installing kitty"

  local current_version=""
  if [ -x "$HOME/.local/kitty.app/bin/kitty" ]; then
    current_version="$("$HOME/.local/kitty.app/bin/kitty" --version | awk '{print $2}')"
  fi

  if [ "$current_version" = "$KITTY_VERSION" ]; then
    echo "  -> kitty $KITTY_VERSION already installed"
  else
    echo "  -> Downloading kitty $KITTY_VERSION"
    curl -fsSL https://sw.kovidgoyal.net/kitty/installer.sh |
      sh -s "installer=version-${KITTY_VERSION}" "launch=n" "dest=~/.local"
  fi

  # Make kitty available on PATH for the desktop file / default terminal launcher.
  mkdir -p "$HOME/.local/bin"
  if [ ! -e "$HOME/.local/bin/kitty" ]; then
    ln -s "$HOME/.local/kitty.app/bin/kitty" "$HOME/.local/bin/kitty"
  fi

  # Expose the desktop entry so xdg-terminal-exec can find it.
  mkdir -p "$HOME/.local/share/applications"
  if [ ! -e "$HOME/.local/share/applications/kitty.desktop" ]; then
    ln -s "$HOME/.local/kitty.app/share/applications/kitty.desktop" \
          "$HOME/.local/share/applications/kitty.desktop"
  fi
  if [ ! -e "$HOME/.local/share/applications/kitty-open.desktop" ]; then
    ln -s "$HOME/.local/kitty.app/share/applications/kitty-open.desktop" \
          "$HOME/.local/share/applications/kitty-open.desktop"
  fi

  if command -v update-desktop-database >/dev/null 2>&1; then
    update-desktop-database "$HOME/.local/share/applications" >/dev/null 2>&1 || true
  fi
}

set_kitty_as_default_terminal() {
  echo "==> Setting kitty as the default terminal emulator"
  mkdir -p "$HOME/.config"

  local list_file="$HOME/.config/ubuntu-xdg-terminals.list"
  if [ -f "$list_file" ] && [ "$(head -n 1 "$list_file")" = "kitty.desktop" ]; then
    echo "  -> kitty already set as default terminal"
    return 0
  fi

  printf '%s\n' "kitty.desktop" > "$list_file"
  echo "  -> kitty set as default terminal (log out/in to take full effect)"
}

install_kitty_env() {
  install_kitty
  set_kitty_as_default_terminal
}
