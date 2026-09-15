#!/usr/bin/env bash
set -Eeuo pipefail
REPO_ROOT=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
export REPO_ROOT
# shellcheck source=lib/common.sh
source "$REPO_ROOT/lib/common.sh"
# shellcheck source=lib/catalog.sh
source "$REPO_ROOT/lib/catalog.sh"
# shellcheck source=config/versions.sh
source "$REPO_ROOT/config/versions.sh"

usage() {
  cat <<'EOF'
Usage: ./setup.sh [install|plan|doctor|update] [options]
  --profile workstation|core  Default: workstation
  --only module,...          Selected modules plus their dependencies
  --dotfiles-source PATH     Use a local chezmoi source instead of GitHub
  --help                     Show this help

Modules: base,shell,runtimes,ai,containers,database,apps,database-gui,
         dotfiles,desktop,drivers,tools,devops,diagnostics,maintenance
devops and diagnostics are opt-in; tools belongs to the workstation profile.
plan and doctor are read-only. Run install/update as your normal user.
EOF
}

parse_args() {
  ACTION=install PROFILE=workstation ONLY='' DOTFILES_SOURCE=''
  if (($#)) && [[ $1 != -* ]]; then
    ACTION=$1
    shift
  fi
  case $ACTION in install | plan | doctor | update) ;; *) die "Unknown command: $ACTION" ;; esac
  while (($#)); do
    case $1 in
      --profile | --only | --dotfiles-source)
        (($# >= 2)) && [[ -n $2 && $2 != --* ]] || die "Missing value for $1"
        case $1 in --profile) PROFILE=$2 ;; --only) ONLY=$2 ;; --dotfiles-source) DOTFILES_SOURCE=$2 ;; esac
        shift 2
        ;;
      --help | -h)
        usage
        exit 0
        ;;
      *) die "Unknown option: $1" ;;
    esac
  done
  [[ $PROFILE == workstation || $PROFILE == core ]] || die "Unknown profile: $PROFILE"
  if [[ -n $DOTFILES_SOURCE ]]; then
    [[ -d $DOTFILES_SOURCE ]] || die "Dotfiles source does not exist: $DOTFILES_SOURCE"
    DOTFILES_SOURCE=$(cd -- "$DOTFILES_SOURCE" && pwd)
  fi
  resolve_modules
}

preflight() {
  [[ $(uname -s) == Linux && -r /etc/os-release ]] || die 'Run this on Ubuntu 26.04, not Windows/Git Bash.'
  # shellcheck source=/dev/null
  source /etc/os-release
  [[ $ID == ubuntu && $VERSION_ID == 26.04 ]] || die "Expected Ubuntu 26.04; found $PRETTY_NAME"
  [[ $(uname -m) == x86_64 ]] || die 'This release currently supports x86_64 only.'
  [[ $EUID != 0 ]] || die 'Run as your normal user; setup calls sudo when needed.'
  command -v sudo >/dev/null || die 'sudo is required.'
  local required=10485760 available
  if is_selected apps; then required=26214400; fi
  available=$(df -Pk "$HOME" | awk 'END {print $4}')
  ((available >= required)) || die "Need at least $((required / 1048576)) GiB free on the home filesystem."
  available=$(df -Pk / | awk 'END {print $4}')
  ((available >= required)) || die "Need at least $((required / 1048576)) GiB free on the system filesystem."
  if is_selected containers; then user_systemd || die 'Podman requires a systemd user session. Log in normally and retry.'; fi
  if is_selected maintenance; then user_systemd || die 'Maintenance timers require a systemd user login session.'; fi
  if is_selected apps || is_selected desktop; then
    desktop_session || die 'Desktop modules require a graphical Ubuntu session. Use --profile core on a server.'
  fi
  if is_selected desktop; then
    command -v gsettings >/dev/null && gsettings list-schemas | grep -qx org.gnome.shell || die 'Desktop configuration requires an installed GNOME session. Use --profile core otherwise.'
  fi
  if is_selected containers; then
    local conflict
    for conflict in docker-ce docker-ce-cli docker.io docker-desktop containerd.io; do
      if installed "$conflict"; then die "Docker conflict: $conflict. Export data and follow docs/PODMAN.md before switching engines."; fi
    done
  fi
}

