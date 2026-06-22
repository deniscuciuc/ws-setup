#!/usr/bin/env bash
set -euo pipefail

# shellcheck source=/dev/null
source "$(dirname "${BASH_SOURCE[0]}")/versions.sh"

install_ohmyzsh() {
  echo "==> Installing Oh My Zsh"
  if [ -d "$HOME/.oh-my-zsh" ]; then
    echo "  -> Oh My Zsh already installed"
  else
    # Keep the chezmoi-managed .zshrc instead of replacing it with the OMZ template.
    RUNZSH=no CHSH=no KEEP_ZSHRC=yes sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
  fi
}

install_zsh_plugin() {
  local repo="$1"
  local name="$2"
  local target="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/$name"

  echo "  -> Installing zsh plugin $name"
  if [ -d "$target" ]; then
    echo "     $name already installed"
  else
    git clone --depth=1 "$repo" "$target"
  fi
}

install_zsh_plugins() {
  echo "==> Installing zsh plugins"
  install_zsh_plugin "https://github.com/zsh-users/zsh-autosuggestions" "zsh-autosuggestions"
  install_zsh_plugin "https://github.com/zsh-users/zsh-syntax-highlighting" "zsh-syntax-highlighting"
  install_zsh_plugin "https://github.com/zsh-users/zsh-history-substring-search" "zsh-history-substring-search"
  install_zsh_plugin "https://github.com/MichaelAquilina/zsh-you-should-use" "you-should-use"
}

install_starship() {
  echo "==> Installing starship"
  if command -v starship >/dev/null 2>&1; then
    echo "  -> starship already installed"
    return 0
  fi

  mkdir -p "$HOME/.local/bin"
  curl -fsSL https://starship.rs/install.sh | sh -s -- -y -v "v$STARSHIP_VERSION" -b "$HOME/.local/bin"
}

set_zsh_default() {
  echo "==> Setting zsh as the default login shell"
  local zsh_path
  zsh_path="$(command -v zsh)"

  local current_user
  current_user="$(whoami)"

  local current_shell
  current_shell="$(getent passwd "$current_user" | cut -d: -f7)"

  if [ "$current_shell" = "$zsh_path" ]; then
    echo "  -> zsh is already the default shell"
  else
    sudo chsh -s "$zsh_path" "$current_user"
    echo "  -> Default shell changed to zsh (log out and back in for it to take effect)"
  fi
}

enable_zsh_for_bash() {
  echo "==> Configuring bash to launch zsh for interactive shells"
  local bashrc="$HOME/.bashrc"
  local marker="# ws-setup: auto-switch to zsh"

  if [ -f "$bashrc" ] && grep -q "$marker" "$bashrc"; then
    echo "  -> .bashrc already switches to zsh"
    return 0
  fi

  {
    echo ""
    echo "$marker"
    echo "if [[ \$- == *i* ]] && [ -z \"\${ZSH_VERSION:-}\" ] && command -v zsh >/dev/null 2>&1; then"
    echo "  exec zsh -l"
    echo "fi"
  } >> "$bashrc"
  echo "  -> appended zsh launcher to .bashrc"
}

install_zsh() {
  install_ohmyzsh
  install_zsh_plugins
  install_starship
  set_zsh_default
  enable_zsh_for_bash
}
