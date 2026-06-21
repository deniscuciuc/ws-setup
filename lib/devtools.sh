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
    nvm use "$NODE_VERSION" >/dev/null 2>&1 || true
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

  if [ -d "$HOME/.nvm/versions/node/${NODE_VERSION}" ]; then
    local current
    current="$(with_nvm nvm current 2>/dev/null)"
    if [ "$current" = "$NODE_VERSION" ]; then
      echo "  -> Node ${NODE_VERSION} already installed and default"
      return 0
    fi
  fi

  with_nvm nvm install "$NODE_VERSION"
  with_nvm nvm use "$NODE_VERSION"
  with_nvm nvm alias default "$NODE_VERSION"

  echo "==> Node ${NODE_VERSION} installed"
}

install_pnpm() {
  if with_nvm corepack pnpm --version 2>/dev/null | grep -qx "$PNPM_VERSION"; then
    echo "  -> pnpm ${PNPM_VERSION} already active"
    return 0
  fi

  echo "==> Installing corepack ${COREPACK_VERSION} and pnpm ${PNPM_VERSION}"
  with_nvm npm install -g "corepack@${COREPACK_VERSION}"
  with_nvm corepack enable
  with_nvm corepack prepare "pnpm@${PNPM_VERSION}" --activate
  echo "==> pnpm ${PNPM_VERSION} installed"
}

npm_package_is_installed() {
  local name="$1"
  local version="$2"
  local output
  output="$(with_nvm npm list -g --depth=0 "$name" 2>/dev/null)" || return 1
  echo "$output" | grep -Fq "${name}@${version}"
}

install_npm_global() {
  local package_spec="$1"
  local package_name="${package_spec%@*}"
  local package_version="${package_spec##*@}"

  if npm_package_is_installed "$package_name" "$package_version"; then
    echo "  -> ${package_spec} already installed"
    return 0
  fi

  echo "==> Installing ${package_spec}"
  with_nvm npm install -g "$package_spec"
}

install_gh_copilot_extension() {
  echo "==> Installing gh copilot extension"

  if ! command -v gh >/dev/null 2>&1; then
    echo "ERROR: gh CLI is required but not installed" >&2
    return 1
  fi

  local installed_version
  installed_version="$(gh extension list 2>/dev/null | awk '/github\/gh-copilot/ {print $3}')" || true

  if [ "$installed_version" = "$GH_COPILOT_EXTENSION_VERSION" ]; then
    echo "  -> gh copilot extension ${GH_COPILOT_EXTENSION_VERSION} already installed"
    return 0
  fi

  [ -n "$installed_version" ] && gh extension remove github/gh-copilot
  gh extension install github/gh-copilot --pin "$GH_COPILOT_EXTENSION_VERSION"
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
