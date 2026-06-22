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
  # Use absolute paths in TryExec/Exec so it works even when ~/.local/bin is not
  # on PATH in the GNOME session.
  mkdir -p "$HOME/.local/share/applications"
  local kitty_desktop="$HOME/.local/share/applications/kitty.desktop"
  if [ -L "$kitty_desktop" ]; then
    rm "$kitty_desktop"
  fi
  cat > "$kitty_desktop" <<EOF
[Desktop Entry]
Version=1.0
Type=Application
Name=kitty
GenericName=Terminal emulator
Comment=Fast, feature-rich, GPU based terminal
TryExec=$HOME/.local/kitty.app/bin/kitty
StartupNotify=true
Exec=$HOME/.local/kitty.app/bin/kitty
Icon=$HOME/.local/kitty.app/share/icons/hicolor/256x256/apps/kitty.png
Categories=System;TerminalEmulator;
X-TerminalArgExec=--
X-TerminalArgTitle=--title
X-TerminalArgAppId=--class
X-TerminalArgDir=--working-directory
X-TerminalArgHold=--hold
EOF

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

  _write_terminal_list() {
    local file="$1"
    if [ -f "$file" ] && [ "$(head -n 1 "$file")" = "kitty.desktop" ]; then
      return 0
    fi
    printf '%s\n' "kitty.desktop" > "$file"
  }

  # Prefer the Ubuntu-specific list, with fallbacks for plain GNOME/other DEs.
  _write_terminal_list "$HOME/.config/ubuntu-xdg-terminals.list"
  _write_terminal_list "$HOME/.config/gnome-xdg-terminals.list"
  _write_terminal_list "$HOME/.config/xdg-terminals.list"

  echo "  -> kitty set as default terminal (log out/in to take full effect)"
}

install_kitty_env() {
  install_kitty
  set_kitty_as_default_terminal
}
