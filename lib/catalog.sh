#!/usr/bin/env bash
WORKSTATION_MODULES=(base shell dotfiles runtimes ai containers database tools apps database-gui desktop drivers maintenance)
MODULE_ORDER=("${WORKSTATION_MODULES[@]}" devops diagnostics)
CORE_MODULES=(base shell runtimes ai containers database dotfiles)
declare -A DEPENDENCIES=(
  [base]='' [shell]='base' [runtimes]='dotfiles' [ai]='dotfiles'
  [containers]='dotfiles' [database]='base' [apps]='base'
  ["database-gui"]='base' [dotfiles]='shell' [desktop]='shell apps containers dotfiles'
  [drivers]='apps'
  [tools]='base' [devops]='base' [diagnostics]='base'
  [maintenance]='dotfiles'
)
# shellcheck disable=SC2034
declare -A DESCRIPTIONS=(
  [base]='CLI utilities, Git, backups and diagnostics'
  [shell]='Starship, ble.sh and shell prerequisites'
  [runtimes]='Node 24/mise/Corepack, Python/uv and .NET 10'
  [ai]='Standalone Claude Code and Codex CLIs'
  [containers]='Native rootless Podman and Docker-compatible Compose'
  [database]='SQL, MongoDB and cache command-line clients'
  [apps]='Brave, VS Code, AI desktop apps, Steam and productivity'
  ["database-gui"]='DBeaver, MongoDB Compass and Bruno'
  [dotfiles]='Portable chezmoi configuration and Bash migration'
  [desktop]='Ubuntu terminal, Kitty, font, extensions and Podman Desktop'
  [drivers]='Ubuntu-recommended NVIDIA driver and diagnostics'
  [tools]='Cloudflare Tunnel, OpenTofu, yq, just and network utilities'
  [devops]='Optional SOPS, age, Ansible and Trivy'
  [diagnostics]='Optional Wireshark and TShark'
  [maintenance]='Daily storage/backup checks and weekly backup integrity timer'
)

resolve_modules() {
  local requested=() name dependency changed=1
  declare -A selected=()
  if [[ -n $ONLY ]]; then
    IFS=',' read -r -a requested <<<"$ONLY"
  elif [[ $PROFILE == core ]]; then
    requested=("${CORE_MODULES[@]}")
  else requested=("${WORKSTATION_MODULES[@]}"); fi
  for name in "${requested[@]}"; do
    [[ -v DEPENDENCIES[$name] ]] || die "Unknown module: $name"
    selected[$name]=1
  done
  while ((changed)); do
    changed=0
    for name in "${!selected[@]}"; do
      for dependency in ${DEPENDENCIES[$name]}; do
        if [[ ! -v selected[$dependency] ]]; then
          selected[$dependency]=1
          changed=1
        fi
      done
    done
  done
  SELECTED=()
  for name in "${MODULE_ORDER[@]}"; do
    if [[ -v selected[$name] ]]; then SELECTED+=("$name"); fi
  done
}

is_selected() {
  local name
  for name in "${SELECTED[@]}"; do [[ $name != "$1" ]] || return 0; done
  return 1
}
