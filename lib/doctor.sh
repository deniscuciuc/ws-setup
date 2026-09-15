#!/usr/bin/env bash
ok() { printf '[OK] %s\n' "$*"; }
bad() {
  printf '[FAIL] %s\n' "$*"
  DOCTOR_ERRORS=$((DOCTOR_ERRORS + 1))
}
note() { printf '[CHECK] %s\n' "$*"; }
check_command() { if command -v "$1" >/dev/null 2>&1; then ok "$1"; else bad "$1 missing"; fi; }
check_package() { if installed "$1"; then ok "package $1"; else bad "package $1 missing"; fi; }

doctor() {
  DOCTOR_ERRORS=0
  local module command package source_dir diff listing
  printf 'Read-only workstation diagnostics · %s\n' "$PROFILE"
  if [[ $(uname -s) != Linux ]]; then
    bad 'Ubuntu diagnostics require Linux'
    return 1
  fi
  for module in "${SELECTED[@]}"; do
    printf '\n%s\n' "$module"
    case $module in
      base)
        while IFS= read -r package; do check_package "$package"; done < <(lines "$REPO_ROOT/packages/base.txt")
        for command in chezmoi bw ws-ssh-vault bat fd ws-backup; do
          # ws-backup belongs to dotfiles and may not be selected with base alone.
          [[ $command != ws-backup ]] || continue
          check_command "$command"
        done
        ;;
      shell)
        check_command starship
        if [[ -r $HOME/.local/share/blesh/ble.sh ]]; then ok 'ble.sh'; else bad 'ble.sh missing'; fi
        ;;
      runtimes)
        for command in mise node npm pnpm corepack uv dotnet; do check_command "$command"; done
        if command -v node >/dev/null; then
          if [[ $(cd "$HOME" && node --version) == "v$NODE_VERSION" ]]; then ok "Node baseline $NODE_VERSION"; else bad 'Node baseline differs from config/versions.sh'; fi
        fi
        if command -v dotnet >/dev/null; then
          if DOTNET_CLI_TELEMETRY_OPTOUT=1 DOTNET_SKIP_FIRST_TIME_EXPERIENCE=1 dotnet --list-sdks | grep -q "^$DOTNET_VERSION"; then ok '.NET SDK'; else bad '.NET SDK missing'; fi
        fi
        ;;
      ai)
        check_command claude
        check_command codex
        note 'Authentication is verified interactively; no account requests are sent by doctor.'
        ;;
      containers)
        for command in podman docker docker-compose; do check_command "$command"; done
        if systemctl --user is-active --quiet podman.socket; then ok 'rootless Podman socket'; else bad 'Podman user socket inactive'; fi
        if [[ -S ${XDG_RUNTIME_DIR:-/nonexistent}/podman/podman.sock ]]; then ok 'Podman socket exists'; else bad 'Podman socket missing'; fi
        if [[ ${DOCKER_HOST:-} == "unix://${XDG_RUNTIME_DIR:-}/podman/podman.sock" ]]; then ok 'Docker endpoint'; else note 'Start a new login session or check your intentional DOCKER_HOST override.'; fi
        if [[ $(readlink -f /usr/bin/docker 2>/dev/null) == /usr/bin/podman ]] || installed podman-docker; then ok 'podman-docker bridge'; else bad 'Docker bridge missing'; fi
        note 'Run scripts/smoke-containers.sh for workloads; doctor does not initialize container storage.'
        ;;
      database)
        for command in psql mysql sqlite3 redis-cli mongosh sqlcmd; do check_command "$command"; done
        ;;
      apps)
        while IFS= read -r package; do check_package "$package"; done < <(lines "$REPO_ROOT/packages/apps.txt")
        for package in chatgpt gitkraken discord; do check_package "$package"; done
        while IFS= read -r package; do
          if command -v snap >/dev/null && snap list "$package" >/dev/null 2>&1; then ok "snap $package"; else bad "snap $package missing"; fi
        done < <(lines "$REPO_ROOT/packages/snap.txt")
        note 'Launch GUI apps and complete docs/SETUP_CHECKLIST.md; package presence does not prove GUI compatibility.'
        ;;
      database-gui)
        while IFS= read -r package; do check_package "$package"; done < <(lines "$REPO_ROOT/packages/database-gui.txt")
        for package in mongodb-compass bruno; do check_package "$package"; done
        ;;
      tools | devops | diagnostics)
        while IFS= read -r package; do check_package "$package"; done < <(lines "$REPO_ROOT/packages/$module.txt")
        case $module in
          tools) for command in cloudflared tofu yq just skopeo nethogs nmap iperf3 duf; do check_command "$command"; done ;;
          devops) for command in age ansible sops trivy; do check_command "$command"; done ;;
          diagnostics)
            check_command wireshark
            check_command tshark
            ;;
        esac
        ;;
      dotfiles)
        source_dir=$DOTFILES_SOURCE
        if [[ -z $source_dir && -r $STATE_DIR/dotfiles-source ]]; then IFS= read -r source_dir <"$STATE_DIR/dotfiles-source"; fi
        source_dir=${source_dir:-$HOME/.local/share/chezmoi}
        if command -v chezmoi >/dev/null; then
          if diff=$(
            umask 022
            chezmoi --source "$source_dir" diff --no-pager 2>&1
          ); then
            if [[ -z $diff ]]; then ok 'No managed dotfile drift'; else bad 'Managed files differ; run ws-dotfiles diff (local changes may be intentional).'; fi
          else bad 'chezmoi could not render source'; fi
        else bad 'chezmoi missing'; fi
        if [[ $(getent passwd "$(id -un)" | cut -d: -f7) == /bin/bash ]]; then ok 'Bash login shell'; else bad 'Bash is not the login shell'; fi
        check_command ws-backup
        if [[ -r $HOME/.config/workstation/backup.conf ]]; then note 'Backup configured; use ws-backup check with the disk attached.'; else note 'Configure the external backup disk using dotfiles/docs/BACKUP.md.'; fi
        ;;
      desktop)
        check_command kitty
        check_command gnome-disks
        check_command baobab
        if command -v flatpak >/dev/null && flatpak info --user io.podman_desktop.PodmanDesktop >/dev/null 2>&1; then ok 'Podman Desktop'; else bad 'Podman Desktop missing'; fi
        if desktop_session; then
          if [[ $(xdg-settings get default-web-browser) == brave-browser.desktop ]]; then ok 'Brave default browser'; else bad 'Brave is not default'; fi
          if command -v code >/dev/null; then
            listing=$(code --list-extensions)
            while IFS= read -r command; do
              if grep -Fqix "$command" <<<"$listing"; then ok "extension $command"; else bad "extension $command missing"; fi
            done < <(lines "$REPO_ROOT/packages/vscode.txt")
          fi
        else bad 'No graphical login session; cannot verify desktop settings'; fi
        ;;
      drivers)
        if command -v lspci >/dev/null && lspci -nn | grep -Ei '(VGA|3D|Display)' | grep -qi nvidia; then
          if command -v nvidia-smi >/dev/null && nvidia-smi --query-gpu=name,driver_version --format=csv,noheader; then ok 'NVIDIA driver responds'; else bad 'NVIDIA driver requires attention/reboot'; fi
        else note 'No NVIDIA display adapter visible in this environment'; fi
        ;;
    esac
  done
  if [[ -f /var/run/reboot-required ]]; then note 'Reboot required'; fi
  printf '\n%s failed check(s). Read-only diagnostics do not certify VM/hardware acceptance.\n' "$DOCTOR_ERRORS"
  ((DOCTOR_ERRORS == 0))
}
