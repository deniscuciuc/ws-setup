#!/usr/bin/env bash
set -euo pipefail

# shellcheck source=/dev/null
source "$(dirname "${BASH_SOURCE[0]}")/lib/apt.sh"
# shellcheck source=/dev/null
source "$(dirname "${BASH_SOURCE[0]}")/lib/snap.sh"
# shellcheck source=/dev/null
source "$(dirname "${BASH_SOURCE[0]}")/lib/dotfiles.sh"
# shellcheck source=/dev/null
source "$(dirname "${BASH_SOURCE[0]}")/lib/kitty.sh"
# shellcheck source=/dev/null
source "$(dirname "${BASH_SOURCE[0]}")/lib/zsh.sh"
# shellcheck source=/dev/null
source "$(dirname "${BASH_SOURCE[0]}")/lib/devtools.sh"
# shellcheck source=/dev/null
source "$(dirname "${BASH_SOURCE[0]}")/lib/checklist.sh"

main() {
  echo "==> Starting workstation setup"

  install_apt_packages
  install_snaps
  apply_dotfiles
  install_kitty_env
  install_zsh
  install_devtools
  generate_checklist

  echo "==> Setup complete"
}

main "$@"
