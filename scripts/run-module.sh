#!/usr/bin/env bash
# A separate process preserves errexit while the coordinator records failures.
set -Eeuo pipefail
MODULE=${1:?module required}
export MODULE
REPO_ROOT=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
for component in common assets repositories modules dotfiles desktop; do
  # shellcheck source=/dev/null
  source "$REPO_ROOT/lib/$component.sh"
done
# shellcheck source=../config/versions.sh
source "$REPO_ROOT/config/versions.sh"
trap 'printf "Module %s failed at line %s (exit %s).\n" "$MODULE" "$LINENO" "$?" >&2' ERR
function_name=install_${MODULE//-/_}
declare -F "$function_name" >/dev/null || die "Unknown module: $MODULE"
"$function_name"
