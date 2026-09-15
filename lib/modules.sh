#!/usr/bin/env bash
install_base() {
  sudo apt-get update
  apt_manifest base
  install_asset chezmoi
  install_asset bw
  write_user_file "$HOME/.local/bin/ws-ssh-vault" 755 <"$REPO_ROOT/scripts/ssh-vault.py"
  pending 'Use bw login/unlock and docs/SSH_MIGRATION.md to migrate SSH keys; enable Bitwarden Desktop SSH Agent after signing in.'
  mkdir -p "$HOME/.local/bin"
  # Expose Debian's renamed binaries without replacing standard commands.
  if [[ ! -e $HOME/.local/bin/bat && ! -L $HOME/.local/bin/bat ]]; then ln -s /usr/bin/batcat "$HOME/.local/bin/bat"; fi
  if [[ ! -e $HOME/.local/bin/fd && ! -L $HOME/.local/bin/fd ]]; then ln -s /usr/bin/fdfind "$HOME/.local/bin/fd"; fi
  pending 'Restore SSH/GPG keys from your encrypted backup; sign in with gh auth login and glab auth login.'
}

install_shell() {
  [[ -r /usr/share/doc/fzf/examples/completion.bash && -r /usr/share/doc/fzf/examples/key-bindings.bash ]] || die 'fzf shell scripts are missing. Preserve /usr/share/doc/fzf/examples in dpkg exclusions, then reinstall fzf.'
  install_asset starship
  install_asset blesh
}

install_runtimes() {
  apt_packages "dotnet-sdk-$DOTNET_VERSION"
  install_asset mise
  install_asset uv
  # Global baseline is managed in dotfiles; installing does not trust project configs.
  mise install "node@$NODE_VERSION"
  if [[ $(mise exec "node@$NODE_VERSION" -- corepack --version 2>/dev/null || true) != "$COREPACK_VERSION" ]]; then
    mise exec "node@$NODE_VERSION" -- npm install --global "corepack@$COREPACK_VERSION"
  fi
  mise exec "node@$NODE_VERSION" -- corepack enable
  if [[ $(cd "$HOME" && mise exec "node@$NODE_VERSION" -- pnpm --version 2>/dev/null || true) != "$PNPM_VERSION" ]]; then
    mise exec "node@$NODE_VERSION" -- corepack install --global "pnpm@$PNPM_VERSION"
  fi
  mise reshim
  uv python install "$PYTHON_VERSION"
  pending 'In each project, respect global.json, mise.toml/.node-version, packageManager and .python-version; restore dependencies instead of copying caches.'
}

install_ai() {
  install_asset claude
  install_asset codex
  pending 'Run claude and codex once and complete their browser sign-ins. AI configuration is portable; credentials are not in Git.'
}

ensure_subids() {
  python3 "$REPO_ROOT/scripts/subids.py" "$(id -un)"
}

install_containers() {
  apt_manifest containers
  install_asset compose
  ensure_subids
  systemctl --user enable --now podman.socket
  podman info --format '{{.Host.Security.Rootless}}' | grep -qx true
  pending 'Log out and back in to import the Podman socket into desktop apps; then run scripts/smoke-containers.sh.'
}

install_database() {
  apt_manifest database
  install_asset mongosh
  install_asset sqlcmd
}

install_apps() {
  add_repository brave https://brave-browser-apt-release.s3.brave.com/ stable main
  add_repository vscode https://packages.microsoft.com/repos/code stable main
  add_repository claude-desktop https://downloads.claude.ai/claude-desktop/apt/stable stable main
  add_repository onlyoffice https://download.onlyoffice.com/repo/debian squeeze main
  steam_repository
  # Avoid a second vendor-created source entry using a differently named key.
  printf 'CLAUDE_DESKTOP_ADD_REPO="false"\n' | write_system_file /etc/default/claude-desktop
  echo 'code code/add-microsoft-repo boolean false' | sudo debconf-set-selections
  if ! dpkg --print-foreign-architectures | grep -qx i386; then sudo dpkg --add-architecture i386; fi
  sudo apt-get update
  # Valve's launcher includes the device rules and conflicts with Ubuntu's steam-devices.
  apt_manifest apps
  steam_repository
  install_asset chatgpt
  install_asset gitkraken
  install_asset discord
  pending 'Open ONLYOFFICE and verify a representative document, then follow docs/TOOLS.md to remove any preinstalled LibreOffice applications while retaining their settings.'
  pending 'Open GitKraken and Discord and complete their sign-ins.'
  if [[ $ACTION == update ]]; then apt_packages chatgpt; fi
  apt_packages snapd
  sudo systemctl enable --now snapd.socket
  timeout 180 sudo snap wait system seed.loaded
  local name
  while IFS= read -r name; do
    if snap list "$name" >/dev/null 2>&1; then
      if [[ $ACTION == update ]]; then timeout --foreground 1800 sudo snap refresh "$name" --channel=stable; fi
    elif [[ $ACTION == install ]]; then timeout --foreground 1800 sudo snap install "$name" --channel=stable; fi
  done < <(lines "$REPO_ROOT/packages/snap.txt")
  # Claude's default recommendations provide QEMU; KVM needs a new login.
  if getent group kvm >/dev/null; then
    if ! id -nG "$(id -un)" | tr ' ' '\n' | grep -qx kvm; then sudo usermod -aG kvm "$(id -un)"; fi
  fi
  # Brave is verified before removing the default browser package; keep profiles.
  if installed brave-browser; then
    if snap list firefox >/dev/null 2>&1; then sudo snap remove firefox; fi
  fi
  pending 'Sign in to Brave sync, Bitwarden, Todoist, Telegram, Spotify, Steam, Claude Desktop and ChatGPT. Linux AI desktops have preview limitations.'
  pending 'If using Claude Cowork, enable firmware virtualization and log in again for kvm group membership.'
}

install_database_gui() {
  add_repository dbeaver https://dbeaver.io/debs/dbeaver-ce / ''
  sudo apt-get update
  apt_manifest database-gui
  install_asset compass
  install_asset bruno
  pending 'Open DBeaver, Compass, RedisInsight and Bruno; import connection settings without committing passwords. Some vendors do not yet list Ubuntu 26.04 in their support matrix.'
}

install_tools() {
  add_repository cloudflared https://pkg.cloudflare.com/cloudflared any main
  echo 'iperf3 iperf3/start_daemon boolean false' | sudo debconf-set-selections
  sudo apt-get update
  apt_manifest tools
  install_asset tofu
  install_asset yq
  install_asset just
  pending 'Cloudflared is installed without creating a tunnel. Add Wrangler locally in each Workers project; see docs/TOOLS.md.'
}

install_devops() {
  apt_manifest devops
  install_asset sops
  install_asset trivy
  pending 'Configure SOPS recipients and Ansible inventories per project; keep age private keys outside Git.'
}

install_diagnostics() {
  echo 'wireshark-common wireshark-common/install-setuid boolean false' | sudo debconf-set-selections
  apt_manifest diagnostics
  pending 'Wireshark and TShark are installed without granting packet-capture privileges. See docs/TOOLS.md for capture setup.'
}
