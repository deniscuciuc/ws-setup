#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=versions.sh
source "$SCRIPT_DIR/versions.sh"

# Run a command with nvm loaded in a subshell.
# nvm scripts reference optional/unbound variables, so we temporarily disable 'set -u'.
with_nvm() {
  (
    set +u
    export NVM_DIR="$HOME/.nvm"
    # shellcheck source=/dev/null
    [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
    "$@"
  )
}

install_node() {
  echo "==> Installing nvm and Node ${NODE_VERSION}"

  if [ -d "$HOME/.nvm" ]; then
    echo "  -> nvm already installed"
  else
    curl -fsSL "https://raw.githubusercontent.com/nvm-sh/nvm/${NVM_INSTALL_VERSION}/install.sh" | bash
  fi

  with_nvm nvm install "$NODE_VERSION"
  with_nvm nvm use "$NODE_VERSION"
  with_nvm nvm alias default "$NODE_VERSION"

  echo "==> Node ${NODE_VERSION} installed"
}

install_pnpm() {
  echo "==> Enabling corepack and installing pnpm ${PNPM_VERSION}"
  with_nvm corepack enable
  with_nvm corepack prepare "pnpm@${PNPM_VERSION}" --activate
  echo "==> pnpm ${PNPM_VERSION} installed"
}

install_npm_global() {
  local package_spec="$1"
  echo "==> Installing ${package_spec}"
  with_nvm npm install -g "$package_spec"
}

install_gh_copilot_extension() {
  echo "==> Installing gh copilot extension"
  if gh extension list 2>/dev/null | grep -q 'gh-copilot'; then
    echo "  -> gh copilot extension already installed"
  else
    gh extension install github/gh-copilot --pin "$GH_COPILOT_VERSION"
  fi
  echo "==> gh copilot extension installed"
}

install_github_copilot_cli() {
  install_npm_global "@githubnext/github-copilot-cli@${GITHUB_COPILOT_CLI_VERSION}"
}

install_claude_code() {
  install_npm_global "@anthropic-ai/claude-code@${CLAUDE_CODE_VERSION}"
}

install_codex() {
  install_npm_global "@openai/codex@${CODEX_VERSION}"
}

install_kimi_code() {
  install_npm_global "@moonshot-ai/kimi-code@${KIMI_CODE_VERSION}"
}

install_devtools() {
  install_node
  install_pnpm
  install_gh_copilot_extension
  install_github_copilot_cli
  install_claude_code
  install_codex
  install_kimi_code
}