report() {
  local result=$? report_file="$STATE_DIR/reports/$RUN_ID.md"
  trap - EXIT
  {
    printf '# Workstation setup report\n\nCommand: `%s` · profile: `%s`\n\n' "$ACTION" "$PROFILE"
    printf '| Module | Result |\n|---|---|\n'
    local name
    for name in "${SELECTED[@]}"; do printf '| %s | %s |\n' "$name" "${RESULTS[$name]:-NOT RUN}"; done
    printf '\nExit code: %s\n\n' "$result"
    if [[ -s $STATE_DIR/reports/$RUN_ID.pending ]]; then
      printf '## Next steps\n\n'
      sed 's/^/- [ ] /' "$STATE_DIR/reports/$RUN_ID.pending"
    fi
    if [[ -f /var/run/reboot-required ]]; then printf '\nA system reboot is required.\n'; fi
    printf '\nSee docs/SETUP_CHECKLIST.md and run ./setup.sh doctor after signing in again.\n'
  } >"$report_file"
  dpkg-query -W -f='${binary:Package}\t${Version}\t${Status}\n' >"$STATE_DIR/reports/$RUN_ID.packages.tsv" 2>/dev/null || true
  cp "$report_file" "$STATE_DIR/latest-report.md"
  printf '\nReport: %s\n' "$report_file"
  if ((result)); then
    printf 'Setup is incomplete. Read the failed module log and rerun the same command.\n'
  else printf 'Selected modules completed. Finish the checklist; desktop/hardware acceptance is separate.\n'; fi
  exit "$result"
}

main() {
  parse_args "$@"
  STATE_DIR=${XDG_STATE_HOME:-$HOME/.local/state}/ws-setup
  CACHE_DIR=${XDG_CACHE_HOME:-$HOME/.cache}/ws-setup
  # An unqualified update follows installation receipts, including opt-in modules.
  # This also avoids desktop prerequisites on a machine managing only CLI tools.
  if [[ $ACTION == update && -z $ONLY ]]; then
    SELECTED=()
    local managed
    for managed in "${MODULE_ORDER[@]}"; do
      if [[ -f $STATE_DIR/modules/$managed ]]; then SELECTED+=("$managed"); fi
    done
  fi
  export ACTION PROFILE DOTFILES_SOURCE STATE_DIR CACHE_DIR
  export PATH="$HOME/.local/bin:$HOME/.local/share/mise/shims:$PATH"
  if [[ $ACTION == plan ]]; then
    printf 'Ubuntu 26.04 x86_64 · %s · no changes made\n' "$PROFILE"
    local name
    for name in "${SELECTED[@]}"; do printf '  %-14s %s\n' "$name" "${DESCRIPTIONS[$name]}"; done
    preflight
    printf 'Prerequisites passed. sudo authentication is checked only during installation.\n'
    return
  fi
  # shellcheck source=lib/doctor.sh
  source "$REPO_ROOT/lib/doctor.sh"
  if [[ $ACTION == doctor ]]; then
    doctor
    return
  fi
  preflight
  sudo -v
  umask 077
  RUN_ID=$(date -u +%Y%m%dT%H%M%SZ)-$$
  export RUN_ID
  mkdir -p "$STATE_DIR/reports" "$STATE_DIR/modules" "$CACHE_DIR"
  exec 9>"$STATE_DIR/setup.lock"
  flock -n 9 || die 'Another workstation setup is running.'
  declare -gA RESULTS=()
  trap report EXIT
  local name dep blocked rc failures=0
  for name in "${SELECTED[@]}"; do
    if [[ $ACTION == update && ! -f $STATE_DIR/modules/$name ]]; then
      RESULTS[$name]='SKIPPED (not managed yet)'
      continue
    fi
    blocked=''
    for dep in ${DEPENDENCIES[$name]}; do
      if [[ ${RESULTS[$dep]:-} == FAILED* || ${RESULTS[$dep]:-} == BLOCKED* ]]; then blocked=$dep; fi
    done
    if [[ -n $blocked ]]; then
      RESULTS[$name]="BLOCKED ($blocked failed)"
      failures=$((failures + 1))
      continue
    fi
    printf '\n==> %s\n' "$name"
    set +e
    bash "$REPO_ROOT/scripts/run-module.sh" "$name" 2>&1 | tee "$STATE_DIR/reports/$RUN_ID.$name.log"
    rc=$?
    set -e
    if ((rc)); then
      RESULTS[$name]="FAILED (exit $rc)"
      failures=$((failures + 1))
    else
      RESULTS[$name]=OK
      printf '%s\n' "$RUN_ID" >"$STATE_DIR/modules/$name"
    fi
  done
  ((failures == 0))
}

if [[ ${BASH_SOURCE[0]} == "$0" ]]; then main "$@"; fi
